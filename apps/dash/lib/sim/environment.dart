import 'dart:math' as math;

import '../core/model.dart';

/// Deterministic point-cloud world for a simulated device kind.
List<List<double>> genEnv(DeviceKind kind) {
  final pts = <List<double>>[];
  var s = (kind == DeviceKind.arm || kind == DeviceKind.bench) ? 3 : 7;
  double r() {
    s = (s * 9301 + 49297) % 233280;
    return s / 233280;
  }

  void box(double x0, double y0, double z0, double w, double d, double h, int n) {
    for (var i = 0; i < n; i++) {
      final f = (r() * 5).floor(), u = r(), v = r();
      pts.add(switch (f) {
        0 => [x0 + u * w, y0 + v * d, z0 + h],
        1 => [x0, y0 + u * d, z0 + v * h],
        2 => [x0 + w, y0 + u * d, z0 + v * h],
        3 => [x0 + u * w, y0, z0 + v * h],
        _ => [x0 + u * w, y0 + d, z0 + v * h],
      });
    }
  }

  void tree(double x, double y, double h, bool trunk) {
    for (var k = 0; k < 60; k++) {
      final a = r() * 6.28, b = r() * 3.14, rr = 1.2 + r() * .6;
      pts.add([x + math.cos(a) * math.sin(b) * rr, y + math.sin(a) * math.sin(b) * rr, h + math.cos(b) * rr]);
    }
    if (trunk) {
      for (var k = 0; k < 12; k++) {
        pts.add([x + (r() * 2 - 1) * .1, y + (r() * 2 - 1) * .1, r() * h]);
      }
    }
  }

  switch (kind) {
    case DeviceKind.bench:
      box(-.8, -.5, 0, 1.6, 1, .02, 500);
      box(-2, 1.4, 0, 4, .05, 2, 900);
      box(1.2, -.4, 0, .4, .5, .6, 200);
    case DeviceKind.rocket:
      for (var i = 0; i < 1800; i++) {
        pts.add([r() * 120 - 60, r() * 120 - 60, r() * .1]);
      }
      for (var i = 0; i < 14; i++) {
        final x = r() * 100 - 50, y = r() * 100 - 50, h = 3 + r() * 4;
        if (hypot2(x, y) < 12) continue;
        tree(x, y, h, false);
      }
    case DeviceKind.arm:
      box(0.6, -0.6, 0, 0.8, 1.2, 0.7, 700);
      box(-1.4, 0.5, 0, 0.6, 0.6, 0.5, 300);
      box(0.8, -0.2, 0.7, 0.15, 0.15, 0.12, 90);
      box(1.0, 0.25, 0.7, 0.12, 0.2, 0.1, 80);
      for (var i = 0; i < 900; i++) {
        final a = r() * math.pi * 2;
        pts.add([math.cos(a) * 2.4, math.sin(a) * 2.4, r() * 1.6]);
      }
    default:
      final rover = kind == DeviceKind.rover;
      final boxes = [
        for (var i = 0; i < 9; i++) [r() * 70 - 35, r() * 70 - 35, 4 + r() * 6, 4 + r() * 6, 2 + r() * (rover ? 4 : 12)],
      ];
      for (final b in boxes) {
        final n = ((b[2] * b[3] + 2 * (b[2] + b[3]) * b[4]) * 1.4).round();
        box(b[0], b[1], 0, b[2], b[3], b[4], n);
      }
      for (var i = 0; i < 22; i++) {
        tree(r() * 80 - 40, r() * 80 - 40, 3 + r() * 4, true);
      }
      for (var i = 0; i < 1400; i++) {
        pts.add([r() * 90 - 45, r() * 90 - 45, rover ? 0 : r() * .15]);
      }
  }
  return pts;
}

class SimTarget {
  SimTarget(this.id, this.r, this.a, this.va, this.vr);
  final String id;
  double r, a, va, vr;
}

List<SimTarget> genTargets(DeviceKind kind) => switch (kind) {
  DeviceKind.rocket || DeviceKind.bench || DeviceKind.generic => [],
  DeviceKind.arm => [SimTarget('OP-1', 1.9, 2.2, .05, 0)],
  _ => [SimTarget('T1', 18, .6, .04, .3), SimTarget('T2', 32, 2.4, -.02, -.4), SimTarget('T3', 24, 4.1, .03, 0), SimTarget('T4', 41, 5.3, .01, .2)],
};
