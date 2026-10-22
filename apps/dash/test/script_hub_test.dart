import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:koebelt_dash/core/dash.dart';
import 'package:koebelt_dash/scripts/script_hub.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A script, as koebelt_dash_scripts talks to dash.
class _Script {
  _Script(this.ws) {
    ws.listen((d) {
      final m = (jsonDecode(d as String) as Map).cast<String, dynamic>();
      got.add(m);
      if (m['t'] == 'res') _waiting.remove(m['id'])?.complete(m);
    });
  }
  final WebSocket ws;
  final got = <Map<String, dynamic>>[];
  final _waiting = <int, Completer<Map<String, dynamic>>>{};
  var _id = 0;

  static Future<_Script> open(ScriptHub hub, {String? token}) async {
    final s = _Script(await WebSocket.connect('ws://127.0.0.1:${hub.port}/scripts'));
    s.ws.add(jsonEncode({'t': 'hello', 'v': 1, 'token': token ?? hub.token, 'name': 'test.py'}));
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return s;
  }

  Future<Map<String, dynamic>> call(String t, [Map<String, dynamic> m = const {}]) {
    final id = ++_id, c = Completer<Map<String, dynamic>>();
    _waiting[id] = c;
    ws.add(jsonEncode({'t': t, 'id': id, ...m}));
    return c.future.timeout(const Duration(seconds: 2));
  }

  void send(String t, [Map<String, dynamic> m = const {}]) => ws.add(jsonEncode({'t': t, ...m}));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Dash d;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    d = Dash();
    await d.init();
    final mule = d.addSimulated(simTemplates().firstWhere((t) => t.id == 'mule'));
    await d.connect(mule.id);
    await d.scripts.start(port: 0);
  });

  tearDown(() async {
    await d.scripts.stop();
    await d.disconnectAll();
  });

  // dash's frame loop, in fast-forward.
  Future<void> run(double seconds) async {
    for (var t = 0.0; t < seconds; t += .05) {
      d.tick(.05);
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
  }

  test('a script needs the token', () async {
    final s = await _Script.open(d.scripts, token: 'nope');
    expect(s.got.single['t'], 'bye');
    expect(d.scripts.conns, isEmpty);
  });

  test('a script drives with named sticks, scaled by its speed limit, and gets telemetry', () async {
    final s = await _Script.open(d.scripts);
    expect(s.got.first['t'], 'welcome');
    final use = await s.call('use');
    expect(use['value']['kind'], 'rover');
    expect(use['value']['sim'], isTrue);
    final l = d.links.values.single;

    expect((await s.call('sticks', {'a': {'throttle': 1, 'steer': -.5}}))['ok'], isTrue);
    expect(l.drive, isNotNull);
    // Limit 60 %: forward is the right stick's y, steering the left stick's x.
    expect(l.drive!.axes(l.input), [closeTo(-.3, 1e-9), 0, 0, closeTo(.6, 1e-9)]);

    final bad = await s.call('sticks', {'a': {'pitch': 1}});
    expect(bad['err'], contains('not a stick of a rover'));

    await run(.3);
    expect(s.got.where((m) => m['t'] == 'tlm'), isNotEmpty);
    expect(s.got.lastWhere((m) => m['t'] == 'tlm')['d']['drive'], 'script');
  });

  test('the operator’s sticks take over until Resume', () async {
    final s = await _Script.open(d.scripts);
    await s.call('use');
    await s.call('sticks', {'a': {'throttle': 1}});
    final l = d.links.values.single;
    l.input[3] = -.8;
    expect(l.drive!.axes(l.input)[3], -.8, reason: 'the operator wins');
    l.input[3] = 0;
    expect(l.drive!.axes(l.input)[3], 0, reason: 'still the operator’s, until Resume');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(s.got.where((m) => m['t'] == 'takeover').single['on'], isTrue);
    d.scripts.resume(l);
    expect(l.drive!.axes(l.input)[3], closeTo(.6, 1e-9));
  });

  test('a script that goes quiet loses the device, which holds', () async {
    final s = await _Script.open(d.scripts);
    await s.call('use');
    await s.call('sticks', {'a': {'throttle': 1}});
    final l = d.links.values.single;
    await run(.3);
    expect(l.drive, isNotNull, reason: 'within the watchdog');
    await run(.6);
    expect(l.drive, isNull);
    expect(l.tel.mode, 'HOLD');
    expect((await s.call('sticks', {'a': {'throttle': 1}}))['err'], contains('stopped responding'));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(s.got.lastWhere((m) => m['t'] == 'released')['why'], contains('stopped responding'));
  });

  test('a script that disconnects loses the device too', () async {
    final s = await _Script.open(d.scripts);
    await s.call('use');
    await s.call('sticks', {'a': {'throttle': 1}});
    await s.ws.close();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(d.links.values.single.drive, isNull);
    expect(d.scripts.conns, isEmpty);
  });

  test('STOP releases every script and refuses their commands until cleared', () async {
    final s = await _Script.open(d.scripts);
    await s.call('use');
    await s.call('sticks', {'a': {'throttle': 1}});
    d.emergencyStop();
    expect(d.links.values.single.drive, isNull);
    final r = await s.call('sticks', {'a': {'throttle': 1}});
    expect(r['err'], contains('STOP is on'));
    expect((await s.call('cmd', {'c': 'mode', 'a': {'m': 'AUTO'}}))['ok'], isFalse);
  });

  test('limits: no arming or parameter writes unless the operator allows them; speed capped', () async {
    final s = await _Script.open(d.scripts);
    await s.call('use');
    expect((await s.call('cmd', {'c': 'arm'}))['err'], contains('not allowed'));
    expect((await s.call('cmd', {'c': 'mode', 'a': {'m': 'TAKEOFF'}}))['err'], contains('not allowed'));
    expect((await s.call('cmd', {'c': 'pset', 'a': {'MAX_SPD': 9}}))['err'], contains('not allowed'));
    expect((await s.call('cmd', {'c': 'mode', 'a': {'m': 'manual'}}))['ok'], isTrue);
    expect(d.links.values.single.tel.mode, 'MANUAL');
    await s.call('cmd', {'c': 'speed', 'a': {'v': 1}});
    expect(d.links.values.single.speed, .6);
    d.scripts.conns.single.limits.allowArm = true;
    expect((await s.call('cmd', {'c': 'arm'}))['ok'], isTrue);
  });

  test('leaving the geofence ends the script’s control', () async {
    final s = await _Script.open(d.scripts);
    await s.call('use');
    await s.call('sticks', {'a': {'throttle': 1}});
    final l = d.links.values.single;
    d.scripts.conns.single.limits.fence = 5;
    for (var i = 0; i < 40; i++) {
      s.send('ka');
      l.tel.pos = [i.toDouble(), 0, 0];
      await run(.05);
    }
    expect(l.drive, isNull);
    expect(s.got.lastWhere((m) => m['t'] == 'released')['why'], contains('geofence'));
    // It cannot simply take the sticks again: the operator decides.
    expect((await s.call('sticks', {'a': {'throttle': 1}}))['err'], contains('must resume'));
    d.scripts.unblock(d.scripts.conns.single);
    expect((await s.call('sticks', {'a': {'throttle': 0}}))['ok'], isTrue);
  });

  test('settings and triggers declared by the script, changed and fired from dash', () async {
    final s = await _Script.open(d.scripts);
    expect((await s.call('setting', {'name': 'speed', 'value': .4, 'min': 0, 'max': 1}))['value'], .4);
    await s.call('trigger', {'name': 'Drop payload', 'kind': 'button', 'key': 'D'});
    final c = d.scripts.conns.single;
    expect(c.triggers.keys, ['Drop payload']);
    d.scripts.setSetting(c, 'speed', .7);
    d.scripts.fire(c, 'Drop payload');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(s.got.firstWhere((m) => m['t'] == 'setting'), {'t': 'setting', 'name': 'speed', 'value': .7});
    expect(s.got.firstWhere((m) => m['t'] == 'fire')['name'], 'Drop payload');
    // Declaring it again (the script restarted) keeps the operator's value.
    expect((await s.call('setting', {'name': 'speed', 'value': .4, 'min': 0, 'max': 1}))['value'], .7);
  });
}
