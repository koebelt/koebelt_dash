// Proximity sensors: the simulator's, through hello and telemetry, to the
// Live widget, the alert, conditions and scripts' capabilities.
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:koebelt_dash/core/alerts.dart';
import 'package:koebelt_dash/core/dash.dart';
import 'package:koebelt_dash/core/model.dart';
import 'package:koebelt_dash/core/telemetry.dart';
import 'package:koebelt_dash/screens/tiles.dart';
import 'package:koebelt_dash/scripts/fields.dart';
import 'package:koebelt_dash/scripts/requirements.dart';
import 'package:koebelt_dash/sim/sim_camera.dart';
import 'package:koebelt_dash/sim/sim_device.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the simulated rover sees the ball in front, not behind', () {
    final sim = SimDevice(DeviceInfo(id: 'r', name: 'R', kind: DeviceKind.rover));
    sim.t = 40;
    final b = SimCamera.ballAt(sim.t);
    final (feet, _) = SimCamera.personAt(sim.t);
    // Two metres short of the ball, facing it (away from the person).
    final a = math.atan2(b[1], b[0]);
    sim.pos = [b[0] - 2 * math.cos(a), b[1] - 2 * math.sin(a), 0];
    sim.yaw = a;
    sim.env = const [];
    expect(math.sqrt(math.pow(feet[0] - sim.pos[0], 2) + math.pow(feet[1] - sim.pos[1], 2)), greaterThan(4.5), reason: 'the person is out of range');
    final ids = [for (final p in sim.proxSensors) p.id];
    final v = sim.proxReadings();
    expect(ids, ['front', 'front_left', 'front_right', 'rear']);
    expect(v[0], closeTo(2 - SimCamera.ballRadius, .02), reason: 'front: the ball');
    expect(v[3], -1, reason: 'rear: nothing');
    final drone = SimDevice(DeviceInfo(id: 'd', name: 'D', kind: DeviceKind.drone))..pos = [0, 0, 5.5];
    expect(drone.proxReadings().last, closeTo(5.5, 1e-9), reason: 'down: its height');
  });

  test('from hello to the widget, the nearest obstacle, conditions, capabilities and the alert', () async {
    SharedPreferences.setMockInitialValues({});
    final d = Dash();
    await d.init();
    final mule = d.addSimulated(simTemplates().firstWhere((t) => t.id == 'mule'));
    await d.connect(mule.id);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final l = d.links.values.single;
    expect([for (final p in l.info.prox) p.id], ['front', 'front_left', 'front_right', 'rear'], reason: 'declared in hello');
    expect(l.tel.seen, contains('prox'));
    expect(l.tel.prox, hasLength(4));
    expect(capabilitiesOf(l.info, l), contains('proximity'));
    expect(tileById(d, 'prox'), isNotNull, reason: 'a Live widget');

    // Something 0.2 m in front, nothing elsewhere.
    l.tel.prox = [.2, -1, -1, -1];
    expect((d.nearest!.sensor.id, d.nearest!.d), ('front', .2));
    expect(tileById(d, 'prox')!.val(d), '0.20 m · front');
    final f = fieldsOf(l);
    expect((f(['prox', 'front']), f(['prox', 'rear']), f(['prox', 'nearest'])), (.2, double.infinity, .2));
    expect(conditionFields(DeviceKind.rover, prox: l.info.prox).map((x) => x.field), containsAll(['prox.nearest', 'prox.front']));

    // The alert: only while armed, only sensors that look ahead.
    final m = AlertMonitor(), p = AlertPrefs(), fired = <AlertLevel>[];
    final t = Telemetry(DeviceKind.rover)
      ..seen.add('prox')
      ..prox = [.2, -1]
      ..proxDown = [false, true];
    for (var i = 0; i < 8; i++) {
      m.step(.2, t, DeviceKind.rover, 0, p, fired.add);
    }
    expect(m.active.keys, isNot(contains('obstacle')), reason: 'disarmed');
    t.armed = true;
    for (var i = 0; i < 8; i++) {
      m.step(.2, t, DeviceKind.rover, 0, p, fired.add);
    }
    expect(m.active.keys, contains('obstacle'));
    t
      ..prox = [-1, .05]
      ..armed = true;
    final m2 = AlertMonitor();
    for (var i = 0; i < 8; i++) {
      m2.step(.2, t, DeviceKind.rover, 0, p, fired.add);
    }
    expect(m2.active.keys, isNot(contains('obstacle')), reason: 'a sensor looking down reads the ground, not an obstacle');

    await d.disconnectAll();
  });
}
