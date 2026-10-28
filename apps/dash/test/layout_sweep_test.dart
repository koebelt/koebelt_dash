// Every screen, on every simulated device, at phone, tablet and desktop
// sizes: no overflow, no exception. Also several devices at once, large
// text, the other stick layouts and the dialogs. With SWEEP_SHOTS=<dir>, a
// picture of each, to look at.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koebelt_dash/app.dart';
import 'package:koebelt_dash/core/dash.dart';
import 'package:koebelt_dash/core/model.dart';
import 'package:koebelt_dash/scripts/script_hub.dart';
import 'package:koebelt_dash/screens/devices.dart';
import 'package:koebelt_dash/screens/export_dialog.dart';
import 'package:koebelt_dash/screens/import_dialog.dart';
import 'package:koebelt_dash/screens/script_dialogs.dart';
import 'package:koebelt_dash/screens/update_ui.dart';
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

typedef _Size = ({String name, Size size, EdgeInsets pad});

const _se = (name: 'se', size: Size(320, 568), pad: EdgeInsets.only(top: 20));
const _phone = (name: 'phone', size: Size(390, 844), pad: EdgeInsets.only(top: 47, bottom: 34));
const _land = (name: 'phone-land', size: Size(844, 390), pad: EdgeInsets.only(left: 47, right: 47, bottom: 21));
const _ipad = (name: 'ipad', size: Size(820, 1180), pad: EdgeInsets.only(top: 24, bottom: 20));
const _ipadLand = (name: 'ipad-land', size: Size(1180, 820), pad: EdgeInsets.only(top: 24, bottom: 20));
const _small = (name: 'window-small', size: Size(640, 480), pad: EdgeInsets.zero);
const _laptop = (name: 'laptop', size: Size(1280, 720), pad: EdgeInsets.zero);
const _desktop = (name: 'desktop', size: Size(1920, 1080), pad: EdgeInsets.zero);
const _ultrawide = (name: 'ultrawide', size: Size(3440, 1000), pad: EdgeInsets.zero);
const _all = <_Size>[_se, _phone, _land, _ipad, _ipadLand, _small, _laptop, _desktop, _ultrawide];

const _screens = ['live', 'live-wall', 'control', 'automate', 'program', 'scripts', 'params', 'replay', 'devices', 'guides', 'settings'];

final _shots = Platform.environment['SWEEP_SHOTS'];

/// Pumps the app, records what goes wrong, takes the picture.
class _Sweep {
  _Sweep(this.tester, this.dash);
  final WidgetTester tester;
  final Dash dash;
  final problems = <String>{};
  var where = '';

  Future<T> run<T>(Future<T> Function() body) async {
    final prior = FlutterError.onError;
    FlutterError.onError = (e) {
      final first = e.exceptionAsString().split('\n').first;
      final at = RegExp(r'lib/[\w/]+\.dart:\d+').firstMatch(e.toString())?.group(0) ?? '?';
      problems.add('$where: $first [$at]');
    };
    try {
      return await body();
    } finally {
      FlutterError.onError = prior;
    }
  }

  Future<void> connect(List<String> ids) => tester.runAsync(() async {
    await dash.disconnectAll();
    for (final id in ids) {
      await dash.connect(id);
    }
    await Future<void>.delayed(const Duration(milliseconds: 1200));
  });

  Future<void> screen(String tag, _Size s, String scr, {double text = 1, Future<void> Function(BuildContext)? then}) async {
    where = '$tag ${s.name} $scr';
    final replay = scr == 'replay';
    if (replay) dash.openReplay(dash.sessions.first.id);
    dash.layout = scr == 'live-wall' ? 'wall' : 'hud';
    tester.view.physicalSize = s.size * 2;
    tester.view.devicePixelRatio = 2;
    tester.view.padding = FakeViewPadding(left: s.pad.left * 2, top: s.pad.top * 2, right: s.pad.right * 2, bottom: s.pad.bottom * 2);
    tester.platformDispatcher.textScaleFactorTestValue = text;
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(brightness: Brightness.dark),
          home: Scaffold(
            body: DashApp(key: UniqueKey(), dash: dash, initial: scr == 'live-wall' ? 'live' : scr),
          ),
        ),
      ),
    );
    await settle();
    if (then != null) {
      await then(tester.element(find.byType(Shell)));
      await settle();
    }
    if (_shots != null) {
      await tester.runAsync(() async {
        final b = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final img = await b.toImage(pixelRatio: 1);
        final png = await img.toByteData(format: ui.ImageByteFormat.png);
        await File('$_shots/${tag}_${s.name}_$scr.png').writeAsBytes(png!.buffer.asUint8List());
      });
    }
    if (then != null) {
      // Closes the dialog.
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 300));
    }
    if (replay) dash.closeReplay();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
  }

  Future<void> settle() async {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> finish() async {
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(dash.disconnectAll);
    await tester.pump(const Duration(seconds: 10));
    tester.view.reset();
    for (final p in problems) {
      debugPrint('SWEEP $p');
    }
    expect(problems, isEmpty);
  }
}

Future<(_Sweep, List<String>)> _start(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  await tester.runAsync(_loadFonts);
  if (_shots != null) await tester.runAsync(() => Directory(_shots!).create(recursive: true));
  final dash = Dash();
  final ids = <String>[];
  await tester.runAsync(() async {
    await dash.init();
    for (final t in simTemplates()) {
      ids.add(dash.addSimulated(t).id);
    }
    dash.loadSamples();
  });
  return (_Sweep(tester, dash), ids);
}

void main() {
  const long = Timeout(Duration(minutes: 20));

  testWidgets('every screen, every device, every size: no overflow, no exception', (tester) async {
    final (sw, ids) = await _start(tester);
    await sw.run(() async {
      for (final dev in ['none', ...ids]) {
        await sw.connect(dev == 'none' ? [] : [dev]);
        for (final s in _all) {
          for (final scr in _screens) {
            await sw.screen(dev, s, scr);
          }
        }
      }
    });
    await sw.finish();
  }, timeout: long);

  testWidgets('five devices at once, large text, the other stick layouts', (tester) async {
    final (sw, ids) = await _start(tester);
    await sw.run(() async {
      await sw.connect(ids);
      for (final s in [_se, _phone, _ipad, _small, _laptop]) {
        for (final scr in _screens) {
          await sw.screen('fleet', s, scr);
        }
      }
      for (final dev in [ids[0], ids[1]]) {
        await sw.connect([dev]);
        for (final s in [_se, _phone, _land, _ipad, _small]) {
          for (final scr in _screens) {
            await sw.screen('$dev-text', s, scr, text: 1.35);
          }
        }
        for (final cs in ['sliders', 'tilt']) {
          sw.dash.settings.control = cs;
          for (final s in _all) {
            await sw.screen('$dev-$cs', s, 'control');
          }
        }
        sw.dash.settings.control = 'joysticks';
      }
    });
    await sw.finish();
  }, timeout: long);

  testWidgets('dialogs, small and large', (tester) async {
    final (sw, ids) = await _start(tester);
    await sw.run(() async {
      await sw.connect([ids[0]]);
      final dialogs = <String, Future<void> Function(BuildContext)>{
        'pair': (c) async => showPairDialog(c, sw.dash, (_) {}),
        'pair-sim': (c) async => showPairDialog(c, sw.dash, (_) {}, simulated: true),
        'export': (c) async => showExportDialog(c, sw.dash.sessions.first),
        'import': (c) async => showImportDialog(c, sw.dash),
        'trigger': (c) async => unawaited(showTriggerDialog(c, sw.dash, events: const ['start', 'land'], kind: DeviceKind.drone)),
        'limits': (c) async => unawaited(showLimitsDialog(c, ScriptLimits(), onChanged: () {}, kind: DeviceKind.drone)),
        'add-host': (c) async => unawaited(showAddHostDialog(c, sw.dash)),
        'versions': (c) async => unawaited(showVersionPicker(c, sw.dash)),
      };
      for (final s in [_se, _land, _small, _desktop]) {
        for (final MapEntry(:key, :value) in dialogs.entries) {
          await sw.screen('dialog-$key', s, 'live', then: value);
        }
      }
    });
    await sw.finish();
  }, timeout: long);
}

void unawaited(Future<void>? f) {}
