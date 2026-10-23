import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:koebelt_dash/viz/scene3d.dart';

void main() {
  // The scene's camera transform (scene3d.dart): world (x east, y north) to
  // camera [right, depth].
  (double, double) toCamera(double camYaw, double x, double y) {
    final c = math.cos(camYaw), s = math.sin(camYaw);
    return (c * x + s * y, -s * x + c * y);
  }

  test('the chase camera looks along the drone’s heading, whichever way it faces', () {
    for (var deg = -180; deg <= 180; deg += 15) {
      final yaw = deg * math.pi / 180;
      final (right, depth) = toCamera(chaseYaw(yaw), math.cos(yaw), math.sin(yaw));
      expect(depth, closeTo(1, 1e-9), reason: 'forward is into the screen at $deg°');
      expect(right, closeTo(0, 1e-9));
    }
  });

  test('when the drone yaws, the camera turns with it, by the same amount', () {
    expect(chaseYaw(1.0) - chaseYaw(.5), closeTo(.5, 1e-12));
  });
}
