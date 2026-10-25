/// What scripts show in Live: pictures (dev.show), charts (dev.chart) and
/// plotted series (dev.plot). Each is a widget there, by name.
library;

import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

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
  void picture(Map m, String by) {
    if (kind != 'picture') fps = 0;
    kind = 'picture';
    image = base64Decode('${m['data']}');
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
