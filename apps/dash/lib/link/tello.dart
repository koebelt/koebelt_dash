// DJI / Ryze Tello and Tello EDU over the Tello SDK: text commands to UDP
// 8889, state lines on UDP 8890, presented as a KoebeltLink drone. The phone
// or computer joins the Tello's own Wi-Fi (TELLO-XXXXXX); the drone is then
// always 192.168.10.1.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'protocol.dart';
import 'transport.dart';

const telloHost = '192.168.10.1';

/// Parses a Tello state line: `pitch:0;roll:0;yaw:0;vgx:0;…;\r\n`.
Map<String, double> parseTelloState(String s) => {
  for (final kv in s.trim().split(';'))
    if (kv.contains(':')) kv.substring(0, kv.indexOf(':')): double.tryParse(kv.substring(kv.indexOf(':') + 1)) ?? 0,
};

class TelloTransport implements Transport {
  TelloTransport({this.host = telloHost, this.cmdPort = 8889, this.statePort = 8890});
  final String host;
  final int cmdPort, statePort;

  RawDatagramSocket? _cmd, _state;
  InternetAddress? _addr;
  final _out = StreamController<Msg>.broadcast();
  Timer? _hello;
  bool _helloWanted = false, _connected = false, _flying = false, _armed = false, _estop = false;
  String _mode = 'HOLD', _lastState = '';
  final List<double> _pos = [0, 0, 0];
  DateTime? _lastState8890;
  final _clock = Stopwatch()..start();
  num? _pingTs;

  @override
  String get label => 'Wi-Fi · Tello';

  @override
  Stream<Msg> get messages => _out.stream;

  @override
  Future<void> open() async {
    _addr = (await InternetAddress.lookup(host)).first;
    final c = _cmd = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    c.listen((e) {
      if (e != RawSocketEvent.read) return;
      final d = c.receive();
      if (d != null) _reply(utf8.decode(d.data, allowMalformed: true).trim());
    });
    final s = _state = await RawDatagramSocket.bind(InternetAddress.anyIPv4, statePort, reuseAddress: true);
    s.listen((e) {
      if (e != RawSocketEvent.read) return;
      final d = s.receive();
      if (d != null) _onState(utf8.decode(d.data, allowMalformed: true));
    });
    _write('command'); // enter SDK mode
  }

  void _write(String cmd) {
    final c = _cmd, a = _addr;
    if (c == null || a == null) return;
    try {
      c.send(utf8.encode(cmd), a, cmdPort);
    } catch (_) {}
  }

  void _emit(Msg m) {
    if (!_out.isClosed) _out.add(m);
  }

  void _reply(String r) {
    if (_pingTs != null) {
      _emit({'t': 'pong', 'ts': _pingTs});
      _pingTs = null;
    }
    if (r == 'ok' && !_connected) {
      _connected = true;
      if (_helloWanted) _sayHello();
    } else if (r.startsWith('error')) {
      _emit({'t': 'log', 'lvl': 'warn', 'msg': 'Tello: $r'});
    }
  }

  void _sayHello() {
    _hello?.cancel();
    _emit({
      't': 'hello',
      'v': protocolVersion,
      'id': 'tello',
      'name': 'Tello',
      'kind': 'drone',
      'model': 'DJI Tello · SDK',
      'lib': 'tello/2',
      'sensors': ['IMU', 'BARO', 'TOF'],
      'ok': true,
    });
    _emit({
      't': 'chan',
      'ch': [
        {
          'id': 'tof',
          'axes': ['dist'],
          'unit': 'cm',
          'hz': 10,
        },
      ],
    });
    _pushState();
  }

  void _onState(String line) {
    final s = parseTelloState(line);
    if (s.isEmpty) return;
    final now = DateTime.now();
    final dt = _lastState8890 == null ? 0.0 : now.difference(_lastState8890!).inMicroseconds / 1e6;
    _lastState8890 = now;
    final yaw = (s['yaw'] ?? 0) * math.pi / 180;
    // Velocities are in decimetres per second, x forward and y right of the
    // take-off heading, as community Tello libraries read them.
    final vf = (s['vgx'] ?? 0) / 10, vr = (s['vgy'] ?? 0) / 10, vz = -(s['vgz'] ?? 0) / 10;
    final vx = vr, vy = vf; // east-ish, north-ish: the take-off heading is "north"
    if (dt > 0 && dt < 1) {
      _pos[0] += vx * dt;
      _pos[1] += vy * dt;
    }
    _pos[2] = (s['h'] ?? 0) / 100;
    _flying = _pos[2] > .1 || (s['tof'] ?? 0) > 30 && _flying;
    _emit({
      't': 'tlm',
      'ts': _clock.elapsedMilliseconds,
      'd': {
        'att': [-(s['roll'] ?? 0) * math.pi / 180, (s['pitch'] ?? 0) * math.pi / 180, math.pi / 2 - yaw],
        'pos': List.of(_pos),
        'vel': [vx, vy, vz],
        'bat': [0, 0, s['bat'] ?? 0],
        'temp': [((s['templ'] ?? 0) + (s['temph'] ?? 0)) / 2],
        'imu': [(s['agx'] ?? 0) / 1000 * 9.80665, (s['agy'] ?? 0) / 1000 * 9.80665, (s['agz'] ?? 0) / 1000 * 9.80665, 0, 0, 0],
        'tof': [s['tof'] ?? 0],
      },
    });
    _pushState();
  }

  void _pushState() {
    final m = {'t': 'state', 'mode': _mode, 'armed': _armed || _flying, 'estop': _estop, 'fs': false, 'ext': <String, dynamic>{}};
    final k = '$m';
    if (k != _lastState) {
      _lastState = k;
      _emit(m);
    }
  }

  @override
  void send(Msg m) {
    switch (m['t']) {
      case 'hello':
        _helloWanted = true;
        if (_connected) {
          _sayHello();
        } else {
          _write('command');
        }
      case 'ping':
        _pingTs = m['ts'] as num?;
        if (!_flying) _write('battery?');
      case 'ctl':
        // The rc heartbeat also keeps the Tello from landing on its own
        // after 15 s without commands.
        if (!_flying) return;
        int c(String k) => (((m[k] as num?) ?? 0).toDouble().clamp(-1.0, 1.0) * 100).round();
        final manual = _mode == 'MANUAL' && !_estop;
        _write(manual ? 'rc ${c('rx')} ${c('ry')} ${c('ly')} ${c('lx')}' : 'rc 0 0 0 0');
      case 'arm':
        _armed = m['v'] == true && !_estop;
        if (!_armed && _flying) _write('land');
        _pushState();
      case 'mode':
        if (_estop) return;
        final want = '${m['m']}';
        switch (want) {
          case 'TAKEOFF':
            _takeoff();
          case 'LAND' || 'RTH':
            _write('land');
            _mode = 'LAND';
          case 'HOLD' || 'AUTO':
            _write('stop'); // hover in place
            _mode = 'HOLD';
          case 'MANUAL':
            _mode = 'MANUAL';
        }
        _pushState();
      case 'stop':
        _estop = true;
        _armed = false;
        _write('emergency'); // motors off at once
        _pushState();
      case 'reset':
        _estop = false;
        _pushState();
      case 'cmd':
        if (_estop) return;
        final a = (m['a'] as Map?)?.cast<String, dynamic>() ?? const {};
        double n(String k) => (a[k] as num?)?.toDouble() ?? 0;
        switch (m['c']) {
          case 'takeoff':
            _takeoff();
          case 'goto':
            _goto(n('x'), n('y'), n('z'));
          case 'sethome':
            _pos[0] = _pos[1] = 0;
        }
    }
  }

  void _takeoff() {
    if (!_armed) {
      _emit({'t': 'log', 'lvl': 'warn', 'msg': 'Arm before taking off'});
      return;
    }
    _write('takeoff');
    _mode = 'HOLD';
  }

  /// `go x y z speed` is relative to the drone, in cm, 20–500 per axis.
  void _goto(double x, double y, double z) {
    final dx = x - _pos[0], dy = y - _pos[1], dz = z - _pos[2];
    int cm(double v) {
      final c = (v * 100).round();
      return c.abs() < 20 ? 0 : c.clamp(-500, 500);
    }

    // Take-off heading is "north" (+y): forward is +y, left is −x.
    final fwd = cm(dy), left = cm(-dx), up = cm(dz);
    if (fwd == 0 && left == 0 && up == 0) return;
    _write('go $fwd $left $up 50');
    _mode = 'AUTO';
    _pushState();
  }

  @override
  Future<void> close() async {
    _hello?.cancel();
    _cmd?.close();
    _state?.close();
    await _out.close();
  }
}
