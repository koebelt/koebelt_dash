import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_libserialport/flutter_libserialport.dart';

import 'boards.dart';
import 'bytes.dart';
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

/// Raw bytes on a serial port, for protocol adapters (MAVLink, MSP).
class SerialByteLink implements ByteLink {
  SerialByteLink(this.path, {this.baud = 115200, this.name});
  final String path;
  final int baud;

  /// Label override for the UI.
  final String? name;
  SerialPort? _port;
  SerialPortReader? _reader;
  StreamSubscription<Uint8List>? _sub;
  final _in = StreamController<Uint8List>.broadcast();

  @override
  String get label => name ?? 'USB · $path';

  @override
  Stream<Uint8List> get bytes => _in.stream;

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
      if (!_in.isClosed) _in.add(b);
    }, onError: (_) {});
  }

  @override
  void write(List<int> data) {
    final p = _port;
    if (p == null || !p.isOpen) return;
    try {
      p.write(Uint8List.fromList(data), timeout: 20);
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

/// Ports the OS lists that are never a device: the macOS Bluetooth and
/// debug consoles, and the dial-in (`tty.`) twin of each macOS port.
bool _system(String path) => path.contains('Bluetooth-Incoming-Port') || path.contains('debug-console') || (path.startsWith('/dev/tty.') && !Platform.isLinux);

/// A Bluetooth Classic serial port (SPP): an HC-05 / HC-06 module paired in
/// the system settings shows up as one of these on desktops.
bool isBluetoothPort(String path) {
  if (path.contains('rfcomm')) return true;
  try {
    final p = SerialPort(path);
    final t = p.transport;
    p.dispose();
    return t == SerialPortTransport.bluetooth;
  } catch (_) {
    return false;
  }
}

/// USB serial ports worth offering.
List<String> usbPorts() {
  if (!serialSupported) return const [];
  try {
    return [
      for (final path in SerialPort.availablePorts)
        if (!_system(path) && !isBluetoothPort(path)) path,
    ];
  } catch (_) {
    return const [];
  }
}

/// Bluetooth Classic serial ports (paired HC-05 / HC-06 modules).
List<String> bluetoothPorts() {
  if (!serialSupported) return const [];
  try {
    return [
      for (final path in SerialPort.availablePorts)
        if (!_system(path) && isBluetoothPort(path)) path,
    ];
  } catch (_) {
    return const [];
  }
}

/// Lists serial ports as candidate devices (kind is learned on connect).
/// Ports whose USB name matches a known radio are listed as radio links,
/// Bluetooth Classic ports as Bluetooth serial modules.
List<Found> serialPorts() => [
  for (final path in usbPorts())
    if (radioForUsb(describePort(path)) case final r?)
      Found(id: 'radio:$path', name: describePort(path), kind: 'generic', transport: 'radio', address: path, via: 'Radio · ${r.name}', radio: r.id)
    else
      Found(id: 'serial:$path', name: _boardName(path), kind: 'generic', transport: 'serial', address: path, via: 'USB · $path', board: _board(path)?.name),
  // Opening a Bluetooth port starts a slow radio connection, so these are
  // listed, not probed.
  for (final path in bluetoothPorts())
    Found(
      id: 'bt:$path',
      name: path.split('/').last.replaceFirst(RegExp(r'^cu\.'), ''),
      kind: 'generic',
      transport: 'serial',
      address: path,
      via: 'Bluetooth serial · ${path.split('/').last}',
      module: 'btserial',
    ),
];

/// Opens [path] for a few seconds and reports the device on the far side
/// of a radio: a koebelt/link announce, or a MAVLink vehicle (SiK radios
/// usually carry MAVLink from a Pixhawk).
Future<Found?> probePort(String path, RadioModule radio, {int? baud, Duration listen = const Duration(seconds: 4)}) async {
  final r = await probeLink(SerialByteLink(path, baud: baud ?? radio.baud), listen: listen);
  if (r == null) return null;
  final f = Found(
    id: r.proto == 'koebelt' ? (r.id ?? 'radio:$path') : '${r.proto}:radio:$path',
    name: r.name,
    kind: r.kind,
    transport: 'radio',
    address: path,
    via: 'Radio · ${radio.name}',
    model: r.model,
    pair: r.pair,
    lib: r.lib,
    proto: r.proto,
  )..radio = radio.id;
  return f;
}

Board? _board(String path) {
  final (v, p) = portIds(path);
  return boardFor(v, p);
}

String _boardName(String path) {
  final d = describePort(path), b = _board(path);
  return b == null || b.family == 'uart' ? d : (d.toLowerCase().contains(b.name.toLowerCase().split(' ').first) ? d : '${b.name} · $d');
}

/// USB vendor and product id of a port, when the OS reports them.
(int?, int?) portIds(String path) {
  try {
    final p = SerialPort(path);
    final ids = (p.vendorId, p.productId);
    p.dispose();
    return ids;
  } catch (_) {
    return (null, null);
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
