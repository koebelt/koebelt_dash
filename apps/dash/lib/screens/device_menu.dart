import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../core/dash.dart';
import '../core/device_link.dart';
import '../core/sequence.dart';
import '../core/model.dart';
import '../theme/tokens.dart';
import '../ui/components.dart';
import '../ui/icons.dart';
import '../ui/mark.dart';
import 'devices.dart';
import 'replay.dart' show groupTitle;

/// The device name at the top left. Opens a popover to see the active
/// device, switch to another paired one, disconnect, or pair a new one.
class DeviceBtn extends StatefulWidget {
  const DeviceBtn({super.key, required this.d, required this.go, this.sub = true});
  final Dash d;
  final ValueChanged<String> go;
  final bool sub;
  @override
  State<DeviceBtn> createState() => _DeviceBtnState();
}

class _DeviceBtnState extends State<DeviceBtn> {
  final _link = LayerLink();
  final _focus = FocusNode(debugLabel: 'device menu');
  OverlayEntry? _entry;

  bool get open => _entry != null;

  void _toggle() => open ? _close() : _open();

  void _open() {
    final screenW = MediaQuery.sizeOf(context).width;
    final w = (screenW - 32).clamp(0.0, 340.0);
    _entry = OverlayEntry(
      builder: (_) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(behavior: HitTestBehavior.translucent, onTap: _close),
          ),
          CompositedTransformFollower(
            link: _link,
            targetAnchor: Alignment.bottomLeft,
            followerAnchor: Alignment.topLeft,
            offset: const Offset(0, 10),
            child: CallbackShortcuts(
              bindings: {const SingleActivator(LogicalKeyboardKey.escape): _close},
              child: Focus(
                focusNode: _focus,
                child: Material(
                  type: MaterialType.transparency,
                  child: ListenableBuilder(
                    listenable: widget.d,
                    builder: (_, _) => DeviceMenu(
                      d: widget.d,
                      width: w,
                      onClose: _close,
                      go: (s) {
                        _close();
                        widget.go(s);
                      },
                      pair: () {
                        _close();
                        showPairDialog(context, widget.d, widget.go);
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_entry!);
    // Keyboard focus moves into the popover so Escape closes it.
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
    setState(() {});
  }

  void _close() {
    _entry?.remove();
    _entry = null;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _entry?.remove();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.d, dev = d.device;
    final nm = d.replay?.session.deviceName ?? dev?.name ?? (d.connecting != null ? '${t.connecting}…' : t.noDevice);
    return CompositedTransformTarget(
      link: _link,
      child: Semantics(
        button: true,
        expanded: open,
        label: t.navDevices,
        child: Pressable(
          onTap: _toggle,
          builder: (_, h, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // The name first; the tags after it only while they fit
                    // on its line (a narrow bar drops them, whole, onto a
                    // second line that is clipped away).
                    SizedBox(
                      height: MediaQuery.textScalerOf(context).scale(24),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 24,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        clipBehavior: Clip.hardEdge,
                        children: [
                          Text(nm, style: KText.headingXs, maxLines: 1, overflow: TextOverflow.ellipsis),
                          if (d.replay != null) KTag(t.navReplay, tone: TagTone.info, height: 20),
                          // On a phone (no second line) one tag: Replay wins.
                          if (d.simulated && (widget.sub || d.replay == null)) SimTag(text: d.replay != null ? t.tagDemo : t.tagSim, height: 20),
                          if (!widget.sub && d.replay == null && d.links.length > 1) MonoLabel('+${d.links.length - 1}', color: K.textAccent),
                        ],
                      ),
                    ),
                    if (widget.sub) ...[
                      const SizedBox(height: 6),
                      MonoLabel(
                        [
                          if (d.replay != null) '${t.navReplay} · ${groupTitle(d.replay!.session)}' else if (dev != null) d.kind.label else t.notConnected,
                          if (d.replay == null && d.links.length > 1) t.moreConnected(d.links.length - 1),
                        ].join(' · '),
                        maxLines: 1,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              AnimatedRotation(
                turns: open ? .5 : 0,
                duration: K.durFast,
                child: KIcon('chevron-down', size: 16, color: h || open ? K.textPrimary : K.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Popover content: active device, the other paired devices, actions.
class DeviceMenu extends StatelessWidget {
  const DeviceMenu({super.key, required this.d, required this.width, required this.onClose, required this.go, required this.pair});
  final Dash d;
  final double width;
  final VoidCallback onClose, pair;
  final ValueChanged<String> go;

  @override
  Widget build(BuildContext context) {
    final active = d.replay == null ? d.device : null;
    final connected = [
      for (final l in d.links.values)
        if (l.id != active?.id) l,
    ];
    final others = d.devices.where((x) => x.id != active?.id && !d.links.containsKey(x.id)).toList();
    final maxH = MediaQuery.sizeOf(context).height * .7;
    return Container(
      width: width,
      constraints: BoxConstraints(maxHeight: maxH),
      decoration: BoxDecoration(
        color: K.surfaceRaised,
        border: Border.all(color: K.borderSubtle),
        borderRadius: BorderRadius.circular(K.radiusCard),
        boxShadow: K.shadowOverlay,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (d.replay != null) _replay(),
                  if (active != null) _active(active),
                  if (connected.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 8, 4),
                      child: Row(
                        children: [
                          Expanded(child: MonoLabel(t.alsoConnected)),
                          KButton(t.disconnectAll, size: KSize.sm, variant: KButtonVariant.ghost, onPressed: d.disconnectAll),
                        ],
                      ),
                    ),
                    for (final l in connected) _linked(l),
                  ],
                  if (others.isNotEmpty) ...[
                    Padding(padding: const EdgeInsets.fromLTRB(16, 10, 16, 4), child: MonoLabel(d.links.isNotEmpty ? t.connectAnother : t.pairedDevices)),
                    for (final x in others) _row(x),
                  ],
                  if (d.devices.isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.noPairedDevicesShort, style: KText.bodyMd),
                          const SizedBox(height: 6),
                          Text(t.noPairedDevicesHint, style: KText.bodySm.copyWith(color: K.textMuted)),
                        ],
                      ),
                    ),
                  if (d.connectError != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                      child: KNotice(tone: Tone.negative, child: Text(d.connectError!)),
                    ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: K.borderHairline)),
            ),
            child: Row(
              children: [
                KButton(t.pairDevice, size: KSize.sm, variant: KButtonVariant.secondary, iconLeft: const KIcon('plus', size: 14), onPressed: pair),
                const Spacer(),
                KButton(
                  d.devices.isEmpty ? t.quickstart : t.manage,
                  size: KSize.sm,
                  variant: KButtonVariant.ghost,
                  iconRight: const KIcon('arrow-right', size: 14),
                  onPressed: () => go(d.devices.isEmpty ? 'guides' : 'devices'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _replay() {
    final r = d.replay!.session;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MonoLabel(t.replaying, color: K.textAccent),
          const SizedBox(height: 8),
          Text(r.name, style: KText.bodyMd, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          MonoLabel('${r.deviceName} · ${r.date}', maxLines: 1),
          const SizedBox(height: 10),
          KButton(
            t.closeReplay,
            size: KSize.sm,
            variant: KButtonVariant.secondary,
            onPressed: () {
              d.closeReplay();
              onClose();
            },
          ),
        ],
      ),
    );
  }

  Widget _active(DeviceInfo x) {
    final tel = d.liveTel;
    final facts = [
      x.kind.label,
      x.simulated ? t.simulator : (x.via.isEmpty ? x.transport.label : x.via),
      '${tel.battery.round()} %',
      if (!x.simulated || d.latency > 0) '${d.latency.round()} ms',
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: K.surfaceAccentSoft,
        border: Border.all(color: K.limeA32),
        borderRadius: BorderRadius.circular(K.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PulseDot(color: d.linkLost ? K.negative : K.accent),
              const SizedBox(width: 8),
              Flexible(
                child: Text(x.name, style: KText.bodyMd, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              if (x.simulated) const SimTag(height: 20) else KTag(x.transport.label, height: 20),
            ],
          ),
          const SizedBox(height: 8),
          MonoLabel(facts.join(' · '), maxLines: 2, height: 1.4),
          const SizedBox(height: 10),
          Row(
            children: [
              KButton(
                t.disconnect,
                size: KSize.sm,
                variant: KButtonVariant.ghost,
                onPressed: () {
                  d.disconnect();
                  onClose();
                },
              ),
              const Spacer(),
              KButton(t.open, size: KSize.sm, variant: KButtonVariant.secondary, onPressed: () => go('live')),
            ],
          ),
        ],
      ),
    );
  }

  /// A connected device that is not focused: tap to show it, ✕ to disconnect.
  Widget _linked(DeviceLink l) {
    final x = l.info, tel = l.tel, lost = l.linkLostFor > 0, alerts = l.alerts.shown.length;
    final facts = [
      if (lost) t.linkLost else tel.mode,
      if (tel.armed) t.armed,
      if (tel.seen.contains('bat')) '${tel.battery.round()} %',
      if (alerts > 0) t.alerts(alerts),
      if (l.runner?.state == RunState.running) t.sequenceRunning,
    ];
    return Pressable(
      onTap: () => d.focusDevice(x.id),
      builder: (_, h, _) => Container(
        color: h ? K.whiteA06 : Colors.transparent,
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          children: [
            PulseDot(color: lost || tel.estop ? K.negative : (alerts > 0 ? K.warning : K.positive), animate: !lost),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(x.name, style: KText.bodySm, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  MonoLabel(facts.join(' · '), size: 9, color: lost ? K.negative : null, maxLines: 1),
                ],
              ),
            ),
            MonoLabel(t.show, color: h ? K.textAccent : K.textMuted),
            KIconButton(
              'x',
              label: t.disconnectName(x.name),
              size: KSize.sm,
              variant: KIconButtonVariant.bare,
              onPressed: () => d.disconnect(id: x.id),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(DeviceInfo x) {
    final connecting = d.connecting == x.id;
    final disabled = !x.online || (d.connecting != null && !connecting);
    return Pressable(
      disabled: disabled,
      onTap: () {
        // Switching keeps the previous device in its mode; drones hold.
        d.connect(x.id);
      },
      builder: (_, h, _) => Container(
        color: h ? K.whiteA06 : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Opacity(
          opacity: disabled && !connecting ? .45 : 1,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(x.name, style: KText.bodySm, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 8),
                        if (x.simulated) const SimTag(height: 18) else KTag(x.transport.label, height: 18),
                      ],
                    ),
                    const SizedBox(height: 4),
                    MonoLabel('${x.kind.label}${x.online ? '' : ' · ${t.offline}'}', size: 9),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (connecting)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const MarkMotion(MarkLoop.loading, size: 28, gap: K.surfaceRaised),
                    const SizedBox(width: 8),
                    MonoLabel(t.connecting),
                  ],
                )
              else if (!disabled)
                MonoLabel(t.connect, color: h ? K.textAccent : K.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
