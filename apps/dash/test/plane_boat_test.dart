// Planes and boats: what they are from MAVLink, and the simulated ones flying
// and sailing a stored sequence (a plane passes its waypoints and lands in a
// glide; a boat drifts in the current).
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:koebelt_dash/core/dash.dart';
import 'package:koebelt_dash/core/model.dart';
import 'package:koebelt_dash/core/sequence.dart';
import 'package:koebelt_dash/link/mavlink_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Runs the app (and its simulators) ten times faster than the clock.
Future<void> _until(Dash d, bool Function() done, {int maxMs = 20000}) async {
  final sw = Stopwatch()..start();
  while (!done() && sw.elapsedMilliseconds < maxMs) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    d.tick(.1);
  }
}

Future<Dash> _connect(DeviceKind kind, {String? id}) async {
  SharedPreferences.setMockInitialValues({});
  final d = Dash();
  await d.init();
  final dev = d.addSimulated(simTemplates().firstWhere((t) => t.kind == kind && (id == null || t.id == id)));
  await d.connect(dev.id);
  d.setSpeed(1);
  await _until(d, () => false, maxMs: 300);
  return d;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('MAVLink vehicle types', () {
    expect(mavKind(1), 'plane', reason: 'fixed wing');
    expect(mavKind(20), 'plane', reason: 'quadplane (VTOL)');
    expect(mavKind(11), 'boat');
    expect(mavKind(10), 'rover');
    expect(mavKind(2), 'drone');
    expect(DeviceKind.parse('plane'), DeviceKind.plane);
    expect(DeviceKind.plane.flies && DeviceKind.boat.drives, isTrue);
    expect([mavBody(13), mavBody(14), mavBody(4), mavBody(20), mavBody(2)], ['hexa', 'octo', 'heli', 'vtol', '']);
  });

  test('body shapes: what the device declares, else its kind\'s usual one', () {
    expect(DeviceKind.drone.bodyOr('hexa'), 'hexa');
    expect(DeviceKind.drone.bodyOr('car'), 'quad', reason: 'not a drone shape');
    expect(DeviceKind.rover.bodyOr(''), '4wd');
    expect(DeviceKind.legged.bodyOr(null), 'quadruped');
    expect(DeviceKind.legged.bodyOr('humanoid'), 'humanoid');
    expect(DeviceKind.rover.bodyOr('balancer'), 'balancer');
    expect(DeviceKind.arm.bodyOr('hexa'), '');
    final info = DeviceInfo(id: 'x', name: 'X', kind: DeviceKind.rover, body: 'tracked');
    expect(DeviceInfo.fromJson(info.toJson()).body, 'tracked');
  });

  test('a shape picked in the app wins over the declared one, and is kept', () async {
    final d = await _connect(DeviceKind.rover, id: 'wobble');
    final dev = d.device!;
    expect(d.body, 'balancer', reason: 'as it declares');
    d.setBodyChoice(dev, 'tracked');
    expect(d.body, 'tracked');
    await d.disconnect();
    await d.connect(dev.id);
    await _until(d, () => false, maxMs: 300);
    expect(dev.body, 'balancer', reason: 'it still declares its own');
    expect(d.body, 'tracked', reason: 'the pick survives the reconnect');
    expect(DeviceInfo.fromJson(dev.toJson()).shape, 'tracked', reason: 'and is saved');
    d.setBodyChoice(dev, '');
    expect(d.body, 'balancer');
    await d.disconnect();
    d.dispose();
  });

  test('a plane takes off, passes its waypoint and lands in a glide', () async {
    final d = await _connect(DeviceKind.plane);
    final q = Sequence(
      id: 'lap',
      name: 'Lap',
      kind: DeviceKind.plane,
      steps: [
        SeqStep('takeoff', {'alt': 20.0}),
        SeqStep('goto', {'x': 120.0, 'y': 0.0, 'z': 30.0}),
        SeqStep('land', {}),
      ],
    );
    d.runSequence(q);
    final r = d.runner!;
    await _until(d, () => r.index >= 1);
    expect(d.liveTel.pos[2], greaterThan(15), reason: 'it climbed out');
    await _until(d, () => r.index >= 2);
    expect(d.liveTel.pos[0], greaterThan(90), reason: 'it reached the waypoint');
    await _until(d, () => r.state == RunState.done || r.state == RunState.failed, maxMs: 30000);
    expect(r.state, RunState.done, reason: r.message);
    expect(d.liveTel.armed, isFalse, reason: 'landed and disarmed');
    expect(d.liveTel.pos[2], lessThan(.5), reason: 'on the ground');
    await d.disconnect();
    d.dispose();
  });

  test('a legged robot stands, walks a stored sequence and sits', () async {
    final d = await _connect(DeviceKind.legged);
    expect(DeviceKind.legged.walks && DeviceKind.legged.onGround && !DeviceKind.legged.drives, isTrue);
    d.setArmed(true);
    await _until(d, () => d.liveTel.stance == 'stand' && d.liveTel.pos[2] > .15);
    expect(d.liveTel.stance, 'stand', reason: 'armed: it stands up');
    d.cmd('gait', {'v': 'trot'});
    await _until(d, () => d.liveTel.gait == 'trot');
    final q = Sequence(
      id: 'yard',
      name: 'Yard',
      kind: DeviceKind.legged,
      steps: [
        SeqStep('goto', {'x': 3.0, 'y': 2.0}),
        SeqStep('goto', {'x': 0.0, 'y': 0.0}),
      ],
    );
    expect(q.steps.first.summary(DeviceKind.legged), startsWith('Walk to'));
    d.runSequence(q);
    final r = d.runner!;
    await _until(d, () => r.state == RunState.done || r.state == RunState.failed, maxMs: 30000);
    expect(r.state, RunState.done, reason: r.message);
    d.cmd('stance', {'v': 'sit'});
    await _until(d, () => d.liveTel.stance == 'sit' && d.liveTel.pos[2] < .12);
    expect(d.liveTel.pos[2], lessThan(.12), reason: 'sitting, the body is low');
    await d.disconnect();
    d.dispose();
  });

  test('a two-wheeled robot leans to drive; a humanoid stands tall and crouches', () async {
    final w = await _connect(DeviceKind.rover, id: 'wobble');
    expect(w.device!.body, 'balancer');
    w.setArmed(true);
    w.operatorMode('MANUAL');
    var leaned = 0.0;
    await _until(w, () {
      w.input[3] = 1;
      leaned = math.min(leaned, w.liveTel.pitch);
      return w.liveTel.speed > .5;
    });
    expect(leaned, lessThan(-.05), reason: 'nose down to speed up');
    await w.disconnect();
    w.dispose();

    final a = await _connect(DeviceKind.legged, id: 'ada');
    expect(a.device!.body, 'humanoid');
    a.setArmed(true);
    await _until(a, () => a.liveTel.pos[2] > .7);
    expect(a.liveTel.pos[2], greaterThan(.7), reason: 'standing: hips at about 0.8 m');
    a.operatorMode('MANUAL');
    await _until(a, () {
      a.input[1] = -1; // crouch
      return a.liveTel.pos[2] < .7;
    });
    expect(a.liveTel.pos[2], lessThan(.7));
    await a.disconnect();
    a.dispose();
  });

  test('a boat sails a loop despite the current', () async {
    final d = await _connect(DeviceKind.boat);
    d.setArmed(true);
    final q = Sequence(
      id: 'loop',
      name: 'Loop',
      kind: DeviceKind.boat,
      steps: [
        SeqStep('goto', {'x': 20.0, 'y': 10.0}),
        SeqStep('goto', {'x': 0.0, 'y': 0.0}),
      ],
    );
    d.runSequence(q);
    final r = d.runner!;
    await _until(d, () => r.state == RunState.done || r.state == RunState.failed, maxMs: 30000);
    expect(r.state, RunState.done, reason: r.message);
    final p = d.liveTel.pos;
    expect(p[0] * p[0] + p[1] * p[1], lessThan(2.5 * 2.5), reason: 'back at the start');
    await d.disconnect();
    d.dispose();
  });
}
