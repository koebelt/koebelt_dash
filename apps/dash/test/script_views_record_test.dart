// What scripts show is kept with the recording and replays with it.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:koebelt_dash/core/dash.dart';
import 'package:koebelt_dash/core/model.dart';
import 'package:koebelt_dash/core/store.dart';
import 'package:koebelt_dash/scripts/views.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> wait(int ms) => Future<void>.delayed(Duration(milliseconds: ms));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('pictures, charts and plots are recorded, replay at their time, and go with the recording', () async {
    final tmp = Directory.systemTemp.createTempSync('kdash_views');
    SharedPreferences.setMockInitialValues({});
    final d = Dash(store: Store(recordingsRoot: tmp.path));
    await d.init();
    final dev = d.addSimulated(simTemplates().firstWhere((t) => t.kind == DeviceKind.rover));
    await d.connect(dev.id);
    final l = d.links.values.single;
    final cam = l.views['cam'] = ScriptView('cam', 'picture', 'test.py');
    final scan = l.views['scan'] = ScriptView('scan', 'chart', 'test.py');
    final speed = l.views['speed'] = ScriptView('speed', 'plot', 'test.py');
    final a = Uint8List.fromList([0xFF, 0xD8, 1, 1, 1]), b = Uint8List.fromList([0xFF, 0xD8, 2, 2, 2]);

    d.startRec();
    await wait(100);
    Future<void> run(int ms) async {
      for (var t = 0; t < ms; t += 20) {
        d.tick(.02);
        await wait(20);
      }
    }

    cam.picture(const {}, 'test.py', bytes: a);
    d.recordView(l, cam);
    scan.chartFrom({
      'chart': 'bar',
      'series': {
        'd': [1, 2],
      },
    }, 'test.py');
    d.recordView(l, scan);
    speed.plotFrom(['target', 'actual'], 'test.py');
    d.recordView(l, speed);
    await run(700);
    cam.picture(const {}, 'test.py', bytes: b);
    d.recordView(l, cam);
    scan.chartFrom({
      'chart': 'bar',
      'series': {
        'd': [3, 4],
      },
    }, 'test.py');
    d.recordView(l, scan);
    await run(500);
    d.stopRec();
    final r = d.lastSaved!;
    for (var i = 0; i < 100 && r.views.isEmpty; i++) {
      await wait(20);
    }
    await wait(200);
    expect({for (final v in r.views) v['name']: v['kind']}, {'cam': 'picture', 'scan': 'chart', 'speed': 'plot'});
    expect(r.views.firstWhere((v) => v['name'] == 'cam')['frames'], 2);
    expect(r.views.firstWhere((v) => v['name'] == 'speed')['labels'], ['target', 'actual']);
    final files = [
      for (final v in r.views)
        if (v['file'] != null) '${tmp.path}/${v['file']}',
    ];
    expect(files.every((f) => File(f).existsSync()), isTrue);
    await d.disconnect();
    d.dispose();

    // Loaded again: the replay shows what was shown then.
    final d2 = Dash(store: Store(recordingsRoot: tmp.path));
    await d2.init();
    d2.openReplay(r.id);
    final rp = d2.replay!..playing = false;
    Future<void> at(double t) async {
      rp.t = t;
      for (var i = 0; i < 10; i++) {
        d2.tick(0);
        await wait(20);
      }
    }

    expect(d2.scriptViews.keys, containsAll(['cam', 'scan', 'speed']));
    await at(.3);
    expect(d2.scriptViews['cam']!.image, a);
    expect(d2.scriptViews['scan']!.series['d'], [1, 2]);
    expect(d2.scriptViews['speed']!.labels, ['target', 'actual']);
    await at(r.dur);
    expect(d2.scriptViews['cam']!.image, b);
    expect(d2.scriptViews['scan']!.series['d'], [3, 4]);
    d2.closeReplay();
    expect(d2.scriptViews, isEmpty, reason: 'no replay, no device');

    await d2.deleteRecording(r.id);
    expect(files.any((f) => File(f).existsSync()), isFalse, reason: 'its files go with it');
    d2.dispose();
    tmp.deleteSync(recursive: true);
  });
}
