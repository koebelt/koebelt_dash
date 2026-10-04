/// Radio links: a radio modem on a serial port of the computer or phone,
/// talking to a matching radio on the device. To the app every one of them
/// is newline-delimited JSON on a serial port; the profile only sets the
/// baud rate and how much traffic the air link can carry.
///
/// The same profiles exist in every library (see protocol/PROTOCOL.md,
/// "Radio links"), so both ends agree on rates without negotiating.
class RadioModule {
  const RadioModule(this.id, this.name, this.desc, {required this.baud, required this.tlmHz, required this.ctlHz, this.bridge = false, this.usb = const []});

  /// Stable id used in saved devices and by the libraries (`sik`, `lora`…).
  final String id;
  final String name, desc;

  /// Default serial speed between the app and the ground radio.
  final int baud;

  /// Telemetry rate the app asks for over this link.
  final int tlmHz;

  /// Control heartbeat rate. 0 = telemetry only: no sticks, no STOP.
  final int ctlHz;

  /// True when the ground side is a small board you flash yourself (the
  /// radio is not a USB serial device on its own).
  final bool bridge;

  /// Substrings of the USB product name that identify this radio.
  final List<String> usb;

  bool get telemetryOnly => ctlHz == 0;
}

const radioModules = [
  RadioModule(
    'sik',
    'SiK telemetry radio',
    '433 / 868 / 915 MHz pairs: 3DR, Holybro, RFD900. Transparent serial up to about 1 km, 40 km for RFD900.',
    baud: 57600,
    tlmHz: 5,
    ctlHz: 10,
    usb: ['SiK', 'RFD900', '3DR Radio', 'Holybro Telemetry'],
  ),
  RadioModule(
    'lora',
    'LoRa ground station',
    'A board with a LoRa radio on USB, flashed with the ground-station sketch. 2 to 10 km, telemetry only.',
    baud: 115200,
    tlmHz: 2,
    ctlHz: 0,
    bridge: true,
  ),
  RadioModule('hc12', 'HC-12 433 MHz', 'Cheap transparent serial module on a USB adapter. About 1 km at 9600 baud.', baud: 9600, tlmHz: 2, ctlHz: 5),
  RadioModule(
    'xbee',
    'XBee / DigiMesh',
    'Digi XBee in transparent mode on a USB explorer board. 2.4 GHz or 900 MHz.',
    baud: 57600,
    tlmHz: 5,
    ctlHz: 10,
    usb: ['XBee'],
  ),
  RadioModule(
    'other',
    'Other serial radio',
    'Any transparent serial radio. Set its baud rate; the app uses conservative rates.',
    baud: 57600,
    tlmHz: 2,
    ctlHz: 5,
  ),
];

RadioModule radioModule(String? id) => radioModules.firstWhere((m) => m.id == id, orElse: () => radioModules.last);

/// The radio a USB product name belongs to, if it is recognisable.
RadioModule? radioForUsb(String product) {
  final p = product.toLowerCase();
  for (final m in radioModules) {
    if (m.usb.any((u) => p.contains(u.toLowerCase()))) return m;
  }
  return null;
}
