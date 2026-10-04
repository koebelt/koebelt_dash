// App <-> Python library interop over real UDP.
// Needs libs/python/.venv (see libs/python/README.md); skipped otherwise.
@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:koebelt_dash/core/model.dart';
import 'package:koebelt_dash/core/telemetry.dart';
import 'package:koebelt_dash/link/protocol.dart';
import 'package:koebelt_dash/link/session.dart';
import 'package:koebelt_dash/link/udp_io.dart';

void main() {
  final py = File('../../libs/python/.venv/bin/python');
  test(
    'connects to koebelt-link-sim and drives it',
    () async {
      const port = 47911;
      final proc = await Process.start(
        py.path,
        ['-m', 'koebelt_link.sim', '--kind', 'rover', '--port', '$port'],
        environment: {'KOEBELT_LINK_HOME': Directory.systemTemp.createTempSync('kl').path},
      );
      addTearDown(proc.kill);
      await Future<void>.delayed(const Duration(milliseconds: 800));

      final got = <Msg>[];
      final tel = Telemetry(DeviceKind.rover);
      final s = DeviceSession(
        UdpTransport('127.0.0.1', port),
        onMessage: (m) {
          got.add(m);
          if (m['t'] == 'tlm') tel.applyTlm((m['d'] as Map).cast<String, dynamic>());
          if (m['t'] == 'state') tel.applyState(m);
        },
      );
      final hello = await s.open();
      expect(hello['kind'], 'rover');
      expect(hello['lib'], startsWith('python/'));
      await Future<void>.delayed(const Duration(milliseconds: 1500));

      final params = parseParams(got.firstWhere((m) => m['t'] == 'params'), DeviceKind.rover);
      expect(params.expand((g) => g.params).map((p) => p.key), containsAll(['SPD_P', 'MAX_SPD']));
      expect(got.any((m) => m['t'] == 'chan'), isTrue);
      expect(tel.hasGps, isTrue);
      expect(tel.custom['motor_temp'], hasLength(2));
      expect(got.any((m) => m['t'] == 'pc'), isTrue);
      expect(s.latency, lessThan(100));

      // Manual drive: forward on the right stick.
      s.send({'t': 'mode', 'm': 'MANUAL'});
      s.axes = () => const [0, 0, 0, 1];
      final x0 = tel.pos[0], y0 = tel.pos[1];
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      expect(tel.mode, 'MANUAL');
      expect(hypot2(tel.pos[0] - x0, tel.pos[1] - y0), greaterThan(.5));

      s.sendStop();
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(tel.estop, isTrue);
      expect(tel.armed, isFalse);
      await s.close();
    },
    skip: py.existsSync() ? false : 'python venv not set up',
    timeout: const Timeout(Duration(seconds: 30)),
  );
}
