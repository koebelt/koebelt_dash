import 'package:flutter_test/flutter_test.dart';
import 'package:koebelt_dash/core/dash.dart';
import 'package:koebelt_dash/core/model.dart';
import 'package:koebelt_dash/scripts/library.dart';
import 'package:koebelt_dash/scripts/requirements.dart';

void main() {
  DeviceInfo sim(String id) => simTemplates().firstWhere((t) => t.id == id);

  test('# requires: lines: kinds (any), capabilities (all), comments ignored', () {
    final r = ScriptRequirements.parse('''"""Follow."""
# requires: drone, rover     # a kind: any one of them
# requires: GPS camera
import math
''');
    expect(r.kinds, {DeviceKind.drone, DeviceKind.rover});
    expect(r.needs, ['gps', 'camera']);
    expect(r.describe(), 'a drone or rover with gps and camera');
    expect(ScriptRequirements.parse('import x').isEmpty, isTrue);
    expect(ScriptRequirements.parse('', extra: ['bench']).kinds, {DeviceKind.bench});
  });

  test('checked against what devices announce: the simulators', () {
    final r = ScriptRequirements.parse('# requires: rover\n# requires: camera, lidar');
    expect(r.missing(sim('mule')), isEmpty, reason: 'Mule: a rover with 2D LIDAR and a camera');
    expect(r.missing(sim('kite')), ['a rover (Kite is a drone)', 'lidar']);
    expect(ScriptRequirements.parse('# requires: joints').missing(sim('cell')), isEmpty);
    expect(ScriptRequirements.parse('# requires: wheel_odom').missing(sim('mule')), isEmpty, reason: 'a sensor by its own name');
  });

  test('a new script requires the kind it was made for', () {
    final src = scriptTemplate('loop', DeviceKind.rover, 'Patrol');
    final r = ScriptRequirements.parse(src);
    expect(r.kinds, {DeviceKind.rover});
    expect(r.needs, isEmpty, reason: 'the explanation line is not read as requirements');
  });

  test('why a device does not fit, in a sentence', () {
    final drone = ScriptRequirements.parse('# requires: drone, gps');
    expect(drone.whyNot(sim('mule')), 'Mule is a rover; this script needs a drone with gps.');
    expect(drone.whyNot(sim('kite')), isNull);
    expect(ScriptRequirements.parse('# requires: lidar, thrust').whyNot(sim('kite')), 'Kite has no lidar or thrust; this script needs a device with lidar and thrust.');
  });
}
