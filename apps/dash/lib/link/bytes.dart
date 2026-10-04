import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

/// A raw byte pipe: what protocol adapters (MAVLink, MSP, Tello) run on.
/// KoebeltLink devices use [Transport]s directly; boards with their own
/// firmware need the bytes.
abstract class ByteLink {
  Stream<Uint8List> get bytes;
  Future<void> open();
  void write(List<int> data);
  Future<void> close();
  String get label;
}

/// UDP to one peer. [localPort] 0 picks any port; MAVLink ground stations
/// listen on 14550 because vehicles and telemetry bridges send there.
class UdpByteLink implements ByteLink {
  UdpByteLink({this.host, this.port, this.localPort = 0, this.name});

  /// Peer address. When null, the first sender becomes the peer.
  final String? host;
  final int? port;
  final int localPort;

  /// Label override for the UI.
  final String? name;

  RawDatagramSocket? _sock;
  InternetAddress? _peer;
  int? _peerPort;
  final _in = StreamController<Uint8List>.broadcast();

  @override
  String get label => name ?? 'UDP · ${host ?? '*'}:${port ?? localPort}';

  @override
  Stream<Uint8List> get bytes => _in.stream;

  @override
  Future<void> open() async {
    if (host != null) _peer = (await InternetAddress.lookup(host!)).first;
    _peerPort = port;
    final s = await RawDatagramSocket.bind(InternetAddress.anyIPv4, localPort, reuseAddress: true, reusePort: _reusePort);
    s.broadcastEnabled = true;
    _sock = s;
    s.listen((e) {
      if (e != RawSocketEvent.read) return;
      final d = s.receive();
      if (d == null) return;
      if (_peer == null) {
        _peer = d.address;
        _peerPort = d.port;
      } else if (d.address != _peer || (_peerPort != null && d.port != _peerPort && port != null)) {
        return;
      }
      _peerPort ??= d.port;
      if (!_in.isClosed) _in.add(d.data);
    });
  }

  @override
  void write(List<int> data) {
    final s = _sock, a = _peer, p = _peerPort;
    if (s == null || a == null || p == null) return;
    try {
      s.send(data, a, p);
    } catch (_) {}
  }

  @override
  Future<void> close() async {
    _sock?.close();
    _sock = null;
    await _in.close();
  }
}

bool get _reusePort => Platform.isMacOS || Platform.isIOS || Platform.isLinux || Platform.isAndroid;

/// Two ends of an in-memory pipe, for tests and simulators.
class MemoryByteLink implements ByteLink {
  MemoryByteLink._(this.label, this._out, this._in);

  /// Returns (app end, device end).
  static (MemoryByteLink, MemoryByteLink) pair([String label = 'Memory']) {
    final a = StreamController<Uint8List>.broadcast(), b = StreamController<Uint8List>.broadcast();
    return (MemoryByteLink._(label, a, b), MemoryByteLink._(label, b, a));
  }

  @override
  final String label;
  final StreamController<Uint8List> _out, _in;

  @override
  Stream<Uint8List> get bytes => _in.stream;

  @override
  Future<void> open() async {}

  @override
  void write(List<int> data) {
    if (!_out.isClosed) scheduleMicrotask(() => _out.isClosed ? null : _out.add(Uint8List.fromList(data)));
  }

  @override
  Future<void> close() async {
    if (!_out.isClosed) await _out.close();
  }
}

/// One UDP socket per local port, shared by everyone who listens there.
/// MAVLink discovery and a vehicle link both need port 14550 at once, and
/// two sockets on one port do not reliably both receive unicast packets.
class UdpHub {
  UdpHub._(this.port);
  final int port;
  static final Map<int, UdpHub> _hubs = {};

  RawDatagramSocket? _sock;
  Future<void>? _opening;
  int _users = 0;
  final _in = StreamController<Datagram>.broadcast();

  Stream<Datagram> get datagrams => _in.stream;

  static Future<UdpHub> acquire(int port) async {
    final h = _hubs.putIfAbsent(port, () => UdpHub._(port));
    h._users++;
    await (h._opening ??= h._open());
    return h;
  }

  Future<void> _open() async {
    final s = await RawDatagramSocket.bind(InternetAddress.anyIPv4, port, reuseAddress: true, reusePort: _reusePort);
    s.broadcastEnabled = true;
    _sock = s;
    s.listen((e) {
      if (e != RawSocketEvent.read) return;
      final d = s.receive();
      if (d != null && !_in.isClosed) _in.add(d);
    });
  }

  void send(List<int> data, InternetAddress to, int toPort) {
    try {
      _sock?.send(data, to, toPort);
    } catch (_) {}
  }

  void release() {
    if (--_users > 0) return;
    _sock?.close();
    _sock = null;
    _opening = null;
    _hubs.remove(port);
  }
}

/// A peer reached through a shared [UdpHub] (MAVLink vehicles on 14550).
/// With [port] 0 the peer's port is learnt from its first packet, and
/// [defaultPort] is used until then (14555: ESP MAVLink bridges listen there).
class HubByteLink implements ByteLink {
  HubByteLink({required this.host, required this.port, this.localPort = 14550, this.defaultPort = 14555, this.name});
  final String host;
  final int port, localPort, defaultPort;
  final String? name;
  UdpHub? _hub;
  InternetAddress? _peer;
  late int _peerPort = port == 0 ? defaultPort : port;
  StreamSubscription<Datagram>? _sub;
  final _in = StreamController<Uint8List>.broadcast();

  @override
  String get label => name ?? 'UDP · $host:$port';

  @override
  Stream<Uint8List> get bytes => _in.stream;

  @override
  Future<void> open() async {
    _peer = (await InternetAddress.lookup(host)).first;
    final h = _hub = await UdpHub.acquire(localPort);
    _sub = h.datagrams.listen((d) {
      if (d.address != _peer || (port != 0 && d.port != port) || _in.isClosed) return;
      _peerPort = d.port;
      _in.add(d.data);
    });
  }

  @override
  void write(List<int> data) {
    final p = _peer;
    if (p != null) _hub?.send(data, p, _peerPort);
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    _hub?.release();
    _hub = null;
    await _in.close();
  }
}
