import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koebelt_dash/app.dart';
import 'package:koebelt_dash/core/dash.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // Control, Program and Tune act on a live device. During a replay they used
  // to mix the recording's kind with the live device (or crash without one).
  for (final connected in [false, true]) {
    testWidgets('Control, Program and Tune wait while a replay plays (${connected ? 'device connected' : 'no device'})', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final dash = Dash();
      await tester.runAsync(() async {
        await dash.init();
        final kite = dash.addSimulated(simTemplates()[0]);
        dash.loadSamples();
        if (connected) await dash.connect(kite.id);
      });
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final arm = dash.sessions.firstWhere((s) => s.kind != dash.device?.kind);
      for (final screen in ['control', 'program', 'params']) {
        dash.openReplay(arm.id);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DashApp(key: UniqueKey(), dash: dash, initial: screen),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull, reason: screen);
        expect(find.byType(ReplayHold), findsOneWidget, reason: screen);
        expect(find.textContaining('off during a replay'), findsOneWidget, reason: screen);

        await tester.tap(find.textContaining('EXIT REPLAY'));
        await tester.pump(const Duration(milliseconds: 100));
        expect(dash.replay, isNull);
        expect(find.byType(ReplayHold), findsNothing, reason: screen);
        expect(find.text('No device connected'), connected ? findsNothing : findsOneWidget, reason: screen);
      }
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(() async => dash.disconnectAll());
      await tester.pump(const Duration(seconds: 10));
    });
  }
}
