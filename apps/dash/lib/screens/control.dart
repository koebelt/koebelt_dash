import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../core/dash.dart';
import '../core/gamepad.dart';
import '../core/model.dart';
import '../theme/tokens.dart';
import '../ui/components.dart';
import '../viz/scene3d.dart';
import '../viz/viz.dart';
import 'common.dart';
import 'controller_settings.dart' show PadChip;
import 'live.dart';
import 'main_view.dart';
import 'tiles.dart';

// ------------------------------------------------------------------ inputs
class _Pad extends StatelessWidget {
  const _Pad({required this.child, required this.w, required this.h, this.circle = true});
  final Widget child;
  final double w, h;
  final bool circle;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(circle ? w : K.radiusCard),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
      child: Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: K.inkA55,
          shape: circle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: circle ? null : BorderRadius.circular(K.radiusCard),
          border: Border.all(color: K.borderSubtle),
        ),
        child: child,
      ),
    ),
  );
}

/// Two-axis virtual stick. Reports x right-positive, y up-positive, −1…1.
class Joystick extends StatefulWidget {
  const Joystick({super.key, this.size = 160, required this.onMove, this.label, this.axes, this.disabled = false, this.onCentre, this.mirror});
  final double size;

  /// Position to show while not touched (a game controller's stick), x right, y up.
  final Offset? mirror;
  final void Function(double x, double y) onMove;
  final String? label;
  final List<String>? axes;
  final bool disabled;
  final VoidCallback? onCentre;
  @override
  State<Joystick> createState() => _JoystickState();
}

class _JoystickState extends State<Joystick> {
  Offset k = Offset.zero;
  bool act = false;

  void _upd(Offset local) {
    final r = widget.size / 2;
    var x = (local.dx - r) / r, y = (local.dy - r) / r;
    final m = math.sqrt(x * x + y * y);
    if (m > 1) {
      x /= m;
      y /= m;
    }
    setState(() => k = Offset(x, y));
    widget.onMove(x, -y);
  }

  void _end() {
    setState(() {
      act = false;
      k = Offset.zero;
    });
    widget.onMove(0, 0);
    widget.onCentre?.call();
  }

  @override
  void didUpdateWidget(Joystick old) {
    super.didUpdateWidget(old);
    if (widget.disabled && act) _end();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size, kn = s * .36, ax = widget.axes;
    final mi = widget.mirror;
    final k = act || mi == null ? this.k : Offset(mi.dx, -mi.dy);
    return Opacity(
      opacity: widget.disabled ? .38 : 1,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onPanDown: widget.disabled
                ? null
                : (e) {
                    act = true;
                    _upd(e.localPosition);
                  },
            onPanUpdate: widget.disabled ? null : (e) => _upd(e.localPosition),
            onPanEnd: (_) => _end(),
            onPanCancel: _end,
            child: MouseRegion(
              cursor: widget.disabled ? SystemMouseCursors.forbidden : SystemMouseCursors.grab,
              child: _Pad(
                w: s,
                h: s,
                child: Stack(
                  children: [
                    Positioned(
                      left: s / 2,
                      top: 8,
                      bottom: 8,
                      child: Container(width: 1, color: K.borderHairline),
                    ),
                    Positioned(
                      top: s / 2,
                      left: 8,
                      right: 8,
                      child: Container(height: 1, color: K.borderHairline),
                    ),
                    if (ax != null) ...[
                      Positioned(top: 10, left: 0, right: 0, child: MonoLabel(ax[0], size: 9, align: TextAlign.center)),
                      Positioned(bottom: 10, left: 0, right: 0, child: MonoLabel(ax[1], size: 9, align: TextAlign.center)),
                      Positioned(left: 10, top: 0, bottom: 0, child: Center(child: MonoLabel(ax[2], size: 9))),
                      Positioned(right: 10, top: 0, bottom: 0, child: Center(child: MonoLabel(ax[3], size: 9))),
                    ],
                    AnimatedPositioned(
                      duration: act ? Duration.zero : K.durBase,
                      curve: K.easeStandard,
                      left: s / 2 - kn / 2 + k.dx * (s - kn) / 2,
                      top: s / 2 - kn / 2 + k.dy * (s - kn) / 2,
                      child: AnimatedContainer(
                        duration: K.durFast,
                        width: kn,
                        height: kn,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: act || (mi != null && mi != Offset.zero) ? K.accent : K.ink100),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (widget.label != null) ...[const SizedBox(height: 8), MonoLabel(widget.label!)],
        ],
      ),
    );
  }
}

/// One-axis spring-loaded slider.
class SpringSlider extends StatefulWidget {
  const SpringSlider({super.key, this.len = 150, this.vertical = true, required this.onMove, this.label, this.ends, this.disabled = false});
  final double len;
  final bool vertical;
  final ValueChanged<double> onMove;
  final String? label;
  final List<String>? ends;
  final bool disabled;
  @override
  State<SpringSlider> createState() => _SpringSliderState();
}

class _SpringSliderState extends State<SpringSlider> {
  double k = 0;
  bool act = false;

  void _upd(Offset l) {
    final v = widget.vertical, half = widget.len / 2;
    var x = v ? -(l.dy - half) / half : (l.dx - half) / half;
    x = x.clamp(-1, 1);
    setState(() => k = x);
    widget.onMove(x);
  }

  void _end() {
    setState(() {
      act = false;
      k = 0;
    });
    widget.onMove(0);
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vertical, len = widget.len, e = widget.ends;
    final w = v ? 56.0 : len, h = v ? len : 56.0;
    final kw = v ? 40.0 : 20.0, kh = v ? 20.0 : 40.0;
    return Opacity(
      opacity: widget.disabled ? .38 : 1,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onPanDown: widget.disabled
                ? null
                : (d) {
                    act = true;
                    _upd(d.localPosition);
                  },
            onPanUpdate: widget.disabled ? null : (d) => _upd(d.localPosition),
            onPanEnd: (_) => _end(),
            onPanCancel: _end,
            child: _Pad(
              w: w,
              h: h,
              circle: false,
              child: Stack(
                children: [
                  if (v)
                    Positioned(
                      left: w / 2,
                      top: 10,
                      bottom: 10,
                      child: Container(width: 1, color: K.borderHairline),
                    ),
                  if (!v)
                    Positioned(
                      top: h / 2,
                      left: 10,
                      right: 10,
                      child: Container(height: 1, color: K.borderHairline),
                    ),
                  if (e != null) ...[
                    if (v) ...[
                      Positioned(top: 6, left: 0, right: 0, child: MonoLabel(e[0], size: 9, align: TextAlign.center)),
                      Positioned(bottom: 6, left: 0, right: 0, child: MonoLabel(e[1], size: 9, align: TextAlign.center)),
                    ] else ...[
                      Positioned(left: 6, top: 0, bottom: 0, child: Center(child: MonoLabel(e[0], size: 9))),
                      Positioned(right: 6, top: 0, bottom: 0, child: Center(child: MonoLabel(e[1], size: 9))),
                    ],
                  ],
                  AnimatedPositioned(
                    duration: act ? Duration.zero : K.durBase,
                    curve: K.easeStandard,
                    left: v ? w / 2 - kw / 2 : w / 2 - kw / 2 + k * (len - 40) / 2,
                    top: v ? h / 2 - kh / 2 - k * (len - 40) / 2 : h / 2 - kh / 2,
                    child: Container(
                      width: kw,
                      height: kh,
                      decoration: BoxDecoration(color: act ? K.accent : K.ink100, borderRadius: BorderRadius.circular(K.radiusControl)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (widget.label != null) ...[const SizedBox(height: 8), MonoLabel(widget.label!)],
        ],
      ),
    );
  }
}

/// Tilt control. Uses the accelerometer when the platform has one,
/// otherwise the pad can be dragged to simulate tilt.
class TiltPad extends StatefulWidget {
  const TiltPad({super.key, this.size = 160, required this.onMove, required this.label, this.disabled = false});
  final double size;
  final void Function(double x, double y) onMove;
  final String label;
  final bool disabled;
  @override
  State<TiltPad> createState() => _TiltPadState();
}

class _TiltPadState extends State<TiltPad> {
  Offset k = Offset.zero;
  bool act = false, sensor = false;
  Offset? base;
  StreamSubscription<AccelerometerEvent>? _sub;

  @override
  void initState() {
    super.initState();
    try {
      _sub = accelerometerEventStream(samplingPeriod: SensorInterval.gameInterval).listen(
        (e) {
          // gamma: left/right tilt, beta: front/back tilt, in degrees.
          final gamma = math.atan2(e.x, e.z) * 57.3, beta = math.atan2(e.y, e.z) * 57.3;
          base ??= Offset(gamma, beta);
          if (!sensor) setState(() => sensor = true);
          if (widget.disabled) return;
          var x = -(gamma - base!.dx) / 25, y = -(beta - base!.dy) / 25;
          final m = math.sqrt(x * x + y * y);
          if (m > 1) {
            x /= m;
            y /= m;
          }
          setState(() => k = Offset(x, y));
          widget.onMove(x, -y);
        },
        onError: (_) {},
        cancelOnError: true,
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _sub?.cancel();
    widget.onMove(0, 0);
    super.dispose();
  }

  void _upd(Offset l) {
    final r = widget.size / 2;
    var x = (l.dx - r) / r, y = (l.dy - r) / r;
    final m = math.sqrt(x * x + y * y);
    if (m > 1) {
      x /= m;
      y /= m;
    }
    setState(() => k = Offset(x, y));
    widget.onMove(x, -y);
  }

  void _end() {
    setState(() {
      act = false;
      k = Offset.zero;
    });
    widget.onMove(0, 0);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size, drag = !widget.disabled && !sensor;
    return Opacity(
      opacity: widget.disabled ? .38 : 1,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onDoubleTap: sensor ? () => base = null : null,
            onPanDown: drag
                ? (e) {
                    act = true;
                    _upd(e.localPosition);
                  }
                : null,
            onPanUpdate: drag ? (e) => _upd(e.localPosition) : null,
            onPanEnd: drag ? (_) => _end() : null,
            onPanCancel: drag ? _end : null,
            child: MouseRegion(
              cursor: SystemMouseCursors.precise,
              child: _Pad(
                w: s,
                h: s,
                child: Stack(
                  children: [
                    for (final r in const [.33, .66])
                      Positioned.fill(
                        child: Padding(
                          padding: EdgeInsets.all(r * s / 2),
                          child: CustomPaint(painter: _DashedCircle()),
                        ),
                      ),
                    AnimatedPositioned(
                      duration: act || sensor ? Duration.zero : K.durBase,
                      left: s / 2 - 11 + k.dx * (s - 22) / 2,
                      top: s / 2 - 11 + k.dy * (s - 22) / 2,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: K.accent, width: 2),
                          color: act || sensor ? K.limeA32 : Colors.transparent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          MonoLabel(sensor ? widget.label : 'Tilt · drag to simulate'),
        ],
      ),
    );
  }
}

class _DashedCircle extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = K.borderHairline
      ..style = PaintingStyle.stroke;
    final r = s.width / 2;
    for (var a = 0.0; a < math.pi * 2; a += .2) {
      c.drawArc(Rect.fromCircle(center: Offset(r, r), radius: r), a, .1, false, p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

// ------------------------------------------------------------------ drone / rover
class MobileControl extends StatelessWidget {
  const MobileControl(this.d, {super.key, required this.w, required this.h});
  final Dash d;
  final double w, h;

  @override
  Widget build(BuildContext context) {
    final s = d.liveTel, drone = d.kind == DeviceKind.drone, stacked = w < 640;
    final live = s.armed && !s.estop, dis = !live || d.linkLost;
    final inv = d.settings.invertY ? -1.0 : 1.0, cs = d.settings.control, I = d.input;
    void g() {
      if (I.any((v) => v != 0)) d.goManual();
    }

    void setL(double x, double y) {
      I[0] = x;
      I[1] = drone ? y : 0;
      g();
    }

    void setR(double x, double y) {
      I[2] = drone ? x : 0;
      I[3] = y * inv;
      g();
    }

    final js = stacked ? math.min(150.0, (w - 72) / 2) : math.min(180.0, math.max(130.0, h * .28));
    Widget L, R;
    void centre() => d.hapticTick();
    if (cs == 'sliders') {
      L = Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SpringSlider(
            len: js,
            onMove: (v) {
              drone ? I[1] = v : I[3] = v * inv;
              g();
            },
            disabled: dis,
            label: drone ? 'Throttle' : 'Drive',
            ends: drone ? const ['UP', 'DN'] : const ['FWD', 'REV'],
          ),
          if (drone) ...[
            const SizedBox(width: 12),
            SpringSlider(
              len: js * .8,
              vertical: false,
              onMove: (v) {
                I[0] = v;
                g();
              },
              disabled: dis,
              label: 'Yaw',
              ends: const ['L', 'R'],
            ),
          ],
        ],
      );
      R = drone
          ? Joystick(size: js, onMove: setR, disabled: dis, label: 'Pitch · roll', axes: const ['FWD', 'BACK', 'L', 'R'], onCentre: centre)
          : SpringSlider(
              len: js,
              vertical: false,
              onMove: (v) {
                I[0] = v;
                g();
              },
              disabled: dis,
              label: 'Steer',
              ends: const ['L', 'R'],
            );
    } else if (cs == 'tilt') {
      L = drone
          ? SpringSlider(
              len: js,
              onMove: (v) {
                I[1] = v;
                g();
              },
              disabled: dis,
              label: 'Throttle',
              ends: const ['UP', 'DN'],
            )
          : const SizedBox();
      R = TiltPad(
        size: js,
        disabled: dis,
        label: drone ? 'Tilt · pitch and roll' : 'Tilt · steer and drive',
        onMove: (x, y) {
          if (drone) {
            I[2] = x;
            I[3] = y * inv;
          } else {
            I[0] = x;
            I[3] = y * inv;
          }
          g();
        },
      );
    } else {
      final pad = d.padMapper.driving;
      L = Joystick(
        size: js,
        mirror: pad ? Offset(I[0], drone ? I[1] : 0) : null,
        onMove: setL,
        disabled: dis,
        label: drone ? 'Throttle · yaw' : 'Steer',
        axes: drone ? const ['UP', 'DN', 'YAW', 'YAW'] : const ['', '', 'L', 'R'],
        onCentre: centre,
      );
      R = Joystick(
        size: js,
        mirror: pad ? Offset(drone ? I[2] : 0, I[3] * inv) : null,
        onMove: setR,
        disabled: dis,
        label: drone ? 'Pitch · roll' : 'Drive',
        axes: drone ? const ['FWD', 'BACK', 'L', 'R'] : const ['FWD', 'REV', '', ''],
        onCentre: centre,
      );
    }
    const csMap = {'joysticks': 'STICKS', 'sliders': 'SLIDERS', 'tilt': 'TILT'};
    final csSeg = Seg(
      small: true,
      items: const ['STICKS', 'SLIDERS', 'TILT'],
      value: csMap[cs],
      onChanged: (v) => d.updateSettings((st) => st.control = csMap.entries.firstWhere((e) => e.value == v).key),
    );
    final special = const ['TAKEOFF', 'LAND', 'RTH'].contains(s.mode);
    final top = Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Seg(items: const ['AUTO', 'MANUAL', 'HOLD'], value: special ? '' : s.mode, onChanged: d.setMode, small: stacked),
        if (drone) Seg(items: const ['TAKEOFF', 'LAND', 'RTH'], value: s.mode, onChanged: d.setMode, small: stacked),
        RecordButton(d, small: stacked),
        if (viewItems(d, cameras3d: false).length > 1)
          ViewSeg(
            d,
            view: d.controlView,
            cameras3d: false,
            onChanged: (v) {
              d.controlView = v;
              d.emit();
            },
          ),
        PadChip(d),
        KButton('Set home', size: KSize.sm, variant: KButtonVariant.secondary, onPressed: d.linkLost ? null : () => confirmSetHome(context, d)),
      ],
    );
    final stats = Wrap(
      spacing: 24,
      runSpacing: 12,
      children: [
        drone ? Readout('Alt', s.pos[2].toStringAsFixed(1), 'm') : Readout('Odom', s.range.toStringAsFixed(0), 'm'),
        Readout('Speed', s.speed.toStringAsFixed(1), 'm/s'),
        Readout('Hdg', s.heading.round().toString().padLeft(3, '0'), '°'),
        Readout('Home', s.range.toStringAsFixed(0), 'm'),
      ],
    );
    if (stacked) {
      return Column(
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: K.surfaceDeep,
                border: Border(bottom: BorderSide(color: K.borderHairline)),
              ),
              child: Stack(
                children: [
                  Positioned.fill(child: MainView(d, view: d.controlView, interactive: false, attribution: false)),
                  Positioned(top: 12, left: 12, right: 12, child: top),
                  Positioned(left: 12, right: 12, bottom: 12, child: stats),
                  Positioned(right: 4, bottom: 4, child: MapOverlayAttribution(d, view: d.controlView)),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(child: SpeedSlider(d)),
                    const SizedBox(width: 12),
                    csSeg,
                  ],
                ),
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.end, children: [L, R]),
              ],
            ),
          ),
        ],
      );
    }
    return Container(
      color: K.surfaceDeep,
      child: Stack(
        children: [
          Positioned.fill(child: MainView(d, view: d.controlView, interactive: false, attribution: false)),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: top),
                const SizedBox(width: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    csSeg,
                    const SizedBox(width: 16),
                    SizedBox(width: 200, child: SpeedSlider(d)),
                  ],
                ),
              ],
            ),
          ),
          if (w > 820) Positioned(bottom: 24, left: 0, right: 0, child: Center(child: stats)),
          Positioned(left: 24, bottom: 24, child: L),
          Positioned(right: 24, bottom: 24, child: R),
          Positioned(right: 4, bottom: 4, child: MapOverlayAttribution(d, view: d.controlView)),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ arm
class HoldBtn extends StatefulWidget {
  const HoldBtn({super.key, required this.child, required this.onDown, required this.onUp, this.disabled = false});
  final Widget child;
  final VoidCallback onDown, onUp;
  final bool disabled;
  @override
  State<HoldBtn> createState() => _HoldBtnState();
}

class _HoldBtnState extends State<HoldBtn> {
  bool p = false;
  void _up() {
    if (!p) return;
    setState(() => p = false);
    widget.onUp();
  }

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: widget.disabled ? .38 : 1,
    child: Listener(
      onPointerDown: widget.disabled
          ? null
          : (_) {
              setState(() => p = true);
              widget.onDown();
            },
      onPointerUp: (_) => _up(),
      onPointerCancel: (_) => _up(),
      child: MouseRegion(
        cursor: widget.disabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
        child: AnimatedScale(
          scale: p ? K.pressScale : 1,
          duration: K.durFast,
          child: AnimatedContainer(
            duration: K.durFast,
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: p ? K.accent : Colors.transparent,
              border: Border.all(color: p ? K.accent : K.borderSubtle),
              borderRadius: BorderRadius.circular(K.radiusControl),
            ),
            child: DefaultTextStyle(
              style: KText.mono(13, color: p ? K.textOnAccent : K.textPrimary),
              child: widget.child,
            ),
          ),
        ),
      ),
    ),
  );
}

class ArmControl extends StatefulWidget {
  const ArmControl(this.d, {super.key, required this.w});
  final Dash d;
  final double w;
  @override
  State<ArmControl> createState() => _ArmControlState();
}

class _ArmControlState extends State<ArmControl> {
  @override
  Widget build(BuildContext context) {
    final d = widget.d, s = d.liveTel, live = s.armed && !s.estop && !d.linkLost, wide = widget.w >= 900, tab = d.armFrame;
    // Which stick moves each row, shown while a controller is connected.
    final pad = d.gamepads.pads.isNotEmpty && d.pad.enabled;
    final jointStick = d.armWrist ? const {0: 'LX', 1: 'LY', 4: 'RY', 5: 'RX'} : const {0: 'LX', 1: 'LY', 2: 'RY', 3: 'RX'};
    const cartStick = {0: 'LY', 1: 'LX', 2: 'RY'};
    Widget stick(String? l) => SizedBox(
      width: pad ? 36 : 0,
      child: l == null || !pad ? null : MonoLabel(l, color: K.textAccent, size: 10),
    );
    String btn(PadAction a) => padSourceLabel(d.pad.buttons[a]);
    void jog(int i, double v) {
      d.goManual();
      d.setJog(i, v);
    }

    const cart = [
      ['X', 0],
      ['Y', 1],
      ['Z', 2],
    ];
    final tip = s.armPts[5];
    final panel = Padding(
      padding: EdgeInsets.all(wide ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              Seg(items: const ['AUTO', 'MANUAL', 'HOLD'], value: s.mode, onChanged: d.setMode),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  RecordButton(d, small: false),
                  KButton('Home pose', variant: KButtonVariant.secondary, onPressed: live ? () => d.cmd('home') : null),
                  KButton('Set as home', variant: KButtonVariant.ghost, onPressed: d.linkLost ? null : () => confirmSetHome(context, d)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: KTabs(items: const ['Joint', 'Cartesian'], value: tab, onChanged: d.setArmFrame),
          ),
          const SizedBox(height: 20),
          if (tab == 'Joint')
            for (var i = 0; i < 6; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    SizedBox(width: 32, child: MonoLabel('J${i + 1}', color: K.textSecondary)),
                    stick(jointStick[i]),
                    const SizedBox(width: 10),
                    HoldBtn(disabled: !live, onDown: () => jog(i, -1), onUp: () => d.setJog(i, 0), child: const Text('−')),
                    const SizedBox(width: 10),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (_, c) {
                          final x = c.maxWidth * (.5 + (s.joints[i] / 3.2) * .5).clamp(0, 1);
                          return SizedBox(
                            height: 14,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Positioned(left: 0, right: 0, top: 5, child: Container(height: 4, color: K.ink500)),
                                Positioned(
                                  left: c.maxWidth / 2,
                                  top: 1,
                                  child: Container(width: 1, height: 12, color: K.ink300),
                                ),
                                Positioned(
                                  left: x - 1,
                                  top: 0,
                                  child: Container(width: 2, height: 14, color: K.accent),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    HoldBtn(disabled: !live, onDown: () => jog(i, 1), onUp: () => d.setJog(i, 0), child: const Text('+')),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 64,
                      child: Text('${(s.joints[i] * 57.3).toStringAsFixed(1)}°', textAlign: TextAlign.right, style: KText.mono(14)),
                    ),
                  ],
                ),
              )
          else ...[
            for (final c in cart)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    SizedBox(width: 32, child: MonoLabel(c[0] as String, color: K.textSecondary)),
                    stick(cartStick[c[1]]),
                    const SizedBox(width: 10),
                    HoldBtn(
                      disabled: !live,
                      onDown: () {
                        d.goManual();
                        d.setCart([for (var a = 0; a < 3; a++) a == c[1] ? -1.0 : 0.0]);
                      },
                      onUp: () => d.setCart(const [0, 0, 0]),
                      child: const Text('−'),
                    ),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: '${tip[c[1] as int].toStringAsFixed(3)} ', style: KText.mono(16)),
                            TextSpan(
                              text: 'M',
                              style: KText.mono(11, color: K.textMuted),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    HoldBtn(
                      disabled: !live,
                      onDown: () {
                        d.goManual();
                        d.setCart([for (var a = 0; a < 3; a++) a == c[1] ? 1.0 : 0.0]);
                      },
                      onUp: () => d.setCart(const [0, 0, 0]),
                      child: const Text('+'),
                    ),
                  ],
                ),
              ),
            const Padding(padding: EdgeInsets.only(top: 4), child: MonoLabel('Tool frame · base-relative', height: 1.5)),
          ],
          if (pad)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: MonoLabel(
                'Controller · ${btn(PadAction.armFrame)}: joint / cartesian · ${btn(PadAction.armWrist)}: ${d.armWrist ? 'J3 J4' : 'wrist'} · ${btn(PadAction.gripper)}: gripper',
                height: 1.5,
                maxLines: 3,
              ),
            ),
          const SizedBox(height: 20),
          SpeedSlider(d),
          const SizedBox(height: 20),
          Row(
            children: [
              const MonoLabel('Gripper'),
              const Spacer(),
              MonoLabel('${(s.gripper * 100).round()}% open', color: K.textPrimary),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: KButton(
                  'Open',
                  fullWidth: true,
                  variant: KButtonVariant.secondary,
                  onPressed: live
                      ? () {
                          d.goManual();
                          d.cmd('gripper', {'v': .9});
                        }
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: KButton(
                  'Close',
                  fullWidth: true,
                  variant: KButtonVariant.secondary,
                  onPressed: live
                      ? () {
                          d.goManual();
                          d.cmd('gripper', {'v': .1});
                        }
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
    final scene = Container(
      color: K.surfaceDeep,
      child: Stack(
        children: [
          Positioned.fill(child: Scene3D(d, view: 'orbit')),
          Positioned(
            left: 16,
            bottom: 16,
            child: Row(
              children: [
                Readout('Tool X', tip[0].toStringAsFixed(3), 'm'),
                const SizedBox(width: 24),
                Readout('Tool Y', tip[1].toStringAsFixed(3), 'm'),
                const SizedBox(width: 24),
                Readout('Tool Z', tip[2].toStringAsFixed(3), 'm'),
              ],
            ),
          ),
        ],
      ),
    );
    if (wide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                border: Border(right: BorderSide(color: K.borderHairline)),
              ),
              child: scene,
            ),
          ),
          SizedBox(width: 400, child: SingleChildScrollView(child: panel)),
        ],
      );
    }
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            height: math.max(260, widget.w * .6),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: K.borderHairline)),
            ),
            child: scene,
          ),
          panel,
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ rocket
class _CheckRow extends StatelessWidget {
  const _CheckRow(this.k, this.ok, this.v);
  final String k, v;
  final bool ok;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: K.borderHairline)),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(k, style: KText.bodySm.copyWith(color: K.textSecondary)),
        ),
        KBadge(v, tone: ok ? Tone.positive : Tone.warning),
      ],
    ),
  );
}

class RocketControl extends StatelessWidget {
  const RocketControl(this.d, {super.key, required this.w});
  final Dash d;
  final double w;

  @override
  Widget build(BuildContext context) {
    final s = d.liveTel, wide = w >= 900, phone = w < 600, ph = s.mode, py = s.pyro;
    final live = !s.estop && !d.linkLost;
    double P(String k, double def) => d.devParams?[k] ?? def;
    final timer = ph == 'COUNT'
        ? 'T−${math.max(0, s.countdown).toStringAsFixed(1)}'
        : ph == 'PAD'
        ? 'T−${P('COUNTDOWN', 10).toStringAsFixed(0)}.0'
        : 'T+${mmss(s.phaseT)}';
    final pyOk = py[0] == 'OK' && py[1] == 'OK';
    final flying = const ['BOOST', 'COAST', 'DROGUE'].contains(ph);
    final panel = Padding(
      padding: EdgeInsets.all(wide ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const MonoLabel('Flight phase'),
                    const SizedBox(height: 8),
                    Text(phaseLabel[ph] ?? ph, style: KText.display(size: 40, color: ph == 'COUNT' || ph == 'BOOST' ? K.textAccent : K.textPrimary)),
                  ],
                ),
              ),
              Text(timer, style: KText.mono(22)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: Readout('Alt', s.pos[2].toStringAsFixed(0), 'm')),
              Expanded(child: Readout('Vz', f1(s.vel[2], 0), 'm/s')),
              Expanded(child: Readout('Max', s.maxAlt.toStringAsFixed(0), 'm')),
              Expanded(child: Readout('Range', s.range.toStringAsFixed(0), 'm')),
            ],
          ),
          if (ph == 'PAD' || ph == 'COUNT') ...[
            const SizedBox(height: 20),
            const MonoLabel('Pre-flight'),
            const SizedBox(height: 8),
            _CheckRow('Pyro continuity · drogue, main', pyOk, pyOk ? 'OK' : 'Check'),
            _CheckRow('GPS lock', s.sats >= 6, s.hasGps ? '${s.sats} sats' : 'No fix'),
            _CheckRow('Link', !d.linkLost && s.rssi > -80, d.linkLost ? 'Lost' : '${s.rssi.round()} dBm'),
            _CheckRow('Flight computer', s.armed, s.armed ? 'Armed' : 'Safe'),
          ],
          const SizedBox(height: 20),
          if (ph == 'PAD' && !s.armed) ...[
            KButton('Arm flight computer', size: KSize.lg, variant: KButtonVariant.secondary, fullWidth: true, onPressed: live ? () => d.setArmed(true) : null),
            const SizedBox(height: 10),
            const MonoLabel('Arm only when the pad is clear', height: 1.6),
          ],
          if (ph == 'PAD' && s.armed)
            KButton(
              'Start countdown · ${P('COUNTDOWN', 10).toStringAsFixed(0)} s',
              size: KSize.lg,
              fullWidth: true,
              onPressed: live && pyOk ? () => d.cmd('countdown', {'s': P('COUNTDOWN', 10)}) : null,
            ),
          if (ph == 'COUNT')
            Pressable(
              onTap: () => d.cmd('abort'),
              builder: (_, _, _) => Container(
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: K.negative, borderRadius: BorderRadius.circular(K.radiusControl)),
                child: Text(
                  'ABORT LAUNCH',
                  style: KText.mono(13, w: FontWeight.w700, color: K.ink900, tracking: K.trLabel),
                ),
              ),
            ),
          if (flying)
            Row(
              children: [
                Expanded(
                  child: KButton(
                    'Deploy drogue',
                    variant: KButtonVariant.secondary,
                    fullWidth: true,
                    onPressed: ph == 'COAST' && py[0] == 'OK' ? () => d.cmd('deploy', {'ch': 0}) : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: KButton(
                    'Deploy main',
                    variant: KButtonVariant.secondary,
                    fullWidth: true,
                    onPressed: ph != 'BOOST' && py[1] == 'OK' ? () => d.cmd('deploy', {'ch': 1}) : null,
                  ),
                ),
              ],
            ),
          if (flying || ph == 'MAIN') ...[
            const SizedBox(height: 10),
            MonoLabel('Auto deploy · drogue at apogee · main at ${P('MAIN_ALT', 150).toStringAsFixed(0)} m', height: 1.6),
          ],
          if (ph == 'LANDED') ...[
            KNotice(
              tone: Tone.positive,
              title: 'Landed',
              child: Text('Apogee ${s.maxAlt.toStringAsFixed(0)} m · landed ${s.range.toStringAsFixed(0)} m from the pad.'),
            ),
            const SizedBox(height: 10),
            KButton('Reset to pad', variant: KButtonVariant.secondary, onPressed: () => d.cmd('reset')),
          ],
          const SizedBox(height: 10),
          Align(alignment: Alignment.centerLeft, child: RecordButton(d, small: false)),
        ],
      ),
    );
    final scene = Container(
      color: K.surfaceDeep,
      child: Stack(
        children: [
          Positioned.fill(child: Scene3D(d, view: 'chase')),
          Positioned(
            left: 12,
            bottom: 12,
            width: phone ? w - 24 : 320,
            height: phone ? 90 : 120,
            child: HudPanel(
              title: 'Altitude · 10 s',
              child: LineChart(d, keys: const ['alt'], colors: const [VC.lime]),
            ),
          ),
        ],
      ),
    );
    if (wide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                border: Border(right: BorderSide(color: K.borderHairline)),
              ),
              child: scene,
            ),
          ),
          SizedBox(width: 400, child: SingleChildScrollView(child: panel)),
        ],
      );
    }
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            height: math.max(260, w * .7),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: K.borderHairline)),
            ),
            child: scene,
          ),
          panel,
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ bench
class BenchControl extends StatefulWidget {
  const BenchControl(this.d, {super.key, required this.w});
  final Dash d;
  final double w;
  @override
  State<BenchControl> createState() => _BenchControlState();
}

class _BenchControlState extends State<BenchControl> {
  String kind = 'RAMP';
  @override
  Widget build(BuildContext context) {
    final d = widget.d, s = d.liveTel, w = widget.w, wide = w >= 900, phone = w < 600;
    final live = s.armed && !s.estop && !d.linkLost, seq = s.seqKind;
    double P(String k, double def) => d.devParams?[k] ?? def;
    final pct = ((seq != null ? s.throttleOut : d.benchThrottle) * 100).round();
    void setThr(double v) {
      d.benchThrottle = v / 100;
      d.cmd('throttle', {'v': v / 100});
    }

    final pw = s.power, eff = pw > 5 ? s.thrust * 101.97 / pw : 0.0;
    Widget box(Widget c, {double? height}) => Panel(height: height, child: c);
    Widget chartBox(String t, String k, Color col, double hgt) => box(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MonoLabel(t),
          const SizedBox(height: 8),
          Expanded(
            child: LineChart(d, keys: [k], colors: [col], pinnable: true),
          ),
        ],
      ),
      height: hgt,
    );
    final readouts = [
      Readout('Thrust', s.thrust.toStringAsFixed(2), 'N'),
      Readout('RPM', '${s.rpm.round()}', ''),
      Readout('Current', s.current.toStringAsFixed(1), 'A'),
      Readout('Power', pw.toStringAsFixed(0), 'W'),
      Readout('Temp', s.temp.toStringAsFixed(1), '°C', tone: s.temp > 70 ? K.warning : null),
      Readout('Efficiency', eff.toStringAsFixed(1), 'g/W'),
    ];
    final left = Padding(
      padding: EdgeInsets.all(wide ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          box(
            LayoutBuilder(
              builder: (_, c) {
                final n = phone ? 3 : 6;
                return Wrap(
                  runSpacing: 16,
                  children: [for (final r in readouts) SizedBox(width: c.maxWidth / n, child: r)],
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          chartBox('Thrust · 10 s', 'thr', VC.lime, phone ? 180 : 240),
          const SizedBox(height: 12),
          if (phone) ...[
            chartBox('RPM', 'rpm', VC.white, 150),
            const SizedBox(height: 12),
            chartBox('Current', 'cur', VC.info, 150),
          ] else
            Row(
              children: [
                Expanded(child: chartBox('RPM', 'rpm', VC.white, 150)),
                const SizedBox(width: 12),
                Expanded(child: chartBox('Current', 'cur', VC.info, 150)),
              ],
            ),
        ],
      ),
    );
    final curKind = seq ?? kind;
    final panel = Padding(
      padding: EdgeInsets.all(wide ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (s.mode == 'CUTOFF') ...[
            KNotice(
              tone: Tone.warning,
              title: 'Cutoff · ${s.cutoff ?? 'limit'}',
              child: Wrap(
                children: [
                  const Text('Throttle was set to 0. Check the motor before running again. '),
                  GestureDetector(
                    onTap: () => d.cmd('clear'),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Text(
                        'Clear',
                        style: KText.bodySm.copyWith(color: K.textPrimary, decoration: TextDecoration.underline, decorationColor: K.whiteA20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          if (!s.armed) ...[
            const KNotice(tone: Tone.info, title: 'Disarmed', child: Text('Arm the bench to spin the motor. Keep clear of the propeller.')),
            const SizedBox(height: 20),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const MonoLabel('Throttle'),
              const Spacer(),
              Text('$pct%', style: KText.display(size: 40, color: pct > 0 ? K.textAccent : K.textPrimary)),
            ],
          ),
          const SizedBox(height: 12),
          Opacity(
            opacity: !live || seq != null ? .4 : 1,
            child: KSlider(value: d.benchThrottle * 100, min: 0, max: 100, step: 1, height: 32, onChanged: !live || seq != null ? null : setThr),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final v in const [0, 25, 50, 75, 100]) ...[
                if (v > 0) const SizedBox(width: 6),
                Expanded(
                  child: KButton(
                    '$v',
                    size: KSize.sm,
                    fullWidth: true,
                    padding: EdgeInsets.zero,
                    variant: (d.benchThrottle * 100).round() == v && seq == null ? KButtonVariant.primary : KButtonVariant.secondary,
                    onPressed: !live || seq != null ? null : () => setThr(v.toDouble()),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          hairline,
          const SizedBox(height: 20),
          const MonoLabel('Test sequence'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Seg(small: true, items: const ['RAMP', 'STEPS'], value: curKind, onChanged: (v) => seq == null ? setState(() => kind = v) : null),
              seq != null
                  ? KButton('Stop · ${mmss(s.seqT)}', size: KSize.sm, variant: KButtonVariant.secondary, onPressed: () => d.cmd('seq', {'kind': null}))
                  : KButton(
                      'Run and record',
                      size: KSize.sm,
                      onPressed: live
                          ? () {
                              d.cmd('seq', {'kind': kind});
                              if (!d.recording) d.startRec();
                            }
                          : null,
                    ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${curKind == 'RAMP' ? 'Ramp 0 to 100 % over ${P('RAMP_TIME', 10).toStringAsFixed(0)} s, hold 2 s, stop.' : 'Steps of ${P('STEP_SIZE', 25).toStringAsFixed(0)} %, ${_n(P('STEP_HOLD', 3))} s each, up to 100 %.'} Limits: ${P('MAX_CURRENT', 45).toStringAsFixed(0)} A, ${P('MAX_TEMP', 90).toStringAsFixed(0)} °C.',
            style: KText.bodySm.copyWith(color: K.textMuted),
          ),
          if (wide) ...[
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(K.radiusCard),
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: K.surfaceDeep,
                  border: Border.all(color: K.borderHairline),
                  borderRadius: BorderRadius.circular(K.radiusCard),
                ),
                child: Scene3D(d, view: 'orbit', layers: const {'grid': true, 'cloud': true}),
              ),
            ),
          ],
        ],
      ),
    );
    if (!wide) {
      return SingleChildScrollView(
        child: Column(
          children: [
            Container(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: K.borderHairline)),
              ),
              child: panel,
            ),
            left,
          ],
        ),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              border: Border(right: BorderSide(color: K.borderHairline)),
            ),
            child: SingleChildScrollView(child: left),
          ),
        ),
        SizedBox(width: 380, child: SingleChildScrollView(child: panel)),
      ],
    );
  }
}

String _n(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

class ControlScreen extends StatelessWidget {
  const ControlScreen(this.d, {super.key, required this.w, required this.h});
  final Dash d;
  final double w, h;
  @override
  Widget build(BuildContext context) => !d.canControl
      ? TelemetryOnly(d)
      : switch (d.kind) {
          DeviceKind.arm => ArmControl(d, w: w),
          DeviceKind.rocket => RocketControl(d, w: w),
          DeviceKind.bench => BenchControl(d, w: w),
          _ => MobileControl(d, w: w, h: h),
        };
}

/// Shown instead of the controls on telemetry-only links (LoRa) and MSP.
class TelemetryOnly extends StatelessWidget {
  const TelemetryOnly(this.d, {super.key});
  final Dash d;
  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: d.device?.proto == 'msp'
            ? KNotice(
                tone: Tone.info,
                title: 'Monitoring and tuning',
                child: Text(
                  '${d.deviceName} runs ${d.device?.model.split(' · ').first ?? 'Betaflight or INAV'} and is connected over MSP, the configuration link. '
                  'The app shows its telemetry, tunes its PID gains on the Tune screen, and STOP disarms it. Fly it with your RC transmitter.',
                ),
              )
            : KNotice(
                tone: Tone.warning,
                title: 'Telemetry-only link',
                child: Text(
                  '${d.deviceName} is connected through ${d.radio?.name ?? 'a radio'}, which carries telemetry only. Sticks, modes and commands do not reach the device this way; STOP does, within about a second. '
                  'Control it over its main link (Wi-Fi, Bluetooth or a SiK radio) and rely on its failsafe when that link is out of range.',
                ),
              ),
      ),
    ),
  );
}
