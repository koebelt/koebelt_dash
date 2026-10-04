import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'discovery.dart';
import 'protocol.dart';
import 'transport.dart';

/// Wi-Fi transport: one JSON message per UDP datagram to device port 47800.
class UdpTransport implements Transport {
  UdpTransport(this.host, [this.port = udpDevicePort]);
  final String host;
  final int port;
  RawDatagramSocket? _sock;
  InternetAddress? _addr;
  final _in = StreamController<Msg>.broadcast();

  @override
  String get label => 'Wi-Fi · $host';

  @override
  Stream<Msg> get messages => _in.stream;

  @override
  Future<void> open() async {
    _addr = (await InternetAddress.lookup(host)).first;
    final s = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    _sock = s;
    s.listen((e) {
      if (e != RawSocketEvent.read) return;
      final d = s.receive();
      if (d == null || d.address != _addr) return;
      final m = decodeMsg(utf8.decode(d.data, allowMalformed: true));
      if (m != null && !_in.isClosed) _in.add(m);
    });
  }

  @override
  void send(Msg m) {
    final s = _sock, a = _addr;
    if (s == null || a == null) return;
    s.send(utf8.encode(encodeMsg(m)), a, port);
  }

  @override
  Future<void> close() async {
    _sock?.close();
    _sock = null;
    await _in.close();
  }
}

/// Listens for `announce` broadcasts on 47801 and broadcasts `discover`.
class LanDiscovery {
  RawDatagramSocket? _listen, _probe;
  Timer? _timer;
  bool _stopped = false;

  Future<void> start(void Function(Found) onFound) async {
    try {
      final l = await RawDatagramSocket.bind(InternetAddress.anyIPv4, udpAnnouncePort, reuseAddress: true, reusePort: _reusePortSupported);
      // stop() may have run while binding.
      if (_stopped) return l.close();
      _listen = l;
      l.listen((e) => _read(l, e, onFound));
    } catch (_) {
      // Port busy (another dash instance). Probing below still works.
    }
    try {
      final p = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      if (_stopped) return p.close();
      _probe = p;
      p.broadcastEnabled = true;
      p.listen((e) => _read(p, e, onFound));
      void probe() {
        try {
          _probe?.send(utf8.encode(encodeMsg({'t': 'discover'})), InternetAddress('255.255.255.255'), udpDevicePort);
        } catch (_) {}
      }

      probe();
      _timer = Timer.periodic(const Duration(seconds: 2), (_) => probe());
    } catch (_) {}
  }

  void _read(RawDatagramSocket s, RawSocketEvent e, void Function(Found) onFound) {
    if (e != RawSocketEvent.read) return;
    final d = s.receive();
    if (d == null) return;
    final m = decodeMsg(utf8.decode(d.data, allowMalformed: true));
    if (m == null || m['t'] != 'announce') return;
    onFound(Found.fromAnnounce(m, transport: 'udp', address: d.address.address, via: 'Wi-Fi · ${d.address.address}'));
  }

  void stop() {
    _stopped = true;
    _timer?.cancel();
    _listen?.close();
    _probe?.close();
    _listen = _probe = null;
  }
}

bool get _reusePortSupported => Platform.isMacOS || Platform.isIOS || Platform.isLinux || Platform.isAndroid;
