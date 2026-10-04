import 'package:flutter_test/flutter_test.dart';
import 'package:koebelt_dash/core/model.dart';
import 'package:koebelt_dash/core/sequence.dart';
import 'package:koebelt_dash/core/telemetry.dart';
import 'package:koebelt_dash/link/protocol.dart';
import 'package:koebelt_dash/link/session.dart';
import 'package:koebelt_dash/link/transport.dart';
import 'package:koebelt_dash/sim/sim_device.dart';

/// A minimal app: session + telemetry, driving the runner over the real protocol.
class Host implements SequenceHost {
  Host(this.s, this.t);
  final DeviceSession s;
  final Telemetry t;
  @override
  List<double> get seqPos => t.pos;
  @override
  List<double> get seqJoints => t.joints;
  @override
  String get seqMode => t.mode;
  @override
  bool get seqArmed => t.armed;
  @override
  bool get seqStopped => t.estop;
  @override
  bool get seqLinkLost => false;
  @override
  void seqSetMode(String m) {
    s.send({'t': 'mode', 'm': m});
    t.mode = m;
  }

  @override
  void seqSetArmed(bool v) {
    s.send({'t': 'arm', 'v': v});
    t.armed = v;
  }

  @override
  void seqSetSpeed(double v) => s.send({'t': 'speed', 'v': v});
  @override
  void seqCmd(String c, Map<String, dynamic> a) => s.send({'t': 'cmd', 'c': c, 'a': a});
}

Future<(Host, SimDevice)> connect(DeviceKind kind) async {
  final sim = SimDevice(DeviceInfo(id: 'x', name: 'X', kind: kind));
  final lt = LoopbackTransport('test');
  sim.attach(lt);
  final t = Telemetry(kind);
  final s = DeviceSession(
    lt,
    onMessage: (Msg m) {
      if (m['t'] == 'tlm') t.applyTlm((m['d'] as Map).cast<String, dynamic>());
      if (m['t'] == 'state') t.applyState(m);
    },
  );
  await s.open();
  s.send({'t': 'speed', 'v': 1.0});
  await Future<void>.delayed(const Duration(milliseconds: 200));
  return (Host(s, t), sim);
}

Future<SequenceRunner> run(Sequence q, Host h, {int maxMs = 30000, void Function(SequenceRunner)? during}) async {
  final r = SequenceRunner(q, h);
  final sw = Stopwatch()..start();
  while ((r.state == RunState.running || r.state == RunState.paused) && sw.elapsedMilliseconds < maxMs) {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    r.tick(.02);
    during?.call(r);
  }
  return r;
}

void main() {
  test('drone: take off, fly to a waypoint, land', () async {
    final (h, sim) = await connect(DeviceKind.drone);
    sim.pos = [0, 0, 0];
    final q = Sequence(
      id: 'a',
      name: 'hop',
      kind: DeviceKind.drone,
      steps: [
        SeqStep('takeoff', {'alt': 5.0}),
        SeqStep('goto', {'x': 6.0, 'y': 4.0, 'z': 5.0}),
        SeqStep('land', {}),
      ],
    );
    final r = await run(q, h);
    expect(r.state, RunState.done, reason: r.message);
    expect(hypot2(sim.pos[0] - 6, sim.pos[1] - 4), lessThan(1.2));
    expect(sim.pos[2], lessThan(.2));
    expect(sim.armed, isFalse, reason: 'landing disarms');
    await h.s.close();
    sim.detach();
  }, timeout: const Timeout(Duration(seconds: 40)));

  test('arm: move to pose, gripper, home', () async {
    final (h, sim) = await connect(DeviceKind.arm);
    final q = Sequence(
      id: 'b',
      name: 'pick',
      kind: DeviceKind.arm,
      steps: [
        SeqStep('pose', {'j1': 40.0, 'j2': -10.0, 'j3': 80.0, 'j4': 0.0, 'j5': 60.0, 'j6': 0.0}),
        SeqStep('gripper', {'open': 10.0}),
        SeqStep('home', {}),
      ],
    );
    List<double>? atPose;
    final r = await run(
      q,
      h,
      during: (r) {
        if (r.index == 1 && atPose == null) atPose = List.of(sim.joints);
      },
    );
    expect(r.state, RunState.done, reason: r.message);
    expect(atPose![0] * 57.3, closeTo(40, 2));
    expect(sim.gripper, closeTo(.1, 1e-6));
    expect(sim.joints[1], closeTo(-.5, .03));
    await h.s.close();
    sim.detach();
  }, timeout: const Timeout(Duration(seconds: 40)));

  test('bench: throttle hold and ramp reach the motor', () async {
    final (h, sim) = await connect(DeviceKind.bench);
    final q = Sequence(
      id: 'c',
      name: 'ramp',
      kind: DeviceKind.bench,
      steps: [
        SeqStep('arm', {'v': 'ARM'}),
        SeqStep('throttle', {'pct': 30.0, 's': 1.0}),
        SeqStep('ramp', {'from': 30.0, 'to': 60.0, 's': 1.0}),
      ],
    );
    var peak = 0.0;
    final r = await run(q, h, during: (_) => peak = peak > sim.thrOut ? peak : sim.thrOut);
    expect(r.state, RunState.done, reason: r.message);
    expect(peak, closeTo(.6, .03));
    await h.s.close();
    sim.detach();
  });

  test('emergency stop aborts a running sequence', () async {
    final (h, sim) = await connect(DeviceKind.rover);
    sim.armed = true;
    final q = Sequence(
      id: 'd',
      name: 'far',
      kind: DeviceKind.rover,
      steps: [
        SeqStep('goto', {'x': 200.0, 'y': 0.0}),
      ],
    );
    var sent = false;
    final r = await run(
      q,
      h,
      maxMs: 5000,
      during: (_) {
        if (!sent) {
          sent = true;
          Future<void>.delayed(const Duration(milliseconds: 300), h.s.sendStop);
        }
      },
    );
    expect(r.state, RunState.failed);
    expect(r.message, contains('emergency stop'));
    expect(sim.estop, isTrue);
    await h.s.close();
    sim.detach();
  });

  test('set home: vehicle frame restarts at the current position', () async {
    final (h, sim) = await connect(DeviceKind.rover);
    sim.armed = true;
    h.seqSetMode('HOLD');
    await Future<void>.delayed(const Duration(milliseconds: 100));
    sim.pos = [12, -7, 0];
    sim.vel = [0, 0, 0];
    h.seqCmd('sethome', {});
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(h.t.pos[0].abs() + h.t.pos[1].abs(), lessThan(.2), reason: 'reported position is relative to the new home');
    final q = Sequence(
      id: 'h',
      name: 'h',
      kind: DeviceKind.rover,
      steps: [
        SeqStep('goto', {'x': 3.0, 'y': 0.0}),
      ],
    );
    final r = await run(q, h);
    expect(r.state, RunState.done, reason: r.message);
    expect(sim.pos[0], closeTo(15, .7), reason: 'waypoint measured from the new home');
    expect(sim.pos[1], closeTo(-7, .7));
    await h.s.close();
    sim.detach();
  }, timeout: const Timeout(Duration(seconds: 40)));

  test('set home pose: the Home step returns to it', () async {
    final (h, sim) = await connect(DeviceKind.arm);
    final custom = [0.5, -0.3, 0.9, 0.2, 0.4, 1.0];
    h.seqCmd('sethome', {'j': custom});
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final q = Sequence(
      id: 'p',
      name: 'p',
      kind: DeviceKind.arm,
      steps: [
        SeqStep('pose', {'j1': -30.0, 'j2': -10.0, 'j3': 60.0, 'j4': 0.0, 'j5': 30.0, 'j6': 0.0}),
        SeqStep('home', {}),
      ],
    );
    final r = await run(q, h);
    expect(r.state, RunState.done, reason: r.message);
    for (var i = 0; i < 6; i++) {
      expect(sim.joints[i], closeTo(custom[i], .03));
    }
    await h.s.close();
    sim.detach();
  }, timeout: const Timeout(Duration(seconds: 40)));

  test('examples and summaries cover every kind', () {
    for (final k in DeviceKind.values) {
      for (final d in stepDefs(k)) {
        expect(SeqStep.fresh(d).summary(k), isNotEmpty);
      }
    }
    expect(exampleSequences('kite', DeviceKind.drone).single.steps, isNotEmpty);
  });
}
