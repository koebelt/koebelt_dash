import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koebelt_dash/core/dash.dart';
import 'package:koebelt_dash/core/model.dart';
import 'package:koebelt_dash/core/telemetry.dart';
import 'package:koebelt_dash/screens/tiles.dart';
import 'package:koebelt_dash/viz/viz.dart';

Dash withHistory() {
  final d = Dash();
  d.liveTel = Telemetry(DeviceKind.drone);
  for (var i = 0; i < 300; i++) {
    d.liveTel.acc = [math.sin(i / 20) * 2, math.cos(i / 15), 9.81 + math.sin(i / 7) * .5];
    d.hist.sample(d.liveTel, 0);
  }
  return d;
}

void main() {
  testWidgets('tapping a tile still opens it; a drag over its chart does not', (tester) async {
    final d = withHistory();
    var opened = 0;
    final tile = tiles.firstWhere((t) => t.id == 'accel');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(width: 320, height: 180, child: Tile(d, tile, onOpen: () => opened++)),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(LineChart));
    await tester.pump();
    expect(opened, 1, reason: 'tap on the chart opens the tile');
    final c = tester.getCenter(find.byType(LineChart));
    await tester.dragFrom(c, const Offset(60, 0));
    await tester.pump();
    expect(opened, 1, reason: 'horizontal drag inspects instead of opening');
  });

  testWidgets('hover shows the readout (rendered for review)', (tester) async {
    final dir = Platform.environment['CAPTURE_DIR'];
    await tester.runAsync(() async {
      for (final f in ['Archivo', 'JetBrainsMono']) {
        final l = FontLoader(f);
        for (final w in [400, 500, 600, 700]) {
          l.addFont(rootBundle.load('assets/fonts/$f-$w.ttf'));
        }
        await l.load();
      }
    });
    final d = withHistory();
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFF1D1A1B),
          body: Center(
            child: RepaintBoundary(
              key: key,
              child: Container(
                color: const Color(0xFF1D1A1B),
                padding: const EdgeInsets.all(16),
                width: 560,
                height: 240,
                child: LineChart(d, keys: const ['ax', 'ay', 'az'], sym: true, pinnable: true),
              ),
            ),
          ),
        ),
      ),
    );
    final r = tester.getRect(find.byType(LineChart));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(Offset(r.left + r.width * .62, r.center.dy));
    await tester.pump();
    if (dir != null) {
      await tester.runAsync(() async {
        final b = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final img = await b.toImage();
        final png = await img.toByteData(format: ui.ImageByteFormat.png);
        await Directory(dir).create(recursive: true);
        await File('$dir/chart_hover.png').writeAsBytes(png!.buffer.asUint8List());
      });
    }
    await mouse.removePointer();
    d.dispose();
  });
}
