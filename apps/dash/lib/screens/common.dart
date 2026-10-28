import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../core/dash.dart';
import '../theme/tokens.dart';
import '../core/model.dart';
import '../ui/components.dart';

/// REC button: starts/stops a session recording.
class RecordButton extends StatelessWidget {
  const RecordButton(this.d, {super.key, this.small = true, this.label = true});
  final Dash d;
  final bool small, label;
  @override
  Widget build(BuildContext context) {
    final off = !d.hasDevice || d.replay != null, rec = d.recording;
    final h = small ? 32.0 : 40.0;
    return Opacity(
      opacity: off ? .38 : 1,
      child: Pressable(
        disabled: off,
        onTap: () => rec ? d.stopRec() : d.startRec(),
        builder: (_, _, _) => ClipRRect(
          borderRadius: BorderRadius.circular(K.radiusControl),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
            child: Container(
              height: h,
              width: label ? null : h,
              padding: label ? const EdgeInsets.symmetric(horizontal: 12) : null,
              decoration: BoxDecoration(
                color: rec ? const Color(0x24EE7A63) : K.inkA60,
                border: Border.all(color: rec ? K.negative : K.borderSubtle),
                borderRadius: BorderRadius.circular(K.radiusControl),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  PulseDot(animate: rec, square: rec),
                  if (label) ...[
                    const SizedBox(width: 8),
                    Text(
                      rec ? mmss(d.t - d.recStart) : 'REC',
                      style: KText.mono(11, color: rec ? K.negative : K.textPrimary, tracking: K.trLabel),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SpeedSlider extends StatelessWidget {
  const SpeedSlider(this.d, {super.key, this.label = 'Speed limit'});
  final Dash d;
  final String label;
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minWidth: 140),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(child: MonoLabel(label, maxLines: 1)),
            const SizedBox(width: 8),
            Flexible(child: MonoLabel('${(d.speed * 100).round()}%', color: K.textPrimary, maxLines: 1)),
          ],
        ),
        const SizedBox(height: 8),
        KSlider(value: d.speed, min: .1, max: 1, step: .05, onChanged: d.setSpeed),
      ],
    ),
  );
}

/// Confirms and sets the home point (vehicles) or home pose (arms).
Future<void> confirmSetHome(BuildContext context, Dash d) async {
  final arm = d.kind == DeviceKind.arm;
  final t = d.liveTel;
  await showKDialog<void>(
    context,
    builder: (ctx) => KDialogPanel(
      title: arm ? 'Set home pose' : 'Set home here',
      width: 460,
      onClose: () => Navigator.pop(ctx),
      footer: [
        KButton('Cancel', variant: KButtonVariant.ghost, onPressed: () => Navigator.pop(ctx)),
        KButton(
          arm ? 'Use this pose' : 'Set home',
          onPressed: () {
            d.setHome();
            Navigator.pop(ctx);
          },
        ),
      ],
      children: [
        if (arm) ...[
          Text('The current joint angles become the pose that Home pose and sequence Home steps move to.'),
          Text([for (final j in t.joints) '${(j * 57.3).toStringAsFixed(1)}°'].join('  ·  '), style: KText.mono(12, color: K.textPrimary)),
        ] else ...[
          Text(
            'The current position becomes home (0, 0). Return-to-home flies back here, and sequence waypoints are measured from here. '
            'The device is ${t.range.toStringAsFixed(1)} m from the current home.',
          ),
          if (t.hasGps) Text('${t.lat.toStringAsFixed(6)}, ${t.lon.toStringAsFixed(6)}', style: KText.mono(12, color: K.textPrimary)),
        ],
      ],
    ),
  );
}

/// The device's control mode, as a segmented control: MANUAL and HOLD are
/// the operator's to choose; AUTO is dash's, lit while a sequence or a
/// script drives the device (with what drives it), dimmed otherwise.
/// Choosing MANUAL or HOLD during AUTO takes the device back.
class ModePicker extends StatelessWidget {
  const ModePicker(this.d, {super.key, this.small = false, this.onPicked});
  final Dash d;
  final bool small;

  /// After the operator chose a mode (Live opens Control on MANUAL).
  final ValueChanged<String>? onPicked;

  @override
  Widget build(BuildContext context) {
    final mode = d.liveTel.mode, who = d.automation, auto = mode == 'AUTO';
    final can = d.hasDevice && d.replay == null && d.canControl && !d.liveTel.estop;
    final h = small ? 30.0 : 38.0, pad = small ? 10.0 : 14.0;
    Widget item(String m, {bool first = false}) => Pressable(
      onTap: can
          ? () {
              d.operatorMode(m);
              onPicked?.call(m);
            }
          : null,
      builder: (_, hover, _) {
        final on = mode == m;
        return AnimatedContainer(
          duration: K.durFast,
          height: h,
          padding: EdgeInsets.symmetric(horizontal: pad),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? K.accent : (hover && can ? K.whiteA08 : Colors.transparent),
            border: first ? null : const Border(left: BorderSide(color: K.borderHairline)),
          ),
          child: Text(
            m,
            style: KText.mono(11, color: on ? K.textOnAccent : K.textSecondary, tracking: K.trLabel),
          ),
        );
      },
    );
    // What drives it, by name: "follow_person" for a script, the sequence's name.
    final name = who?.substring(who.indexOf('·') + 1).trim().replaceAll(RegExp(r'\.py$'), '');
    final autoItem = Tooltip(
      message: auto
          ? '${who ?? 'dash drives it'}. Choose MANUAL or HOLD, or move the sticks, to take it back.'
          : 'dash\'s mode: while a sequence or a script drives the device. Run one from Automate.',
      waitDuration: const Duration(milliseconds: 400),
      child: AnimatedContainer(
        duration: K.durFast,
        height: h,
        padding: EdgeInsets.symmetric(horizontal: pad),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: auto ? K.accent : Colors.transparent,
          border: const Border(left: BorderSide(color: K.borderHairline)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (auto) ...[const PulseDot(color: K.textOnAccent, square: true), const SizedBox(width: 7)],
            Text(
              'AUTO',
              style: KText.mono(11, color: auto ? K.textOnAccent : K.textFaint, tracking: K.trLabel),
            ),
            if (auto && name != null) ...[
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: small ? 110 : 160),
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: KText.mono(10.5, color: K.textOnAccent.withValues(alpha: .7), w: FontWeight.w400),
                ),
              ),
            ],
          ],
        ),
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(K.radiusControl),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
        child: Container(
          decoration: BoxDecoration(
            color: K.inkA60,
            border: Border.all(color: K.borderSubtle),
            borderRadius: BorderRadius.circular(K.radiusControl),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [item('MANUAL', first: true), item('HOLD'), autoItem]),
        ),
      ),
    );
  }
}

/// The control mode as a small badge, where a phone has no room for the
/// control: AUTO lit, with a pulse.
class ModeBadge extends StatelessWidget {
  const ModeBadge(this.d, {super.key, this.height = 30});
  final Dash d;
  final double height;
  @override
  Widget build(BuildContext context) {
    final mode = d.liveTel.mode, auto = mode == 'AUTO';
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: auto ? K.accent : K.inkA60,
        border: Border.all(color: auto ? K.accent : K.borderSubtle),
        borderRadius: BorderRadius.circular(K.radiusControl),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (auto) ...[const PulseDot(color: K.textOnAccent, square: true), const SizedBox(width: 6)],
          Text(
            mode,
            style: KText.mono(11, color: auto ? K.textOnAccent : (mode == 'MANUAL' ? K.textPrimary : K.textSecondary), tracking: K.trLabel),
          ),
        ],
      ),
    );
  }
}
