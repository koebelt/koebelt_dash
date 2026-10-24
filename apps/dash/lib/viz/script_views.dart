import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../scripts/views.dart';
import '../theme/tokens.dart';
import 'viz.dart';

/// A picture or a chart a script shows (dev.show, dev.chart), as a Live
/// widget: it repaints when the script sends a new one.
class ScriptViewBody extends StatelessWidget {
  const ScriptViewBody(this.view, {super.key});
  final ScriptView view;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: view,
    builder: (context, _) => Stack(
      fit: StackFit.expand,
      children: [
        if (view.kind == 'chart')
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 8, 10, 4),
            child: CustomPaint(painter: _ChartPainter(view, view.version)),
          )
        else
          ColoredBox(
            color: K.surfaceDeep,
            child: view.image == null
                ? Center(child: Text('Waiting for the script', style: KText.label(size: 10, color: K.textFaint)))
                : Image.memory(view.image!, fit: BoxFit.contain, gaplessPlayback: true, filterQuality: FilterQuality.medium),
          ),
        if (view.ended)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(color: K.inkA70, borderRadius: BorderRadius.circular(K.radiusControl)),
              child: Text('SCRIPT ENDED', style: KText.label(size: 9, color: K.textMuted)),
            ),
          ),
      ],
    ),
  );
}

/// Colours of a chart's series, as Live's charts use them.
const scriptSeriesColors = [VC.lime, VC.info, VC.warn, VC.pos, VC.neg, VC.white, VC.ink100, VC.ink200];

Paint _line(Color c, [double w = 1]) => Paint()
  ..color = c
  ..strokeWidth = w
  ..style = PaintingStyle.stroke;

/// A whole chart from a script: line, bar or scatter, with its series named
/// in a legend.
class _ChartPainter extends CustomPainter {
  _ChartPainter(this.v, this.version);
  final ScriptView v;
  final int version;

  @override
  void paint(Canvas c, Size s) {
    final series = v.series.entries.where((e) => e.value.isNotEmpty).toList();
    if (series.isEmpty || s.width < 40 || s.height < 30) return;
    final n = series.map((e) => e.value.length).reduce(math.max);
    final xs = v.x != null && v.x!.length >= n ? v.x! : [for (var i = 0; i < n; i++) i.toDouble()];
    final bar = v.chart == 'bar';

    var lo = double.infinity, hi = double.negativeInfinity;
    for (final e in series) {
      for (final y in e.value) {
        if (!y.isFinite) continue;
        lo = math.min(lo, y);
        hi = math.max(hi, y);
      }
    }
    if (!lo.isFinite) return;
    if (bar) {
      lo = math.min(lo, 0);
      hi = math.max(hi, 0);
    }
    if (hi == lo) {
      hi += 1;
      lo -= 1;
    }
    final pad = (hi - lo) * .08;
    if (!bar || lo < 0) lo -= pad;
    hi += pad;
    var x0 = double.infinity, x1 = double.negativeInfinity;
    for (final x in xs.take(n)) {
      if (!x.isFinite) continue;
      x0 = math.min(x0, x);
      x1 = math.max(x1, x);
    }
    if (!x0.isFinite || x0 == x1) {
      x0 = 0;
      x1 = math.max(1, n - 1).toDouble();
    }

    // Plot area: values on the left, x range and axis names below, legend on top.
    const L = 34.0, B = 16.0;
    final top = series.length > 1 || v.yLabel.isNotEmpty ? 16.0 : 4.0;
    final w = s.width - L, h = s.height - B - top;
    if (w <= 0 || h <= 0) return;
    double py(double y) => top + h - (y - lo) / (hi - lo) * h;
    final slot = w / n;
    double px(int i) => bar ? L + slot * (i + .5) : L + (xs[i] - x0) / (x1 - x0) * w;

    String fmt(double x) {
      final a = x.abs();
      return a >= 1000 || (a < .01 && a > 0) ? x.toStringAsExponential(1) : x.toStringAsFixed(a < 10 && x != x.roundToDouble() ? 1 : 0);
    }

    final grid = _line(VC.hair2);
    for (var i = 0; i <= 3; i++) {
      final y = lo + (hi - lo) * i / 3;
      c.drawLine(Offset(L, py(y)), Offset(s.width, py(y)), grid);
      drawText(c, fmt(y), Offset(0, py(y)), VC.ink300, middle: true);
    }
    if (lo < 0 && hi > 0) c.drawLine(Offset(L, py(0)), Offset(s.width, py(0)), _line(VC.hair));

    for (var k = 0; k < series.length; k++) {
      final ys = series[k].value, col = scriptSeriesColors[k % scriptSeriesColors.length];
      if (bar) {
        final bw = slot * .8 / series.length;
        final fill = Paint()..color = col.withValues(alpha: .85);
        for (var i = 0; i < ys.length; i++) {
          if (!ys[i].isFinite) continue;
          final left = L + slot * i + slot * .1 + bw * k;
          c.drawRect(Rect.fromLTRB(left, math.min(py(ys[i]), py(math.max(lo, 0))), left + math.max(1, bw - 1), math.max(py(ys[i]), py(math.max(lo, 0)))), fill);
        }
      } else if (v.chart == 'scatter') {
        final dot = Paint()..color = col.withValues(alpha: .9);
        for (var i = 0; i < ys.length && i < xs.length; i++) {
          if (ys[i].isFinite && xs[i].isFinite) c.drawCircle(Offset(px(i), py(ys[i])), 2.2, dot);
        }
      } else {
        final p = Path();
        var on = false;
        for (var i = 0; i < ys.length && i < xs.length; i++) {
          if (!ys[i].isFinite || !xs[i].isFinite) {
            on = false;
            continue;
          }
          on ? p.lineTo(px(i), py(ys[i])) : p.moveTo(px(i), py(ys[i]));
          on = true;
        }
        c.drawPath(p, _line(col, 1.4));
      }
    }

    // The x range, and the axes' names.
    final by = s.height - B / 2;
    drawText(c, bar ? '' : fmt(x0), Offset(L, by), VC.ink300, middle: true);
    if (!bar) drawText(c, fmt(x1), Offset(s.width, by), VC.ink300, middle: true, align: TextAlign.right);
    // The x axis's name in the middle (mono: 6 px a character).
    if (v.xLabel.isNotEmpty) drawText(c, v.xLabel.toUpperCase(), Offset(L + w / 2 - v.xLabel.length * 3, by), VC.ink200, middle: true);
    if (v.yLabel.isNotEmpty) drawText(c, v.yLabel.toUpperCase(), Offset(L, 6), VC.ink200, middle: true);
    if (series.length > 1) {
      var lx = s.width;
      for (var k = series.length - 1; k >= 0; k--) {
        final name = series[k].key.toUpperCase();
        final tw = name.length * 6.0 + 4;
        lx -= tw;
        drawText(c, name, Offset(lx, 6), VC.ink100, middle: true);
        lx -= 10;
        c.drawRect(Rect.fromLTWH(lx, 5, 6, 2), Paint()..color = scriptSeriesColors[k % scriptSeriesColors.length]);
        lx -= 10;
      }
    }
  }

  @override
  bool shouldRepaint(_ChartPainter o) => o.version != version || o.v != v;
}
