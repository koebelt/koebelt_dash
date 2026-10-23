// The add-a-script-host dialog while it looks for hosts. Picture with CAPTURE_DIR=/tmp/x.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koebelt_dash/core/dash.dart';
import 'package:koebelt_dash/screens/script_dialogs.dart';
import 'package:koebelt_dash/ui/mark.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final shots = Platform.environment['CAPTURE_DIR'];

  testWidgets('the searching mark shows while it looks for hosts', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.runAsync(() async {
      for (final fam in ['Archivo', 'JetBrainsMono']) {
        final l = FontLoader(fam);
        for (final w in [400, 500, 600, 700]) {
          l.addFont(rootBundle.load('assets/fonts/$fam-$w.ttf'));
        }
        await l.load();
      }
    });
    final d = Dash();
    await tester.runAsync(d.init);
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(brightness: Brightness.dark),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(child: TextButton(onPressed: () => showAddHostDialog(context, d), child: const Text('open'))),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('LOOKING FOR SCRIPT HOSTS'), findsOneWidget);
    expect(find.byWidgetPredicate((w) => w is MarkMotion && w.loop == MarkLoop.searching), findsOneWidget);
    if (shots != null) {
      await tester.runAsync(() async {
        final b = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final img = await b.toImage();
        final png = await img.toByteData(format: ui.ImageByteFormat.png);
        await File('$shots/add_host_searching.png').writeAsBytes(png!.buffer.asUint8List());
      });
    }
    // Let the look finish and the dialog settle.
    await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 2)));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  });
}
