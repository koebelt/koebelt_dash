import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:koebelt_dash/core/compat.dart';
import 'package:koebelt_dash/core/model.dart';
import 'package:koebelt_dash/scripts/script_runner.dart';

DeviceInfo _dev(String name, String? lib, [int? protocol]) => DeviceInfo(
  id: name,
  name: name,
  kind: DeviceKind.rover,
  model: '',
  sensors: const [],
  transport: TransportKind.udp,
  address: '',
  lib: lib,
  protocol: protocol,
);

void main() {
  const c = Compat(protocol: 2, minLib: {'arduino': '2.0.0', 'python': '1.4.0'});

  test('a library older than the minimum is a problem, a newer or equal one is not', () {
    expect(c.problem('arduino/1.9.3', 1), contains('needs arduino/2.0.0 or later'));
    expect(c.problem('arduino/2.0.0', 2), isNull);
    expect(c.problem('arduino/2.10.1', 2), isNull, reason: 'numeric, not text, comparison');
    expect(c.problem('python/1.3.9', 1), contains('python/1.4.0'));
  });

  test('a device that speaks a newer protocol needs a newer app', () {
    expect(c.problem('arduino/3.0.0', 3), contains('newer than this version'));
  });

  test('devices without koebelt/link, or a library with no minimum, are fine', () {
    expect(c.problem(null, null), isNull, reason: 'MAVLink, MSP, Tello, or never connected');
    expect(c.problem('sim/1.0.0', 1), isNull, reason: 'the app’s own simulator');
    expect(c.problem('rust/0.1.0', 1), isNull, reason: 'rust has no minimum here');
    expect(c.problem('garbage', 1), isNull);
  });

  test('lists the paired devices a version would leave behind', () {
    final bad = c.incompatible([_dev('Kite', 'arduino/1.0.0', 1), _dev('Mule', 'python/1.5.0', 1), _dev('Tello', null)]);
    expect(bad.map((b) => b.device.name), ['Kite']);
  });

  test('releases from before compat.json support everything', () {
    expect(Compat.legacy.incompatible([_dev('Kite', 'arduino/0.1.0', 1)]), isEmpty);
  });

  test('the bundled compat.json parses, and the app still supports the libraries it ships for', () {
    final mine = Compat.parse(File('compat.json').readAsStringSync());
    expect(mine.protocol, greaterThanOrEqualTo(1));
    for (final family in ['arduino', 'python', 'rust']) {
      expect(mine.minLib[family], isNotNull, reason: 'a minimum for $family');
    }
  });

  test('a device remembers its library across restarts', () {
    final d = DeviceInfo.fromJson(_dev('Kite', 'arduino/1.0.0', 1).toJson());
    expect(d.lib, 'arduino/1.0.0');
    expect(d.protocol, 1);
  });

  test('pre-releases come before their release, in order', () {
    const order = ['1.2.3', '1.3.0-alpha.1', '1.3.0-beta.1', '1.3.0-beta.2', '1.3.0-beta.10', '1.3.0-rc.1', '1.3.0', '1.3.1'];
    for (var i = 0; i < order.length - 1; i++) {
      expect(compareVersions(order[i], order[i + 1]), -1, reason: '${order[i]} < ${order[i + 1]}');
      expect(compareVersions(order[i + 1], order[i]), 1);
    }
    expect(compareVersions('1.3.0-beta.1', '1.3.0-beta.1'), 0);
    expect(isPrerelease('1.3.0-rc.1'), isTrue);
    expect(isPrerelease('1.3.0'), isFalse);
    expect([pep440('1.3.0-beta.1'), pep440('1.3.0-rc.2'), pep440('1.3.0-alpha.3'), pep440('1.3.0')], ['1.3.0b1', '1.3.0rc2', '1.3.0a3', '1.3.0']);
  });

  test('the Python package dash installs: any with this script API, betas only for a beta', () {
    expect(scriptsPackageSpec('1.3.0-beta.2'), 'koebelt-dash-scripts>=1.3.0b1,<2');
    expect(scriptsPackageSpec('1.3.0'), 'koebelt-dash-scripts>=1.3.0,<2');
    expect(scriptsPackageSpec('1.4.2'), 'koebelt-dash-scripts>=1.3.0,<2');
  });
}
