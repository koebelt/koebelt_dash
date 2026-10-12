// Several devices connected at once: the focused one gets the sticks, the
// others hold on centred sticks without tripping their failsafe; STOP stops
// them all; alerts, sequences and recordings work per device.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:koebelt_dash/core/dash.dart';
import 'package:koebelt_dash/core/model.dart';
import 'package:koebelt_dash/core/sequence.dart';
import 'package:koebelt_dash/core/store.dart';
import 'package:koebelt_dash/screens/replay.dart' show sessionEntries, groupTitle;
import 'package:shared_preferences/shared_preferences.dart';

Future<void> run(Dash d, int ms, {bool Function()? until}) async {
  final sw = Stopwatch()..start();
  while (sw.elapsedMilliseconds < ms && !(until?.call() ?? false)) {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    d.tick(.02);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => HttpOverrides.global = null); // simulated cameras are real HTTP
  late Directory tmp;
  late Dash d;
  late DeviceInfo kite, mule, cell;

  setUp(() async {
    tmp = Directory.systemTemp.createTempSync('kdash-multi');
    SharedPreferences.setMockInitialValues({});
    d = Dash(store: Store(recordingsRoot: tmp.path));
    await d.init();
    d.updateSettings((s) => s.recordVideo = false);
    kite = d.addSimulated(simTemplates().firstWhere((t) => t.kind == DeviceKind.drone));
    mule = d.addSimulated(simTemplates().firstWhere((t) => t.kind == DeviceKind.rover));
    cell = d.addSimulated(simTemplates().firstWhere((t) => t.kind == DeviceKind.arm));
    await d.connect(kite.id);
    await d.connect(mule.id);
  });
  tearDown(() async {
    await d.disconnectAll();
    d.dispose();
    tmp.deleteSync(recursive: true);
  });

  test('both stay connected; the last one connected is shown', () async {
    expect(d.links.keys, [kite.id, mule.id]);
    expect(d.deviceId, mule.id);
    expect(d.device?.name, mule.name);
    // Connecting one that is already connected only shows it.
    await d.connect(kite.id);
    expect(d.deviceId, kite.id);
    expect(d.links, hasLength(2));
    d.focusNth(1);
    expect(d.deviceId, mule.id);
    d.focusNext();
    expect(d.deviceId, kite.id);
  });

  test('background devices keep their heartbeat: no failsafe after 3 s', () async {
    await run(d, 3000);
    for (final l in d.links.values) {
      expect(l.linkLostFor, 0, reason: l.info.name);
      expect(l.tel.failsafe, isFalse, reason: '${l.info.name} must not fail over while not shown');
    }
  });

  test('sticks drive only the focused device; switching centres the old one', () async {
    d.focusDevice(kite.id);
    d.setArmed(true);
    await run(d, 300);
    d.padMapper.input('n:leftStickY', 1);
    final k = d.links[kite.id]!, m = d.links[mule.id]!;
    expect(k.input[1], 1);
    expect(m.input, everyElement(0));
    d.focusDevice(mule.id);
    expect(k.input, everyElement(0), reason: 'the drone holds instead of keeping full throttle');
    d.padMapper.input('n:leftStickY', 0);
  });

  test('STOP stops every connected device; reset clears them all', () async {
    for (final id in [kite.id, mule.id]) {
      d.focusDevice(id);
      d.setArmed(true);
    }
    await run(d, 300);
    d.emergencyStop();
    await run(d, 600);
    for (final l in d.links.values) {
      expect(l.tel.estop, isTrue, reason: l.info.name);
      expect(l.tel.armed, isFalse, reason: l.info.name);
    }
    d.resetStop();
    await run(d, 600);
    for (final l in d.links.values) {
      expect(l.tel.estop, isFalse, reason: l.info.name);
    }
  });

  test('STOP and reset reach the devices while a replay is open', () async {
    d.loadSamples();
    d.openReplay(d.sessions.first.id);
    d.emergencyStop();
    await run(d, 600);
    expect(d.links.values.every((l) => l.tel.estop), isTrue);
    d.resetStop();
    await run(d, 1200);
    for (final l in d.links.values) {
      expect(l.tel.estop, isFalse, reason: '${l.info.name}: the reset must not stay in the app');
    }
  });

  test('alerts are watched on every device, not only the one shown', () async {
    d.updateAlerts((p) {
      p.sound = false;
      p.limit['battery'] = 101;
    });
    await run(d, 3000, until: () => d.links.values.every((l) => l.alerts.shown.isNotEmpty));
    for (final l in d.links.values) {
      expect(l.alerts.shown.map((a) => a.rule.id), contains('battery'), reason: l.info.name);
    }
    d.ackAlert('battery', on: kite.id);
    expect(d.links[kite.id]!.alerts.shown.map((a) => a.rule.id), isNot(contains('battery')));
    expect(d.links[mule.id]!.alerts.shown.map((a) => a.rule.id), contains('battery'));
  });

  test('each device runs its own sequence at the same time', () async {
    Sequence wait(String id, DeviceKind k) => Sequence(
      id: id,
      name: id,
      kind: k,
      steps: [
        SeqStep('wait', {'s': 1.0}),
      ],
    );
    d.focusDevice(kite.id);
    d.runSequence(wait('a', DeviceKind.drone));
    d.focusDevice(mule.id);
    d.runSequence(wait('b', DeviceKind.rover));
    final ra = d.links[kite.id]!.runner!, rb = d.links[mule.id]!.runner!;
    await run(d, 8000, until: () => ra.state == RunState.done && rb.state == RunState.done);
    expect((ra.state, rb.state), (RunState.done, RunState.done), reason: '${ra.message} / ${rb.message}');
  });

  test('Record captures every connected device, grouped', () async {
    d.startRec();
    await d.connect(cell.id); // joins the running recording
    await run(d, 1200);
    d.stopRec();
    await run(d, 300);
    final group = d.lastSaved!.group;
    expect(group, isNotNull);
    final recs = d.sessions.where((s) => s.group == group).toList();
    expect(recs.map((r) => r.deviceName).toSet(), {kite.name, mule.name, cell.name});
    expect(recs.map((r) => r.id).toSet(), hasLength(3));
    expect(recs.every((r) => r.name.startsWith('Session 1 · ')), isTrue, reason: recs.map((r) => r.name).toList().toString());
    expect(d.lastSaved!.deviceId, d.deviceId, reason: 'the one shown is the one opened');
    // Listed as one session with its devices under it, among single recordings.
    d.loadSamples();
    final entries = sessionEntries(d.sessions);
    final e = entries.firstWhere((e) => e.length > 1);
    expect(e.map((r) => r.deviceName).toList(), [cell.name, kite.name, mule.name]..sort());
    expect(groupTitle(e.first), 'Session 1');
    expect(entries.length, d.sessions.length - 2, reason: 'three recordings, one entry');

    // Replaying one plays the session: the others on the same clock.
    final kiteRec = e.firstWhere((r) => r.deviceName == kite.name);
    d.openReplay(kiteRec.id);
    final r = d.replay!;
    expect(r.mates.map((m) => m.rec.deviceName).toSet(), {mule.name, cell.name});
    expect(r.dur, e.map((x) => x.dur).reduce((a, b) => a > b ? a : b), reason: 'the timeline spans the session');
    d.seekReplay(r.dur * .8);
    d.tick(0);
    final muleTel = r.mates.firstWhere((m) => m.rec.deviceName == mule.name).tel;
    expect(muleTel.lat, isNot(0), reason: 'the rover is placed on the map');
    expect(d.companions.map((c) => c.name).toSet(), {mule.name, cell.name});
    // Showing another device keeps the moment.
    final at = r.t;
    d.showCompanion(r.mates.firstWhere((m) => m.rec.deviceName == mule.name).rec.id);
    expect(d.replay!.session.deviceName, mule.name);
    expect(d.replay!.t, at);
    expect(d.companions.map((c) => c.name).toSet(), {kite.name, cell.name});
    d.closeReplay();
  });

  test('disconnecting the shown device shows another; at most maxLinks', () async {
    await d.disconnect();
    expect(d.deviceId, kite.id);
    expect(d.links.keys, [kite.id]);
    await d.disconnect();
    expect(d.hasDevice, isFalse);
    expect(Dash.maxLinks, greaterThanOrEqualTo(4));
  });
}
