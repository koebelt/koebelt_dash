import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koebelt_dash/app.dart';
import 'package:koebelt_dash/core/dash.dart';
import 'package:koebelt_dash/screens/device_menu.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('device name opens a popover to switch, manage and pair', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final dash = Dash();
    await tester.runAsync(() async {
      await dash.init();
      final kite = dash.addSimulated(simTemplates()[0]);
      dash.addSimulated(simTemplates()[1]);
      await dash.connect(kite.id);
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
    await tester.pump(const Duration(milliseconds: 100));

    // Tapping the name opens the popover instead of the Devices screen.
    await tester.tap(find.descendant(of: find.byType(DeviceBtn), matching: find.text('Kite')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(DeviceMenu), findsOneWidget);
    expect(find.text('Devices'), findsNothing, reason: 'still on the Live screen');
    expect(find.text('SWITCH TO'), findsOneWidget);
    expect(find.text('DISCONNECT'), findsOneWidget);

    // Escape closes it.
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(DeviceMenu), findsNothing);

    // Switch to the rover from the list.
    await tester.tap(find.byType(DeviceBtn));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.descendant(of: find.byType(DeviceMenu), matching: find.text('Mule')));
    // Closing the first session (opened on real time) and opening the new
    // one (on the test clock) need both clocks to move.
    for (var i = 0; i < 40 && dash.device?.name != 'Mule'; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(dash.device?.name, 'Mule');
    expect(find.byType(DeviceMenu), findsOneWidget, reason: 'stays open showing the new active device');

    // Manage goes to the Devices screen and closes the popover.
    await tester.tap(find.text('MANAGE'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(DeviceMenu), findsNothing);
    expect(find.text('Devices'), findsWidgets);

    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() async {
      await dash.disconnect();
      await Future<void>.delayed(const Duration(milliseconds: 300)); // simulators detach 100 ms later
    });
    await tester.pump(const Duration(seconds: 6));
  });
}
