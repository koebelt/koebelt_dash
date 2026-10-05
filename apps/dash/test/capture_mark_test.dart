// Renders the mark and its loops for review.
// Run:  CAPTURE_DIR=/tmp/shots flutter test test/capture_mark_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koebelt_dash/theme/tokens.dart';
import 'package:koebelt_dash/ui/components.dart';
import 'package:koebelt_dash/ui/mark.dart';

void main() {
  final dir = Platform.environment['CAPTURE_DIR'];
  testWidgets('capture mark', (tester) async {
    if (dir == null) return;
    await tester.runAsync(() async {
      for (final fam in ['Archivo', 'JetBrainsMono']) {
        final l = FontLoader(fam);
        for (final w in [400, 500, 600, 700]) {
          l.addFont(rootBundle.load('assets/fonts/$fam-$w.ttf'));
        }
        await l.load();
      }
    });
    tester.view.physicalSize = const Size(1200, 760);
    tester.view.devicePixelRatio = 1;
    final key = GlobalKey();
    Widget cell(String label, Widget w) => Container(
      width: 190,
      height: 220,
      color: K.surfacePage,
      alignment: Alignment.center,
      child: Column(mainAxisSize: MainAxisSize.min, children: [w, const SizedBox(height: 12), MonoLabel(label)]),
    );
    final progress = ValueNotifier(0.0);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Material(
          color: K.surfaceDeep,
          child: RepaintBoundary(
            key: key,
            child: Container(
              color: K.surfaceDeep,
              padding: const EdgeInsets.all(10),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  cell('static', const Mark(size: 120)),
                  cell('brand', const Brand()),
                  cell('boot', const MarkMotion(MarkLoop.boot, size: 140)),
                  cell('loading', const MarkMotion(MarkLoop.loading, size: 140)),
                  cell(
                    'progress',
                    ValueListenableBuilder(
                      valueListenable: progress,
                      builder: (_, p, _) => MarkMotion(MarkLoop.progress, size: 140, progress: p),
                    ),
                  ),
                  cell('searching', const MarkMotion(MarkLoop.searching, size: 140)),
                  cell('link lost', const MarkMotion(MarkLoop.link, size: 140)),
                  cell('gizmo', const MarkMotion(MarkLoop.gizmo, size: 180)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    Future<void> shot(String name) async {
      await tester.runAsync(() async {
        final b = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final img = await b.toImage();
        final png = await img.toByteData(format: ui.ImageByteFormat.png);
        await File('$dir/mark_$name.png').writeAsBytes(png!.buffer.asUint8List());
      });
    }

    for (final (ms, p) in [(300, .1), (1000, .4), (2600, .8), (5600, 1.0), (9400, 1.0)]) {
      progress.value = p;
      // Advance in frames so the organic follow settles like it would live.
      for (var i = 0; i < 20; i++) {
        await tester.pump(Duration(milliseconds: (ms / 20).round()));
      }
      await shot('$ms');
    }
    await tester.pumpWidget(const SizedBox());
    tester.view.reset();
  });
}
