// dash runs a real Python script with koebelt-dash-scripts, which drives a
// simulated rover. Needs a Python with the package: KDASH_SCRIPTS_PYTHON, or
// the development venv in libs/python-dash-scripts/.venv (skipped without).
@TestOn('vm')
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:koebelt_dash/core/dash.dart';
import 'package:koebelt_dash/scripts/hosts.dart';
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
    print("refused:", e.code, e.title)
try:
    dev.drive_to_the_moon()
except AttributeError:
    print("no such method")
dev.land()  # the simulated Kite starts in the air
dev.takeoff(5)
print("alt", round(dev.tlm.alt, 2))
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
    expect(o, contains('refused: E0303 that point is 500 m from home, beyond the 50 m geofence'));
    // Done from 0.6 m below the target, as in Program.
    expect(double.parse(RegExp(r'alt ([0-9.]+)').firstMatch(o)![1]!), inInclusiveRange(4.4, 5.6));
    expect(double.parse(RegExp(r'off by ([0-9.]+)').firstMatch(o)![1]!), lessThanOrEqualTo(1.5), reason: 'Program\'s 1 m arrival radius, and a little drift before the script reads it');
    expect(o, contains('landed 0'));
    expect(run.state, ScriptState.exited, reason: o);
  }, skip: python == null ? 'no Python with koebelt-dash-scripts (KDASH_SCRIPTS_PYTHON)' : false, timeout: const Timeout(Duration(seconds: 90)));

  test('a phone runs a script on a script host, which drives through the phone’s dash', () async {
    SharedPreferences.setMockInitialValues({});
    final d = Dash();
    await d.init();
    final mule = d.addSimulated(simTemplates().firstWhere((t) => t.id == 'mule'));
    await d.connect(mule.id);
    // A free port: a koebelt dash running on this computer holds the usual one.
    await d.scripts.start(port: 0);
    final ticker = Timer.periodic(const Duration(milliseconds: 20), (_) => d.tick(.02));
    // A host on this computer, on a free port.
    final free = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = free.port;
    await free.close();
    final home = await Directory.systemTemp.createTemp('kdash-host-home');
    final host = await Process.start(python!, ['-m', 'koebelt_dash_scripts', 'host', '--port', '$port', '--no-discovery', '--name', 'Bench PC'], environment: {'HOME': home.path});
    final lines = <String>[];
    host.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen(lines.add);
    host.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen(lines.add);
    addTearDown(() async {
      ticker.cancel();
      host.kill();
      for (final r in d.scripts.runs) {
        await r.stop();
      }
      await d.scripts.stop();
      await d.disconnectAll();
    });
    for (var i = 0; i < 100 && !lines.any((l) => l.startsWith('Pairing code: ')); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    final code = lines.firstWhere((l) => l.startsWith('Pairing code: ')).substring(14, 21);

    await expectLater(pairHost('127.0.0.1', port, 'AAA-AAA', myName: 'test'), throwsA(isA<HostError>().having((e) => e.message, 'message', contains('Wrong pairing code'))));
    final paired = await pairHost('127.0.0.1', port, code, myName: 'Thomas’s iPhone');
    expect(paired.name, 'Bench PC');
    d.scripts.addHost(paired);

    final dir = await Directory.systemTemp.createTemp('kdash-remote');
    await Directory('${dir.path}/remote').create();
    File('${dir.path}/remote/settings.txt').writeAsStringSync('0.6');
    final file = File('${dir.path}/remote/main.py')..writeAsStringSync('''
from koebelt_dash_scripts import connect, every
dev = connect()
speed = float(open("settings.txt").read())
print("remote on", dev.name, "speed", speed)
dev.mode("MANUAL")
x0 = dev.tlm.pos[1]
for i in every(0.05):
    dev.sticks(throttle=speed)
    if i == 30:
        break
dev.sticks(throttle=0)
print("done")
''');
    final run = await d.scripts.runOnHost(file, paired);
    expect(d.scripts.lan, isTrue, reason: 'the API listens on the network for the host');
    String out() => run.console.map((l) => l.text).join('\n');
    for (var i = 0; i < 300 && run.state == ScriptState.running; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    expect(out(), contains('remote on Mule speed 0.6'), reason: '${out()}\nhost: ${lines.join('\n')}');
    expect(out(), contains('done'));
    expect(run.where, 'Bench PC');
    expect(run.state, ScriptState.exited);
    expect(d.links.values.single.tel.speed, greaterThan(.2), reason: 'the rover moved');
  }, skip: python == null ? 'no Python with koebelt-dash-scripts (KDASH_SCRIPTS_PYTHON)' : false, timeout: const Timeout(Duration(seconds: 60)));

  test('from the network, only a run’s own token is accepted', () async {
    SharedPreferences.setMockInitialValues({});
    final d = Dash();
    await d.init();
    await d.scripts.start(port: 0, lan: true);
    addTearDown(d.scripts.stop);
    final ip = (await NetworkInterface.list(type: InternetAddressType.IPv4)).expand((i) => i.addresses).where((a) => !a.isLoopback).firstOrNull;
    if (ip == null) return markTestSkipped('no network address');
    final ws = await WebSocket.connect('ws://${ip.address}:${d.scripts.port}/scripts');
    ws.add(jsonEncode({'t': 'hello', 'v': 1, 'token': d.scripts.token}));
    final m = jsonDecode(await ws.first as String) as Map;
    expect(m['t'], 'bye', reason: 'the main token only works from this computer');
  });

  group('examples', () {
    Future<(Dash, ScriptRun)> runExample(String sim, String example, {bool allowArm = false}) async {
      SharedPreferences.setMockInitialValues({});
      final d = Dash();
      await d.init();
      await d.connect(d.addSimulated(simTemplates().firstWhere((t) => t.id == sim)).id);
      await d.scripts.start(port: 0);
      final ticker = Timer.periodic(const Duration(milliseconds: 20), (_) => d.tick(.02));
      final file = File('../../libs/python-dash-scripts/examples/$example').absolute;
      d.scripts.configFor(file.path).limits.allowArm = allowArm;
      final run = await d.scripts.runFile(file, python: python);
      addTearDown(() async {
        ticker.cancel();
        await run.stop();
        await d.scripts.stop();
        await d.disconnectAll();
      });
      return (d, run);
    }

    test('hold_altitude brings the drone to 5 m', () async {
      final (d, run) = await runExample('kite', 'hold_altitude.py');
      final tel = d.links.values.single.tel;
      for (var i = 0; i < 300 && (tel.pos[2] - 5).abs() > .4; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      expect(tel.pos[2], closeTo(5, .4), reason: run.console.map((l) => l.text).join('\n'));
    }, skip: python == null ? 'no Python with koebelt-dash-scripts' : false, timeout: const Timeout(Duration(seconds: 40)));

    test('thrust_curve measures every step on the bench', () async {
      final (_, run) = await runExample('bench', 'thrust_curve.py', allowArm: true);
      for (var i = 0; i < 900 && run.state == ScriptState.running; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      final rows = run.console.map((l) => l.text).where((t) => RegExp(r'^\d+\t').hasMatch(t)).toList();
      expect(rows, hasLength(10), reason: run.console.map((l) => l.text).join('\n'));
      final thrust = [for (final r in rows) double.parse(r.split('\t')[1])];
      expect(thrust.last, greaterThan(thrust.first), reason: 'more throttle, more thrust');
      expect(run.state, ScriptState.exited);
    }, skip: python == null ? 'no Python with koebelt-dash-scripts' : false, timeout: const Timeout(Duration(seconds: 60)));
  });

  test('choosing a Python checks it again', () async {
    SharedPreferences.setMockInitialValues({});
    final d = Dash();
    await d.init();
    // What dash remembered: no package (it was installed since).
    d.scripts.pythons = [PythonEnv(python!, '3', hasPackage: false)];
    expect(d.scripts.envOf(python)!.hasPackage, isFalse);
    await d.scripts.recheckPython(python);
    expect(d.scripts.envOf(python)!.hasPackage, isTrue);
    expect(d.scripts.pythons, hasLength(1), reason: 'replaced, not added');
    await d.scripts.recheckPython('/nonexistent/python3');
    expect(d.scripts.envOf('/nonexistent/python3'), isNull, reason: 'not a Python');
  }, skip: python == null ? 'no Python with koebelt-dash-scripts' : false);

  test('dash knows the library version in a Python, and the newest one for this app on PyPI', () async {
    SharedPreferences.setMockInitialValues({});
    final d = Dash();
    await d.init();
    await d.scripts.recheckPython(python!);
    final have = d.scripts.envOf(python)!.packageVersion!;
    expect(have, matches(RegExp(r'^1\.3\.0(b\d+)?$')), reason: 'the version pip installed');
    final pypi = MockClient((_) async => http.Response(jsonEncode({'releases': {'1.2.0': [], '1.3.0b1': [], have: [], '1.3.9b1': [], '2.0.0': []}}), 200));
    await d.scripts.checkPackageUpdates(client: pypi, force: true);
    // This app is a beta: betas count, 2.x does not.
    expect(d.scripts.latestPackage, '1.3.9-beta.1');
    expect(d.scripts.packageOutdated(python), isTrue);
    await d.scripts.checkPackageUpdates(client: MockClient((_) async => http.Response(jsonEncode({'releases': {have: []}}), 200)), force: true);
    expect(d.scripts.packageOutdated(python), isFalse);
  }, skip: python == null ? 'no Python with koebelt-dash-scripts' : false);

  test('which library versions a release app and a beta app accept', () {
    expect(scriptsPackageAccepts('1.3.0-beta.2', '1.3.0-beta.3'), isTrue);
    expect(scriptsPackageAccepts('1.3.0-beta.2', '1.3.0'), isFalse, reason: 'a release app takes no betas');
    expect(scriptsPackageAccepts('1.3.1', '1.3.0'), isTrue);
    expect(scriptsPackageAccepts('2.0.0', '1.3.0'), isFalse, reason: 'another script API');
    expect(scriptsPackageAccepts('1.2.0', '1.3.0'), isFalse);
  });
}
