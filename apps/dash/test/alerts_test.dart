import 'package:flutter_test/flutter_test.dart';
import 'package:koebelt_dash/core/alerts.dart';
import 'package:koebelt_dash/core/dash.dart';
import 'package:koebelt_dash/core/model.dart';
import 'package:koebelt_dash/core/telemetry.dart';
import 'package:shared_preferences/shared_preferences.dart';

Telemetry _tel({double? battery, double? alt, DeviceKind kind = DeviceKind.drone}) {
  final t = Telemetry(kind);
  if (battery != null) {
    t.applyTlm({
      'bat': [15.0, 10.0, battery],
    });
  }
  if (alt != null) {
    t.applyTlm({
      'pos': [0.0, 0.0, alt],
    });
  }
  return t;
}

void main() {
  group('monitor', () {
    test('fires after a second past the limit, once, and clears with margin', () {
      final m = AlertMonitor(), p = AlertPrefs(), fired = <AlertLevel>[];
      final t = _tel(battery: 30);
      for (var i = 0; i < 10; i++) {
        m.step(.2, t, DeviceKind.drone, 0, p, fired.add);
      }
      expect(m.active, isEmpty);
      t.battery = 24;
      m.step(.2, t, DeviceKind.drone, 0, p, fired.add);
      expect(m.active, isEmpty, reason: 'a spike under one second does not fire');
      for (var i = 0; i < 5; i++) {
        m.step(.2, t, DeviceKind.drone, 0, p, fired.add);
      }
      expect(m.active.keys, ['battery']);
      expect(fired, [AlertLevel.warning]);
      t.battery = 26; // back over the limit, but inside the margin
      m.step(.2, t, DeviceKind.drone, 0, p, fired.add);
      expect(m.active.keys, ['battery']);
      t.battery = 29;
      m.step(.2, t, DeviceKind.drone, 0, p, fired.add);
      expect(m.active, isEmpty);
      expect(fired, hasLength(1));
    });

    test('critical repeats until acknowledged; acknowledged hides the banner', () {
      final m = AlertMonitor(), p = AlertPrefs(), fired = <AlertLevel>[];
      final t = _tel(battery: 5);
      for (var i = 0; i < 5 * 14; i++) {
        m.step(.2, t, DeviceKind.drone, 0, p, fired.add);
      }
      expect(m.shown.first.rule.id, 'batteryCritical', reason: 'most severe first');
      expect(fired.where((l) => l == AlertLevel.critical).length, greaterThan(1));
      m.ack('batteryCritical');
      final n = fired.length;
      for (var i = 0; i < 5 * 14; i++) {
        m.step(.2, t, DeviceKind.drone, 0, p, fired.add);
      }
      expect(fired.length, n);
      expect(m.shown.map((a) => a.rule.id), ['battery']);
    });

    test('values the device does not send, other kinds and switched-off rules never fire', () {
      final m = AlertMonitor(), p = AlertPrefs(), fired = <AlertLevel>[];
      final rover = _tel(alt: 500, kind: DeviceKind.rover);
      for (var i = 0; i < 20; i++) {
        m.step(.2, rover, DeviceKind.rover, 0, p, fired.add);
      }
      expect(m.active, isEmpty, reason: 'no battery sent, altitude is for drones');
      final drone = _tel(alt: 500);
      p.on['altitude'] = false;
      for (var i = 0; i < 20; i++) {
        m.step(.2, drone, DeviceKind.drone, 0, p, fired.add);
      }
      expect(m.active, isEmpty);
      p.on['altitude'] = true;
      p.limit['altitude'] = 600;
      for (var i = 0; i < 20; i++) {
        m.step(.2, drone, DeviceKind.drone, 0, p, fired.add);
      }
      expect(m.active, isEmpty, reason: 'own limit');
    });

    test('prefs round-trip', () {
      final p = AlertPrefs()
        ..sound = false
        ..on['voltage'] = true
        ..limit['voltage'] = 14.2;
      final q = AlertPrefs()..load(p.toJson());
      expect(q.sound, isFalse);
      expect(q.isOn(alertRule('voltage')!), isTrue);
      expect(q.limitOf(alertRule('voltage')!), 14.2);
    });
  });

  test('a simulated drone over its battery limit raises an alert', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    final d = Dash();
    await d.init();
    d.updateAlerts((p) {
      p.sound = false;
      p.limit['battery'] = 101;
    });
    final dev = d.addSimulated(simTemplates().first);
    await d.connect(dev.id);
    for (var i = 0; i < 40 && d.alerts.shown.isEmpty; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      d.tick(.05);
    }
    expect(d.alerts.shown.map((a) => a.rule.id), contains('battery'));
    d.ackAlert('battery');
    expect(d.alerts.shown.map((a) => a.rule.id), isNot(contains('battery')));
    await d.disconnect();
    expect(d.alerts.active, isEmpty);
    d.dispose();
  });
}
