// The koebelt/dash mark (H1: six isometric axes and a lime hub) and its
// motion, ported from the design's logo-motion.js / Logo Motion.html.
//
// Static: [Mark], [Brand]. Animated: [MarkMotion] with the loops the design
// assigns: boot (app launch), loading, progress, searching (pairing),
// link lost, and the gizmo (empty states). [orientationGizmo] draws the
// mark as an axis gizmo for a 3D camera.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../theme/tokens.dart';

// ------------------------------------------------------------------ geometry
typedef V3 = List<double>;

const _cm = Color(0xFFFFFFFF), _ctn = Color(0xFFB4AFB0), _ca = Color(0xFFDCFB47), _cdim = Color(0xFF3E393A);

double _r(double d) => d * math.pi / 180;
double _clamp(double v, [double a = 0, double b = 1]) => v < a ? a : (v > b ? b : v);
double _lerp(double a, double b, double t) => a + (b - a) * t;
final _ease = const Cubic(.2, .8, .2, 1).transform;
double _eio(double t) => t < .5 ? 4 * t * t * t : 1 - math.pow(-2 * t + 2, 3) / 2;
Color _mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;

final _t30 = math.tan(_r(30));

/// One arm of the mark, pointing at [deg], as a 6-point polygon in mark units
/// (the mark spans −100…100). [q] scales it to a projected length.
List<Offset> markArm(double deg, {double? q, double w = 30}) {
  final qq = q ?? 1, len = q != null ? 100 * qq : 100.0, a0 = (w / 2) / _t30, yy = (22 - 8) * _t30;
  final u = Offset(math.cos(_r(deg)), math.sin(_r(deg))), p = Offset(-u.dy, u.dx);
  Offset pt(double a, double b) => u * a + p * b;
  final s = q != null ? math.min(1.0, qq / .4) : 1.0;
  return [pt(22 * s, yy), pt((8 + a0) * s, w / 2), pt(len, w / 2), pt(len, -w / 2), pt((8 + a0) * s, -w / 2), pt(22 * s, -yy)];
}

List<Offset> markHex([double s = 1]) => [
  for (final a in const [-60, 0, 60, 120, 180, 240]) Offset(16.17 * s * math.cos(_r(a.toDouble())), 16.17 * s * math.sin(_r(a.toDouble()))),
];

/// Arms facing the viewer are white, facing away grey.
Color markTone(double z) {
  final g = _clamp(217.5 + 65 * z, 140, 255), k = (255 - g) / 75;
  return Color.fromARGB(255, g.round(), (g - 5 * k).round(), (g - 4 * k).round());
}

class MarkPiece {
  const MarkPiece(this.pts, this.color, [this.opacity = 1]);
  final List<Offset> pts;
  final Color color;
  final double opacity;
}

V3 _n(V3 v) {
  final l = math.sqrt(v[0] * v[0] + v[1] * v[1] + v[2] * v[2]);
  return [v[0] / l, v[1] / l, v[2] / l];
}

double _d(V3 a, V3 b) => a[0] * b[0] + a[1] * b[1] + a[2] * b[2];
V3 _cr(V3 a, V3 b) => [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]];
V3 _ad(V3 a, V3 b, [double s = 1]) => [a[0] + b[0] * s, a[1] + b[1] * s, a[2] + b[2] * s];
V3 _sc(V3 a, double s) => [a[0] * s, a[1] * s, a[2] * s];
double _len(V3 a) => math.sqrt(_d(a, a));

V3 _rotA(V3 v, V3 axis, double an) {
  final ax = _n(axis), c = math.cos(an), s = math.sin(an), d = _d(ax, v), cr = _cr(ax, v);
  return [for (var i = 0; i < 3; i++) v[i] * c + cr[i] * s + ax[i] * d * (1 - c)];
}

V3 _slerp(V3 a, V3 b, double t) {
  final w = math.acos(_clamp(_d(a, b), -1, 1));
  if (w < 1e-3) return _n([for (var i = 0; i < 3; i++) _lerp(a[i], b[i], t)]);
  var ax = _cr(a, b);
  if (_len(ax) < 1e-4) ax = _cr(a, a[0].abs() < .9 ? [1, 0, 0] : [0, 1, 0]);
  return _rotA(a, ax, w * t);
}

V3 _rz(V3 v, double a) => [v[0] * math.cos(a) - v[1] * math.sin(a), v[0] * math.sin(a) + v[1] * math.cos(a), v[2]];

final V3 _cam = _n([1, 1, 1]), _rt = _n([-1, 1, 0]);
final V3 _up = _cr(_cam, _rt);
final double _kk = 100 / math.sqrt(2 / 3);

/// Screen position (mark units) and perspective factor of a 3D point.
(Offset, double) _proj(V3 p, double persp) {
  final f = _lerp(1, 4.5 / (4.5 - _d(p, _cam)), persp);
  return (Offset(_d(p, _rt) * _kk * f, -_d(p, _up) * _kk * f), f);
}

const List<V3> _rest = [
  [0, 0, 1],
  [0, -1, 0],
  [1, 0, 0],
  [0, 0, -1],
  [0, 1, 0],
  [-1, 0, 0],
];
const _one = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0];
List<V3> _turn(double a) => [for (final v in _rest) _rz(v, a)];
List<V3> _dup(List<V3> a, List<int> ix) => [...a, for (final i in ix) a[i]];
V3 _scr(double th, double dep) => _n(_ad(_ad(_sc(_rt, math.cos(_r(th))), _up, math.sin(_r(th))), _cam, dep));

List<V3> _frustum(V3 look, double hfov) {
  final u = _n(_cr(look, [0, 0, 1])), v = _cr(u, look), th = math.tan(_r(hfov)), tv = math.tan(_r(hfov * .62));
  return _dup(
    [
      for (final ab in const [
        [1, 1],
        [-1, 1],
        [-1, -1],
        [1, -1],
      ])
        _n(_ad(_ad(look, u, ab[0] * th), v, ab[1] * tv)),
    ],
    [0, 2],
  );
}

// ------------------------------------------------------------------ painting
class _MarkPainter extends CustomPainter {
  _MarkPainter(this.pieces, {this.gap, this.pad = 110, super.repaint});
  final List<MarkPiece> Function() pieces;
  final Color? gap;
  final double pad;

  @override
  void paint(Canvas c, Size s) {
    final k = s.shortestSide / (pad * 2);
    c.save();
    c.translate(s.width / 2, s.height / 2);
    c.scale(k);
    final ps = pieces();
    for (final p in ps) {
      if (p.opacity <= 0) continue;
      final path = Path()..addPolygon(p.pts, true);
      if (gap != null) {
        c.drawPath(
          path,
          Paint()
            ..color = gap!.withValues(alpha: p.opacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 16
            ..strokeJoin = StrokeJoin.round,
        );
      }
      c.drawPath(path, Paint()..color = p.color.withValues(alpha: p.opacity));
    }
    c.restore();
  }

  @override
  bool shouldRepaint(covariant _MarkPainter o) => true;
}

/// The mark as the brand SVG draws it.
List<MarkPiece> staticMark({Color hub = _ca, Color pos = _cm, Color neg = _ctn}) {
  List<Offset> pts(String s) => [for (final xy in s.split(' ')) Offset(double.parse(xy.split(',')[0]), double.parse(xy.split(',')[1]))];
  return [
    for (final p in const [
      '8.08,-22 15,-33.98 15,-100 -15,-100 -15,-33.98 -8.08,-22',
      '15.01,18 21.93,29.98 79.1,62.99 94.1,37.01 36.93,4 23.09,4',
      '-23.09,4 -36.93,4 -94.1,37.01 -79.1,62.99 -21.93,29.98 -15.01,18',
    ])
      MarkPiece(pts(p), pos),
    for (final p in const [
      '23.09,-4 36.93,-4 94.1,-37.01 79.1,-62.99 21.93,-29.98 15.01,-18',
      '-8.08,22 -15,33.98 -15,100 15,100 15,33.98 8.08,22',
      '-15.01,-18 -21.93,-29.98 -79.1,-62.99 -94.1,-37.01 -36.93,-4 -23.09,-4',
    ])
      MarkPiece(pts(p), neg),
    MarkPiece(pts('8.08,-14 16.17,0 8.08,14 -8.08,14 -16.17,0 -8.08,-14'), hub),
  ];
}

/// The static mark. [ink] is the version for light backgrounds.
class Mark extends StatelessWidget {
  const Mark({super.key, this.size = 20, this.ink = false});
  final double size;
  final bool ink;
  @override
  Widget build(BuildContext context) {
    final pieces = ink ? staticMark(hub: const Color(0xFF1D1A1B), pos: const Color(0xFF1D1A1B), neg: const Color(0xFF6E696A)) : staticMark();
    return Semantics(
      label: 'koebelt/dash',
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: _MarkPainter(() => pieces, pad: 100)),
      ),
    );
  }
}

/// Mark + `koebelt/dash` wordmark: JetBrains Mono 500, lowercase, lime slash.
class Brand extends StatelessWidget {
  const Brand({super.key, this.small = false});
  final bool small;
  @override
  Widget build(BuildContext context) {
    final style = KText.mono(small ? 15 : 17, w: FontWeight.w500, color: K.textPrimary, tracking: -.01);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Mark(size: small ? 22 : 28),
        SizedBox(width: small ? 8 : 10),
        Flexible(
          child: Text.rich(
            TextSpan(
              style: style,
              children: const [
                TextSpan(text: 'koebelt'),
                TextSpan(
                  text: '/',
                  style: TextStyle(color: K.textAccent),
                ),
                TextSpan(text: 'dash'),
              ],
            ),
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.fade,
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------ rig
class _Target {
  _Target({required this.dirs, required this.len, required this.hub, required this.persp, this.rate = .14, this.w, this.hubS = 1, this.hubC = _ca, this.col});
  final List<V3> dirs;
  final List<double> len;
  final V3 hub;
  final double persp, rate, hubS;
  final double op = 1;
  final double? w;
  final Color hubC;

  /// Per-arm colour override and its strength.
  final List<(Color, double)>? col;
}

/// The shared 3D rig of the status loops: arms follow their target
/// organically and are shaded by the way they face.
class _Rig {
  List<V3>? dirs;
  late List<double> len;
  late V3 hub;
  late double persp;
  double _pt = 0;

  List<MarkPiece> frame(double t, _Target T) {
    final dt = _clamp(_pt == 0 ? 1 : (t - _pt) / 16.7, 0, 3);
    _pt = t;
    final k = 1 - math.pow(1 - T.rate, dt).toDouble(), kl = 1 - math.pow(1 - T.rate * .7, dt).toDouble();
    if (dirs == null) {
      dirs = [for (final d in T.dirs) List.of(d)];
      len = List.of(T.len);
      hub = List.of(T.hub);
      persp = T.persp;
    }
    dirs = [for (var i = 0; i < 6; i++) _slerp(dirs![i], T.dirs[i], k)];
    len = [for (var i = 0; i < 6; i++) _lerp(len[i], T.len[i], kl)];
    hub = [for (var i = 0; i < 3; i++) _lerp(hub[i], T.hub[i], k)];
    persp = _lerp(persp, T.persp, k);
    final (hp, hf) = _proj(hub, persp);
    final arms = <(double, MarkPiece)>[];
    for (var i = 0; i < 6; i++) {
      final d = dirs![i];
      final (tp, _) = _proj(_ad(hub, d, len[i]), persp);
      final dv = tp - hp, base = markTone(_d(d, _cam)), o = T.col?[i];
      final pts = markArm(math.atan2(dv.dy, dv.dx) * 180 / math.pi, q: dv.distance / 100, w: T.w ?? _lerp(30, 24, persp));
      arms.add((_d(_ad(hub, d, len[i] / 2), _cam), MarkPiece([for (final p in pts) p + hp], o == null ? base : _mix(base, o.$1, o.$2), T.op)));
    }
    arms.sort((a, b) => a.$1.compareTo(b.$1));
    return [
      for (final a in arms) a.$2,
      MarkPiece([for (final p in markHex(hf * T.hubS)) p + hp], T.hubC, T.op),
    ];
  }
}

// ------------------------------------------------------------------ gizmo
class _Pose {
  const _Pose(this.dirs, this.len, this.hub, this.persp);
  final List<V3> dirs;
  final List<double> len;
  final V3 hub;
  final double persp;
}

_Pose _camPose(V3 look, double hfov, double l, [double ox = 0, double oy = 0]) =>
    _Pose(_frustum(look, hfov), List.filled(6, l), _ad(_ad(_sc(_rt, .55), _up, -.35), _ad(_sc(_rt, ox), _up, oy)), 1);

final Map<String, _Pose> _poses = () {
  final tumble = [
    for (final v in _rest) _rotA(v, [.3, 1, .2], 1.3),
  ];
  final look = _scr(152, -.25);
  return {
    'Rest': _Pose(_rest, _one, const [0, 0, 0], 0),
    'Tumble': _Pose(tumble, _one, const [0, 0, 0], 1),
    'Tumble2': _Pose(
      [
        for (final v in tumble) _rotA(v, [1, .2, .6], 1.6),
      ],
      _one,
      const [0, 0, 0],
      1,
    ),
    'Fan': _Pose(
      _dup(
        [
          for (var i = 0; i < 4; i++) _scr(-54 + 36.0 * i, const [.3, -.2, .25, -.3][i]),
        ],
        [1, 2],
      ),
      [.85, 1.05, 1, .9, 1.05, 1],
      _sc(_rt, -.35),
      1,
    ),
    'Cam': _camPose(look, 27, 1.05, .1, .05),
    'CamZoom': _camPose(look, 11, 1.75, .35, .25),
    'CamPanL': _camPose(_rz(look, .55), 11, 1.75, .05, .4),
    'CamPanR': _camPose(_rz(look, -.45), 11, 1.75, .4, -.05),
    'CamOut': _camPose(_rz(look, .2), 40, .8, -.1, -.1),
    'CamZoom2': _camPose(_rz(look, -.1), 11, 1.75, .25, .15),
  };
}();

// [pose, transition ms, hold ms]: Rest, Tumble, Fan, Camera (wide, zoom in, pan, zoom out, zoom in, pan).
const _seq = [
  ('Rest', 1100.0, 1700.0),
  ('Tumble', 1100.0, 150.0),
  ('Tumble2', 1200.0, 350.0),
  ('Fan', 1000.0, 1000.0),
  ('Cam', 1200.0, 900.0),
  ('CamZoom', 1000.0, 700.0),
  ('CamPanL', 1100.0, 500.0),
  ('CamOut', 1200.0, 800.0),
  ('CamZoom2', 1100.0, 600.0),
  ('CamPanR', 1300.0, 700.0),
];

final List<List<int>> _p6 = () {
  final out = <List<int>>[], a = [0, 1, 2, 3, 4, 5];
  void go(int k) {
    if (k == 6) {
      out.add(List.of(a));
      return;
    }
    for (var i = k; i < 6; i++) {
      var x = a[k];
      a[k] = a[i];
      a[i] = x;
      go(k + 1);
      x = a[k];
      a[k] = a[i];
      a[i] = x;
    }
  }

  go(0);
  return out;
}();

class _Gizmo {
  List<V3> cdirs = List.of(_rest);
  List<double> clen = List.of(_one);
  V3 chub = [0, 0, 0];
  double cpersp = 0;
  // transition
  List<V3>? fd, td;
  List<double>? fl, tl;
  V3? fh, th;
  double fp = 0, tp = 0, t0 = 0, dur = 0;
  int gi = 0;
  double hold = 0;
  String name = 'Rest';
  // organic follow
  List<V3>? gd;
  late List<double> gl;
  late V3 gh;
  late double gp;
  double gsw = 1, pt = 0;
  static const gk = [.07, .09, .08, .1, .075, .095];

  bool _same(List<V3> d, List<double> l, int i, int j) => _d(d[i], d[j]) > .999 && (l[i] - l[j]).abs() < 1e-3;

  void go(double t, int idx) {
    final (nm, du, _) = _seq[idx];
    final P = _poses[nm]!;
    var best = [0, 1, 2, 3, 4, 5];
    if (!nm.startsWith('Tumble')) {
      // Keep merged arms merged and move each arm the shortest way.
      final pairs = [
        for (var i = 0; i < 6; i++)
          for (var j = i + 1; j < 6; j++)
            if (_same(cdirs, clen, i, j)) (i, j),
      ];
      var bs = 1e9;
      for (final pm in _p6) {
        var s = 0.0;
        for (final (i, j) in pairs) {
          if (!_same(P.dirs, P.len, pm[i], pm[j])) s += 100;
        }
        for (var i = 0; i < 6; i++) {
          s += math.acos(_clamp(_d(cdirs[i], P.dirs[pm[i]]), -1, 1));
        }
        if (s < bs) {
          bs = s;
          best = pm;
        }
      }
    }
    fd = List.of(cdirs);
    fl = List.of(clen);
    fh = List.of(chub);
    fp = cpersp;
    td = [for (final j in best) P.dirs[j]];
    tl = [for (final j in best) P.len[j]];
    th = P.hub;
    tp = P.persp;
    t0 = t;
    dur = du;
    gi = idx;
  }

  List<MarkPiece> frame(double t, List<(Offset, Offset)> ground) {
    if (hold == 0) hold = t;
    if (td != null) {
      final e = t - t0, k = _eio(_clamp(e / dur));
      cdirs = [for (var i = 0; i < 6; i++) _slerp(fd![i], td![i], k)];
      clen = [for (var i = 0; i < 6; i++) _lerp(fl![i], tl![i], k)];
      chub = [for (var i = 0; i < 3; i++) _lerp(fh![i], th![i], k)];
      cpersp = _lerp(fp, tp, k);
      if (e > dur * .45) name = _seq[gi].$1;
      if (e >= dur) {
        td = null;
        hold = t;
      }
    } else if (t - hold > _seq[gi].$3) {
      go(t, (gi + 1) % _seq.length);
    }
    final dt = _clamp(pt == 0 ? 1 : (t - pt) / 16.7, 0, 3);
    pt = t;
    double fk(double k) => 1 - math.pow(1 - k, dt).toDouble();
    if (gd == null) {
      gd = [for (final d in cdirs) List.of(d)];
      gl = List.of(clen);
      gh = List.of(chub);
      gp = cpersp;
    }
    final ld = [
      for (var i = 0; i < 6; i++)
        () {
          for (var j = 0; j < i; j++) {
            if (_d(cdirs[i], cdirs[j]) > .9999 && (clen[i] - clen[j]).abs() < 1e-3) return j;
          }
          return i;
        }(),
    ];
    gd = [for (var i = 0; i < 6; i++) _slerp(gd![i], cdirs[i], fk(gk[ld[i]]))];
    gl = [for (var i = 0; i < 6; i++) _lerp(gl[i], clen[i], fk(gk[ld[i]] * .6))];
    gh = [for (var i = 0; i < 3; i++) _lerp(gh[i], chub[i], fk(.12))];
    gp = _lerp(gp, cpersp, fk(.1));
    final camera = name.startsWith('Cam');
    gsw = _lerp(gsw, camera ? 2.4 : 1, fk(.04));
    final wob = gp * .06, sw1 = gp * .14 * gsw * math.sin(t / 1700), sw2 = gp * .1 * gsw * math.sin(t / 2300 + 1);
    final dirs = [
      for (var i = 0; i < 6; i++)
        () {
          var d = _rotA(_rotA(gd![i], [0, 0, 1], sw1), [1, -1, 0], sw2);
          final ax = _cr(d, [0, 0, 1]);
          d = _rotA(d, [0, 0, 1], wob * math.sin(t / 900 + ld[i] * 1.7));
          return _rotA(d, _len(ax) > 1e-3 ? ax : [1, 0, 0], wob * .7 * math.sin(t / 1130 + ld[i] * 2.3));
        }(),
    ];
    final cm = _clamp((gsw - 1) / 1.4);
    final h = _ad(_ad(_ad(gh, [0, 0, 1], .015 * gp * math.sin(t / 500)), _rt, .09 * cm * math.sin(t / 1300)), _up, .07 * cm * math.sin(t / 1700 + .8));
    final (hp, hf) = _proj(h, gp);
    final arms = <(double, MarkPiece)>[];
    for (var i = 0; i < 6; i++) {
      final l = gl[i] * (1 + .035 * gp * math.sin(t / 620 + ld[i] * 1.3));
      final (tp2, _) = _proj(_ad(h, dirs[i], l), gp);
      final dv = tp2 - hp;
      final pts = markArm(math.atan2(dv.dy, dv.dx) * 180 / math.pi, q: dv.distance / 100, w: _lerp(30, 18, gp));
      arms.add((_d(_ad(h, dirs[i], l / 2), _cam), MarkPiece([for (final p in pts) p + hp], markTone(_d(dirs[i], _cam)))));
    }
    arms.sort((a, b) => a.$1.compareTo(b.$1));
    // Ground marks fade in with perspective.
    ground.clear();
    if (gp > .01) {
      for (var x = -2.4; x <= 2.41; x += .8) {
        for (var y = -2.4; y <= 2.41; y += .8) {
          for (final sg in [
            ([x - .09, y, -.5], [x + .09, y, -.5]),
            ([x, y - .09, -.5], [x, y + .09, -.5]),
          ]) {
            ground.add((_proj(sg.$1, gp).$1, _proj(sg.$2, gp).$1));
          }
        }
      }
    }
    _groundOpacity = gp;
    return [
      for (final a in arms) a.$2,
      MarkPiece([for (final p in markHex(hf)) p + hp], _ca),
    ];
  }

  double _groundOpacity = 0;
}

// ------------------------------------------------------------------ widget
enum MarkLoop {
  /// App launch: tumbles in from a random orientation and lands on the mark.
  boot,

  /// Indeterminate loading: slow turntable, lime pulse around the arms.
  loading,

  /// Determinate: turns from a side view into the mark as it fills.
  progress,

  /// Pairing and scanning: the camera frustum sweeps like a searchlight.
  searching,

  /// Arms droop and grey while [MarkMotion.lost]; lift back on reconnect.
  link,

  /// Empty states: rest, tumble, fan, camera, rest.
  gizmo,
}

class MarkMotion extends StatefulWidget {
  const MarkMotion(this.loop, {super.key, this.size = 48, this.progress = 0, this.lost = true, this.gap = K.surfacePage, this.onDone});
  final MarkLoop loop;
  final double size;

  /// 0…1 for [MarkLoop.progress].
  final double progress;

  /// For [MarkLoop.link]: true while the link is lost.
  final bool lost;

  /// Background colour: arms crossing each other keep an 8-unit gap of it.
  final Color gap;

  /// For [MarkLoop.boot]: called when the mark has landed.
  final VoidCallback? onDone;

  @override
  State<MarkMotion> createState() => _MarkMotionState();
}

class _MarkMotionState extends State<MarkMotion> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _tick = ValueNotifier<double>(0);
  final _rig = _Rig();
  final _gizmo = _Gizmo();
  final _ground = <(Offset, Offset)>[];
  final _rnd = math.Random();
  late V3 _bootAxis = _n([_rnd.nextDouble() * 2 - 1, _rnd.nextDouble() * 2 - 1, _rnd.nextDouble() * 2 - 1]);
  late double _bootAngle = 2.2 + _rnd.nextDouble() * 1.4;
  double? _doneAt;
  bool _reported = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((e) => _tick.value = e.inMicroseconds / 1000)..start();
  }

  @override
  void didUpdateWidget(MarkMotion old) {
    super.didUpdateWidget(old);
    if (old.loop != widget.loop && widget.loop == MarkLoop.boot) {
      _bootAxis = _n([_rnd.nextDouble() * 2 - 1, _rnd.nextDouble() * 2 - 1, _rnd.nextDouble() * 2 - 1]);
      _bootAngle = 2.2 + _rnd.nextDouble() * 1.4;
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _tick.dispose();
    super.dispose();
  }

  List<MarkPiece> _pieces() {
    final t = _tick.value;
    switch (widget.loop) {
      case MarkLoop.boot:
        final e = _eio(_clamp((t - 100) / 1600)), gr = _ease(_clamp((t - 100) / 700));
        if (e >= 1 && !_reported) {
          _reported = true;
          WidgetsBinding.instance.addPostFrameCallback((_) => widget.onDone?.call());
        }
        return _rig.frame(
          t,
          _Target(
            dirs: [for (final v in _rest) _rotA(v, _bootAxis, _bootAngle * (1 - e))],
            len: List.filled(6, .35 + .65 * gr),
            hub: const [0, 0, 0],
            persp: .8 * (1 - e),
            hubS: gr,
            rate: .6,
          ),
        );
      case MarkLoop.loading:
        final ph = (t / 110) % 6;
        return _rig.frame(
          t,
          _Target(
            dirs: _turn(t / 1500),
            len: _one,
            hub: const [0, 0, 0],
            persp: .6,
            rate: .3,
            hubC: _ctn,
            col: [for (var i = 0; i < 6; i++) (_mix(_cdim, _ca, _ease(_clamp(1 - (((ph - i) % 6 + 6) % 6) / 2.4))), 1.0)],
          ),
        );
      case MarkLoop.progress:
        final p = _clamp(widget.progress);
        if (p >= 1) {
          _doneAt ??= t;
        } else {
          _doneAt = null;
        }
        final hk = _doneAt == null ? 0.0 : _ease(_clamp((t - _doneAt!) / 300));
        return _rig.frame(
          t,
          _Target(
            dirs: _turn((1 - _ease(p)) * math.pi * .5),
            len: _one,
            hub: const [0, 0, 0],
            persp: .6 * (1 - hk),
            rate: .2,
            hubC: _mix(_cdim, _ca, hk),
            col: [for (var i = 0; i < 6; i++) (_cdim, 1 - _ease(_clamp(p * 6 - i)))],
          ),
        );
      case MarkLoop.searching:
        final sw = math.sin(t / 1500), look = _scr(90 + 58 * sw, -.15 + .12 * math.sin(t / 1100));
        return _rig.frame(
          t,
          _Target(dirs: _frustum(look, 26 + 3 * math.sin(t / 900)), len: List.filled(6, 1.3), hub: _sc(_up, -.45), persp: .8, rate: .12, w: 17),
        );
      case MarkLoop.link:
        final lost = widget.lost, blink = (t / 500).floor() % 2 == 1;
        return _rig.frame(
          t,
          _Target(
            dirs: lost
                ? [
                    for (final d in _rest) _slerp(d, const [0, 0, -1], d[2] < -.9 ? 0 : .45),
                  ]
                : _rest,
            len: lost ? List.filled(6, .8) : _one,
            hub: lost ? const [0, 0, -.08] : const [0, 0, 0],
            persp: lost ? .5 : 0,
            rate: lost ? .05 : .16,
            hubC: lost ? (blink ? _ctn : _cdim) : _ca,
            col: lost ? List.filled(6, (_cdim, .75)) : null,
          ),
        );
      case MarkLoop.gizmo:
        return _gizmo.frame(t, _ground);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Respect "reduce motion": the still mark says the same.
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return Mark(size: widget.size * 200 / 220);
    return RepaintBoundary(
      child: SizedBox.square(
        dimension: widget.size,
        child: CustomPaint(
          painter: _GroundPainter(_ground, () => _gizmo._groundOpacity, _tick),
          foregroundPainter: _MarkPainter(_pieces, gap: widget.gap, repaint: _tick),
        ),
      ),
    );
  }
}

class _GroundPainter extends CustomPainter {
  _GroundPainter(this.lines, this.opacity, Listenable repaint) : super(repaint: repaint);
  final List<(Offset, Offset)> lines;
  final double Function() opacity;
  @override
  void paint(Canvas c, Size s) {
    if (lines.isEmpty) return;
    c.clipRect(Offset.zero & s);
    final k = s.shortestSide / 220;
    final p = Paint()
      ..color = Color.fromRGBO(255, 255, 255, .14 * _clamp(opacity()))
      ..strokeWidth = 1.5 / k;
    c.save();
    c.translate(s.width / 2, s.height / 2);
    c.scale(k);
    for (final (a, b) in lines) {
      c.drawLine(a, b, p);
    }
    c.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => true;
}

// ------------------------------------------------------------------ 3D view orientation
/// The mark as an orientation gizmo for a camera described by how each
/// world axis (+Z, −Y, +X, −Z, +Y, −X) lands on screen: [axes] gives, per
/// axis, its screen direction (x right, y down, unit = full length) and how
/// much it faces the viewer (−1…1). Drawn centred at [c] with radius [r].
void paintOrientationGizmo(Canvas canvas, Offset c, double r, List<(Offset, double)> axes, {Color gap = K.surfaceDeep}) {
  final k = r / 100;
  final arms = <(double, MarkPiece)>[];
  for (final (dir, z) in axes) {
    final pts = markArm(math.atan2(dir.dy, dir.dx) * 180 / math.pi, q: dir.distance);
    arms.add((-z, MarkPiece(pts, markTone(z))));
  }
  arms.sort((a, b) => b.$1.compareTo(a.$1)); // far first
  canvas.save();
  canvas.translate(c.dx, c.dy);
  canvas.scale(k);
  for (final (_, p) in arms) {
    final path = Path()..addPolygon(p.pts, true);
    canvas.drawPath(
      path,
      Paint()
        ..color = gap
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(path, Paint()..color = p.color);
  }
  canvas.drawPath(Path()..addPolygon(markHex(), true), Paint()..color = _ca);
  canvas.restore();
}

/// Launch: the Boot loop over [child], then a fade. The mark only, no
/// wordmark. Skipped when the system asks for reduced motion.
class BootSplash extends StatefulWidget {
  const BootSplash({super.key, required this.child});
  final Widget child;
  @override
  State<BootSplash> createState() => _BootSplashState();
}

class _BootSplashState extends State<BootSplash> {
  bool _landed = false, _gone = false;

  void _land() {
    if (!mounted || _landed) return;
    // Hold the landed mark a beat before revealing the app.
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) setState(() => _landed = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_gone || (MediaQuery.maybeDisableAnimationsOf(context) ?? false)) return widget.child;
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            ignoring: _landed,
            child: AnimatedOpacity(
              opacity: _landed ? 0 : 1,
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOut,
              onEnd: () => setState(() => _gone = true),
              child: ColoredBox(
                color: K.surfacePage,
                child: Center(child: MarkMotion(MarkLoop.boot, size: 176, onDone: _land)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
