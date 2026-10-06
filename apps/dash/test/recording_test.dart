import 'package:flutter_test/flutter_test.dart';
import 'package:koebelt_dash/core/dash.dart';
import 'package:koebelt_dash/core/export.dart';
import 'package:koebelt_dash/core/model.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> wait(int ms) => Future<void>.delayed(Duration(milliseconds: ms));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('records at the telemetry rate with frame times; replay and CSV follow them', () async {
    SharedPreferences.setMockInitialValues({});
    final d = Dash();
    await d.init();
    d.updateSettings((s) => s.rateHz = 60);
    final dev = d.addSimulated(simTemplates().first);
    await d.connect(dev.id);
    await wait(300);
    d.startRec();
    for (var i = 0; i < 30; i++) {
      await wait(50);
      d.tick(.05);
    }
    d.stopRec();
    final r = d.lastSaved!;
    expect(r.frames.first['t'], isA<num>());
    // About 60 Hz over 1.5 s; well above the old 10 Hz.
    expect(r.rateHz, greaterThan(30), reason: '${r.frames.length} frames in ${r.dur} s');
    expect(r.dur, closeTo(1.5, .4));
    for (var i = 1; i < r.frames.length; i++) {
      expect(r.timeAt(i), greaterThan(r.timeAt(i - 1)));
    }
    expect(r.frameAt(r.timeAt(5) + 1e-4), 5);
    expect(r.frameAt(-1), 0);
    expect(r.frameAt(99), r.frames.length - 1);

    final row = toCsv(r).split('\n')[3].split(',');
    expect(double.parse(row[0]), r.timeAt(1));

    d.openReplay(r.id);
    d.seekReplay(r.dur / 2);
    d.tick(0);
    expect(d.tel.mode, isNotEmpty);
    d.closeReplay();
    await d.disconnect();
    d.dispose();
  });

  test('legacy 10 Hz recordings keep their timing', () {
    final r = Recording(
      id: 'x',
      name: 'n',
      deviceId: 'x',
      kind: DeviceKind.drone,
      deviceName: 'K',
      date: '',
      frames: [for (var i = 0; i < 25; i++) <String, dynamic>{}],
    );
    expect(r.dur, 2.5);
    expect(r.timeAt(10), 1.0);
    expect(r.frameAt(1.05), 10);
    expect(r.rateHz, closeTo(10, .5));
  });
}
