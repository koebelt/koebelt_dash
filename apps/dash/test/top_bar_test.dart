// The top bar at its fullest on a desktop: two devices (STOP ALL, +1
// connected) and an alert chip. The test font is wider than the app's, so
// what fits here fits in every language.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koebelt_dash/app.dart';
import 'package:koebelt_dash/core/dash.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('a wide top bar fits two devices and an alert, in the wide test font', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final dash = Dash();
    await tester.runAsync(() async {
      await dash.init();
      final kite = dash.addSimulated(simTemplates()[0]);
      final mule = dash.addSimulated(simTemplates()[1]);
      await dash.connect(kite.id);
      await dash.connect(mule.id);
      dash.updateAlerts((p) => p.limit['latency'] = 1);
      await Future<void>.delayed(const Duration(milliseconds: 1500));
    });
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DashApp(dash: dash, initial: 'live'),
        ),
      ),
    );
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      dash.tick(.1);
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(dash.alerts.shown, isNotEmpty, reason: 'the alert chip shows');
  });
}
