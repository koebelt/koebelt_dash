import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../core/compat.dart' show compareVersions, isPrerelease;
import '../link/protocol.dart' show appVersion;

/// A Python interpreter scripts can run with.
class PythonEnv {
  const PythonEnv(this.path, this.version, {required this.hasPackage, this.packageVersion});
  final String path, version;

  /// Whether koebelt-dash-scripts is installed in it, and which version (1.3.0b2).
  final bool hasPackage;
  final String? packageVersion;

  @override
  String toString() => 'Python $version ($path)';
}

/// Asks an interpreter for its version and whether it has the package; null
/// if it is not a working Python 3.
Future<PythonEnv?> probePython(String path) async {
  try {
    final r = await Process.run(path, [
      '-c',
      'import sys\n'
          'try:\n'
          '    from importlib.metadata import version\n'
          '    v = version("koebelt-dash-scripts")\n'
          'except Exception:\n'
          '    v = "-"\n'
          'print(sys.version.split()[0], v)',
    ]).timeout(const Duration(seconds: 8));
    final out = '${r.stdout}'.trim().split(' ');
    if (r.exitCode != 0 || out.length != 2 || !out[0].startsWith('3.')) return null;
    return PythonEnv(path, out[0], hasPackage: out[1] != '-', packageVersion: out[1] == '-' ? null : out[1]);
  } catch (_) {
    return null;
  }
}

/// The interpreters on this computer: on the PATH, Homebrew, pyenv, conda,
/// and virtual environments in [near] (the scripts folder).
Future<List<PythonEnv>> findPythons({Directory? near}) async {
  final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '';
  final win = Platform.isWindows;
  final candidates = <String>{
    if (near != null)
      for (final v in ['.venv', 'venv', 'env']) win ? '${near.path}\\$v\\Scripts\\python.exe' : '${near.path}/$v/bin/python',
    for (final dir in (Platform.environment['PATH'] ?? '').split(win ? ';' : ':'))
      for (final n in win ? ['python.exe', 'python3.exe'] : ['python3', 'python']) '$dir${win ? '\\' : '/'}$n',
    if (!win) ...[
      '/opt/homebrew/bin/python3',
      '/usr/local/bin/python3',
      '/usr/bin/python3',
      '$home/.pyenv/shims/python3',
      for (final c in ['miniconda3', 'anaconda3', 'miniforge3', 'mambaforge']) '$home/$c/bin/python',
    ],
    if (win)
      for (final c in ['miniconda3', 'anaconda3']) '$home\\$c\\python.exe',
  };
  final seen = <String>{}, found = <PythonEnv>[];
  for (final c in candidates) {
    final f = File(c);
    if (!f.existsSync()) continue;
    // The same interpreter under several names counts once.
    final real = f.resolveSymbolicLinksSync();
    if (!seen.add(real)) continue;
    // The Windows Store's python.exe is a stub that opens the Store.
    if (win && c.contains('WindowsApps')) continue;
    final p = await probePython(c);
    if (p != null) found.add(p);
  }
  return found;
}

/// The interpreter a script asks for in its first lines:
/// `# python: ~/venvs/vision/bin/python`.
String? pythonFromHeader(String source) {
  for (final line in const LineSplitter().convert(source).take(5)) {
    final m = RegExp(r'^#\s*python:\s*(.+?)\s*$').firstMatch(line);
    if (m != null) {
      final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '';
      return m[1]!.replaceFirst(RegExp(r'^~'), home);
    }
  }
  return null;
}

/// Creates a virtual environment in [dir] with koebelt-dash-scripts, using
/// [base] (any Python 3.9+). Returns its interpreter. [log] gets pip's output.
Future<String> createScriptsVenv(String base, Directory dir, void Function(String) log) async {
  final py = Platform.isWindows ? '${dir.path}\\Scripts\\python.exe' : '${dir.path}/bin/python';
  if (!File(py).existsSync()) {
    log('Creating a Python environment in ${dir.path}');
    final r = await Process.run(base, ['-m', 'venv', dir.path]);
    if (r.exitCode != 0) throw ProcessException(base, ['-m', 'venv'], '${r.stderr}', r.exitCode);
  }
  await installScriptsPackage(py, log);
  return py;
}

/// What dash asks pip for: any koebelt-dash-scripts that speaks this app's
/// script API (version 1, from 1.3.0b1), up to the next major version. A
/// beta app accepts betas; a release app only releases.
String scriptsPackageSpec([String app = appVersion]) => 'koebelt-dash-scripts>=${isPrerelease(app) ? '1.3.0b1' : '1.3.0'},<2';

/// Whether a koebelt-dash-scripts version (in the app's form: 1.3.0-beta.2)
/// is one [scriptsPackageSpec] accepts.
bool scriptsPackageAccepts(String v, [String app = appVersion]) {
  final min = isPrerelease(app) ? '1.3.0-beta.1' : '1.3.0';
  if (!isPrerelease(app) && isPrerelease(v)) return false;
  return compareVersions(v, min) >= 0 && compareVersions(v, '2.0.0-alpha.0') < 0;
}

/// Installs koebelt-dash-scripts into [python].
Future<void> installScriptsPackage(String python, void Function(String) log, {bool upgrade = false}) async {
  final spec = scriptsPackageSpec();
  log('${upgrade ? 'Updating' : 'Installing'} $spec');
  await pipInstall(python, [spec], log, upgrade: upgrade);
}

/// `python -m pip install [specs]`, its output to [log]; throws if pip fails.
Future<void> pipInstall(String python, List<String> specs, void Function(String) log, {bool upgrade = false}) async {
  final p = await Process.start(python, ['-m', 'pip', 'install', if (upgrade) '--upgrade', ...specs]);
  // All of pip's output first: its last lines say why it failed.
  final out = p.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen(log).asFuture<void>();
  final err = p.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen(log).asFuture<void>();
  final code = await p.exitCode;
  await Future.wait([out, err]);
  if (code != 0) throw ProcessException(python, ['-m', 'pip', 'install'], 'pip failed ($code)', code);
}

enum ScriptState { running, exited, failed }

/// Sorts a script's output into the console's levels, for its colours: err,
/// warn, info, debug, or [fallback] (out for stdout, err for stderr).
///
/// - Python tracebacks and koebelt-dash-scripts' `error[E…]` are errors,
///   `warning[W…]` and Python's warnings are warnings, and the lines that go
///   with them (indented, `-->`, `|`, `=`) take the same level.
/// - Lines that start with a level, as `logging` writes them or as a print
///   can (`DEBUG:root:…`, `debug: …`, `[WARNING] …`), take it.
class ConsoleLevels {
  ConsoleLevels(this.fallback);
  final String fallback;
  String? _block;

  static final _ansi = RegExp(r'\x1B\[[0-?]*[ -/]*[@-~]');
  static final _tagged = RegExp(r'^\s*\[?(debug|info|warning|warn|error|critical|fatal)\]?\s*[:\]|-]', caseSensitive: false);
  static final _rust = RegExp(r'^(error|warning)\[\w+\]:');
  static final _pyWarning = RegExp(r':\d+: \w*Warning: ');
  static final _goesWith = RegExp(r'^([ \t]|\s*(-->|\||=|\^))');
  static final _exception = RegExp(r'^[\w.]+(Error|Exception|Interrupt|Exit)\b');

  /// The text as a terminal would end up showing it: no colour codes, and
  /// only what follows the last carriage return (progress bars).
  static String clean(String s) {
    s = s.replaceAll(_ansi, '');
    final cr = s.lastIndexOf('\r');
    return cr >= 0 ? s.substring(cr + 1) : s;
  }

  String levelOf(String line) {
    if (line.trim().isEmpty) {
      final b = _block;
      _block = null;
      return b ?? fallback;
    }
    if (line.startsWith('Traceback (most recent call last)')) return _block = 'err';
    final rust = _rust.firstMatch(line);
    if (rust != null) return _block = rust[1] == 'error' ? 'err' : 'warn';
    if (_pyWarning.hasMatch(line)) return _block = 'warn';
    final tag = _tagged.firstMatch(line);
    if (tag != null) {
      return _block = switch (tag[1]!.toLowerCase()) {
        'debug' => 'debug',
        'info' => 'info',
        'warning' || 'warn' => 'warn',
        _ => 'err',
      };
    }
    final block = _block;
    if (block != null && _goesWith.hasMatch(line)) return block;
    _block = null;
    // A traceback ends with the exception itself.
    if (block == 'err' && _exception.hasMatch(line)) return 'err';
    return fallback;
  }
}

typedef ConsoleLine = ({DateTime at, String level, String text});

/// A script dash started, here or on a script host: its output and state.
/// [token] is the one it connects with, so dash knows which connection is it.
abstract class ScriptRun {
  ScriptRun(this.file, this.token, this.onChange) : startedAt = DateTime.now();
  final File file;
  final String token;
  final void Function() onChange;
  final DateTime startedAt;
  ScriptState state = ScriptState.running;
  int? exitCode;
  final List<ConsoleLine> console = [];

  /// Where it runs, for the panel: "This computer", or the host's name.
  String get where;

  void log(String level, String text) {
    console.add((at: DateTime.now(), level: level, text: text));
    if (console.length > 2000) console.removeRange(0, console.length - 2000);
    onChange();
  }

  final _levels = {'out': ConsoleLevels('out'), 'err': ConsoleLevels('err')};

  /// A line the script wrote to [stream] (out or err), at the level it says.
  void output(String stream, String line) {
    final text = ConsoleLevels.clean(line);
    log((_levels[stream] ?? _levels['out']!).levelOf(text), text);
  }

  /// Asks the script to end, then ends it.
  Future<void> stop({Duration grace = const Duration(seconds: 2)});
}

/// A script running in a Python on this computer.
class LocalRun extends ScriptRun {
  LocalRun._(super.file, super.token, super.onChange, this.python, this.process) {
    process.stdout.transform(const SystemEncoding().decoder).transform(const LineSplitter()).listen((l) => output('out', l));
    process.stderr.transform(const SystemEncoding().decoder).transform(const LineSplitter()).listen((l) => output('err', l));
    process.exitCode.then((code) {
      // this.: dart:io has a top-level exitCode too.
      this.exitCode = code;
      state = code == 0 || _stopping ? ScriptState.exited : ScriptState.failed;
      log(state == ScriptState.failed ? 'err' : 'sys', _stopping ? 'Stopped' : 'Exited with code $code');
    });
  }

  final String python;
  final Process process;
  bool _stopping = false;

  @override
  String get where => 'This computer';

  @override
  Future<void> stop({Duration grace = const Duration(seconds: 2)}) async {
    if (state != ScriptState.running) return;
    _stopping = true;
    process.kill(ProcessSignal.sigterm);
    try {
      await process.exitCode.timeout(grace);
    } on TimeoutException {
      process.kill(ProcessSignal.sigkill);
    }
  }

  /// Starts [file] with [python], connected to the script API at [url].
  static Future<LocalRun> start(File file, String python, {required String url, required String token, required void Function() onChange}) async {
    final p = await Process.start(
      python,
      ['-u', file.path],
      workingDirectory: file.parent.path,
      environment: {'KOEBELT_DASH_URL': url, 'KOEBELT_DASH_TOKEN': token, 'PYTHONUNBUFFERED': '1', 'PYTHONIOENCODING': 'utf-8'},
    );
    final r = LocalRun._(file, token, onChange, python, p);
    r.log('sys', 'Started with Python at $python');
    return r;
  }
}
