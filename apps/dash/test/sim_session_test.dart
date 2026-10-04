import 'package:flutter_test/flutter_test.dart';
import 'package:koebelt_dash/core/model.dart';
import 'package:koebelt_dash/core/telemetry.dart';
import 'package:koebelt_dash/link/protocol.dart';
import 'package:koebelt_dash/link/session.dart';
import 'package:koebelt_dash/link/transport.dart';
import 'package:koebelt_dash/sim/sim_device.dart';

/// Opens a real session to a simulated device over the loopback transport.
Future<(DeviceSession, SimDevice, List<Msg>)> open(DeviceKind kind) async {
  final info = DeviceInfo(id: 'x', name: 'X', kind: kind);
  final sim = SimDevice(info);
  final lt = LoopbackTransport('test');
  sim.attach(lt);
  final got = <Msg>[];
  final s = DeviceSession(lt, onMessage: got.add);
  final hello = await s.open();
  expect(hello['kind'], kind.name);
  return (s, sim, got);
}

Future<void> wait(int ms) => Future<void>.delayed(Duration(milliseconds: ms));

void main() {
  test('handshake streams params, state and telemetry', () async {
    final (s, sim, got) = await open(DeviceKind.drone);
    await wait(400);
    final types = got.map((m) => m['t']).toSet();
    expect(types, containsAll(['params', 'state', 'tlm']));
    final tel = Telemetry(DeviceKind.drone);
    for (final m in got.where((m) => m['t'] == 'tlm')) {
      tel.applyTlm((m['d'] as Map).cast<String, dynamic>());
    }
    expect(tel.hasGps, isTrue);
    expect(tel.pos[2], greaterThan(5)); // demo drone flies at ~8 m
    expect(s.latency, greaterThanOrEqualTo(0));
    await s.close();
    sim.detach();
  });

  test('simulated sensors match what a hobby build carries', () async {
    Future<Set<String>> channels(DeviceKind k) async {
      final (s, sim, got) = await open(k);
      await wait(1200);
      final tel = Telemetry(k);
      for (final m in got) {
        if (m['t'] == 'tlm') tel.applyTlm((m['d'] as Map).cast<String, dynamic>());
        if (m['t'] == 'pc') tel.addPoints(decodePoints(m['d']));
        if (m['t'] == 'tracks') tel.applyTracks(m['d']);
      }
      await s.close();
      sim.detach();
      if (k == DeviceKind.rover) {
        expect(tel.cloud, isNotEmpty);
        expect(tel.cloud.every((p) => p[2] == .25), isTrue, reason: '2D scan plane');
      }
      return tel.seen;
    }

    final drone = await channels(DeviceKind.drone);
    expect(drone, containsAll(['imu', 'gps', 'bat']));
    expect(drone.intersection({'pc', 'tracks', 'joints', 'ft'}), isEmpty);
    final rover = await channels(DeviceKind.rover);
    expect(rover, containsAll(['imu', 'gps', 'pc']));
    expect(rover.contains('tracks'), isFalse);
    final arm = await channels(DeviceKind.arm);
    expect(arm, containsAll(['joints', 'bat']));
    expect(arm.intersection({'imu', 'ft', 'pc', 'tracks', 'gps'}), isEmpty);
  });

  test('stop disarms and blocks mode changes until reset', () async {
    final (s, sim, got) = await open(DeviceKind.rover);
    s.sendStop();
    await wait(150);
    expect(sim.estop, isTrue);
    expect(sim.armed, isFalse);
    s.send({'t': 'mode', 'm': 'MANUAL'});
    await wait(50);
    expect(sim.mode, 'HOLD');
    s.send({'t': 'reset'});
    await wait(50);
    expect(sim.estop, isFalse);
    expect(sim.armed, isFalse, reason: 'stays disarmed after reset');
    expect(got.where((m) => m['t'] == 'state').any((m) => m['estop'] == true), isTrue);
    await s.close();
    sim.detach();
  });

  test('device failsafe fires when the heartbeat stops', () async {
    final (s, sim, _) = await open(DeviceKind.drone);
    s.send({'t': 'fs', 'action': 'RTH', 'ms': 300});
    await wait(200);
    expect(sim.fsActive, isFalse);
    s.holdHeartbeat = true;
    await wait(600);
    expect(sim.fsActive, isTrue);
    expect(['RTH', 'LAND'], contains(sim.mode)); // RTH hands over to LAND once home
    s.holdHeartbeat = false;
    await wait(200);
    expect(sim.fsActive, isFalse);
    expect(['RTH', 'LAND'], contains(sim.mode), reason: 'mode stays until the app picks one');
    await s.close();
    sim.detach();
  });

  test('parameter writes are acknowledged and applied', () async {
    final (s, sim, got) = await open(DeviceKind.bench);
    s.send({
      't': 'pset',
      'p': {'MAX_CURRENT': 30, 'NOPE': 1},
    });
    await wait(900);
    final ack = got.lastWhere((m) => m['t'] == 'pack');
    expect(ack['keys'], ['MAX_CURRENT']);
    expect(sim.params['MAX_CURRENT'], 30);
    await s.close();
    sim.detach();
  });

  test('rocket flies a full profile offline', () {
    final fr = SimDevice.record(DeviceInfo(id: 'r', name: 'R', kind: DeviceKind.rocket), 200);
    final modes = fr.map((f) => f['mode']).toSet();
    expect(modes, containsAll(['BOOST', 'COAST', 'DROGUE', 'MAIN', 'LANDED']));
    expect(fr.map((f) => f['maxAlt'] as double).reduce((a, b) => a > b ? a : b), greaterThan(200));
  });
}
