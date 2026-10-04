import 'protocol.dart';

/// A device seen on the network or over BLE, before pairing.
class Found {
  Found({
    required this.id,
    required this.name,
    required this.kind,
    required this.transport,
    required this.address,
    required this.via,
    this.pair,
    this.lib,
    this.model = '',
    this.sensors = const [],
    this.radio,
  });

  factory Found.fromAnnounce(Msg m, {required String transport, required String address, required String via}) => Found(
    id: '${m['id'] ?? address}',
    name: '${m['name'] ?? m['id'] ?? 'Device'}',
    kind: '${m['kind'] ?? 'generic'}',
    transport: transport,
    address: address,
    via: via,
    pair: m['pair'] as String?,
    lib: m['lib'] as String?,
    model: '${m['model'] ?? ''}',
    sensors: List<String>.from(m['sensors'] ?? const []),
  );

  final String id, name, kind, transport, address, via;
  final String? pair, lib;
  final String model;
  final List<String> sensors;

  /// Radio module id when [transport] is `radio`.
  String? radio;
}
