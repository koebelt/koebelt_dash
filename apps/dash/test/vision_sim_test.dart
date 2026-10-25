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
        if (o != null && o.isNotEmpty) offsets.add(o.first);
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
}
