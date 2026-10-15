// The macOS update swap with a real release: mounts a published, notarized
// koebelt dash .dmg, checks its team signature and Gatekeeper, stages it next
// to a stand-in "old" app in a temp folder, runs the generated swap script
// (with `open` stubbed) and checks the old app was replaced.
//
//   UPDATE_E2E_DMG=~/Downloads/koebelt-dash-1.0.0-macos.dmg flutter test test/updater_macos_e2e_test.dart
//
// Skipped without the variable, and anywhere but macOS.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:koebelt_dash/core/updater_install.dart';

void main() {
  final dmg = Platform.environment['UPDATE_E2E_DMG'];
  // Optional: a .dmg of an unsigned build, which must be refused.
  final unsigned = Platform.environment['UPDATE_E2E_UNSIGNED_DMG'];

  test('a notarized release replaces the running app', () async {
    final root = await Directory.systemTemp.createTemp('kdash-e2e');
    addTearDown(() => root.delete(recursive: true));
    final app = '${root.path}/koebelt dash.app';
    final exe = File('$app/Contents/MacOS/koebelt dash')..createSync(recursive: true);
    exe.writeAsStringSync('old');

    // A process that has already ended: the script must not wait for it.
    final gone = await Process.start('/usr/bin/true', []);
    await gone.exitCode;

    // The installer deletes its download folder's contents, so work on a copy.
    final dl = await Directory('${root.path}/download').create();
    final copy = await File(dmg!).copy('${dl.path}/update.dmg');

    String? script;
    await installUpdate('macos', copy, '1.0.0', exe: exe.path, waitPid: gone.pid, runScript: (s) async => script = s);
    expect(Directory('${root.path}/.koebelt-dash-update.app').existsSync(), isTrue, reason: 'verified and staged next to the app');
    expect(script, isNotNull);

    final bin = await Directory('${root.path}/bin').create();
    final opened = File('${root.path}/opened');
    File('${bin.path}/open')
      ..writeAsStringSync('#!/bin/sh\necho "\$1" > "${opened.path}"\n')
      ..setLastModifiedSync(DateTime.now());
    await Process.run('/bin/chmod', ['+x', '${bin.path}/open']);
    final r = await Process.run('/bin/sh', [script!], environment: {'PATH': '${bin.path}:/usr/bin:/bin'});
    expect(r.exitCode, 0, reason: '${r.stderr}');

    expect(File('$app/Contents/MacOS/koebelt dash').lengthSync(), greaterThan(1000), reason: 'the real binary replaced the stand-in');
    expect(Directory('$app/Contents/_CodeSignature').existsSync(), isTrue);
    expect(Directory('$app.old').existsSync(), isFalse);
    expect(Directory('${root.path}/.koebelt-dash-update.app').existsSync(), isFalse);
    expect(opened.readAsStringSync().trim(), app);
    final sig = await Process.run('/usr/bin/codesign', ['--verify', '--deep', '--strict', app]);
    expect(sig.exitCode, 0, reason: '${sig.stderr}');
  }, skip: dmg == null || !Platform.isMacOS ? 'set UPDATE_E2E_DMG to a release .dmg (macOS only)' : false);

  test('an app not signed by koebelt is refused and nothing is replaced', () async {
    final root = await Directory.systemTemp.createTemp('kdash-e2e');
    addTearDown(() => root.delete(recursive: true));
    final exe = File('${root.path}/koebelt dash.app/Contents/MacOS/koebelt dash')..createSync(recursive: true);
    exe.writeAsStringSync('old');
    final copy = await File(unsigned!).copy('${root.path}/update.dmg');
    await expectLater(
      installUpdate('macos', copy, '9.9.9', exe: exe.path, waitPid: 1, runScript: (_) async => fail('must not get as far as the swap')),
      throwsA(isA<UpdateError>()),
    );
    expect(exe.readAsStringSync(), 'old');
    expect(Directory('${root.path}/.koebelt-dash-update.app').existsSync(), isFalse, reason: 'the staged copy is removed');
  }, skip: unsigned == null || !Platform.isMacOS ? 'set UPDATE_E2E_UNSIGNED_DMG to an unsigned .dmg (macOS only)' : false);
}
