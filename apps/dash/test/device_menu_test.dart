import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koebelt_dash/app.dart';
import 'package:koebelt_dash/core/dash.dart';
import 'package:koebelt_dash/core/model.dart';
import 'package:koebelt_dash/screens/device_menu.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('device name opens a popover to connect more, switch, manage and pair', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final dash = Dash();
    late final DeviceInfo kite;
    await tester.runAsync(() async {
      await dash.init();
      kite = dash.addSimulated(simTemplates()[0]);
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
    expect(find.text('CONNECT ANOTHER'), findsOneWidget);
    expect(find.text('DISCONNECT'), findsOneWidget);

    // Escape closes it.
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(DeviceMenu), findsNothing);

    // Connect the rover too: the drone stays connected, the rover is shown.
    await tester.tap(find.byType(DeviceBtn));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.descendant(of: find.byType(DeviceMenu), matching: find.text('Mule')));
    // Opening the new session (on the test clock) needs both clocks to move.
    for (var i = 0; i < 40 && dash.device?.name != 'Mule'; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(dash.device?.name, 'Mule');
    expect(dash.links.keys, containsAll([kite.id, dash.deviceId]), reason: 'both connected');
    expect(find.byType(DeviceMenu), findsOneWidget, reason: 'stays open showing the new active device');
    expect(find.text('ALSO CONNECTED'), findsOneWidget);
    expect(find.textContaining('+1 CONNECTED'), findsOneWidget);

    // Back to the drone from "Also connected": a switch, no reconnect.
    await tester.tap(find.descendant(of: find.byType(DeviceMenu), matching: find.text('Kite')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(dash.deviceId, kite.id);
    expect(dash.links, hasLength(2));

    // Manage goes to the Devices screen and closes the popover.
    await tester.tap(find.text('MANAGE'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(DeviceMenu), findsNothing);
    expect(find.text('Devices'), findsWidgets);

    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() async {
      await dash.disconnectAll();
      await Future<void>.delayed(const Duration(milliseconds: 300)); // simulators detach 100 ms later
    });
    await tester.pump(const Duration(seconds: 6));
  });
}
