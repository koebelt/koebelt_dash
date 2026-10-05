import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:koebelt_dash/core/dash.dart';
import 'package:koebelt_dash/core/export.dart';
import 'package:koebelt_dash/core/model.dart';
import 'package:koebelt_dash/core/telemetry.dart';
import 'package:koebelt_dash/sim/sim_device.dart';

Recording rec(DeviceKind k, {double secs = 3, DateTime? at}) => Recording(
  id: 'r-${k.name}',
  name: 'Test, "flight"',
  deviceId: 'x',
  kind: k,
  deviceName: 'Kite',
  date: '01 Oct · 10:00',
  frames: SimDevice.record(DeviceInfo(id: 'x', name: 'Kite', kind: k), secs),
  startedAt: at,
);

void main() {
  test('sliced CSV export matches the one-shot one and reports progress', () async {
    final r = rec(DeviceKind.drone, secs: 120);
    final seen = <double>[];
    final text = await exportRecordingAsync(r, ExportFormat.csv, onProgress: seen.add);
    expect(text, toCsv(r));
    expect(seen.length, greaterThan(2));
    expect(seen, orderedEquals([...seen]..sort()));
    expect(seen.last, 1);
  });

  test('CSV has one row per frame and only the channels the device sent', () {
    final r = rec(DeviceKind.drone);
    final lines = toCsv(r).trim().split('\n');
    expect(lines.first, startsWith('# koebelt/dash recording'));
    final head = lines[1].split(',');
    expect(head.first, 't_s');
    expect(head, containsAll(['x_m', 'z_m', 'roll_deg', 'ax_ms2', 'lat_deg', 'voltage_v', 'rssi_dbm']));
    expect(head.where((h) => h.startsWith('j1') || h.startsWith('thrust')), isEmpty);
    expect(lines.length - 2, r.frames.length);
    final row = lines[2 + 10].split(',');
    expect(row.length, head.length);
    expect(row[0], '1.0', reason: '10 Hz time column');
    // commas and quotes in names are escaped in the comment line only; fields stay numeric
    expect(double.tryParse(row[head.indexOf('lat_deg')]), closeTo(47.3769, .01));
  });

  test('arm CSV has joints, not GPS; no GPX offered', () {
    final r = rec(DeviceKind.arm);
    final head = toCsv(r).split('\n')[1].split(',');
    expect(head, containsAll(['j1_deg', 'j6_deg', 'gripper_open']));
    expect(head.any((h) => h.startsWith('lat')), isFalse);
    expect(formatsFor(r), isNot(contains(ExportFormat.gpx)));
  });

  test('custom channels become columns', () {
    final t = Telemetry(DeviceKind.generic)
      ..applyTlm({
        'motor_temp': [40.5, 41.0],
      });
    final r = Recording(id: 'c', name: 'c', deviceId: 'x', kind: DeviceKind.generic, deviceName: 'X', date: '', frames: [t.snapshot()]);
    final lines = toCsv(r).trim().split('\n');
    final head = lines[1].split(',');
    expect(head, containsAll(['motor_temp_1', 'motor_temp_2']));
    expect(lines[2].split(',')[head.indexOf('motor_temp_2')], '41');
  });

  test('JSON export round-trips', () {
    final r = rec(DeviceKind.rover, at: DateTime.utc(2026, 10, 1, 9, 30));
    final j = jsonDecode(exportRecording(r, ExportFormat.json)) as Map<String, dynamic>;
    expect(j['format'], 'koebelt-dash-recording');
    final back = Recording.fromJson(j);
    expect(back.frames.length, r.frames.length);
    expect(back.startedAt, r.startedAt);
    expect(back.kind, DeviceKind.rover);
  });

  test('GPX has timestamped track points', () {
    final r = rec(DeviceKind.drone, at: DateTime.utc(2026, 10, 1, 9, 30));
    final g = toGpx(r);
    expect(g, contains('<gpx version="1.1"'));
    expect(RegExp('<trkpt ').allMatches(g).length, r.frames.length);
    expect(g, contains('<time>2026-10-01T09:30:00.100Z</time>'));
    expect(g, contains('Test, &quot;flight&quot;'));
    expect(exportFileName(r, ExportFormat.gpx), 'Kite_Test_flight.gpx');
  });
}
