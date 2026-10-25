// KOEBELT design-system components (Button, IconButton, Badge, Tag, Switch,
// Notice, Dialog, Tabs, Input) plus the dash-specific Seg, Readout, KSlider.
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'icons.dart';

/// Hover + press state wrapper. Press scales to 0.985, never lifts.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.builder, this.onTap, this.disabled = false, this.cursor});
  final Widget Function(BuildContext, bool hover, bool press) builder;
  final VoidCallback? onTap;
  final bool disabled;
  final MouseCursor? cursor;
  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _h = false, _p = false;
  @override
  Widget build(BuildContext context) {
    final off = widget.disabled || widget.onTap == null;
    return MouseRegion(
      cursor: widget.cursor ?? (widget.disabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click),
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = _p = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: off ? null : (_) => setState(() => _p = true),
        onTapUp: off ? null : (_) => setState(() => _p = false),
        onTapCancel: () => setState(() => _p = false),
        onTap: off ? null : widget.onTap,
        child: AnimatedScale(
          scale: _p && !off ? K.pressScale : 1,
          duration: K.durFast,
          curve: K.easeStandard,
          child: widget.builder(context, _h && !widget.disabled, _p && !off),
        ),
      ),
    );
  }
}

enum KButtonVariant { primary, secondary, ghost, inverse }

enum KSize { sm, md, lg }

class KButton extends StatelessWidget {
  const KButton(
    this.label, {
    super.key,
    this.onPressed,
    this.variant = KButtonVariant.primary,
    this.size = KSize.md,
    this.iconLeft,
    this.iconRight,
    this.fullWidth = false,
    this.padding,
  });
  final String label;
  final VoidCallback? onPressed;
  final KButtonVariant variant;
  final KSize size;
  final Widget? iconLeft, iconRight;
  final bool fullWidth;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    final h = switch (size) {
      KSize.sm => 32.0,
      KSize.md => 44.0,
      KSize.lg => 56.0,
    };
    final px = switch (size) {
      KSize.sm => K.s4,
      KSize.md => K.s6,
      KSize.lg => K.s8,
    };
    final fs = size == KSize.sm ? 11.0 : 13.0;
    return Opacity(
      opacity: disabled ? .38 : 1,
      child: Pressable(
        disabled: disabled,
        onTap: onPressed,
        builder: (context, hover, _) {
          Color bg, fg, border;
          switch (variant) {
            case KButtonVariant.primary:
              bg = hover ? K.accentHover : K.accent;
              fg = K.textOnAccent;
              border = bg;
            case KButtonVariant.secondary:
              bg = Colors.transparent;
              fg = K.textPrimary;
              border = hover ? K.borderStrong : K.borderSubtle;
            case KButtonVariant.ghost:
              bg = hover ? K.whiteA08 : Colors.transparent;
              fg = hover ? K.textPrimary : K.textSecondary;
              border = Colors.transparent;
            case KButtonVariant.inverse:
              bg = hover ? K.ink050 : K.surfaceInverse;
              fg = K.textInverse;
              border = bg;
          }
          return AnimatedContainer(
            duration: K.durFast,
            curve: K.easeStandard,
            height: h,
            width: fullWidth ? double.infinity : null,
            padding: padding ?? EdgeInsets.symmetric(horizontal: px),
            decoration: BoxDecoration(
              color: bg,
              border: Border.all(color: border),
              borderRadius: BorderRadius.circular(K.radiusControl),
            ),
            child: DefaultTextStyle(
              style: KText.mono(fs, color: fg, tracking: K.trLabel),
              child: IconTheme(
                data: IconThemeData(color: fg),
                child: Row(
                  mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (iconLeft != null) ...[iconLeft!, const SizedBox(width: K.s3)],
                    Flexible(child: Text(label.toUpperCase(), maxLines: 1, overflow: TextOverflow.clip, softWrap: false)),
                    if (iconRight != null) ...[const SizedBox(width: K.s3), iconRight!],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

enum KIconButtonVariant { outline, solid, bare }

class KIconButton extends StatelessWidget {
  const KIconButton(this.icon, {super.key, required this.label, this.onPressed, this.size = KSize.md, this.variant = KIconButtonVariant.outline});
  final String icon, label;
  final VoidCallback? onPressed;
  final KSize size;
  final KIconButtonVariant variant;
  @override
  Widget build(BuildContext context) {
    final d = switch (size) {
      KSize.sm => 32.0,
      KSize.md => 40.0,
      KSize.lg => 48.0,
    };
    final disabled = onPressed == null;
    return Semantics(
      button: true,
      label: label,
      child: Tooltip(
        message: label,
        waitDuration: const Duration(milliseconds: 600),
        child: Opacity(
          opacity: disabled ? .38 : 1,
          child: Pressable(
            disabled: disabled,
            onTap: onPressed,
            builder: (context, hover, _) {
              Color bg, fg, border;
              switch (variant) {
                case KIconButtonVariant.solid:
                  bg = hover ? K.accentHover : K.accent;
                  fg = K.textOnAccent;
                  border = bg;
                case KIconButtonVariant.bare:
                  bg = hover ? K.whiteA08 : Colors.transparent;
                  fg = hover ? K.textPrimary : K.textSecondary;
                  border = Colors.transparent;
                case KIconButtonVariant.outline:
                  bg = Colors.transparent;
                  fg = K.textPrimary;
                  border = hover ? K.borderStrong : K.borderSubtle;
              }
              return AnimatedContainer(
                duration: K.durFast,
                width: d,
                height: d,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: bg,
                  border: Border.all(color: border),
                  borderRadius: BorderRadius.circular(K.radiusControl),
                ),
                child: KIcon(icon, size: size == KSize.sm ? 16 : 18, color: fg),
              );
            },
          ),
        ),
      ),
    );
  }
}

enum Tone { positive, warning, negative, info, accent }

Color toneColor(Tone t) => switch (t) {
  Tone.positive => K.positive,
  Tone.warning => K.warning,
  Tone.negative => K.negative,
  Tone.info => K.info,
  Tone.accent => K.accent,
};

class KBadge extends StatelessWidget {
  const KBadge(this.text, {super.key, this.tone = Tone.positive, this.dot = true});
  final String text;
  final Tone tone;
  final bool dot;
  @override
  Widget build(BuildContext context) {
    final c = toneColor(tone);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (dot) ...[
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
          ),
          const SizedBox(width: K.s3),
        ],
        // Ends in … where a row is too narrow for it, rather than overflowing.
        Flexible(
          child: Text(
            text.toUpperCase(),
            style: KText.label(color: c),
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

enum TagTone { neutral, accent, solid, info }

class KTag extends StatelessWidget {
  const KTag(this.text, {super.key, this.tone = TagTone.neutral, this.height = 26});
  final String text;
  final TagTone tone;
  final double height;
  @override
  Widget build(BuildContext context) {
    final (bg, fg, bd) = switch (tone) {
      TagTone.neutral => (Colors.transparent, K.textMuted, K.borderHairline),
      TagTone.accent => (K.surfaceAccentSoft, K.textAccent, K.limeA32),
      TagTone.solid => (K.accent, K.textOnAccent, K.accent),
      TagTone.info => (const Color(0x1F8FB9E0), K.info, const Color(0x668FB9E0)),
    };
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: K.s4),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: bd),
        borderRadius: BorderRadius.circular(K.radiusPill),
      ),
      child: Center(
        widthFactor: 1,
        child: Text(text.toUpperCase(), style: KText.label(color: fg), maxLines: 1, softWrap: false),
      ),
    );
  }
}

class KSwitch extends StatelessWidget {
  const KSwitch({super.key, required this.checked, this.onChanged, this.label, this.disabled = false});
  final bool checked;
  final ValueChanged<bool>? onChanged;
  final String? label;
  final bool disabled;
  @override
  Widget build(BuildContext context) {
    final off = disabled || onChanged == null;
    return Opacity(
      opacity: off ? .38 : 1,
      child: Pressable(
        disabled: off,
        onTap: off ? null : () => onChanged!(!checked),
        builder: (_, _, _) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: K.durFast,
              width: 40,
              height: 22,
              decoration: BoxDecoration(
                color: checked ? K.accent : Colors.transparent,
                border: Border.all(color: checked ? K.accent : K.borderSubtle),
                borderRadius: BorderRadius.circular(K.radiusPill),
              ),
              child: AnimatedAlign(
                duration: K.durFast,
                curve: K.easeStandard,
                alignment: checked ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.all(2),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(color: checked ? K.textOnAccent : K.textMuted, shape: BoxShape.circle),
                ),
              ),
            ),
            if (label != null) ...[const SizedBox(width: K.s4), Text(label!.toUpperCase(), style: KText.label())],
          ],
        ),
      ),
    );
  }
}

class KNotice extends StatelessWidget {
  const KNotice({super.key, this.tone = Tone.info, this.title, required this.child, this.square = false, this.leading});
  final Tone tone;
  final String? title;
  final Widget child;

  /// Replaces the tone icon (18 px slot).
  final Widget? leading;

  /// Full-bleed banner variant used under the top bar (radius 0, 3px left border).
  final bool square;
  @override
  Widget build(BuildContext context) {
    final c = toneColor(tone);
    final icon = switch (tone) {
      Tone.positive => 'check',
      Tone.warning => 'triangle-alert',
      Tone.negative => 'circle-alert',
      _ => 'info',
    };
    final body = Padding(
      padding: const EdgeInsets.symmetric(horizontal: K.s6, vertical: K.s5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: leading ?? KIcon(icon, size: 18, color: c),
          ),
          const SizedBox(width: K.s5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(
                    title!.toUpperCase(),
                    style: KText.mono(13, color: c, tracking: K.trLabel),
                  ),
                  const SizedBox(height: K.s2 + 2),
                ],
                DefaultTextStyle(
                  style: KText.bodySm.copyWith(color: K.textSecondary),
                  child: child,
                ),
              ],
            ),
          ),
        ],
      ),
    );
    // Rounded borders must be uniform in Flutter, so the tone stripe is drawn as its own strip.
    return ClipRRect(
      borderRadius: BorderRadius.circular(square ? 0 : K.radiusControl),
      child: Container(
        decoration: BoxDecoration(
          color: K.surfaceSunken,
          border: square ? const Border(bottom: BorderSide(color: K.borderHairline)) : Border.all(color: K.borderHairline),
          borderRadius: square ? null : BorderRadius.circular(K.radiusControl),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: square ? 3 : 2, color: c),
              Expanded(child: body),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dialog panel. Use [showKDialog] for imperative dialogs, or [KModal] for
/// dialogs driven by state (e.g. the emergency-stop dialog).
class KDialogPanel extends StatelessWidget {
  const KDialogPanel({super.key, required this.title, required this.onClose, required this.children, this.footer, this.width = 520});
  final String title;
  final VoidCallback onClose;
  final List<Widget> children;
  final List<Widget>? footer;
  final double width;
  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: width, maxHeight: MediaQuery.sizeOf(context).height - 48),
      child: Material(
        type: MaterialType.transparency,
        child: Container(
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
              Container(
                padding: const EdgeInsets.fromLTRB(K.s7, K.s6 - 4, K.s6, K.s6 - 4),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: K.borderHairline)),
                ),
                child: Row(
                  children: [
                    Expanded(child: Text(title, style: KText.headingXs)),
                    KIconButton('x', label: 'Close', size: KSize.sm, variant: KIconButtonVariant.bare, onPressed: onClose),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(K.s7),
                  child: DefaultTextStyle(
                    style: KText.bodySm.copyWith(color: K.textSecondary),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < children.length; i++) ...[if (i > 0) const SizedBox(height: K.s5), children[i]],
                      ],
                    ),
                  ),
                ),
              ),
              if (footer != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: K.s7, vertical: K.s6 - 4),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: K.borderHairline)),
                  ),
                  child: Wrap(alignment: WrapAlignment.end, spacing: K.s4, runSpacing: K.s3, children: footer!),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class KModal extends StatelessWidget {
  const KModal({super.key, required this.onDismiss, required this.child});
  final VoidCallback onDismiss;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: onDismiss,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 9, sigmaY: 9),
          child: Container(
            color: K.scrim,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(K.s7),
            child: GestureDetector(onTap: () {}, child: child),
          ),
        ),
      ),
    );
  }
}

Future<T?> showKDialog<T>(BuildContext context, {required Widget Function(BuildContext) builder}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: Colors.transparent,
    transitionDuration: K.durBase,
    pageBuilder: (ctx, _, _) => Stack(
      children: [KModal(onDismiss: () => Navigator.of(ctx).pop(), child: builder(ctx))],
    ),
    transitionBuilder: (_, a, _, child) => FadeTransition(
      opacity: CurvedAnimation(parent: a, curve: K.easeStandard),
      child: child,
    ),
  );
}

class KTabs extends StatelessWidget {
  const KTabs({super.key, required this.items, required this.value, required this.onChanged, this.border = true});
  final List<String> items;
  final String value;
  final ValueChanged<String> onChanged;
  final bool border;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: border
          ? const BoxDecoration(
              border: Border(bottom: BorderSide(color: K.borderHairline)),
            )
          : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: K.s7),
            Pressable(
              onTap: () => onChanged(items[i]),
              builder: (_, hover, _) {
                final on = items[i] == value;
                return Container(
                  padding: const EdgeInsets.only(bottom: K.s4),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: on ? K.accent : Colors.transparent, width: 2)),
                  ),
                  child: Text(
                    items[i].toUpperCase(),
                    style: KText.mono(13, color: on || hover ? K.textPrimary : K.textMuted, tracking: K.trLabel),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class KInput extends StatefulWidget {
  const KInput({super.key, this.controller, this.placeholder, this.onChanged, this.height = 48, this.style, this.keyboardType});
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final String? placeholder;
  final ValueChanged<String>? onChanged;
  final double height;
  final TextStyle? style;
  @override
  State<KInput> createState() => _KInputState();
}

class _KInputState extends State<KInput> {
  final _focus = FocusNode();
  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final st = widget.style ?? KText.bodyMd;
    return AnimatedContainer(
      duration: K.durFast,
      height: widget.height,
      padding: const EdgeInsets.symmetric(horizontal: K.s5),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: K.surfaceSunken,
        border: Border.all(color: _focus.hasFocus ? K.accent : K.borderHairline),
        borderRadius: BorderRadius.circular(K.radiusControl),
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focus,
        onChanged: widget.onChanged,
        keyboardType: widget.keyboardType,
        style: st,
        cursorColor: K.accent,
        decoration: InputDecoration.collapsed(
          hintText: widget.placeholder,
          hintStyle: st.copyWith(color: K.textFaint),
        ),
      ),
    );
  }
}

/// Segmented control used for modes, views and input methods.
class Seg extends StatelessWidget {
  const Seg({super.key, required this.items, required this.value, required this.onChanged, this.small = false});
  final List<String> items;
  final String? value;
  final ValueChanged<String> onChanged;
  final bool small;
  @override
  Widget build(BuildContext context) {
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < items.length; i++)
                Pressable(
                  onTap: () => onChanged(items[i]),
                  builder: (_, hover, _) {
                    final on = items[i] == value;
                    return AnimatedContainer(
                      duration: K.durFast,
                      height: small ? 30 : 38,
                      padding: EdgeInsets.symmetric(horizontal: small ? 10 : 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: on ? K.accent : (hover ? K.whiteA08 : Colors.transparent),
                        border: i > 0 ? const Border(left: BorderSide(color: K.borderHairline)) : null,
                      ),
                      child: Text(
                        items[i],
                        style: KText.mono(11, color: on ? K.textOnAccent : K.textSecondary, tracking: K.trLabel),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class MonoLabel extends StatelessWidget {
  const MonoLabel(this.text, {super.key, this.color, this.size = 11, this.height = 1, this.align, this.maxLines});
  final String text;
  final Color? color;
  final double size, height;
  final TextAlign? align;
  final int? maxLines;
  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: KText.label(size: size, color: color, height: height),
    textAlign: align,
    maxLines: maxLines,
    overflow: maxLines == null ? null : TextOverflow.ellipsis,
  );
}

/// Label over a large mono value with a small unit.
class Readout extends StatelessWidget {
  const Readout(this.k, this.v, this.u, {super.key, this.tone});
  final String k, v, u;
  final Color? tone;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        MonoLabel(k),
        const SizedBox(height: 6),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: v,
                style: KText.mono(20, color: tone ?? K.textPrimary, tracking: -.02),
              ),
              if (u.isNotEmpty)
                TextSpan(
                  text: ' $u',
                  style: KText.mono(11, color: K.textMuted),
                ),
            ],
          ),
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.visible,
        ),
      ],
    );
  }
}

/// The `.kslider`: 2px track, 14px square lime thumb.
class KSlider extends StatelessWidget {
  const KSlider({super.key, required this.value, required this.min, required this.max, this.step, this.onChanged, this.height = 24});
  final double value, min, max;
  final double? step;
  final ValueChanged<double>? onChanged;
  final double height;
  @override
  Widget build(BuildContext context) {
    final divs = step == null ? null : ((max - min) / step!).round().clamp(1, 100000);
    return SizedBox(
      height: height,
      child: SliderTheme(
        data: SliderThemeData(
          trackHeight: 2,
          activeTrackColor: K.ink400,
          inactiveTrackColor: K.ink400,
          disabledActiveTrackColor: K.ink400,
          disabledInactiveTrackColor: K.ink400,
          thumbColor: K.accent,
          disabledThumbColor: K.accent,
          overlayShape: SliderComponentShape.noOverlay,
          thumbShape: const _SquareThumb(),
          trackShape: const RectangularSliderTrackShape(),
          tickMarkShape: SliderTickMarkShape.noTickMark,
          showValueIndicator: ShowValueIndicator.never,
        ),
        child: Slider(value: value.clamp(min, max), min: min, max: max, divisions: divs, onChanged: onChanged),
      ),
    );
  }
}

class _SquareThumb extends SliderComponentShape {
  const _SquareThumb();
  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(14, 14);
  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    context.canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: center, width: 14, height: 14), const Radius.circular(2)),
      Paint()..color = K.accent,
    );
  }
}

/// Pulsing record / scan dot.
class PulseDot extends StatefulWidget {
  const PulseDot({super.key, this.color = K.negative, this.animate = true, this.period = const Duration(milliseconds: 1200), this.square = false});
  final Color color;
  final bool animate, square;
  final Duration period;
  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: widget.period);
  @override
  void initState() {
    super.initState();
    if (widget.animate) _c.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(PulseDot old) {
    super.didUpdateWidget(old);
    if (widget.animate && !_c.isAnimating) _c.repeat(reverse: true);
    if (!widget.animate) _c.value = 0;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: widget.animate ? Tween(begin: 1.0, end: .25).animate(CurvedAnimation(parent: _c, curve: K.easeStandard)) : const AlwaysStoppedAnimation(1),
    child: Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: widget.color,
        shape: widget.square ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: widget.square ? BorderRadius.circular(2) : null,
      ),
    ),
  );
}

/// Eyebrow + page title, with an optional right-hand slot.
class PageHead extends StatelessWidget {
  const PageHead({super.key, required this.eyebrow, required this.title, this.right, required this.phone});
  final String eyebrow, title;
  final Widget? right;
  final bool phone;
  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.end,
      runSpacing: K.s5,
      spacing: K.s5,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            MonoLabel(eyebrow, color: K.textAccent),
            const SizedBox(height: 10),
            Text(title, style: phone ? KText.headingMd : KText.headingLg),
          ],
        ),
        ?right,
      ],
    );
  }
}

/// Flat raised panel with a hairline border — the system's "card".
class Panel extends StatelessWidget {
  const Panel({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.height, this.color = K.surfaceRaised});
  final Widget child;
  final EdgeInsets padding;
  final double? height;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    height: height,
    padding: padding,
    decoration: BoxDecoration(
      color: color,
      border: Border.all(color: K.borderHairline),
      borderRadius: BorderRadius.circular(K.radiusCard),
    ),
    child: child,
  );
}

const hairline = Divider(height: 1, thickness: 1, color: K.borderHairline);

String mmss(double s) {
  s = s < 0 ? 0 : s;
  final m = (s / 60).floor(), r = (s % 60).floor();
  return '${m.toString().padLeft(2, '0')}:${r.toString().padLeft(2, '0')}';
}

/// Signed fixed-point with a real minus sign, as in the design (`f1`).
String f1(num v, [int n = 1]) => '${v >= 0 ? '' : '−'}${v.abs().toStringAsFixed(n)}';

/// Marks anything that is not real hardware: simulated devices and demo recordings.
class SimTag extends StatelessWidget {
  const SimTag({super.key, this.text = 'Sim', this.height = 22});
  final String text;
  final double height;
  @override
  Widget build(BuildContext context) => Tooltip(
    message: 'Simulated in the app, not real hardware',
    child: KTag(text, tone: TagTone.info, height: height),
  );
}
