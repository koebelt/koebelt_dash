import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koebelt_dash/app.dart';
import 'package:koebelt_dash/core/dash.dart';
import 'package:koebelt_dash/core/sequence.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('sequence steps reorder by dragging the grip', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final dash = Dash();
    late Sequence q;
    await tester.runAsync(() async {
      await dash.init();
      final dev = dash.addSimulated(simTemplates().first);
      await dash.connect(dev.id);
      q = dash.sequencesFor(dev.id).first;
    });
    final before = [for (final s in q.steps) s.type];
    expect(before.first, 'takeoff');

    tester.view.physicalSize = const Size(1440, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DashApp(dash: dash, initial: 'program'),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    // Drag the first step's grip below the third step.
    final grips = find.byTooltip('Drag to reorder');
    expect(grips, findsNWidgets(q.steps.length));
    final start = tester.getCenter(grips.at(0));
    final target = tester.getCenter(grips.at(2));
    final g = await tester.startGesture(start);
    await tester.pump(const Duration(milliseconds: 50));
    for (var k = 1; k <= 10; k++) {
      await g.moveTo(Offset.lerp(start, target + const Offset(0, 30), k / 10)!);
      await tester.pump(const Duration(milliseconds: 16));
    }
    await g.up();
    // The app's frame ticker never settles, so pump through the drop animation.
    for (var k = 0; k < 30; k++) {
      await tester.pump(const Duration(milliseconds: 30));
    }

    final after = [for (final s in q.steps) s.type];
    expect(after, isNot(before));
    // Steps differ in height and the list measures from the dragged row's
    // edge, so the exact slot depends on layout: check that it moved down.
    expect(after.indexOf('takeoff'), greaterThan(0), reason: '$after');
    expect(after.first, isNot('takeoff'));
    expect(after..sort(), [...before]..sort(), reason: 'same steps, new order');

    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() => dash.disconnect());
    await tester.pump(const Duration(seconds: 6));
  });
}
