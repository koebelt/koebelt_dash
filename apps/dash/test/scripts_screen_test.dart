// The Scripts screen with a real script running on the simulated rover.
// Pictures with CAPTURE_DIR=/tmp/x; the script needs a Python with
// koebelt-dash-scripts (KDASH_SCRIPTS_PYTHON, or libs/python-dash-scripts/.venv).
@TestOn('vm')
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koebelt_dash/app.dart';
import 'package:koebelt_dash/core/dash.dart';
import 'package:koebelt_dash/scripts/library.dart';
import 'package:koebelt_dash/scripts/script_runner.dart';
import 'package:koebelt_dash/scripts/triggers.dart';
import 'package:koebelt_dash/screens/scripts.dart';
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

const _follow = '''"""Follow the line.

Drives north and keeps on the x = 0 line.
"""
from koebelt_dash_scripts import connect, every, pid

dev = connect()
speed = dev.setting("speed", 0.4, min=0, max=1)
hold = pid(1.5, 0.0, 0.2)
paused = False


@dev.trigger("Pause", kind="switch", key="P")
def pause(on):
    global paused
    paused = on
    print("paused" if on else "going")


@dev.trigger("Mark here", key="M", gamepad="LT")
def mark():
    dev.mark("here")
    print("marked at", [round(v, 1) for v in dev.tlm.pos])


print("following on", dev.name)
for _ in every(0.05):
    dev.sticks(throttle=0 if paused else speed.value, steer=hold.update(-dev.tlm.pos[0]))
''';

String? _python() {
  final env = Platform.environment['KDASH_SCRIPTS_PYTHON'];
  if (env != null) return env;
  final venv = File('../../libs/python-dash-scripts/.venv/bin/python');
  return venv.existsSync() ? venv.absolute.path : null;
}

void main() {
  final shots = Platform.environment['CAPTURE_DIR'];
  final python = _python();

  testWidgets('the Scripts screen: library, editor, a running script, its triggers, and Control', (tester) async {
    SharedPreferences.setMockInitialValues({});
    // The real fonts: the test font is taller and would overflow the phone tab bar.
    await tester.runAsync(_loadFonts);
    final d = Dash();
    late ScriptLibrary lib;
    late File file;
    await tester.runAsync(() async {
      await d.init();
      final mule = d.addSimulated(simTemplates().firstWhere((t) => t.id == 'mule'));
      await d.connect(mule.id);
      await d.scripts.start(port: 0);
      final dir = await Directory.systemTemp.createTemp('kdash-screen');
      lib = ScriptLibrary(Directory('${dir.path}/koebelt/dash-scripts'));
      file = await lib.create('Follow the line', _follow);
      await lib.create('Hold altitude', scriptTemplate('loop', d.kind, 'Hold altitude'));
      await lib.create('Survey and photos', scriptTemplate('button', d.kind, 'Survey and photos'));
      await d.scripts.refreshPythons(near: lib.dir);
      d.scripts.configFor(file.path)
        ..python = python
        ..bindings.add(TriggerBinding('Low battery', TriggerSource.condition, expr: 'battery.pct < 25 for 3s'));
    });

    Future<void> settle([int frames = 20]) async {
      for (var i = 0; i < frames; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
        await tester.pump(const Duration(milliseconds: 30));
      }
    }

    final key = GlobalKey();
    Future<void> shot(String name, double scale) async {
      if (shots == null) return;
      await tester.runAsync(() async {
        final b = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final img = await b.toImage(pixelRatio: scale);
        final png = await img.toByteData(format: ui.ImageByteFormat.png);
        await File('$shots/$name.png').writeAsBytes(png!.buffer.asUint8List());
      });
    }

    Future<void> show(String screen, {required bool phone}) async {
      final (size, scale, top, bottom) = phone ? (const Size(440, 956), 2.0, 62.0, 34.0) : (const Size(1440, 900), 1.0, 0.0, 0.0);
      tester.view.physicalSize = size * scale;
      tester.view.devicePixelRatio = scale;
      tester.view.padding = FakeViewPadding(top: top * scale, bottom: bottom * scale);
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(brightness: Brightness.dark),
            home: Scaffold(
              body: ScriptsLibraryScope(
                library: lib,
                child: DashApp(key: UniqueKey(), dash: d, initial: screen),
              ),
            ),
          ),
        ),
      );
      await settle();
    }

    addTearDown(() => tester.view.reset());
    await show('scripts', phone: false);
    expect(find.text('Follow the line'), findsWidgets);
    expect(find.text('Hold altitude'), findsOneWidget);
    await tester.tap(find.text('Follow the line').first);
    await settle();

    if (python != null) {
      await tester.tap(find.text('RUN'));
      await settle(80);
      final run = d.scripts.runs.single;
      expect(run.state, ScriptState.running, reason: run.console.map((l) => l.text).join('\n'));
      expect(run.console.map((l) => l.text), contains('following on Mule'));
      expect(find.text('Pause'), findsWidgets, reason: 'declared triggers show');
      expect(find.text('KEY P'), findsOneWidget);
      // The M key fires its trigger.
      await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
      await settle(15);
      expect(run.console.map((l) => l.text).any((t) => t.startsWith('marked at')), isTrue);
    }
    await shot('scripts_desktop', 1);

    await show('scripts', phone: true);
    await shot('scripts_phone_list', 2);
    await tester.tap(find.text('Follow the line').first);
    await settle();
    await shot('scripts_phone_run', 2);
    await tester.tap(find.text('EDIT').first);
    await settle();
    await shot('scripts_phone_edit', 2);

    await show('control', phone: true);
    if (python != null) expect(find.textContaining('DRIVES'), findsOneWidget);
    await shot('scripts_phone_control', 2);

    await tester.runAsync(() async {
      for (final r in d.scripts.runs) {
        await r.stop();
      }
      await d.scripts.stop();
      await d.disconnectAll();
    });
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 10));
  });
}
