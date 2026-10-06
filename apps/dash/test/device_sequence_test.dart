// Sequences stored on and run by the device (protocol/PROTOCOL.md,
// "Sequences on the device"), against the simulator's device side.
import 'package:flutter_test/flutter_test.dart';
import 'package:koebelt_dash/core/dash.dart';
import 'package:koebelt_dash/core/model.dart';
import 'package:koebelt_dash/core/sequence.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _until(Dash d, bool Function() done, {int maxMs = 30000}) async {
  final sw = Stopwatch()..start();
  while (!done() && sw.elapsedMilliseconds < maxMs) {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    d.tick(.02);
  }
}

Future<Dash> _drone() async {
  SharedPreferences.setMockInitialValues({});
  final d = Dash();
  await d.init();
  final dev = d.addSimulated(simTemplates().firstWhere((t) => t.kind == DeviceKind.drone));
  await d.connect(dev.id);
  d.setSpeed(1);
  await _until(d, () => false, maxMs: 300);
  return d;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('steps survive the wire format', () {
    for (final kind in DeviceKind.values) {
      for (final def in stepDefs(kind)) {
        final s = SeqStep.fresh(def);
        if (def.type == 'cmd') s.p['name'] = 'beep';
        final back = SeqStep.fromWire(s.toWire(kind));
        expect(back.type, s.type);
        for (final k in s.p.keys) {
          if (kind != DeviceKind.drone && def.type == 'goto' && k == 'z') continue;
          final a = s.p[k], b = back.p[k];
          if (a is num) {
            expect((b as num).toDouble(), closeTo(a.toDouble(), 1e-6), reason: '${def.type}.$k');
          } else {
            expect(b, a, reason: '${def.type}.$k');
          }
        }
      }
    }
  });

  test('a drone flies a stored sequence through a lost link', () async {
    final d = await _drone();
    expect(d.seqCap, greaterThan(0));
    final q = Sequence(
      id: 'hop',
      name: 'Hop',
      kind: DeviceKind.drone,
      steps: [
        SeqStep('takeoff', {'alt': 3.0}),
        SeqStep('goto', {'x': 4.0, 'y': 0.0, 'z': 3.0}),
        SeqStep('wait', {'s': .5}),
        SeqStep('land', {}),
      ],
    );
    d.runSequence(q);
    final r = d.runner!;
    expect(r.onDevice, isTrue);
    await _until(d, () => r.index >= 1);
    expect(r.state, RunState.running);
    // Withhold the control heartbeat: an app-run sequence would pause and the
    // device would fail over to HOLD after 1.8 s. This one carries on.
    d.dropLink();
    await _until(d, () => d.linkLost);
    await _until(d, () => r.state == RunState.done || r.state == RunState.failed, maxMs: 40000);
    expect(r.state, RunState.done, reason: r.message);
    expect(d.liveTel.pos[0], closeTo(4, 1.2));
    expect(d.liveTel.armed, isFalse, reason: 'landed and disarmed');
    await d.disconnect();
    d.dispose();
  });

  test('pause, resume and stop from the app', () async {
    final d = await _drone();
    final q = Sequence(
      id: 'w',
      name: 'Wait',
      kind: DeviceKind.drone,
      steps: [
        SeqStep('wait', {'s': 30.0}),
      ],
    );
    d.runSequence(q);
    final r = d.runner!;
    await _until(d, () => !(r as DeviceSequenceRunner).uploading && r.state == RunState.running && (r.stepProgress ?? 0) > 0);
    r.pause();
    await _until(d, () => r.state == RunState.paused, maxMs: 3000);
    expect(r.state, RunState.paused);
    r.resume();
    await _until(d, () => r.state == RunState.running, maxMs: 3000);
    expect(r.state, RunState.running);
    r.stop('Stopped from the app');
    await _until(d, () => false, maxMs: 1200);
    expect(r.state, RunState.failed);
    await d.disconnect();
    d.dispose();
  });

  test('a step the device cannot store runs from the app instead', () async {
    final d = await _drone();
    // A pose step means nothing to a drone: the device declines the upload.
    final q = Sequence(
      id: 'odd',
      name: 'Odd',
      kind: DeviceKind.drone,
      steps: [
        SeqStep('wait', {'s': .2}),
        SeqStep('pose', {'j1': 0.0}),
      ],
    );
    d.runSequence(q);
    await _until(d, () => d.runner != null && !d.runner!.onDevice, maxMs: 3000);
    expect(d.runner!.onDevice, isFalse);
    expect(d.runner!.message, contains('Running from the app'));
    await d.disconnect();
    d.dispose();
  });

  test('reconnecting picks up a sequence still running on the device', () async {
    final d = await _drone();
    final q = Sequence(
      id: 'long',
      name: 'Long wait',
      kind: DeviceKind.drone,
      steps: [
        SeqStep('wait', {'s': 30.0}),
      ],
    );
    d.sequencesFor(d.deviceId!).add(q);
    d.runSequence(q);
    await _until(d, () => !(d.runner as DeviceSequenceRunner).uploading && d.runner!.state == RunState.running);
    final id = d.deviceId!;
    await d.disconnect();
    expect(d.runner, isNull);
    await d.connect(id);
    await _until(d, () => d.runner != null, maxMs: 3000);
    expect(d.runner?.seq.id, 'long');
    expect(d.runner?.state, RunState.running);
    d.runner!.stop('done');
    await d.disconnect();
    d.dispose();
  });
}
