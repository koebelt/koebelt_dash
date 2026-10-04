import 'dart:async';

import '../core/model.dart';
import 'protocol.dart';
import 'transport.dart';

/// One open session with a device: handshake, control heartbeat (20 Hz,
/// slower on radio links, none on telemetry-only links), ping for latency,
/// and dispatch of incoming messages.
class DeviceSession {
  DeviceSession(this.transport, {required this.onMessage, this.key, this.ctlHz = 20, this.pingEvery = const Duration(seconds: 1)});
  final Transport transport;
  final void Function(Msg) onMessage;
  final String? key;

  /// Control heartbeat rate; 0 for telemetry-only links.
  final int ctlHz;
  final Duration pingEvery;
  bool get controls => ctlHz > 0;

  StreamSubscription<Msg>? _sub;
  Timer? _ctlTimer, _pingTimer;
  final _clock = Stopwatch()..start();
  double lastRx = 0;
  double latency = 0;
  int _seq = 0;
  bool closed = false;

  /// Current stick axes; read by the heartbeat.
  List<double> Function() axes = () => const [0, 0, 0, 0];

  /// When true, the heartbeat is withheld (used by "Test failsafe").
  bool holdHeartbeat = false;

  double get now => _clock.elapsedMicroseconds / 1e6;
  double get silence => now - lastRx;

  /// Opens the transport and waits for the device's `hello`.
  Future<Msg> open({Duration timeout = const Duration(seconds: 5)}) async {
    await transport.open();
    final hello = Completer<Msg>();
    _sub = transport.messages.listen((m) {
      lastRx = now;
      if (m['t'] == 'hello' && !hello.isCompleted) {
        hello.complete(m);
        return;
      }
      if (m['t'] == 'pong' && m['ts'] is num) {
        latency = (now * 1000 - (m['ts'] as num)).clamp(0, 5000).toDouble();
      }
      onMessage(m);
    });
    transport.send({'t': 'hello', 'v': protocolVersion, 'app': 'dash/$appVersion', 'key': ?key});
    final h = await hello.future.timeout(timeout);
    if (h['ok'] == false) throw StateError(h['err'] == 'key' ? 'Pairing key rejected. Pair the device again.' : 'Device refused the session');
    if (controls) {
      _ctlTimer = Timer.periodic(Duration(microseconds: 1000000 ~/ ctlHz), (_) {
        if (holdHeartbeat) return;
        final a = axes();
        transport.send({'t': 'ctl', 's': _seq++, 'lx': _r(a[0]), 'ly': _r(a[1]), 'rx': _r(a[2]), 'ry': _r(a[3])});
      });
    }
    _pingTimer = Timer.periodic(pingEvery, (_) => send({'t': 'ping', 'ts': (now * 1000).round()}));
    return h;
  }

  static double _r(double v) => (v * 1000).roundToDouble() / 1000;

  void send(Msg m) {
    if (!closed) transport.send(m);
  }

  /// Emergency stop is sent three times, 30 ms apart, per the protocol.
  void sendStop() {
    for (var i = 0; i < 3; i++) {
      Timer(Duration(milliseconds: 30 * i), () => send({'t': 'stop'}));
    }
  }

  Future<void> close() async {
    if (closed) return;
    send({'t': 'bye'});
    closed = true;
    _ctlTimer?.cancel();
    _pingTimer?.cancel();
    await Future<void>.delayed(const Duration(milliseconds: 40));
    await _sub?.cancel();
    await transport.close();
  }
}

/// Parameter table parsed from a `params` message.
List<ParamGroup> parseParams(Msg m, DeviceKind kind) {
  final defs = <String, ParamDef>{};
  for (final e in (m['p'] as List? ?? const [])) {
    final l = e as List;
    double n(int i, double d) => i < l.length && l[i] is num ? (l[i] as num).toDouble() : d;
    final key = '${l[0]}';
    final unit = l.length > 5 ? '${l[5] ?? ''}' : '';
    final label = l.length > 6 && l[6] != null ? '${l[6]}' : key;
    final v = n(1, 0);
    defs[key] = ParamDef(key, label, v, n(2, 0), n(3, v == 0 ? 1 : v * 4), n(4, .01), unit);
  }
  final layout = m['layout'];
  if (layout is List && layout.isNotEmpty) {
    return [
      for (final g in layout)
        ParamGroup('${g['cat']}', '${g['name']}', [for (final k in g['keys'] as List) ?defs['$k']], g['chart'] == null ? null : List<String>.from(g['chart'])),
    ];
  }
  // No layout: group by the prefix before the first underscore.
  final groups = <String, List<ParamDef>>{};
  for (final p in defs.values) {
    final i = p.key.indexOf('_');
    groups.putIfAbsent(i > 0 ? p.key.substring(0, i) : 'General', () => []).add(p);
  }
  return [for (final e in groups.entries) ParamGroup('Parameters', e.key, e.value)];
}
