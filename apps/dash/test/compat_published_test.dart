// The app against a koebelt/link release people already run: a device built
// from a published package (PyPI, crates.io), not from this repository. Run by
// tools/compat/run.sh for every published version; skipped without it.
//
//   KDASH_COMPAT_CMD   the device, {port} replaced: "python -m koebelt_link.sim --port {port}"
//   KDASH_COMPAT_LIB   what its hello must say, e.g. "python/1.0.0"
@TestOn('vm')
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:koebelt_dash/core/model.dart';
import 'package:koebelt_dash/core/telemetry.dart';
import 'package:koebelt_dash/link/protocol.dart';
import 'package:koebelt_dash/link/session.dart';
import 'package:koebelt_dash/link/udp_io.dart';

void main() {
  final cmd = Platform.environment['KDASH_COMPAT_CMD'];
  final lib = Platform.environment['KDASH_COMPAT_LIB'];

  test(
    'the app works with $lib',
    () async {
      const port = 47931;
      final argv = cmd!.replaceAll('{port}', '$port').split(' ');
      final proc = await Process.start(argv.first, argv.skip(1).toList(), environment: {'KOEBELT_LINK_HOME': Directory.systemTemp.createTempSync('kl').path});
      addTearDown(proc.kill);
      final log = StringBuffer();
      proc.stdout.transform(const SystemEncoding().decoder).listen(log.write);
      proc.stderr.transform(const SystemEncoding().decoder).listen(log.write);

      final got = <Msg>[];
      final tel = Telemetry(DeviceKind.rover);
      late DeviceSession s;
      Msg? hello;
      // The device needs a moment to bind its port.
      for (var i = 0; i < 10 && hello == null; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        s = DeviceSession(
          UdpTransport('127.0.0.1', port),
          onMessage: (m) {
            got.add(m);
            if (m['t'] == 'tlm') tel.applyTlm((m['d'] as Map).cast<String, dynamic>());
            if (m['t'] == 'state') tel.applyState(m);
          },
        );
        try {
          hello = await s.open(timeout: const Duration(seconds: 2));
        } on TimeoutException {
          await s.close();
        }
      }
      expect(hello, isNotNull, reason: 'no hello from the device. Its output:\n$log');

      // 1. It is the published release, and it describes itself.
      expect(hello!['lib'], lib, reason: 'the device must be the published build, not this repository');
      expect(hello['kind'], 'rover');
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      final params = parseParams(got.firstWhere((m) => m['t'] == 'params'), DeviceKind.rover);
      expect(params.expand((g) => g.params).map((p) => p.key), contains('MAX_SPD'));
      expect(got.where((m) => m['t'] == 'tlm'), isNotEmpty, reason: 'telemetry');
      expect(tel.armed, isTrue);

      // 2. Driving: forward on the right stick in Manual.
      s.send({'t': 'mode', 'm': 'MANUAL'});
      s.axes = () => const [0, 0, 0, 1];
      final x0 = tel.pos[0], y0 = tel.pos[1];
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      expect(tel.mode, 'MANUAL');
      expect(hypot2(tel.pos[0] - x0, tel.pos[1] - y0), greaterThan(.3), reason: 'the rover moves');
      s.axes = () => const [0, 0, 0, 0];

      // 3. The device's own failsafe when the app goes quiet, and back.
      s.holdHeartbeat = true;
      await Future<void>.delayed(const Duration(milliseconds: 2600));
      expect(tel.failsafe, isTrue, reason: 'failsafe after 1.8 s without control');
      s.holdHeartbeat = false;
      await Future<void>.delayed(const Duration(milliseconds: 300));
      s.send({'t': 'mode', 'm': 'MANUAL'});
      await Future<void>.delayed(const Duration(milliseconds: 800));
      expect(tel.failsafe, isFalse, reason: 'control returns with the heartbeat and a new mode');

      // 4. A stored sequence keeps running through a lost link.
      if (hello['seq'] is num && (hello['seq'] as num) >= 3) {
        got.clear();
        s.send({
          't': 'seq',
          'id': 'compat',
          'steps': [
            [
              'wait',
              {'s': 1.0},
            ],
            [
              'mode',
              {'m': 'HOLD'},
            ],
            [
              'wait',
              {'s': 0.4},
            ],
          ],
        });
        await Future<void>.delayed(const Duration(milliseconds: 400));
        final ack = got.where((m) => m['t'] == 'seqack').firstOrNull;
        expect(ack?['ok'], isTrue, reason: 'seqack: $ack');
        s.send({'t': 'seqrun', 'id': 'compat'});
        s.holdHeartbeat = true;
        Map? run;
        for (var i = 0; i < 40; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 100));
          final states = got.where((m) => m['t'] == 'state' && (m['ext'] as Map?)?['run'] != null);
          // While it runs, the lost link must not interrupt it.
          for (final st in states) {
            if ((st['ext'] as Map)['run']['st'] == 'run') expect(st['fs'] == true, isFalse, reason: 'failsafe during a stored sequence: $st');
          }
          run = states.isEmpty ? null : (states.last['ext'] as Map)['run'] as Map;
          if (run?['st'] == 'done' || run?['st'] == 'fail') break;
        }
        expect(run?['st'], 'done', reason: 'sequence report: $run');
        expect(tel.mode, 'HOLD', reason: 'the mode step ran');
        s.holdHeartbeat = false;
        await Future<void>.delayed(const Duration(milliseconds: 300));
      }

      // 5. STOP.
      s.sendStop();
      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(tel.estop, isTrue);
      expect(tel.armed, isFalse);
      await s.close();
    },
    skip: cmd == null || lib == null ? 'set KDASH_COMPAT_CMD and KDASH_COMPAT_LIB (tools/compat/run.sh)' : false,
    timeout: const Timeout(Duration(seconds: 60)),
  );
}
