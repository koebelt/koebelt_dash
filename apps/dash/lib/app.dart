import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'core/alerts.dart';
import 'core/dash.dart';
import 'core/model.dart';
import 'core/system_ui.dart';
import 'core/updater.dart' show UpdateState;
import 'screens/assistant_ui.dart';
import 'screens/control.dart';
import 'screens/device_menu.dart';
import 'screens/devices.dart';
import 'screens/guides.dart';
import 'screens/live.dart';
import 'screens/params.dart';
import 'screens/automate.dart';
import 'screens/program.dart';
import 'screens/replay.dart';
import 'screens/script_dialogs.dart' show keyLabelOf;
import 'screens/scripts.dart';
import 'screens/settings.dart';
import 'screens/update_ui.dart';
import 'theme/tokens.dart';
import 'ui/components.dart';
import 'ui/icons.dart';
import 'ui/mark.dart';

/// What Automate opens: always shown under it in the sidebar.
const automateItems = [
  ['program', 'Sequences'],
  ['scripts', 'Scripts'],
];

const nav = [
  ['live', 'Live', 'activity'],
  ['control', 'Control', 'gamepad'],
  // A landing page, and Sequences and Scripts below it (automateItems).
  ['automate', 'Automate', 'list-checks'],
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
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  /// Keys bound to script triggers, except while typing.
  bool _onKey(KeyEvent e) {
    if (e is! KeyDownEvent || widget.dash.scripts.conns.isEmpty) return false;
    final ctx = FocusManager.instance.primaryFocus?.context;
    if (ctx == null || ctx.widget is EditableText || ctx.findAncestorWidgetOfExactType<EditableText>() != null) return false;
    final k = HardwareKeyboard.instance;
    if (k.isMetaPressed || k.isControlPressed || k.isAltPressed) return false;
    return widget.dash.scripts.onKey(keyLabelOf(e.logicalKey));
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CallbackShortcuts(
    // 1–9: show and drive the Nth connected device (text fields keep their digits).
    bindings: {for (var i = 0; i < 9; i++) SingleActivator(LogicalKeyboardKey(LogicalKeyboardKey.digit1.keyId + i)): () => widget.dash.focusNth(i)},
    child: Focus(
      autofocus: true,
      child: ListenableBuilder(
        listenable: widget.dash,
        builder: (_, _) => Shell(d: widget.dash, initial: widget.initial),
      ),
    ),
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

  @override
  void initState() {
    super.initState();
    // An assistant may show a screen.
    widget.d.mcp.onOpen = (s) {
      if (mounted) go(s);
    };
  }
  String? detail;
  Recording? toast;
  String? _seen;
  Timer? _toastT;

  void go(String s) => setState(() {
    detail = null;
    screen = s;
  });

  /// Whether nav item [id] is the screen shown (Automate: or one under it).
  bool _on(String id) => screen == id || (id == 'automate' && (screen == 'program' || screen == 'scripts'));

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
        // With a home indicator below it, the tab bar's buttons sit partly in
        // its strip: 44 pt of buttons, and the bottom 24 pt of the strip left
        // clear for the home swipe and the screen's rounded corners, which
        // would otherwise cut the outer labels. Without one, 60.
        // tabH: the buttons; navH: the whole bar, buttons and clear zone.
        final homeClear = math.min(pad.bottom, 24.0);
        final tabH = pad.bottom > 0 ? 44.0 : 60.0;
        final navH = phone ? tabH + homeClear : 0.0, topH = phone ? 100.0 : 64.0;
        final bodyW = mode == 'desktop'
            ? W - 232
            : mode == 'tablet'
            ? W - 80
            : W;
        // In portrait the tab bar sits above the bottom inset; sideways the
        // screens run down into it (the rail keeps its buttons above it).
        final bodyH = H - topH - navH - pad.top;
        setImmersive(!phone && pad.bottom > 0 && (screen == 'live' || screen == 'control'));
        final none = !d.hasDevice && d.replay == null && const ['live', 'control', 'program', 'params'].contains(screen);
        final Widget body;
        if (none) {
          body = NoDevice(d: d, w: bodyW, go: go);
        } else if (d.replay != null && const ['control', 'program', 'params'].contains(screen)) {
          // Controls, sequences and parameters act on a live device, not a recording.
          body = ReplayHold(d: d, w: bodyW, screen: screen, go: go);
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
            'scripts' => ScriptsScreen(d, w: bodyW, go: go),
            'automate' => AutomateHome(d, w: bodyW, go: go),
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
                            if (d.updater.nudge || d.updater.state == UpdateState.downloading || d.updater.state == UpdateState.installing) ...[
                              const SizedBox(width: 10),
                              UpdateChip(d: d, compact: true),
                            ],
                            if (d.mcp.enabled && d.mcp.connected != null) ...[const SizedBox(width: 10), AssistantChip(d, compact: true)],
                            const SizedBox(width: 10),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 120),
                              child: AlertChip(d: d, compact: true),
                            ),
                            const SizedBox(width: 10),
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
                    const SizedBox(width: 20),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 340),
                      child: AlertChip(d: d),
                    ),
                    if (d.mcp.enabled && d.mcp.connected != null) ...[const SizedBox(width: 12), AssistantChip(d)],
                    const SizedBox(width: 20),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: StatusCluster(d: d),
                      ),
                    ),
                    UpdateChip(d: d, gap: 16),
                    const SizedBox(width: 24),
                    Container(width: 1, height: 28, color: K.borderHairline),
                    const SizedBox(width: 24),
                    ModeArm(d: d),
                    const SizedBox(width: 24),
                    EStop(d: d),
                  ],
                ),
              );
        // Under Automate on phones and tablets (the sidebar lists both on
        // desktops): back to Automate, and the other one a tap away.
        final tabbed = mode != 'desktop' && (screen == 'program' || screen == 'scripts');
        final main = Column(
          children: [
            top,
            if (tabbed) AutomateBar(screen: screen, phone: phone, go: go),
            Expanded(child: ClipRect(child: body)),
          ],
        );
        final showToast = toast != null && screen != 'replay';
        return ColoredBox(
          color: K.surfacePage,
          // Only the top is inset here. The bottom inset (the home indicator on
          // iPhone and iPad): in portrait the tab bar fills it, with its buttons
          // above it; sideways the screens run into it, and on Live and Control
          // the indicator dims and a first swipe from the edge stays in the app
          // (setImmersive below), so a stick near the edge does not go home.
          child: Padding(
            padding: EdgeInsets.only(top: pad.top),
            child: Stack(
              children: [
                Positioned.fill(
                  child: phone
                      ? Column(
                          children: [
                            Expanded(child: main),
                            Container(
                              height: navH,
                              padding: EdgeInsets.only(bottom: homeClear),
                              decoration: const BoxDecoration(
                                color: K.surfaceSunken,
                                border: Border(top: BorderSide(color: K.borderHairline)),
                              ),
                              child: Row(
                                children: [
                                  for (final n in nav.where((n) => !const ['devices', 'guides'].contains(n[0])))
                                    Expanded(
                                      child: NavBtn(it: n, on: _on(n[0]), go: go, variant: 'tab', height: tabH),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            if (mode == 'desktop') _sidebar(d, pad.bottom) else _rail(pad.bottom),
                            Expanded(child: main),
                          ],
                        ),
                ),
                // An assistant's action on real hardware, waiting for the operator.
                if (d.mcp.approvals.isNotEmpty)
                  phone
                      ? Positioned.fill(
                          child: ColoredBox(
                            color: K.scrim,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: ApprovalCard(d, d.mcp.approvals.first, key: ValueKey(d.mcp.approvals.first)),
                              ),
                            ),
                          ),
                        )
                      : Positioned(top: topH + 16, right: 24, child: ApprovalCard(d, d.mcp.approvals.first, key: ValueKey(d.mcp.approvals.first))),
                if (showToast)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: navH + (phone ? 0 : pad.bottom) + 16,
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
                    bottom: navH + (phone ? 0 : pad.bottom) + 16,
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
                        KButton(d.links.values.where((l) => l.tel.estop).length > 1 ? 'Reset all' : 'Reset stop', onPressed: d.resetStop),
                      ],
                      children: [
                        Text(
                          d.links.length > 1
                              ? 'Motors are stopped and all motion commands are blocked on ${d.links.values.where((l) => l.tel.estop).map((l) => l.info.name).join(', ')}.'
                              : 'Motors are stopped and all motion commands are blocked on ${d.device?.name ?? 'the device'}.',
                        ),
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

  /// [bottom]: the screen's bottom inset, which the sidebar's colour fills.
  Widget _sidebar(Dash d, [double bottom = 0]) => Container(
    width: 232,
    padding: EdgeInsets.only(bottom: bottom),
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
              for (final n in nav) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: NavBtn(it: n, on: n[0] == 'automate' ? screen == 'automate' : _on(n[0]), go: go),
                ),
                if (n[0] == 'automate')
                  for (final a in automateItems)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: NavSub(id: a[0], label: a[1], on: screen == a[0], go: go),
                    ),
              ],
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
                      Builder(
                        builder: (_) {
                          final l = d.links[dev.id], lost = (l?.linkLostFor ?? 0) > 0;
                          return KBadge(
                            dev.id == d.deviceId
                                ? 'Active'
                                : lost
                                ? 'Lost'
                                : l != null
                                ? 'Linked'
                                : dev.id == d.connecting
                                ? '…'
                                : !dev.online
                                ? 'Off'
                                : 'On',
                            tone: !dev.online || lost
                                ? Tone.negative
                                : dev.id == d.deviceId || dev.id == d.connecting
                                ? Tone.accent
                                : l != null
                                ? Tone.info
                                : Tone.positive,
                          );
                        },
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

  Widget _rail([double bottom = 0]) => Container(
    width: 80,
    padding: EdgeInsets.only(bottom: bottom),
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
        // Eight buttons are taller than a phone held sideways: they scroll there.
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              children: [for (final n in nav) NavBtn(it: n, on: _on(n[0]), go: go, variant: 'rail')],
            ),
          ),
        ),
      ],
    ),
  );
}

class NavBtn extends StatelessWidget {
  const NavBtn({super.key, required this.it, required this.on, required this.go, this.variant = 'side', this.height = 60});
  final List<String> it;
  final bool on;
  final ValueChanged<String> go;
  final String variant;

  /// The tab bar's height (variant tab).
  final double height;
  @override
  Widget build(BuildContext context) {
    final id = it[0], label = it[1], ic = it[2];
    return Pressable(
      onTap: () => go(id),
      builder: (_, h, _) {
        if (variant == 'tab') {
          return Container(
            height: height,
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: on ? K.accent : Colors.transparent, width: 2)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                KIcon(ic, size: 20, color: on ? K.accent : K.textMuted),
                SizedBox(height: height < 56 ? 4 : 6),
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

/// A screen under a sidebar item (Automate's Sequences and Scripts),
/// indented under its label, on a line that ties them to it.
class NavSub extends StatelessWidget {
  const NavSub({super.key, required this.id, required this.label, required this.on, required this.go});
  final String id, label;
  final bool on;
  final ValueChanged<String> go;
  @override
  Widget build(BuildContext context) => Pressable(
    onTap: () => go(id),
    builder: (_, h, _) => AnimatedContainer(
      duration: K.durFast,
      height: 34,
      margin: const EdgeInsets.only(left: 24),
      padding: const EdgeInsets.only(left: 21),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: on
            ? K.whiteA08
            : h
            ? K.surfaceHover
            : Colors.transparent,
        border: Border(left: BorderSide(color: on ? K.accent : K.borderHairline, width: on ? 2 : 1)),
      ),
      child: Text(label, style: KText.bodySm.copyWith(color: on ? K.textPrimary : (h ? K.textPrimary : K.textSecondary))),
    ),
  );
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
    // Live while anything is connected, replay or not: a device may be moving.
    final off = d.links.isEmpty, n = d.links.length;
    return Semantics(
      button: true,
      label: n > 1 ? 'Emergency stop, all $n devices' : 'Emergency stop',
      child: _maybeTip(
        n > 1
            ? 'Stops all $n connected devices'
            : d.hasDevice && !d.canControl
            ? 'STOP is still sent over this telemetry-only radio, but it is slow: up to a second'
            : null,
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
                    n > 1 && !compact ? 'STOP ALL' : 'STOP',
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

/// Something that needs attention: a lost link, an alert, on the device
/// shown or another connected one.
class Issue {
  const Issue(this.key, this.title, this.body, {required this.tone, this.mark, this.ok, this.show});
  final String key, title, body;
  final Tone tone;

  /// The link mark (lost or lifting back) for link states.
  final bool? mark;
  final VoidCallback? ok, show;
}

List<Issue> issuesOf(Dash d) {
  final out = <Issue>[];
  final lf = d.linkLostFor, several = d.links.length > 1;
  final who = several ? '${d.deviceName} · ' : '';
  if (lf > 0) {
    final fs = d.kind == DeviceKind.drone
        ? const {'HOLD': 'holding position', 'RTH': 'returning home', 'LAND': 'landing in place'}[d.settings.failsafe]!
        : 'holding position';
    out.add(
      Issue(
        'link',
        '${who}Link lost · ${lf.toStringAsFixed(1)} s',
        '${lf >= 1.8 ? 'Failsafe active: $fs.' : 'Reconnecting. Failsafe starts at 1.8 s.'} Controls are locked until the link is back.',
        tone: Tone.negative,
        mark: true,
      ),
    );
  } else if (d.linkRestored > 0) {
    out.add(Issue('link', '${who}Link restored', 'Manual control is available again.', tone: Tone.positive, mark: false));
  }
  Issue alert(ActiveAlert a, String name, VoidCallback ok, [VoidCallback? show]) => Issue(
    'alert-$name-${a.rule.id}',
    '$name${a.rule.label} · ${a.rule.fmt(a.value)}',
    '${a.rule.below ? 'Below' : 'Above'} ${a.rule.fmt(a.limit)}. ${a.rule.act}',
    tone: a.rule.level == AlertLevel.critical ? Tone.negative : Tone.warning,
    ok: ok,
    show: show,
  );
  if (d.replay == null) {
    for (final a in d.alerts.shown) {
      out.add(alert(a, who, () => d.ackAlert(a.rule.id)));
    }
  }
  // The other connected devices: a lost link or an alert still shows, by name.
  for (final l in d.links.values) {
    if (l.id == d.deviceId) continue;
    if (l.linkLostFor > 0) {
      out.add(
        Issue(
          'lost-${l.id}',
          '${l.info.name} · Link lost · ${l.linkLostFor.toStringAsFixed(1)} s',
          'Its failsafe takes over after 1.8 s.',
          tone: Tone.negative,
          show: () => d.focusDevice(l.id),
        ),
      );
    }
    if (d.replay == null) {
      for (final a in l.alerts.shown) {
        out.add(alert(a, '${l.info.name} · ', () => d.ackAlert(a.rule.id, on: l.id), () => d.focusDevice(l.id)));
      }
    }
  }
  // Connected devices this app version does not support.
  for (final l in d.links.values) {
    final why = l.compatProblem;
    if (why == null) continue;
    final newer = why.contains('newer than this version');
    out.add(
      Issue(
        'compat-${l.id}',
        '${l.info.name} · ${newer ? 'Needs a newer app' : 'Library too old'}',
        'Some features may not work: $why. ${newer ? 'Update koebelt dash.' : 'Update the koebelt/link library on the device, or install an older koebelt dash in Settings > Updates.'}',
        tone: Tone.warning,
        show: l.id == d.deviceId ? null : () => d.focusDevice(l.id),
      ),
    );
  }
  // Most urgent first: critical, then warnings, then good news.
  int rank(Tone t) => t == Tone.negative ? 0 : (t == Tone.warning ? 1 : 2);
  return out..sort((a, b) => rank(a.tone) - rank(b.tone));
}

/// Alerts and link problems as one chip in the top bar: the most urgent,
/// and how many more. Tap for all of them. It takes no room of the screen
/// below and moves nothing.
class AlertChip extends StatefulWidget {
  const AlertChip({super.key, required this.d, this.compact = false});
  final Dash d;
  final bool compact;
  @override
  State<AlertChip> createState() => _AlertChipState();
}

class _AlertChipState extends State<AlertChip> {
  final _link = LayerLink();
  OverlayEntry? _entry;

  void _close() {
    _entry?.remove();
    _entry = null;
    if (mounted) setState(() {});
  }

  void _open() {
    // Under the chip, kept inside the screen (on a phone the chip sits at the right).
    final screen = MediaQuery.sizeOf(context), w = (screen.width - 32).clamp(0.0, 420.0);
    final box = context.findRenderObject()! as RenderBox, at = box.localToGlobal(Offset.zero);
    final left = at.dx.clamp(16.0, math.max(16.0, screen.width - 16 - w)).toDouble(), top = at.dy + box.size.height + 10;
    _entry = OverlayEntry(
      builder: (_) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(behavior: HitTestBehavior.translucent, onTap: _close),
          ),
          Positioned(
            left: left,
            top: top,
            child: Material(
              type: MaterialType.transparency,
              child: ListenableBuilder(
                listenable: widget.d,
                builder: (_, _) {
                  final issues = issuesOf(widget.d);
                  if (issues.isEmpty) WidgetsBinding.instance.addPostFrameCallback((_) => _close());
                  return Container(
                    width: w,
                    constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .6),
                    decoration: BoxDecoration(
                      color: K.surfaceRaised,
                      border: Border.all(color: K.borderSubtle),
                      borderRadius: BorderRadius.circular(K.radiusCard),
                      boxShadow: K.shadowOverlay,
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final (i, x) in issues.indexed) ...[
                            if (i > 0) const SizedBox(height: 8),
                            KNotice(
                              key: ValueKey(x.key),
                              tone: x.tone,
                              leading: x.mark == null ? null : _mark(x.mark!),
                              title: x.title,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(x.body),
                                  if (x.ok != null || x.show != null) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        if (x.show != null)
                                          KButton(
                                            'Show',
                                            size: KSize.sm,
                                            variant: KButtonVariant.ghost,
                                            onPressed: () {
                                              x.show!();
                                              _close();
                                            },
                                          ),
                                        if (x.ok != null) KButton('OK', size: KSize.sm, variant: KButtonVariant.ghost, onPressed: x.ok),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_entry!);
    setState(() {});
  }

  @override
  void dispose() {
    _entry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final issues = issuesOf(widget.d);
    if (issues.isEmpty) return const SizedBox.shrink();
    final top = issues.first, c = toneColor(top.tone), more = issues.length - 1;
    return CompositedTransformTarget(
      link: _link,
      child: Semantics(
        button: true,
        label: '${issues.length} alert${issues.length == 1 ? '' : 's'}: ${top.title}',
        child: Pressable(
          onTap: () => _entry == null ? _open() : _close(),
          builder: (_, h, _) => Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: c.withValues(alpha: h ? .22 : .14),
              border: Border.all(color: c.withValues(alpha: .6)),
              borderRadius: BorderRadius.circular(K.radiusControl),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (top.mark != null)
                  SizedBox(width: 18, height: 18, child: _mark(top.mark!))
                else
                  KIcon(top.tone == Tone.positive ? 'check' : (top.tone == Tone.negative ? 'circle-alert' : 'triangle-alert'), size: 16, color: c),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    (widget.compact
                            ? (top.mark == true
                                  ? 'Link lost'
                                  : issues.length == 1
                                  ? '1 alert'
                                  : '${issues.length} alerts')
                            : top.title)
                        .toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: KText.mono(11, w: FontWeight.w600, color: c, tracking: K.trLabel),
                  ),
                ),
                if (more > 0 && !widget.compact) ...[const SizedBox(width: 8), MonoLabel('+$more', color: c)],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Same element through lost → restored, so the mark lifts back up.
  static Widget _mark(bool lost) => MarkMotion(MarkLoop.link, key: const ValueKey('link-mark'), size: 18, lost: lost, gap: K.surfaceSunken);
}

/// Control, Sequences and Tune while a recording plays: they act on live
/// devices, so they wait until the replay is closed.
class ReplayHold extends StatelessWidget {
  const ReplayHold({super.key, required this.d, required this.w, required this.screen, required this.go});
  final Dash d;
  final double w;
  final String screen;
  final ValueChanged<String> go;
  @override
  Widget build(BuildContext context) {
    final phone = w < 600;
    final (title, what) = switch (screen) {
      'control' => ('Controls are off during a replay', 'Controls act'),
      'program' => ('Sequences are off during a replay', 'Sequences run'),
      _ => ('Tuning is off during a replay', 'Parameters are read and written'),
    };
    final live = d.device?.name;
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: phone ? const EdgeInsets.symmetric(horizontal: 16, vertical: 40) : const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MonoLabel('Replay · ${groupTitle(d.replay!.session)}', color: K.textAccent),
                const SizedBox(height: 12),
                Text(title, style: phone ? KText.headingMd : KText.headingLg),
                const SizedBox(height: 12),
                Text(
                  '$what on a connected device, not on a recording. '
                  '${live != null ? 'Exit the replay to get back to $live.' : 'Exit the replay, then connect a device.'}',
                  style: KText.bodyMd.copyWith(color: K.textSecondary),
                ),
                SizedBox(height: phone ? 24 : 32),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    KButton('Back to the replay', iconLeft: const KIcon('replay', size: 16), onPressed: () => go('replay')),
                    KButton(live != null ? 'Exit replay, back to $live' : 'Exit replay', variant: KButtonVariant.secondary, onPressed: d.closeReplay),
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
                SizedBox(height: phone ? 20 : 28),
                Align(
                  alignment: Alignment.centerLeft,
                  child: KButton('Pair new device', iconLeft: const KIcon('plus', size: 16), onPressed: () => showPairDialog(context, d, go)),
                ),
                SizedBox(height: phone ? 24 : 32),
                const MonoLabel('Or'),
                const SizedBox(height: 8),
                hairline,
                _Option(
                  icon: 'devices',
                  title: 'Add a simulated device',
                  desc: 'A virtual drone, rover, arm, rocket or test bench, to try the app without hardware.',
                  onTap: () => showPairDialog(context, d, go, simulated: true),
                ),
                _Option(icon: 'replay', title: 'Open a recording', desc: 'Replay a session, a flight log or the sample recordings.', onTap: () => go('replay')),
                _Option(
                  icon: 'book',
                  title: 'Set up the library',
                  desc: 'Add koebelt/link to your Arduino, Python, ROS 2 or Rust project.',
                  onTap: () => go('guides'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A full-width choice row: icon, title, one line of explanation, arrow.
class _Option extends StatelessWidget {
  const _Option({required this.icon, required this.title, required this.desc, required this.onTap});
  final String icon, title, desc;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    builder: (_, h, _) => Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: h ? K.surfaceHover : Colors.transparent,
        border: const Border(bottom: BorderSide(color: K.borderHairline)),
      ),
      child: Row(
        children: [
          KIcon(icon, size: 18, color: h ? K.textPrimary : K.textSecondary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: KText.bodyMd),
                const SizedBox(height: 4),
                Text(desc, style: KText.bodySm.copyWith(color: K.textMuted)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          KIcon('arrow-right', size: 16, color: h ? K.textAccent : K.textMuted),
        ],
      ),
    ),
  );
}
