// Importing recordings and flight controller logs. The real ArduPilot and
// PX4 logs are downloaded once into test/fixtures/logs (not committed);
// those tests skip when offline. Reference values come from pymavlink and
// pyulog.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:koebelt_dash/core/dash.dart';
import 'package:koebelt_dash/core/export.dart';
import 'package:koebelt_dash/core/log_import.dart';
import 'package:koebelt_dash/core/model.dart';
import 'package:koebelt_dash/sim/sim_device.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _logs = {
  'test.BIN': 'https://github.com/ArduPilot/pymavlink/raw/master/tests/test.BIN',
  'vtol.tlog': 'https://github.com/ArduPilot/UAVLogViewer/raw/master/src/assets/vtol.tlog',
  'sample.ulg': 'https://github.com/PX4/pyulog/raw/main/test/sample.ulg',
};

Future<Uint8List?> _log(String name) async {
  final f = File('test/fixtures/logs/$name');
  if (!f.existsSync()) {
    try {
      final c = HttpClient();
      final res = await (await c.getUrl(Uri.parse(_logs[name]!))).close();
      if (res.statusCode != 200) return null;
      final b = await res.fold<List<int>>([], (a, x) => a..addAll(x));
      f.parent.createSync(recursive: true);
      f.writeAsBytesSync(b);
      c.close();
    } catch (_) {
      return null;
    }
  }
  return f.readAsBytesSync();
}

Map<String, dynamic>? _firstWith(List<Map<String, dynamic>> fr, String ch) => fr.where((f) => (f['seen'] as List).contains(ch)).firstOrNull;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => HttpOverrides.global = null);

  test('JSON export round-trips', () {
    final r = Recording(
      id: 'x',
      name: 'Hover',
      deviceId: 'x',
      kind: DeviceKind.drone,
      deviceName: 'Kite',
      date: '',
      frames: SimDevice.record(DeviceInfo(id: 'x', name: 'Kite', kind: DeviceKind.drone), 3),
      startedAt: DateTime.utc(2026, 5, 1, 10),
    );
    final log = parseLog('Kite_Hover.json', utf8.encode(exportRecording(r, ExportFormat.json)));
    expect(log.name, 'Hover');
    expect(log.deviceName, 'Kite');
    expect(log.kind, DeviceKind.drone);
    expect(log.startedAt, r.startedAt);
    expect(jsonEncode(log.frames), jsonEncode(r.frames));
  });

  test('unknown files are refused with a readable reason', () {
    expect(() => parseLog('notes.txt', Uint8List.fromList(utf8.encode('hello'))), throwsA(isA<LogImportError>()));
    expect(() => parseLog('x.json', Uint8List.fromList(utf8.encode('{"a":1}'))), throwsA(isA<LogImportError>()));
  });

  test('ArduPilot DataFlash .bin', () async {
    final b = await _log('test.BIN');
    if (b == null) return markTestSkipped('offline');
    final l = parseLog('test.BIN', b);
    expect(l.deviceName, 'ArduPlane');
    expect(l.kind, DeviceKind.drone);
    expect(l.startedAt!.year, 2017);
    final f = _firstWith(l.frames, 'att')!;
    // pymavlink: first ATT Roll −7.18°, Pitch 2.58°, Yaw 337.1°.
    expect(f['roll'], closeTo(7.18 * math.pi / 180, .01));
    expect(f['pitch'], closeTo(2.58 * math.pi / 180, .01));
    expect(f['yaw'], closeTo(math.pi / 2 - 337.1 * math.pi / 180, .01));
    final g = _firstWith(l.frames, 'gps')!;
    expect(g['lat'], closeTo(-35.36263, 1e-4));
    expect(g['lon'], closeTo(149.16530, 1e-4));
    expect(_firstWith(l.frames, 'bat')!['voltage'], closeTo(12.39, .05));
    for (var i = 1; i < l.frames.length; i++) {
      expect(l.frames[i]['t'], greaterThanOrEqualTo(l.frames[i - 1]['t']));
    }
  });

  test('MAVLink .tlog through the live adapter', () async {
    final b = await _log('vtol.tlog');
    if (b == null) return markTestSkipped('offline');
    final l = parseLog('vtol.tlog', b);
    expect(l.deviceName, 'ArduPlane'); // HEARTBEAT type 1, ArduPilot
    expect(l.startedAt!.toUtc().toIso8601String(), startsWith('2018-08-08T14:06'));
    expect(l.frames.last['t'], greaterThan(200));
    final g = _firstWith(l.frames, 'gps')!;
    expect(g['lat'], closeTo(-35.36299, 1e-3));
    expect(g['lon'], closeTo(149.16494, 1e-3));
    final modes = {for (final f in l.frames) f['mode']};
    expect(modes, containsAll(['AUTO', 'LAND']));
    expect(l.frames.any((f) => f['armed'] == true), isTrue);
    // No battery monitor in this vehicle (0 V, −1 %): no battery channel.
    expect(_firstWith(l.frames, 'bat'), isNull);
  });

  test('PX4 ULog .ulg', () async {
    final b = await _log('sample.ulg');
    if (b == null) return markTestSkipped('offline');
    final l = parseLog('sample.ulg', b);
    expect(l.deviceName, 'PX4');
    expect(l.frames.last['t'], closeTo(69, 1));
    expect(l.frames.length / l.frames.last['t'], closeTo(50, 6), reason: 'capped at 50 Hz');
    final f = _firstWith(l.frames, 'att')!;
    // pyulog: first vehicle_attitude → roll 0.0515, pitch 0.1164, yaw −0.5889.
    expect(f['roll'], closeTo(-0.0515, .02));
    expect(f['pitch'], closeTo(0.1164, .02));
    expect(f['yaw'], closeTo(math.pi / 2 + 0.5889, .02));
    expect(l.frames.last['pos'][2], closeTo(-0.0947, .02), reason: 'NED z → up');
    expect({for (final f in l.frames) f['mode']}, {'—', 'MANUAL'});
  });

  test('Dash imports a file as a recording and replays it', () async {
    SharedPreferences.setMockInitialValues({});
    final d = Dash();
    await d.init();
    final r0 = Recording(
      id: 'x',
      name: 'Field test',
      deviceId: 'x',
      kind: DeviceKind.rover,
      deviceName: 'Mule',
      date: '',
      frames: SimDevice.record(DeviceInfo(id: 'x', name: 'Mule', kind: DeviceKind.rover), 2),
    );
    final r = await d.importLog('Mule_Field_test.json', utf8.encode(exportRecording(r0, ExportFormat.json)));
    expect(d.sessions.first, same(r));
    expect(r.name, 'Field test');
    expect(r.kind, DeviceKind.rover);
    expect(r.dur, r0.dur);
    d.openReplay(r.id);
    d.tick(.1);
    expect(d.replay?.session, same(r));
    d.dispose();
  });
}
