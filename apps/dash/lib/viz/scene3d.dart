import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../core/dash.dart';
import '../core/model.dart';
import '../ui/components.dart' show f1;
import 'viz.dart';

class _Cam {
  double yaw = -.6, pitch = .55, dist = 60;
  List<double> target = [0, 0, 0];
  bool user = false;
}

/// Wireframe 3D view: grid, lidar point cloud, trajectory, radar tracks and
/// the device model. Views: orbit, chase, top. Drag to orbit, scroll or
/// pinch to zoom, double-tap to return to the automatic camera.
class Scene3D extends StatefulWidget {
  const Scene3D(this.dash, {super.key, this.view = 'orbit', this.layers, this.interactive = true, this.label = true});
  final Dash dash;
  final String view;
  final Map<String, bool>? layers;
  final bool interactive, label;
  @override
  State<Scene3D> createState() => _Scene3DState();
}

class _Scene3DState extends State<Scene3D> {
  final cam = _Cam();
  double _scaleStart = 60;

  @override
  void didUpdateWidget(Scene3D old) {
    super.didUpdateWidget(old);
    if (old.view != widget.view) cam.user = false;
  }

  @override
  Widget build(BuildContext context) {
    final paint = RepaintBoundary(
      child: CustomPaint(
        size: Size.infinite,
        painter: _ScenePainter(widget.dash, cam, widget.view, widget.layers ?? const {'cloud': true, 'trail': true, 'grid': true, 'radar': true}, widget.label),
      ),
    );
    if (!widget.interactive) return paint;
    return Listener(
      onPointerSignal: (e) {
        if (e is PointerScrollEvent) {
          cam.user = true;
          cam.dist = (cam.dist * (1 + e.scrollDelta.dy * .001)).clamp(1.5, 150);
        }
      },
      child: GestureDetector(
        onDoubleTap: () => cam.user = false,
        onScaleStart: (_) => _scaleStart = cam.dist,
        onScaleUpdate: (d) {
          cam.user = true;
          if (d.pointerCount > 1) {
            cam.dist = (_scaleStart / d.scale).clamp(1.5, 150);
          } else {
            cam.yaw -= d.focalPointDelta.dx * .008;
            cam.pitch = (cam.pitch + d.focalPointDelta.dy * .006).clamp(.05, 1.55);
          }
        },
        child: MouseRegion(cursor: SystemMouseCursors.grab, child: paint),
      ),
    );
  }
}

class _ScenePainter extends FramePainter {
  _ScenePainter(super.dash, this.cam, this.view, this.layers, this.label);
  final _Cam cam;
  final String view;
  final Map<String, bool> layers;
  final bool label;

  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height;
    if (w <= 0 || h <= 0) return;
    c.clipRect(Offset.zero & s);
    final S = dash.tel, kind = dash.kind;
    final arm = kind == DeviceKind.arm || kind == DeviceKind.bench, isArm = kind == DeviceKind.arm;
    final focus = kind == DeviceKind.bench
        ? [0.0, 0, .45]
        : arm
        ? [0.0, 0, .6]
        : S.rPos;
    if (!cam.user) {
      double ty, tp, td;
      if (view == 'top') {
        ty = 0;
        tp = 1.5;
        td = arm ? 5 : 70;
      } else if (view == 'chase') {
        ty = arm || kind == DeviceKind.rocket ? -.6 : -S.rYaw + math.pi / 2;
        tp = .35;
        td = arm ? 4 : 22;
      } else {
        ty = cam.yaw + .0008;
        tp = .55;
        td = arm ? 4.6 : 55;
      }
      const k = .08;
      var dy = ty - cam.yaw;
      dy = math.atan2(math.sin(dy), math.cos(dy));
      cam.yaw += dy * k;
      cam.pitch += (tp - cam.pitch) * k;
      cam.dist += (td - cam.dist) * k;
    }
    cam.target = [for (var i = 0; i < 3; i++) cam.target[i] + (focus[i] - cam.target[i]) * .12];

    final cy = math.cos(cam.yaw), sy = math.sin(cam.yaw), cp = math.cos(cam.pitch), sp = math.sin(cam.pitch);
    final f = math.min(w, h) * 1.1, t = cam.target, dist = cam.dist;
    const near = .1;
    // Camera space: [x right, d depth, u up].
    List<double> C(List<double> p) {
      final x = p[0] - t[0], y = p[1] - t[1], z = p[2] - t[2];
      final x1 = cy * x + sy * y, y1 = -sy * x + cy * y;
      return [x1, y1 * cp - z * sp + dist, y1 * sp + z * cp];
    }

    List<double> proj(List<double> c) => [w / 2 + c[0] * f / c[1], h / 2 - c[2] * f / c[1], c[1]];

    // Projection: returns null behind the camera. [2] is depth.
    List<double>? P(List<double> p) {
      final c = C(p);
      return c[1] < near ? null : proj(c);
    }

    // Segments crossing the camera plane are clipped at the near plane instead
    // of dropped, so long grid lines stay visible at low, close camera angles.
    void line(Path path, List<double> a, List<double> b) {
      var ca = C(a), cb = C(b);
      if (ca[1] < near && cb[1] < near) return;
      if (ca[1] < near || cb[1] < near) {
        final k = (near - ca[1]) / (cb[1] - ca[1]);
        final m = [for (var i = 0; i < 3; i++) ca[i] + (cb[i] - ca[i]) * k];
        m[1] = near;
        if (ca[1] < near) {
          ca = m;
        } else {
          cb = m;
        }
      }
      final A = proj(ca), B = proj(cb);
      path
        ..moveTo(A[0], A[1])
        ..lineTo(B[0], B[1]);
    }

    Paint st(Color col, [double lw = 1]) => Paint()
      ..color = col
      ..style = PaintingStyle.stroke
      ..strokeWidth = lw;

    if (layers['grid'] ?? true) {
      final g = arm ? .5 : 5.0, n = arm ? 6 : 10;
      final ox = (focus[0] / g).round() * g, oy = (focus[1] / g).round() * g;
      final minor = Path(), major = Path();
      for (var i = -n; i <= n; i++) {
        final x = ox + i * g, y = oy + i * g;
        line((x / g).round() % 5 != 0 ? minor : major, [x, oy - n * g, 0], [x, oy + n * g, 0]);
        line((y / g).round() % 5 != 0 ? minor : major, [ox - n * g, y, 0], [ox + n * g, y, 0]);
      }
      c.drawPath(minor, st(const Color(0x24FFFFFF)));
      c.drawPath(major, st(const Color(0x4DFFFFFF)));
      final ax = Path(), ay = Path();
      line(ax, [0, 0, 0], [g * 2, 0, 0]);
      line(ay, [0, 0, 0], [0, g * 2, 0]);
      c.drawPath(ax, st(const Color(0x998FB9E0), 1.5));
      c.drawPath(ay, st(const Color(0x99EFC067), 1.5));
    }

    if (layers['cloud'] ?? true) {
      final R = arm ? 3.0 : 26.0, sw = S.sweep;
      final hot = <Offset>[], hotA = <double>[], cold = <Offset>[], coldA = <double>[];
      for (final q in S.cloud) {
        final dx = q[0] - focus[0], dy = q[1] - focus[1], dz = q[2] - focus[2];
        final d = math.sqrt(dx * dx + dy * dy + dz * dz);
        if (d > R) continue;
        final pr = P(q);
        if (pr == null) continue;
        final az = math.atan2(dx, dy);
        final dd = ((sw - az) % (math.pi * 2) + math.pi * 2) % (math.pi * 2);
        final al = 1 - d / R;
        if (dd < .5) {
          hot.add(Offset(pr[0], pr[1]));
          hotA.add(al);
        } else {
          cold.add(Offset(pr[0], pr[1]));
          coldA.add(al * .55 * .8);
        }
      }
      _points(c, cold, coldA, VC.white);
      _points(c, hot, hotA, VC.lime);
    }

    if ((layers['trail'] ?? true) && S.trail.length > 1) {
      final path = Path();
      var started = false;
      for (final q in S.trail) {
        final p = P(q);
        if (p == null) continue;
        started ? path.lineTo(p[0], p[1]) : path.moveTo(p[0], p[1]);
        started = true;
      }
      c.drawPath(path, st(VC.lime.withValues(alpha: .45), 1.5));
    }

    if ((layers['radar'] ?? true) && !arm) {
      for (final g in S.targets) {
        final p = P([S.rPos[0] + math.sin(g.a) * g.r, S.rPos[1] + math.cos(g.a) * g.r, 1.5]);
        if (p == null) continue;
        final sz = math.max(3.0, 120 / p[2]);
        c.drawRect(Rect.fromLTWH(p[0] - sz, p[1] - sz, sz * 2, sz * 2), st(VC.warn, 1.25));
        drawText(c, '${g.id} ${g.r.toStringAsFixed(0)}M', Offset(p[0] + sz + 4, p[1]), VC.warn);
      }
    }

    final model = Path();
    final lime2 = st(VC.lime, 2);
    switch (kind) {
      case DeviceKind.drone:
        final p = S.rPos, cyw = math.cos(S.rYaw), syw = math.sin(S.rYaw);
        const a = .9;
        final arms = [
          for (final uv in const [
            [a, a],
            [a, -a],
            [-a, a],
            [-a, -a],
          ])
            [p[0] + cyw * uv[0] - syw * uv[1], p[1] + syw * uv[0] + cyw * uv[1], p[2] + (uv[0] * S.rPitch * -1 + uv[1] * S.rRoll) * .6],
        ];
        line(model, arms[0], arms[3]);
        line(model, arms[1], arms[2]);
        c.drawPath(model, lime2);
        final rotors = Path();
        for (final q in arms) {
          _ring(rotors, P, q, .45, 16);
        }
        c.drawPath(rotors, st(VC.lime, 1.25));
        final drop = Path();
        line(drop, p, [p[0], p[1], 0]);
        c.drawPath(_dash(drop), st(const Color(0x40FFFFFF)));
        final hd = Path();
        line(hd, p, [p[0] + cyw * 2, p[1] + syw * 2, p[2]]);
        c.drawPath(hd, st(VC.white));
      case DeviceKind.rover:
        final p = S.rPos, cyw = math.cos(S.rYaw), syw = math.sin(S.rYaw);
        List<double> b(double u, double v, double z) => [p[0] + cyw * u - syw * v, p[1] + syw * u + cyw * v, z];
        const L = 1.2, W = .8, H = .6;
        final k = [b(L, W, 0), b(L, -W, 0), b(-L, -W, 0), b(-L, W, 0), b(L, W, H), b(L, -W, H), b(-L, -W, H), b(-L, W, H)];
        for (final e in const [
          [0, 1],
          [1, 2],
          [2, 3],
          [3, 0],
          [4, 5],
          [5, 6],
          [6, 7],
          [7, 4],
          [0, 4],
          [1, 5],
          [2, 6],
          [3, 7],
        ]) {
          line(model, k[e[0]], k[e[1]]);
        }
        c.drawPath(model, lime2);
        final hd = Path();
        line(hd, b(L, 0, H), b(L + 2, 0, H));
        c.drawPath(hd, st(VC.white));
      case DeviceKind.rocket:
        final p = S.rPos, ph = S.mode, chute = ph == 'DROGUE' || ph == 'MAIN';
        var d = [math.sin(S.rPitch) * .8, math.sin(S.rPitch) * .6, math.cos(S.rPitch)];
        if (chute) d = [math.sin(S.rRoll) * .5, math.sin(S.rPitch) * .5, 1];
        final n = hypot3(d[0], d[1], d[2]);
        d = [for (final x in d) x / n];
        const L = 2.4;
        final tip = [p[0] + d[0] * L, p[1] + d[1] * L, p[2] + d[2] * L];
        line(model, p, tip);
        c.drawPath(model, st(VC.lime, 3));
        final fins = Path();
        for (final uw in const [
          [.4, 0.0],
          [-.4, 0.0],
          [0.0, .4],
          [0.0, -.4],
        ]) {
          line(fins, p, [p[0] + uw[0], p[1] + uw[1], p[2] - .3]);
        }
        c.drawPath(fins, st(VC.lime, 1.5));
        final rail = Path();
        line(rail, [0, 0, 0], [0, 0, 3.5]);
        c.drawPath(rail, st(const Color(0x59FFFFFF)));
        if (ph == 'BOOST') {
          final fl = Path();
          line(fl, p, [p[0] - d[0] * 2.2, p[1] - d[1] * 2.2, p[2] - d[2] * 2.2]);
          c.drawPath(fl, st(VC.warn, 2));
        }
        if (chute) {
          final r = ph == 'MAIN' ? 2.2 : .8, top = [p[0], p[1], p[2] + (ph == 'MAIN' ? 7 : 4)];
          final ring = [
            for (var i = 0; i <= 16; i++) [top[0] + math.cos(i / 16 * 6.283) * r, top[1] + math.sin(i / 16 * 6.283) * r, top[2]],
          ];
          final canopy = Path();
          var s0 = false;
          for (final q in ring) {
            final pp = P(q);
            if (pp == null) continue;
            s0 ? canopy.lineTo(pp[0], pp[1]) : canopy.moveTo(pp[0], pp[1]);
            s0 = true;
          }
          c.drawPath(canopy, st(VC.white, 1.25));
          final lines = Path();
          for (var i = 0; i < ring.length; i += 4) {
            line(lines, ring[i], tip);
          }
          c.drawPath(lines, st(const Color(0x59FFFFFF)));
        }
        if (p[2] > 1) {
          final drop = Path();
          line(drop, p, [p[0], p[1], 0]);
          c.drawPath(_dash(drop), st(const Color(0x40FFFFFF)));
        }
      case DeviceKind.bench:
        for (final e in const [
          [
            [-.3, -.2, 0.0],
            [.3, -.2, 0.0],
          ],
          [
            [.3, -.2, 0.0],
            [.3, .2, 0.0],
          ],
          [
            [.3, .2, 0.0],
            [-.3, .2, 0.0],
          ],
          [
            [-.3, .2, 0.0],
            [-.3, -.2, 0.0],
          ],
          [
            [0.0, -.15, 0.0],
            [0.0, -.15, .5],
          ],
          [
            [0.0, .15, 0.0],
            [0.0, .15, .5],
          ],
          [
            [0.0, -.15, .5],
            [0.0, .15, .5],
          ],
        ]) {
          line(model, e[0], e[1]);
        }
        c.drawPath(model, lime2);
        final mc = P([0, 0, .56]);
        if (mc != null) c.drawRect(Rect.fromLTWH(mc[0] - 5, mc[1] - 5, 10, 10), Paint()..color = VC.lime);
        final hub = <double>[0, 0, .62], prop = Path();
        for (var bl = 0; bl < 2; bl++) {
          final an = S.propA + bl * math.pi;
          line(prop, [hub[0] - math.cos(an) * .25, hub[1] - math.sin(an) * .25, hub[2]], [hub[0] + math.cos(an) * .25, hub[1] + math.sin(an) * .25, hub[2]]);
        }
        c.drawPath(prop, st(VC.white, 2));
        if (S.rpm > 600) {
          final disc = Path();
          _ring(disc, P, hub, .25, 24);
          c.drawPath(disc, st(VC.lime.withValues(alpha: math.min(.6, S.rpm / 9000))));
        }
        if (S.rpm > 300) {
          final tl = math.min(.6, S.thrust / 40), arrow = Path();
          line(arrow, [0, 0, .66], [0, 0, .66 + tl]);
          c.drawPath(arrow, st(VC.lime.withValues(alpha: .5), 1.5));
        }
      default:
        final pts = S.rArmPts;
        for (var i = 1; i < pts.length; i++) {
          line(model, pts[i - 1], pts[i]);
        }
        c.drawPath(model, st(VC.lime, 3));
        for (final q in pts) {
          final p = P(q);
          if (p != null) c.drawCircle(Offset(p[0], p[1]), 3.5, Paint()..color = VC.lime);
        }
        final tip = pts[5], g = S.gripper * .08, gr = Path();
        line(gr, [tip[0], tip[1] - g, tip[2]], [tip[0], tip[1] + g, tip[2]]);
        c.drawPath(gr, st(VC.white, 2));
    }

    if (label) {
      final p = P(
        isArm
            ? S.rArmPts[5]
            : kind == DeviceKind.bench
            ? [0, 0, .7]
            : S.rPos,
      );
      if (p != null) {
        drawText(c, dash.deviceName.toUpperCase(), Offset(p[0] + 14, p[1] - 12), VC.white);
        final sub = isArm
            ? 'Z ${S.armPts[5][2].toStringAsFixed(2)}M'
            : kind == DeviceKind.bench
            ? 'THRUST ${S.thrust.toStringAsFixed(1)}N · ${S.rpm.round()} RPM'
            : kind == DeviceKind.rocket
            ? '${S.mode} · ALT ${S.pos[2].toStringAsFixed(0)}M · ${f1(S.vel[2], 0)}M/S'
            : 'ALT ${S.pos[2].toStringAsFixed(1)}M · ${S.speed.toStringAsFixed(1)}M/S';
        drawText(c, sub, Offset(p[0] + 14, p[1] + 2), VC.ink200);
      }
    }
  }

  void _ring(Path path, List<double>? Function(List<double>) P, List<double> q, double r, int n) {
    var s0 = false;
    for (var i = 0; i <= n; i++) {
      final an = i / n * 6.283;
      final pp = P([q[0] + math.cos(an) * r, q[1] + math.sin(an) * r, q[2]]);
      if (pp == null) continue;
      s0 ? path.lineTo(pp[0], pp[1]) : path.moveTo(pp[0], pp[1]);
      s0 = true;
    }
  }

  /// Draws points bucketed by alpha to keep draw calls low.
  void _points(Canvas c, List<Offset> pts, List<double> alphas, Color col) {
    final buckets = List.generate(6, (_) => <Offset>[]);
    for (var i = 0; i < pts.length; i++) {
      buckets[(alphas[i] * 5.999).floor().clamp(0, 5)].add(pts[i]);
    }
    for (var b = 0; b < 6; b++) {
      if (buckets[b].isEmpty) continue;
      c.drawPoints(
        ui.PointMode.points,
        buckets[b],
        Paint()
          ..color = col.withValues(alpha: (b + .5) / 6)
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.square,
      );
    }
  }

  Path _dash(Path src) {
    final out = Path();
    for (final m in src.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 6) {
        out.addPath(m.extractPath(d, math.min(d + 2, m.length)), Offset.zero);
      }
    }
    return out;
  }
}
