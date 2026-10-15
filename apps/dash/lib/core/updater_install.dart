import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// A failure with a message for the person updating.
class UpdateError implements Exception {
  const UpdateError(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Where updates are downloaded. On Android this is the cache folder the
/// FileProvider in AndroidManifest.xml shares with the system installer.
Future<Directory> updateDownloadDir() async {
  final d = Directory('${(await getTemporaryDirectory()).path}/updates');
  if (d.existsSync()) d.deleteSync(recursive: true);
  return d.create(recursive: true);
}

/// Called before the app quits for an update (disconnects devices cleanly).
Future<void> Function()? beforeUpdateQuit;

/// Installs a verified update. Desktop: prepares the new version next to the
/// running one, starts a small script that waits for this process to end,
/// swaps them and starts the new one, then quits. Android: opens the system
/// installer, which updates in place because the APK carries the same key.
///
/// [exe], [waitPid] and [runScript] stand in for this process in tests: the
/// running executable, the process the script waits for, and starting the
/// script then quitting.
Future<void> installUpdate(String os, File file, String version, {String? exe, int? waitPid, Future<void> Function(String script)? runScript}) {
  final x = _Ctx(exe ?? Platform.resolvedExecutable, waitPid ?? pid, runScript);
  return switch (os) {
    'macos' => _macos(file, x),
    'windows' => _windows(file, x),
    'linux' => _linux(file, x),
    'android' => _android(file),
    _ => throw UpdateError('Updates are not installed by the app on $os.'),
  };
}

class _Ctx {
  _Ctx(this.exe, this.pid, this.runScript);
  final String exe;
  final int pid;
  final Future<void> Function(String script)? runScript;

  Future<void> quitInto(String shell, String script) async {
    if (runScript != null) return runScript!(script);
    await Process.start(shell, shell == 'cmd.exe' ? ['/c', script] : [script], mode: ProcessStartMode.detached);
    await beforeUpdateQuit?.call();
    exit(0);
  }
}

/// The team that signs koebelt dash (Developer ID); an update must be signed
/// by the same one.
const _teamId = '89489C74MY';

Future<ProcessResult> _run(String cmd, List<String> args) async {
  final r = await Process.run(cmd, args);
  if (r.exitCode != 0) throw UpdateError('$cmd failed: ${'${r.stderr}'.trim().split('\n').first}');
  return r;
}

void _checkWritable(String dir, String hint) {
  try {
    final probe = File('$dir/.koebelt-dash-write-test')..writeAsStringSync('');
    probe.deleteSync();
  } catch (_) {
    throw UpdateError('Cannot write to $dir. $hint');
  }
}

Future<void> _macos(File dmg, _Ctx x) async {
  // …/koebelt dash.app/Contents/MacOS/koebelt dash
  final app = Directory(x.exe).parent.parent.parent.path;
  if (!app.endsWith('.app')) throw const UpdateError('Could not find the app bundle to replace.');
  if (app.contains('/AppTranslocation/')) {
    throw const UpdateError('macOS is running koebelt dash from a temporary copy. Move it to Applications, open it from there and update again.');
  }
  final parent = Directory(app).parent.path;
  _checkWritable(parent, 'Move koebelt dash to Applications (or another folder you can write to) and update again.');

  final mount = await Directory.systemTemp.createTemp('kdash-update');
  final staged = '$parent/.koebelt-dash-update.app';
  try {
    await _run('/usr/bin/hdiutil', ['attach', '-nobrowse', '-readonly', '-noautoopen', '-mountpoint', mount.path, dmg.path]);
    try {
      final found = mount.listSync().whereType<Directory>().where((d) => d.path.endsWith('.app')).toList();
      if (found.isEmpty) throw const UpdateError('The disk image has no app in it.');
      if (Directory(staged).existsSync()) Directory(staged).deleteSync(recursive: true);
      await _run('/usr/bin/ditto', [found.first.path, staged]);
    } finally {
      await Process.run('/usr/bin/hdiutil', ['detach', '-quiet', mount.path]);
    }
    // Signed by the same team, intact, and accepted by Gatekeeper (notarized).
    await _run('/usr/bin/codesign', ['--verify', '--deep', '--strict', staged]);
    final info = await Process.run('/usr/bin/codesign', ['-dv', staged]);
    if (!'${info.stderr}'.contains('TeamIdentifier=$_teamId')) throw const UpdateError('The update is not signed by koebelt. Nothing was installed.');
    await _run('/usr/sbin/spctl', ['--assess', '--type', 'execute', staged]);
  } catch (_) {
    if (Directory(staged).existsSync()) Directory(staged).deleteSync(recursive: true);
    rethrow;
  } finally {
    mount.deleteSync(recursive: true);
  }

  final script = File('${dmg.parent.path}/install.sh')
    ..writeAsStringSync('''
#!/bin/sh
# Waits for koebelt dash to quit, swaps in the update, starts it.
while kill -0 ${x.pid} 2>/dev/null; do sleep 0.2; done
old="$app.old"
rm -rf "\$old"
if mv "$app" "\$old" && mv "$staged" "$app"; then
  rm -rf "\$old"
else
  [ -d "\$old" ] && [ ! -d "$app" ] && mv "\$old" "$app"
  rm -rf "$staged"
fi
open "$app"
''');
  await x.quitInto('/bin/sh', script.path);
}

Future<void> _windows(File setup, _Ctx x) async {
  final script = File('${setup.parent.path}\\install.cmd')
    ..writeAsStringSync('''
@echo off
rem Waits for koebelt dash to quit, runs the installer silently, starts the new version.
:wait
tasklist /FI "PID eq ${x.pid}" 2>nul | find "${x.pid}" >nul && (ping -n 2 127.0.0.1 >nul & goto wait)
"${setup.path}" /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /CLOSEAPPLICATIONS
start "" "${x.exe}"
''');
  await x.quitInto('cmd.exe', script.path);
}

Future<void> _linux(File tarball, _Ctx x) async {
  // The bundle folder: …/koebelt-dash-1.0.0-linux-x64/koebelt_dash
  final bundle = File(x.exe).parent.path;
  final parent = Directory(bundle).parent.path;
  _checkWritable(parent, 'Move the koebelt dash folder somewhere you can write to and update again.');
  final unpack = await Directory(parent).createTemp('.koebelt-dash-update');
  try {
    await _run('tar', ['-xzf', tarball.path, '-C', unpack.path]);
    final dirs = unpack.listSync().whereType<Directory>().toList();
    if (dirs.length != 1 || !File('${dirs.first.path}/koebelt_dash').existsSync()) throw const UpdateError('The download does not contain koebelt dash.');
  } catch (_) {
    unpack.deleteSync(recursive: true);
    rethrow;
  }
  final fresh = unpack.listSync().whereType<Directory>().first.path;
  final script = File('${tarball.parent.path}/install.sh')
    ..writeAsStringSync('''
#!/bin/sh
# Waits for koebelt dash to quit, swaps in the update, starts it. The folder
# keeps its name, so the menu entry from install.sh still points at it.
while kill -0 ${x.pid} 2>/dev/null; do sleep 0.2; done
old="$bundle.old"
rm -rf "\$old"
if mv "$bundle" "\$old" && mv "$fresh" "$bundle"; then
  rm -rf "\$old"
else
  [ -d "\$old" ] && [ ! -d "$bundle" ] && mv "\$old" "$bundle"
fi
rm -rf "${unpack.path}"
nohup "$bundle/koebelt_dash" >/dev/null 2>&1 &
''');
  await x.quitInto('/bin/sh', script.path);
}

const _channel = MethodChannel('com.koebelt.dash/updater');

Future<void> _android(File apk) async {
  final r = await _channel.invokeMethod<String>('installApk', {'path': apk.path});
  if (r == 'needs-permission') {
    throw const UpdateError('Allow koebelt dash to install apps (the settings page just opened), then tap Update again.');
  }
}
