// Recordings from files: koebelt/dash JSON exports, ArduPilot DataFlash logs
// (.bin), MAVLink telemetry logs (.tlog, what ground stations save) and PX4
// ULog files (.ulg). Flight controller logs become ordinary recordings: the
// same frames, at up to 50 Hz, so replay, the map and export work on them.
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import '../link/bytes.dart';
import '../link/mavlink.dart';
import '../link/mavlink_adapter.dart';
import '../link/protocol.dart' show decodePoints;
import 'model.dart';
import 'telemetry.dart';

/// File types offered in the open dialog.
const importExtensions = ['json', 'bin', 'tlog', 'ulg'];

class LogImportError implements Exception {
  LogImportError(this.message);
  final String message;
  @override
  String toString() => message;
}

/// What a log file holds, ready to become a recording.
class ImportedLog {
  ImportedLog({required this.format, required this.deviceName, required this.kind, required this.frames, this.name, this.startedAt, this.cloud = const []});
  final String format, deviceName;
  final String? name;
  final DeviceKind kind;
  final List<Map<String, dynamic>> frames;
  final DateTime? startedAt;
  final List<List<double>> cloud;
}

/// Reads [bytes], picking the format from its content (then the extension).
ImportedLog parseLog(String fileName, Uint8List bytes) {
  final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';
  final ImportedLog log;
  if (bytes.length > 16 && ascii.decode(bytes.sublist(0, 4), allowInvalid: true) == 'ULog') {
    log = _ulog(bytes);
  } else if (bytes.length > 3 && bytes[0] == 0xA3 && bytes[1] == 0x95) {
    log = _dataflash(bytes);
  } else if (ext == 'json' || _firstChar(bytes) == '{') {
    log = _json(bytes);
  } else if (ext == 'tlog' || _looksLikeTlog(bytes)) {
    log = _tlog(bytes);
  } else {
    throw LogImportError('This file is not a log the app can read. It opens koebelt/dash JSON exports, ArduPilot .bin and .tlog logs, and PX4 .ulg logs.');
  }
  if (log.frames.length < 2) throw LogImportError('The ${log.format} file has no telemetry the app can show (attitude, position, battery).');
  return log;
}

String _firstChar(Uint8List b) {
  for (final c in b.take(64)) {
    if (c > 32) return String.fromCharCode(c);
  }
  return '';
}

// ------------------------------------------------------------------ frames
/// Builds recording frames from timed telemetry updates, through the same
/// [Telemetry] the live view uses.
class _Timeline {
  // No mode until the log names one.
  final tel = Telemetry(DeviceKind.drone)
    ..predict = false
    ..mode = '—';
  final frames = <Map<String, dynamic>>[];
  double? _t0;
  double _last = -1;
  static const maxHz = 50.0;

  /// Time of the first frame, in the log's own clock (seconds).
  double? get t0 => _t0;

  void tlm(double t, Map<String, dynamic> d) {
    tel.applyTlm(d);
    _frame(t);
  }

  void state(double t, Map<String, dynamic> m) {
    tel.applyState(m);
    _frame(t, force: true);
  }

  void _frame(double t, {bool force = false}) {
    _t0 ??= t;
    final rel = t - _t0!;
    if (rel < _last) return; // clock jumped back: keep frames in order
    if (!force && _last >= 0 && rel - _last < 1 / maxHz) return;
    if (rel == _last && frames.isNotEmpty) frames.removeLast();
    _last = rel;
    frames.add(tel.snapshot()..['t'] = (rel * 1000).round() / 1000);
  }
}

/// App attitude from roll / pitch / yaw in the NED convention flight
/// controllers use (radians): roll positive left wing down, yaw from east
/// counter-clockwise (see the MAVLink adapter).
List<double> _att(double roll, double pitch, double yaw) => [-roll, pitch, math.pi / 2 - yaw];

/// East / north metres of [lat], [lon] from [home].
(double, double) _en((double, double) home, double lat, double lon) => ((lon - home.$2) * 111111 * math.cos(home.$1 * math.pi / 180), (lat - home.$1) * 111111);

// ------------------------------------------------------------------ JSON
ImportedLog _json(Uint8List bytes) {
  final Object? j;
  try {
    j = jsonDecode(utf8.decode(bytes));
  } catch (_) {
    throw LogImportError('This JSON file could not be read.');
  }
  if (j is! Map || j['frames'] is! List) throw LogImportError('This JSON file is not a koebelt/dash recording export.');
  final frames = [for (final f in j['frames'] as List) (f as Map).cast<String, dynamic>()];
  return ImportedLog(
    format: 'koebelt/dash',
    name: j['name'] as String?,
    deviceName: '${j['deviceName'] ?? 'Device'}',
    kind: DeviceKind.parse('${j['kind'] ?? 'generic'}'),
    frames: frames,
    startedAt: j['startedAt'] is String ? DateTime.tryParse(j['startedAt']) : null,
    cloud: j['cloud'] is String ? decodePoints(j['cloud']) : const [],
  );
}

// ------------------------------------------------------------------ MAVLink .tlog
// Each record: the time it was received (µs since 1970, big-endian), then
// one MAVLink frame. The frames go through the live MAVLink adapter, so the
// app reads them exactly as it would from the vehicle.
bool _plausibleUs(int us) => us > 946684800000000 && us < 4102444800000000; // 2000–2100

bool _looksLikeTlog(Uint8List b) {
  if (b.length < 20) return false;
  final bd = ByteData.sublistView(b);
  return (b[8] == 0xFD || b[8] == 0xFE) && _plausibleUs(bd.getUint64(0));
}

ImportedLog _tlog(Uint8List b) {
  final bd = ByteData.sublistView(b);
  final tl = _Timeline(), parser = MavParser();
  final mav = MavlinkTransport(MemoryByteLink.pair().$1);
  var t = 0.0;
  int? first;
  mav.tap = (m) {
    final d = m['d'];
    if (m['t'] == 'tlm' && d is Map) tl.tlm(t, d.cast<String, dynamic>());
    if (m['t'] == 'state') tl.state(t, m);
  };
  var i = 0;
  while (i + 8 + 8 <= b.length) {
    final magic = b[i + 8];
    if (magic != 0xFD && magic != 0xFE) {
      i++;
      continue;
    }
    final us = bd.getUint64(i);
    if (!_plausibleUs(us)) {
      i++;
      continue;
    }
    final v2 = magic == 0xFD, len = b[i + 9];
    final total = v2 ? 10 + len + 2 + ((b[i + 10] & 1) == 1 ? 13 : 0) : 6 + len + 2;
    if (i + 8 + total > b.length) break;
    final id = v2 ? b[i + 15] | b[i + 16] << 8 | b[i + 17] << 16 : b[i + 13];
    // Only messages the codec knows, so the parser never holds a partial
    // frame across records; parameters are not telemetry.
    if (mavDefs[id] != null && id != Mav.paramValue) {
      first ??= us;
      t = (us - first) / 1e6;
      for (final m in parser.add(b.sublist(i + 8, i + 8 + total))) {
        mav.feed(m);
      }
    }
    i += 8 + total;
  }
  if (mav.sys == null) throw LogImportError('This .tlog has no vehicle heartbeat, so its messages cannot be attributed to a vehicle.');
  return ImportedLog(
    format: 'MAVLink telemetry log',
    deviceName: mavVehicleName(mav.autopilot, mav.type),
    kind: DeviceKind.parse(mavKind(mav.type)),
    frames: tl.frames,
    startedAt: first == null ? null : DateTime.fromMicrosecondsSinceEpoch(first + ((tl.t0 ?? 0) * 1e6).round(), isUtc: true),
  );
}

// ------------------------------------------------------------------ ArduPilot DataFlash
class _DfFmt {
  _DfFmt(this.name, this.length, this.format, this.columns);
  final String name, format;
  final int length;
  final List<String> columns;

  static const _size = {
    'a': 64, 'b': 1, 'B': 1, 'h': 2, 'H': 2, 'i': 4, 'I': 4, 'f': 4, 'd': 8, 'n': 4, 'N': 16, 'Z': 64, //
    'c': 2, 'C': 2, 'e': 4, 'E': 4, 'L': 4, 'M': 1, 'q': 8, 'Q': 8,
  };

  /// Field values; null when the format uses a type this reader skips.
  Map<String, Object>? decode(ByteData bd, int at) {
    final out = <String, Object>{};
    var o = at;
    for (var k = 0; k < format.length; k++) {
      final c = format[k], sz = _size[c];
      if (sz == null) return null;
      final col = k < columns.length ? columns[k] : '_$k';
      final Object v = switch (c) {
        'b' => bd.getInt8(o),
        'B' || 'M' => bd.getUint8(o),
        'h' => bd.getInt16(o, Endian.little),
        'H' => bd.getUint16(o, Endian.little),
        'i' => bd.getInt32(o, Endian.little),
        'I' => bd.getUint32(o, Endian.little),
        'f' => bd.getFloat32(o, Endian.little),
        'd' => bd.getFloat64(o, Endian.little),
        'c' => bd.getInt16(o, Endian.little) / 100,
        'C' => bd.getUint16(o, Endian.little) / 100,
        'e' => bd.getInt32(o, Endian.little) / 100,
        'E' => bd.getUint32(o, Endian.little) / 100,
        'L' => bd.getInt32(o, Endian.little) / 1e7,
        'q' => bd.getInt64(o, Endian.little),
        'Q' => bd.getUint64(o, Endian.little),
        'n' || 'N' || 'Z' => _cstr(bd, o, sz),
        _ => 0, // 'a': int16[32], not used
      };
      out[col] = v;
      o += sz;
    }
    return out;
  }
}

String _cstr(ByteData bd, int at, int n) {
  final b = <int>[];
  for (var i = 0; i < n; i++) {
    final c = bd.getUint8(at + i);
    if (c == 0) break;
    b.add(c);
  }
  return latin1.decode(b);
}

ImportedLog _dataflash(Uint8List b) {
  final bd = ByteData.sublistView(b);
  final fmts = <int, _DfFmt>{
    0x80: _DfFmt('FMT', 89, 'BBnNZ', const ['Type', 'Length', 'Name', 'Format', 'Columns']),
  };
  final tl = _Timeline();
  var t = 0.0, mavType = 2, vehicle = 'ArduPilot', kind = DeviceKind.drone;
  var mode = 'MANUAL', native = '', armed = false;
  (double, double, double)? home, origin;
  DateTime? wallAt; // wall clock at log time [wallT]
  double wallT = 0;
  bool hasPos = false;

  double n(Map<String, Object> v, String k) => (v[k] as num?)?.toDouble() ?? 0;
  bool first(Map<String, Object> v) => ((v['I'] ?? v['Instance'] ?? v['Inst'] ?? 0) as num) == 0;
  void state() => tl.state(t, {
    'mode': mode,
    'armed': armed,
    'ext': {'fc_mode': native},
  });

  var i = 0;
  while (i + 3 <= b.length) {
    if (b[i] != 0xA3 || b[i + 1] != 0x95) {
      i++;
      continue;
    }
    final f = fmts[b[i + 2]];
    if (f == null || i + f.length > b.length) {
      i++;
      continue;
    }
    final v = f.decode(bd, i + 3);
    i += f.length;
    if (v == null) continue;
    if (f.name == 'FMT') {
      final type = v['Type'] as int, len = v['Length'] as int;
      final cols = (v['Columns'] as String).split(',');
      if (type != 0x80 && len > 3) fmts[type] = _DfFmt(v['Name'] as String, len, v['Format'] as String, cols);
      continue;
    }
    if (v['TimeUS'] is int) {
      t = (v['TimeUS'] as int) / 1e6;
    } else if (v['TimeMS'] is int) {
      t = (v['TimeMS'] as int) / 1e3;
    }
    switch (f.name) {
      case 'MSG':
        final m = '${v['Message']}';
        // Logs usually start at arming (LOG_DISARMED off), after the ARM
        // record, but always carry these texts.
        if (m == 'Arming motors' || m == 'Disarming motors') {
          armed = m == 'Arming motors';
          state();
        }
        final w = RegExp(r'^(?:APM:)?(Ardu\w+|Copter|Plane|Rover|Sub|Blimp|AntennaTracker)\b').firstMatch(m)?.group(1);
        if (w != null) {
          final cls = w.replaceFirst('Ardu', '');
          vehicle = 'Ardu$cls';
          (mavType, kind) = switch (cls) {
            'Plane' => (1, DeviceKind.drone),
            'Rover' => (10, DeviceKind.rover),
            'Sub' => (12, DeviceKind.rover),
            _ => (2, DeviceKind.drone),
          };
        }
      case 'ATT':
        const r = math.pi / 180;
        tl.tlm(t, {'att': _att(n(v, 'Roll') * r, n(v, 'Pitch') * r, n(v, 'Yaw') * r)});
      case 'IMU':
        if (!first(v)) break;
        tl.tlm(t, {
          'imu': [n(v, 'AccX'), n(v, 'AccY'), n(v, 'AccZ'), n(v, 'GyrX'), n(v, 'GyrY'), n(v, 'GyrZ')],
        });
      case 'ORGN':
        final o = (n(v, 'Lat'), n(v, 'Lng'), n(v, 'Alt'));
        if (v['Type'] == 1) home = o; // AHRS home
        origin ??= o;
      case 'GPS':
        if (!first(v) || n(v, 'Status') < 3) break;
        final lat = n(v, 'Lat'), lon = n(v, 'Lng'), alt = n(v, 'Alt');
        if (lat == 0 && lon == 0) break;
        home ??= origin ?? (lat, lon, alt);
        if (wallAt == null && v['GWk'] is int && (v['GWk'] as int) > 0) {
          wallAt = DateTime.utc(1980, 1, 6).add(Duration(days: 7 * (v['GWk'] as int), milliseconds: v['GMS'] as int)).subtract(const Duration(seconds: 18));
          wallT = t;
        }
        final spd = n(v, 'Spd'), crs = n(v, 'GCrs') * math.pi / 180;
        final d = <String, dynamic>{
          'gps': [lat, lon, alt, n(v, 'NSats')],
          'vel': [spd * math.sin(crs), spd * math.cos(crs), -n(v, 'VZ')],
        };
        if (!hasPos) {
          final (x, y) = _en((home.$1, home.$2), lat, lon);
          d['pos'] = [x, y, alt - home.$3];
        }
        tl.tlm(t, d);
      case 'POS':
        final lat = n(v, 'Lat'), lon = n(v, 'Lng');
        if (lat == 0 && lon == 0) break;
        home ??= origin ?? (lat, lon, n(v, 'Alt'));
        hasPos = true;
        final (x, y) = _en((home.$1, home.$2), lat, lon);
        tl.tlm(t, {
          'pos': [x, y, v.containsKey('RelHomeAlt') ? n(v, 'RelHomeAlt') : n(v, 'Alt') - home.$3],
        });
      case 'BAT' || 'CURR':
        if (!first(v)) break;
        tl.tlm(t, {
          'bat': [n(v, 'Volt'), n(v, 'Curr'), if (v['RemPct'] is num) n(v, 'RemPct')],
        });
      case 'CTUN':
        if (v['ThO'] is num) {
          tl.tlm(t, {
            'throttle': [n(v, 'ThO')],
          });
        }
      case 'MODE':
        native = mavModeName(Mav.ardupilot, mavType, (v['ModeNum'] ?? v['Mode'] ?? 0) as int);
        mode = appMode(native);
        state();
      case 'ARM':
        armed = n(v, 'ArmState') != 0;
        state();
      case 'EV':
        final id = n(v, 'Id');
        if (id == 10 || id == 11) {
          armed = id == 10;
          state();
        }
    }
  }
  final t0 = tl.t0 ?? 0;
  return ImportedLog(
    format: 'ArduPilot log',
    deviceName: vehicle,
    kind: kind,
    frames: tl.frames,
    startedAt: wallAt?.subtract(Duration(microseconds: ((wallT - t0) * 1e6).round())),
  );
}

// ------------------------------------------------------------------ PX4 ULog
class _UField {
  _UField(this.type, this.name, this.count);
  final String type, name;
  final int count;
}

const _uSize = {
  'int8_t': 1, 'uint8_t': 1, 'bool': 1, 'char': 1, 'int16_t': 2, 'uint16_t': 2, //
  'int32_t': 4, 'uint32_t': 4, 'float': 4, 'int64_t': 8, 'uint64_t': 8, 'double': 8,
};

const _px4Nav = {
  0: 'MANUAL', 1: 'ALTCTL', 2: 'POSCTL', 3: 'AUTO.MISSION', 4: 'AUTO.LOITER', 5: 'AUTO.RTL', 7: 'AUTO.RTGS', 10: 'ACRO', //
  12: 'DESCEND', 13: 'TERMINATION', 14: 'OFFBOARD', 15: 'STABILIZED', 17: 'AUTO.TAKEOFF', 18: 'AUTO.LAND', 19: 'AUTO.FOLLOW',
  20: 'AUTO.PRECLAND', 21: 'ORBIT', 22: 'AUTO.VTOL_TAKEOFF',
};

ImportedLog _ulog(Uint8List b) {
  final bd = ByteData.sublistView(b);
  final formats = <String, List<_UField>>{};
  final layouts = <String, Map<String, (int, String)>>{};
  final subs = <int, (String, int)>{};
  final tl = _Timeline();
  var name = 'PX4', kind = DeviceKind.drone, armed = false, native = '';
  DateTime? wallAt;
  double wallT = 0;
  (double, double, double)? home;

  int sizeOf(String type) => _uSize[type] ?? (formats[type] ?? const <_UField>[]).fold(0, (s, f) => s + sizeOf(f.type) * f.count);

  // Offsets of a topic's top-level fields; arrays as name[i].
  Map<String, (int, String)> layout(String topic) => layouts.putIfAbsent(topic, () {
    final out = <String, (int, String)>{};
    var o = 0;
    for (final f in formats[topic] ?? const <_UField>[]) {
      final sz = sizeOf(f.type);
      for (var k = 0; k < f.count; k++) {
        out[f.count > 1 ? '${f.name}[$k]' : f.name] = (o + k * sz, f.type);
      }
      o += sz * f.count;
    }
    return out;
  });

  var i = 16;
  while (i + 3 <= b.length) {
    final size = bd.getUint16(i, Endian.little), type = b[i + 2], p = i + 3;
    i = p + size;
    if (i > b.length) break;
    switch (type) {
      case 0x46: // 'F': format
        final s = latin1.decode(b.sublist(p, p + size));
        final c = s.indexOf(':');
        if (c < 0) break;
        formats[s.substring(0, c)] = [
          for (final f in s.substring(c + 1).split(';'))
            if (f.trim().contains(' '))
              () {
                final parts = f.trim().split(' '), m = RegExp(r'^(\w+)\[(\d+)\]$').firstMatch(parts[0]);
                return m == null ? _UField(parts[0], parts[1], 1) : _UField(m.group(1)!, parts[1], int.parse(m.group(2)!));
              }(),
        ];
      case 0x49: // 'I': info
        final kl = b[p];
        final key = latin1.decode(b.sublist(p + 1, p + 1 + kl));
        if (key.endsWith(' sys_name')) name = _cstr(bd, p + 1 + kl, size - 1 - kl);
      case 0x41: // 'A': subscription
        subs[bd.getUint16(p + 1, Endian.little)] = (latin1.decode(b.sublist(p + 3, p + size)), b[p]);
      case 0x44: // 'D': data
        final sub = subs[bd.getUint16(p, Endian.little)];
        if (sub == null || sub.$2 != 0) break;
        final topic = sub.$1, lay = layout(topic), at = p + 2, end = p + size;
        num? f(String k) {
          final e = lay[k];
          if (e == null || at + e.$1 + (_uSize[e.$2] ?? 0) > end) return null;
          final o = at + e.$1;
          return switch (e.$2) {
            'int8_t' => bd.getInt8(o),
            'uint8_t' || 'bool' || 'char' => bd.getUint8(o),
            'int16_t' => bd.getInt16(o, Endian.little),
            'uint16_t' => bd.getUint16(o, Endian.little),
            'int32_t' => bd.getInt32(o, Endian.little),
            'uint32_t' => bd.getUint32(o, Endian.little),
            'int64_t' => bd.getInt64(o, Endian.little),
            'uint64_t' => bd.getUint64(o, Endian.little),
            'float' => bd.getFloat32(o, Endian.little),
            'double' => bd.getFloat64(o, Endian.little),
            _ => null,
          };
        }

        double g(String k) => (f(k) ?? 0).toDouble();
        final ts = f('timestamp');
        if (ts == null) break;
        final t = ts / 1e6;
        switch (topic) {
          case 'vehicle_attitude':
            final w = g('q[0]'), x = g('q[1]'), y = g('q[2]'), z = g('q[3]');
            tl.tlm(t, {
              'att': _att(
                math.atan2(2 * (w * x + y * z), 1 - 2 * (x * x + y * y)),
                math.asin((2 * (w * y - z * x)).clamp(-1.0, 1.0)),
                math.atan2(2 * (w * z + x * y), 1 - 2 * (y * y + z * z)),
              ),
            });
          case 'vehicle_local_position':
            tl.tlm(t, {
              'pos': [g('y'), g('x'), -g('z')],
              'vel': [g('vy'), g('vx'), -g('vz')],
            });
          case 'vehicle_gps_position' || 'sensor_gps':
            final deg = f('latitude_deg') != null;
            final lat = deg ? g('latitude_deg') : g('lat') / 1e7, lon = deg ? g('longitude_deg') : g('lon') / 1e7;
            final alt = f('altitude_msl_m') != null ? g('altitude_msl_m') : g('alt') / 1000;
            if (g('fix_type') < 3 || (lat == 0 && lon == 0)) break;
            home ??= (lat, lon, alt);
            final utc = f('time_utc_usec');
            if (wallAt == null && utc != null && utc > 0) {
              wallAt = DateTime.fromMicrosecondsSinceEpoch(utc.toInt(), isUtc: true);
              wallT = t;
            }
            tl.tlm(t, {
              'gps': [lat, lon, alt, g('satellites_used')],
            });
          case 'battery_status':
            final v = f('voltage_v') != null ? g('voltage_v') : g('voltage_filtered_v'), rem = g('remaining');
            if (v <= 0) break;
            tl.tlm(t, {
              'bat': [v, math.max(0.0, g('current_a')), if (rem >= 0) rem * 100],
            });
          case 'sensor_combined':
            tl.tlm(t, {
              'imu': [g('accelerometer_m_s2[0]'), g('accelerometer_m_s2[1]'), g('accelerometer_m_s2[2]'), g('gyro_rad[0]'), g('gyro_rad[1]'), g('gyro_rad[2]')],
            });
          case 'vehicle_status':
            final vt = f('vehicle_type');
            if (vt == 3) kind = DeviceKind.rover;
            final nav = _px4Nav[f('nav_state')?.toInt()] ?? 'MODE ${f('nav_state')}';
            final arm = f('arming_state') == 2;
            if (nav == native && arm == armed) break;
            native = nav;
            armed = arm;
            tl.state(t, {
              'mode': nav == 'DESCEND' ? 'LAND' : appMode(nav),
              'armed': armed,
              'ext': {'fc_mode': nav},
            });
        }
    }
  }
  final t0 = tl.t0 ?? 0;
  return ImportedLog(
    format: 'PX4 log',
    deviceName: name.isEmpty ? 'PX4' : name,
    kind: kind,
    frames: tl.frames,
    startedAt: wallAt?.subtract(Duration(microseconds: ((wallT - t0) * 1e6).round())),
  );
}
