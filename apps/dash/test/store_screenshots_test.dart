// App Store screenshots, at the sizes Apple requires, from the app itself
// with the simulated devices:
//
//   STORE_SHOTS=/tmp/store flutter test test/store_screenshots_test.dart
//
// iphone_*.png  1320 × 2868 (6.9", 440 × 956 pt at 3x, with the safe areas
//               of a phone with a Dynamic Island)
// ipad_*.png    2064 × 2752 (13", 1032 × 1376 pt at 2x)
//
// Upload them with tools/release/app_store.py. Skipped without STORE_SHOTS.
// The sensor wall is left out on purpose: its camera tile has no simulated
// stream and says "No signal".
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

typedef _Shot = ({String name, String device, String screen, String layout, bool replay});

const _iphone = <_Shot>[
  (name: '1-live', device: 'sim-kite', screen: 'live', layout: 'hud', replay: false),
  (name: '2-control', device: 'sim-kite', screen: 'control', layout: '', replay: false),
  (name: '3-program', device: 'sim-kite', screen: 'program', layout: '', replay: false),
  (name: '5-replay', device: 'sim-kite', screen: 'replay', layout: '', replay: true),
  (name: '4-arm', device: 'sim-cell', screen: 'control', layout: '', replay: false),
];
const _ipad = <_Shot>[
  (name: '1-live', device: 'sim-kite', screen: 'live', layout: 'hud', replay: false),
  (name: '3-program', device: 'sim-kite', screen: 'program', layout: '', replay: false),
  (name: '4-replay', device: 'sim-kite', screen: 'replay', layout: '', replay: true),
  (name: '2-arm', device: 'sim-cell', screen: 'control', layout: '', replay: false),
  (name: '5-rover', device: 'sim-mule', screen: 'control', layout: '', replay: false),
];

void main() {
  final dir = Platform.environment['STORE_SHOTS'];

  testWidgets('App Store screenshots', (tester) async {
    await tester.runAsync(() => Directory(dir!).create(recursive: true));
    SharedPreferences.setMockInitialValues({});
    await tester.runAsync(_loadFonts);
    final dash = Dash();
    await tester.runAsync(() async {
      await dash.init();
      for (final t in simTemplates()) {
        dash.addSimulated(t);
      }
      dash.loadSamples();
    });

    for (final (kind, shots, size, scale, inset) in [
      ('iphone', _iphone, const Size(440, 956), 3.0, const (top: 62.0, bottom: 34.0)),
      ('ipad', _ipad, const Size(1032, 1376), 2.0, const (top: 24.0, bottom: 20.0)),
    ]) {
      String? connected;
      for (final s in shots) {
        // One device at a time, so the screens show a single machine.
        if (s.device != connected) {
          await tester.runAsync(() async {
            await dash.disconnectAll();
            await dash.connect(s.device);
            await Future<void>.delayed(const Duration(milliseconds: 2500));
          });
          connected = s.device;
        }
        if (s.replay) dash.openReplay(dash.sessions.first.id);
        if (s.layout.isNotEmpty) dash.layout = s.layout;
        tester.view.physicalSize = size * scale;
        tester.view.devicePixelRatio = scale;
        tester.view.padding = FakeViewPadding(top: inset.top * scale, bottom: inset.bottom * scale);
        final key = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: ThemeData(brightness: Brightness.dark),
              home: Scaffold(
                body: SafeArea(
                  child: DashApp(key: UniqueKey(), dash: dash, initial: s.screen),
                ),
              ),
            ),
          ),
        );
        // Let telemetry flow and the 3D camera settle.
        for (var i = 0; i < 45; i++) {
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 25)));
          await tester.pump(const Duration(milliseconds: 33));
        }
        await tester.runAsync(() async {
          final b = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final img = await b.toImage(pixelRatio: scale);
          final png = await img.toByteData(format: ui.ImageByteFormat.png);
          await File('$dir/${kind}_${s.name}.png').writeAsBytes(png!.buffer.asUint8List());
        });
        if (s.replay) dash.closeReplay();
      }
    }
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(dash.disconnectAll);
    await tester.pump(const Duration(seconds: 10));
    tester.view.reset();
  }, skip: dir == null); // needs STORE_SHOTS
}
