import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:koebelt_dash/core/model.dart';
import 'package:koebelt_dash/core/telemetry.dart';

/// Simulates the render loop: a device sends 30 Hz samples with network
/// jitter, the screen draws at 120 fps. Returns per-frame rendered steps (m).
List<double> run({required double speed, required bool jitter, required double velError}) {
  final t = Telemetry(DeviceKind.rocket);
  final rnd = math.Random(3);
  const frame = 1 / 120, period = 1 / 30;
  var now = 0.0, nextSend = 0.0, deviceT = 0.0;
  final pending = <(double, double)>[]; // (arrival time, device time)
  final steps = <double>[];
  double? last;
  while (now < 3) {
    while (nextSend <= now) {
      deviceT = nextSend;
      final delay = .02 + (jitter ? rnd.nextDouble() * .016 - .008 : 0);
      pending.add((nextSend + delay, deviceT));
      nextSend += period;
    }
    pending.sort((a, b) => a.$1.compareTo(b.$1));
    while (pending.isNotEmpty && pending.first.$1 <= now) {
      final dt = pending.removeAt(0).$2;
      t.applyTlm({
        'pos': [0.0, 0.0, speed * dt],
        'vel': [0.0, 0.0, speed * (1 + velError)],
      }, ts: dt * 1000);
    }
    t.animate(frame);
    now += frame;
    final z = t.rPos[2];
    if (last != null && now > .5) steps.add(z - last);
    last = z;
  }
  return steps;
}

void main() {
  test('fast objects move smoothly between jittery 30 Hz samples', () {
    const speed = 150.0, ideal = speed / 120; // 1.25 m per frame
    final smooth = run(speed: speed, jitter: true, velError: .05);
    final worst = smooth.map((s) => (s - ideal).abs()).reduce(math.max);
    // Without smoothing a frame would move 0 m or ~5 m (one 30 Hz sample).
    expect(worst, lessThan(ideal * .35), reason: 'max per-frame deviation $worst m');
    expect(smooth.every((s) => s > 0), isTrue, reason: 'never stalls or goes backwards');
  });

  test('a new sample that disagrees is faded in, not snapped', () {
    final t = Telemetry(DeviceKind.drone);
    t.applyTlm({
      'pos': [0.0, 0.0, 10.0],
      'vel': [0.0, 0.0, 0.0],
    }, ts: 0);
    for (var i = 0; i < 10; i++) {
      t.animate(1 / 60);
    }
    t.applyTlm({
      'pos': [2.0, 0.0, 10.0],
      'vel': [0.0, 0.0, 0.0],
    }, ts: 170);
    t.animate(1 / 60);
    expect(t.rPos[0], lessThan(.5), reason: 'no 2 m jump in one frame');
    for (var i = 0; i < 60; i++) {
      t.animate(1 / 60);
    }
    expect(t.rPos[0], closeTo(2, .01), reason: 'converges to the reported position');
  });
}
