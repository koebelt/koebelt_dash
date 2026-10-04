// MAVLink v1/v2 framing and the handful of common.xml messages a ground
// station needs. Table-driven: each message is its id, CRC extra and field
// layout in wire order (larger types first, extensions last), as generated
// by the MAVLink tools. Checked against pymavlink in the tests.
import 'dart:convert';
import 'dart:typed_data';

enum MavType { u8, i8, u16, i16, u32, i32, u64, i64, f32, chr }

const _size = {
  MavType.u8: 1,
  MavType.i8: 1,
  MavType.u16: 2,
  MavType.i16: 2,
  MavType.u32: 4,
  MavType.i32: 4,
  MavType.u64: 8,
  MavType.i64: 8,
  MavType.f32: 4,
  MavType.chr: 1,
};

class MavField {
  const MavField(this.name, this.type, [this.count = 1]);
  final String name;
  final MavType type;
  final int count;
}

class MavDef {
  const MavDef(this.id, this.name, this.crcExtra, this.fields);
  final int id, crcExtra;
  final String name;
  final List<MavField> fields;
  int get length => fields.fold(0, (a, f) => a + _size[f.type]! * f.count);
}

const _u8 = MavType.u8,
    _i8 = MavType.i8,
    _u16 = MavType.u16,
    _i16 = MavType.i16,
    _u32 = MavType.u32,
    _i32 = MavType.i32,
    _u64 = MavType.u64,
    _i64 = MavType.i64,
    _f = MavType.f32;

const mavDefs = <int, MavDef>{
  0: MavDef(0, 'HEARTBEAT', 50, [
    MavField('custom_mode', _u32),
    MavField('type', _u8),
    MavField('autopilot', _u8),
    MavField('base_mode', _u8),
    MavField('system_status', _u8),
    MavField('mavlink_version', _u8),
  ]),
  1: MavDef(1, 'SYS_STATUS', 124, [
    MavField('present', _u32),
    MavField('enabled', _u32),
    MavField('health', _u32),
    MavField('load', _u16),
    MavField('voltage_battery', _u16),
    MavField('current_battery', _i16), //
    MavField('drop_rate_comm', _u16),
    MavField('errors_comm', _u16),
    MavField('e1', _u16),
    MavField('e2', _u16),
    MavField('e3', _u16),
    MavField('e4', _u16),
    MavField('battery_remaining', _i8),
    MavField('present_ext', _u32), MavField('enabled_ext', _u32), MavField('health_ext', _u32),
  ]),
  11: MavDef(11, 'SET_MODE', 89, [MavField('custom_mode', _u32), MavField('target_system', _u8), MavField('base_mode', _u8)]),
  21: MavDef(21, 'PARAM_REQUEST_LIST', 159, [MavField('target_system', _u8), MavField('target_component', _u8)]),
  22: MavDef(22, 'PARAM_VALUE', 220, [
    MavField('param_value', _f),
    MavField('param_count', _u16),
    MavField('param_index', _u16),
    MavField('param_id', MavType.chr, 16),
    MavField('param_type', _u8),
  ]),
  23: MavDef(23, 'PARAM_SET', 168, [
    MavField('param_value', _f),
    MavField('target_system', _u8),
    MavField('target_component', _u8),
    MavField('param_id', MavType.chr, 16),
    MavField('param_type', _u8),
  ]),
  24: MavDef(24, 'GPS_RAW_INT', 24, [
    MavField('time_usec', _u64),
    MavField('lat', _i32),
    MavField('lon', _i32),
    MavField('alt', _i32),
    MavField('eph', _u16),
    MavField('epv', _u16),
    MavField('vel', _u16),
    MavField('cog', _u16), //
    MavField('fix_type', _u8),
    MavField('satellites_visible', _u8),
    MavField('alt_ellipsoid', _i32),
    MavField('h_acc', _u32),
    MavField('v_acc', _u32),
    MavField('vel_acc', _u32),
    MavField('hdg_acc', _u32),
    MavField('yaw', _u16),
  ]),
  27: MavDef(27, 'RAW_IMU', 144, [
    MavField('time_usec', _u64),
    MavField('xacc', _i16),
    MavField('yacc', _i16),
    MavField('zacc', _i16),
    MavField('xgyro', _i16),
    MavField('ygyro', _i16),
    MavField('zgyro', _i16), //
    MavField('xmag', _i16), MavField('ymag', _i16), MavField('zmag', _i16), MavField('id', _u8), MavField('temperature', _i16),
  ]),
  30: MavDef(30, 'ATTITUDE', 39, [
    MavField('time_boot_ms', _u32),
    MavField('roll', _f),
    MavField('pitch', _f),
    MavField('yaw', _f),
    MavField('rollspeed', _f),
    MavField('pitchspeed', _f),
    MavField('yawspeed', _f),
  ]),
  32: MavDef(32, 'LOCAL_POSITION_NED', 185, [
    MavField('time_boot_ms', _u32),
    MavField('x', _f),
    MavField('y', _f),
    MavField('z', _f),
    MavField('vx', _f),
    MavField('vy', _f),
    MavField('vz', _f),
  ]),
  33: MavDef(33, 'GLOBAL_POSITION_INT', 104, [
    MavField('time_boot_ms', _u32),
    MavField('lat', _i32),
    MavField('lon', _i32),
    MavField('alt', _i32),
    MavField('relative_alt', _i32),
    MavField('vx', _i16),
    MavField('vy', _i16),
    MavField('vz', _i16),
    MavField('hdg', _u16),
  ]),
  66: MavDef(66, 'REQUEST_DATA_STREAM', 148, [
    MavField('req_message_rate', _u16),
    MavField('target_system', _u8),
    MavField('target_component', _u8),
    MavField('req_stream_id', _u8),
    MavField('start_stop', _u8),
  ]),
  69: MavDef(69, 'MANUAL_CONTROL', 243, [
    MavField('x', _i16), MavField('y', _i16), MavField('z', _i16), MavField('r', _i16), MavField('buttons', _u16), MavField('target', _u8), //
    MavField('buttons2', _u16),
    MavField('enabled_extensions', _u8),
    MavField('s', _i16),
    MavField('t', _i16),
    MavField('aux1', _i16),
    MavField('aux2', _i16),
    MavField('aux3', _i16),
    MavField('aux4', _i16),
    MavField('aux5', _i16),
    MavField('aux6', _i16),
  ]),
  74: MavDef(74, 'VFR_HUD', 20, [
    MavField('airspeed', _f),
    MavField('groundspeed', _f),
    MavField('alt', _f),
    MavField('climb', _f),
    MavField('heading', _i16),
    MavField('throttle', _u16),
  ]),
  75: MavDef(75, 'COMMAND_INT', 158, [
    MavField('param1', _f),
    MavField('param2', _f),
    MavField('param3', _f),
    MavField('param4', _f),
    MavField('x', _i32),
    MavField('y', _i32),
    MavField('z', _f),
    MavField('command', _u16), //
    MavField('target_system', _u8), MavField('target_component', _u8), MavField('frame', _u8), MavField('current', _u8), MavField('autocontinue', _u8),
  ]),
  76: MavDef(76, 'COMMAND_LONG', 152, [
    MavField('param1', _f),
    MavField('param2', _f),
    MavField('param3', _f),
    MavField('param4', _f),
    MavField('param5', _f),
    MavField('param6', _f),
    MavField('param7', _f), //
    MavField('command', _u16), MavField('target_system', _u8), MavField('target_component', _u8), MavField('confirmation', _u8),
  ]),
  77: MavDef(77, 'COMMAND_ACK', 143, [
    MavField('command', _u16),
    MavField('result', _u8),
    MavField('progress', _u8),
    MavField('result_param2', _i32),
    MavField('target_system', _u8),
    MavField('target_component', _u8),
  ]),
  109: MavDef(109, 'RADIO_STATUS', 185, [
    MavField('rxerrors', _u16),
    MavField('fixed', _u16),
    MavField('rssi', _u8),
    MavField('remrssi', _u8),
    MavField('txbuf', _u8),
    MavField('noise', _u8),
    MavField('remnoise', _u8),
  ]),
  111: MavDef(111, 'TIMESYNC', 34, [MavField('tc1', _i64), MavField('ts1', _i64)]),
  242: MavDef(242, 'HOME_POSITION', 104, [
    MavField('latitude', _i32),
    MavField('longitude', _i32),
    MavField('altitude', _i32),
    MavField('x', _f),
    MavField('y', _f),
    MavField('z', _f),
    MavField('q', _f, 4), //
    MavField('approach_x', _f), MavField('approach_y', _f), MavField('approach_z', _f), MavField('time_usec', _u64),
  ]),
  253: MavDef(253, 'STATUSTEXT', 83, [MavField('severity', _u8), MavField('text', MavType.chr, 50), MavField('id', _u16), MavField('chunk_seq', _u8)]),
};

/// One decoded message: sender, id and fields by name.
class MavMsg {
  MavMsg(this.sys, this.comp, this.id, this.f);
  final int sys, comp, id;
  final Map<String, dynamic> f;
  String get name => mavDefs[id]?.name ?? '#$id';
  num n(String k) => f[k] as num? ?? 0;
  @override
  String toString() => '$name($sys/$comp) $f';
}

/// CRC-16/MCRF4XX (X.25), as MAVLink uses.
int mavCrc(Iterable<int> bytes, [int crc = 0xFFFF]) {
  for (final b in bytes) {
    var t = (b ^ (crc & 0xFF)) & 0xFF;
    t ^= (t << 4) & 0xFF;
    crc = ((crc >> 8) ^ (t << 8) ^ (t << 3) ^ (t >> 4)) & 0xFFFF;
  }
  return crc;
}

/// Encodes MAVLink v2 frames as the ground station (sysid 255, compid 190).
class MavEncoder {
  MavEncoder({this.sys = 255, this.comp = 190});
  final int sys, comp;
  int _seq = 0;

  Uint8List encode(int id, Map<String, dynamic> values) {
    final def = mavDefs[id]!;
    final p = ByteData(def.length);
    var o = 0;
    for (final f in def.fields) {
      for (var i = 0; i < f.count; i++) {
        final v = f.type == MavType.chr ? null : (f.count == 1 ? values[f.name] : (values[f.name] as List?)?[i]);
        switch (f.type) {
          case MavType.u8:
            p.setUint8(o, (v as num? ?? 0).toInt() & 0xFF);
          case MavType.i8:
            p.setInt8(o, (v as num? ?? 0).toInt());
          case MavType.u16:
            p.setUint16(o, (v as num? ?? 0).toInt() & 0xFFFF, Endian.little);
          case MavType.i16:
            p.setInt16(o, (v as num? ?? 0).toInt(), Endian.little);
          case MavType.u32:
            p.setUint32(o, (v as num? ?? 0).toInt() & 0xFFFFFFFF, Endian.little);
          case MavType.i32:
            p.setInt32(o, (v as num? ?? 0).toInt(), Endian.little);
          case MavType.u64:
            p.setUint64(o, (v as num? ?? 0).toInt(), Endian.little);
          case MavType.i64:
            p.setInt64(o, (v as num? ?? 0).toInt(), Endian.little);
          case MavType.f32:
            p.setFloat32(o, (v as num? ?? 0).toDouble(), Endian.little);
          case MavType.chr:
            final s = ascii.encode('${values[f.name] ?? ''}');
            for (var k = 0; k < f.count; k++) {
              p.setUint8(o + k, k < s.length ? s[k] : 0);
            }
            o += f.count;
            i = f.count; // whole string written
            continue;
        }
        o += _size[f.type]!;
      }
    }
    // v2 drops trailing zero bytes of the payload (at least one byte stays).
    var len = def.length;
    while (len > 1 && p.getUint8(len - 1) == 0) {
      len--;
    }
    final out = BytesBuilder(copy: false)
      ..add([0xFD, len, 0, 0, _seq++ & 0xFF, sys, comp, id & 0xFF, (id >> 8) & 0xFF, (id >> 16) & 0xFF])
      ..add(Uint8List.sublistView(p, 0, len));
    final frame = out.takeBytes();
    final crc = mavCrc([...frame.sublist(1), def.crcExtra]);
    return Uint8List.fromList([...frame, crc & 0xFF, crc >> 8]);
  }
}

/// Splits a byte stream into MAVLink messages, v1 and v2, checking CRCs.
/// Messages with ids outside [mavDefs] are skipped.
class MavParser {
  final List<int> _buf = [];

  List<MavMsg> add(List<int> bytes) {
    _buf.addAll(bytes);
    final out = <MavMsg>[];
    var i = 0;
    while (true) {
      while (i < _buf.length && _buf[i] != 0xFD && _buf[i] != 0xFE) {
        i++;
      }
      if (i >= _buf.length) break;
      final v2 = _buf[i] == 0xFD;
      if (_buf.length - i < (v2 ? 10 : 6)) break;
      final len = _buf[i + 1];
      final signed = v2 && (_buf[i + 2] & 1) == 1;
      final head = v2 ? 10 : 6, total = head + len + 2 + (signed ? 13 : 0);
      if (_buf.length - i < total) break;
      final id = v2 ? _buf[i + 7] | _buf[i + 8] << 8 | _buf[i + 9] << 16 : _buf[i + 5];
      final def = mavDefs[id];
      if (def == null) {
        // Unknown id: its CRC cannot be checked, so this may not be a frame
        // start at all. Move one byte on; real frames re-sync on their own.
        i++;
        continue;
      }
      final crc = mavCrc([..._buf.sublist(i + 1, i + head + len), def.crcExtra]);
      final got = _buf[i + head + len] | _buf[i + head + len + 1] << 8;
      if (crc != got) {
        i++; // not a frame start after all
        continue;
      }
      final payload = Uint8List(def.length)..setRange(0, len < def.length ? len : def.length, _buf.sublist(i + head, i + head + len));
      out.add(MavMsg(_buf[i + (v2 ? 5 : 3)], _buf[i + (v2 ? 6 : 4)], id, _decode(def, payload)));
      i += total;
    }
    _buf.removeRange(0, i);
    if (_buf.length > 4096) _buf.clear();
    return out;
  }

  static Map<String, dynamic> _decode(MavDef def, Uint8List payload) {
    final b = ByteData.sublistView(payload);
    final m = <String, dynamic>{};
    var o = 0;
    for (final f in def.fields) {
      if (f.type == MavType.chr) {
        final raw = payload.sublist(o, o + f.count);
        final end = raw.indexOf(0);
        m[f.name] = ascii.decode(end < 0 ? raw : raw.sublist(0, end), allowInvalid: true);
        o += f.count;
        continue;
      }
      final vals = <num>[];
      for (var i = 0; i < f.count; i++) {
        vals.add(switch (f.type) {
          MavType.u8 => b.getUint8(o),
          MavType.i8 => b.getInt8(o),
          MavType.u16 => b.getUint16(o, Endian.little),
          MavType.i16 => b.getInt16(o, Endian.little),
          MavType.u32 => b.getUint32(o, Endian.little),
          MavType.i32 => b.getInt32(o, Endian.little),
          MavType.u64 => b.getUint64(o, Endian.little),
          MavType.i64 => b.getInt64(o, Endian.little),
          MavType.f32 => b.getFloat32(o, Endian.little),
          MavType.chr => 0,
        });
        o += _size[f.type]!;
      }
      m[f.name] = f.count == 1 ? vals.first : vals;
    }
    return m;
  }
}

// ---- enums used by the adapter (common.xml)
abstract final class Mav {
  static const heartbeat = 0, sysStatus = 1, setMode = 11, paramRequestList = 21, paramValue = 22, paramSet = 23, gpsRawInt = 24, rawImu = 27;
  static const attitude = 30, localPositionNed = 32, globalPositionInt = 33, requestDataStream = 66, manualControl = 69, vfrHud = 74;
  static const commandInt = 75, commandLong = 76, commandAck = 77, radioStatus = 109, timesync = 111, homePosition = 242, statustext = 253;

  // MAV_CMD
  static const cmdNavTakeoff = 22, cmdDoSetMode = 176, cmdDoSetHome = 179, cmdDoReposition = 192, cmdArmDisarm = 400, cmdGetHomePosition = 410;
  static const cmdSetMessageInterval = 511;

  /// MAV_AUTOPILOT
  static const ardupilot = 3, px4 = 12, invalid = 8;

  /// MAV_MODE_FLAG
  static const flagSafetyArmed = 128, flagCustomModeEnabled = 1;

  /// MAV_TYPE values that are not vehicles (ground stations, gimbals, cameras…).
  static const nonVehicleTypes = {6, 18, 26, 27, 28, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46};

  static const forceDisarm = 21196.0;
}
