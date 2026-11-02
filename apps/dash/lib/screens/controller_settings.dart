import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../core/dash.dart';
import '../core/gamepad.dart';
import '../core/model.dart';
import '../theme/tokens.dart';
import '../ui/components.dart';

/// Settings section for USB and Bluetooth game controllers: status, live
/// input, axis and button bindings learned by moving the control.
class ControllerSection extends StatefulWidget {
  const ControllerSection(this.d, {super.key, required this.phone});
  final Dash d;
  final bool phone;
  @override
  State<ControllerSection> createState() => _ControllerSectionState();
}

class _ControllerSectionState extends State<ControllerSection> {
  PadMapper get m => widget.d.padMapper;
  PadConfig get cfg => widget.d.pad;

  @override
  void initState() {
    super.initState();
    m.onLearned = () {
      widget.d.savePad();
      if (mounted) setState(() {});
    };
  }

  @override
  void dispose() {
    m.cancelLearning();
    m.onLearned = null;
    super.dispose();
  }

  void _learn(String slot) => setState(() => m.learning == slot ? m.cancelLearning() : m.startLearning(slot));

  static List<(String, String)> get _axisLabels => [(t.padYawSteer, 'lx'), (t.stickThrottle, 'ly'), (t.padRoll, 'rx'), (t.padPitchDrive, 'ry')];

  @override
  Widget build(BuildContext context) {
    final d = widget.d, g = d.gamepads, phone = widget.phone;
    final pads = g.pads.values.toList();
    final status = !g.available
        ? t.padUnavailable
        : pads.isEmpty
        ? t.padNone
        : t.padConnected(pads.join(', '));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(padding: const EdgeInsets.only(bottom: 4), child: MonoLabel(t.secController)),
        _row(
          title: t.padUse,
          desc: '$status ${t.padUseDesc}',
          child: KSwitch(
            checked: cfg.enabled,
            onChanged: (v) {
              cfg.enabled = v;
              if (!v) m.releaseAll();
              d.savePad();
            },
          ),
        ),
        if (cfg.enabled) ...[
          Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 8),
            child: Row(
              children: [
                Expanded(child: MonoLabel(t.padSticks)),
                if (m.learning != null) MonoLabel(t.padMoveNow, color: K.textAccent),
              ],
            ),
          ),
          ListenableBuilder(
            listenable: d.frame,
            builder: (context, _) {
              final out = m.axes;
              return Column(children: [for (var i = 0; i < 4; i++) _axisRow(i, out[i], phone)]);
            },
          ),
          Padding(padding: const EdgeInsets.only(top: 20, bottom: 8), child: MonoLabel(t.padButtons)),
          ListenableBuilder(
            listenable: d.frame,
            builder: (context, _) => Column(children: [for (final a in PadAction.values) _buttonRow(a, phone)]),
          ),
          _row(
            title: t.padDeadzone,
            desc: t.padDeadzoneDesc((cfg.deadzone * 100).round()),
            child: SizedBox(
              width: 200,
              child: KSlider(
                value: cfg.deadzone,
                min: 0,
                max: .3,
                step: .01,
                onChanged: (v) {
                  cfg.deadzone = v;
                  d.savePad();
                },
              ),
            ),
          ),
          _row(
            title: t.padExpo,
            desc: t.padExpoDesc((cfg.expo * 100).round()),
            child: SizedBox(
              width: 200,
              child: KSlider(
                value: cfg.expo,
                min: 0,
                max: 1,
                step: .05,
                onChanged: (v) {
                  cfg.expo = v;
                  d.savePad();
                },
              ),
            ),
          ),
          _row(
            title: t.padResetMapping,
            desc: t.padResetMappingDesc,
            child: KButton(
              t.reset,
              size: KSize.sm,
              variant: KButtonVariant.ghost,
              onPressed: () {
                m.cancelLearning();
                cfg.reset();
                d.savePad();
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _row({required String title, String? desc, required Widget child}) => Container(
    padding: const EdgeInsets.symmetric(vertical: 20),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: K.borderHairline)),
    ),
    child: widget.phone
        ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_text(title, desc), const SizedBox(height: 12), child])
        : Row(
            children: [
              Expanded(child: _text(title, desc)),
              const SizedBox(width: 32),
              child,
            ],
          ),
  );

  Widget _text(String title, String? desc) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: KText.bodyMd),
      if (desc != null) ...[
        const SizedBox(height: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Text(desc, style: KText.bodySm.copyWith(color: K.textMuted)),
        ),
      ],
    ],
  );

  Widget _axisRow(int i, double v, bool phone) {
    final b = cfg.axes[i], slot = 'axis:$i', learning = m.learning == slot;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: K.borderHairline)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: phone ? 92 : 140,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_axisLabels[i].$1, style: KText.bodySm),
                const SizedBox(height: 2),
                MonoLabel(_axisLabels[i].$2, size: 9),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MonoLabel(learning ? t.waiting : padSourceLabel(b.src), color: learning ? K.textAccent : K.textSecondary, maxLines: 1),
                const SizedBox(height: 6),
                _Bar(v),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Shrinks on a small phone with long words (other languages, large text).
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Tooltip(
                    message: t.invertDirection,
                    child: Pressable(
                      onTap: () {
                        b.invert = !b.invert;
                        widget.d.savePad();
                      },
                      builder: (_, _, _) => KTag(b.invert ? t.inverted : t.normal, tone: b.invert ? TagTone.accent : TagTone.neutral, height: 26),
                    ),
                  ),
                  const SizedBox(width: 8),
                  KButton(
                    learning ? t.cancel : t.learn,
                    size: KSize.sm,
                    variant: learning ? KButtonVariant.primary : KButtonVariant.ghost,
                    onPressed: () => _learn(slot),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buttonRow(PadAction a, bool phone) {
    final src = cfg.buttons[a], slot = 'btn:${a.name}', learning = m.learning == slot;
    final down = src != null && (m.values[src] ?? 0) > .5;
    final hold = m.holdProgress(a);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: K.borderHairline)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: phone ? 92 : 140,
            child: Text(a.label, style: KText.bodySm.copyWith(color: a == PadAction.stop ? K.negative : K.textPrimary)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MonoLabel(learning ? t.waiting : padSourceLabel(src), color: learning ? K.textAccent : (down ? K.textAccent : K.textSecondary), maxLines: 1),
                if (!phone) ...[const SizedBox(height: 2), MonoLabel(a.hint, size: 9, maxLines: 1)],
                if (hold > 0) ...[const SizedBox(height: 4), _Bar(hold, from0: true)],
              ],
            ),
          ),
          if (src != null && !learning)
            KIconButton(
              'x',
              label: t.clearName(a.label),
              size: KSize.sm,
              variant: KIconButtonVariant.bare,
              onPressed: () {
                cfg.buttons[a] = null;
                widget.d.savePad();
              },
            ),
          const SizedBox(width: 8),
          KButton(
            learning ? t.cancel : t.learn,
            size: KSize.sm,
            variant: learning ? KButtonVariant.primary : KButtonVariant.ghost,
            onPressed: () => _learn(slot),
          ),
        ],
      ),
    );
  }
}

/// Centre-zero bar for an axis value −1…1 (or 0…1 with [from0]).
class _Bar extends StatelessWidget {
  const _Bar(this.v, {this.from0 = false});
  final double v;
  final bool from0;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 6,
    child: LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth, mid = from0 ? 0.0 : w / 2;
        final x = from0 ? v.clamp(0.0, 1.0) * w : mid + v.clamp(-1.0, 1.0) * w / 2;
        return Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(color: K.whiteA08, borderRadius: BorderRadius.circular(3)),
              ),
            ),
            if (!from0)
              Positioned(
                left: mid - .5,
                top: 0,
                bottom: 0,
                child: Container(width: 1, color: K.borderSubtle),
              ),
            Positioned(
              left: x < mid ? x : mid,
              width: (x - mid).abs(),
              top: 0,
              bottom: 0,
              child: DecoratedBox(
                decoration: BoxDecoration(color: K.accent, borderRadius: BorderRadius.circular(3)),
              ),
            ),
          ],
        );
      },
    ),
  );
}

/// Small status chip for the control screen: which controller is driving.
class PadChip extends StatelessWidget {
  const PadChip(this.d, {super.key});
  final Dash d;
  @override
  Widget build(BuildContext context) {
    final g = d.gamepads;
    if (!d.pad.enabled || g.pads.isEmpty) return const SizedBox.shrink();
    final name = g.active ?? g.pads.values.first;
    final driving = d.padCanDrive;
    return Tooltip(
      message: driving
          ? t.padDrives(name, d.deviceName)
          : d.kind == DeviceKind.drone || d.kind == DeviceKind.rover
          ? t.padArmToDrive(name)
          : t.padButtonsWork,
      child: KTag('${t.pad} · $name', tone: driving ? TagTone.accent : TagTone.neutral),
    );
  }
}
