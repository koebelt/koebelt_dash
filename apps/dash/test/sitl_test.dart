// The app against the real ArduPilot autopilot in simulation (SITL), in
// Docker. Opt-in, because it needs Docker and takes a few minutes:
//
//   SITL=1 flutter test test/sitl_test.dart
//
// It builds tools/sitl/Dockerfile.ardupilot on first run. Each vehicle is
// found the way a user finds it (Pair device > Nearby, MAVLink on UDP
// 14550), flies a sequence as a mission, and its own DataFlash log is
// imported afterwards.
@TestOn('vm')
@Tags(['sitl'])
library;

import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:koebelt_dash/core/dash.dart';
import 'package:koebelt_dash/core/log_import.dart';
import 'package:koebelt_dash/core/model.dart';
import 'package:koebelt_dash/core/sequence.dart';
import 'package:koebelt_dash/link/discovery.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _ardupilot = 'koebelt/sitl-ardupilot', _px4 = 'koebelt/sitl-px4';
final _on = Platform.environment['SITL'] == '1';

Future<ProcessResult> docker(List<String> args) => Process.run('docker', args);

Future<void> ensureImage(String image, String dockerfile) async {
  if ((await docker(['image', 'inspect', image])).exitCode == 0) return;
  final b = await Process.run('docker', ['build', '-t', image, '-f', dockerfile, '.'], workingDirectory: '../../tools/sitl');
  if (b.exitCode != 0) throw StateError('docker build failed:\n${b.stderr}');
}

/// Starts [vehicle] from [image]; returns the container name.
Future<String> startSitl(String vehicle, {String image = _ardupilot}) async {
  final name = 'kd-sitl-$vehicle';
  await docker(['rm', '-f', name]);
  final r = await docker([
    'run', '-d', '--name', name, if (image == _ardupilot) ...['--platform', 'linux/amd64'], //
    '--add-host=host.docker.internal:host-gateway', image, vehicle,
  ]);
  if (r.exitCode != 0) throw StateError('docker run failed: ${r.stderr}');
  addTearDown(() => docker(['rm', '-f', name]));
  return name;
}

/// The logs the autopilot wrote (ArduPilot .BIN, PX4 .ulg), copied out of
/// the container, oldest first.
Future<List<File>> fetchLogs(String container, {String from = '/sitl/logs', String ext = '.BIN'}) async {
  final dir = Directory.systemTemp.createTempSync('kd-sitl-logs');
  await docker(['cp', '$container:$from/.', dir.path]);
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.toLowerCase().endsWith(ext.toLowerCase())).toList();
  return files..sort((a, b) => a.statSync().modified.compareTo(b.statSync().modified));
}

Future<void> pump(Dash d, int ms, {bool Function()? until}) async {
  final sw = Stopwatch()..start();
  while (sw.elapsedMilliseconds < ms && !(until?.call() ?? false)) {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    d.tick(.05);
  }
}

/// Finds the vehicle on UDP 14550, pairs and connects, and waits until the
/// autopilot reports its EKF origin (GPS and position ready to arm).
/// [readyText]: the autopilot's message that it is ready (ArduPilot repeats
/// it as the EKF switches to GPS); null to wait for a position and a few
/// seconds (PX4 says "Ready for takeoff!" once, before the app connects).
Future<Dash> connectVehicle(String expectName, {String? readyText = 'is using GPS'}) async {
  SharedPreferences.setMockInitialValues({});
  final d = Dash();
  await d.init();
  d.startScan();
  Found? f;
  await pump(d, 60000, until: () => (f = d.found.values.where((x) => x.proto == 'mavlink').firstOrNull) != null);
  d.stopScan();
  expect(f, isNotNull, reason: 'no MAVLink heartbeat on UDP 14550');
  expect(f!.name, expectName);
  expect(await d.pair(f!), isNull);
  final dev = d.devices.firstWhere((x) => x.id == f!.id);
  if (d.deviceId != dev.id) await d.connect(dev.id);
  expect(d.connectError, isNull);
  expect(d.seqCap, greaterThan(0), reason: 'ArduPilot takes sequences as missions');
  // What a pilot waits for: the EKF navigating on GPS, not just a fix.
  bool ready() => (readyText == null || d.logs.any((m) => '${m['msg']}'.contains(readyText))) && d.liveTel.hasGps && d.liveTel.seen.contains('pos');
  await pump(d, 90000, until: ready);
  expect(ready(), isTrue, reason: 'no EKF origin; last messages: ${d.logs.reversed.take(5).map((m) => m['msg']).toList()}');
  await pump(d, 3000); // pre-arm checks settle
  return d;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    if (!_on) return;
    await ensureImage(_ardupilot, 'Dockerfile.ardupilot');
    await ensureImage(_px4, 'Dockerfile.px4');
  });

  test(
    'ArduCopter: telemetry, parameters, a sequence flown as a mission, its log imported',
    () async {
      final c = await startSitl('copter');
      final d = await connectVehicle('ArduCopter');
      final t = d.liveTel;
      expect(t.seen, containsAll(['att', 'gps', 'pos', 'bat', 'imu']));
      expect(t.battery, inInclusiveRange(1, 100), reason: 'SITL battery monitor reports a percentage');
      expect(t.voltage, greaterThan(10));
      expect(d.paramGroups[d.deviceId]?.expand((g) => g.params).length ?? 0, greaterThan(500), reason: 'full parameter table');

      d.startRec();
      final q = Sequence(
        id: 'sitl-hop',
        name: 'SITL hop',
        kind: DeviceKind.drone,
        steps: [
          SeqStep('arm', {'v': 'ARM'}),
          SeqStep('takeoff', {'alt': 10.0}),
          SeqStep('goto', {'x': 20.0, 'y': 10.0, 'z': 12.0}),
          SeqStep('wait', {'s': 2.0}),
          SeqStep('land', {}),
        ],
      );
      d.runSequence(q);
      final r = d.runner!;
      expect(r.onDevice, isTrue);
      var maxAlt = 0.0, closest = double.infinity;
      final modes = <String>{};
      await pump(
        d,
        240000,
        until: () {
          final p = d.liveTel.pos;
          maxAlt = math.max(maxAlt, p[2]);
          closest = math.min(closest, math.sqrt(math.pow(p[0] - 20, 2) + math.pow(p[1] - 10, 2)));
          modes.add(d.liveTel.mode);
          return r.state == RunState.done || r.state == RunState.failed;
        },
      );
      d.stopRec();
      expect(r.state, RunState.done, reason: '${r.message} · log: ${d.logs.reversed.take(6).map((m) => m['msg']).toList()}');
      expect(maxAlt, greaterThan(8), reason: 'took off to about 10 m');
      expect(closest, lessThan(3), reason: 'reached the waypoint 20 m east, 10 m north');
      expect(d.liveTel.armed, isFalse, reason: 'landed and disarmed');
      // Landing is a mission item: the vehicle stays in AUTO throughout.
      expect(modes, contains('AUTO'));
      final rec = d.lastSaved!;
      expect(rec.frames.length, greaterThan(100));
      await d.disconnect();
      d.dispose();

      // The autopilot's own log of the same flight.
      final logs = await fetchLogs(c);
      expect(logs, isNotEmpty, reason: 'ArduPilot logs while armed');
      // Kept as a real ArduCopter log for the import tests (not committed).
      logs.last.copySync('${(Directory('test/fixtures/logs')..createSync(recursive: true)).path}/sitl-arducopter.BIN');
      final log = parseLog(logs.last.path, logs.last.readAsBytesSync());
      expect(log.deviceName, 'ArduCopter');
      expect(log.startedAt, isNotNull, reason: 'GPS time');
      final fr = log.frames;
      expect(fr.any((f) => (f['seen'] as List).contains('bat') && (f['battery'] as num) < 100), isTrue, reason: 'battery percentage');
      expect({for (final f in fr) f['mode']}, contains('AUTO'));
      final far = fr
          .map((f) => f['pos'] as List)
          .fold<double>(0, (m, p) => math.max(m, math.sqrt((p[0] as num) * (p[0] as num) + (p[1] as num) * (p[1] as num))));
      expect(far, closeTo(math.sqrt(20 * 20 + 10 * 10), 3), reason: 'the log shows the same waypoint');
      expect(fr.any((f) => f['armed'] == true), isTrue);
    },
    skip: _on ? false : 'set SITL=1 (needs Docker)',
    timeout: const Timeout(Duration(minutes: 8)),
  );

  test(
    'ArduRover: drives a sequence as a mission',
    () async {
      await startSitl('rover');
      final d = await connectVehicle('ArduRover');
      final q = Sequence(
        id: 'sitl-drive',
        name: 'SITL drive',
        kind: DeviceKind.rover,
        steps: [
          SeqStep('arm', {'v': 'ARM'}),
          SeqStep('goto', {'x': 15.0, 'y': 5.0}),
          SeqStep('wait', {'s': 1.0}),
          SeqStep('goto', {'x': 0.0, 'y': 0.0}),
        ],
      );
      d.runSequence(q);
      final r = d.runner!;
      expect(r.onDevice, isTrue);
      var closest = double.infinity;
      await pump(
        d,
        240000,
        until: () {
          final p = d.liveTel.pos;
          closest = math.min(closest, math.sqrt(math.pow(p[0] - 15, 2) + math.pow(p[1] - 5, 2)));
          return r.state == RunState.done || r.state == RunState.failed;
        },
      );
      expect(r.state, RunState.done, reason: '${r.message} · log: ${d.logs.reversed.take(6).map((m) => m['msg']).toList()}');
      expect(closest, lessThan(3), reason: 'reached the first waypoint');
      final p = d.liveTel.pos;
      expect(math.sqrt(p[0] * p[0] + p[1] * p[1]), lessThan(4), reason: 'back near home');
      d.setArmed(false);
      await pump(d, 1500);
      await d.disconnect();
      d.dispose();
    },
    skip: _on ? false : 'set SITL=1 (needs Docker)',
    timeout: const Timeout(Duration(minutes: 8)),
  );

  test(
    'PX4: telemetry, a sequence flown as a mission, its ULog imported',
    () async {
      final c = await startSitl('quadx', image: _px4);
      final d = await connectVehicle('PX4 copter', readyText: null);
      await pump(d, 5000);
      expect(d.liveTel.seen, containsAll(['att', 'gps', 'pos', 'bat', 'imu']), reason: 'PX4 sends HIGHRES_IMU, not RAW_IMU');
      expect(d.paramGroups[d.deviceId]?.expand((g) => g.params).length ?? 0, greaterThan(500));
      final q = Sequence(
        id: 'sitl-px4',
        name: 'SITL PX4 hop',
        kind: DeviceKind.drone,
        steps: [
          SeqStep('arm', {'v': 'ARM'}),
          SeqStep('takeoff', {'alt': 10.0}),
          SeqStep('goto', {'x': 20.0, 'y': 10.0, 'z': 12.0}),
          SeqStep('wait', {'s': 2.0}),
          SeqStep('land', {}),
        ],
      );
      d.runSequence(q);
      final r = d.runner!;
      expect(r.onDevice, isTrue);
      var maxAlt = 0.0, closest = double.infinity;
      await pump(
        d,
        300000,
        until: () {
          final p = d.liveTel.pos;
          maxAlt = math.max(maxAlt, p[2]);
          closest = math.min(closest, math.sqrt(math.pow(p[0] - 20, 2) + math.pow(p[1] - 10, 2)));
          return r.state == RunState.done || r.state == RunState.failed;
        },
      );
      expect(r.state, RunState.done, reason: '${r.message} · log: ${d.logs.reversed.take(8).map((m) => m['msg']).toList()}');
      expect(maxAlt, greaterThan(8));
      expect(closest, lessThan(3));
      // Done at touchdown (MISSION_ITEM_REACHED); PX4 disarms 2 s later.
      await pump(d, 10000, until: () => !d.liveTel.armed);
      expect(d.liveTel.armed, isFalse);
      await d.disconnect();
      d.dispose();

      final logs = await fetchLogs(c, from: '/px4/build/px4_sitl_default/log', ext: '.ulg');
      expect(logs, isNotEmpty, reason: 'PX4 logs from arming to disarming');
      logs.last.copySync('${(Directory('test/fixtures/logs')..createSync(recursive: true)).path}/sitl-px4.ulg');
      final log = parseLog(logs.last.path, logs.last.readAsBytesSync());
      expect(log.deviceName, 'PX4');
      // No start time: the SIH simulator's GPS reports UTC time as 0 (a real one does not).
      final fr = log.frames;
      expect(fr.any((f) => (f['seen'] as List).contains('gps')), isTrue, reason: 'a current PX4 logs GPS');
      expect(fr.any((f) => (f['seen'] as List).contains('bat') && (f['battery'] as num) < 100), isTrue, reason: 'and the battery');
      expect(fr.any((f) => f['armed'] == true), isTrue);
      final far = fr
          .map((f) => f['pos'] as List)
          .fold<double>(0, (m, p) => math.max(m, math.sqrt((p[0] as num) * (p[0] as num) + (p[1] as num) * (p[1] as num))));
      expect(far, closeTo(math.sqrt(20 * 20 + 10 * 10), 3));
    },
    skip: _on ? false : 'set SITL=1 (needs Docker)',
    timeout: const Timeout(Duration(minutes: 10)),
  );
}
