// Finding boards that do not run KoebeltLink: MAVLink vehicles on the
// network, a Tello on its Wi-Fi, and flight controllers and boards on USB.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'boards.dart';
import 'bytes.dart';
import 'discovery.dart';
import 'mavlink.dart';
import 'mavlink_adapter.dart';
import 'serial_io.dart';
import 'tello.dart';

/// Ground stations listen on UDP 14550: SITL, MAVProxy, mavlink-router and
/// Wi-Fi telemetry bridges (ESP8266/ESP32 MAVLink bridges, DroneBridge) send
/// their vehicles' heartbeats there.
const mavlinkGcsPort = 14550;

class MavlinkUdpDiscovery {
  MavlinkUdpDiscovery({this.port = mavlinkGcsPort});
  final int port;
  UdpHub? _hub;
  StreamSubscription? _sub;
  final _parsers = <String, MavParser>{};
  bool _stopped = false;

  Future<void> start(void Function(Found) onFound) async {
    try {
      final h = await UdpHub.acquire(port);
      if (_stopped) return h.release();
      _hub = h;
      _sub = h.datagrams.listen((d) {
        final from = '${d.address.address}:${d.port}';
        for (final m in (_parsers[from] ??= MavParser()).add(d.data)) {
          if (m.id != Mav.heartbeat) continue;
          final t = m.n('type').toInt(), ap = m.n('autopilot').toInt();
          if (ap == Mav.invalid || Mav.nonVehicleTypes.contains(t)) continue;
          final fw = ap == Mav.px4 ? 'PX4' : (ap == Mav.ardupilot ? 'ArduPilot' : 'MAVLink');
          onFound(
            Found(
              id: 'mav-${m.sys}@$from',
              name: mavVehicleName(ap, t),
              kind: mavKind(t),
              transport: 'udp',
              address: from,
              via: 'Wi-Fi · $from',
              model: '$fw · system ${m.sys}',
              proto: 'mavlink',
            ),
          );
        }
      });
    } catch (_) {
      // Port in use by another ground station (Mission Planner, QGC).
    }
  }

  void stop() {
    _stopped = true;
    _sub?.cancel();
    _hub?.release();
    _hub = null;
  }
}

/// A Tello answers "ok" to "command" when this device is on its Wi-Fi.
class TelloDiscovery {
  RawDatagramSocket? _sock;
  Timer? _timer;
  bool _stopped = false;

  Future<void> start(void Function(Found) onFound, {String host = telloHost, int port = 8889}) async {
    try {
      final s = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      if (_stopped) return s.close();
      _sock = s;
      final addr = InternetAddress(host);
      s.listen((e) {
        if (e != RawSocketEvent.read) return;
        final d = s.receive();
        if (d == null || utf8.decode(d.data, allowMalformed: true).trim() != 'ok') return;
        onFound(
          Found(id: 'tello@$host', name: 'Tello', kind: 'drone', transport: 'udp', address: host, via: 'Wi-Fi · $host', model: 'DJI Tello', proto: 'tello'),
        );
      });
      void ask() {
        try {
          s.send(utf8.encode('command'), addr, port);
        } catch (_) {}
      }

      ask();
      _timer = Timer.periodic(const Duration(seconds: 2), (_) => ask());
    } catch (_) {}
  }

  void stop() {
    _stopped = true;
    _timer?.cancel();
    _sock?.close();
  }
}

/// Probes USB ports whose board is known to be safe to talk to, once per
/// scan, and reports what each one runs.
class UsbBoardScanner {
  final Set<String> _done = {};
  bool _stopped = false;

  Future<void> start(void Function(Found) onFound, {bool Function(String path)? skip}) async {
    for (final path in usbPorts()) {
      if (_stopped) return;
      if (_done.contains(path) || (skip?.call(path) ?? false)) continue;
      final (vid, pid) = portIds(path);
      final b = boardFor(vid, pid);
      if (b == null || !b.probe) continue;
      _done.add(path);
      final r = await probeLink(SerialByteLink(path, baud: 115200));
      if (r == null || _stopped) continue;
      onFound(
        Found(
          id: r.proto == 'koebelt' ? (r.id ?? 'serial:$path') : '${r.proto}:$path',
          name: r.name,
          kind: r.kind,
          transport: 'serial',
          address: path,
          via: 'USB · ${b.name}',
          model: r.model,
          pair: r.pair,
          lib: r.lib,
          proto: r.proto,
          board: b.name,
        ),
      );
    }
  }

  void stop() => _stopped = true;
}
