import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_libserialport/flutter_libserialport.dart';

import 'discovery.dart';
import 'protocol.dart';
import 'radio.dart';
import 'transport.dart';

bool get serialSupported => Platform.isMacOS || Platform.isLinux || Platform.isWindows || Platform.isAndroid;

/// USB serial: newline-delimited JSON at 115200 baud. Radio links use the
/// same transport at their module's baud rate.
class SerialTransport implements Transport {
  SerialTransport(this.path, {this.baud = 115200, this.radio});
  final String path;
  final int baud;
  final RadioModule? radio;
  SerialPort? _port;
  SerialPortReader? _reader;
  StreamSubscription<Uint8List>? _sub;
  final _lines = LineDecoder();
  final _in = StreamController<Msg>.broadcast();

  @override
  String get label => radio == null ? 'USB · $path' : 'Radio · ${radio!.name}';

  @override
  Stream<Msg> get messages => _in.stream;

  @override
  Future<void> open() async {
    final p = SerialPort(path);
    if (!p.openReadWrite()) throw StateError('Cannot open $path: ${SerialPort.lastError}');
    p.config = SerialPortConfig()
      ..baudRate = baud
      ..bits = 8
      ..stopBits = 1
      ..parity = SerialPortParity.none
      ..setFlowControl(SerialPortFlowControl.none);
    _port = p;
    _reader = SerialPortReader(p);
    _sub = _reader!.stream.listen((b) {
      for (final m in _lines.add(b)) {
        if (!_in.isClosed) _in.add(m);
      }
    }, onError: (_) {});
  }

  @override
  void send(Msg m) {
    final p = _port;
    if (p == null || !p.isOpen) return;
    try {
      p.write(Uint8List.fromList(utf8.encode('${encodeMsg(m)}\n')), timeout: 20);
    } catch (_) {}
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    _reader?.close();
    _port?.close();
    _port?.dispose();
    _port = null;
    await _in.close();
  }
}

/// Serial ports worth offering: USB adapters, not the Bluetooth or debug
/// consoles macOS lists, and only the call-out (`cu.`) side on macOS.
List<String> usbPorts() {
  if (!serialSupported) return const [];
  try {
    return [
      for (final path in SerialPort.availablePorts)
        if (!path.contains('Bluetooth') && !path.contains('debug-console') && (!path.startsWith('/dev/tty.') || Platform.isLinux)) path,
    ];
  } catch (_) {
    return const [];
  }
}

/// Lists USB serial ports as candidate devices (kind is learned on connect).
/// Ports whose USB name matches a known radio are listed as radio links.
List<Found> serialPorts() => [
  for (final path in usbPorts())
    if (radioForUsb(describePort(path)) case final r?)
      Found(id: 'radio:$path', name: describePort(path), kind: 'generic', transport: 'radio', address: path, via: 'Radio · ${r.name}', radio: r.id)
    else
      Found(id: 'serial:$path', name: describePort(path), kind: 'generic', transport: 'serial', address: path, via: 'USB · $path'),
];

/// Opens [path] for a few seconds and returns the first `announce` heard,
/// for finding the device on the far side of a radio before pairing.
Future<Found?> probePort(String path, RadioModule radio, {int? baud, Duration listen = const Duration(seconds: 4)}) async {
  final t = SerialTransport(path, baud: baud ?? radio.baud, radio: radio);
  try {
    await t.open();
    final first = t.messages.firstWhere((m) => m['t'] == 'announce').timeout(listen);
    t.send({'t': 'discover', 'v': protocolVersion});
    final m = await first;
    return Found.fromAnnounce(m, transport: 'radio', address: path, via: 'Radio · ${radio.name}')..radio = radio.id;
  } catch (_) {
    return null;
  } finally {
    await t.close();
  }
}

String describePort(String path) {
  try {
    final p = SerialPort(path);
    final d = p.productName ?? p.description;
    p.dispose();
    return d == null || d.isEmpty ? path.split('/').last : d;
  } catch (_) {
    return path.split('/').last;
  }
}
