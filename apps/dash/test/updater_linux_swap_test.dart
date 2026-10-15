// The Linux update swap for real (tar and sh only, so it also runs on macOS):
// a release tarball is unpacked next to the running folder, and the generated
// script swaps the folders, keeping the name the menu entry points at, and
// starts the new version.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:koebelt_dash/core/updater_install.dart';

void main() {
  test('a release tarball replaces the running folder', () async {
    final root = await Directory.systemTemp.createTemp('kdash-linux');
    addTearDown(() => root.delete(recursive: true));

    // Running: …/koebelt-dash/koebelt_dash (the folder name is the user's choice).
    final bundle = '${root.path}/koebelt-dash';
    File('$bundle/koebelt_dash')
      ..createSync(recursive: true)
      ..writeAsStringSync('old');
    File('$bundle/data/old-only').createSync(recursive: true);

    // The release: koebelt-dash-1.1.0-linux-x64/ with a koebelt_dash that
    // records that it was started.
    final started = File('${root.path}/started');
    final rel = Directory('${root.path}/src/koebelt-dash-1.1.0-linux-x64')..createSync(recursive: true);
    File('${rel.path}/koebelt_dash').writeAsStringSync('#!/bin/sh\necho new > "${started.path}"\n');
    await Process.run('/bin/chmod', ['+x', '${rel.path}/koebelt_dash']);
    final dl = await Directory('${root.path}/download').create();
    final tarball = File('${dl.path}/koebelt-dash-1.1.0-linux-x64.tar.gz');
    final t = await Process.run('tar', ['-czf', tarball.path, '-C', '${root.path}/src', 'koebelt-dash-1.1.0-linux-x64']);
    expect(t.exitCode, 0, reason: '${t.stderr}');

    final gone = await Process.start('/usr/bin/true', []);
    await gone.exitCode;
    String? script;
    await installUpdate('linux', tarball, '1.1.0', exe: '$bundle/koebelt_dash', waitPid: gone.pid, runScript: (s) async => script = s);

    final r = await Process.run('/bin/sh', [script!]);
    expect(r.exitCode, 0, reason: '${r.stderr}');
    for (var i = 0; i < 50 && !started.existsSync(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }

    expect(File('$bundle/koebelt_dash').readAsStringSync(), contains('echo new'), reason: 'same folder name, new contents');
    expect(File('$bundle/data/old-only').existsSync(), isFalse, reason: 'the old folder is gone, not merged');
    expect(Directory('$bundle.old').existsSync(), isFalse);
    expect(root.listSync().where((e) => e.path.contains('.koebelt-dash-update')), isEmpty, reason: 'nothing left behind');
    expect(started.readAsStringSync().trim(), 'new', reason: 'the new version was started');
  }, skip: Platform.isWindows ? 'needs tar and sh' : false);
}
