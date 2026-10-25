import 'dart:math' as math;

import '../core/device_link.dart';
import '../core/model.dart';
import 'conditions.dart';

/// The fields conditions can read on a device, with a label and unit for the
/// picker. Custom channels the device declares come on top.
List<({String field, String label, String unit})> conditionFields(DeviceKind kind) => [
  (field: 'battery.pct', label: 'Battery', unit: '%'),
  (field: 'battery.v', label: 'Battery voltage', unit: 'V'),
  if (kind == DeviceKind.drone || kind == DeviceKind.rover || kind == DeviceKind.rocket || kind == DeviceKind.generic) ...[
    (field: 'home.distance', label: 'Distance from home', unit: 'm'),
    (field: 'alt', label: 'Height above home', unit: 'm'),
    (field: 'speed', label: 'Speed', unit: 'm/s'),
    (field: 'heading', label: 'Heading', unit: '°'),
  ],
  if (kind == DeviceKind.drone) ...[(field: 'roll', label: 'Roll', unit: '°'), (field: 'pitch', label: 'Pitch', unit: '°')],
  if (kind == DeviceKind.arm) (field: 'gripper', label: 'Gripper', unit: '%'),
  if (kind == DeviceKind.bench) ...[
    (field: 'thrust', label: 'Thrust', unit: 'N'),
    (field: 'rpm', label: 'RPM', unit: ''),
    (field: 'temp', label: 'Temperature', unit: '°C'),
  ],
  (field: 'link.rssi', label: 'Signal', unit: 'dBm'),
  (field: 'link.latency', label: 'Latency', unit: 'ms'),
  (field: 'gps.sats', label: 'GPS satellites', unit: ''),
];

/// Looks fields up in a device's live telemetry.
FieldLookup fieldsOf(DeviceLink l) {
  final t = l.tel;
  return (path) {
    final head = path.first, rest = path.skip(1).toList();
    Object? sub(Map<String, Object?> m) => rest.length == 1 ? m[rest.single] : null;
    switch (head) {
      case 'battery':
        if (!t.seen.contains('bat')) return null;
        return rest.isEmpty ? t.battery : sub({'pct': t.battery, 'v': t.voltage, 'a': t.current});
      case 'alt':
        return t.pos[2];
      case 'pos':
        return rest.isEmpty ? t.pos : sub({'x': t.pos[0], 'y': t.pos[1], 'z': t.pos[2]});
      case 'home':
        return sub({'distance': math.sqrt(t.pos[0] * t.pos[0] + t.pos[1] * t.pos[1])});
      case 'speed':
        return math.sqrt(t.vel[0] * t.vel[0] + t.vel[1] * t.vel[1] + t.vel[2] * t.vel[2]);
      case 'climb':
        return t.vel[2];
      case 'heading':
        return t.heading;
      case 'roll':
        return t.roll * 180 / math.pi;
      case 'pitch':
        return t.pitch * 180 / math.pi;
      case 'mode':
        return t.mode;
      case 'armed':
        return t.armed;
      case 'failsafe':
        return t.failsafe;
      case 'estop':
        return t.estop;
      case 'link':
        return sub({'rssi': t.hasRssi ? t.rssi : null, 'latency': l.session.latency * 1000});
      case 'gps':
        if (!t.hasGps) return null;
        return sub({'lat': t.lat, 'lon': t.lon, 'alt': t.gpsAlt, 'sats': t.sats});
      case 'gripper':
        return t.gripper * 100;
      case 'joints':
        return rest.isEmpty ? t.joints : _index(t.joints, rest.single);
      case 'thrust':
        return t.thrust;
      case 'torque':
        return t.torque;
      case 'rpm':
        return t.rpm;
      case 'temp':
        return t.temp;
      case 'throttle':
        return t.throttleOut * 100;
      case 'script':
        // Values a script plots: script.target_x
        return rest.length == 1 ? _channel(t.custom['script:${rest.single}'], const []) : null;
    }
    // A custom channel the device declares: motor_temp, motor_temp.max, motor_temp[2]
    return _channel(t.custom[head], rest);
  };
}

Object? _index(List<double> v, String i) {
  final n = int.tryParse(i);
  return n == null || n < 0 || n >= v.length ? null : v[n];
}

Object? _channel(List<double>? v, List<String> rest) {
  if (v == null || v.isEmpty) return null;
  if (rest.isEmpty) return v.first;
  if (rest.length != 1) return null;
  return switch (rest.single) {
    'max' => v.reduce(math.max),
    'min' => v.reduce(math.min),
    'avg' => v.reduce((a, b) => a + b) / v.length,
    final i => _index(v, i),
  };
}
