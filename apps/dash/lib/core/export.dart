// Recording export: CSV (one row per frame), JSON (full recording) and GPX
// (GPS track). Pure functions, no I/O. Video: see video/video_rec.dart.
import 'dart:convert';
import 'dart:math' as math;

import 'dash.dart';

enum ExportFormat {
  csv('CSV', 'csv', 'text/csv', 'One row per frame at the recorded rate, one column per channel. Opens in spreadsheets, pandas, MATLAB.'),
  json('JSON', 'json', 'application/json', 'The full recording including the point cloud, without the video. Lossless.'),
  gpx('GPX', 'gpx', 'application/gpx+xml', 'GPS track for maps and flight-log tools.'),
  video('Video', 'avi', 'video/x-msvideo', 'The camera recorded with the session, as MJPEG AVI. Plays in VLC and most video editors.');

  const ExportFormat(this.label, this.ext, this.mime, this.desc);
  final String label, ext, mime, desc;
}

bool hasGps(Recording r) => r.frames.any((f) => (f['seen'] as List?)?.contains('gps') ?? false);

List<ExportFormat> formatsFor(Recording r) => [ExportFormat.csv, ExportFormat.json, if (hasGps(r)) ExportFormat.gpx, if (r.hasVideo) ExportFormat.video];

String exportFileName(Recording r, ExportFormat f) {
  final safe = '${r.deviceName} ${r.name}'.replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_').replaceAll(RegExp(r'_+'), '_');
  return '${safe.replaceAll(RegExp(r'^_|_$'), '')}.${f.ext}';
}

String exportRecording(Recording r, ExportFormat f) => switch (f) {
  ExportFormat.csv => toCsv(r),
  ExportFormat.json => const JsonEncoder.withIndent(
    '  ',
  ).convert({'format': 'koebelt-dash-recording', 'version': 1, 'rateHz': (r.rateHz * 10).round() / 10, ...r.toJson()}),
  ExportFormat.gpx => toGpx(r),
  ExportFormat.video => throw UnsupportedError('Video is exported as bytes: see mjpegAvi'),
};

// ------------------------------------------------------------------ CSV
typedef _Col = (String header, String Function(Map<String, dynamic> f) value);

String _n(dynamic v, [int digits = 4]) {
  if (v is! num || !v.isFinite) return '';
  final d = v.toDouble();
  if (d == d.roundToDouble() && d.abs() < 1e12) return d.toStringAsFixed(0);
  return double.parse(d.toStringAsFixed(digits)).toString();
}

String _deg(dynamic v) => v is num ? _n(v * 180 / math.pi, 3) : '';

dynamic _at(Map f, String k, int i) {
  final l = f[k];
  return l is List && i < l.length ? l[i] : null;
}

String _csvField(String s) => s.contains(RegExp('[",\n]')) ? '"${s.replaceAll('"', '""')}"' : s;

String toCsv(Recording r) {
  final b = StringBuffer();
  for (final _ in _csvRows(r, b)) {}
  return b.toString();
}

/// Encodes in slices, yielding to the event loop between them so the UI
/// keeps animating; [onProgress] gets the fraction of frames written.
Future<String> exportRecordingAsync(Recording r, ExportFormat f, {void Function(double)? onProgress}) async {
  if (f != ExportFormat.csv) {
    final s = exportRecording(r, f);
    onProgress?.call(1);
    return s;
  }
  final b = StringBuffer(), n = math.max(1, r.frames.length);
  var i = 0;
  for (final _ in _csvRows(r, b)) {
    if (++i % 500 == 0) {
      onProgress?.call(i / n);
      await Future<void>.delayed(Duration.zero);
    }
  }
  onProgress?.call(1);
  return b.toString();
}

/// Writes the CSV into [b], yielding once per frame row.
Iterable<void> _csvRows(Recording r, StringBuffer b) sync* {
  final seen = <String>{for (final f in r.frames) ...List<String>.from(f['seen'] ?? const [])};
  // Custom channels and their widths.
  final custom = <String, int>{};
  for (final f in r.frames) {
    final c = f['custom'];
    if (c is Map) {
      for (final e in c.entries) {
        custom['${e.key}'] = math.max(custom['${e.key}'] ?? 0, (e.value as List).length);
      }
    }
  }
  final cols = <_Col>[
    ('mode', (f) => '${f['mode'] ?? ''}'),
    ('armed', (f) => f['armed'] == true ? '1' : '0'),
    if (seen.contains('pos')) ...[
      for (final (i, a) in ['x_m', 'y_m', 'z_m'].indexed) (a, (f) => _n(_at(f, 'pos', i))),
    ],
    if (seen.contains('vel')) ...[
      for (final (i, a) in ['vx_ms', 'vy_ms', 'vz_ms'].indexed) (a, (f) => _n(_at(f, 'vel', i))),
    ],
    if (seen.contains('att')) ...[('roll_deg', (f) => _deg(f['roll'])), ('pitch_deg', (f) => _deg(f['pitch'])), ('yaw_deg', (f) => _deg(f['yaw']))],
    if (seen.contains('imu')) ...[
      for (final (i, a) in ['ax_ms2', 'ay_ms2', 'az_ms2'].indexed) (a, (f) => _n(_at(f, 'acc', i))),
      for (final (i, a) in ['gx_rads', 'gy_rads', 'gz_rads'].indexed) (a, (f) => _n(_at(f, 'gyro', i))),
    ],
    if (seen.contains('gps')) ...[('lat_deg', (f) => _n(f['lat'], 7)), ('lon_deg', (f) => _n(f['lon'], 7)), ('gps_alt_m', (f) => _n(f['galt'], 2))],
    if (seen.contains('bat')) ...[
      ('voltage_v', (f) => _n(f['voltage'], 3)),
      ('current_a', (f) => _n(f['current'], 3)),
      ('battery_pct', (f) => _n(f['battery'], 1)),
    ],
    if (seen.contains('rssi')) ('rssi_dbm', (f) => _n(f['rssi'], 1)),
    if (seen.contains('joints')) ...[for (var i = 0; i < 6; i++) ('j${i + 1}_deg', (f) => _deg(_at(f, 'joints', i)))],
    if (seen.contains('tool')) ('gripper_open', (f) => _n(f['gripper'], 3)),
    if (seen.contains('ft')) ...[
      for (final (i, a) in ['fx_n', 'fy_n', 'fz_n'].indexed) (a, (f) => _n(_at(f, 'ft', i))),
    ],
    if (seen.contains('thrust')) ...[('thrust_n', (f) => _n(f['thrust'])), ('torque_nm', (f) => _n(f['torque']))],
    if (seen.contains('rpm')) ('rpm', (f) => _n(f['rpm'], 0)),
    if (seen.contains('temp')) ('temp_c', (f) => _n(f['temp'], 2)),
    if (seen.contains('throttle')) ('throttle_out', (f) => _n(f['thr'], 3)),
    if (seen.contains('rocket')) ...[
      ('max_alt_m', (f) => _n(f['maxAlt'], 2)),
      ('phase_t_s', (f) => _n(f['phaseT'], 2)),
      for (var i = 0; i < 4; i++) ('pyro${i + 1}', (f) => '${_at(f, 'pyro', i) ?? ''}'),
    ],
    for (final e in custom.entries)
      for (var i = 0; i < e.value; i++) ('${e.key}_${i + 1}', (f) => _n(((f['custom'] as Map?)?[e.key] as List?)?.elementAtOrNull(i))),
  ];
  b
    ..writeln(
      '# koebelt/dash recording: ${r.name} · ${r.deviceName} (${r.kind.name}) · ${r.date}'
      '${r.startedAt != null ? ' · started ${r.startedAt!.toUtc().toIso8601String()}' : ''}'
      ' · ${r.rateHz.round()} Hz · position in metres from home, east/north/up',
    )
    ..writeln(['t_s', for (final c in cols) c.$1].join(','));
  for (var i = 0; i < r.frames.length; i++) {
    final f = r.frames[i];
    b.writeln([r.timeAt(i).toStringAsFixed(3), for (final c in cols) _csvField(c.$2(f))].join(','));
    yield null;
  }
}

// ------------------------------------------------------------------ GPX
String _xml(String s) => s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;').replaceAll('"', '&quot;');

String toGpx(Recording r) {
  final b = StringBuffer()
    ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
    ..writeln('<gpx version="1.1" creator="koebelt/dash" xmlns="http://www.topografix.com/GPX/1/1">')
    ..writeln(
      '  <metadata><name>${_xml(r.name)}</name><desc>${_xml('${r.deviceName} · ${r.date}')}</desc>'
      '${r.startedAt != null ? '<time>${r.startedAt!.toUtc().toIso8601String()}</time>' : ''}</metadata>',
    )
    ..writeln('  <trk><name>${_xml('${r.deviceName} · ${r.name}')}</name><type>${r.kind.name}</type><trkseg>');
  for (var i = 0; i < r.frames.length; i++) {
    final f = r.frames[i];
    final lat = f['lat'], lon = f['lon'];
    if (lat is! num || lon is! num || (lat == 0 && lon == 0)) continue;
    final ele = f['galt'] is num ? '<ele>${_n(f['galt'], 2)}</ele>' : '';
    final t = r.startedAt == null ? '' : '<time>${r.startedAt!.add(Duration(microseconds: (r.timeAt(i) * 1e6).round())).toUtc().toIso8601String()}</time>';
    b.writeln('    <trkpt lat="${_n(lat, 7)}" lon="${_n(lon, 7)}">$ele$t</trkpt>');
  }
  b
    ..writeln('  </trkseg></trk>')
    ..writeln('</gpx>');
  return b.toString();
}
