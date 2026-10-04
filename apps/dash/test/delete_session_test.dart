import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koebelt_dash/core/dash.dart';
import 'package:koebelt_dash/core/model.dart';
import 'package:koebelt_dash/screens/replay.dart';

void main() {
  testWidgets('deleting a session asks for confirmation', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final d = Dash();
    d.sessions.add(
      Recording(
        id: 's1',
        name: 'Bench run 4',
        deviceId: 'x',
        kind: DeviceKind.bench,
        deviceName: 'Thrust bench',
        date: '01 Oct · 11:00',
        frames: List.generate(30, (_) => <String, dynamic>{}),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListenableBuilder(listenable: d, builder: (_, _) => ReplayScreen(d, w: 1200, h: 900)),
        ),
      ),
    );

    final trash = find.bySemanticsLabel('Delete Bench run 4');
    expect(trash, findsOneWidget, reason: 'visible without hover, so touch screens can delete');

    await tester.tap(trash);
    await tester.pumpAndSettle();
    expect(find.text('Delete Bench run 4?'), findsOneWidget);
    expect(find.text('THRUST BENCH · 01 OCT · 11:00 · 00:03'), findsNWidgets(2)); // list row + dialog
    await tester.tap(find.text('CANCEL'));
    await tester.pumpAndSettle();
    expect(d.sessions, hasLength(1), reason: 'cancel keeps it');

    await tester.tap(trash);
    await tester.pumpAndSettle();
    await tester.tap(find.text('DELETE'));
    await tester.pumpAndSettle();
    expect(d.sessions, isEmpty);
    expect(find.text('Bench run 4'), findsNothing);
  });
}
