import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koebelt_dash/core/dash.dart';
import 'package:koebelt_dash/screens/guides.dart';
import 'package:koebelt_dash/screens/guides_data.dart';

Future<void> show(WidgetTester tester, Size size, VoidCallback back) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  final g = guides.firstWhere((x) => x.id == 'ex-drone');
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: GuideView(Dash(), g: g, w: size.width, go: (_) {}, back: back),
      ),
    ),
  );
  await tester.pump();
}

/// The guide's own vertical scroller (code blocks scroll sideways).
final page = find.byWidgetPredicate((w) => w is SingleChildScrollView && w.scrollDirection == Axis.vertical && w.controller != null);

bool onScreen(WidgetTester tester, Finder f, Size size) {
  final r = tester.getRect(f);
  return r.top >= 0 && r.bottom <= size.height;
}

void main() {
  testWidgets('wide: back button and steps index stay put while the guide scrolls', (tester) async {
    const size = Size(1300, 800);
    addTearDown(tester.view.reset);
    var backs = 0;
    await show(tester, size, () => backs++);
    final back = find.text('ALL GUIDES');
    final lastStep = guides.firstWhere((x) => x.id == 'ex-drone').steps.last.t;
    final indexEntry = find.text(lastStep).first; // the index entry comes first in the tree
    final before = tester.getRect(back);

    await tester.drag(page, const Offset(0, -20000));
    await tester.pumpAndSettle();

    expect(tester.getRect(back), before, reason: 'back button did not move');
    expect(onScreen(tester, indexEntry, size), isTrue, reason: 'steps index still visible');
    final numbers = find.text((guides.firstWhere((x) => x.id == 'ex-drone').steps.length).toString().padLeft(2, '0'));
    expect(numbers, findsWidgets);

    // Jumping from the index scrolls the content, the index itself stays.
    await tester.tap(find.text('What the app gives you').first);
    await tester.pumpAndSettle();
    expect(tester.getRect(back), before);

    await tester.tap(back);
    expect(backs, 1);
  });

  testWidgets('phone: back bar stays at the top and shows progress', (tester) async {
    const size = Size(390, 844);
    addTearDown(tester.view.reset);
    await show(tester, size, () {});
    final back = find.text('ALL GUIDES');
    final before = tester.getRect(back);
    expect(find.text('STEP 1 OF 4'), findsOneWidget);
    await tester.drag(page, const Offset(0, -40000));
    await tester.pumpAndSettle();
    expect(tester.getRect(back), before);
    expect(find.text('STEP 4 OF 4'), findsOneWidget);
  });
}
