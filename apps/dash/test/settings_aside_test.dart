// Settings on a wide screen: the sections listed beside them. Pictures with
// CAPTURE_DIR=/tmp/x.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koebelt_dash/app.dart';
import 'package:koebelt_dash/core/dash.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _loadFonts() async {
  for (final fam in ['Archivo', 'JetBrainsMono']) {
    final l = FontLoader(fam);
    for (final w in [400, 500, 600, 700]) {
      l.addFont(rootBundle.load('assets/fonts/$fam-$w.ttf'));
    }
    await l.load();
  }
}

void main() {
  final shots = Platform.environment['CAPTURE_DIR'];

  testWidgets('the aside lists the sections, jumps to one, and follows the scroll', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.runAsync(_loadFonts);
    final d = Dash();
    await tester.runAsync(d.init);
    final key = GlobalKey();
    Future<void> show(Size size, double scale) async {
      tester.view.physicalSize = size * scale;
      tester.view.devicePixelRatio = scale;
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(brightness: Brightness.dark),
            home: Scaffold(body: DashApp(key: UniqueKey(), dash: d, initial: 'settings')),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    Future<void> shot(String name, double scale) async {
      if (shots == null) return;
      await tester.runAsync(() async {
        final b = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final img = await b.toImage(pixelRatio: scale);
        final png = await img.toByteData(format: ui.ImageByteFormat.png);
        await File('$shots/$name.png').writeAsBytes(png!.buffer.asUint8List());
      });
    }

    addTearDown(tester.view.reset);
    await show(const Size(1440, 900), 1);
    final aside = find.byWidgetPredicate((w) => w is Text && w.data == 'Updates' && w.style?.fontFamily != 'JetBrainsMono');
    expect(aside, findsOneWidget, reason: 'the aside lists Updates');
    expect(find.text('AI assistants'), findsOneWidget);
    await shot('settings_aside_top', 1);

    await tester.tap(find.text('AI assistants'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('Let assistants use koebelt dash'), findsOneWidget);
    expect(tester.getTopLeft(find.text('AI ASSISTANTS (MCP)')).dy, lessThan(900), reason: 'the section is in view');
    Color? highlight(String label) => (tester.widget<AnimatedContainer>(find.ancestor(of: find.text(label), matching: find.byType(AnimatedContainer)).first).decoration as BoxDecoration?)?.color;
    expect(highlight('AI assistants'), isNot(Colors.transparent), reason: 'the clicked section stays highlighted, though the page cannot scroll it to the top');
    expect(highlight('Updates'), Colors.transparent);
    await shot('settings_aside_jump', 1);

    // Scrolling by hand moves the highlight.
    await tester.drag(find.text('Let assistants use koebelt dash'), const Offset(0, 8000));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(highlight('Control'), isNot(Colors.transparent), reason: 'back at the top');
    await shot('settings_aside_scrolled', 1);

    // iPad held sideways has it; a phone does not.
    await show(const Size(1366, 1024), 2);
    expect(find.text('AI assistants'), findsOneWidget);
    await shot('settings_aside_ipad', 1);
    await show(const Size(440, 956), 2);
    expect(find.text('AI assistants'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 10));
  });
}
