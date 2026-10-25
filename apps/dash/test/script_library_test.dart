import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koebelt_dash/core/model.dart';
import 'package:koebelt_dash/scripts/library.dart';
import 'package:koebelt_dash/scripts/script_runner.dart';

void main() {
  late Directory dir;
  late ScriptLibrary lib;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('kdash-lib');
    lib = ScriptLibrary(Directory('${dir.path}/dash-scripts'));
  });
  tearDown(() => dir.delete(recursive: true));

  List<int> zip(Map<String, String> files) {
    final a = Archive();
    for (final e in files.entries) {
      final b = utf8.encode(e.value);
      a.addFile(ArchiveFile(e.key, b.length, b));
    }
    return ZipEncoder().encode(a);
  }

  test('new scripts get a file name from their title, and a title from their docstring', () async {
    final f = await lib.create('Follow me!', scriptTemplate('loop', DeviceKind.rover, 'Follow me'));
    expect(f.uri.pathSegments.last, 'follow_me.py');
    expect(await f.readAsString(), contains('dev.sticks(throttle=0, steer=0)'));
    final g = await lib.create('Follow me', '');
    expect(g.uri.pathSegments.last, 'follow_me_2.py', reason: 'never overwrites');
    final list = await lib.list();
    expect(list.map((s) => s.name), ['Follow me', 'Follow me 2'], reason: 'docstring, else the file name');
    expect(list.first.label, 'follow_me.py');
  });

  test('imports a .py, and a .zip with its files (in a top folder or not)', () async {
    final py = await lib.import('Colour tracker.py', utf8.encode('"""Track a colour."""\n'));
    expect(py.uri.pathSegments.last, 'colour_tracker.py');

    final z = await lib.import(
      'vision.zip',
      zip({'vision/main.py': '"""Follow with YOLO."""', 'vision/model/yolo.pt': 'weights', '__MACOSX/vision/._main.py': 'junk'}),
    );
    expect(z.path, endsWith('/vision/main.py'));
    expect(File('${z.parent.path}/model/yolo.pt').existsSync(), isTrue);
    expect(Directory('${z.parent.path}/__MACOSX').existsSync(), isFalse);

    final one = await lib.import('one.zip', zip({'run_me.py': 'print(1)', 'data.csv': '1,2'}));
    expect(one.path, endsWith('/one/main.py'), reason: 'its only top-level .py becomes main.py');

    await expectLater(lib.import('two.zip', zip({'a.py': '', 'b.py': ''})), throwsFormatException);
    await expectLater(lib.import('notes.txt', [1]), throwsFormatException);
    await expectLater(lib.import('evil.zip', zip({'main.py': '', '../outside.py': 'x'})), completes);
    expect(File('${lib.dir.path}/outside.py').existsSync(), isFalse, reason: 'no writing outside the folder');

    final list = await lib.list();
    expect(list.map((s) => s.label), containsAll(['colour_tracker.py', 'vision/', 'one/']));
    expect(list.firstWhere((s) => s.label == 'vision/').name, 'Follow with YOLO');
  });

  test('exports a folder script as a zip that imports back', () async {
    await lib.import('vision.zip', zip({'main.py': '"""Vision."""', 'model.pt': 'w'}));
    final s = (await lib.list()).single;
    final out = await lib.export(s);
    expect(out.name, 'vision.zip');
    final back = await ScriptLibrary(Directory('${dir.path}/other')).import(out.name, out.bytes);
    expect(File('${back.parent.path}/model.pt').readAsStringSync(), 'w');
  });

  test('duplicate, rename, and delete into a trash that keeps the files', () async {
    final f = await lib.create('Hold', '"""Hold."""');
    var s = (await lib.list()).single;
    final copy = await lib.duplicate(s);
    expect(copy.uri.pathSegments.last, 'hold_copy.py');
    final renamed = await lib.rename(s, 'Hold altitude');
    expect(renamed.uri.pathSegments.last, 'hold_altitude.py');
    expect(f.existsSync(), isFalse);
    s = (await lib.list()).firstWhere((x) => x.label == 'hold_altitude.py');
    await lib.delete(s);
    expect((await lib.list()).map((x) => x.label), ['hold_copy.py']);
    expect(lib.trash.listSync().single.path, endsWith('hold_altitude.py'));
  });

  test('a script names its interpreter in its first lines', () {
    expect(pythonFromHeader('# python: /opt/py/bin/python3\nimport x'), '/opt/py/bin/python3');
    expect(pythonFromHeader('"""Doc."""\n# python: ~/venvs/vision/bin/python'), endsWith('/venvs/vision/bin/python'));
    expect(pythonFromHeader('import x\n'), isNull);
  });

  test('the examples in the app are the package’s examples, compressed', () {
    // name.py.gz: App Store Connect refuses an iOS app holding readable Python as unsigned code.
    final app = Directory('assets/script_examples').listSync().whereType<File>().toList();
    expect(app.where((f) => !f.path.endsWith('.py.gz')), isEmpty, reason: 'only .py.gz in the app bundle');
    final pkg = Directory('../../libs/python-dash-scripts/examples').listSync().whereType<File>().where((f) => f.path.endsWith('.py')).toList();
    String names(List<File> l) => (l.map((f) => f.uri.pathSegments.last.replaceAll(RegExp(r'\.gz$'), '')).toList()..sort()).join(', ');
    expect(names(app), names(pkg), reason: 'run tools/assets/sync_app_assets.py');
    for (final f in app) {
      final src = f.uri.pathSegments.last.replaceAll(RegExp(r'\.gz$'), '');
      expect(
        utf8.decode(gzip.decode(f.readAsBytesSync())),
        File('../../libs/python-dash-scripts/examples/$src').readAsStringSync(),
        reason: 'run tools/assets/sync_app_assets.py',
      );
    }
  });

  test('the docs assistants read are the repository’s, compressed', () {
    const pairs = {
      'assets/docs/PROTOCOL.md.gz': '../../protocol/PROTOCOL.md',
      'assets/docs/SCRIPTS.md.gz': '../../protocol/SCRIPTS.md',
      'assets/docs/SCRIPTS_API.md.gz': '../../libs/python-dash-scripts/README.md',
    };
    for (final e in pairs.entries) {
      expect(utf8.decode(gzip.decode(File(e.key).readAsBytesSync())), File(e.value).readAsStringSync(), reason: 'run tools/assets/sync_app_assets.py');
    }
  });
}
