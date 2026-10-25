import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../core/model.dart';

/// Pose of the simulated camera, read every frame.
class CamPose {
  CamPose(this.pos, this.yaw, this.pitch, this.roll);
  final List<double> pos;
  final double yaw, pitch, roll;
}

/// A simulated onboard camera: an HTTP server on the loopback interface
/// that streams `multipart/x-mixed-replace` frames, exactly like an
/// ESP32-CAM or mjpg-streamer. The app's real video client connects to it,
/// so the whole video path is exercised. Frames are rendered from the
/// simulated world (ground, sky, the point-cloud scenery) and encoded as PNG.
class SimCamera {
  SimCamera({required this.kind, required this.pose, required this.world, required this.osd, double Function()? now}) : now = now ?? _since();
  final DeviceKind kind;
  final CamPose Function() pose;
  final List<List<double>> world;
  final String Function() osd;

  /// Seconds, for what moves in the scene.
  final double Function() now;
  static double Function() _since() {
    final sw = Stopwatch()..start();
    return () => sw.elapsedMicroseconds / 1e6;
  }

  /// Something to track near home: a yellow ball (30 in OpenCV's hue, the
  /// colour tracker's default) rolling a figure of eight east of home, at
  /// most about 0.7 m/s, so a rover can keep it in view.
  static const ballRadius = .35;
  static List<double> ballAt(double t) => [6 + 4 * math.sin(.1 * t), 2 + 3 * math.sin(.2 * t), ballRadius];

  /// Someone to follow: a person in a red shirt walking a 10 m circle round
  /// home at 1.1 m/s. Where their feet are, and which way they walk.
  static (List<double>, double) personAt(double t) {
    const r = 10.0, w = 1.1 / r;
    final a = w * t;
    return ([r * math.cos(a), r * math.sin(a), 0], a + math.pi / 2);
  }

  static const w = 480, h = 270, fps = 12;
  static const boundary = 'kdashframe';

  HttpServer? _server;
  int _clients = 0;

  /// URL to declare in `hello`, valid once [start] has completed.
  String get url => 'http://127.0.0.1:${_server?.port ?? 0}/stream';
  bool get running => _server != null;

  Future<void> start() async {
    if (_server != null) return;
    final s = _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    s.listen(_serve, onError: (_) {});
  }

  Future<void> stop() async {
    final s = _server;
    _server = null;
    await s?.close(force: true);
  }

  Future<void> _serve(HttpRequest req) async {
    final res = req.response;
    if (req.uri.path == '/snapshot') {
      res.headers.contentType = ContentType('image', 'png');
      res.add(await render());
      await res.close();
      return;
    }
    if (req.uri.path != '/stream') {
      res.statusCode = HttpStatus.notFound;
      await res.close();
      return;
    }
    res.bufferOutput = false;
    res.headers.set(HttpHeaders.contentTypeHeader, 'multipart/x-mixed-replace; boundary=$boundary');
    res.headers.set(HttpHeaders.cacheControlHeader, 'no-cache');
    _clients++;
    var open = true;
    unawaited(res.done.then((_) => open = false, onError: (_) => open = false));
    try {
      while (open && _server != null) {
        final t0 = DateTime.now();
        final png = await render();
        res.add('--$boundary\r\nContent-Type: image/png\r\nContent-Length: ${png.length}\r\n\r\n'.codeUnits);
        res.add(png);
        res.add('\r\n'.codeUnits);
        await res.flush();
        final wait = const Duration(milliseconds: 1000 ~/ fps) - DateTime.now().difference(t0);
        if (wait > Duration.zero) await Future<void>.delayed(wait);
      }
    } catch (_) {
      // client went away
    } finally {
      _clients--;
      try {
        await res.close();
      } catch (_) {}
    }
  }

  int get clients => _clients;

  /// One frame as PNG bytes.
  Future<Uint8List> render() async {
    final rec = ui.PictureRecorder();
    paint(Canvas(rec), const Size(w * 1.0, h * 1.0));
    final img = await rec.endRecording().toImage(w, h);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    img.dispose();
    return bytes!.buffer.asUint8List();
  }

  /// Draws the camera view: sky, ground grid, home pad and scenery.
  void paint(Canvas c, Size s) {
    final p = pose();
    final cy = math.cos(p.yaw), sy = math.sin(p.yaw), cp = math.cos(p.pitch), sp = math.sin(p.pitch);
    // Camera basis: forward F, right R, up U (roll applied around F).
    final f = [cy * cp, sy * cp, sp];
    final r0 = [sy, -cy, 0.0], u0 = [-cy * sp, -sy * sp, cp];
    final cr = math.cos(p.roll), sr = math.sin(p.roll);
    final r = [for (var i = 0; i < 3; i++) r0[i] * cr - u0[i] * sr];
    final u = [for (var i = 0; i < 3; i++) u0[i] * cr + r0[i] * sr];
    final fl = s.width * .55; // ~ 85° horizontal field of view
    const near = .15;

    List<double> cam(List<double> q) {
      final d = [q[0] - p.pos[0], q[1] - p.pos[1], q[2] - p.pos[2]];
      return [d[0] * r[0] + d[1] * r[1] + d[2] * r[2], d[0] * f[0] + d[1] * f[1] + d[2] * f[2], d[0] * u[0] + d[1] * u[1] + d[2] * u[2]];
    }

    Offset scr(List<double> c3) => Offset(s.width / 2 + c3[0] * fl / c3[1], s.height / 2 - c3[2] * fl / c3[1]);

    // Sky.
    c.drawRect(Offset.zero & s, Paint()..shader = ui.Gradient.linear(Offset.zero, Offset(0, s.height), const [Color(0xFF2A3644), Color(0xFF6D7F92)]));

    // Ground: a large square clipped against the near plane.
    final big = 3000.0, gx = p.pos[0], gy = p.pos[1];
    final quad = [
      [gx - big, gy - big, 0.0],
      [gx + big, gy - big, 0.0],
      [gx + big, gy + big, 0.0],
      [gx - big, gy + big, 0.0],
    ].map(cam).toList();
    final poly = _clip(quad, near);
    if (poly.length >= 3) {
      final path = Path()..addPolygon([for (final q in poly) scr(q)], true);
      c.drawPath(path, Paint()..color = kind == DeviceKind.rover ? const Color(0xFF3F3A33) : const Color(0xFF3D4734));
    }

    // Ground grid every 5 m around the camera.
    final grid = Paint()
      ..color = const Color(0x33FFFFFF)
      ..strokeWidth = 1;
    const step = 5.0, n = 24;
    final ox = (gx / step).round() * step, oy = (gy / step).round() * step;
    for (var i = -n; i <= n; i++) {
      _seg(c, cam([ox + i * step, oy - n * step, 0]), cam([ox + i * step, oy + n * step, 0]), near, scr, grid);
      _seg(c, cam([ox - n * step, oy + i * step, 0]), cam([ox + n * step, oy + i * step, 0]), near, scr, grid);
    }

    // Home pad: white, so colour trackers see the ball, not the pad (lime
    // is inside their yellow).
    final pad = Paint()
      ..color = const Color(0xCCF2F2F2)
      ..strokeWidth = 2;
    for (var i = 0; i < 24; i++) {
      final a0 = i / 24 * math.pi * 2, a1 = (i + 1) / 24 * math.pi * 2;
      _seg(c, cam([math.cos(a0) * 1.5, math.sin(a0) * 1.5, 0]), cam([math.cos(a1) * 1.5, math.sin(a1) * 1.5, 0]), near, scr, pad);
    }
    _seg(c, cam([-1, 0, 0]), cam([1, 0, 0]), near, scr, pad);
    _seg(c, cam([0, -1, 0]), cam([0, 1, 0]), near, scr, pad);

    // Scenery: the simulated point cloud, bigger and brighter when close.
    final dots = <double, List<Offset>>{};
    for (final q in world) {
      final c3 = cam(q);
      if (c3[1] < near || c3[1] > 120) continue;
      final o = scr(c3);
      if (o.dx < -4 || o.dy < -4 || o.dx > s.width + 4 || o.dy > s.height + 4) continue;
      final b = (c3[1] < 8
          ? 3.0
          : c3[1] < 25
          ? 2.0
          : 1.0);
      (dots[b] ??= []).add(o);
    }
    for (final e in dots.entries) {
      c.drawPoints(
        ui.PointMode.points,
        e.value,
        Paint()
          ..color = Color.fromRGBO(226, 232, 214, e.key == 1 ? .45 : .8)
          ..strokeWidth = e.key
          ..strokeCap = StrokeCap.round,
      );
    }

    // What moves: the ball and the person, farthest first.
    final t = now();
    final ball = ballAt(t);
    final (feet, _) = personAt(t);
    final things = [(cam(ball), true), (cam(feet), false)]..sort((a, b) => b.$1[1].compareTo(a.$1[1]));
    for (final (c3, isBall) in things) {
      if (c3[1] < near + .3 || c3[1] > 80) continue;
      isBall ? _ball(c, c3, scr, fl, cam) : _person(c, c3, scr, fl, t);
    }

    // Lens vignette and on-screen display.
    c.drawRect(
      Offset.zero & s,
      Paint()..shader = ui.Gradient.radial(s.center(Offset.zero), s.width * .75, const [Color(0x00000000), Color(0x8C000000)], const [.55, 1]),
    );
    final tp = TextPainter(
      text: TextSpan(
        text: osd(),
        style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 9, color: Color(0xE6FFFFFF), letterSpacing: .5),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: s.width - 16);
    tp.paint(c, Offset((s.width - tp.width) / 2, s.height * .1));
    tp.dispose();
    // Centre mark.
    final cm = Paint()
      ..color = const Color(0x99FFFFFF)
      ..strokeWidth = 1;
    final m = s.center(Offset.zero);
    c.drawLine(m - const Offset(10, 0), m - const Offset(4, 0), cm);
    c.drawLine(m + const Offset(4, 0), m + const Offset(10, 0), cm);
  }

  /// The ball, shaded, with its shadow on the ground.
  void _ball(Canvas c, List<double> c3, Offset Function(List<double>) scr, double fl, List<double> Function(List<double>) cam) {
    final o = scr(c3), rad = ballRadius * fl / c3[1];
    final b = ballAt(now());
    final g = cam([b[0], b[1], 0]);
    if (g[1] > .3) {
      final go = scr(g);
      c.drawOval(Rect.fromCenter(center: go, width: rad * 2.2, height: rad * .7), Paint()..color = const Color(0x55000000));
    }
    c.drawCircle(
      o,
      rad,
      Paint()
        ..shader = ui.Gradient.radial(
          o - Offset(rad * .35, rad * .35),
          rad * 1.3,
          const [Color(0xFFFFE066), Color(0xFFF2C21B), Color(0xFF9C7A0C)],
          const [0, .45, 1],
        ),
    );
  }

  /// A person, feet at [c3]: legs that swing as they walk, a red shirt, a head.
  void _person(Canvas c, List<double> c3, Offset Function(List<double>) scr, double fl, double t) {
    final k = fl / c3[1]; // pixels per metre at their distance
    final foot = scr(c3);
    Offset at(double up, double side) => foot + Offset(side * k, -up * k);
    final swing = math.sin(t * 5.5) * .14;
    final leg = Paint()
      ..color = const Color(0xFF2B3A55)
      ..strokeWidth = math.max(1, .16 * k)
      ..strokeCap = StrokeCap.round;
    c.drawLine(at(.9, -.09), at(0, -.09 + swing), leg);
    c.drawLine(at(.9, .09), at(0, .09 - swing), leg);
    final arm = Paint()
      ..color = const Color(0xFFB4302A)
      ..strokeWidth = math.max(1, .1 * k)
      ..strokeCap = StrokeCap.round;
    c.drawLine(at(1.42, -.24), at(.95, -.26 - swing), arm);
    c.drawLine(at(1.42, .24), at(.95, .26 + swing), arm);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromPoints(at(1.5, -.24), at(.86, .24)), Radius.circular(.08 * k)), Paint()..color = const Color(0xFFC8372D));
    c.drawCircle(at(1.64, 0), .13 * k, Paint()..color = const Color(0xFFD9A47F));
  }

  static void _seg(Canvas c, List<double> a, List<double> b, double near, Offset Function(List<double>) scr, Paint p) {
    if (a[1] < near && b[1] < near) return;
    if (a[1] < near || b[1] < near) {
      final k = (near - a[1]) / (b[1] - a[1]);
      final m = [for (var i = 0; i < 3; i++) a[i] + (b[i] - a[i]) * k];
      if (a[1] < near) {
        a = m;
      } else {
        b = m;
      }
    }
    c.drawLine(scr(a), scr(b), p);
  }

  /// Sutherland–Hodgman against depth >= near.
  static List<List<double>> _clip(List<List<double>> poly, double near) {
    final out = <List<double>>[];
    for (var i = 0; i < poly.length; i++) {
      final a = poly[i], b = poly[(i + 1) % poly.length];
      final ain = a[1] >= near, bin = b[1] >= near;
      if (ain) out.add(a);
      if (ain != bin) {
        final k = (near - a[1]) / (b[1] - a[1]);
        out.add([for (var j = 0; j < 3; j++) a[j] + (b[j] - a[j]) * k]);
      }
    }
    return out;
  }
}
