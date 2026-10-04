// Video, radio links and game controllers.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:koebelt_dash/core/dash.dart';
import 'package:koebelt_dash/core/gamepad.dart';
import 'package:koebelt_dash/core/model.dart';
import 'package:koebelt_dash/link/protocol.dart';
import 'package:koebelt_dash/link/radio.dart';
import 'package:koebelt_dash/link/session.dart';
import 'package:koebelt_dash/link/transport.dart';
import 'package:koebelt_dash/sim/sim_device.dart';
import 'package:koebelt_dash/video/mjpeg.dart';
import 'package:koebelt_dash/video/video_hub.dart';
import 'package:shared_preferences/shared_preferences.dart';

Uint8List part(List<int> body, {bool length = true}) => Uint8List.fromList([
  ...ascii.encode('--frame\r\nContent-Type: image/jpeg\r\n${length ? 'Content-Length: ${body.length}\r\n' : ''}\r\n'),
  ...body,
  ...ascii.encode('\r\n'),
]);

class _Target implements PadTarget {
  final axes = <List<double>>[];
  final actions = <PadAction>[];
  @override
  void padAxes(List<double> v) => axes.add(List.of(v));
  @override
  void padAction(PadAction a) => actions.add(a);
}

Future<void> wait(int ms) => Future<void>.delayed(Duration(milliseconds: ms));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // The simulator's camera is a real HTTP server; tests block HTTP by default.
  setUpAll(() => HttpOverrides.global = null);

  group('MJPEG', () {
    final a = [0xFF, 0xD8, 1, 2, 3, 0xFF, 0xD9], b = [0xFF, 0xD8, 9, 9, 0xFF, 0xD9];

    test('splits parts with Content-Length, fed byte by byte', () {
      final p = MjpegParser('frame');
      final bytes = [...part(a), ...part(b)];
      final out = <Uint8List>[];
      for (final x in bytes) {
        out.addAll(p.add([x]));
      }
      expect(out.map((f) => f.toList()), [a, b]);
    });

    test('falls back to the boundary when parts have no length', () {
      final p = MjpegParser('--frame');
      final out = [
        ...p.add([...part(a, length: false), ...part(b, length: false)]),
        ...p.add(ascii.encode('--frame\r\n')),
      ];
      expect(out.map((f) => f.toList()), [a, b]);
    });

    test('boundary from the content type', () {
      expect(boundaryOf('multipart/x-mixed-replace; boundary=123456789000000000000987654321'), '123456789000000000000987654321');
      expect(boundaryOf('multipart/x-mixed-replace;boundary="frame"'), 'frame');
      expect(boundaryOf('image/jpeg'), isNull);
    });

    test('stream URLs resolve against the Wi-Fi address only', () {
      final wifi = DeviceInfo(id: 'a', name: 'A', kind: DeviceKind.drone, transport: TransportKind.udp, address: '10.0.4.22');
      final radio = DeviceInfo(id: 'b', name: 'B', kind: DeviceKind.drone, transport: TransportKind.radio, address: '/dev/ttyUSB0');
      expect(resolveVideoUrl(':81/stream', wifi).toString(), 'http://10.0.4.22:81/stream');
      expect(resolveVideoUrl(':81/stream', radio), isNull);
      expect(resolveVideoUrl('http://cam.local/stream', radio).toString(), 'http://cam.local/stream');
    });

    test('simulated camera streams decodable frames to the real client', () async {
      final sim = SimDevice(DeviceInfo(id: 'k', name: 'Kite', kind: DeviceKind.drone));
      final lt = LoopbackTransport('t');
      sim.attach(lt);
      await wait(200);
      final s = DeviceSession(lt, onMessage: (_) {});
      final hello = await s.open();
      final video = (hello['video'] as List).cast<Map>();
      expect(video.single['fmt'], 'mjpeg');
      final c = MjpegClient(Uri.parse(video.single['url']));
      final frames = <Uint8List>[];
      final sub = c.frames.listen(frames.add);
      c.start();
      for (var i = 0; i < 50 && frames.length < 3; i++) {
        await wait(100);
      }
      expect(frames.length, greaterThanOrEqualTo(3));
      final codec = await ui.instantiateImageCodec(frames.last);
      final img = (await codec.getNextFrame()).image;
      expect([img.width, img.height], [480, 270]);
      await sub.cancel();
      await c.close();
      await s.close();
      sim.detach();
    });
  });

  group('radio links', () {
    test('profiles match protocol/vectors.json', () {
      final v = jsonDecode(File('../../protocol/vectors.json').readAsStringSync())['radio'] as List;
      expect(radioModules.map((m) => m.id), [for (final r in v) r['id']]);
      for (final r in v) {
        final m = radioModule(r['id']);
        expect([m.baud, m.tlmHz, m.ctlHz], [r['baud'], r['tlm_hz'], r['ctl_hz']], reason: m.id);
      }
      expect(radioForUsb('RFD900x')?.id, 'sik');
      expect(radioForUsb('CP2102 USB to UART Bridge Controller'), isNull);
    });

    Future<int> ctlCount(int hz) async {
      final lt = LoopbackTransport('t');
      final ctl = <Msg>[];
      lt.deviceInbox.listen((m) {
        if (m['t'] == 'hello') lt.deviceSend({'t': 'hello', 'v': 1, 'id': 'r', 'ok': true});
        if (m['t'] == 'ctl') ctl.add(m);
      });
      final s = DeviceSession(lt, onMessage: (_) {}, ctlHz: hz);
      await s.open();
      await wait(1000);
      await s.close();
      return ctl.length;
    }

    test('heartbeat follows the radio profile; telemetry-only sends none', () async {
      expect(await ctlCount(0), 0);
      final n = await ctlCount(radioModule('sik').ctlHz);
      expect(n, inInclusiveRange(7, 12));
    });
  });

  group('game controller', () {
    test('standard sticks map to the four axes with dead zone and expo', () {
      final t = _Target(), cfg = PadConfig(), m = PadMapper(cfg, t);
      m.input('n:leftStickY', 1);
      expect(t.axes.last, [0, 1, 0, 0]);
      m.input('n:rightStickX', .05); // inside the 8 % dead zone
      expect(t.axes.last[2], 0);
      m.input('n:rightStickX', .5);
      expect(t.axes.last[2], allOf(greaterThan(0), lessThan(.5)), reason: 'expo softens the middle');
      m.input('n:leftStickY', 0);
      m.input('n:rightStickX', 0);
      expect(t.axes.last, [0, 0, 0, 0], reason: 'one zero when released');
      final n = t.axes.length;
      m.input('n:leftStickX', .01);
      expect(t.axes.length, n, reason: 'idle controller does not overwrite on-screen sticks');
    });

    test('STOP fires at once, arm needs a one-second hold', () async {
      final t = _Target(), m = PadMapper(PadConfig(), t);
      m.input('n:b', 1, button: true);
      expect(t.actions, [PadAction.stop]);
      m.input('n:b', 0, button: true);
      m.input('n:start', 1, button: true);
      m.tick();
      expect(t.actions, [PadAction.stop]);
      await wait(1050);
      m.tick();
      m.tick();
      expect(t.actions, [PadAction.stop, PadAction.arm]);
    });

    test('learning prefers the normalised name and learns direction', () async {
      final t = _Target(), cfg = PadConfig(), m = PadMapper(cfg, t);
      m.startLearning('axis:1');
      // Raw arrives first, then the normalised event for the same stick.
      m.input('r:AXIS_Y', 0);
      m.input('r:AXIS_Y', -1);
      m.input('n:leftStickY', 1);
      await wait(80);
      expect(cfg.axes[1].src, 'n:leftStickY');
      expect(cfg.axes[1].invert, isFalse);
    });

    test('RC transmitter: raw 0…65535 axis is calibrated and inverted by learning', () async {
      final t = _Target(), cfg = PadConfig(), m = PadMapper(cfg, t);
      m.startLearning('axis:3');
      m.input('r:Y', 32768);
      m.input('r:Y', 0); // pushed forward reads low on this transmitter
      await wait(80);
      expect(cfg.axes[3].src, 'r:Y');
      expect(cfg.axes[3].invert, isTrue);
      m.input('r:Y', 65535);
      m.input('r:Y', 0);
      expect(t.axes.last[3], closeTo(1, .01));
      m.input('r:Y', 32768);
      expect(t.axes.last[3], 0);
    });

    test('drives an armed simulated drone; STOP stops it', () async {
      SharedPreferences.setMockInitialValues({});
      final d = Dash();
      await d.init();
      final dev = d.addSimulated(simTemplates().first);
      await d.connect(dev.id);
      expect(d.session, isNotNull);
      await wait(300);
      final why = 'armed ${d.liveTel.armed} estop ${d.liveTel.estop} lost ${d.linkLost} silence ${d.session?.silence} ctl ${d.canControl}';
      d.padMapper.input('n:leftStickY', 1);
      expect(d.input[1], 1, reason: why);
      expect(d.liveTel.mode, 'MANUAL');
      d.padMapper.input('n:leftStickY', 0);
      d.padMapper.input('n:b', 1, button: true);
      expect(d.liveTel.estop, isTrue);
      d.padMapper.input('n:leftStickY', 1);
      expect(d.input[1], 0, reason: 'no drive after STOP');
      await d.disconnect();
      d.dispose();
    });
  });
}
