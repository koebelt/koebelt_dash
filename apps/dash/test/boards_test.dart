// Boards with their own firmware: MSP (Betaflight / INAV), Tello, USB board
// recognition and protocol sniffing.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:koebelt_dash/core/model.dart';
import 'package:koebelt_dash/core/telemetry.dart';
import 'package:koebelt_dash/core/dash.dart';
import 'package:koebelt_dash/link/ble_transport.dart';
import 'package:koebelt_dash/link/board_discovery.dart';
import 'package:koebelt_dash/link/boards.dart';
import 'package:koebelt_dash/link/bytes.dart';
import 'package:koebelt_dash/link/discovery.dart';
import 'package:koebelt_dash/link/mavlink.dart';
import 'package:koebelt_dash/link/msp.dart';
import 'package:koebelt_dash/link/protocol.dart';
import 'package:koebelt_dash/link/session.dart';
import 'package:koebelt_dash/link/tello.dart';

Future<void> wait(int ms) => Future<void>.delayed(Duration(milliseconds: ms));

/// `$M>` reply as a Betaflight board sends it.
List<int> reply(int cmd, List<int> data) {
  var ck = data.length ^ cmd;
  for (final b in data) {
    ck ^= b;
  }
  return [0x24, 0x4D, 0x3E, data.length, cmd, ...data, ck & 0xFF];
}

List<int> le16(int v) => [v & 0xFF, (v >> 8) & 0xFF];
List<int> le32(int v) => [v & 0xFF, (v >> 8) & 0xFF, (v >> 16) & 0xFF, (v >> 24) & 0xFF];

/// A Betaflight 4.5 board answering the requests the adapter makes.
class FakeBetaflight {
  FakeBetaflight(this.link) {
    link.bytes.listen((b) {
      for (final r in _requests(b)) {
        _answer(r.$1, r.$2);
      }
    });
  }
  final MemoryByteLink link;
  final pid = <int>[45, 80, 40, 47, 84, 46, 45, 80, 0, 50, 50, 75, 40, 0, 0];
  bool armed = true, armingDisabled = false, saved = false;

  Iterable<(int, List<int>)> _requests(List<int> b) sync* {
    var i = 0;
    while (i + 5 < b.length) {
      if (b[i] == 0x24 && b[i + 1] == 0x4D && b[i + 2] == 0x3C) {
        final len = b[i + 3];
        yield (b[i + 4], b.sublist(i + 5, i + 5 + len));
        i += 6 + len;
      } else {
        i++;
      }
    }
  }

  void _answer(int cmd, List<int> data) {
    final out = switch (cmd) {
      Msp.apiVersion => [0, 1, 46],
      Msp.fcVariant => ascii.encode('BTFL'),
      Msp.fcVersion => [4, 5, 1],
      Msp.boardInfo => [...ascii.encode('S7X2'), 0, 0],
      Msp.name => ascii.encode('Racer 5'),
      Msp.status => [...le16(125), ...le16(0), ...le16(0x23), ...le32(armed ? 1 : 0), 0],
      Msp.attitude => [...le16(-52), ...le16(31), ...le16(270)],
      Msp.altitude => [...le32(1234), ...le16(-20)],
      Msp.analog => [168, ...le16(300), ...le16(900), ...le16(1250), ...le16(1680)],
      Msp.batteryState => [4, ...le16(1500), 168, ...le16(300), ...le16(1250), 0, ...le16(1680)],
      Msp.rawImu => [...le16(10), ...le16(-20), ...le16(512), ...le16(41), ...le16(0), ...le16(-41), 0, 0, 0, 0, 0, 0],
      Msp.rawGps => [2, 11, ...le32(473769000), ...le32(85417000), ...le16(410), ...le16(0), ...le16(0)],
      Msp.pid => pid,
      Msp.setPid => () {
        pid.setAll(0, data);
        return <int>[];
      }(),
      Msp.eepromWrite => () {
        saved = true;
        return <int>[];
      }(),
      Msp.setArmingDisabled => () {
        armingDisabled = data.first == 1;
        if (armingDisabled) armed = false;
        return <int>[];
      }(),
      _ => null,
    };
    if (out != null) link.write(reply(cmd, out));
  }
}

void main() {
  test('MSP parser checks the XOR checksum and skips noise', () {
    final p = MspParser();
    final ok = reply(Msp.attitude, [1, 2, 3, 4, 5, 6]);
    final bad = List.of(ok)..[ok.length - 1] ^= 0xFF;
    final got = [
      for (final b in [0x00, 0x24, ...bad, ...ok]) ...p.add([b]),
    ];
    expect(got.map((r) => r.cmd), [Msp.attitude]);
    expect(mspFrame(Msp.status), [0x24, 0x4D, 0x3C, 0, 101, 101]);
  });

  test('Betaflight over MSP: identity, telemetry, PID tuning, save, STOP', () async {
    final (app, fc) = MemoryByteLink.pair('USB');
    final board = FakeBetaflight(fc);
    final got = <Msg>[];
    final tel = Telemetry(DeviceKind.drone);
    final s = DeviceSession(
      MspTransport(app, poll: const Duration(milliseconds: 50)),
      ctlHz: 0,
      onMessage: (m) {
        got.add(m);
        if (m['t'] == 'tlm') tel.applyTlm((m['d'] as Map).cast<String, dynamic>());
        if (m['t'] == 'state') tel.applyState(m);
      },
    );
    final hello = await s.open();
    expect(hello['name'], 'Racer 5');
    expect(hello['model'], 'Betaflight · 4.5.1 · S7X2');
    await wait(400);
    expect(tel.armed, isTrue);
    expect(tel.voltage, closeTo(16.8, .01));
    expect(tel.battery, closeTo(100, .1), reason: '4.2 V per cell on 4 cells');
    expect(tel.pos[2], closeTo(12.34, .01));
    expect(tel.lat, closeTo(47.3769, 1e-6));
    expect(tel.roll, closeTo(5.2 * 3.14159 / 180, .01), reason: 'Betaflight roll is right-down positive; the app is left-down');

    final params = parseParams(got.firstWhere((m) => m['t'] == 'params'), DeviceKind.drone);
    expect(params.map((g) => g.name), ['Roll', 'Pitch', 'Yaw']);
    expect(params.first.params.map((p) => p.def), [45, 80, 40]);

    s.send({
      't': 'pset',
      'p': {'PITCH_D': 52},
    });
    s.send({'t': 'psave'});
    await wait(100);
    expect(board.pid[5], 52);
    expect(board.saved, isTrue);
    expect(got.any((m) => m['t'] == 'pack'), isTrue);

    s.sendStop();
    await wait(300);
    expect(board.armingDisabled, isTrue);
    expect(tel.armed, isFalse);
    expect(tel.estop, isTrue);
    await s.close();
  });

  test('Tello: SDK mode, state lines, rc sticks, take-off, emergency', () async {
    final drone = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
    final probe = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
    final statePort = probe.port;
    probe.close();
    final cmds = <String>[];
    InternetAddress? app;
    int? appPort;
    drone.listen((e) {
      final d = drone.receive();
      if (d == null) return;
      final c = utf8.decode(d.data);
      cmds.add(c);
      app = d.address;
      appPort = d.port;
      if (!c.startsWith('rc ')) drone.send(utf8.encode('ok'), d.address, d.port);
    });
    var h = 0;
    final states = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (app == null) return;
      final line =
          'pitch:2;roll:-3;yaw:90;vgx:10;vgy:0;vgz:0;templ:60;temph:62;tof:${h + 10};h:$h;bat:87;baro:120.5;time:3;agx:-5.00;agy:2.00;agz:-998.00;\r\n';
      drone.send(utf8.encode(line), InternetAddress.loopbackIPv4, statePort);
    });
    addTearDown(() {
      states.cancel();
      drone.close();
    });

    final got = <Msg>[];
    final tel = Telemetry(DeviceKind.drone);
    final s = DeviceSession(
      TelloTransport(host: '127.0.0.1', cmdPort: drone.port, statePort: statePort),
      onMessage: (m) {
        got.add(m);
        if (m['t'] == 'tlm') tel.applyTlm((m['d'] as Map).cast<String, dynamic>());
        if (m['t'] == 'state') tel.applyState(m);
        if (m['t'] == 'chan') {}
      },
    );
    var ctl = [0.0, 0.0, 0.0, 0.0];
    s.axes = () => ctl;
    final hello = await s.open();
    expect(hello['name'], 'Tello');
    expect(cmds.first, 'command');
    await wait(300);
    expect(tel.battery, 87);
    expect(tel.custom['tof'], isNotEmpty);

    s.send({'t': 'arm', 'v': true});
    s.send({'t': 'mode', 'm': 'TAKEOFF'});
    await wait(100);
    expect(cmds, contains('takeoff'));
    h = 120;
    await wait(300);
    expect(tel.pos[2], closeTo(1.2, .01));
    s.send({'t': 'mode', 'm': 'MANUAL'});
    ctl = [.5, 0, 0, 1];
    await wait(200);
    expect(cmds.where((c) => c.startsWith('rc ')).last, 'rc 0 100 0 50');
    s.sendStop();
    await wait(150);
    expect(cmds, contains('emergency'));
    expect(appPort, isNotNull);
    await s.close();
  });

  test('USB ids name the board and say whether it is safe to probe', () {
    expect(boardFor(0x0483, 0x5740)?.name, 'STM32 flight controller');
    expect(boardFor(0x2DAE, 0x1016)?.family, 'fc');
    expect(boardFor(0x303A, 0x1001)?.name, 'ESP32 (native USB)');
    expect(boardFor(0x0403, 0x6015)?.probe, isFalse, reason: 'SiK radios: listen only');
    expect(boardFor(0x1234, 0x5678), isNull);
  });

  test('the sniffer tells koebelt/link, MAVLink and MSP apart', () {
    final hb = MavEncoder(sys: 1, comp: 1).encode(Mav.heartbeat, {'type': 2, 'autopilot': 12, 'base_mode': 81, 'system_status': 4, 'mavlink_version': 3});
    expect(ProtocolSniffer().add(hb)?.name, 'PX4 copter');
    final announce = utf8.encode('${encodeMsg({'t': 'announce', 'id': 'mule', 'name': 'Mule', 'kind': 'rover', 'pair': 'ABC-DEF'})}\n');
    final k = ProtocolSniffer().add([...utf8.encode('boot noise\r\n'), ...announce]);
    expect([k?.proto, k?.name, k?.pair], ['koebelt', 'Mule', 'ABC-DEF']);
    final m = ProtocolSniffer();
    expect(m.add([...reply(Msp.fcVariant, ascii.encode('INAV')), ...reply(Msp.name, ascii.encode('Wing'))]), isNull);
    expect([m.mspResult?.proto, m.mspResult?.name, m.mspResult?.model], ['msp', 'Wing', 'INAV']);
  });

  test('a probe over a byte link identifies a board that answers', () async {
    final (app, board) = MemoryByteLink.pair();
    board.bytes.listen((b) {
      // A koebelt/link board answers discover with announce.
      if (utf8.decode(b, allowMalformed: true).contains('"discover"')) {
        board.write(utf8.encode('${encodeMsg({'t': 'announce', 'id': 'kite', 'name': 'Kite', 'kind': 'drone'})}\n'));
      }
    });
    final r = await probeLink(app, listen: const Duration(milliseconds: 500));
    expect([r?.proto, r?.name, r?.kind], ['koebelt', 'Kite', 'drone']);
  });

  test('MAVLink vehicles on UDP are discovered from their heartbeat', () async {
    final disc = MavlinkUdpDiscovery(port: 14591);
    final found = <Found>[];
    await disc.start(found.add);
    final v = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
    v.send(MavEncoder(sys: 3, comp: 1).encode(Mav.heartbeat, {'type': 10, 'autopilot': 3, 'mavlink_version': 3}), InternetAddress.loopbackIPv4, 14591);
    await wait(100);
    final vport = v.port;
    disc.stop();
    v.close();
    expect(found.single.name, 'ArduRover');
    expect(found.single.proto, 'mavlink');
    expect(found.single.address, '127.0.0.1:$vport');
    expect(found.single.kind, 'rover');
  });

  test('ground-station heartbeats are ignored', () {
    final gcs = MavEncoder().encode(Mav.heartbeat, {'type': 6, 'autopilot': 8, 'mavlink_version': 3});
    expect(ProtocolSniffer().add(gcs), isNull);
    expect(Uint8List.fromList(gcs).first, 0xFD);
  });

  test('third-party Bluetooth modules: profile from the advertised service, slow link rates', () {
    expect(profileForServices(['0000FFE0-0000-1000-8000-00805F9B34FB']).id, 'hm10');
    expect(profileForServices(['0000dfb0-0000-1000-8000-00805f9b34fb']).id, 'bluno');
    expect(profileForServices(['49535343-fe7d-4ae5-8fa9-9fafd205e455']).id, 'rn4870');
    expect(profileForServices([bleService]).id, 'koebelt');
    expect(profileForServices(const []).id, 'koebelt');
    final hm = bleProfile('hm10');
    expect(
      [hm.service, hm.rx, hm.tx],
      ['0000ffe0-0000-1000-8000-00805f9b34fb', '0000ffe1-0000-1000-8000-00805f9b34fb', '0000ffe1-0000-1000-8000-00805f9b34fb'],
    );
    expect(hm.module, isTrue);

    final module = DeviceInfo(id: 'ble:x', name: 'BT05', kind: DeviceKind.rover, transport: TransportKind.ble, module: 'hm10');
    final hc05 = DeviceInfo(id: 'bt:x', name: 'HC-05', kind: DeviceKind.rover, transport: TransportKind.serial, module: 'btserial');
    final wifi = DeviceInfo(id: 'udp:x', name: 'Kite', kind: DeviceKind.drone, transport: TransportKind.udp);
    expect(Dash.linkRates(module), (ctlHz: 5, tlmHz: 5));
    expect(Dash.linkRates(hc05), (ctlHz: 5, tlmHz: 5));
    expect(Dash.linkRates(wifi), isNull);
    // Saved and restored with the device.
    expect(DeviceInfo.fromJson(module.toJson()).module, 'hm10');
  });
}
