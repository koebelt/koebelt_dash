// Recognising boards: USB ids of popular flight controllers and
// microcontroller boards, and a probe that tells KoebeltLink, MAVLink and MSP
// apart by what the board answers.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'bytes.dart';
import 'mavlink.dart';
import 'mavlink_adapter.dart';
import 'msp.dart';
import 'protocol.dart';

/// What a USB id says about a board.
class Board {
  const Board(this.name, this.family, {this.probe = true});
  final String name;

  /// `fc` flight controller, `mcu` microcontroller board, `uart` a USB-serial
  /// chip on some board (ESP32 dev kits, Arduino clones, radios).
  final String family;

  /// Safe to open and send probe messages to. Off for radios and unknowns.
  final bool probe;
}

/// USB vendor id -> board, or (vendor, product) for shared vendor ids.
const _byVendor = <int, Board>{
  0x1209: Board('ArduPilot board', 'fc'), // pid.codes 0x5740/0x5741: ArduPilot ChibiOS
  0x2DAE: Board('CubePilot Cube', 'fc'),
  0x3162: Board('Holybro Pixhawk', 'fc'),
  0x26AC: Board('Pixhawk (PX4 / 3DR)', 'fc'),
  0x35A7: Board('ARK Electronics FC', 'fc'),
  0x3185: Board('Auterion Skynode', 'fc'),
  0x303A: Board('ESP32 (native USB)', 'mcu'),
  0x2E8A: Board('Raspberry Pi Pico', 'mcu'),
  0x16C0: Board('Teensy', 'mcu'),
  0x2341: Board('Arduino', 'mcu'),
  0x2A03: Board('Arduino', 'mcu'),
  0x239A: Board('Adafruit board', 'mcu'),
  0x1B4F: Board('SparkFun board', 'mcu'),
  0x2886: Board('Seeed XIAO', 'mcu'),
  0x10C4: Board('CP210x USB-UART', 'uart'),
  0x1A86: Board('CH34x USB-UART', 'uart'),
  0x0403: Board('FTDI USB-UART', 'uart'),
};

const _byProduct = <(int, int), Board>{
  (0x0483, 0x5740): Board('STM32 flight controller', 'fc'), // Betaflight, INAV, ArduPilot and PX4 on STM32 VCP
  (0x0483, 0xDF11): Board('STM32 in DFU mode', 'fc', probe: false),
  (0x1209, 0x5740): Board('ArduPilot board', 'fc'),
  (0x1209, 0x5741): Board('ArduPilot board (bootloader)', 'fc', probe: false),
  (0x2341, 0x1002): Board('Arduino UNO R4', 'mcu'),
  (0x2341, 0x8057): Board('Arduino Nano 33 IoT', 'mcu'),
  (0x2341, 0x805A): Board('Arduino Nano 33 BLE', 'mcu'),
  (0x2341, 0x0070): Board('Arduino Nano ESP32', 'mcu'),
  (0x2341, 0x005E): Board('Arduino Nano RP2040 Connect', 'mcu'),
  (0x2E8A, 0xF00A): Board('Raspberry Pi Pico W', 'mcu'),
  (0x0403, 0x6015): Board('FTDI USB-UART (SiK radio?)', 'uart', probe: false),
};

Board? boardFor(int? vid, int? pid) {
  if (vid == null) return null;
  return _byProduct[(vid, pid ?? -1)] ?? _byVendor[vid];
}

/// What a probe found on a port.
class ProbeResult {
  ProbeResult(this.proto, {required this.name, required this.kind, this.model = '', this.id, this.pair, this.lib});

  /// `koebelt`, `mavlink` or `msp`.
  final String proto;
  final String name, kind, model;
  final String? id, pair, lib;
}

/// Watches a byte stream and decides which protocol the board speaks.
class ProtocolSniffer {
  final _mav = MavParser();
  final _msp = MspParser();
  final List<int> _line = [];
  String? _variant, _mspName;
  bool _msp0 = false;

  /// Feeds bytes; returns a result once something is recognised.
  ProbeResult? add(List<int> bytes) {
    for (final m in _mav.add(bytes)) {
      if (m.id != Mav.heartbeat) continue;
      final t = m.n('type').toInt(), ap = m.n('autopilot').toInt();
      if (ap == Mav.invalid || Mav.nonVehicleTypes.contains(t)) continue;
      final firmware = ap == Mav.px4 ? 'PX4' : (ap == Mav.ardupilot ? 'ArduPilot' : 'MAVLink');
      return ProbeResult('mavlink', name: mavVehicleName(ap, t), kind: mavKind(t), model: '$firmware · system ${m.sys}', id: 'mav-${m.sys}');
    }
    for (final r in _msp.add(bytes)) {
      _msp0 = true;
      if (r.cmd == Msp.fcVariant && r.data.length >= 4) _variant = ascii.decode(r.data.sublist(0, 4), allowInvalid: true);
      if (r.cmd == Msp.name) _mspName = ascii.decode(r.data, allowInvalid: true).trim();
    }
    for (final b in bytes) {
      if (b == 10) {
        final m = decodeMsg(utf8.decode(_line, allowMalformed: true));
        _line.clear();
        if (m != null && (m['t'] == 'announce' || m['t'] == 'hello')) {
          return ProbeResult(
            'koebelt',
            name: '${m['name'] ?? m['id'] ?? 'Device'}',
            kind: '${m['kind'] ?? 'generic'}',
            model: '${m['model'] ?? ''}',
            id: m['id'] as String?,
            pair: m['pair'] as String?,
            lib: m['lib'] as String?,
          );
        }
      } else if (_line.length < 4096) {
        _line.add(b);
      } else {
        _line.clear();
      }
    }
    return null;
  }

  /// MSP needs a second round trip for the name; call when the probe ends.
  ProbeResult? get mspResult {
    if (!_msp0) return null;
    final fw = switch (_variant) {
      'BTFL' => 'Betaflight',
      'INAV' => 'INAV',
      'EMUF' => 'EmuFlight',
      null => 'MSP',
      final v => v,
    };
    return ProbeResult('msp', name: (_mspName?.isNotEmpty ?? false) ? _mspName! : '$fw flight controller', kind: 'drone', model: fw);
  }
}

/// Bytes that make each protocol answer: a ground-station heartbeat (PX4
/// only starts MAVLink on USB once it hears one), MSP identity requests and
/// a KoebeltLink discover.
List<Uint8List> probeRequests() => [
  MavEncoder().encode(Mav.heartbeat, {'type': 6, 'autopilot': Mav.invalid, 'system_status': 4, 'mavlink_version': 3}),
  mspFrame(Msp.apiVersion),
  mspFrame(Msp.fcVariant),
  mspFrame(Msp.name),
  Uint8List.fromList(utf8.encode('\n${encodeMsg({'t': 'discover', 'v': protocolVersion})}\n')),
];

/// Opens [link], asks, listens, and reports what the board is.
Future<ProbeResult?> probeLink(ByteLink link, {Duration listen = const Duration(milliseconds: 2500)}) async {
  final sniff = ProtocolSniffer();
  final done = Completer<ProbeResult?>();
  StreamSubscription? sub;
  try {
    await link.open();
    sub = link.bytes.listen((b) {
      final r = sniff.add(b);
      if (r != null && !done.isCompleted) done.complete(r);
    });
    for (final r in probeRequests()) {
      link.write(r);
    }
    // Ask again halfway: boards that reset when the port opens (ESP32 dev
    // kits, Arduino) take a moment to boot.
    final again = Timer(listen ~/ 2, () {
      for (final r in probeRequests()) {
        link.write(r);
      }
    });
    // MAVLink and KoebeltLink answer with a complete identity; MSP boards
    // are reported when listening ends, with whatever name they gave.
    final r = await done.future.timeout(listen, onTimeout: () => sniff.mspResult);
    again.cancel();
    return r;
  } catch (_) {
    return null;
  } finally {
    await sub?.cancel();
    await link.close();
  }
}
