// Renders the map, camera, radio and controller screens for review.
// Run:  CAPTURE_DIR=/tmp/shots flutter test test/capture_features_test.dart
// Skipped when CAPTURE_DIR is not set. Map tiles are not fetched in tests
// (no network), so the map shows its offline grid.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koebelt_dash/app.dart';
import 'package:koebelt_dash/core/dash.dart';
import 'package:koebelt_dash/screens/device_menu.dart';
import 'package:koebelt_dash/screens/devices.dart';
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
  final dir = Platform.environment['CAPTURE_DIR'];
  final sizes = {'phone': const Size(390, 844), 'tablet': const Size(1180, 820), 'desktop': const Size(1440, 900)};
  // [device, screen, size, live view, control view, extra]
  final shots = <List<String>>[
    ['sim-kite', 'live', 'desktop', 'chase', '', 'menu'],
    ['sim-kite', 'live', 'phone', 'chase', '', 'menu'],
    ['sim-kite', 'live', 'desktop', 'map', '', ''],
    ['sim-kite', 'live', 'desktop', 'map', '', 'osm'],
    ['sim-kite', 'live', 'desktop', 'cam', '', ''],
    ['sim-kite', 'live', 'phone', 'cam', '', ''],
    ['sim-kite', 'control', 'desktop', '', 'cam', ''],
    ['sim-kite', 'control', 'phone', '', 'map', ''],
    ['sim-kite', 'settings', 'desktop', '', '', ''],
    ['sim-mule', 'live', 'tablet', 'cam', '', 'wall'],
    ['sim-nova', 'live', 'desktop', 'cam', '', ''],
    ['sim-nova', 'guides', 'tablet', '', '', ''],
    ['sim-nova', 'devices', 'desktop', '', '', 'radio'],
  ];

  testWidgets('capture features', (tester) async {
    if (dir == null) return;
    // Real HTTP for the simulator's camera server (tests block it by default).
    HttpOverrides.global = null;
    await tester.runAsync(() => Directory(dir).create(recursive: true));
    SharedPreferences.setMockInitialValues({});
    await tester.runAsync(_loadFonts);
    final dash = Dash();
    await tester.runAsync(() async {
      await dash.init();
      for (final t in simTemplates()) {
        dash.addSimulated(t);
      }
      dash.settings.mapTiles = 'none';
    });
    String? cur;
    for (final s in shots) {
      final (dev, screen, size, lv, cv, extra) = (s[0], s[1], s[2], s[3], s[4], s[5]);
      if (dev != cur) {
        await tester.runAsync(() async {
          await dash.connect(dev);
          await Future<void>.delayed(const Duration(milliseconds: 1500));
        });
        cur = dev;
      }
      if (lv.isNotEmpty) dash.liveView = lv;
      if (cv.isNotEmpty) dash.controlView = cv;
      // One shot with real OpenStreetMap tiles when the network allows it.
      dash.settings.mapTiles = extra == 'osm' ? 'osm' : 'none';
      dash.layout = extra == 'wall' ? 'wall' : 'hud';
      final sz = sizes[size]!;
      tester.view.physicalSize = sz;
      tester.view.devicePixelRatio = 1;
      final key = GlobalKey();
      // The boundary wraps the whole app so dialogs are captured too.
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(brightness: Brightness.dark),
            home: Scaffold(
              body: DashApp(key: UniqueKey(), dash: dash, initial: screen),
            ),
          ),
        ),
      );
      if (extra == 'menu') {
        await tester.tap(find.byType(DeviceBtn));
      }
      if (extra == 'radio') {
        showPairDialog(tester.element(find.byType(DashApp)), dash, (_) {}, radio: true);
      }
      // Real telemetry and real video frames (the simulator's camera server).
      for (var i = 0; i < 60; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
        await tester.pump(const Duration(milliseconds: 33));
      }
      await tester.runAsync(() async {
        final b = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final img = await b.toImage(pixelRatio: 1);
        final png = await img.toByteData(format: ui.ImageByteFormat.png);
        await File('$dir/f_${dev}_${screen}_${size}_$lv$cv$extra.png').writeAsBytes(png!.buffer.asUint8List());
      });
    }
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() async {
      await dash.disconnect();
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump(const Duration(seconds: 10));
    tester.view.reset();
  });
}
