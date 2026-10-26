import 'model.dart';
import 'telemetry.dart';

/// Warnings fire once; critical alerts repeat their sound until acknowledged.
enum AlertLevel { warning, critical }

/// What an alert watches. [read] returns null when the device does not
/// report it, so the alert never fires on a value it does not have.
class AlertRule {
  const AlertRule(
    this.id,
    this.label,
    this.desc,
    this.unit, {
    required this.below,
    required this.def,
    required this.hyst,
    required this.read,
    required this.act,
    this.level = AlertLevel.warning,
    this.on = true,
    this.kinds,
    this.digits = 0,
  });
  final String id, label, unit;

  /// What it watches, for the settings; what to do, for the banner.
  final String desc, act;

  /// Fires when the value drops below the limit (battery, signal) rather
  /// than rising above it (altitude, distance).
  final bool below;

  /// Default limit, and how far back the value must come to clear.
  final double def, hyst;
  final AlertLevel level;

  /// On by default.
  final bool on;

  /// Device kinds it applies to; null for all.
  final Set<DeviceKind>? kinds;
  final int digits;
  final double? Function(Telemetry t, double latencyMs) read;

  String fmt(double v) => '${v.toStringAsFixed(digits)} $unit';
}

double? _bat(Telemetry t, double _) => t.seen.contains('bat') ? t.battery : null;

final alertRules = <AlertRule>[
  AlertRule('battery', act: 'Time to bring it back.', 'Battery low', 'Charge left, as the device reports it.', '%', below: true, def: 25, hyst: 3, read: _bat),
  AlertRule(
    'batteryCritical',
    act: 'Land or stop now.',
    'Battery critical',
    'A second, louder limit: repeats until acknowledged.',
    '%',
    below: true,
    def: 10,
    hyst: 3,
    level: AlertLevel.critical,
    read: _bat,
  ),
  AlertRule(
    'voltage',
    act: 'Time to bring it back.',
    'Battery voltage',
    'For packs that do not report a percentage. Set the limit for your pack, for example 3.5 V per cell.',
    'V',
    below: true,
    def: 10.5,
    hyst: .2,
    on: false,
    digits: 1,
    read: (t, _) => t.seen.contains('bat') && t.voltage > 0 ? t.voltage : null,
  ),
  AlertRule(
    'obstacle',
    act: 'Steer away, or stop.',
    'Obstacle close',
    'The nearest thing a proximity sensor sees, while armed (sensors looking down do not count).',
    'm',
    below: true,
    def: .3,
    hyst: .1,
    digits: 2,
    read: (t, _) => t.armed ? t.nearestObstacle : null,
  ),
  AlertRule(
    'rssi',
    act: 'Move closer or turn back.',
    'Weak signal',
    'Received signal strength, when the link reports it.',
    'dBm',
    below: true,
    def: -85,
    hyst: 4,
    read: (t, _) => t.hasRssi ? t.rssi : null,
  ),
  AlertRule(
    'latency',
    act: 'Control will feel late.',
    'High latency',
    'Round trip of the link. Control feels late above a few hundred milliseconds.',
    'ms',
    below: false,
    def: 400,
    hyst: 100,
    read: (t, ms) => ms > 0 ? ms : null,
  ),
  AlertRule(
    'altitude',
    act: 'Descend.',
    'Altitude ceiling',
    'Height above home. 120 m is the usual limit for drones in Europe and the US.',
    'm',
    below: false,
    def: 120,
    hyst: 5,
    kinds: {DeviceKind.drone},
    read: (t, _) => t.seen.contains('pos') ? t.alt : null,
  ),
  AlertRule(
    'distance',
    act: 'Bring it closer.',
    'Distance from home',
    'A simple geofence: horizontal distance from where it started.',
    'm',
    below: false,
    def: 300,
    hyst: 10,
    kinds: {DeviceKind.drone, DeviceKind.rover},
    read: (t, _) => t.seen.contains('pos') ? t.range : null,
  ),
  AlertRule(
    'temp',
    act: 'Let it cool down.',
    'Temperature',
    'Motor, ESC or board temperature, when the device reports one.',
    '°C',
    below: false,
    def: 70,
    hyst: 3,
    read: (t, _) => t.seen.contains('temp') ? t.temp : null,
  ),
];

AlertRule? alertRule(String id) => alertRules.where((r) => r.id == id).firstOrNull;

/// Per-rule user settings: on/off and the limit.
class AlertPrefs {
  final Map<String, bool> on = {};
  final Map<String, double> limit = {};

  /// Sound on alerts and on link loss.
  bool sound = true;

  bool isOn(AlertRule r) => on[r.id] ?? r.on;
  double limitOf(AlertRule r) => limit[r.id] ?? r.def;

  Map<String, dynamic> toJson() => {'on': on, 'limit': limit, 'sound': sound};
  void load(Map? j) {
    if (j == null) return;
    final o = j['on'], l = j['limit'];
    if (o is Map) on.addAll({for (final e in o.entries) '${e.key}': e.value == true});
    if (l is Map) {
      limit.addAll({
        for (final e in l.entries)
          if (e.value is num) '${e.key}': (e.value as num).toDouble(),
      });
    }
    sound = j['sound'] ?? sound;
  }
}

class ActiveAlert {
  ActiveAlert(this.rule, this.value, this.limit);
  final AlertRule rule;
  double value, limit;
  bool acked = false;
}

/// Watches live telemetry against the rules. A rule fires once its value has
/// been past the limit for [settle] seconds, and clears when it comes back
/// past the limit by the rule's margin, so a value hovering at the limit
/// does not flicker.
class AlertMonitor {
  static const settle = 1.0, repeat = 6.0;

  /// Firing alerts, in rule order.
  final Map<String, ActiveAlert> active = {};
  final Map<String, double> _past = {};
  double _sinceSound = 0;

  List<ActiveAlert> get shown => [
    for (final a in active.values)
      if (!a.acked) a,
  ]..sort((a, b) => b.rule.level.index - a.rule.level.index);

  /// Advances by [dt] seconds. [notify] is called with the level of a newly
  /// fired alert, and again for critical alerts left unacknowledged.
  /// Returns true when the set of shown alerts changed.
  bool step(double dt, Telemetry t, DeviceKind kind, double latencyMs, AlertPrefs prefs, void Function(AlertLevel) notify) {
    var changed = false;
    for (final r in alertRules) {
      final v = (r.kinds == null || r.kinds!.contains(kind)) && prefs.isOn(r) ? r.read(t, latencyMs) : null;
      final lim = prefs.limitOf(r), a = active[r.id];
      if (v == null) {
        _past.remove(r.id);
        if (active.remove(r.id) != null) changed = true;
        continue;
      }
      if (a != null) {
        a
          ..value = v
          ..limit = lim;
        final clear = r.below ? v > lim + r.hyst : v < lim - r.hyst;
        if (clear) {
          active.remove(r.id);
          changed = true;
        }
        continue;
      }
      if (r.below ? v < lim : v > lim) {
        final p = (_past[r.id] ?? 0) + dt;
        _past[r.id] = p;
        if (p >= settle) {
          _past.remove(r.id);
          active[r.id] = ActiveAlert(r, v, lim);
          changed = true;
          _sinceSound = 0;
          notify(r.level);
        }
      } else {
        _past.remove(r.id);
      }
    }
    if (active.values.any((a) => !a.acked && a.rule.level == AlertLevel.critical)) {
      _sinceSound += dt;
      if (_sinceSound >= repeat) {
        _sinceSound = 0;
        notify(AlertLevel.critical);
      }
    }
    return changed;
  }

  void ack(String id) => active[id]?.acked = true;

  void clear() {
    active.clear();
    _past.clear();
  }
}
