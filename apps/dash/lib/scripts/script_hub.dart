import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import '../core/dash.dart';
import '../core/device_link.dart';
import '../core/model.dart';
import '../link/protocol.dart';
import 'script_runner.dart';

/// The script API: Python scripts (koebelt-dash-scripts) connect here over a
/// WebSocket, and every command they send passes the safety layer below
/// before it reaches a device. See docs/design/scripts.md and
/// protocol/SCRIPTS.md for the messages.
const scriptApiVersion = 1;
const scriptApiPort = 47920;

/// What the operator lets a script do on a device. Set in dash, never by the
/// script.
class ScriptLimits {
  ScriptLimits({this.maxSpeed = .6, this.fence = 50, this.ceiling = 30, this.allowArm = false, this.allowParams = false});

  /// Fraction of full stick (0–1). Also sent as the device's speed limit.
  double maxSpeed;

  /// Metres from home, horizontally, and height above home; 0 = no limit.
  double fence, ceiling;
  bool allowArm, allowParams;

  Map<String, dynamic> toJson() => {'maxSpeed': maxSpeed, 'fence': fence, 'ceiling': ceiling, 'allowArm': allowArm, 'allowParams': allowParams};
}

/// Stick names per kind, as the protocol's axes (lx ly rx ry): drones fly
/// "mode 2", ground robots steer on the left and drive on the right.
const stickAxes = <DeviceKind, Map<String, int>>{
  DeviceKind.drone: {'yaw': 0, 'throttle': 1, 'roll': 2, 'pitch': 3},
  DeviceKind.rover: {'steer': 0, 'throttle': 3},
};

/// Maps named sticks (`throttle`, `steer`…) or raw axes (`lx`…) to the four
/// axes, clamped to −1…1. Unknown names are an error.
List<double> sticksFor(DeviceKind kind, Map a, List<double> current) {
  final names = stickAxes[kind] ?? const {};
  final out = List.of(current);
  for (final e in a.entries) {
    final i = names[e.key] ?? const {'lx': 0, 'ly': 1, 'rx': 2, 'ry': 3}[e.key];
    if (i == null) {
      throw ArgumentError('"${e.key}" is not a stick of a ${kind.name}${names.isEmpty ? '' : ' (${names.keys.join(', ')})'}');
    }
    out[i] = (e.value as num).toDouble().clamp(-1.0, 1.0);
  }
  return out;
}

/// A script driving one device's sticks. The control heartbeat reads [axes]
/// 20 times a second; the operator's sticks win over the script's.
class ScriptDrive {
  ScriptDrive(this.conn, this.link);
  final ScriptConn conn;
  final DeviceLink link;
  final List<double> sticks = [0, 0, 0, 0];

  /// The operator took over: the script's sticks are ignored until Resume.
  bool paused = false;

  /// Beyond this, an operator stick counts as taking over.
  static const takeoverAt = .15;

  List<double> axes(List<double> operator) {
    if (operator.any((x) => x.abs() > takeoverAt)) {
      if (!paused) {
        paused = true;
        conn.hub.takeover(this);
      }
      return operator;
    }
    if (paused) return operator;
    final k = conn.limits.maxSpeed;
    return [for (final x in sticks) x * k];
  }
}

/// One connected script.
class ScriptConn {
  ScriptConn(this.hub, this.ws, this.name);
  final ScriptHub hub;
  final WebSocket ws;
  String name;
  int? pid;
  final limits = ScriptLimits();

  /// The device this script works with (a link id), and whether it holds its sticks.
  String? device;
  ScriptDrive? drive;
  double lastSeen = 0;

  /// Why dash took the sticks away (watchdog, geofence, STOP…): the script
  /// cannot take them again until the operator resumes it.
  String? blocked;

  /// The script's own loop rate, from its keep-alives (every()).
  double? hz;

  /// Declared by the script: settings (name → value, bounds) and triggers.
  final Map<String, Map<String, dynamic>> settings = {};
  final Map<String, Map<String, dynamic>> triggers = {};
  final List<({double t, String level, String text})> console = [];

  void send(Map<String, dynamic> m) {
    try {
      ws.add(jsonEncode(m));
    } catch (_) {}
  }

  /// The process, when dash started the script.
  ScriptRun? run;

  void log(String level, String text) {
    console.add((t: hub.d.t, level: level, text: text));
    if (console.length > 500) console.removeRange(0, console.length - 500);
    run?.log(level, text);
  }
}

class ScriptHub {
  ScriptHub(this.d);
  final Dash d;
  HttpServer? _server;
  final List<ScriptConn> conns = [];

  /// Scripts dash started, running or finished (the last few).
  final List<ScriptRun> runs = [];
  String token = _newToken();
  double _tlmAcc = 0;

  /// A script that sends nothing for this long, while it drives, loses the
  /// device, which holds.
  static const watchdog = .5;

  int? get port => _server?.port;

  static String _newToken() {
    final r = math.Random.secure();
    return [for (var i = 0; i < 16; i++) r.nextInt(256).toRadixString(16).padLeft(2, '0')].join();
  }

  /// Opens the API on 127.0.0.1. [discovery]: where to write the address and
  /// token for scripts started by hand (null in tests).
  Future<void> start({int port = scriptApiPort, File? discovery}) async {
    if (_server != null) return;
    try {
      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
    } on SocketException {
      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    }
    _server!.listen(_onRequest, onError: (_) {});
    if (discovery != null) {
      await discovery.parent.create(recursive: true);
      await discovery.writeAsString(jsonEncode({'url': 'ws://127.0.0.1:${_server!.port}/scripts', 'token': token, 'pid': pid, 'app': appVersion}));
    }
  }

  Future<void> stop() async {
    for (final c in List.of(conns)) {
      await c.ws.close();
    }
    await _server?.close(force: true);
    _server = null;
  }

  /// `~/.koebelt/dash-api.json`, where koebelt_dash_scripts looks for dash.
  static File defaultDiscovery() {
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '.';
    return File('$home/.koebelt/dash-api.json');
  }

  Future<void> _onRequest(HttpRequest req) async {
    if (req.uri.path != '/scripts' || !WebSocketTransformer.isUpgradeRequest(req)) {
      req.response.statusCode = HttpStatus.notFound;
      await req.response.close();
      return;
    }
    final ws = await WebSocketTransformer.upgrade(req);
    ScriptConn? c;
    ws.listen(
      (data) {
        if (data is! String) return;
        final Map<String, dynamic> m;
        try {
          m = (jsonDecode(data) as Map).cast<String, dynamic>();
        } catch (_) {
          return;
        }
        if (c == null) {
          if (m['t'] != 'hello' || m['token'] != token) {
            ws.add(jsonEncode({'t': 'bye', 'why': 'Wrong or missing token.'}));
            ws.close();
            return;
          }
          c = ScriptConn(this, ws, (m['name'] as String?) ?? 'script')..pid = (m['pid'] as num?)?.toInt();
          c!.run = runs.where((r) => r.pid == c!.pid && r.state == ScriptState.running).firstOrNull;
          c!.lastSeen = d.t;
          conns.add(c!);
          c!.log('info', 'Connected');
          c!.send({'t': 'welcome', 'v': scriptApiVersion, 'app': appVersion, 'devices': _devices()});
          d.emit();
          return;
        }
        c!.lastSeen = d.t;
        _onMsg(c!, m);
      },
      onDone: () {
        if (c != null) _gone(c!, 'The script ended.');
      },
      onError: (_) {},
    );
  }

  List<Map<String, dynamic>> _devices() => [
    for (final l in d.links.values) {'id': l.id, 'name': l.info.name, 'kind': l.kind.name, 'sim': l.info.simulated, 'focus': l.id == d.deviceId},
  ];

  DeviceLink? _link(ScriptConn c) => c.device == null ? null : d.links[c.device];

  void _gone(ScriptConn c, String why) {
    if (!conns.remove(c)) return;
    _release(c, why);
    d.emit();
  }

  /// Takes the sticks back from a script; a device it drove holds. Unless the
  /// script asked for it, it stays [ScriptConn.blocked] until the operator
  /// resumes it.
  void _release(ScriptConn c, String why, {bool block = true}) {
    final dr = c.drive;
    if (dr == null) return;
    c.drive = null;
    if (block) c.blocked = why;
    if (dr.link.drive == dr) {
      dr.link.drive = null;
      final t = dr.link.tel;
      if (t.armed && !t.estop && dr.link.kind != DeviceKind.arm && dr.link.kind != DeviceKind.bench) {
        d.linkHost(dr.link).seqSetMode('HOLD');
      }
    }
    c.log('warn', why);
    c.send({'t': 'released', 'why': why});
  }

  void _res(ScriptConn c, Object? id, {String? err, Object? value}) => c.send({'t': 'res', 'id': id, 'ok': err == null, 'err': ?err, 'value': ?value});

  void _onMsg(ScriptConn c, Map<String, dynamic> m) {
    final id = m['id'];
    try {
      switch (m['t']) {
        case 'ka':
          c.hz = (m['hz'] as num?)?.toDouble() ?? c.hz;
          return;
        case 'use':
          final want = m['device'] as String?;
          final l = want == null ? d.focus : d.links.values.where((x) => x.id == want || x.info.name.toLowerCase() == want.toLowerCase()).firstOrNull;
          if (l == null) return _res(c, id, err: want == null ? 'No device is connected in koebelt dash.' : 'No connected device called "$want".');
          if (c.device != l.id) _release(c, 'Switched device.', block: false);
          c.device = l.id;
          return _res(c, id, value: {'id': l.id, 'name': l.info.name, 'kind': l.kind.name, 'sim': l.info.simulated, 'lib': l.info.lib, 'limits': c.limits.toJson()});
        case 'sticks':
          final l = _link(c);
          if (l == null) return _res(c, id, err: 'Call use() first.');
          if (l.tel.estop) return _res(c, id, err: 'STOP is on: the operator must clear it.');
          if (c.blocked != null) return _res(c, id, err: '${c.blocked} The operator must resume the script in dash.');
          final other = l.drive;
          if (other != null && other.conn != c) return _res(c, id, err: 'Another script (${other.conn.name}) drives ${l.info.name}.');
          final dr = c.drive ??= ScriptDrive(c, l);
          l.drive = dr;
          dr.sticks.setAll(0, sticksFor(l.kind, (m['a'] as Map?) ?? const {}, dr.sticks));
          if (id != null) _res(c, id);
          return;
        case 'release':
          _release(c, 'Released by the script.', block: false);
          return _res(c, id);
        case 'cmd':
          return _cmd(c, id, m['c'] as String? ?? '', (m['a'] as Map?)?.cast<String, dynamic>() ?? const {});
        case 'setting':
          final name = m['name'] as String;
          final prev = c.settings[name];
          c.settings[name] = {...?prev, ...m, 'value': prev?['value'] ?? m['value']};
          d.emit();
          return _res(c, id, value: c.settings[name]!['value']);
        case 'trigger':
          c.triggers[m['name'] as String] = m;
          d.emit();
          return _res(c, id);
        case 'print':
          c.log((m['level'] as String?) ?? 'out', '${m['text']}');
          d.emit();
          return;
        case 'plot':
          final l = _link(c);
          if (l != null) l.tel.custom['script:${m['name']}'] = [(m['v'] as num).toDouble()];
          return;
        case 'mark':
          final l = _link(c);
          if (l != null) d.scriptEvent(l, '${m['text']}');
          return _res(c, id);
        case 'notify':
          c.log((m['level'] as String?) ?? 'info', '${m['text']}');
          d.emit();
          return _res(c, id);
        default:
          return _res(c, id, err: 'Unknown message "${m['t']}".');
      }
    } catch (e) {
      _res(c, id, err: e is ArgumentError ? '${e.message}' : '$e');
    }
  }

  void _cmd(ScriptConn c, Object? id, String cmd, Map<String, dynamic> a) {
    if (cmd == 'stop') {
      d.emergencyStop();
      return _res(c, id);
    }
    final l = _link(c);
    if (l == null) return _res(c, id, err: 'Call use() first.');
    if (l.tel.estop) return _res(c, id, err: 'STOP is on: the operator must clear it.');
    final h = d.linkHost(l), lim = c.limits;
    switch (cmd) {
      case 'mode':
        final mode = '${a['m']}'.toUpperCase();
        if (mode == 'TAKEOFF' && !lim.allowArm) return _res(c, id, err: 'Take-off is not allowed for this script (Limits in dash).');
        h.seqSetMode(mode);
      case 'arm':
        if (!lim.allowArm) return _res(c, id, err: 'Arming is not allowed for this script (Limits in dash).');
        h.seqSetArmed(a['v'] != false);
      case 'disarm':
        h.seqSetArmed(false);
      case 'speed':
        final v = (a['v'] as num).toDouble().clamp(.1, 1.0);
        h.seqSetSpeed(math.min(v, lim.maxSpeed));
      case 'params':
        return _res(c, id, value: d.paramDev[l.id] ?? const {});
      case 'pset':
        if (!lim.allowParams) return _res(c, id, err: 'Parameter writes are not allowed for this script (Limits in dash).');
        d.sendTo(l, {'t': 'pset', 'p': a});
      case 'psave':
        if (!lim.allowParams) return _res(c, id, err: 'Parameter writes are not allowed for this script (Limits in dash).');
        d.sendTo(l, {'t': 'psave'});
      default:
        // Kind-specific commands (release, countdown, sethome…).
        h.seqCmd(cmd, a);
    }
    _res(c, id);
  }

  /// The operator moved the sticks while a script drove.
  void takeover(ScriptDrive dr) {
    dr.conn.log('warn', 'Operator took over ${dr.link.info.name}');
    dr.conn.send({'t': 'takeover', 'on': true});
    d.emit();
  }

  /// Gives the sticks back to the script after a takeover.
  void resume(DeviceLink l) {
    final dr = l.drive;
    if (dr == null || !dr.paused) return;
    dr.paused = false;
    dr.conn.log('info', 'Control resumed');
    dr.conn.send({'t': 'takeover', 'on': false});
    d.emit();
  }

  /// Lets a script drive again after dash took the sticks away.
  void unblock(ScriptConn c) {
    if (c.blocked == null) return;
    c.blocked = null;
    c.log('info', 'Resumed by the operator');
    c.send({'t': 'resumed'});
    d.emit();
  }

  /// STOP: every script loses its device; scripts dash started are ended.
  void onStop() {
    for (final c in List.of(conns)) {
      _release(c, 'STOP');
      c.send({'t': 'stop'});
    }
    for (final r in runs) {
      if (r.state == ScriptState.running) {
        r.log('warn', 'STOP');
        r.stop(grace: const Duration(milliseconds: 300));
      }
    }
  }

  /// Runs a script file. The interpreter: [python], else the one the script
  /// names in its first lines (`# python: …`), else [fallback].
  Future<ScriptRun> runFile(File file, {String? python, String fallback = 'python3'}) async {
    if (_server == null) throw StateError('The script API is not running.');
    final py = python ?? pythonFromHeader(await file.readAsString()) ?? fallback;
    final r = await ScriptRun.start(file, py, url: 'ws://127.0.0.1:${_server!.port}/scripts', token: token, onChange: d.emit);
    runs.add(r);
    if (runs.length > 20) runs.removeAt(0);
    d.emit();
    return r;
  }

  /// The connection of a script dash started, once it has connected.
  ScriptConn? connOf(ScriptRun r) => conns.where((c) => c.run == r).firstOrNull;

  /// A trigger fired by the operator or a condition.
  void fire(ScriptConn c, String name, [Object? value]) {
    c.log('trig', 'Trigger "$name"');
    c.send({'t': 'fire', 'name': name, 'value': ?value});
    d.emit();
  }

  /// A setting changed in dash.
  void setSetting(ScriptConn c, String name, Object value) {
    c.settings[name]?['value'] = value;
    c.send({'t': 'setting', 'name': name, 'value': value});
    d.emit();
  }

  void tick(double dt) {
    if (conns.isEmpty) return;
    for (final c in List.of(conns)) {
      final dr = c.drive;
      if (dr == null) continue;
      if (!d.links.containsKey(dr.link.id)) {
        _release(c, '${dr.link.info.name} disconnected.');
        continue;
      }
      if (d.t - c.lastSeen > watchdog) {
        _release(c, 'The script stopped responding: ${dr.link.info.name} holds.');
        continue;
      }
      final p = dr.link.tel.pos, lim = c.limits;
      if (lim.fence > 0 && math.sqrt(p[0] * p[0] + p[1] * p[1]) > lim.fence) {
        _release(c, '${dr.link.info.name} left the ${lim.fence.round()} m geofence: it holds.');
      } else if (lim.ceiling > 0 && dr.link.kind == DeviceKind.drone && p[2] > lim.ceiling) {
        _release(c, '${dr.link.info.name} went above the ${lim.ceiling.round()} m ceiling: it holds.');
      }
    }
    _tlmAcc += dt;
    if (_tlmAcc < .05) return;
    _tlmAcc = 0;
    for (final c in conns) {
      final l = _link(c);
      if (l == null) continue;
      final t = l.tel;
      c.send({
        't': 'tlm',
        'd': {
          ...t.snapshot()..remove('seen'),
          'speed': math.sqrt(t.vel[0] * t.vel[0] + t.vel[1] * t.vel[1] + t.vel[2] * t.vel[2]),
          'heading': t.heading,
          'estop': t.estop,
          'failsafe': t.failsafe,
          'latency': l.session.latency,
          'drive': c.drive == null ? 'none' : (c.drive!.paused ? 'operator' : 'script'),
        },
      });
    }
  }

  void dispose() {
    for (final r in runs) {
      r.stop(grace: Duration.zero);
    }
    stop();
  }
}
