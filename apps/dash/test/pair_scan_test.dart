import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koebelt_dash/core/dash.dart';
import 'package:koebelt_dash/screens/devices.dart';
import 'package:koebelt_dash/ui/mark.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('pairing keeps the searching loop up while the dialog is open, found or not', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final dash = Dash();
    await tester.runAsync(dash.init);
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (c) {
              ctx = c;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    showPairDialog(ctx, dash, (_) {});
    final searching = find.byWidgetPredicate((w) => w is MarkMotion && w.loop == MarkLoop.searching);
    // Long after the first pass, with nothing found, it is still scanning.
    for (var i = 0; i < 50; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(searching, findsOneWidget);
    // "Scanning Wi-Fi…", or "Still scanning…" once something answered (a
    // device on this network, another test's simulated one).
    expect(find.textContaining('SCANNING', findRichText: true), findsOneWidget);

    Navigator.of(ctx).pop();
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 6)); // the UDP ports linger 5 s after the scan
  });
}
