import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koebelt_dash/ui/mark.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('boot splash lands, fades and leaves the app', (tester) async {
    await tester.pumpWidget(_host(const BootSplash(child: Text('app'))));
    expect(find.byType(MarkMotion), findsOneWidget);
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(MarkMotion), findsNothing);
    expect(find.text('app'), findsOneWidget);
  });

  testWidgets('reduced motion: no splash, static mark for loops', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: _host(
          const Column(
            children: [
              BootSplash(child: Text('app')),
              MarkMotion(MarkLoop.loading),
            ],
          ),
        ),
      ),
    );
    expect(find.text('app'), findsOneWidget);
    expect(find.byType(Mark), findsOneWidget);
  });

  testWidgets('link mark keeps its state from lost to restored', (tester) async {
    Widget at(bool lost) => _host(MarkMotion(MarkLoop.link, key: const ValueKey('l'), lost: lost));
    await tester.pumpWidget(at(true));
    await tester.pump(const Duration(seconds: 1));
    final s = tester.state(find.byType(MarkMotion));
    await tester.pumpWidget(at(false));
    await tester.pump(const Duration(seconds: 1));
    expect(tester.state(find.byType(MarkMotion)), same(s));
  });

  testWidgets('every loop paints', (tester) async {
    await tester.pumpWidget(_host(Wrap(children: [for (final l in MarkLoop.values) MarkMotion(l, size: 40, progress: .5)])));
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(tester.takeException(), isNull);
  });
}
