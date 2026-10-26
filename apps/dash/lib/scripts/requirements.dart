import '../core/device_link.dart';
import '../core/model.dart';

/// What a script needs from a device, from `# requires:` lines in its first
/// lines (read by dash without Python, so phones check it too):
///
///     # requires: drone, rover      a kind: any one of them
///     # requires: gps, camera       capabilities: all of them
///
/// Words that are kinds (drone, rover, arm, rocket, bench, generic) choose
/// the kinds; the others are capabilities (see [capabilitiesOf]).
class ScriptRequirements {
  const ScriptRequirements({this.kinds = const {}, this.needs = const []});
  final Set<DeviceKind> kinds;
  final List<String> needs;

  bool get isEmpty => kinds.isEmpty && needs.isEmpty;

  static ScriptRequirements parse(String source, {List<String> extra = const []}) {
    final words = <String>[...extra];
    for (final line in source.split('\n').take(40)) {
      final m = RegExp(r'^\s*#\s*requires\s*:\s*(.*)$', caseSensitive: false).firstMatch(line);
      // A comment after the list is not part of it.
      if (m != null) words.addAll(m[1]!.split('#').first.split(RegExp(r'[,\s]+')));
    }
    final kinds = <DeviceKind>{}, needs = <String>[];
    for (final w in words.map((w) => w.trim().toLowerCase()).where((w) => w.isNotEmpty)) {
      final k = DeviceKind.values.where((k) => k.name == w).firstOrNull;
      if (k != null) {
        kinds.add(k);
      } else if (!needs.contains(w)) {
        needs.add(w);
      }
    }
    return ScriptRequirements(kinds: kinds, needs: needs);
  }

  /// "a drone or rover with gps and camera".
  String describe() {
    String list(List<String> l, String and) => l.length <= 1 ? l.join() : '${l.sublist(0, l.length - 1).join(', ')} $and ${l.last}';
    final k = kinds.isEmpty ? 'a device' : 'a ${list([for (final k in kinds) k.name], 'or')}';
    return needs.isEmpty ? k : '$k with ${list(needs, 'and')}';
  }

  /// What [info] lacks for this script (empty: it fits). [link] adds what dash
  /// sees on a connected device.
  List<String> missing(DeviceInfo info, [DeviceLink? link]) {
    final out = <String>[];
    if (kinds.isNotEmpty && !kinds.contains(info.kind)) out.add('a ${kinds.map((k) => k.name).join(' or ')} (${info.name} is a ${info.kind.name})');
    final have = capabilitiesOf(info, link);
    for (final n in needs) {
      if (!have.contains(n)) out.add(n);
    }
    return out;
  }
}

extension WhyNot on ScriptRequirements {
  /// Why [info] does not fit, as a sentence; null if it does.
  String? whyNot(DeviceInfo info, [DeviceLink? link]) {
    if (kinds.isNotEmpty && !kinds.contains(info.kind)) return '${info.name} is a ${info.kind.name}; this script needs ${describe()}.';
    final have = capabilitiesOf(info, link);
    final lacks = [
      for (final n in needs)
        if (!have.contains(n)) n,
    ];
    if (lacks.isEmpty) return null;
    return '${info.name} has no ${lacks.length == 1 ? lacks.single : '${lacks.sublist(0, lacks.length - 1).join(', ')} or ${lacks.last}'}; this script needs ${describe()}.';
  }
}

/// A sensor name as devices announce it ("IMU 200 G", "2D LIDAR", "WHEEL
/// ODOM") → the capability words scripts ask for.
Set<String> _sensorWords(String sensor) {
  final s = sensor.toLowerCase();
  const keys = {
    'gps': 'gps',
    'gnss': 'gps',
    'imu': 'imu',
    'baro': 'baro',
    'compass': 'compass',
    'mag': 'compass',
    'lidar': 'lidar',
    'camera': 'camera',
    'range': 'rangefinder',
    'sonar': 'rangefinder',
    'odom': 'odometry',
    'joint': 'joints',
    'current': 'current',
    'rpm': 'rpm',
    'temp': 'temp',
    'load cell': 'thrust',
    'thrust': 'thrust',
    'pyro': 'pyro',
    'vibration': 'vibration',
    'ultrason': 'proximity',
    'tof': 'proximity',
    'prox': 'proximity',
    'ir range': 'proximity',
  };
  return {
    for (final e in keys.entries)
      if (s.contains(e.key)) e.value,
    // Also the name itself: "wheel_odom", "motor_temp"…
    s.trim().replaceAll(RegExp(r'[^a-z0-9]+'), '_'),
  };
}

/// What a device can offer a script: the sensors it announced, and on a
/// connected device what dash sees (telemetry fields, camera streams, its own
/// channels, stored sequences, parameters).
Set<String> capabilitiesOf(DeviceInfo info, [DeviceLink? link]) {
  final out = <String>{for (final s in info.sensors) ..._sensorWords(s), if (info.prox.isNotEmpty) 'proximity'};
  if (link != null) {
    const seen = {
      'gps': 'gps',
      'imu': 'imu',
      'bat': 'battery',
      'joints': 'joints',
      'tool': 'gripper',
      'thrust': 'thrust',
      'rpm': 'rpm',
      'temp': 'temp',
      'pc': 'lidar',
      'tracks': 'tracks',
      'rssi': 'rssi',
    };
    for (final k in link.tel.seen) {
      final w = seen[k];
      if (w != null) out.add(w);
    }
    if (link.video.isNotEmpty) out.add('camera');
    out.addAll(link.tel.custom.keys.where((k) => !k.startsWith('script:')));
    if (link.seqCap > 0) out.add('sequences');
    if (link.tel.seen.contains('prox')) out.add('proximity');
  }
  if (info.kind == DeviceKind.arm) out.addAll({'joints', 'gripper'});
  return out;
}
