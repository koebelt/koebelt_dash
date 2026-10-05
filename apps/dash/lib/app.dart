import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'core/dash.dart';
import 'core/model.dart';
import 'screens/control.dart';
import 'screens/device_menu.dart';
import 'screens/devices.dart';
import 'screens/guides.dart';
import 'screens/live.dart';
import 'screens/params.dart';
import 'screens/program.dart';
import 'screens/replay.dart';
import 'screens/settings.dart';
import 'theme/tokens.dart';
import 'ui/components.dart';
import 'ui/icons.dart';
import 'ui/mark.dart';

const nav = [
  ['live', 'Live', 'activity'],
  ['control', 'Control', 'gamepad'],
  ['program', 'Program', 'list-checks'],
  ['params', 'Tune', 'tune'],
  ['replay', 'Replay', 'replay'],
  ['devices', 'Devices', 'devices'],
  ['guides', 'Guides', 'book'],
  ['settings', 'Settings', 'gear'],
];

/// Root: owns the frame ticker that drives telemetry sampling and canvases.
class DashApp extends StatefulWidget {
  const DashApp({super.key, required this.dash, this.initial = 'live'});
  final Dash dash;
  final String initial;
  @override
  State<DashApp> createState() => _DashAppState();
}

class _DashAppState extends State<DashApp> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _last = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((now) {
      final dt = ((now - _last).inMicroseconds / 1e6).clamp(0.0, .05);
      _last = now;
      widget.dash.tick(dt);
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.dash,
    builder: (_, _) => Shell(d: widget.dash, initial: widget.initial),
  );
}

class Shell extends StatefulWidget {
  const Shell({super.key, required this.d, required this.initial});
  final Dash d;
  final String initial;
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  late String screen = widget.initial;
  String? detail;
  Recording? toast;
  String? _seen;
  Timer? _toastT;

  void go(String s) => setState(() {
    detail = null;
    screen = s;
  });

  @override
  void dispose() {
    _toastT?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.d;
    final l = d.lastSaved;
    if (l != null && l.id != _seen) {
      _seen = l.id;
      toast = l;
      _toastT?.cancel();
      _toastT = Timer(const Duration(seconds: 5), () {
        if (mounted) setState(() => toast = null);
      });
    }
    return LayoutBuilder(
      builder: (context, c) {
        final W = c.maxWidth, H = c.maxHeight;
        final mode = W < 600
                ? 'phone'
                : W < 1200
                ? 'tablet'
                : 'desktop',
            phone = mode == 'phone';
        final pad = MediaQuery.paddingOf(context);
        final navH = phone ? 60.0 : 0.0, topH = phone ? 100.0 : 64.0;
        final bodyW = mode == 'desktop'
            ? W - 232
            : mode == 'tablet'
            ? W - 80
            : W;
        final bodyH = H - topH - navH - pad.top - pad.bottom;
        final none = !d.hasDevice && d.replay == null && const ['live', 'control', 'program', 'params'].contains(screen);
        final Widget body;
        if (none) {
          body = NoDevice(d: d, w: bodyW, go: go);
        } else {
          body = switch (screen) {
            'live' =>
              detail != null
                  ? SensorDetail(d, key: ValueKey(detail), id: detail!, onBack: () => setState(() => detail = null), w: bodyW)
                  : LiveScreen(d, w: bodyW, onOpen: (id) => setState(() => detail = id)),
            'params' => ParamsScreen(d, w: bodyW),
            'program' => ProgramScreen(d, w: bodyW),
            'control' => ControlScreen(d, w: bodyW, h: bodyH),
            'replay' => ReplayScreen(d, w: bodyW, h: bodyH),
            'guides' => GuidesScreen(d, w: bodyW, go: go),
            'devices' => DevicesScreen(d, w: bodyW, go: go),
            _ => SettingsScreen(d, w: bodyW, go: go),
          };
        }
        final top = phone
            ? Container(
                height: topH,
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: K.borderHairline)),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: DeviceBtn(d: d, go: go, sub: false),
                            ),
                            const SizedBox(width: 12),
                            EStop(d: d, compact: true),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: const BoxDecoration(
                        color: K.surfaceSunken,
                        border: Border(top: BorderSide(color: K.borderHairline)),
                      ),
                      child: Row(
                        children: [
                          Expanded(child: StatusCluster(d: d, phone: true)),
                          const SizedBox(width: 12),
                          ModeArm(d: d, phone: true),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            : Container(
                height: topH,
                padding: const EdgeInsets.fromLTRB(20, 0, 16, 0),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: K.borderHairline)),
                ),
                child: Row(
                  children: [
                    DeviceBtn(d: d, go: go),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: StatusCluster(d: d),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Container(width: 1, height: 28, color: K.borderHairline),
                    const SizedBox(width: 24),
                    ModeArm(d: d),
                    const SizedBox(width: 24),
                    EStop(d: d),
                  ],
                ),
              );
        final main = Column(
          children: [
            top,
            Banners(d: d),
            Expanded(child: ClipRect(child: body)),
          ],
        );
        final showToast = toast != null && screen != 'replay';
        return ColoredBox(
          color: K.surfacePage,
          child: Padding(
            padding: EdgeInsets.only(top: pad.top, bottom: pad.bottom),
            child: Stack(
              children: [
                Positioned.fill(
                  child: phone
                      ? Column(
                          children: [
                            Expanded(child: main),
                            Container(
                              height: navH,
                              decoration: const BoxDecoration(
                                color: K.surfaceSunken,
                                border: Border(top: BorderSide(color: K.borderHairline)),
                              ),
                              child: Row(
                                children: [
                                  for (final n in nav.where((n) => n[0] != 'devices' && n[0] != 'guides'))
                                    Expanded(
                                      child: NavBtn(it: n, on: screen == n[0], go: go, variant: 'tab'),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            if (mode == 'desktop') _sidebar(d) else _rail(),
                            Expanded(child: main),
                          ],
                        ),
                ),
                if (showToast)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: navH + 16,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                        decoration: BoxDecoration(
                          color: K.surfaceRaised,
                          border: Border.all(color: K.borderSubtle),
                          borderRadius: BorderRadius.circular(K.radiusCard),
                          boxShadow: K.shadowOverlay,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const KIcon('check', size: 16, color: K.positive),
                            const SizedBox(width: 14),
                            Text('Saved as ${toast!.name}', style: KText.bodySm),
                            const SizedBox(width: 14),
                            KButton(
                              'Replay',
                              size: KSize.sm,
                              variant: KButtonVariant.ghost,
                              onPressed: () {
                                final id = toast!.id;
                                setState(() => toast = null);
                                d.openReplay(id);
                                go('replay');
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (d.liveTel.estop && d.estopAck && d.hasDevice && !showToast)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: navH + 16,
                    child: Center(
                      child: Pressable(
                        onTap: d.unackStop,
                        builder: (_, _, _) => Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(color: K.negative, borderRadius: BorderRadius.circular(K.radiusControl)),
                          child: Center(
                            widthFactor: 1,
                            child: Text(
                              'STOP ENGAGED · TAP TO RESET',
                              style: KText.mono(11, w: FontWeight.w700, color: K.ink900, tracking: K.trLabel),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (d.liveTel.estop && !d.estopAck && d.hasDevice)
                  KModal(
                    onDismiss: d.ackStop,
                    child: KDialogPanel(
                      title: 'Emergency stop engaged',
                      width: 440,
                      onClose: d.ackStop,
                      footer: [
                        KButton('Keep stopped', variant: KButtonVariant.ghost, onPressed: d.ackStop),
                        KButton('Reset stop', onPressed: d.resetStop),
                      ],
                      children: [
                        Text('Motors are stopped and all motion commands are blocked on ${d.device?.name ?? 'the device'}.'),
                        const Text('Check the device before you reset. After reset it stays disarmed until you arm it again.'),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sidebar(Dash d) => Container(
    width: 232,
    decoration: const BoxDecoration(
      color: K.surfaceSunken,
      border: Border(right: BorderSide(color: K.borderHairline)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          alignment: Alignment.centerLeft,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: K.borderHairline)),
          ),
          child: const Brand(),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              for (final n in nav)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: NavBtn(it: n, on: screen == n[0], go: go),
                ),
            ],
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: K.borderHairline)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const MonoLabel('Fleet'),
              for (final dev in d.devices.take(8)) ...[
                const SizedBox(height: 12),
                Pressable(
                  disabled: !dev.online,
                  cursor: dev.online ? null : SystemMouseCursors.basic,
                  onTap: () {
                    if (d.replay != null) d.closeReplay();
                    if (dev.id != d.deviceId) d.connect(dev.id);
                  },
                  builder: (_, h, _) => Row(
                    children: [
                      Expanded(
                        child: Text(
                          dev.name,
                          overflow: TextOverflow.ellipsis,
                          style: KText.bodySm.copyWith(color: dev.id == d.deviceId || h ? K.textPrimary : K.textMuted),
                        ),
                      ),
                      if (dev.simulated) ...[const MonoLabel('Sim', color: K.info, size: 9), const SizedBox(width: 8)],
                      KBadge(
                        dev.id == d.deviceId
                            ? 'Active'
                            : dev.id == d.connecting
                            ? '…'
                            : !dev.online
                            ? 'Off'
                            : 'On',
                        tone: !dev.online
                            ? Tone.negative
                            : dev.id == d.deviceId || dev.id == d.connecting
                            ? Tone.accent
                            : Tone.positive,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );

  Widget _rail() => Container(
    width: 80,
    decoration: const BoxDecoration(
      color: K.surfaceSunken,
      border: Border(right: BorderSide(color: K.borderHairline)),
    ),
    child: Column(
      children: [
        Container(
          height: 64,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: K.borderHairline)),
          ),
          child: const Mark(size: 36),
        ),
        const SizedBox(height: 8),
        for (final n in nav) NavBtn(it: n, on: screen == n[0], go: go, variant: 'rail'),
      ],
    ),
  );
}

class NavBtn extends StatelessWidget {
  const NavBtn({super.key, required this.it, required this.on, required this.go, this.variant = 'side'});
  final List<String> it;
  final bool on;
  final ValueChanged<String> go;
  final String variant;
  @override
  Widget build(BuildContext context) {
    final id = it[0], label = it[1], ic = it[2];
    return Pressable(
      onTap: () => go(id),
      builder: (_, h, _) {
        if (variant == 'tab') {
          return Container(
            height: 60,
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: on ? K.accent : Colors.transparent, width: 2)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                KIcon(ic, size: 20, color: on ? K.accent : K.textMuted),
                const SizedBox(height: 6),
                Text(label.toUpperCase(), style: KText.mono(9, color: on ? K.textPrimary : K.textMuted, tracking: .1)),
              ],
            ),
          );
        }
        if (variant == 'rail') {
          return AnimatedContainer(
            duration: K.durFast,
            padding: const EdgeInsets.symmetric(vertical: 12),
            width: double.infinity,
            decoration: BoxDecoration(
              color: on
                  ? K.whiteA08
                  : h
                  ? K.surfaceHover
                  : Colors.transparent,
              border: Border(left: BorderSide(color: on ? K.accent : Colors.transparent, width: 2)),
            ),
            child: Column(
              children: [
                KIcon(ic, size: 20, color: on ? K.accent : K.textMuted),
                const SizedBox(height: 6),
                Text(label.toUpperCase(), style: KText.mono(9, color: on ? K.textPrimary : K.textMuted, tracking: .1)),
              ],
            ),
          );
        }
        return AnimatedContainer(
          duration: K.durFast,
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: on
                ? K.whiteA08
                : h
                ? K.surfaceHover
                : Colors.transparent,
            border: Border(left: BorderSide(color: on ? K.accent : Colors.transparent, width: 2)),
          ),
          child: Row(
            children: [
              KIcon(
                ic,
                size: 18,
                color: on
                    ? K.accent
                    : on || h
                    ? K.textPrimary
                    : K.textSecondary,
              ),
              const SizedBox(width: 12),
              Text(
                label.toUpperCase(),
                style: KText.mono(13, color: on || h ? K.textPrimary : K.textSecondary, tracking: K.trLabel),
              ),
            ],
          ),
        );
      },
    );
  }
}

class LinkBars extends StatelessWidget {
  const LinkBars({super.key, required this.rssi, required this.lost});
  final double rssi;
  final bool lost;
  @override
  Widget build(BuildContext context) {
    final q = lost
        ? 0
        : rssi > -60
        ? 4
        : rssi > -70
        ? 3
        : rssi > -80
        ? 2
        : 1;
    return SizedBox(
      height: 12,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 1; i <= 4; i++) ...[
            if (i > 1) const SizedBox(width: 2),
            Container(width: 3, height: 3 + i * 2.2, color: i <= q ? (q <= 1 ? K.negative : K.textPrimary) : K.ink400),
          ],
        ],
      ),
    );
  }
}

class BatIcon extends StatelessWidget {
  const BatIcon({super.key, required this.pct});
  final double pct;
  @override
  Widget build(BuildContext context) {
    final c = pct < 20
        ? K.negative
        : pct < 35
        ? K.warning
        : K.textPrimary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 10,
          padding: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            border: Border.all(color: c),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: (pct / 100).clamp(0, 1),
              child: Container(color: c),
            ),
          ),
        ),
        const SizedBox(width: 1),
        Container(width: 2, height: 4, color: c),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.children, required this.title});
  final List<Widget> children;
  final String title;
  @override
  Widget build(BuildContext context) => Tooltip(
    message: title,
    child: DefaultTextStyle(
      style: KText.mono(12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[if (i > 0) const SizedBox(width: 8), children[i]],
        ],
      ),
    ),
  );
}

class StatusCluster extends StatelessWidget {
  const StatusCluster({super.key, required this.d, this.phone = false});
  final Dash d;
  final bool phone;
  @override
  Widget build(BuildContext context) {
    final lost = d.linkLost, s = d.tel;
    if (!d.hasDevice && d.replay == null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: KBadge(d.connecting != null ? 'Connecting' : 'No link', tone: d.connecting != null ? Tone.accent : Tone.warning),
      );
    }
    final lat = d.latency;
    final items = <Widget>[
      if (d.simulated && !phone) const KBadge('Simulated', tone: Tone.info),
      _Stat(
        title: 'Link',
        children: [
          LinkBars(rssi: s.rssi, lost: lost),
          Text(lost ? 'LOST' : '${s.rssi.round()}', style: KText.mono(12, color: lost ? K.negative : null)),
        ],
      ),
      _Stat(
        title: 'Latency',
        children: [
          Text(
            '${lost ? 900 : lat.round()} ms',
            style: KText.mono(
              12,
              color: lost || lat > 150
                  ? K.negative
                  : lat > 60
                  ? K.warning
                  : K.textSecondary,
            ),
          ),
        ],
      ),
      if (d.kind != DeviceKind.arm)
        _Stat(
          title: 'Battery',
          children: [
            BatIcon(pct: s.battery),
            Text('${s.battery.round()}%'),
          ],
        ),
      if (d.recording)
        GestureDetector(
          onTap: d.stopRec,
          child: _Stat(
            title: 'Recording',
            children: [
              const PulseDot(),
              Text(mmss(d.t - d.recStart), style: KText.mono(12, color: K.negative)),
            ],
          ),
        ),
    ];
    return ClipRect(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < items.length; i++) ...[if (i > 0) SizedBox(width: phone ? 10 : 20), items[i]],
          ],
        ),
      ),
    );
  }
}

class ModeArm extends StatelessWidget {
  const ModeArm({super.key, required this.d, this.phone = false});
  final Dash d;
  final bool phone;
  @override
  Widget build(BuildContext context) {
    if (!d.hasDevice && d.replay == null) return const SizedBox();
    final s = d.tel;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        d.replay != null
            ? const KTag('Replay', tone: TagTone.accent)
            : KTag(d.linkLost || s.failsafe ? 'FAILSAFE' : s.mode, tone: s.mode == 'MANUAL' ? TagTone.accent : TagTone.neutral),
        SizedBox(width: phone ? 10 : 16),
        Tooltip(
          message: s.armed ? 'Armed' : 'Disarmed',
          child: KSwitch(
            checked: s.armed,
            disabled: s.estop || d.replay != null,
            label: phone ? null : (s.armed ? 'Armed' : 'Disarmed'),
            onChanged: d.setArmed,
          ),
        ),
      ],
    );
  }
}

class EStop extends StatelessWidget {
  const EStop({super.key, required this.d, this.compact = false});
  final Dash d;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final off = !d.hasDevice || d.replay != null;
    return Semantics(
      button: true,
      label: 'Emergency stop',
      child: _maybeTip(
        d.hasDevice && !d.canControl ? 'STOP is still sent over this telemetry-only radio, but it is slow: up to a second' : null,
        Opacity(
          opacity: off ? .3 : 1,
          child: Pressable(
            disabled: off,
            onTap: d.emergencyStop,
            builder: (_, _, _) => Container(
              height: 44,
              padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 18),
              decoration: BoxDecoration(color: K.negative, borderRadius: BorderRadius.circular(K.radiusControl)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const KIcon('octagon', size: 18, color: K.ink900),
                  const SizedBox(width: 8),
                  Text(
                    'STOP',
                    style: KText.mono(12, w: FontWeight.w700, color: K.ink900, tracking: K.trLabel),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _maybeTip(String? msg, Widget child) => msg == null ? child : Tooltip(message: msg, child: child);
}

class Banners extends StatelessWidget {
  const Banners({super.key, required this.d});
  final Dash d;
  @override
  Widget build(BuildContext context) {
    final lf = d.linkLostFor;
    if (lf > 0) {
      final fs = d.kind == DeviceKind.drone
          ? const {'HOLD': 'holding position', 'RTH': 'returning home', 'LAND': 'landing in place'}[d.settings.failsafe]!
          : 'holding position';
      return KNotice(
        tone: Tone.negative,
        square: true,
        leading: _mark(true),
        title: 'Link lost · ${lf.toStringAsFixed(1)} s',
        child: Text('${lf >= 1.8 ? 'Failsafe active: $fs.' : 'Reconnecting. Failsafe starts at 1.8 s.'} Controls are locked until the link is back.'),
      );
    }
    if (d.linkRestored > 0) {
      return KNotice(tone: Tone.positive, square: true, leading: _mark(false), title: 'Link restored', child: const Text('Manual control is available again.'));
    }
    return const SizedBox();
  }

  // Same element through lost → restored, so the mark lifts back up.
  static Widget _mark(bool lost) => MarkMotion(MarkLoop.link, key: const ValueKey('link-mark'), size: 26, lost: lost, gap: K.surfaceSunken);
}

class NoDevice extends StatelessWidget {
  const NoDevice({super.key, required this.d, required this.w, required this.go});
  final Dash d;
  final double w;
  final ValueChanged<String> go;
  @override
  Widget build(BuildContext context) {
    final phone = w < 600;
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: phone ? const EdgeInsets.symmetric(horizontal: 16, vertical: 40) : const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const MonoLabel('Not connected', color: K.textAccent),
                const SizedBox(height: 12),
                Text('No device connected', style: phone ? KText.headingMd : KText.headingLg),
                const SizedBox(height: 12),
                Text(
                  'Pick a paired device or pair a new one. Telemetry and controls appear once the link is up.',
                  style: KText.bodyMd.copyWith(color: K.textSecondary),
                ),
                if (d.connectError != null) ...[
                  const SizedBox(height: 20),
                  KNotice(tone: Tone.negative, title: 'Could not connect', child: Text(d.connectError!)),
                ],
                SizedBox(height: phone ? 24 : 32),
                hairline,
                if (d.devices.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text('No paired devices yet.', style: KText.bodySm.copyWith(color: K.textMuted)),
                  ),
                for (final dev in d.devices)
                  Opacity(
                    opacity: dev.online ? 1 : .5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: K.borderHairline)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(child: Text(dev.name, style: KText.headingXs)),
                                    if (dev.simulated) ...[const SizedBox(width: 8), const SimTag(height: 20)],
                                  ],
                                ),
                                const SizedBox(height: 6),
                                MonoLabel('${dev.kind.label} · ${!dev.online ? 'Offline' : '${dev.battery}% battery'}'),
                              ],
                            ),
                          ),
                          d.connecting == dev.id
                              ? const Row(children: [MarkMotion(MarkLoop.loading, size: 28), SizedBox(width: 10), MonoLabel('Connecting')])
                              : KButton(
                                  'Connect',
                                  size: KSize.sm,
                                  variant: KButtonVariant.secondary,
                                  onPressed: !dev.online || d.connecting != null ? null : () => d.connect(dev.id),
                                ),
                        ],
                      ),
                    ),
                  ),
                SizedBox(height: phone ? 24 : 32),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    KButton(
                      'Pair new device',
                      variant: KButtonVariant.secondary,
                      iconLeft: const KIcon('plus', size: 16),
                      onPressed: () => showPairDialog(context, d, go),
                    ),
                    KButton('Set up the library', variant: KButtonVariant.ghost, onPressed: () => go('guides')),
                    KButton('Open a recording', variant: KButtonVariant.ghost, onPressed: () => go('replay')),
                    KButton('Add a simulated device', variant: KButtonVariant.ghost, onPressed: () => showPairDialog(context, d, go, simulated: true)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
