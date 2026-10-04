// Renders every screen at the design's frame sizes and writes PNGs.
// Run:  CAPTURE_DIR=/tmp/shots flutter test test/capture_test.dart
// Skipped when CAPTURE_DIR is not set.
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
  for (final fam in {'Archivo': 'Archivo', 'JetBrainsMono': 'JetBrainsMono'}.entries) {
    final l = FontLoader(fam.key);
    for (final w in [400, 500, 600, 700]) {
      l.addFont(rootBundle.load('assets/fonts/${fam.value}-$w.ttf'));
    }
    await l.load();
  }
}

void main() {
  final dir = Platform.environment['CAPTURE_DIR'];
  final sizes = {'phone': const Size(390, 844), 'tablet': const Size(1180, 820), 'desktop': const Size(1440, 900)};
  final shots = <List<String>>[
    // [device, screen, size, layout]
    ['sim-kite', 'live', 'desktop', 'hud'],
    ['sim-kite', 'program', 'desktop', ''],
    ['sim-kite', 'program', 'phone', ''],
    ['sim-kite', 'live', 'phone', 'hud'],
    ['sim-kite', 'live', 'tablet', 'wall'],
    ['sim-kite', 'control', 'phone', ''],
    ['sim-kite', 'control', 'desktop', ''],
    ['sim-kite', 'params', 'desktop', ''],
    ['sim-kite', 'replay', 'desktop', ''],
    ['sim-kite', 'devices', 'desktop', ''],
    ['sim-kite', 'guides', 'tablet', ''],
    ['sim-kite', 'settings', 'phone', ''],
    ['sim-cell', 'control', 'desktop', ''],
    ['sim-cell', 'live', 'tablet', 'hud'],
    ['sim-cell', 'program', 'desktop', ''],
    ['sim-nova', 'control', 'desktop', ''],
    ['sim-bench', 'control', 'desktop', ''],
    ['sim-bench', 'program', 'tablet', ''],
    ['sim-bench', 'live', 'phone', 'hud'],
    ['sim-mule', 'control', 'tablet', ''],
    ['sim-mule', 'live', 'desktop', 'hud'],
    ['none', 'live', 'phone', ''],
  ];

  testWidgets('capture screens', (tester) async {
    if (dir == null) return;
    await tester.runAsync(() => Directory(dir).create(recursive: true));
    SharedPreferences.setMockInitialValues({});
    await tester.runAsync(_loadFonts);
    final dash = Dash();
    await tester.runAsync(() async {
      await dash.init();
      for (final t in simTemplates()) {
        dash.addSimulated(t);
      }
      dash.loadSamples();
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    String? cur;
    for (final s in shots) {
      final (dev, screen, size, layout) = (s[0], s[1], s[2], s[3]);
      if (dev != cur) {
        await tester.runAsync(() async {
          if (dev == 'none') {
            await dash.disconnect();
          } else {
            await dash.connect(dev);
          }
          await Future<void>.delayed(const Duration(milliseconds: 1500));
        });
        cur = dev;
      }
      if (screen == 'replay') dash.openReplay(dash.sessions.first.id);
      if (layout.isNotEmpty) dash.layout = layout;
      final sz = sizes[size]!;
      tester.view.physicalSize = sz;
      tester.view.devicePixelRatio = 1;
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(brightness: Brightness.dark),
          home: RepaintBoundary(
            key: key,
            child: Scaffold(
              body: DashApp(key: UniqueKey(), dash: dash, initial: screen),
            ),
          ),
        ),
      );
      // Let the ticker sample history and the camera settle, with real telemetry flowing.
      for (var i = 0; i < 40; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 25)));
        await tester.pump(const Duration(milliseconds: 33));
      }
      await tester.runAsync(() async {
        final b = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final img = await b.toImage(pixelRatio: 1);
        final png = await img.toByteData(format: ui.ImageByteFormat.png);
        await File('$dir/${dev}_${screen}_$size${layout.isEmpty ? '' : '_$layout'}.png').writeAsBytes(png!.buffer.asUint8List());
      });
      if (screen == 'replay') dash.closeReplay();
    }
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() async => dash.disconnect());
    await tester.pump(const Duration(seconds: 10)); // flush toast / UI timers
    tester.view.reset();
  });
}
