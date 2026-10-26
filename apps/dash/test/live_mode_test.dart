// The mode control on Live: MANUAL takes the operator to Control.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koebelt_dash/app.dart';
import 'package:koebelt_dash/core/dash.dart';
import 'package:koebelt_dash/screens/control.dart';
import 'package:koebelt_dash/screens/live.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('choosing MANUAL on Live opens Control; HOLD stays', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final d = Dash();
    await tester.runAsync(() async {
      await d.init();
      final k = d.addSimulated(simTemplates().firstWhere((t) => t.id == 'kite'));
      await d.connect(k.id);
      await Future<void>.delayed(const Duration(milliseconds: 600));
    });
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DashApp(dash: d, initial: 'live'),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    Finder inBar(String text) => find.descendant(of: find.byType(LiveScreen), matching: find.text(text));

    await tester.tap(inBar('HOLD'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(LiveScreen), findsOneWidget, reason: 'HOLD stays on Live');

    await tester.tap(inBar('MANUAL'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(d.liveTel.mode, 'MANUAL');
    expect(find.byType(ControlScreen), findsOneWidget, reason: 'MANUAL opens Control, where the sticks are');

    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() async => d.disconnectAll());
    await tester.pump(const Duration(seconds: 10));
    tester.view.reset();
  });
}
