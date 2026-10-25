/// What scripts show in Live: pictures (dev.show), charts (dev.chart) and
/// plotted series (dev.plot). Each is a widget there, by name.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../video/video_rec.dart';

/// A picture, a chart or a plot a script shows, kept on the device it works
/// with, until dash closes.
class ScriptView extends ChangeNotifier {
  ScriptView(this.name, this.kind, this.script);
  final String name;

  /// picture, chart or plot.
  String kind;

  /// The script that shows it, and whether that script has ended (the widget
  /// keeps the last picture, marked as such).
  String script;
  bool ended = false;
  DateTime at = DateTime.now();

  /// Changes with each update, for widgets that repaint on it.
  int version = 0;

  // A picture: JPEG or PNG bytes, their size, and how often they come.
  Uint8List? image;
  int width = 0, height = 0;
  double fps = 0;

  // A chart: its kind (line, bar, scatter), x values (none: 0, 1, 2…),
  // named series, axis labels.
  String chart = 'line';
  List<double>? x;
  Map<String, List<double>> series = {};
  String xLabel = '', yLabel = '';

  // A plot: the names of its series (the values go through telemetry, so
  // they are drawn over time and recorded).
  List<String> labels = const [];

  /// The widget's id in Live layouts.
  String get tileId => 'sv:$name';

  void _touch(String by) {
    final now = DateTime.now();
    if (kind == 'picture') {
      final dt = now.difference(at).inMicroseconds / 1e6;
      if (dt > 0 && dt < 5) fps = fps == 0 ? 1 / dt : fps * .8 + (1 / dt) * .2;
    }
    at = now;
    script = by;
    ended = false;
    version++;
    notifyListeners();
  }

  /// Its script ended: the widget keeps the last of it, marked so.
  void end() {
    ended = true;
    notifyListeners();
  }

  /// From a `view` message with kind picture: `data` (base64 JPEG or PNG),
  /// `w`, `h`.
  void picture(Map m, String by, {Uint8List? bytes}) {
    if (kind != 'picture') fps = 0;
    kind = 'picture';
    image = bytes ?? base64Decode('${m['data']}');
    width = (m['w'] as num?)?.toInt() ?? 0;
    height = (m['h'] as num?)?.toInt() ?? 0;
    _touch(by);
  }

  /// From a `view` message with kind chart: `chart`, `series` {name: [y…]},
  /// `x` [x…] or absent, `xlabel`, `ylabel`. At most 8 series of 5000 points.
  void chartFrom(Map m, String by) {
    kind = 'chart';
    const kinds = {'line', 'bar', 'scatter'};
    chart = kinds.contains(m['chart']) ? '${m['chart']}' : 'line';
    List<double> nums(Object? l) => [for (final v in (l as List? ?? const []).take(5000)) (v is num && v.isFinite) ? v.toDouble() : double.nan];
    series = {for (final e in ((m['series'] as Map?) ?? const {}).entries.take(8)) '${e.key}': nums(e.value)};
    x = m['x'] is List ? nums(m['x']) : null;
    xLabel = '${m['xlabel'] ?? ''}';
    yLabel = '${m['ylabel'] ?? ''}';
    _touch(by);
  }

  /// From a `plot` message: the series' names.
  void plotFrom(List<String> names, String by) {
    if (kind != 'plot' || labels.length != names.length || !_same(labels, names)) {
      kind = 'plot';
      labels = names;
    }
    _touch(by);
  }

  static bool _same(List<String> a, List<String> b) {
    for (var i = 0; i < math.min(a.length, b.length); i++) {
      if (a[i] != b[i]) return false;
    }
    return a.length == b.length;
  }
}

/// A view's name as part of a file name.
String viewSlug(String name) => name.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');

/// What a script shows, kept while dash records: pictures as video (like the
/// camera, at its frame-rate cap), charts at most twice a second, plots'
/// series names (their values are in the telemetry frames).
class ViewRecorder {
  ViewRecorder(this.dir, this.id, this.clock, this.maxFps);
  final String dir, id;
  final double Function() clock;
  final double maxFps;
  final Map<String, _RecSlot> _slots = {};

  /// Keeps [v] as it is now.
  void add(ScriptView v) {
    final slot = _slots[v.name] ??= _RecSlot(v.kind);
    slot.kind = v.kind;
    switch (v.kind) {
      case 'picture':
        final img = v.image;
        if (img == null) return;
        if (slot.video == null) {
          final rec = slot.video = VideoRecorder('$dir/$id-sv-${viewSlug(v.name)}.kdv', clock: clock, maxFps: maxFps);
          slot.opened = rec.open().then((_) => true, onError: (_) => false);
          slot.opened!.then((ok) {
            if (ok) rec.add(img);
          });
          return;
        }
        slot.video!.add(img);
      case 'chart':
        final t = clock();
        if (slot.lastChart >= 0 && t - slot.lastChart < .5) return;
        slot.lastChart = t;
        slot.charts.add(
          jsonEncode({
            't': (t * 1000).round() / 1000,
            'chart': v.chart,
            'series': {
              for (final e in v.series.entries) e.key: [for (final y in e.value) y.isFinite ? y : null],
            },
            if (v.x != null) 'x': [for (final x in v.x!) x.isFinite ? x : null],
            if (v.xLabel.isNotEmpty) 'xlabel': v.xLabel,
            if (v.yLabel.isNotEmpty) 'ylabel': v.yLabel,
          }),
        );
      default:
        slot.labels = v.labels;
    }
  }

  /// Ends it: what goes in the recording ('views'), with the files written
  /// next to it; with [keep] false, the files are removed.
  Future<List<Map<String, dynamic>>> close({
    required bool keep,
    required Future<void> Function(String file, String text) write,
    required Future<void> Function(String file) delete,
  }) async {
    final out = <Map<String, dynamic>>[];
    for (final e in _slots.entries) {
      final slot = e.value, slug = viewSlug(e.key);
      if (slot.video != null) {
        await slot.opened;
        final n = await slot.video!.close();
        if (!keep || n == 0) {
          await delete('$id-sv-$slug.kdv');
        } else {
          out.add({'name': e.key, 'kind': 'picture', 'file': '$id-sv-$slug.kdv', 'frames': n});
        }
      } else if (slot.charts.isNotEmpty) {
        if (!keep) continue;
        await write('$id-sv-$slug.jsonl', slot.charts.join('\n'));
        out.add({'name': e.key, 'kind': 'chart', 'file': '$id-sv-$slug.jsonl', 'samples': slot.charts.length});
      } else if (slot.kind == 'plot' && keep) {
        out.add({'name': e.key, 'kind': 'plot', 'labels': slot.labels});
      }
    }
    return out;
  }
}

class _RecSlot {
  _RecSlot(this.kind);
  String kind;
  VideoRecorder? video;
  Future<bool>? opened;
  final List<String> charts = [];
  double lastChart = -1;
  List<String> labels = const [];
}

/// A recording's script views, played back at the replay time: the same
/// widgets as live, showing what the script showed then.
class ViewPlayer {
  ViewPlayer(List<Map<String, dynamic>> recorded, String dir) {
    for (final j in recorded) {
      final name = '${j['name']}', kind = '${j['kind']}';
      final v = views[name] = ScriptView(name, kind, 'recorded');
      if (kind == 'plot') v.labels = [for (final l in j['labels'] as List? ?? const []) '$l'];
      if (kind == 'picture') _tracks[name] = VideoTrack.open('$dir/${j['file']}');
      if (kind == 'chart') _charts[name] = _loadCharts('$dir/${j['file']}');
    }
  }

  /// The views, by name, as Live shows them.
  final Map<String, ScriptView> views = {};
  final Map<String, Future<VideoTrack?>> _tracks = {};
  final Map<String, Future<List<(double, Map)>>> _charts = {};
  final Map<String, int> _shown = {};
  bool _busy = false;

  static Future<List<(double, Map)>> _loadCharts(String path) async {
    try {
      final lines = await File(path).readAsLines();
      return [
        for (final l in lines)
          if (l.trim().isNotEmpty) (((jsonDecode(l) as Map)['t'] as num).toDouble(), jsonDecode(l) as Map),
      ];
    } catch (_) {
      return const [];
    }
  }

  /// Shows what was shown at [t] seconds.
  Future<void> seek(double t) async {
    if (_busy) return;
    _busy = true;
    try {
      for (final e in _tracks.entries) {
        final tr = await e.value;
        if (tr == null || tr.length == 0) continue;
        final i = tr.frameAt(t);
        if (_shown[e.key] == i) continue;
        _shown[e.key] = i;
        views[e.key]!.picture({'data': '', 'w': 0, 'h': 0}, 'recorded', bytes: await tr.jpeg(i));
      }
      for (final e in _charts.entries) {
        final samples = await e.value;
        var i = -1;
        for (var k = 0; k < samples.length && samples[k].$1 <= t; k++) {
          i = k;
        }
        if (i < 0 || _shown[e.key] == i) continue;
        _shown[e.key] = i;
        views[e.key]!.chartFrom(samples[i].$2, 'recorded');
      }
    } finally {
      _busy = false;
    }
  }

  void close() {
    for (final t in _tracks.values) {
      t.then((v) => v?.close());
    }
  }
}
