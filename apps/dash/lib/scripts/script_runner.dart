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

/// Checks a script's syntax with [python]: null if it parses, else the line
/// and message.
Future<({int line, String message})?> checkSyntax(String python, String source) async {
  const code = 'import ast, json, sys\n'
      'src = sys.stdin.read()\n'
      'try:\n'
      '    ast.parse(src)\n'
      'except SyntaxError as e:\n'
      '    print(json.dumps({"line": e.lineno or 1, "msg": e.msg}))\n';
  try {
    final p = await Process.start(python, ['-c', code]);
    p.stdin.write(source);
    await p.stdin.close();
    final out = await p.stdout.transform(utf8.decoder).join();
    await p.exitCode.timeout(const Duration(seconds: 10));
    if (out.trim().isEmpty) return null;
    final j = jsonDecode(out) as Map;
    return (line: (j['line'] as num).toInt(), message: '${j['msg']}');
  } catch (_) {
    return null;
  }
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
  final p = await Process.start(python, ['-m', 'pip', 'install', if (upgrade) '--upgrade', spec]);
  p.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen(log);
  p.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen(log);
  final code = await p.exitCode;
  if (code != 0) throw ProcessException(python, ['-m', 'pip', 'install'], 'pip failed ($code)', code);
}

enum ScriptState { running, exited, failed }

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

  /// Asks the script to end, then ends it.
  Future<void> stop({Duration grace = const Duration(seconds: 2)});
}

/// A script running in a Python on this computer.
class LocalRun extends ScriptRun {
  LocalRun._(super.file, super.token, super.onChange, this.python, this.process) {
    process.stdout.transform(const SystemEncoding().decoder).transform(const LineSplitter()).listen((l) => log('out', l));
    process.stderr.transform(const SystemEncoding().decoder).transform(const LineSplitter()).listen((l) => log('err', l));
    process.exitCode.then((code) {
      // this.: dart:io has a top-level exitCode too.
      this.exitCode = code;
      state = code == 0 || _stopping ? ScriptState.exited : ScriptState.failed;
      log(state == ScriptState.failed ? 'err' : 'info', _stopping ? 'Stopped' : 'Exited with code $code');
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
    r.log('info', 'Started with Python at $python');
    return r;
  }
}
