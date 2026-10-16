import 'dart:math' as math;

enum DeviceKind {
  drone('Drone'),
  rover('Ground robot'),
  arm('Robot arm'),
  rocket('Rocket'),
  bench('Test bench'),
  generic('Device');

  const DeviceKind(this.label);
  final String label;

  static DeviceKind parse(String? s) => DeviceKind.values.firstWhere((k) => k.name == s, orElse: () => DeviceKind.generic);
}

/// How the app reaches a device. `radio` is a serial port with a radio
/// modem behind it (see link/radio.dart).
enum TransportKind {
  sim('Simulator'),
  udp('Wi-Fi'),
  ble('Bluetooth'),
  serial('USB'),
  radio('Radio');

  const TransportKind(this.label);
  final String label;
}

/// A camera stream the device declared in `hello`.
class VideoStream {
  const VideoStream(this.id, this.url, this.fmt, {this.label = ''});
  final String id, url, fmt, label;

  factory VideoStream.fromJson(Map j) => VideoStream('${j['id'] ?? 'cam'}', '${j['url'] ?? ''}', '${j['fmt'] ?? 'mjpeg'}', label: '${j['label'] ?? ''}');
}

class DeviceInfo {
  DeviceInfo({
    required this.id,
    required this.name,
    required this.kind,
    this.model = '',
    this.online = true,
    this.battery = 100,
    this.sensors = const [],
    this.transport = TransportKind.sim,
    this.address = '',
    this.key,
    this.via = '',
    this.lastSeen,
    this.radio,
    this.baud,
    this.proto = 'koebelt',
    this.module,
    this.lib,
    this.protocol,
  });

  final String id;
  String name;
  DeviceKind kind;
  String model;
  bool online;
  int battery;
  List<String> sensors;
  TransportKind transport;

  /// ip:port for UDP, remote id for BLE, port path for serial and radio, sim id for sim.
  String address;

  /// Pairing key (32 hex chars). Null for open-mode devices.
  String? key;

  /// Human description of how it was found ("BLE · −61 dBm").
  String via;
  DateTime? lastSeen;

  /// Radio module id for [TransportKind.radio] (`sik`, `lora`…).
  String? radio;

  /// Serial speed override for serial and radio links.
  int? baud;

  /// What the device speaks: `koebelt` (the library), `mavlink` (ArduPilot,
  /// PX4), `msp` (Betaflight, INAV) or `tello`.
  String proto;

  /// Third-party serial module in between: a BLE profile (`hm10`, `bluno`,
  /// `rn4870`) or `btserial` (Bluetooth Classic, HC-05/HC-06). These links
  /// are slow, so sessions run at module rates.
  String? module;

  /// The koebelt/link library ("arduino/1.4.2") and protocol version the
  /// device reported when it last connected: what an app update is checked
  /// against (core/compat.dart).
  String? lib;
  int? protocol;

  bool get simulated => transport == TransportKind.sim;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'kind': kind.name,
    'model': model,
    'battery': battery,
    'sensors': sensors,
    'transport': transport.name,
    'address': address,
    'key': key,
    'via': via,
    'radio': ?radio,
    'baud': ?baud,
    if (proto != 'koebelt') 'proto': proto,
    'module': ?module,
    'lib': ?lib,
    'protocol': ?protocol,
  };

  factory DeviceInfo.fromJson(Map<String, dynamic> j) => DeviceInfo(
    id: j['id'],
    name: j['name'],
    kind: DeviceKind.parse(j['kind']),
    model: j['model'] ?? '',
    battery: (j['battery'] ?? 100) as int,
    sensors: List<String>.from(j['sensors'] ?? const []),
    transport: TransportKind.values.firstWhere((t) => t.name == j['transport'], orElse: () => TransportKind.udp),
    address: j['address'] ?? '',
    key: j['key'],
    via: j['via'] ?? '',
    radio: j['radio'] as String?,
    baud: j['baud'] as int?,
    proto: j['proto'] as String? ?? 'koebelt',
    module: j['module'] as String?,
    lib: j['lib'] as String?,
    protocol: (j['protocol'] as num?)?.toInt(),
    online: true, // reachability is only known when connecting
  );
}

/// A radar / safety-scanner track. [a] is bearing in rad, [r] range in m.
class Track {
  Track(this.id, this.r, this.a);
  final String id;
  double r, a;
}

/// Declared custom channel (`chan` message).
class ChannelDef {
  ChannelDef(this.id, this.axes, this.unit, this.hz);
  final String id;
  final List<String> axes;
  final String unit;
  final double hz;
}

/// One parameter as the device reported it.
class ParamDef {
  ParamDef(this.key, this.label, this.def, this.min, this.max, this.step, this.unit);
  final String key, label, unit;
  final double def, min, max, step;
}

class ParamGroup {
  ParamGroup(this.cat, this.name, this.params, [this.chart]);
  final String cat, name;
  final List<ParamDef> params;
  final List<String>? chart;
}

/// Fixed-length ring buffer of samples (null = no data yet).
class Series {
  Series([this.n = 300]) : data = List<double?>.filled(n, null);
  final int n;
  List<double?> data;
  int _head = 0;

  void push(double? v) {
    data[_head] = v;
    _head = (_head + 1) % n;
  }

  /// Oldest to newest.
  Iterable<double?> get ordered sync* {
    for (var i = 0; i < n; i++) {
      yield data[(_head + i) % n];
    }
  }

  List<double?> toList() => ordered.toList();

  double? get last => data[(_head - 1 + n) % n];

  void clear() {
    data = List<double?>.filled(n, null);
    _head = 0;
  }
}

/// Six-axis arm forward kinematics used to draw arms (same link lengths as the design sim).
List<List<double>> armFk(List<double> j) {
  const l = [0.45, 0.9, 0.8, 0.18, 0.14];
  final c = math.cos(j[0]), s = math.sin(j[0]);
  final p0 = [0.0, 0.0, 0.0], p1 = [0.0, 0.0, l[0]];
  var a = j[1] + math.pi / 2;
  final r2 = math.cos(a) * l[1], z2 = math.sin(a) * l[1];
  final p2 = [c * r2, s * r2, l[0] + z2];
  a += -j[2];
  final r3 = r2 + math.cos(a) * l[2], z3 = z2 + math.sin(a) * l[2];
  final p3 = [c * r3, s * r3, l[0] + z3];
  a += -j[4];
  final r4 = r3 + math.cos(a) * l[3], z4 = z3 + math.sin(a) * l[3];
  final p4 = [c * r4, s * r4, l[0] + z4];
  final r5 = r4 + math.cos(a) * l[4], z5 = z4 + math.sin(a) * l[4];
  final p5 = [c * r5, s * r5, l[0] + z5];
  return [p0, p1, p2, p3, p4, p5];
}

double hypot2(double a, double b) => math.sqrt(a * a + b * b);
double hypot3(double a, double b, double c) => math.sqrt(a * a + b * b + c * c);
