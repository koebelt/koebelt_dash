// Smaller recordings (compact frames, gzip on disk) and camera video kept
// with recordings: the .kdv container, playback and the AVI export.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:koebelt_dash/core/dash.dart';
import 'package:koebelt_dash/core/model.dart';
import 'package:koebelt_dash/core/store.dart';
import 'package:koebelt_dash/core/telemetry.dart';
import 'package:koebelt_dash/sim/sim_device.dart';
import 'package:koebelt_dash/video/video_rec.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A JPEG header with a 640×480 start-of-frame, then filler.
Uint8List jpeg(int fill, {int w = 640, int h = 480}) => Uint8List.fromList([
  0xFF, 0xD8, 0xFF, 0xC0, 0x00, 0x11, 0x08, h >> 8, h & 255, w >> 8, w & 255, //
  ...List.filled(40 + fill, fill & 255), 0xFF, 0xD9,
]);

Future<void> wait(int ms) => Future<void>.delayed(Duration(milliseconds: ms));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => HttpOverrides.global = null); // the simulated camera is real HTTP
  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('kdash-rec'));
  tearDown(() => tmp.deleteSync(recursive: true));

  group('compact frames', () {
    test('only the channels the device sent, rounded', () {
      final drone = SimDevice.record(DeviceInfo(id: 'x', name: 'X', kind: DeviceKind.drone), 5);
      final arm = SimDevice.record(DeviceInfo(id: 'y', name: 'Y', kind: DeviceKind.arm), 5);
      expect(drone[20].containsKey('joints'), isFalse);
      expect(drone[20].containsKey('lat'), isTrue);
      expect(arm[20].containsKey('lat'), isFalse);
      expect(arm[20].containsKey('joints'), isTrue);
      final bytes = utf8.encode(jsonEncode(drone)).length / drone.length;
      expect(bytes, lessThan(400), reason: 'was about 820 bytes a frame');
      expect('${drone[20]['voltage']}'.length, lessThan(8), reason: 'rounded, not 17 digits');
    });

    test('old full frames still replay, new ones keep what they lack', () {
      final t = Telemetry(DeviceKind.arm)..joints = [1, 2, 3, 4, 5, 6];
      t.applyFrame({
        'pos': [1.0, 2.0, 3.0],
        'roll': .1,
        'pitch': 0,
        'yaw': 0,
        'mode': 'HOLD',
        'armed': false,
        'seen': ['pos'],
      });
      expect(t.pos, [1.0, 2.0, 3.0]);
      expect(t.joints, [1, 2, 3, 4, 5, 6]);
      final old = Telemetry(DeviceKind.drone).snapshot()
        ..addAll({
          'voltage': 15.2,
          'pyro': ['OK', 'OK', 'OK', '—'],
          'thr': 0.4,
        });
      t.applyFrame(old);
      expect(t.voltage, 15.2);
      expect(t.throttleOut, .4);
    });

    test('recordings are stored gzipped and load back', () async {
      SharedPreferences.setMockInitialValues({});
      final store = Store(recordingsRoot: tmp.path);
      await store.init();
      final frames = SimDevice.record(DeviceInfo(id: 'x', name: 'X', kind: DeviceKind.drone), 60);
      await store.saveRecording({'id': 'r1', 'frames': frames});
      final f = File('${tmp.path}/r1.json.gz');
      expect(f.existsSync(), isTrue);
      expect(f.lengthSync() / frames.length, lessThan(100), reason: 'bytes per frame on disk');
      final back = await store.loadRecordings();
      expect(back.single['frames'], hasLength(frames.length));
      await store.deleteRecording('r1');
      expect(f.existsSync(), isFalse);
    });
  });

  group('video', () {
    test('recorder caps the frame rate; the track finds frames by time', () async {
      var now = 0.0;
      final rec = VideoRecorder('${tmp.path}/v.kdv', clock: () => now, maxFps: 10);
      await rec.open();
      for (var i = 0; i < 60; i++) {
        now = i / 30; // a 30 fps camera
        rec.add(jpeg(i));
      }
      expect(await rec.close(), inInclusiveRange(19, 21), reason: '2 s at 10 fps');
      final t = (await VideoTrack.open('${tmp.path}/v.kdv'))!;
      expect(t.length, rec.frames);
      expect(t.frameAt(-1), 0);
      expect(t.times[t.frameAt(1.05)], lessThanOrEqualTo(1.05));
      expect(t.times[t.frameAt(1.05) + 1], greaterThan(1.05));
      final b = await t.jpeg(3);
      expect(frameSize(b), (640, 480));
      await t.close();
    });

    test('a file cut short (app quit while recording) keeps its whole frames', () async {
      final rec = VideoRecorder('${tmp.path}/c.kdv', clock: () => 0, maxFps: 1000);
      await rec.open();
      var now = 0.0;
      final r2 = VideoRecorder('${tmp.path}/c.kdv', clock: () => now += .1, maxFps: 1000);
      await rec.close();
      await r2.open();
      for (var i = 0; i < 5; i++) {
        r2.add(jpeg(i));
      }
      await r2.close();
      final f = File('${tmp.path}/c.kdv');
      final bytes = f.readAsBytesSync();
      f.writeAsBytesSync(bytes.sublist(0, bytes.length - 10));
      final t = (await VideoTrack.open(f.path))!;
      expect(t.length, 4);
      await t.close();
    });

    test('exports a well-formed MJPEG AVI', () async {
      var now = 0.0;
      final rec = VideoRecorder('${tmp.path}/a.kdv', clock: () => now, maxFps: 100);
      await rec.open();
      for (var i = 0; i < 25; i++) {
        now = i / 10;
        rec.add(jpeg(i));
      }
      await rec.close();
      final t = (await VideoTrack.open('${tmp.path}/a.kdv'))!;
      final avi = await mjpegAvi(t);
      await t.close();
      final bd = ByteData.sublistView(avi);
      String cc(int o) => ascii.decode(avi.sublist(o, o + 4));
      expect(cc(0), 'RIFF');
      expect(bd.getUint32(4, Endian.little), avi.length - 8);
      expect(cc(8), 'AVI ');
      final s = latin1.decode(avi);
      expect(s.contains('MJPG'), isTrue);
      expect('00dc'.allMatches(s).length, 50, reason: '25 chunks + 25 index entries');
      final idx = s.indexOf('idx1');
      expect(bd.getUint32(idx + 4, Endian.little), 25 * 16);
      // Average rate of the track: 10 fps → 100 000 µs per frame.
      expect(bd.getUint32(s.indexOf('avih') + 8, Endian.little), 100000);
      // Decode it with an independent reader when one is installed.
      final py = File('../../libs/python/.venv/bin/python');
      if (py.existsSync() && Process.runSync(py.path, ['-c', 'import av']).exitCode == 0) {
        final f = File('${tmp.path}/a.avi')..writeAsBytesSync(avi);
        final r = Process.runSync(py.path, [
          '-c',
          'import av,sys; c=av.open(sys.argv[1]); s=c.streams.video[0]; print(s.codec_context.name, s.width, s.height, s.frames)',
          f.path,
        ]);
        expect((r.stdout as String).trim(), 'mjpeg 640 480 25', reason: '${r.stderr}');
      }
    });

    test('a simulated camera is recorded with the session and replays', () async {
      SharedPreferences.setMockInitialValues({});
      final d = Dash(store: Store(recordingsRoot: tmp.path));
      await d.init();
      d.updateSettings((s) => s.videoFps = 15);
      final dev = d.addSimulated(simTemplates().firstWhere((t) => t.kind == DeviceKind.drone));
      await d.connect(dev.id);
      for (var i = 0; i < 50 && d.video.isEmpty; i++) {
        await wait(50);
      }
      expect(d.video, isNotEmpty, reason: 'the simulator declares its camera');
      d.startRec();
      for (var i = 0; i < 100; i++) {
        await wait(20);
        d.tick(.02);
      }
      d.stopRec();
      final r = d.lastSaved!;
      for (var i = 0; i < 100 && !r.hasVideo; i++) {
        await wait(20);
      }
      expect(r.hasVideo, isTrue);
      expect(r.video!['frames'], greaterThan(3));
      await wait(200);
      expect(File('${tmp.path}/${r.id}.json.gz').existsSync(), isTrue);
      await d.disconnect();
      d.dispose();

      // Loads again with its video, and replays it.
      final d2 = Dash(store: Store(recordingsRoot: tmp.path));
      await d2.init();
      final again = d2.sessions.firstWhere((s) => s.id == r.id);
      expect(again.hasVideo, isTrue);
      d2.openReplay(again.id);
      final track = (await d2.replayVideo(again))!;
      expect(track.length, r.video!['frames']);
      final first = await track.jpeg(0);
      expect(frameSize(first), isNotNull);
      // The simulator sends PNG frames: they export as a PNG AVI.
      final avi = await mjpegAvi(track);
      final py = File('../../libs/python/.venv/bin/python');
      if (py.existsSync() && Process.runSync(py.path, ['-c', 'import av']).exitCode == 0) {
        final f = File('${tmp.path}/sim.avi')..writeAsBytesSync(avi);
        final out = Process.runSync(py.path, [
          '-c',
          'import av,sys; c=av.open(sys.argv[1]); print(c.streams.video[0].codec_context.name, sum(1 for _ in c.decode(video=0)))',
          f.path,
        ]);
        expect((out.stdout as String).trim(), 'png ${track.length}', reason: '${out.stderr}');
      }
      d2.closeReplay();
      // Deleting the recording deletes its video.
      await d2.deleteRecording(again.id);
      expect(File('${tmp.path}/${r.id}.kdv').existsSync(), isFalse);
      d2.dispose();
    });
  });
}
