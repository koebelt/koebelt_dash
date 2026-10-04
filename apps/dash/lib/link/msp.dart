// Betaflight and INAV flight controllers over MSP (MultiWii Serial
// Protocol v1), presented to the app as a KoebeltLink device. MSP is a
// configuration protocol: the app reads telemetry, tunes the PID gains and
// can disarm, but does not fly the craft (that stays with the RC link), so
// the session is telemetry-only plus STOP.
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'bytes.dart';
import 'protocol.dart';
import 'transport.dart';

abstract final class Msp {
  static const apiVersion = 1, fcVariant = 2, fcVersion = 3, boardInfo = 4, name = 10;
  static const status = 101, rawImu = 102, rawGps = 106, attitude = 108, altitude = 109, analog = 110, pid = 112, batteryState = 130;
  static const setArmingDisabled = 99, setPid = 202, eepromWrite = 250;
}

/// `$M<` request with payload.
Uint8List mspFrame(int cmd, [List<int> payload = const []]) {
  var ck = payload.length ^ cmd;
  for (final b in payload) {
    ck ^= b;
  }
  return Uint8List.fromList([0x24, 0x4D, 0x3C, payload.length, cmd, ...payload, ck & 0xFF]);
}

/// A reply: command, payload, and whether the FC flagged an error (`$M!`).
typedef MspReply = ({int cmd, Uint8List data, bool error});

/// Splits MSP v1 replies (`$M>` / `$M!`) out of a byte stream.
class MspParser {
  final List<int> _buf = [];

  List<MspReply> add(List<int> bytes) {
    _buf.addAll(bytes);
    final out = <MspReply>[];
    var i = 0;
    while (true) {
      while (i + 2 < _buf.length && !(_buf[i] == 0x24 && _buf[i + 1] == 0x4D && (_buf[i + 2] == 0x3E || _buf[i + 2] == 0x21))) {
        i++;
      }
      if (_buf.length - i < 6) break;
      final len = _buf[i + 3], cmd = _buf[i + 4];
      if (_buf.length - i < 6 + len) break;
      var ck = len ^ cmd;
      for (var k = 0; k < len; k++) {
        ck ^= _buf[i + 5 + k];
      }
      if (ck == _buf[i + 5 + len]) {
        out.add((cmd: cmd, data: Uint8List.fromList(_buf.sublist(i + 5, i + 5 + len)), error: _buf[i + 2] == 0x21));
        i += 6 + len;
      } else {
        i++;
      }
    }
    _buf.removeRange(0, i);
    if (_buf.length > 4096) _buf.clear();
    return out;
  }
}

class _R {
  _R(this.d) : b = ByteData.sublistView(d);
  final Uint8List d;
  final ByteData b;
  int o = 0;
  bool has(int n) => o + n <= d.length;
  int u8() => has(1) ? d[o++] : 0;
  int i16() => has(2) ? b.getInt16((o += 2) - 2, Endian.little) : 0;
  int u16() => has(2) ? b.getUint16((o += 2) - 2, Endian.little) : 0;
  int i32() => has(4) ? b.getInt32((o += 4) - 4, Endian.little) : 0;
  int u32() => has(4) ? b.getUint32((o += 4) - 4, Endian.little) : 0;
  String str([int? n]) {
    final end = n == null ? d.length : math.min(d.length, o + n);
    final s = ascii.decode(d.sublist(o, end), allowInvalid: true).replaceAll('\x00', '');
    o = end;
    return s;
  }
}

const _pidNames = ['ROLL', 'PITCH', 'YAW'];

/// A Betaflight / INAV flight controller seen as a KoebeltLink device.
class MspTransport implements Transport {
  MspTransport(this.link, {this.poll = const Duration(milliseconds: 100)});
  final ByteLink link;
  final Duration poll;

  final _parser = MspParser();
  final _out = StreamController<Msg>.broadcast();
  StreamSubscription? _sub;
  Timer? _pollTimer, _helloTimer;

  String variant = '', version = '', board = '', craft = '';
  bool armed = false, _estop = false, _helloWanted = false, _helloSent = false, _identified = false;
  int _cells = 0;
  Uint8List? _pid;
  (double, double)? _home; // first GPS fix
  double _x = 0, _y = 0;
  final _clock = Stopwatch()..start();
  num? _pingTs;

  @override
  String get label => '${link.label} · MSP';

  @override
  Stream<Msg> get messages => _out.stream;

  String get firmware => switch (variant) {
    'BTFL' => 'Betaflight',
    'INAV' => 'INAV',
    'EMUF' => 'EmuFlight',
    'QUIC' => 'QuickSilver',
    'ARDU' => 'ArduPilot',
    _ => variant.isEmpty ? 'MSP' : variant,
  };

  @override
  Future<void> open() async {
    await link.open();
    _sub = link.bytes.listen((b) {
      for (final r in _parser.add(b)) {
        _onReply(r);
      }
    });
    for (final c in [Msp.apiVersion, Msp.fcVariant, Msp.fcVersion, Msp.boardInfo, Msp.name, Msp.pid]) {
      link.write(mspFrame(c));
    }
  }

  void _emit(Msg m) {
    if (!_out.isClosed) _out.add(m);
  }

  void _onReply(MspReply r) {
    if (_pingTs != null) {
      // Any answer completes the round trip the app is timing.
      _emit({'t': 'pong', 'ts': _pingTs});
      _pingTs = null;
    }
    if (r.error) return;
    final p = _R(r.data);
    switch (r.cmd) {
      case Msp.fcVariant:
        variant = p.str(4);
      case Msp.fcVersion:
        version = '${p.u8()}.${p.u8()}.${p.u8()}';
      case Msp.boardInfo:
        board = p.str(4);
      case Msp.name:
        craft = p.str().trim();
        _identified = true;
        if (_helloWanted) _hello();
      case Msp.status:
        p.u16(); // cycle time
        p.u16(); // i2c errors
        p.u16(); // sensors
        final flags = p.u32();
        final a = flags & 1 == 1; // BOXARM is the first box
        if (a != armed) {
          armed = a;
        }
        _state();
      case Msp.attitude:
        final roll = p.i16() / 10, pitch = p.i16() / 10, yaw = p.i16().toDouble();
        _tlm({
          'att': [-roll * math.pi / 180, -pitch * math.pi / 180, math.pi / 2 - yaw * math.pi / 180],
        });
      case Msp.altitude:
        final alt = p.i32() / 100, vario = p.i16() / 100;
        _tlm({
          'pos': [_x, _y, alt],
          'vel': [0, 0, vario],
        });
      case Msp.analog:
        final vbat = p.u8() / 10;
        p.u16(); // mAh drawn
        final rssi = p.u16();
        final amps = p.i16() / 100;
        final v = p.has(2) ? p.u16() / 100 : vbat;
        final pct = _cells > 0 ? ((v / _cells - 3.3) / .9 * 100).clamp(0, 100) : 0;
        _tlm({
          'bat': [v, amps, pct],
          'rssi': [rssi / 1023 * 100 - 100],
        });
      case Msp.batteryState:
        _cells = p.u8();
      case Msp.rawImu:
        _tlm({
          'imu': [
            p.i16() / 512 * 9.80665,
            p.i16() / 512 * 9.80665,
            p.i16() / 512 * 9.80665,
            p.i16() * (4 / 16.4) * math.pi / 180,
            p.i16() * (4 / 16.4) * math.pi / 180,
            p.i16() * (4 / 16.4) * math.pi / 180,
          ],
        });
      case Msp.rawGps:
        final fix = p.u8(), sats = p.u8(), lat = p.i32() / 1e7, lon = p.i32() / 1e7, alt = p.u16().toDouble();
        if (fix > 0 && (lat != 0 || lon != 0)) {
          final h = _home ??= (lat, lon);
          _y = (lat - h.$1) * 111111;
          _x = (lon - h.$2) * 111111 * math.cos(h.$1 * math.pi / 180);
          _tlm({
            'gps': [lat, lon, alt, sats],
          });
        }
      case Msp.pid:
        _pid = r.data;
        _params();
      case Msp.setPid:
        _emit({
          't': 'pack',
          'ok': true,
          'keys': [
            for (final n in _pidNames) ...['${n}_P', '${n}_I', '${n}_D'],
          ],
        });
    }
  }

  void _tlm(Map<String, dynamic> d) => _emit({'t': 'tlm', 'ts': _clock.elapsedMilliseconds, 'd': d});

  void _state() => _emit({
    't': 'state',
    'mode': armed ? 'MANUAL' : 'HOLD',
    'armed': armed,
    'estop': _estop,
    'fs': false,
    'ext': {'fc_mode': armed ? 'ARMED' : 'DISARMED'},
  });

  void _params() {
    final d = _pid;
    if (d == null || d.length < 9) return;
    _emit({
      't': 'params',
      'p': [
        for (var i = 0; i < 3; i++)
          for (var k = 0; k < 3; k++)
            ['${_pidNames[i]}_${'PID'[k]}', d[i * 3 + k], 0, 250, 1, '', '${_pidNames[i][0]}${_pidNames[i].substring(1).toLowerCase()} ${'PID'[k]}'],
      ],
      'layout': [
        for (var i = 0; i < 3; i++)
          {
            'cat': 'PID',
            'name': '${_pidNames[i][0]}${_pidNames[i].substring(1).toLowerCase()}',
            'keys': ['${_pidNames[i]}_P', '${_pidNames[i]}_I', '${_pidNames[i]}_D'],
            'chart': [
              ['gx', 'gy', 'gz'][i],
            ],
          },
      ],
    });
  }

  void _hello() {
    if (_helloSent) return;
    _helloSent = true;
    _helloTimer?.cancel();
    _emit({
      't': 'hello',
      'v': protocolVersion,
      'id': 'msp-${board.isEmpty ? 'fc' : board.toLowerCase()}',
      'name': craft.isNotEmpty ? craft : (board.isNotEmpty ? board : 'Flight controller'),
      'kind': 'drone',
      'model': [firmware, if (version.isNotEmpty) version, if (board.isNotEmpty) board].join(' · '),
      'fw': version,
      'lib': 'msp/1',
      'sensors': ['IMU', 'BARO'],
      'ok': true,
    });
    _params();
    _state();
    _pollTimer = Timer.periodic(poll, (_) {
      for (final c in [Msp.status, Msp.attitude, Msp.analog, Msp.altitude, Msp.rawImu, Msp.rawGps]) {
        link.write(mspFrame(c));
      }
    });
    link.write(mspFrame(Msp.batteryState));
  }

  @override
  void send(Msg m) {
    switch (m['t']) {
      case 'hello':
        _helloWanted = true;
        if (_identified) {
          _hello();
        } else {
          // Older firmware without MSP_NAME: say hello after a moment anyway.
          _helloTimer = Timer(const Duration(milliseconds: 800), _hello);
        }
      case 'ping':
        _pingTs = m['ts'] as num?;
        link.write(mspFrame(Msp.apiVersion));
      case 'stop':
        // Betaflight disarms when arming gets disabled over MSP.
        _estop = true;
        link.write(mspFrame(Msp.setArmingDisabled, [1, 0]));
        _state();
      case 'reset':
        _estop = false;
        link.write(mspFrame(Msp.setArmingDisabled, [0, 0]));
        _state();
      case 'pset':
        final d = _pid;
        if (d == null) return;
        final next = Uint8List.fromList(d);
        final p = (m['p'] as Map?)?.cast<String, dynamic>() ?? const {};
        for (final e in p.entries) {
          final parts = e.key.split('_');
          final i = _pidNames.indexOf(parts.first), k = parts.length > 1 ? 'PID'.indexOf(parts[1]) : -1;
          if (i < 0 || k < 0 || e.value is! num) continue;
          next[i * 3 + k] = (e.value as num).round().clamp(0, 255);
        }
        _pid = next;
        link.write(mspFrame(Msp.setPid, next));
      case 'psave':
        link.write(mspFrame(Msp.eepromWrite));
        _emit({'t': 'log', 'lvl': 'info', 'msg': 'Saved to the flight controller'});
    }
    // ctl, arm, mode and cmd are not sent: MSP is not a flight link.
  }

  @override
  Future<void> close() async {
    _pollTimer?.cancel();
    _helloTimer?.cancel();
    await _sub?.cancel();
    await link.close();
    await _out.close();
  }
}
