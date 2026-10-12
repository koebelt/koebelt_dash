import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/dash.dart';
import '../core/model.dart';
import '../theme/tokens.dart';

/// Chart colours (viz.jsx `VC`).
abstract final class VC {
  static const lime = K.lime500, white = K.white, ink100 = K.ink100, ink200 = K.ink200, ink300 = K.ink300, ink500 = K.ink500, ink900 = K.ink900;
  static const hair = K.whiteA12, hair2 = K.whiteA06;
  static const info = K.info, warn = K.warning, neg = K.negative, pos = K.positive;
}

const axisColors = [VC.white, VC.info, VC.warn];

/// Colours of the other connected devices on the map, in 3D and in the
/// Fleet tile; the one shown is always lime.
const fleetColors = [VC.info, Color(0xFFB79CF0), Color(0xFF6FD3C9), Color(0xFFF29ACB), VC.ink200, VC.warn];

Color fleetColor(Dash d, String id) {
  if (id == d.deviceId && d.replay == null || id == d.replay?.session.id) return VC.lime;
  final i = d.companions.indexWhere((c) => c.id == id);
  return fleetColors[(i < 0 ? 0 : i) % fleetColors.length];
}

const _monoStyle = TextStyle(fontFamily: fontMono, fontSize: 10, fontWeight: FontWeight.w500);

void drawText(Canvas c, String s, Offset o, Color color, {TextAlign align = TextAlign.left, double? width, bool middle = false}) {
  final tp = TextPainter(
    text: TextSpan(
      text: s,
      style: _monoStyle.copyWith(color: color),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  var dx = o.dx;
  if (align == TextAlign.right) dx -= tp.width;
  tp.paint(c, Offset(dx, middle ? o.dy - tp.height / 2 : o.dy - tp.height * .8));
}

Paint _stroke(Color c, [double w = 1]) => Paint()
  ..color = c
  ..style = PaintingStyle.stroke
  ..strokeWidth = w;
Paint _fill(Color c) => Paint()..color = c;

/// Base for canvases that repaint every frame.
abstract class FramePainter extends CustomPainter {
  FramePainter(this.dash, [Listenable? also]) : super(repaint: also == null ? dash.frame : Listenable.merge([dash.frame, also]));
  final Dash dash;
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class LiveCanvas extends StatelessWidget {
  const LiveCanvas(this.painter, {super.key});
  final CustomPainter painter;
  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(painter: painter, size: Size.infinite),
  );
}

// ------------------------------------------------------------------ line chart
/// Readable names and units for the history channels.
const seriesInfo = <String, (String, String)>{
  'vz': ('Vertical speed', 'm/s'),
  'thr': ('Thrust', 'N'),
  'rpm': ('RPM', ''),
  'tq': ('Torque', 'N·m'),
  'tmp': ('Temp', '°C'),
  'pw': ('Power', 'W'),
  'ax': ('Accel X', 'm/s²'),
  'ay': ('Accel Y', 'm/s²'),
  'az': ('Accel Z', 'm/s²'),
  'gx': ('Gyro X', 'rad/s'),
  'gy': ('Gyro Y', 'rad/s'),
  'gz': ('Gyro Z', 'rad/s'),
  'alt': ('Altitude', 'm'),
  'volt': ('Voltage', 'V'),
  'cur': ('Current', 'A'),
  'rssi': ('RSSI', 'dBm'),
  'lat': ('Latency', 'ms'),
  'spd': ('Speed', 'm/s'),
  'j0': ('J1', 'rad'),
  'j1': ('J2', 'rad'),
  'j2': ('J3', 'rad'),
  'j3': ('J4', 'rad'),
  'j4': ('J5', 'rad'),
  'j5': ('J6', 'rad'),
  'fx': ('Fx', 'N'),
  'fy': ('Fy', 'N'),
  'fz': ('Fz', 'N'),
};

String seriesLabel(String k) {
  final i = seriesInfo[k];
  if (i != null) return i.$1;
  final m = RegExp(r'^c:(.+):(\d+)$').firstMatch(k);
  return m == null ? k : '${m[1]!.replaceAll('_', ' ')} ${int.parse(m[2]!) + 1}';
}

String fmtValue(double v) {
  final a = v.abs();
  final s = a >= 1000
      ? v.toStringAsFixed(0)
      : a >= 100
      ? v.toStringAsFixed(1)
      : a >= 1
      ? v.toStringAsFixed(2)
      : v.toStringAsFixed(3);
  return s.startsWith('-') ? '−${s.substring(1)}' : s;
}

/// Scrolling history chart. Hover (mouse) or drag horizontally (touch) to
/// inspect exact values; with [pinnable], a tap pins the readout.
class LineChart extends StatefulWidget {
  const LineChart(this.dash, {super.key, required this.keys, this.colors = axisColors, this.sym = false, this.frozen, this.labels, this.pinnable = false});
  final Dash dash;
  final List<String> keys;
  final List<Color> colors;
  final bool sym;
  final Map<String, List<double?>>? frozen;

  /// Overrides the series names shown in the readout.
  final List<String>? labels;

  /// Tap to pin/unpin the readout. Off where a tap already means something (tiles).
  final bool pinnable;

  /// Samples per second of the history buffers.
  static const hz = 30.0;

  @override
  State<LineChart> createState() => _LineChartState();
}

class _LineChartState extends State<LineChart> {
  final _x = ValueNotifier<double?>(null);
  bool _pinned = false;

  @override
  void dispose() {
    _x.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final painter = _LinePainter(w.dash, w.keys, w.colors, w.sym, w.frozen, _x, w.labels);
    return MouseRegion(
      cursor: SystemMouseCursors.precise,
      onHover: (e) => _pinned ? null : _x.value = e.localPosition.dx,
      onExit: (_) => _pinned ? null : _x.value = null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        // Horizontal drags only, so vertical scrolling still works over charts.
        onHorizontalDragStart: (e) => _x.value = e.localPosition.dx,
        onHorizontalDragUpdate: (e) => _x.value = e.localPosition.dx,
        onHorizontalDragEnd: (_) => _pinned ? null : _x.value = null,
        onHorizontalDragCancel: () => _pinned ? null : _x.value = null,
        onTapUp: w.pinnable
            ? (e) {
                if (_pinned && _x.value != null && (e.localPosition.dx - _x.value!).abs() < 12) {
                  _pinned = false;
                  _x.value = null;
                } else {
                  _pinned = true;
                  _x.value = e.localPosition.dx;
                }
              }
            : null,
        child: RepaintBoundary(
          child: CustomPaint(painter: painter, size: Size.infinite),
        ),
      ),
    );
  }
}

class _LinePainter extends FramePainter {
  _LinePainter(Dash dash, this.keys, this.colors, this.sym, this.frozen, this.hover, this.labels) : super(dash, hover);
  final List<String> keys;
  final List<Color> colors;
  final bool sym;
  final Map<String, List<double?>>? frozen;
  final ValueNotifier<double?> hover;
  final List<String>? labels;
  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height;
    if (w <= 0 || h <= 0) return;
    final data = [for (final k in keys) frozen?[k] ?? dash.hist[k].toList()];
    var lo = double.infinity, hi = double.negativeInfinity;
    for (final a in data) {
      for (final v in a) {
        if (v == null) continue;
        lo = math.min(lo, v);
        hi = math.max(hi, v);
      }
    }
    if (!lo.isFinite) {
      lo = -1;
      hi = 1;
    }
    if (sym) {
      final m = math.max(math.max(lo.abs(), hi.abs()), .2);
      lo = -m;
      hi = m;
    }
    var pad = (hi - lo) * .12;
    if (pad == 0) pad = 1;
    lo -= pad;
    hi += pad;
    const L = 34.0;
    double y(double v) => h - 4 - (v - lo) / (hi - lo) * (h - 8);
    final grid = _stroke(VC.hair2);
    for (var i = 0; i <= 3; i++) {
      final v = lo + (hi - lo) * i / 3, yy = y(v);
      c.drawLine(Offset(L, yy), Offset(w, yy), grid);
      drawText(c, v.toStringAsFixed((hi - lo).abs() < 10 ? 1 : 0), Offset(0, yy), VC.ink300, middle: true);
    }
    for (var ki = 0; ki < data.length; ki++) {
      final a = data[ki];
      final p = Path();
      var st = false;
      for (var i = 0; i < a.length; i++) {
        final v = a[i];
        if (v == null) continue;
        final x = L + i / (a.length - 1) * (w - L);
        st ? p.lineTo(x, y(v)) : p.moveTo(x, y(v));
        st = true;
      }
      c.drawPath(p, _stroke(colors[ki % colors.length], 1.25));
    }
    final hx = hover.value;
    if (hx != null && data.isNotEmpty && data.first.length > 1) _inspect(c, s, data, hx, L, y);
  }

  void _inspect(Canvas c, Size s, List<List<double?>> data, double hx, double L, double Function(double) y) {
    final n = data.first.length;
    final i = (((hx - L) / (s.width - L)) * (n - 1)).round().clamp(0, n - 1);
    final x = L + i / (n - 1) * (s.width - L);
    c.drawLine(Offset(x, 0), Offset(x, s.height), _stroke(VC.white.withValues(alpha: .35)));
    final rows = <(Color, String)>[];
    final names = [for (var k = 0; k < data.length; k++) (labels != null && k < labels!.length ? labels![k] : seriesLabel(keys[k])).toUpperCase()];
    final pad = names.fold<int>(0, (m, n) => math.max(m, n.length));
    for (var k = 0; k < data.length; k++) {
      final v = i < data[k].length ? data[k][i] : null;
      if (v == null) continue;
      final col = colors[k % colors.length];
      c.drawCircle(Offset(x, y(v)), 3.5, Paint()..color = col);
      c.drawCircle(Offset(x, y(v)), 3.5, _stroke(VC.ink900, 1.5));
      final key = keys[k];
      final unit = seriesInfo[key]?.$2 ?? '';
      rows.add((col, '${names[k].padRight(pad)}  ${fmtValue(v).padLeft(7)}${unit.isEmpty ? '' : ' $unit'}'));
    }
    if (rows.isEmpty) return;
    final ago = (n - 1 - i) / LineChart.hz;
    final head = ago < .05 ? 'NOW' : '−${ago.toStringAsFixed(1)} S';
    final tps = [
      for (final r in [(VC.ink200, head), ...rows])
        TextPainter(
          text: TextSpan(
            text: r.$2,
            style: _monoStyle.copyWith(color: r.$1 == VC.ink200 ? VC.ink200 : VC.white),
          ),
          textDirection: TextDirection.ltr,
        )..layout(),
    ];
    const inset = 8.0, lh = 14.0, sw = 10.0;
    final bw = tps.map((t) => t.width).reduce(math.max) + inset * 2 + sw;
    final bh = tps.length * lh + inset * 2 - 2;
    var bx = x + 10;
    if (bx + bw > s.width) bx = x - 10 - bw;
    bx = bx.clamp(0.0, math.max(0.0, s.width - bw));
    final by = 2.0;
    final box = RRect.fromRectAndRadius(Rect.fromLTWH(bx, by, bw, bh), const Radius.circular(4));
    c.drawRRect(box, Paint()..color = const Color(0xF20D0C0C));
    c.drawRRect(box, _stroke(VC.hair));
    for (var r = 0; r < tps.length; r++) {
      final ty = by + inset + r * lh;
      if (r > 0) c.drawRect(Rect.fromLTWH(bx + inset, ty + 4, 6, 2), Paint()..color = rows[r - 1].$1);
      tps[r].paint(c, Offset(bx + inset + (r > 0 ? sw : 0), ty));
    }
  }
}

// ------------------------------------------------------------------ attitude
class AttitudePainter extends FramePainter {
  AttitudePainter(super.dash);
  @override
  void paint(Canvas c, Size s) {
    final t = dash.tel;
    final r = math.min(s.width, s.height) / 2 - 6, cx = s.width / 2, cy = s.height / 2;
    if (r <= 0) return;
    c.save();
    c.clipPath(Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r)));
    c.translate(cx, cy);
    c.rotate(-t.rRoll);
    final off = t.rPitch * r * 2;
    c.drawRect(Rect.fromLTWH(-r * 2, -r * 2 + off, r * 4, r * 2), _fill(VC.ink500));
    c.drawRect(Rect.fromLTWH(-r * 2, off, r * 4, r * 2), _fill(VC.ink900));
    c.drawLine(Offset(-r * 2, off), Offset(r * 2, off), _stroke(VC.white));
    for (var p = -30; p <= 30; p += 10) {
      if (p == 0) continue;
      final yy = off - p / 57.3 * r * 2, l = p % 20 != 0 ? r * .18 : r * .32;
      c.drawLine(Offset(-l, yy), Offset(l, yy), _stroke(VC.ink300));
    }
    c.restore();
    c.drawCircle(Offset(cx, cy), r, _stroke(VC.hair));
    final wing = Path()
      ..moveTo(cx - r * .5, cy)
      ..lineTo(cx - r * .15, cy)
      ..lineTo(cx, cy + r * .1)
      ..lineTo(cx + r * .15, cy)
      ..lineTo(cx + r * .5, cy);
    c.drawPath(wing, _stroke(VC.lime, 2));
    c.drawPath(
      Path()
        ..moveTo(cx, cy - r + 2)
        ..lineTo(cx - 5, cy - r + 11)
        ..lineTo(cx + 5, cy - r + 11)
        ..close(),
      _fill(VC.lime),
    );
    c.save();
    c.translate(cx, cy);
    c.rotate(-t.rRoll);
    c.drawLine(Offset(0, -r + 12), Offset(0, -r + 20), _stroke(VC.white));
    c.restore();
  }
}

// ------------------------------------------------------------------ radar
class RadarPainter extends FramePainter {
  RadarPainter(super.dash, {this.range = 50});
  final double range;
  @override
  void paint(Canvas c, Size s) {
    final t = dash.tel;
    final R = math.min(s.width, s.height) / 2 - 6, cx = s.width / 2, cy = s.height / 2;
    if (R <= 0) return;
    final rg = dash.kind == DeviceKind.arm ? 3.0 : range;
    final hp = _stroke(VC.hair);
    for (var i = 1; i <= 4; i++) {
      c.drawCircle(Offset(cx, cy), R * i / 4, hp);
    }
    c.drawLine(Offset(cx - R, cy), Offset(cx + R, cy), hp);
    c.drawLine(Offset(cx, cy - R), Offset(cx, cy + R), hp);
    final sw = t.sweep;
    for (var i = 0; i < 24; i++) {
      final a = sw - i * .03;
      c.drawLine(
        Offset(cx, cy),
        Offset(cx + math.cos(a - math.pi / 2) * R, cy + math.sin(a - math.pi / 2) * R),
        _stroke(VC.lime.withValues(alpha: .22 * (1 - i / 24))),
      );
    }
    for (final g in t.targets) {
      final d = ((sw - g.a) % (math.pi * 2) + math.pi * 2) % (math.pi * 2);
      final al = math.max(.15, 1 - d / (math.pi * 2));
      final x = cx + math.cos(g.a - math.pi / 2) * g.r / rg * R, y = cy + math.sin(g.a - math.pi / 2) * g.r / rg * R;
      c.drawRect(Rect.fromLTWH(x - 3, y - 3, 6, 6), _fill(VC.warn.withValues(alpha: al)));
      drawText(c, g.id, Offset(x + 6, y - 6), VC.ink100.withValues(alpha: al));
    }
    drawText(c, rg < 10 ? '${rg.toStringAsFixed(0)} M' : '${rg.toStringAsFixed(0)}M', Offset(cx + 4, cy - R + 10), VC.ink300);
  }
}

// ------------------------------------------------------------------ track map
class TrackMapPainter extends FramePainter {
  TrackMapPainter(super.dash);
  @override
  void paint(Canvas c, Size s) {
    final t = dash.tel, w = s.width, h = s.height;
    final p = t.rPos, sc = math.min(w, h) / 70;
    double X(double x) => w / 2 + (x - p[0]) * sc;
    double Y(double y) => h / 2 - (y - p[1]) * sc;
    final gp = _stroke(VC.hair2);
    const g = 10.0;
    for (var x = ((p[0] - w / sc / 2) / g).floor() * g; x < p[0] + w / sc / 2; x += g) {
      c.drawLine(Offset(X(x), 0), Offset(X(x), h), gp);
    }
    for (var y = ((p[1] - h / sc / 2) / g).floor() * g; y < p[1] + h / sc / 2; y += g) {
      c.drawLine(Offset(0, Y(y)), Offset(w, Y(y)), gp);
    }
    c.drawCircle(Offset(X(0), Y(0)), 5, _stroke(VC.ink300));
    drawText(c, 'HOME', Offset(X(0) + 8, Y(0) + 3), VC.ink300);
    if (t.trail.length > 1) {
      final path = Path()..moveTo(X(t.trail[0][0]), Y(t.trail[0][1]));
      for (final q in t.trail.skip(1)) {
        path.lineTo(X(q[0]), Y(q[1]));
      }
      c.drawPath(path, _stroke(VC.lime.withValues(alpha: .5), 1.5));
    }
    c.save();
    c.translate(w / 2, h / 2);
    c.rotate(-t.rYaw);
    c.drawPath(
      Path()
        ..moveTo(9, 0)
        ..lineTo(-6, -6)
        ..lineTo(-3, 0)
        ..lineTo(-6, 6)
        ..close(),
      _fill(VC.lime),
    );
    c.restore();
  }
}

// ------------------------------------------------------------------ joints
class JointBarsPainter extends FramePainter {
  JointBarsPainter(super.dash);
  @override
  void paint(Canvas c, Size s) {
    final j = dash.tel.joints, w = s.width, rh = s.height / 6;
    for (var i = 0; i < 6 && i < j.length; i++) {
      final y = i * rh + rh / 2, L = 30.0, R = w - 56, mid = (L + R) / 2, sc = (R - L) / 2 / 3.2;
      drawText(c, 'J${i + 1}', Offset(0, y), VC.ink200, middle: true);
      c.drawRect(Rect.fromLTWH(L, y - 2, R - L, 4), _fill(VC.ink500));
      c.drawRect(Rect.fromLTWH(mid - .5, y - 6, 1, 12), _fill(VC.ink300));
      final x = mid + j[i] * sc;
      c.drawRect(Rect.fromLTWH(math.min(mid, x), y - 2, (x - mid).abs(), 4), _fill(VC.lime));
      c.drawRect(Rect.fromLTWH(x - 1, y - 6, 2, 12), _fill(VC.lime));
      drawText(c, '${(j[i] * 57.3).toStringAsFixed(1)}°', Offset(w, y), VC.white, align: TextAlign.right, middle: true);
    }
  }
}

// ------------------------------------------------------------------ custom channel bars
class ChannelBarsPainter extends FramePainter {
  ChannelBarsPainter(super.dash, this.id, this.axes);
  final String id;
  final List<String> axes;
  @override
  void paint(Canvas c, Size s) {
    final v = dash.tel.custom[id] ?? const [];
    final n = axes.length, rh = s.height / math.max(1, n);
    var mx = 1e-6;
    for (final x in v) {
      mx = math.max(mx, x.abs());
    }
    for (var i = 0; i < n; i++) {
      final y = i * rh + rh / 2, L = 30.0, R = s.width - 56;
      final val = i < v.length ? v[i] : 0.0;
      drawText(c, axes[i], Offset(0, y), VC.ink200, middle: true);
      c.drawRect(Rect.fromLTWH(L, y - 2, R - L, 4), _fill(VC.ink500));
      c.drawRect(Rect.fromLTWH(L, y - 2, (val.abs() / mx) * (R - L), 4), _fill(VC.lime));
      drawText(c, val.toStringAsFixed(1), Offset(s.width, y), VC.white, align: TextAlign.right, middle: true);
    }
  }
}
