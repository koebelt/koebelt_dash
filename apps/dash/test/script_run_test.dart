// dash runs a real Python script with koebelt-dash-scripts, which drives a
// simulated rover. Needs a Python with the package: KDASH_SCRIPTS_PYTHON, or
// the development venv in libs/python-dash-scripts/.venv (skipped without).
@TestOn('vm')
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:koebelt_dash/core/dash.dart';
import 'package:koebelt_dash/scripts/script_runner.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _script = '''
import math
from koebelt_dash_scripts import connect, every

dev = connect()
print("connected", dev.name, dev.kind)
speed = dev.setting("speed", 0.5, min=0, max=1)

@dev.trigger("Turn")
def turn():
    print("turn fired")

dev.mode("MANUAL")
x0, y0 = dev.tlm.pos[0], dev.tlm.pos[1]
for i in every(0.05):
    dev.sticks(throttle=speed.value)
    if i == 30:
        break
print("moved", round(math.hypot(dev.tlm.pos[0] - x0, dev.tlm.pos[1] - y0), 2))
dev.sticks(throttle=0)
dev.run()
''';

String? _python() {
  final env = Platform.environment['KDASH_SCRIPTS_PYTHON'];
  if (env != null) return env;
  final venv = File('../../libs/python-dash-scripts/.venv/bin/python');
  return venv.existsSync() ? venv.absolute.path : null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final python = _python();

  test('a Python script drives the rover, reacts to a trigger, and ends with STOP', () async {
    SharedPreferences.setMockInitialValues({});
    final d = Dash();
    await d.init();
    final mule = d.addSimulated(simTemplates().firstWhere((t) => t.id == 'mule'));
    await d.connect(mule.id);
    await d.scripts.start(port: 0);
    final ticker = Timer.periodic(const Duration(milliseconds: 20), (_) => d.tick(.02));
    addTearDown(() async {
      ticker.cancel();
      await d.scripts.stop();
      await d.disconnectAll();
    });
    final dir = await Directory.systemTemp.createTemp('kdash-script');
    final file = File('${dir.path}/drive.py')..writeAsStringSync(_script);

    final run = await d.scripts.runFile(file, python: python);
    String out() => run.console.map((l) => l.text).join('\n');
    Future<void> until(bool Function() ok, String what) async {
      for (var i = 0; i < 200 && !ok(); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      expect(ok(), isTrue, reason: '$what. Console:\n${out()}');
    }

    await until(() => out().contains('connected Mule rover'), 'the script connects');
    expect(d.scripts.connOf(run), isNotNull, reason: 'dash knows which process it is');
    await until(() => out().contains('moved'), 'the script drives');
    final moved = double.parse(RegExp(r'moved ([0-9.]+)').firstMatch(out())![1]!);
    expect(moved, greaterThan(.3), reason: 'the rover moved');
    expect(d.links.values.single.tel.mode, 'MANUAL');

    final c = d.scripts.connOf(run)!;
    expect(c.settings.keys, ['speed']);
    d.scripts.fire(c, 'Turn');
    await until(() => out().contains('turn fired'), 'the trigger reaches the script');

    d.emergencyStop();
    await until(() => run.state != ScriptState.running, 'STOP ends the script');
    expect(d.links.values.single.drive, isNull);
  }, skip: python == null ? 'no Python with koebelt-dash-scripts (KDASH_SCRIPTS_PYTHON)' : false, timeout: const Timeout(Duration(seconds: 60)));

  test('the drive_square example reaches its first corner', () async {
    SharedPreferences.setMockInitialValues({});
    final d = Dash();
    await d.init();
    final mule = d.addSimulated(simTemplates().firstWhere((t) => t.id == 'mule'));
    await d.connect(mule.id);
    await d.scripts.start(port: 0);
    final ticker = Timer.periodic(const Duration(milliseconds: 20), (_) => d.tick(.02));
    addTearDown(() async {
      ticker.cancel();
      for (final r in d.scripts.runs) {
        await r.stop();
      }
      await d.scripts.stop();
      await d.disconnectAll();
    });
    final run = await d.scripts.runFile(File('../../libs/python-dash-scripts/examples/drive_square.py').absolute, python: python);
    final tel = d.links.values.single.tel;
    var best = double.infinity;
    for (var i = 0; i < 300; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final dx = tel.pos[0] - 8, dy = tel.pos[1];
      best = [best, dx * dx + dy * dy].reduce((a, b) => a < b ? a : b);
      if (best <= .36) break;
    }
    expect(best, lessThan(.36), reason: 'within 0.6 m of (8, 0). Console:\n${run.console.map((l) => l.text).join('\n')}');
    expect(run.console.where((l) => l.text.contains('Traceback')), isEmpty);
  }, skip: python == null ? 'no Python with koebelt-dash-scripts (KDASH_SCRIPTS_PYTHON)' : false, timeout: const Timeout(Duration(seconds: 60)));

  test('a script sees the camera, draws on it, and flies the drone with steps', () async {
    SharedPreferences.setMockInitialValues({});
    final d = Dash();
    await d.init();
    final kite = d.addSimulated(simTemplates().firstWhere((t) => t.id == 'kite'));
    await d.connect(kite.id);
    await d.scripts.start(port: 0);
    final ticker = Timer.periodic(const Duration(milliseconds: 20), (_) => d.tick(.02));
    addTearDown(() async {
      ticker.cancel();
      for (final r in d.scripts.runs) {
        await r.stop();
      }
      await d.scripts.stop();
      await d.disconnectAll();
    });
    final dir = await Directory.systemTemp.createTemp('kdash-steps');
    final file = File('${dir.path}/fly.py')..writeAsStringSync('''
from koebelt_dash_scripts import connect, ScriptError
dev = connect()
img = dev.camera.jpeg()
print("frame", len(img) > 1000, img[:4] == b"\\x89PNG")
dev.overlay([(0.4, 0.4, 0.2, 0.2, "target")])
try:
    dev.goto(500, 0, 10)
except ScriptError as e:
    print("refused:", e)
try:
    dev.drive_to_the_moon()
except AttributeError:
    print("no such method")
dev.land()  # the simulated Kite starts in the air
dev.takeoff(5)
print("alt", round(dev.tlm.alt))
dev.goto(6, 0, 5)
x, y, z = dev.tlm.pos
print("off by", round(((x - 6) ** 2 + y ** 2 + (z - 5) ** 2) ** 0.5, 1))
dev.land()
print("landed", round(dev.tlm.alt))
''');
    d.scripts.configFor(file.path).limits.allowArm = true;
    final run = await d.scripts.runFile(file, python: python);
    String out() => run.console.map((l) => l.text).join('\n');
    for (var i = 0; i < 1200 && run.state == ScriptState.running; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    final o = out();
    expect(o, contains('frame True True'), reason: o);
    expect(d.links.values.single.overlay?.boxes.single.label, 'target');
    expect(o, contains('refused: That is 500 m from home, beyond the 50 m geofence.'));
    expect(o, contains('alt 5'));
    expect(double.parse(RegExp(r'off by ([0-9.]+)').firstMatch(o)![1]!), lessThanOrEqualTo(1.0), reason: 'Program\'s arrival radius');
    expect(o, contains('landed 0'));
    expect(run.state, ScriptState.exited, reason: o);
  }, skip: python == null ? 'no Python with koebelt-dash-scripts (KDASH_SCRIPTS_PYTHON)' : false, timeout: const Timeout(Duration(seconds: 90)));
}
