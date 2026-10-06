import 'dart:math' as math;

import 'model.dart';

/// The app's view of one device, built from `tlm` / `state` / `pc` /
/// `tracks` messages. Recordings snapshot and restore this.
class Telemetry {
  Telemetry(this.kind);
  DeviceKind kind;

  // pose
  List<double> pos = [0, 0, 0], vel = [0, 0, 0];
  double roll = 0, pitch = 0, yaw = 0;
  List<double> acc = [0, 0, 9.81], gyro = [0, 0, 0];

  // gps
  double lat = 0, lon = 0, gpsAlt = 0;
  int sats = 0;
  bool hasGps = false;

  /// Channels this device has actually sent (`imu`, `gps`, `pc`, `tracks`…).
  /// The dashboard only offers tiles for these.
  final Set<String> seen = {};

  // power / link
  double voltage = 0, current = 0, battery = 100;
  double rssi = -50;
  bool hasRssi = false;

  // arm
  List<double> joints = [0, -0.5, 1.1, 0, 0.6, 0];
  List<double> tool = [0, 0, 0];
  double gripper = 0.2;
  List<double> ft = [0, 0, 0];

  // bench
  double thrust = 0, torque = 0, rpm = 0, temp = 0, throttleOut = 0;

  // rocket
  double maxAlt = 0, phaseT = 0, countdown = 0;
  List<String> pyro = ['OK', 'OK', 'OK', '—'];

  // state
  String mode = 'AUTO';
  bool armed = false, estop = false, failsafe = false;
  String? cutoff;
  String? seqKind;
  double seqT = 0;

  // environment
  List<Track> targets = [];
  final Map<int, List<double>> _cloud = {};
  List<List<double>> cloud = [];
  List<List<double>> trail = [];

  /// GPS fixes ([lat, lon]) along the way, for the map.
  List<List<double>> gpsTrail = [];

  // custom channels: id -> latest values
  final Map<String, List<double>> custom = {};

  // derived, animated locally
  double sweep = 0, propA = 0;

  // ---- smoothed pose for drawing -------------------------------------------
  // Telemetry arrives at 10–60 Hz with network jitter, the screen draws at
  // 60–120 Hz. Canvases use these values: positions are dead-reckoned from the
  // last sample with its velocity (and yaw with the gyro rate), placed on the
  // device's own clock (`tlm.ts`) so arrival jitter does not show, and any
  // mismatch when a new sample lands is faded out instead of snapped.
  List<double> rPos = [0, 0, 0];
  double rYaw = 0, rRoll = 0, rPitch = 0;
  List<double> rJoints = [0, -0.5, 1.1, 0, 0.6, 0];

  /// false for replays: frames are interpolated by the player instead.
  bool predict = true;
  double _clock = 0, _sampleAt = 0, _yawCorr = 0;
  double? _off;
  List<double> _corr = [0, 0, 0];
  bool _hasPose = false;

  List<List<double>> get rArmPts => armFk(rJoints);

  double get _since => (_clock - _sampleAt).clamp(0.0, .25);
  List<double> _predPos() => [for (var i = 0; i < 3; i++) pos[i] + vel[i] * _since];
  double _predYaw() => yaw + gyro[2] * _since;

  double get speed => hypot3(vel[0], vel[1], vel[2]);
  double get alt => pos[2];
  List<List<double>> get armPts => armFk(joints);
  List<double> get tip => armPts[5];
  double get heading => ((90 - yaw * 57.3) % 360 + 360) % 360;
  double get range => hypot2(pos[0], pos[1]);
  double get power => voltage * current;

  /// [ts] is the device timestamp in ms from the `tlm` message.
  void applyTlm(Map<String, dynamic> d, {num? ts}) {
    List<double> v(String k) => (d[k] as List).map((e) => (e as num).toDouble()).toList();
    final posed = d.containsKey('pos') || d.containsKey('att');
    final before = posed && _hasPose ? _predPos() : null;
    final beforeYaw = posed && _hasPose ? _predYaw() : null;
    seen.addAll(d.keys);
    for (final k in d.keys) {
      final x = v(k);
      switch (k) {
        case 'imu':
          acc = x.sublist(0, 3);
          gyro = x.sublist(3, 6);
        case 'att':
          roll = x[0];
          pitch = x[1];
          yaw = x[2];
        case 'pos':
          pos = x;
        case 'vel':
          vel = x;
        case 'gps':
          lat = x[0];
          lon = x[1];
          gpsAlt = x[2];
          sats = x.length > 3 ? x[3].round() : 0;
          hasGps = true;
        case 'bat':
          voltage = x[0];
          current = x[1];
          if (x.length > 2) battery = x[2];
        case 'rssi':
          rssi = x[0];
          hasRssi = true;
        case 'joints':
          joints = x;
        case 'tool':
          tool = x.sublist(0, 3);
          if (x.length > 3) gripper = x[3];
        case 'ft':
          ft = x;
        case 'thrust':
          thrust = x[0];
          if (x.length > 1) torque = x[1];
        case 'rpm':
          rpm = x[0];
        case 'temp':
          temp = x[0];
        case 'throttle':
          throttleOut = x[0];
        case 'rocket':
          maxAlt = x[0];
          phaseT = x[1];
          if (x.length > 2) countdown = x[2];
        default:
          custom[k] = x;
      }
    }
    if (posed) _landed(ts, before, beforeYaw);
  }

  void applyState(Map<String, dynamic> m) {
    if (m['mode'] != null) mode = m['mode'];
    if (m['armed'] != null) armed = m['armed'];
    if (m['estop'] != null) estop = m['estop'];
    if (m['fs'] != null) failsafe = m['fs'];
    final ext = m['ext'];
    if (ext is Map) {
      if (ext['pyro'] is List) pyro = List<String>.from((ext['pyro'] as List).map((e) => e == '-' ? '—' : '$e'));
      cutoff = ext['cutoff'];
      final s = ext['seq'];
      if (s is Map) {
        seqKind = s['kind'];
        seqT = (s['t'] as num?)?.toDouble() ?? 0;
      } else {
        seqKind = null;
      }
    }
  }

  void applyTracks(List list) {
    seen.add('tracks');
    final prev = {for (final t in targets) t.id: t};
    targets = [
      for (final e in list)
        prev[e[0]] != null
            ? (prev[e[0]]!
                ..r = (e[1] as num).toDouble()
                ..a = (e[2] as num).toDouble())
            : Track('${e[0]}', (e[1] as num).toDouble(), (e[2] as num).toDouble()),
    ];
  }

  /// Merge a scan into the persistent point map (10 cm voxels, capped).
  void addPoints(List<List<double>> pts) {
    if (pts.isNotEmpty) seen.add('pc');
    for (final p in pts) {
      final k = ((p[0] * 10).round() & 0x1FFFFF) | (((p[1] * 10).round() & 0x1FFFFF) << 21) | (((p[2] * 10).round() & 0x3FFFFF) << 42);
      _cloud[k] = p;
    }
    if (_cloud.length > 14000) {
      final drop = _cloud.keys.take(_cloud.length - 14000).toList();
      for (final k in drop) {
        _cloud.remove(k);
      }
    }
    cloud = _cloud.values.toList(growable: false);
  }

  void resetEnvironment() {
    _hasPose = false;
    _cloud.clear();
    cloud = [];
    trail = [];
    gpsTrail = [];
    targets = [];
  }

  /// Local animation: radar sweep, prop angle.
  void _landed(num? ts, List<double>? before, double? beforeYaw) {
    if (ts != null) {
      // Lowest observed (local − device) offset = least-delayed sample; relax
      // slowly so clock drift and device restarts are followed.
      final c = _clock - ts / 1000;
      _off = _off == null || (c - _off!).abs() > 5 ? c : math.min(_off! + .0005, c);
      _sampleAt = ts / 1000 + _off!;
    } else {
      _sampleAt = _clock;
    }
    if (before != null && beforeYaw != null) {
      final after = _predPos();
      final jump = hypot3(before[0] - after[0], before[1] - after[1], before[2] - after[2]);
      _corr = jump > 50 ? [0, 0, 0] : [for (var i = 0; i < 3; i++) _corr[i] + before[i] - after[i]];
      var dy = beforeYaw - _predYaw();
      dy = math.atan2(math.sin(dy), math.cos(dy));
      _yawCorr += dy;
    } else {
      _corr = [0, 0, 0];
      _yawCorr = 0;
      rPos = List.of(pos);
      rYaw = yaw;
      rRoll = roll;
      rPitch = pitch;
    }
    _hasPose = true;
  }

  void animate(double dt) {
    _clock += dt;
    if (!predict) {
      rPos = pos;
      rYaw = yaw;
      rRoll = roll;
      rPitch = pitch;
      rJoints = joints;
    } else {
      final fade = math.exp(-dt / .1);
      _corr = [for (final c in _corr) c * fade];
      _yawCorr *= fade;
      final p = _predPos();
      rPos = [for (var i = 0; i < 3; i++) p[i] + _corr[i]];
      rYaw = _predYaw() + _yawCorr;
      final k = 1 - math.exp(-dt / .06);
      rRoll += (roll - rRoll) * k;
      rPitch += (pitch - rPitch) * k;
      if (rJoints.length != joints.length) rJoints = List.of(joints);
      rJoints = [for (var i = 0; i < joints.length; i++) rJoints[i] + (joints[i] - rJoints[i]) * k];
    }
    sweep = (sweep + dt * math.pi * 1.2) % (math.pi * 2);
    propA = (propA + rpm * dt * .004) % 6.283;
  }

  void sampleTrail() {
    final p = kind == DeviceKind.arm ? tip : pos;
    final minStep = kind == DeviceKind.arm || kind == DeviceKind.bench
        ? .02
        : kind == DeviceKind.rocket
        ? 2.5
        : .4;
    final l = trail.isEmpty ? null : trail.last;
    if (l == null || hypot3(p[0] - l[0], p[1] - l[1], p[2] - l[2]) > minStep) {
      trail.add(List.of(p));
      if (trail.length > 600) trail.removeAt(0);
    }
    if (seen.contains('gps') && (lat != 0 || lon != 0)) {
      final g = gpsTrail.isEmpty ? null : gpsTrail.last;
      if (g == null || metresBetween(g[0], g[1], lat, lon) > minStep) {
        gpsTrail.add([lat, lon]);
        if (gpsTrail.length > 2000) gpsTrail.removeAt(0);
      }
    }
  }

  // ---- recording ----
  /// One recording frame: pose, mode and armed state always, other values
  /// only for channels the device has sent, rounded to what the sensors
  /// resolve (millimetres, 0.01°, 0.1 % battery…). About a quarter of the
  /// full state, and smaller still once the file is compressed.
  Map<String, dynamic> snapshot() {
    double r(double v, int digits) {
      if (!v.isFinite) return 0;
      final m = _pow10[digits];
      return (v * m).roundToDouble() / m;
    }

    List<double> rl(List<double> v, int digits) => [for (final x in v) r(x, digits)];
    final has = seen.contains;
    return {
      'pos': rl(pos, 3),
      'roll': r(roll, 4),
      'pitch': r(pitch, 4),
      'yaw': r(yaw, 4),
      'mode': mode,
      'armed': armed,
      'seen': seen.toList(),
      if (has('vel')) 'vel': rl(vel, 3),
      if (has('imu')) ...{'acc': rl(acc, 3), 'gyro': rl(gyro, 4)},
      if (has('gps')) ...{'lat': r(lat, 7), 'lon': r(lon, 7), 'galt': r(gpsAlt, 2)},
      if (has('bat')) ...{'voltage': r(voltage, 3), 'current': r(current, 3), 'battery': r(battery, 1)},
      if (has('rssi')) 'rssi': r(rssi, 1),
      if (has('joints')) 'joints': rl(joints, 4),
      if (has('tool')) 'gripper': r(gripper, 3),
      if (has('ft')) 'ft': rl(ft, 2),
      if (has('thrust')) ...{'thrust': r(thrust, 3), 'torque': r(torque, 4)},
      if (has('rpm')) 'rpm': r(rpm, 0),
      if (has('temp')) 'temp': r(temp, 2),
      if (has('throttle')) 'thr': r(throttleOut, 3),
      if (has('rocket')) ...{'maxAlt': r(maxAlt, 2), 'phaseT': r(phaseT, 2), 'countdown': r(countdown, 2), 'pyro': List.of(pyro)},
      if (targets.isNotEmpty)
        'targets': [
          for (final t in targets) [t.id, r(t.r, 2), r(t.a, 4)],
        ],
      if (custom.isNotEmpty) 'custom': {for (final e in custom.entries) e.key: rl(e.value, 4)},
    };
  }

  static const _pow10 = [1.0, 10.0, 100.0, 1000.0, 10000.0, 100000.0, 1000000.0, 10000000.0];

  /// Restores a frame. Frames from older recordings carry every value;
  /// newer ones only the channels the device sent.
  void applyFrame(Map<String, dynamic> f) {
    List<double>? l(String k) => f[k] is List ? [for (final e in f[k] as List) (e as num).toDouble()] : null;
    double? d(String k) => (f[k] as num?)?.toDouble();
    pos = l('pos') ?? pos;
    vel = l('vel') ?? vel;
    roll = d('roll') ?? roll;
    pitch = d('pitch') ?? pitch;
    yaw = d('yaw') ?? yaw;
    acc = l('acc') ?? acc;
    gyro = l('gyro') ?? gyro;
    lat = d('lat') ?? lat;
    lon = d('lon') ?? lon;
    voltage = d('voltage') ?? voltage;
    current = d('current') ?? current;
    battery = d('battery') ?? battery;
    rssi = d('rssi') ?? rssi;
    joints = l('joints') ?? joints;
    gripper = d('gripper') ?? gripper;
    ft = l('ft') ?? ft;
    thrust = d('thrust') ?? thrust;
    torque = d('torque') ?? torque;
    rpm = d('rpm') ?? rpm;
    temp = d('temp') ?? temp;
    throttleOut = d('thr') ?? throttleOut;
    maxAlt = d('maxAlt') ?? maxAlt;
    phaseT = d('phaseT') ?? phaseT;
    countdown = d('countdown') ?? countdown;
    if (f['pyro'] is List) pyro = List<String>.from(f['pyro']);
    if (f['mode'] is String) mode = f['mode'];
    if (f['armed'] is bool) armed = f['armed'];
    if (f['custom'] is Map) {
      custom
        ..clear()
        ..addAll({
          for (final e in (f['custom'] as Map).entries) '${e.key}': [for (final v in e.value as List) (v as num).toDouble()],
        });
    }
    final hadCloud = cloud.isNotEmpty;
    if (f['seen'] is List) {
      seen
        ..clear()
        ..addAll(List<String>.from(f['seen']));
    }
    if (hadCloud) seen.add('pc');
    if (f['targets'] is List && (f['targets'] as List).isNotEmpty) applyTracks(f['targets']);
  }
}

/// History channels sampled at 30 Hz, 300 samples = 10 s.
const historyKeys = [
  'vz',
  'thr',
  'rpm',
  'tq',
  'tmp',
  'pw',
  'ax',
  'ay',
  'az',
  'gx',
  'gy',
  'gz',
  'alt',
  'volt',
  'cur',
  'rssi',
  'lat',
  'spd',
  'j0',
  'j1',
  'j2',
  'j3',
  'j4',
  'j5',
  'fx',
  'fy',
  'fz',
];

class History {
  final Map<String, Series> ch = {for (final k in historyKeys) k: Series()};
  Series operator [](String k) => ch.putIfAbsent(k, Series.new);

  void sample(Telemetry t, double latency) {
    void h(String k, double v) => this[k].push(v);
    h('vz', t.vel[2]);
    h('thr', t.thrust);
    h('rpm', t.rpm);
    h('tq', t.torque);
    h('tmp', t.temp);
    h('pw', t.power);
    h('ax', t.acc[0]);
    h('ay', t.acc[1]);
    h('az', t.acc[2] - 9.81);
    h('gx', t.gyro[0]);
    h('gy', t.gyro[1]);
    h('gz', t.gyro[2]);
    h('alt', t.pos[2]);
    h('volt', t.voltage);
    h('cur', t.current);
    h('rssi', t.rssi);
    h('lat', latency);
    h('spd', t.speed);
    for (var i = 0; i < 6 && i < t.joints.length; i++) {
      h('j$i', t.joints[i]);
    }
    h('fx', t.ft[0]);
    h('fy', t.ft[1]);
    h('fz', t.ft[2]);
    for (final e in t.custom.entries) {
      for (var i = 0; i < e.value.length; i++) {
        h('c:${e.key}:$i', e.value[i]);
      }
    }
  }

  void clear() {
    for (final s in ch.values) {
      s.clear();
    }
  }

  /// Deep copy for "Pause" in sensor detail.
  Map<String, List<double?>> freeze() => {for (final e in ch.entries) e.key: e.value.toList()};
}

/// Equirectangular distance in metres; fine at the scale of one flight.
double metresBetween(double lat0, double lon0, double lat1, double lon1) {
  final dy = (lat1 - lat0) * 111111, dx = (lon1 - lon0) * 111111 * math.cos(lat0 * math.pi / 180);
  return math.sqrt(dx * dx + dy * dy);
}
