import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:universal_ble/universal_ble.dart';

import 'discovery.dart';
import 'protocol.dart';
import 'transport.dart';

/// BLE transport over a Nordic-UART-style service, newline-delimited JSON.
class BleTransport implements Transport {
  BleTransport(this.deviceId, {this.name});
  final String deviceId;
  final String? name;
  final _in = StreamController<Msg>.broadcast();
  final _lines = LineDecoder();
  StreamSubscription<Uint8List>? _sub;
  int _chunk = 20;
  Future<void> _writing = Future.value();

  @override
  String get label => 'BLE · ${name ?? deviceId}';

  @override
  Stream<Msg> get messages => _in.stream;

  @override
  Future<void> open() async {
    await UniversalBle.connect(deviceId, timeout: const Duration(seconds: 12));
    await UniversalBle.discoverServices(deviceId);
    try {
      _chunk = (await UniversalBle.requestMtu(deviceId, 247)) - 3;
    } catch (_) {}
    _sub = UniversalBle.characteristicValueStream(deviceId, bleTx).listen((v) {
      for (final m in _lines.add(v)) {
        if (!_in.isClosed) _in.add(m);
      }
    });
    await UniversalBle.subscribeNotifications(deviceId, bleService, bleTx);
  }

  @override
  void send(Msg m) {
    final bytes = Uint8List.fromList(utf8.encode('${encodeMsg(m)}\n'));
    // Serialise writes so chunks of different messages never interleave.
    _writing = _writing.then((_) async {
      for (var o = 0; o < bytes.length; o += _chunk) {
        final end = (o + _chunk).clamp(0, bytes.length);
        try {
          await UniversalBle.write(deviceId, bleService, bleRx, bytes.sublist(o, end), withoutResponse: true);
        } catch (_) {
          return;
        }
      }
    });
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    try {
      await UniversalBle.disconnect(deviceId);
    } catch (_) {}
    await _in.close();
  }
}

/// Scans for devices advertising the KoebeltLink service.
class BleDiscovery {
  StreamSubscription<BleDevice>? _sub;

  Future<void> start(void Function(Found) onFound) async {
    try {
      if (await UniversalBle.getBluetoothAvailabilityState() != AvailabilityState.poweredOn) return;
      _sub = UniversalBle.scanStream.listen((d) {
        final name = d.name ?? d.rawName;
        if (name == null || name.isEmpty) return;
        onFound(
          Found(
            id: 'ble:${d.deviceId}',
            name: name,
            kind: 'generic',
            transport: 'ble',
            address: d.deviceId,
            via: 'BLE · ${d.rssi == null ? '' : '−${d.rssi!.abs()} dBm'}',
          ),
        );
      });
      await UniversalBle.startScan(scanFilter: ScanFilter(withServices: [bleService]));
    } catch (_) {
      // Bluetooth off, no permission or unsupported platform.
    }
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    try {
      await UniversalBle.stopScan();
    } catch (_) {}
  }
}
