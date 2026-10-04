import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:universal_ble/universal_ble.dart';

import 'discovery.dart';
import 'protocol.dart';
import 'transport.dart';

/// A Bluetooth LE serial service: the KoebeltLink (Nordic UART) one, or a
/// third-party module's that passes bytes to a microcontroller's UART.
class BleProfile {
  const BleProfile(this.id, this.name, this.service, this.rx, this.tx, {this.module = false});
  final String id, name;

  /// GATT service, the characteristic the app writes, the one it subscribes to.
  final String service, rx, tx;

  /// A UART bridge module: 20-byte packets, paced to its serial speed, and a
  /// slower session (see [moduleLink]).
  final bool module;
}

String _u16(String short) => '0000$short-0000-1000-8000-00805f9b34fb';

final bleProfiles = [
  // Also Adafruit Bluefruit boards and UART Friend, and most "BLE UART" sketches.
  const BleProfile('koebelt', 'KoebeltLink', bleService, bleRx, bleTx),
  BleProfile('hm10', 'HM-10 module', _u16('ffe0'), _u16('ffe1'), _u16('ffe1'), module: true), // HM-10/19, AT-09, BT05, JDY-08/23, HC-08, CC41
  BleProfile('bluno', 'DFRobot Bluno', _u16('dfb0'), _u16('dfb1'), _u16('dfb1'), module: true),
  const BleProfile(
    'rn4870',
    'Microchip RN4870',
    '49535343-fe7d-4ae5-8fa9-9fafd205e455',
    '49535343-8841-43f4-a8d4-ecbe34729bb3',
    '49535343-1e4d-4bd9-ba61-23c647249616',
    module: true,
  ),
];

BleProfile bleProfile(String? id) => bleProfiles.firstWhere((p) => p.id == id, orElse: () => bleProfiles.first);

/// The profile a scanned device advertises (KoebeltLink when unsure).
BleProfile profileForServices(Iterable<String> services) {
  final adv = services.map((s) => s.toLowerCase()).toSet();
  return bleProfiles.firstWhere((p) => adv.contains(p.service), orElse: () => bleProfiles.first);
}

/// BLE transport over a serial-style service, newline-delimited JSON.
class BleTransport implements Transport {
  BleTransport(this.deviceId, {this.name, this.profile = const BleProfile('koebelt', 'KoebeltLink', bleService, bleRx, bleTx)});
  final String deviceId;
  final String? name;
  final BleProfile profile;
  final _in = StreamController<Msg>.broadcast();
  final _lines = LineDecoder();
  StreamSubscription<Uint8List>? _sub;
  int _chunk = 20;
  Future<void> _writing = Future.value();

  @override
  String get label => profile.module ? 'BLE · ${profile.name}' : 'BLE · ${name ?? deviceId}';

  @override
  Stream<Msg> get messages => _in.stream;

  @override
  Future<void> open() async {
    await UniversalBle.connect(deviceId, timeout: const Duration(seconds: 12));
    await UniversalBle.discoverServices(deviceId);
    if (!profile.module) {
      try {
        _chunk = (await UniversalBle.requestMtu(deviceId, 247)) - 3;
      } catch (_) {}
    }
    _sub = UniversalBle.characteristicValueStream(deviceId, profile.tx).listen((v) {
      for (final m in _lines.add(v)) {
        if (!_in.isClosed) _in.add(m);
      }
    });
    await UniversalBle.subscribeNotifications(deviceId, profile.service, profile.tx);
  }

  @override
  void send(Msg m) {
    final bytes = Uint8List.fromList(utf8.encode('${encodeMsg(m)}\n'));
    // Serialise writes so chunks of different messages never interleave.
    _writing = _writing.then((_) async {
      for (var o = 0; o < bytes.length; o += _chunk) {
        final end = (o + _chunk).clamp(0, bytes.length);
        try {
          await UniversalBle.write(deviceId, profile.service, profile.rx, bytes.sublist(o, end), withoutResponse: true);
          // Modules pass packets on to a UART at 9600 baud or so: about 20 ms
          // per 20-byte packet. Do not outrun them.
          if (profile.module) await Future<void>.delayed(const Duration(milliseconds: 25));
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

/// Scans for devices advertising the KoebeltLink service or a known module's.
class BleDiscovery {
  StreamSubscription<BleDevice>? _sub;

  Future<void> start(void Function(Found) onFound) async {
    try {
      if (await UniversalBle.getBluetoothAvailabilityState() != AvailabilityState.poweredOn) return;
      _sub = UniversalBle.scanStream.listen((d) {
        final p = profileForServices(d.services);
        final name = d.name ?? d.rawName ?? (p.module ? p.name : null);
        if (name == null || name.isEmpty) return;
        final rssi = d.rssi == null ? '' : ' · −${d.rssi!.abs()} dBm';
        onFound(
          Found(
            id: 'ble:${d.deviceId}',
            name: name,
            kind: 'generic',
            transport: 'ble',
            address: d.deviceId,
            via: p.module ? 'BLE · ${p.name}$rssi' : 'BLE$rssi',
            module: p.module ? p.id : null,
          ),
        );
      });
      await UniversalBle.startScan(scanFilter: ScanFilter(withServices: [for (final p in bleProfiles) p.service]));
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
