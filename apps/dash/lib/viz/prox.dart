import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'viz.dart';

/// How close something is, as a colour: red within a quarter of the
/// sensor's range, amber within half, then lime.
Color proxColor(double d, double max) => d < max * .25
    ? VC.neg
    : d < max * .5
    ? VC.warn
    : VC.lime;

/// Proximity sensors from above, the device's forward up: a wedge per
/// sensor, its range faint, filled as far as it sees something, coloured by
/// how close; the distance at its end. Sensors looking down show as a
/// height bar on the right.
class ProxPainter extends FramePainter {
  ProxPainter(super.dash);

  @override
  void paint(Canvas c, Size s) {
    final sensors = dash.proxSensors, v = dash.tel.prox;
    final flat = [
      for (var i = 0; i < sensors.length && i < v.length; i++)
        if (!sensors[i].down) (sensors[i], v[i]),
    ];
    final down = [
      for (var i = 0; i < sensors.length && i < v.length; i++)
        if (sensors[i].down) (sensors[i], v[i]),
    ];
    final barW = down.isEmpty ? 0.0 : 46.0;
    final w = s.width - barW, cx = w / 2, cy = s.height / 2;
    final R = math.min(w, s.height) / 2 - 14;
    if (R <= 10) return;
    final range = flat.fold<double>(.5, (m, e) => math.max(m, e.$1.max));
    double px(double m) => m / range * R;

    // Range rings: every metre (every 10 cm under a metre).
    final step = range > 2 ? 1.0 : .1;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..color = VC.hair2;
    for (var r = step; r <= range + 1e-6; r += step) {
      c.drawCircle(Offset(cx, cy), px(r), ring);
    }
    drawText(c, '${range.toStringAsFixed(range < 2 ? 1 : 0)} m', Offset(cx + px(range) * .7071 + 3, cy - px(range) * .7071 - 6), VC.ink300);

    // Distances are labelled nearest first, skipping one that would overlap
    // a label already there (neighbours seeing the same thing).
    final labels = <Offset>[];
    final order = [...flat]..sort((a, b) => (a.$2 < 0 ? 1e9 : a.$2).compareTo(b.$2 < 0 ? 1e9 : b.$2));
    for (final (sn, d) in order) {
      // Clockwise from forward, forward up: screen angle from +x.
      final mid = sn.dir - math.pi / 2, half = math.max(sn.fov, .22) / 2;
      final rect = Rect.fromCircle(center: Offset(cx, cy), radius: px(sn.max));
      final outline = Path()
        ..moveTo(cx, cy)
        ..arcTo(rect, mid - half, half * 2, false)
        ..close();
      c.drawPath(outline, Paint()..color = VC.white.withValues(alpha: .04));
      c.drawPath(
        outline,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = VC.hair,
      );
      final end = Offset(cx + math.cos(mid) * px(sn.max) * 1.0, cy + math.sin(mid) * px(sn.max));
      if (d >= 0) {
        final col = proxColor(d, sn.max);
        final seen = Path()
          ..moveTo(cx, cy)
          ..arcTo(Rect.fromCircle(center: Offset(cx, cy), radius: px(d)), mid - half, half * 2, false)
          ..close();
        c.drawPath(seen, Paint()..color = col.withValues(alpha: .28));
        // The obstacle: an arc at the distance.
        c.drawArc(
          Rect.fromCircle(center: Offset(cx, cy), radius: px(d)),
          mid - half,
          half * 2,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5
            ..color = col,
        );
        final at = Offset(cx + math.cos(mid) * (px(d) + 14), cy + math.sin(mid) * (px(d) + 14));
        if (labels.every((o) => (o - at).distance > 26)) {
          labels.add(at);
          drawText(c, d.toStringAsFixed(2), at - const Offset(12, 0), col, middle: true);
        }
      } else if (R > 70) {
        drawText(c, '—', end - Offset(4 - math.cos(mid) * 8, -math.sin(mid) * 8), VC.ink300, middle: true);
      }
    }

    // The device: a small body pointing forward.
    final body = Path()
      ..moveTo(cx, cy - 9)
      ..lineTo(cx + 6, cy + 7)
      ..lineTo(cx, cy + 4)
      ..lineTo(cx - 6, cy + 7)
      ..close();
    c.drawPath(body, Paint()..color = VC.white);

    // Looking down: height above the ground.
    for (var i = 0; i < down.length; i++) {
      final (sn, d) = down[i];
      final x = w + 12.0 + i * 18, top = 14.0, bottom = s.height - 22;
      final track = Paint()..color = VC.white.withValues(alpha: .08);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(x, top, x + 8, bottom), const Radius.circular(2)), track);
      if (d >= 0) {
        final y = bottom - (d / sn.max).clamp(0.0, 1.0) * (bottom - top);
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(x, y, x + 8, bottom), const Radius.circular(2)), Paint()..color = VC.info);
      }
      drawText(c, d >= 0 ? '↓${d.toStringAsFixed(1)}' : '↓ —', Offset(x - 8, bottom + 10), VC.ink100, middle: true);
    }
  }
}
