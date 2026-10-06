// ArduPilot and PX4 vehicles, spoken to in MAVLink and presented to the
// rest of the app as a koebelt/link device: the adapter turns MAVLink into
// hello / tlm / state / params / log messages, and the app's ctl, mode, arm,
// stop, cmd and pset into MAVLink. Sessions, the Live and Control screens,
// Tune and sequences then work unchanged.
import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'bytes.dart';
import 'mavlink.dart';
import 'protocol.dart';
import 'transport.dart';

/// Vehicle classes the app distinguishes, from MAV_TYPE.
String mavKind(int type) => switch (type) {
  1 || 2 || 3 || 4 || 7 || 13 || 14 || 15 || 16 || 19 || 20 || 21 || 22 || 23 || 24 || 25 || 29 || 35 => 'drone',
  10 || 11 || 12 => 'rover',
  9 => 'rocket',
  _ => 'generic',
};

bool _isPlane(int type) => type == 1 || (type >= 19 && type <= 25);
bool _isRover(int type) => type == 10 || type == 11;

/// "ArduCopter", "PX4 plane"…
String mavVehicleName(int autopilot, int type) {
  final cls = _isPlane(type)
      ? 'Plane'
      : _isRover(type)
      ? (type == 11 ? 'Boat' : 'Rover')
      : type == 12
      ? 'Sub'
      : type == 4
      ? 'Heli'
      : 'Copter';
  return switch (autopilot) {
    Mav.ardupilot => 'Ardu${cls == 'Boat' ? 'Rover' : cls}',
    Mav.px4 => 'PX4 ${cls.toLowerCase()}',
    _ => 'MAVLink ${cls.toLowerCase()}',
  };
}

// ---- flight modes
const _copterModes = {
  0: 'STABILIZE', 1: 'ACRO', 2: 'ALT_HOLD', 3: 'AUTO', 4: 'GUIDED', 5: 'LOITER', 6: 'RTL', 7: 'CIRCLE', 9: 'LAND', 11: 'DRIFT', //
  13: 'SPORT', 14: 'FLIP', 15: 'AUTOTUNE', 16: 'POSHOLD', 17: 'BRAKE', 18: 'THROW', 19: 'AVOID_ADSB', 20: 'GUIDED_NOGPS', 21: 'SMART_RTL',
  22: 'FLOWHOLD', 23: 'FOLLOW', 24: 'ZIGZAG', 25: 'SYSTEMID', 26: 'AUTOROTATE', 27: 'AUTO_RTL',
};
const _planeModes = {
  0: 'MANUAL', 1: 'CIRCLE', 2: 'STABILIZE', 3: 'TRAINING', 4: 'ACRO', 5: 'FBWA', 6: 'FBWB', 7: 'CRUISE', 8: 'AUTOTUNE', 10: 'AUTO', //
  11: 'RTL', 12: 'LOITER', 13: 'TAKEOFF', 14: 'AVOID_ADSB', 15: 'GUIDED', 17: 'QSTABILIZE', 18: 'QHOVER', 19: 'QLOITER', 20: 'QLAND', 21: 'QRTL',
};
const _roverModes = {
  0: 'MANUAL', 1: 'ACRO', 3: 'STEERING', 4: 'HOLD', 5: 'LOITER', 6: 'FOLLOW', 7: 'SIMPLE', 8: 'DOCK', 9: 'CIRCLE', 10: 'AUTO', 11: 'RTL', //
  12: 'SMART_RTL', 15: 'GUIDED', 16: 'INITIALISING',
};
const _px4Main = {1: 'MANUAL', 2: 'ALTCTL', 3: 'POSCTL', 4: 'AUTO', 5: 'ACRO', 6: 'OFFBOARD', 7: 'STABILIZED', 8: 'RATTITUDE'};
const _px4Auto = {1: 'READY', 2: 'TAKEOFF', 3: 'LOITER', 4: 'MISSION', 5: 'RTL', 6: 'LAND', 7: 'RTGS', 8: 'FOLLOW', 9: 'PRECLAND'};

/// The autopilot's own name for its current mode.
String mavModeName(int autopilot, int type, int custom) {
  if (autopilot == Mav.px4) {
    final main = (custom >> 16) & 0xFF, sub = (custom >> 24) & 0xFF;
    final m = _px4Main[main] ?? 'MODE $main';
    return main == 4 ? 'AUTO.${_px4Auto[sub] ?? sub}' : m;
  }
  final table = _isPlane(type) ? _planeModes : (_isRover(type) ? _roverModes : _copterModes);
  return table[custom] ?? 'MODE $custom';
}

/// The app's mode for a native one: what the mode means for the pilot.
String appMode(String native) {
  const hold = {'LOITER', 'POSHOLD', 'BRAKE', 'HOLD', 'QLOITER', 'AUTO.LOITER', 'CIRCLE'};
  const rth = {'RTL', 'SMART_RTL', 'AUTO_RTL', 'QRTL', 'AUTO.RTL', 'AUTO.RTGS'};
  const land = {'LAND', 'QLAND', 'AUTO.LAND', 'AUTO.PRECLAND'};
  const auto = {'AUTO', 'GUIDED', 'FOLLOW', 'ZIGZAG', 'AUTO.MISSION', 'AUTO.FOLLOW', 'OFFBOARD', 'AUTO.READY', 'DOCK'};
  if (hold.contains(native)) return 'HOLD';
  if (rth.contains(native)) return 'RTH';
  if (land.contains(native)) return 'LAND';
  if (native == 'TAKEOFF' || native == 'AUTO.TAKEOFF') return 'TAKEOFF';
  if (auto.contains(native)) return 'AUTO';
  return 'MANUAL';
}

/// (param2, param3) for MAV_CMD_DO_SET_MODE to reach an app mode, or null.
(double, double)? mavModeFor(String app, int autopilot, int type) {
  if (autopilot == Mav.px4) {
    return switch (app) {
      'MANUAL' => (_isRover(type) ? 1 : 2, 0), // ALTCTL: centred throttle holds altitude
      'HOLD' => (4, 3),
      'AUTO' => (4, 4),
      'RTH' => (4, 5),
      'LAND' => (4, 6),
      'TAKEOFF' => (4, 2),
      _ => null,
    };
  }
  if (_isRover(type)) {
    return switch (app) {
      'MANUAL' => (0, 0),
      'HOLD' || 'LAND' => (4, 0),
      'AUTO' => (10, 0),
      'RTH' => (11, 0),
      _ => null,
    };
  }
  if (_isPlane(type)) {
    final vtol = type != 1;
    return switch (app) {
      'MANUAL' => (5, 0), // FBWA
      'HOLD' => (12, 0),
      'AUTO' => (10, 0),
      'RTH' => (11, 0),
      'LAND' => (vtol ? 20 : 11, 0),
      'TAKEOFF' => (13, 0),
      _ => null,
    };
  }
  return switch (app) {
    'MANUAL' => (2, 0), // ALT_HOLD: centred throttle holds altitude, like the app's sticks
    'HOLD' => (5, 0),
    'AUTO' => (3, 0),
    'RTH' => (6, 0),
    'LAND' => (9, 0),
    _ => null,
  };
}

const _guided = {Mav.ardupilot: 4.0};

/// Parameter range guess for the Tune screen: MAVLink parameters carry no
/// limits, so allow a wide band around the current value.
(double, double, double) mavParamRange(double v, bool integer) {
  final a = v.abs();
  final max = a == 0 ? (integer ? 10.0 : 1.0) : (a * 10);
  final min = v < 0 ? -max : (integer ? 0.0 : 0.0);
  final step = integer ? 1.0 : (a == 0 ? .001 : math.pow(10, (math.log(a) / math.ln10).floor() - 2).toDouble());
  return (min, max, step);
}

/// A MAVLink vehicle seen as a koebelt/link device.
class MavlinkTransport implements Transport {
  MavlinkTransport(this.link, {this.ackTimeout = const Duration(seconds: 2)});
  final ByteLink link;
  final Duration ackTimeout;

  final _enc = MavEncoder();
  final _parser = MavParser();
  final _out = StreamController<Msg>.broadcast();
  StreamSubscription? _sub;
  Timer? _gcsHeartbeat, _paramFlush;

  // vehicle
  int? sys;
  int comp = 1, autopilot = Mav.invalid, type = 0, custom = 0, base = 0, status = 0;
  bool _helloWanted = false, _helloSent = false, _estop = false;
  String _lastState = '';

  // position
  (double, double, double)? _home; // lat, lon, alt MSL (m)
  int _sats = 0, _fix = 0;
  bool _haveLocal = false;
  List<double> _gyro = [0, 0, 0];

  // params: id -> (value, type, index)
  final Map<String, (double, int, int)> _params = {};
  int _paramCount = -1;
  bool _paramsSent = false;
  final Map<String, double> _pending = {};
  Timer? _ackTimer;

  // latency
  final Map<int, num> _syncs = {};
  final _clock = Stopwatch()..start();

  @override
  String get label => '${link.label} · MAVLink';

  @override
  Stream<Msg> get messages => _out.stream;

  bool get armed => base & Mav.flagSafetyArmed != 0;
  String get nativeMode => mavModeName(autopilot, type, custom);

  @override
  Future<void> open() async {
    await link.open();
    _sub = link.bytes.listen((b) {
      for (final m in _parser.add(b)) {
        _onMav(m);
      }
    });
    _sendGcsHeartbeat();
    _gcsHeartbeat = Timer.periodic(const Duration(seconds: 1), (_) => _sendGcsHeartbeat());
  }

  void _emit(Msg m) {
    if (!_out.isClosed) _out.add(m);
  }

  void _mav(int id, Map<String, dynamic> f) => link.write(_enc.encode(id, f));

  void _sendGcsHeartbeat() =>
      _mav(Mav.heartbeat, {'type': 6, 'autopilot': Mav.invalid, 'base_mode': 0, 'custom_mode': 0, 'system_status': 4, 'mavlink_version': 3});

  void _command(int cmd, [List<double> p = const []]) {
    final t = sys;
    if (t == null) return;
    double at(int i) => i < p.length ? p[i] : 0;
    _mav(Mav.commandLong, {'command': cmd, 'target_system': t, 'target_component': comp, for (var i = 0; i < 7; i++) 'param${i + 1}': at(i)});
  }

  // ------------------------------------------------------------ vehicle -> app
  void _onMav(MavMsg m) {
    if (m.id == Mav.heartbeat) {
      final t = m.n('type').toInt(), ap = m.n('autopilot').toInt();
      if (ap == Mav.invalid || Mav.nonVehicleTypes.contains(t)) return;
      if (sys == null) {
        sys = m.sys;
        comp = m.comp;
      }
      if (m.sys != sys || m.comp != comp) return;
      autopilot = ap;
      type = t;
      custom = m.n('custom_mode').toInt();
      base = m.n('base_mode').toInt();
      status = m.n('system_status').toInt();
      if (_helloWanted && !_helloSent) _hello();
      _state();
      return;
    }
    if (sys == null || m.sys != sys) return;
    final ts = switch (m.f['time_boot_ms']) {
      final num v => v,
      _ => null,
    };
    switch (m.id) {
      case Mav.attitude:
        _gyro = [m.n('rollspeed').toDouble(), m.n('pitchspeed').toDouble(), m.n('yawspeed').toDouble()];
        // App frame: roll positive left wing down, yaw from east counter-clockwise.
        _tlm({
          'att': [-m.n('roll'), m.n('pitch'), math.pi / 2 - m.n('yaw')],
        }, ts);
      case Mav.globalPositionInt:
        final lat = m.n('lat') / 1e7, lon = m.n('lon') / 1e7, alt = m.n('alt') / 1000;
        if (lat == 0 && lon == 0) return;
        _home ??= (lat, lon, alt - m.n('relative_alt') / 1000);
        final d = <String, dynamic>{
          'gps': [lat, lon, alt, _sats],
          'vel': [m.n('vy') / 100, m.n('vx') / 100, -m.n('vz') / 100],
        };
        if (!_haveLocal || _fix >= 3) {
          final h = _home!;
          final y = (lat - h.$1) * 111111, x = (lon - h.$2) * 111111 * math.cos(h.$1 * math.pi / 180);
          d['pos'] = [x, y, m.n('relative_alt') / 1000];
        }
        _tlm(d, ts);
      case Mav.localPositionNed:
        _haveLocal = true;
        if (_fix >= 3 && _home != null) return; // GPS-relative-to-home wins
        _tlm({
          'pos': [m.n('y'), m.n('x'), -m.n('z')],
          'vel': [m.n('vy'), m.n('vx'), -m.n('vz')],
        }, ts);
      case Mav.gpsRawInt:
        _sats = m.n('satellites_visible').toInt();
        _fix = m.n('fix_type').toInt();
      case Mav.sysStatus:
        final v = m.n('voltage_battery') / 1000, a = m.n('current_battery'), p = m.n('battery_remaining');
        // 0 V / -1 % mean "no battery monitor": send nothing rather than 0 %.
        if (v <= 0 && p < 0) return;
        _tlm({
          'bat': [v, a < 0 ? 0 : a / 100, if (p >= 0) p],
        }, null);
      case Mav.rawImu:
        const g = 9.80665;
        _tlm({
          'imu': [
            m.n('xacc') * g / 1000,
            m.n('yacc') * g / 1000,
            m.n('zacc') * g / 1000,
            if (m.n('xgyro') != 0 || m.n('ygyro') != 0 || m.n('zgyro') != 0) ...[m.n('xgyro') / 1000, m.n('ygyro') / 1000, m.n('zgyro') / 1000] else ..._gyro,
          ],
        }, null);
      case Mav.vfrHud:
        _tlm({
          'throttle': [m.n('throttle') / 100],
        }, null);
      case Mav.radioStatus:
        _tlm({
          'rssi': [m.n('rssi') / 1.9 - 127],
        }, null);
      case Mav.homePosition:
        _home = (m.n('latitude') / 1e7, m.n('longitude') / 1e7, m.n('altitude') / 1000);
      case Mav.statustext:
        final sev = m.n('severity').toInt();
        _emit({'t': 'log', 'lvl': sev <= 3 ? 'error' : (sev == 4 ? 'warn' : 'info'), 'msg': '${m.f['text']}'});
      case Mav.commandAck:
        final r = m.n('result').toInt();
        if (r != 0 && r != 5) {
          const why = {1: 'temporarily rejected', 2: 'denied', 3: 'not supported', 4: 'failed', 6: 'cancelled'};
          _emit({'t': 'log', 'lvl': 'warn', 'msg': 'Vehicle refused command ${m.n('command')}: ${why[r] ?? 'result $r'}'});
        }
      case Mav.paramValue:
        _onParam(m);
      case Mav.timesync:
        final ts1 = m.n('ts1').toInt();
        final ping = _syncs.remove(ts1);
        if (m.n('tc1') != 0 && ping != null) _emit({'t': 'pong', 'ts': ping});
    }
  }

  void _tlm(Map<String, dynamic> d, num? ts) => _emit({'t': 'tlm', 'ts': ?ts, 'd': d});

  void _state() {
    final s = {
      't': 'state',
      'mode': appMode(nativeMode),
      'armed': armed,
      'estop': _estop,
      'fs': status >= 5, // MAV_STATE_CRITICAL / EMERGENCY
      'ext': {'fc_mode': nativeMode},
    };
    final key = '$s';
    if (key == _lastState) return;
    _lastState = key;
    _emit(s);
  }

  void _hello() {
    _helloSent = true;
    final kind = mavKind(type);
    _emit({
      't': 'hello',
      'v': protocolVersion,
      'id': 'mav-$sys',
      'name': mavVehicleName(autopilot, type),
      'kind': kind,
      'model':
          '${autopilot == Mav.px4
              ? 'PX4'
              : autopilot == Mav.ardupilot
              ? 'ArduPilot'
              : 'MAVLink'} · system $sys',
      'lib': 'mavlink/2',
      'sensors': ['IMU', 'BARO', 'COMPASS', 'GPS'],
      'ok': true,
    });
    _requestStreams(10);
    _command(Mav.cmdGetHomePosition);
    _mav(Mav.paramRequestList, {'target_system': sys, 'target_component': comp});
    _state();
  }

  void _requestStreams(num hz) {
    final rate = hz.clamp(1, 20).toInt();
    // ArduPilot: stream groups. PX4 ignores these and uses message intervals.
    _mav(Mav.requestDataStream, {'req_message_rate': rate, 'target_system': sys, 'target_component': comp, 'req_stream_id': 0, 'start_stop': 1});
    for (final (id, r) in [(Mav.attitude, rate), (Mav.globalPositionInt, rate), (Mav.sysStatus, 2), (Mav.gpsRawInt, 2), (Mav.rawImu, rate)]) {
      _command(Mav.cmdSetMessageInterval, [id.toDouble(), 1e6 / r]);
    }
  }

  // ------------------------------------------------------------ parameters
  static bool _intType(int t) => t >= 1 && t <= 8;

  double _decodeParam(double raw, int t) {
    if (autopilot != Mav.px4 || !_intType(t)) return raw;
    // PX4 sends integers bytewise inside the float.
    final b = ByteData(4)..setFloat32(0, raw, Endian.little);
    return switch (t) {
      1 => b.getUint8(0),
      2 => b.getInt8(0),
      3 => b.getUint16(0, Endian.little),
      4 => b.getInt16(0, Endian.little),
      5 => b.getUint32(0, Endian.little),
      _ => b.getInt32(0, Endian.little),
    }.toDouble();
  }

  double _encodeParam(double v, int t) {
    if (autopilot != Mav.px4 || !_intType(t)) return v;
    final b = ByteData(4);
    switch (t) {
      case 1 || 2:
        b.setInt8(0, v.round());
      case 3 || 4:
        b.setInt16(0, v.round(), Endian.little);
      default:
        b.setInt32(0, v.round(), Endian.little);
    }
    return b.getFloat32(0, Endian.little);
  }

  void _onParam(MavMsg m) {
    final id = '${m.f['param_id']}', t = m.n('param_type').toInt();
    final v = _decodeParam(m.n('param_value').toDouble(), t);
    _params[id] = (v, t, m.n('param_index').toInt());
    _paramCount = m.n('param_count').toInt();
    if (_pending.containsKey(id)) {
      _pending.remove(id);
      if (_pending.isEmpty) _ack();
    }
    if (!_paramsSent) {
      // All received, or nothing new for a moment: hand the table over.
      _paramFlush?.cancel();
      if (_params.length >= _paramCount) {
        _sendParams();
      } else {
        _paramFlush = Timer(const Duration(milliseconds: 1500), _sendParams);
      }
    }
  }

  void _sendParams() {
    if (_params.isEmpty) return;
    _paramsSent = true;
    final keys = _params.keys.toList()..sort();
    _emit({
      't': 'params',
      'p': [
        for (final k in keys)
          () {
            final (v, t, _) = _params[k]!;
            final (lo, hi, step) = mavParamRange(v, _intType(t));
            return [k, v, lo, hi, step, ''];
          }(),
      ],
    });
  }

  final List<String> _written = [];
  void _ack() {
    _ackTimer?.cancel();
    _emit({'t': 'pack', 'ok': _pending.isEmpty, 'keys': List.of(_written)});
    _written.clear();
  }

  // ------------------------------------------------------------ app -> vehicle
  @override
  void send(Msg m) {
    final t = sys;
    switch (m['t']) {
      case 'hello':
        _helloWanted = true;
        if (t != null && !_helloSent) _hello();
      case 'ping':
        final now = _clock.elapsedMicroseconds * 1000;
        _syncs[now] = m['ts'] as num;
        if (_syncs.length > 8) _syncs.remove(_syncs.keys.first);
        _mav(Mav.timesync, {'tc1': 0, 'ts1': now});
      case 'ctl':
        // Sticks reach the vehicle only while armed in a pilot-controlled mode.
        if (t == null || !armed || _estop || appMode(nativeMode) != 'MANUAL') return;
        double a(String k) => ((m[k] as num?) ?? 0).toDouble().clamp(-1.0, 1.0);
        final rover = _isRover(type);
        _mav(Mav.manualControl, {
          'target': t,
          'x': (a('ry') * 1000).round(),
          'y': ((rover ? a('lx') : a('rx')) * 1000).round(),
          'z': (500 + (rover ? a('ry') : a('ly')) * 500).round(),
          'r': (rover ? 0 : a('lx') * 1000).round(),
        });
      case 'arm':
        if (!_estop) _command(Mav.cmdArmDisarm, [m['v'] == true ? 1 : 0]);
      case 'mode':
        if (_estop) return;
        final want = '${m['m']}';
        if (want == 'TAKEOFF' && !_isPlane(type) && autopilot != Mav.px4) {
          _takeoff(5);
          return;
        }
        final mm = mavModeFor(want, autopilot, type);
        if (mm != null) _command(Mav.cmdDoSetMode, [Mav.flagCustomModeEnabled.toDouble(), mm.$1, mm.$2]);
      case 'stop':
        // Disarm even in flight: cuts the motors, as the protocol defines STOP.
        _estop = true;
        _command(Mav.cmdArmDisarm, [0, Mav.forceDisarm]);
        _state();
      case 'reset':
        _estop = false;
        _state();
      case 'cmd':
        if (_estop) return;
        final a = (m['a'] as Map?)?.cast<String, dynamic>() ?? const {};
        double n(String k, [double d = 0]) => (a[k] as num?)?.toDouble() ?? d;
        switch (m['c']) {
          case 'takeoff':
            _takeoff(n('alt', 5));
          case 'goto':
            _goto(n('x'), n('y'), n('z', 5));
          case 'sethome':
            _command(Mav.cmdDoSetHome, [1]);
            _home = null; // re-learnt from the next HOME_POSITION / fix
            _command(Mav.cmdGetHomePosition);
        }
      case 'pset':
        final p = (m['p'] as Map?)?.cast<String, dynamic>() ?? const {};
        for (final e in p.entries) {
          final cur = _params[e.key];
          if (cur == null || e.value is! num) continue;
          _pending[e.key] = (e.value as num).toDouble();
          _written.add(e.key);
          _mav(Mav.paramSet, {
            'param_value': _encodeParam((e.value as num).toDouble(), cur.$2),
            'target_system': t,
            'target_component': comp,
            'param_id': e.key,
            'param_type': cur.$2,
          });
        }
        _ackTimer?.cancel();
        _ackTimer = Timer(ackTimeout, _ack);
        if (_pending.isEmpty) _ack();
      case 'psave':
        _emit({'t': 'log', 'lvl': 'info', 'msg': 'The flight controller stores parameters as soon as they are written.'});
      case 'rate':
        if (t != null) _requestStreams((m['hz'] as num?) ?? 10);
    }
  }

  void _takeoff(double alt) {
    if (autopilot == Mav.px4) {
      final h = _home;
      _command(Mav.cmdArmDisarm, [1]);
      _command(Mav.cmdNavTakeoff, [0, 0, 0, double.nan, double.nan, double.nan, (h?.$3 ?? 0) + alt]);
      return;
    }
    if (_isRover(type)) return;
    if (!armed) _command(Mav.cmdArmDisarm, [1]);
    if (_isPlane(type)) {
      _command(Mav.cmdDoSetMode, [1, 13]); // ArduPlane TAKEOFF mode climbs to TKOFF_ALT
      return;
    }
    final guided = _guided[autopilot];
    if (guided != null) _command(Mav.cmdDoSetMode, [1, guided]);
    _command(Mav.cmdNavTakeoff, [0, 0, 0, 0, 0, 0, alt]);
  }

  void _goto(double x, double y, double z) {
    final h = _home, t = sys;
    if (h == null || t == null) {
      _emit({'t': 'log', 'lvl': 'warn', 'msg': 'Go to needs a GPS fix and a home position'});
      return;
    }
    final lat = h.$1 + y / 111111, lon = h.$2 + x / (111111 * math.cos(h.$1 * math.pi / 180));
    if (autopilot == Mav.ardupilot) _command(Mav.cmdDoSetMode, [1, _isPlane(type) || _isRover(type) ? 15 : 4]);
    _mav(Mav.commandInt, {
      'command': Mav.cmdDoReposition,
      'target_system': t,
      'target_component': comp,
      'frame': 6, // MAV_FRAME_GLOBAL_RELATIVE_ALT_INT
      'param1': -1, // default speed
      'param2': 1, // MAV_DO_REPOSITION_FLAGS_CHANGE_MODE
      'param4': double.nan, // keep yaw
      'x': (lat * 1e7).round(),
      'y': (lon * 1e7).round(),
      'z': _isRover(type) ? 0 : z,
    });
  }

  @override
  Future<void> close() async {
    _gcsHeartbeat?.cancel();
    _paramFlush?.cancel();
    _ackTimer?.cancel();
    await _sub?.cancel();
    await link.close();
    await _out.close();
  }
}
