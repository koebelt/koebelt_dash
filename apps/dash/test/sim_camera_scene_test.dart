// The simulated camera shows things to track: a yellow ball and a person.
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koebelt_dash/core/model.dart';
import 'package:koebelt_dash/sim/sim_camera.dart';

void main() {
  /// RGBA of a frame from a rover at home, looking at [target] at time [t].
  Future<(ByteData, Uint8List)> frame(List<double> target, double t) async {
    final yaw = math.atan2(target[1], target[0]);
    final cam = SimCamera(kind: DeviceKind.rover, pose: () => CamPose([0, 0, .55], yaw, -.06, 0), world: const [], osd: () => '', now: () => t);
    final rec = ui.PictureRecorder();
    cam.paint(Canvas(rec), Size(SimCamera.w * 1.0, SimCamera.h * 1.0));
    final img = await rec.endRecording().toImage(SimCamera.w, SimCamera.h);
    final rgba = (await img.toByteData())!;
    final png = (await img.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
    img.dispose();
    return (rgba, png);
  }

  /// How many pixels look like [want] (r, g, b roughly).
  int count(ByteData d, bool Function(int r, int g, int b) want) {
    var n = 0;
    for (var i = 0; i < d.lengthInBytes; i += 4) {
      if (want(d.getUint8(i), d.getUint8(i + 1), d.getUint8(i + 2))) n++;
    }
    return n;
  }

  // The ball's yellow, not the home pad's lime (greener than red).
  bool yellow(int r, int g, int b) => r > 180 && g > 120 && g < r && b < 90;
  bool red(int r, int g, int b) => r > 150 && g < 80 && b < 80;

  testWidgets('a yellow ball and a person in red, where they are at that time', (tester) async {
    await tester.runAsync(() async {
      const t = 12.0;
      final (ball, ballPng) = await frame(SimCamera.ballAt(t), t);
      final (feet, _) = SimCamera.personAt(t);
      final (person, personPng) = await frame(feet, t);
      final dir = Platform.environment['CAPTURE_DIR'];
      if (dir != null) {
        File('$dir/ball.png').writeAsBytesSync(ballPng);
        File('$dir/person.png').writeAsBytesSync(personPng);
      }
      expect(count(ball, yellow), greaterThan(40), reason: 'the ball is in view');
      expect(count(person, red), greaterThan(40), reason: 'the person is in view');
      // Looking away from both: neither.
      final away = SimCamera.ballAt(t);
      final (empty, _) = await frame([-away[0] * 3, -away[1] * 3, 0], t);
      expect(count(empty, yellow), lessThan(5));
    });
  });

  test('they move', () {
    expect(SimCamera.ballAt(0), isNot(SimCamera.ballAt(3)));
    expect(SimCamera.personAt(0).$1, isNot(SimCamera.personAt(3).$1));
    final (p, _) = SimCamera.personAt(17);
    expect(math.sqrt(p[0] * p[0] + p[1] * p[1]), closeTo(10, 1e-9), reason: 'a 10 m circle round home');
  });
}
