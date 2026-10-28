import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:koebelt_dash/core/dash.dart';
import 'package:koebelt_dash/core/sequence.dart';
import 'package:koebelt_dash/scripts/script_hub.dart';
import 'package:koebelt_dash/scripts/triggers.dart';
import 'package:koebelt_dash/screens/tiles.dart' show scriptTiles;
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

  test('a device that does not fit the script is refused, with what it lacks', () async {
    final s = await _Script.open(d.scripts);
    final r = await s.call('use', {
      'requires': ['drone', 'gps'],
    });
    expect(r['code'], 'E0004');
    expect(r['data']['missing'], ['a drone (Mule is a rover)']);
    expect(
      (await s.call('use', {
        'requires': ['rover', 'lidar'],
      }))['ok'],
      isTrue,
    );
  });

  test('a script drives with named sticks, scaled by its speed limit, and gets telemetry', () async {
    final s = await _Script.open(d.scripts);
    expect(s.got.first['t'], 'welcome');
    final use = await s.call('use');
    expect(use['value']['kind'], 'rover');
    expect(use['value']['sim'], isTrue);
    final l = d.links.values.single;

    expect(
      (await s.call('sticks', {
        'a': {'throttle': 1, 'steer': -.5},
      }))['ok'],
      isTrue,
    );
    expect(l.drive, isNotNull);
    // Limit 60 %: forward is the right stick's y, steering the left stick's x.
    expect(l.drive!.axes(l.input), [closeTo(-.3, 1e-9), 0, 0, closeTo(.6, 1e-9)]);

    final bad = await s.call('sticks', {
      'a': {'pitch': 1},
    });
    expect(bad['err'], contains('not a stick of a rover'));

    await run(.3);
    expect(s.got.where((m) => m['t'] == 'tlm'), isNotEmpty);
    expect(s.got.lastWhere((m) => m['t'] == 'tlm')['d']['drive'], 'script');
  });

  test('the operator’s sticks take over until Resume', () async {
    final s = await _Script.open(d.scripts);
    await s.call('use');
    await s.call('sticks', {
      'a': {'throttle': 1},
    });
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
    await s.call('sticks', {
      'a': {'throttle': 1},
    });
    final l = d.links.values.single;
    await run(.3);
    expect(l.drive, isNotNull, reason: 'within the watchdog');
    await run(.6);
    expect(l.drive, isNull);
    expect(l.tel.mode, 'HOLD');
    expect(
      (await s.call('sticks', {
        'a': {'throttle': 1},
      }))['err'],
      contains('stopped responding'),
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(s.got.lastWhere((m) => m['t'] == 'released')['why'], contains('stopped responding'));
  });

  test('a script that disconnects loses the device too', () async {
    final s = await _Script.open(d.scripts);
    await s.call('use');
    await s.call('sticks', {
      'a': {'throttle': 1},
    });
    await s.ws.close();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(d.links.values.single.drive, isNull);
    expect(d.scripts.conns, isEmpty);
  });

  test('STOP releases every script and refuses their commands until cleared', () async {
    final s = await _Script.open(d.scripts);
    await s.call('use');
    await s.call('sticks', {
      'a': {'throttle': 1},
    });
    d.emergencyStop();
    expect(d.links.values.single.drive, isNull);
    final r = await s.call('sticks', {
      'a': {'throttle': 1},
    });
    expect(r['err'], contains('STOP is on'));
    expect(
      (await s.call('cmd', {
        'c': 'mode',
        'a': {'m': 'AUTO'},
      }))['ok'],
      isFalse,
    );
  });

  test('limits: no arming or parameter writes unless the operator allows them; speed capped', () async {
    final s = await _Script.open(d.scripts);
    await s.call('use');
    expect((await s.call('cmd', {'c': 'arm'}))['err'], contains('not allowed'));
    expect(
      (await s.call('cmd', {
        'c': 'mode',
        'a': {'m': 'TAKEOFF'},
      }))['err'],
      contains('not allowed'),
    );
    expect(
      (await s.call('cmd', {
        'c': 'pset',
        'a': {'MAX_SPD': 9},
      }))['err'],
      contains('not allowed'),
    );
    expect(
      (await s.call('cmd', {
        'c': 'mode',
        'a': {'m': 'manual'},
      }))['ok'],
      isTrue,
    );
    // dash chooses MANUAL and AUTO: the script is told once, the mode stays.
    expect(d.links.values.single.tel.mode, 'HOLD');
    await s.call('cmd', {
      'c': 'mode',
      'a': {'m': 'AUTO'},
    });
    final told = d.scripts.conns.single.console.where((l) => l.text.contains('does nothing')).toList();
    expect((told.length, told.single.level), (1, 'warn'));
    expect(d.links.values.single.tel.mode, 'HOLD');
    await s.call('cmd', {
      'c': 'speed',
      'a': {'v': 1},
    });
    expect(d.links.values.single.speed, .6);
    d.scripts.conns.single.limits.allowArm = true;
    expect((await s.call('cmd', {'c': 'arm'}))['ok'], isTrue);
  });

  test('leaving the geofence ends the script’s control', () async {
    final s = await _Script.open(d.scripts);
    await s.call('use');
    await s.call('sticks', {
      'a': {'throttle': 1},
    });
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
    expect(
      (await s.call('sticks', {
        'a': {'throttle': 1},
      }))['err'],
      contains('must resume'),
    );
    d.scripts.unblock(d.scripts.conns.single);
    expect(
      (await s.call('sticks', {
        'a': {'throttle': 0},
      }))['ok'],
      isTrue,
    );
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

  group('steps and sequences', () {
    Future<Map<String, dynamic>> callWhileTicking(_Script s, String t, Map<String, dynamic> m, double seconds) async {
      final f = s.call(t, m).timeout(Duration(milliseconds: (seconds * 1000).round() + 3000));
      var done = false;
      unawaited(f.whenComplete(() => done = true));
      for (var i = 0; i < seconds * 40 && !done; i++) {
        d.tick(.025);
        await Future<void>.delayed(const Duration(milliseconds: 25));
      }
      return f;
    }

    test('a step answers when it is done, and refuses what the device or the limits do not allow', () async {
      final s = await _Script.open(d.scripts);
      await s.call('use');
      final sw = Stopwatch()..start();
      final r = await callWhileTicking(s, 'cmd', {
        'c': 'step',
        'a': {'type': 'wait', 's': .4},
      }, 3);
      expect(r['ok'], isTrue, reason: '$r');
      expect(sw.elapsedMilliseconds, greaterThan(350), reason: 'answered when done');
      expect(
        (await s.call('cmd', {
          'c': 'step',
          'a': {'type': 'takeoff'},
        }))['err'],
        contains('not a step a rover has'),
      );
      expect(
        (await s.call('cmd', {
          'c': 'step',
          'a': {'type': 'goto', 'x': 80, 'y': 0},
        }))['err'],
        contains('beyond the 50 m geofence'),
      );
      expect(
        (await s.call('cmd', {
          'c': 'step',
          'a': {'type': 'wait', 's': 5, 'wait': false},
        }))['ok'],
        isTrue,
        reason: 'returns at once',
      );
      expect(
        (await s.call('cmd', {
          'c': 'step',
          'a': {'type': 'wait', 's': 1},
        }))['err'],
        contains('is running on Mule'),
      );
    });

    test('the operator taking over interrupts the step the script waits on', () async {
      final s = await _Script.open(d.scripts);
      await s.call('use');
      final f = s.call('cmd', {
        'c': 'step',
        'a': {'type': 'goto', 'x': 20, 'y': 0},
      });
      await run(.3);
      d.goManual();
      await run(.2);
      expect((await f)['err'], contains('manual control'));
    });

    test('sequences, by name', () async {
      final s = await _Script.open(d.scripts);
      await s.call('use');
      final l = d.links.values.single;
      d
          .sequencesFor(l.id)
          .add(
            Sequence(
              id: 'q1',
              name: 'Short wait',
              kind: l.kind,
              steps: [
                SeqStep('wait', {'s': .3}),
              ],
            ),
          );
      expect(
        (await s.call('cmd', {
          'c': 'program',
          'a': {'name': 'nope'},
        }))['err'],
        contains('No sequence called "nope"'),
      );
      final r = await callWhileTicking(s, 'cmd', {
        'c': 'program',
        'a': {'name': 'short wait'},
      }, 3);
      expect(r['ok'], isTrue, reason: '$r');
    });
  });

  group('triggers', () {
    Future<(_Script, ScriptConn)> declared() async {
      final s = await _Script.open(d.scripts);
      await s.call('use');
      await s.call('trigger', {'name': 'Drop payload', 'kind': 'button', 'key': 'd', 'gamepad': 'LT'});
      await s.call('trigger', {'name': 'Patrol', 'kind': 'switch'});
      return (s, d.scripts.conns.single);
    }

    List<Map<String, dynamic>> fired(_Script s) => [
      for (final m in s.got)
        if (m['t'] == 'fire') m,
    ];

    test('a declared trigger gets its on-screen control and suggested bindings, and the operator’s setup wins', () async {
      final (_, c) = await declared();
      expect(
        [for (final b in c.config.bindings) '${b.event}/${b.source.name}/${b.key ?? b.pad ?? ''}'],
        ['Drop payload/button/', 'Drop payload/key/D', 'Drop payload/pad/n:leftTrigger', 'Patrol/toggle/'],
      );
      c.config.bindings.removeWhere((b) => b.source == TriggerSource.key);
      expect(c.config.adopt({'name': 'Drop payload', 'key': 'D'}), isFalse, reason: 'already set up');
      expect(c.config.bindings.where((b) => b.source == TriggerSource.key), isEmpty);
    });

    test('keys and controller buttons fire; switches toggle', () async {
      final (s, _) = await declared();
      expect(d.scripts.onKey('D'), isTrue);
      expect(d.scripts.onKey('Q'), isFalse);
      d.padMapper.input('n:leftTrigger', 1, button: true);
      d.padMapper.input('n:leftTrigger', 0, button: true);
      final c = d.scripts.conns.single;
      c.config.bindings.add(TriggerBinding('Patrol', TriggerSource.key, key: 'P'));
      d.scripts.onKey('P');
      d.scripts.onKey('P');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect([for (final m in fired(s)) '${m['name']}:${m['value']}'], ['Drop payload:null', 'Drop payload:null', 'Patrol:true', 'Patrol:false']);
    });

    test('a condition fires once it has held, and again only after it clears', () async {
      final (s, c) = await declared();
      c.config.bindings.add(TriggerBinding('Far', TriggerSource.condition, expr: 'script.x > 10 for 0.3s', both: true));
      s.send('plot', {'name': 'x', 'v': 20});
      for (var i = 0; i < 8; i++) {
        s.send('ka');
        await run(.1);
      }
      s.send('plot', {'name': 'x', 'v': 0});
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await run(.2);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect([for (final m in fired(s)) '${m['name']}:${m['value']}'], ['Far:true', 'Far:false']);
    });

    test('device events and timers', () async {
      final (s, c) = await declared();
      c.config.bindings
        ..add(TriggerBinding('Holding', TriggerSource.event, deviceEvent: 'mode', match: 'hold'))
        ..add(TriggerBinding('Tick', TriggerSource.timer, seconds: .3))
        ..add(TriggerBinding('Once', TriggerSource.timer, seconds: .2, repeat: false));
      final l = d.links.values.single;
      await run(.15);
      d.linkHost(l).seqSetMode('MANUAL');
      await run(.15);
      d.linkHost(l).seqSetMode('HOLD');
      for (var i = 0; i < 7; i++) {
        s.send('ka');
        await run(.1);
      }
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final names = [for (final m in fired(s)) m['name']];
      expect(names.where((n) => n == 'Holding'), hasLength(1), reason: 'MANUAL does not match');
      expect(names.where((n) => n == 'Once'), hasLength(1));
      expect(names.where((n) => n == 'Tick').length, inInclusiveRange(2, 4));
    });

    test('setups are kept per script and survive a restart of dash', () async {
      final (_, c) = await declared();
      c.limits.maxSpeed = .3;
      d.scripts.saveConfigs();
      final again = Dash(store: d.store);
      again.scripts.load();
      final k = again.scripts.configs['name:test.py']!;
      expect(k.limits.maxSpeed, .3);
      expect(k.bindings.map((b) => b.source.name), ['button', 'key', 'pad', 'toggle']);
    });
  });

  test('what a script shows: pictures, charts and plotted series, as Live widgets', () async {
    final s = await _Script.open(d.scripts);
    await s.call('use');
    s.send('view', {
      'name': 'tracking',
      'kind': 'picture',
      'data': base64Encode([1, 2, 3]),
      'w': 640,
      'h': 480,
    });
    s.send('view', {
      'name': 'scan',
      'kind': 'chart',
      'chart': 'scatter',
      'series': {
        'd': [1, 2, null],
      },
      'x': [0, 1, 2],
    });
    s.send('plot', {
      'name': 'speed',
      'v': [2, 1.5],
      'labels': ['target', 'actual'],
    });
    s.send('plot', {'name': 'alt', 'v': 4});
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final l = d.links.values.single;
    expect(l.views.keys, ['tracking', 'scan', 'speed', 'alt']);
    expect(l.views['tracking']!.width, 640);
    expect(l.views['tracking']!.image, [1, 2, 3]);
    expect(l.views['scan']!.chart, 'scatter');
    expect(l.views['scan']!.series['d']![2].isNaN, isTrue, reason: 'a gap');
    expect(l.tel.custom['script:speed'], [2, 1.5]);
    expect(l.views['speed']!.labels, ['target', 'actual']);
    expect(l.views['alt']!.labels, ['alt']);
    expect([for (final t in scriptTiles(d)) t.id], ['sv:tracking', 'sv:scan', 'sv:speed', 'sv:alt']);
    await s.ws.close();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(l.views['tracking']!.ended, isTrue, reason: 'the last picture stays, marked as ended');
  });

  test('a script does not start without a connected device', () async {
    final file = File('${Directory.systemTemp.createTempSync('kdash_nodev').path}/s.py')..writeAsStringSync('print(1)\n');
    await d.disconnectAll();
    expect(d.scripts.whyNotRun, contains('No device connected'));
    await expectLater(d.scripts.runFile(file, python: 'python3'), throwsA(isA<StateError>()));
    expect(d.scripts.runs, isEmpty);
  });

  _Script? s0;
  test('modes: HOLD on connect, MANUAL when armed, AUTO only while a script or a sequence drives', () async {
    final l = d.links.values.single;
    // Until [ok], with the simulator's replies (real time): at most 10 s, as
    // a loaded CI machine can hold a reply back for seconds.
    Future<void> until(bool Function() ok, {int steps = 500}) async {
      for (var i = 0; i < steps && !ok(); i++) {
        s0?.send('ka');
        d.tick(.05);
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    }

    await until(() => l.tel.mode == 'HOLD');
    expect((l.tel.armed, l.tel.mode), (false, 'HOLD'), reason: 'it powers on disarmed in HOLD');
    d.setArmed(true);
    await until(() => l.tel.armed && l.tel.mode == 'MANUAL');
    expect(l.tel.mode, 'MANUAL', reason: 'armed: the operator\'s');

    // A script drives it: AUTO. The operator takes over: MANUAL. Resume: AUTO.
    final s = s0 = await _Script.open(d.scripts);
    await s.call('use');
    await s.call('sticks', {
      'a': {'throttle': .3},
    });
    await until(() => l.tel.mode == 'AUTO');
    expect(l.tel.mode, 'AUTO');
    expect(d.automation, 'Script · ${d.scripts.conns.single.name}');
    // The operator moves a stick: what the control heartbeat reads next.
    l.drive!.axes([0, 0, 0, .8]);
    await until(() => l.tel.mode == 'MANUAL');
    expect((l.drive!.paused, l.tel.mode), (true, 'MANUAL'));
    d.scripts.resume(l);
    await until(() => l.tel.mode == 'AUTO');
    expect(l.tel.mode, 'AUTO');

    // The script asks for HOLD: it stops driving, and it stays in HOLD.
    await s.call('cmd', {
      'c': 'mode',
      'a': {'m': 'HOLD'},
    });
    await until(() => l.drive == null && l.tel.mode == 'HOLD');
    // And it stays so: dash does not put it back in AUTO (two seconds).
    await until(() => l.tel.mode != 'HOLD' || l.drive != null, steps: 100);
    expect((l.drive, l.tel.mode), (null, 'HOLD'));

    // A sequence runs in AUTO; choosing MANUAL takes it back and stops it.
    d.runSequenceOn(
      l,
      Sequence(
        id: 'w',
        name: 'Wait',
        kind: l.kind,
        steps: [
          SeqStep('wait', {'s': 30.0}),
        ],
      ),
    );
    await until(() => l.tel.mode == 'AUTO');
    expect((l.tel.mode, d.automation), ('AUTO', 'Sequence · Wait'));
    d.operatorMode('MANUAL');
    await until(() => l.tel.mode == 'MANUAL');
    expect((l.tel.mode, l.runner!.state), ('MANUAL', RunState.failed));
  });
}
