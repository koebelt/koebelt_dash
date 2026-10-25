// The colour tracker example finds the simulated camera's yellow ball and
// steers the simulated rover to keep it centred. Needs a Python with
// koebelt-dash-scripts, OpenCV and NumPy: KDASH_VISION_PYTHON (skipped
// without; CI does not install OpenCV).
@TestOn('vm')
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:koebelt_dash/core/dash.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final python = Platform.environment['KDASH_VISION_PYTHON'];

  test(
    'the colour tracker sees the ball and keeps it centred',
    () async {
      SharedPreferences.setMockInitialValues({});
      final d = Dash();
      await d.init();
      final mule = d.addSimulated(simTemplates().firstWhere((t) => t.id == 'mule'));
      await d.connect(mule.id);
      await d.scripts.start(port: 0);
      final ticker = Timer.periodic(const Duration(milliseconds: 20), (_) => d.tick(.02));
      addTearDown(() async {
        ticker.cancel();
        for (final r in d.scripts.runs) {
          await r.stop();
        }
        await d.scripts.stop();
        await d.disconnectAll();
      });
      final run = await d.scripts.runFile(File('../../libs/python-dash-scripts/examples/colour_tracker.py').absolute, python: python);
      final l = d.links.values.single;
      String console() => run.console.map((c) => c.text).join('\n');
      final offsets = <double>[];
      for (var i = 0; i < 400; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        final o = l.tel.custom['script:offset'];
        if (o != null && o.isNotEmpty && (offsets.isEmpty || o.first != offsets.last)) offsets.add(o.first);
        if (offsets.length > 60 && offsets.skip(offsets.length - 20).every((x) => x.abs() < .12)) break;
      }
      expect(l.views['mask']?.image, isNotNull, reason: 'the mask is shown in Live. Console:\n${console()}');
      expect(offsets, isNotEmpty, reason: 'it found the ball. Console:\n${console()}');
      expect(
        offsets.skip(offsets.length - 20).every((x) => x.abs() < .12),
        isTrue,
        reason: 'it keeps it centred: ${offsets.skip(offsets.length - 20).map((x) => x.toStringAsFixed(2)).join(' ')}',
      );
      expect(run.console.where((c) => c.text.contains('Traceback')), isEmpty, reason: console());
    },
    skip: python == null ? 'no Python with OpenCV (KDASH_VISION_PYTHON)' : false,
    timeout: const Timeout(Duration(seconds: 60)),
  );

  test(
    'following the person: it turns towards them, not away',
    () async {
      SharedPreferences.setMockInitialValues({});
      final d = Dash();
      await d.init();
      final mule = d.addSimulated(simTemplates().firstWhere((t) => t.id == 'mule'));
      await d.connect(mule.id);
      await d.scripts.start(port: 0);
      final ticker = Timer.periodic(const Duration(milliseconds: 20), (_) => d.tick(.02));
      addTearDown(() async {
        ticker.cancel();
        for (final r in d.scripts.runs) {
          await r.stop();
        }
        await d.scripts.stop();
        await d.disconnectAll();
      });
      // follow_person.py with the red shirt found by colour instead of YOLO:
      // the same x (−0.5 left … 0.5 right) and the same steering.
      final dir = Directory.systemTemp.createTempSync('kdash_follow');
      final file = File('${dir.path}/follow_red.py')
        ..writeAsStringSync('''
import cv2
import numpy as np
from koebelt_dash_scripts import connect, pid

dev = connect()
dev.mode("MANUAL")
steer = pid(1.2, 0, 0.1)
last = 0.0
for frame in dev.camera.frames():
    h, w = frame.shape[:2]
    mask = cv2.inRange(cv2.cvtColor(frame, cv2.COLOR_BGR2HSV), np.array([0, 120, 80]), np.array([8, 255, 255]))
    contours, _ = cv2.findContours(mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    if not contours:
        dev.sticks(throttle=0, steer=0.4 if last >= 0 else -0.4)
        continue
    bx, by, bw, bh = cv2.boundingRect(max(contours, key=cv2.contourArea))
    x = (bx + bw / 2) / w - 0.5
    dev.plot("x", x)
    last = x
    near = bh / h > 0.6
    dev.sticks(throttle=0 if near else 0.4, steer=steer.update(x))
''');
      final run = await d.scripts.runFile(file, python: python);
      final l = d.links.values.single;
      final xs = <double>[];
      for (var i = 0; i < 400; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        final x = l.tel.custom['script:x'];
        if (x != null && x.isNotEmpty && (xs.isEmpty || x.first != xs.last)) xs.add(x.first);
        if (xs.length > 60 && xs.skip(xs.length - 20).every((v) => v.abs() < .12)) break;
      }
      final last = xs.skip(xs.length - 20).toList();
      expect(xs, isNotEmpty, reason: run.console.map((c) => c.text).join('\n'));
      expect(last.every((v) => v.abs() < .12), isTrue, reason: 'the person stays centred: ${last.map((v) => v.toStringAsFixed(2)).join(' ')}');
    },
    skip: python == null ? 'no Python with OpenCV (KDASH_VISION_PYTHON)' : false,
    timeout: const Timeout(Duration(seconds: 60)),
  );
}
