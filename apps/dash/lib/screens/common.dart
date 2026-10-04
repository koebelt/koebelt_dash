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
            MonoLabel(label),
            const Spacer(),
            MonoLabel('${(d.speed * 100).round()}%', color: K.textPrimary),
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
