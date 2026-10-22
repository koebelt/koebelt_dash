import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// A Python interpreter scripts can run with.
class PythonEnv {
  const PythonEnv(this.path, this.version, {required this.hasPackage});
  final String path, version;

  /// Whether koebelt-dash-scripts is installed in it.
  final bool hasPackage;

  @override
  String toString() => 'Python $version ($path)';
}

/// Asks an interpreter for its version and whether it has the package; null
/// if it is not a working Python 3.
Future<PythonEnv?> probePython(String path) async {
  try {
    final r = await Process.run(path, [
      '-c',
      'import sys, importlib.util; print(sys.version.split()[0], importlib.util.find_spec("koebelt_dash_scripts") is not None)',
    ]).timeout(const Duration(seconds: 8));
    final out = '${r.stdout}'.trim().split(' ');
    if (r.exitCode != 0 || out.length != 2 || !out[0].startsWith('3.')) return null;
    return PythonEnv(path, out[0], hasPackage: out[1] == 'True');
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

enum ScriptState { running, exited, failed }

typedef ConsoleLine = ({DateTime at, String level, String text});

/// A script dash started: its process and its output.
class ScriptRun {
  ScriptRun._(this.file, this.python, this.process, this.onChange) : startedAt = DateTime.now() {
    process.stdout.transform(const SystemEncoding().decoder).transform(const LineSplitter()).listen((l) => log('out', l));
    process.stderr.transform(const SystemEncoding().decoder).transform(const LineSplitter()).listen((l) => log('err', l));
    process.exitCode.then((code) {
      exitCode = code;
      state = code == 0 || _stopping ? ScriptState.exited : ScriptState.failed;
      log(state == ScriptState.failed ? 'err' : 'info', _stopping ? 'Stopped' : 'Exited with code $code');
    });
  }

  final File file;
  final String python;
  final Process process;
  final void Function() onChange;
  final DateTime startedAt;
  ScriptState state = ScriptState.running;
  int? exitCode;
  bool _stopping = false;
  final List<ConsoleLine> console = [];

  int get pid => process.pid;

  void log(String level, String text) {
    console.add((at: DateTime.now(), level: level, text: text));
    if (console.length > 2000) console.removeRange(0, console.length - 2000);
    onChange();
  }

  /// Asks the script to end, then ends it.
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
  static Future<ScriptRun> start(File file, String python, {required String url, required String token, required void Function() onChange}) async {
    final p = await Process.start(
      python,
      ['-u', file.path],
      workingDirectory: file.parent.path,
      environment: {'KOEBELT_DASH_URL': url, 'KOEBELT_DASH_TOKEN': token, 'PYTHONUNBUFFERED': '1', 'PYTHONIOENCODING': 'utf-8'},
    );
    final r = ScriptRun._(file, python, p, onChange);
    r.log('info', 'Started with Python at $python');
    return r;
  }
}
