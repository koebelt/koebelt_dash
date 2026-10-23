import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/dash.dart';
import '../core/gamepad.dart';
import '../core/model.dart';
import '../scripts/conditions.dart';
import '../scripts/fields.dart';
import '../scripts/script_hub.dart';
import '../scripts/triggers.dart';
import '../theme/tokens.dart';
import '../ui/components.dart';
import '../ui/icons.dart';

Widget _field(String label, Widget child) =>
    Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [MonoLabel(label), const SizedBox(height: 8), child]);

/// Adds a trigger, or edits [existing]. [events] are the triggers the script
/// declared, offered by name. Returns the binding, or null.
Future<TriggerBinding?> showTriggerDialog(BuildContext context, Dash d, {required List<String> events, required DeviceKind kind, TriggerBinding? existing}) =>
    showKDialog<TriggerBinding>(
      context,
      builder: (ctx) => _TriggerDialog(d: d, events: events, kind: kind, existing: existing),
    );

class _TriggerDialog extends StatefulWidget {
  const _TriggerDialog({required this.d, required this.events, required this.kind, this.existing});
  final Dash d;
  final List<String> events;
  final DeviceKind kind;
  final TriggerBinding? existing;
  @override
  State<_TriggerDialog> createState() => _TriggerDialogState();
}

class _TriggerDialogState extends State<_TriggerDialog> {
  late final TriggerBinding b = widget.existing == null
      ? TriggerBinding(widget.events.firstOrNull ?? '', TriggerSource.button)
      : TriggerBinding.fromJson(widget.existing!.toJson());
  late final _event = TextEditingController(text: b.event);
  late final _expr = TextEditingController(text: b.expr ?? 'battery.pct < 25 for 3s');
  late final _match = TextEditingController(text: b.match ?? '');
  late final _seconds = TextEditingController(text: _n(b.seconds));
  final _keyFocus = FocusNode();
  Timer? _poll;
  bool _learning = false;

  static String _n(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  @override
  void initState() {
    super.initState();
    _expr.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _poll?.cancel();
    if (_learning) widget.d.padMapper.cancelLearning();
    _event.dispose();
    _expr.dispose();
    _match.dispose();
    _seconds.dispose();
    _keyFocus.dispose();
    super.dispose();
  }

  void _learnPad() {
    final m = widget.d.padMapper;
    m.learned = null;
    m.startLearning('src');
    setState(() => _learning = true);
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (m.learned != null || m.learning == null) {
        t.cancel();
        setState(() {
          _learning = false;
          if (m.learned != null) b.pad = m.learned;
        });
      }
    });
  }

  /// The condition, checked live against the device it would run on.
  ({bool ok, String text}) _checkExpr() {
    try {
      final c = Condition.parse(_expr.text);
      final l = widget.d.focus;
      if (l == null) return (ok: true, text: 'Valid');
      try {
        return (ok: true, text: 'Valid · now ${c.test(fieldsOf(l))}');
      } on ConditionError catch (e) {
        return (ok: true, text: 'Valid · ${e.message}');
      }
    } on ConditionError catch (e) {
      return (ok: false, text: e.message);
    }
  }

  String? _padConflict() {
    final src = b.pad;
    if (src == null) return null;
    final a = widget.d.pad.buttons.entries.where((e) => e.value == src).firstOrNull?.key;
    return a == null ? null : '${padSourceLabel(src)} is ${a.label} in the controller mapping: that action wins.';
  }

  bool get _valid =>
      switch (b.source) {
        TriggerSource.key => b.key != null,
        TriggerSource.pad => b.pad != null,
        TriggerSource.condition => _checkExpr().ok,
        TriggerSource.event => b.deviceEvent != null,
        TriggerSource.timer => (double.tryParse(_seconds.text) ?? 0) > 0,
        _ => true,
      } &&
      _event.text.trim().isNotEmpty;

  void _save() {
    b.event = _event.text.trim();
    if (b.source == TriggerSource.condition) b.expr = _expr.text.trim();
    if (b.source == TriggerSource.event) b.match = _match.text.trim().isEmpty ? null : _match.text.trim();
    if (b.source == TriggerSource.timer) b.seconds = double.tryParse(_seconds.text) ?? 5;
    Navigator.pop(context, b);
  }

  Widget _conditionEditor() {
    final picked = pickedFrom(_expr.text);
    final fields = conditionFields(widget.kind);
    final check = _checkExpr();
    Widget box(Widget child, {double? w}) => Container(
      width: w,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: K.surfaceSunken,
        border: Border.all(color: K.borderSubtle),
        borderRadius: BorderRadius.circular(K.radiusControl),
      ),
      child: child,
    );
    void setPicked(PickedCondition p) => _expr.text = expressionOf(p);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (picked != null) ...[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              box(
                w: 200,
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: fields.any((f) => f.field == picked.field) ? picked.field : null,
                    hint: Text(picked.field, style: KText.mono(13)),
                    isExpanded: true,
                    dropdownColor: K.surfaceRaised,
                    style: KText.mono(13),
                    items: [
                      for (final f in fields)
                        DropdownMenuItem(
                          value: f.field,
                          child: Text('${f.label}${f.unit.isEmpty ? '' : ' (${f.unit})'}', style: KText.bodySm.copyWith(color: K.textPrimary)),
                        ),
                    ],
                    onChanged: (v) => setPicked((field: v!, op: picked.op, value: picked.value, seconds: picked.seconds)),
                  ),
                ),
              ),
              Seg(
                small: true,
                items: const ['<', '>'],
                value: picked.op == '<' || picked.op == '<='
                    ? '<'
                    : picked.op == '>' || picked.op == '>='
                    ? '>'
                    : null,
                onChanged: (v) => setPicked((field: picked.field, op: v, value: picked.value, seconds: picked.seconds)),
              ),
              box(
                w: 80,
                TextField(
                  controller: TextEditingController(text: _n(picked.value)),
                  style: KText.mono(13),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  decoration: const InputDecoration.collapsed(hintText: null),
                  onSubmitted: (v) => setPicked((field: picked.field, op: picked.op, value: double.tryParse(v) ?? picked.value, seconds: picked.seconds)),
                ),
              ),
              Text('for', style: KText.bodySm.copyWith(color: K.textMuted)),
              box(
                w: 70,
                TextField(
                  controller: TextEditingController(text: _n(picked.seconds)),
                  style: KText.mono(13),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration.collapsed(hintText: null),
                  onSubmitted: (v) => setPicked((field: picked.field, op: picked.op, value: picked.value, seconds: double.tryParse(v) ?? 0)),
                ),
              ),
              Text('s', style: KText.bodySm.copyWith(color: K.textMuted)),
            ],
          ),
          const SizedBox(height: 10),
        ],
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: K.surfaceSunken,
            border: Border.all(color: check.ok ? K.accent : K.negative),
            borderRadius: BorderRadius.circular(K.radiusControl),
          ),
          child: TextField(
            controller: _expr,
            style: KText.mono(13),
            autocorrect: false,
            enableSuggestions: false,
            decoration: const InputDecoration.collapsed(hintText: 'battery.pct < 25 for 3s'),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            KIcon(check.ok ? 'check' : 'circle-alert', size: 14, color: check.ok ? K.positive : K.negative),
            const SizedBox(width: 6),
            Expanded(
              child: Text(check.text, style: KText.mono(11, color: check.ok ? K.positive : K.negative)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Fields: ${[for (final f in fields) f.field].join(', ')}, mode, armed, and the device’s own channels (motor_temp.max…). '
          'Combine with and, or, not; add “for 3s” to wait.',
          style: KText.bodySm.copyWith(color: K.textMuted),
        ),
        const SizedBox(height: 12),
        Seg(
          small: true,
          items: const ['WHEN TRUE', 'TRUE AND FALSE'],
          value: b.both ? 'TRUE AND FALSE' : 'WHEN TRUE',
          onChanged: (v) => setState(() => b.both = v != 'WHEN TRUE'),
        ),
      ],
    );
  }

  Widget _sourceFields() {
    switch (b.source) {
      case TriggerSource.button:
      case TriggerSource.toggle:
      case TriggerSource.slider:
        return Row(
          children: [
            KSwitch(checked: b.pinned, onChanged: (v) => setState(() => b.pinned = v)),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Also on Control, next to the sticks', style: KText.bodySm.copyWith(color: K.textSecondary)),
            ),
          ],
        );
      case TriggerSource.key:
        return _field(
          'Key',
          Focus(
            focusNode: _keyFocus,
            onKeyEvent: (_, e) {
              if (e is KeyDownEvent && e.logicalKey != LogicalKeyboardKey.escape) {
                setState(() => b.key = keyLabelOf(e.logicalKey));
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: Builder(
              builder: (ctx) => Pressable(
                onTap: () => _keyFocus.requestFocus(),
                builder: (_, hover, _) => ListenableBuilder(
                  listenable: _keyFocus,
                  builder: (_, _) => Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      color: K.surfaceSunken,
                      border: Border.all(color: _keyFocus.hasFocus ? K.accent : K.borderSubtle),
                      borderRadius: BorderRadius.circular(K.radiusControl),
                    ),
                    child: Text(
                      _keyFocus.hasFocus ? (b.key == null ? 'Press a key…' : '${b.key} · press another to change') : (b.key ?? 'Click, then press a key'),
                      style: KText.mono(13, color: b.key == null ? K.textMuted : K.textPrimary),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      case TriggerSource.pad:
        final conflict = _padConflict();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text(b.pad == null ? 'No button yet' : padSourceLabel(b.pad), style: KText.mono(13))),
                KButton(_learning ? 'Press a button…' : 'Learn', size: KSize.sm, variant: KButtonVariant.secondary, onPressed: _learning ? null : _learnPad),
              ],
            ),
            if (conflict != null) ...[const SizedBox(height: 10), KNotice(tone: Tone.warning, child: Text(conflict))],
          ],
        );
      case TriggerSource.condition:
        return _conditionEditor();
      case TriggerSource.event:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final e in deviceEvents.entries)
                  Pressable(
                    onTap: () => setState(() => b.deviceEvent = e.key),
                    builder: (_, _, _) => KTag(e.value, tone: b.deviceEvent == e.key ? TagTone.accent : TagTone.neutral, height: 30),
                  ),
              ],
            ),
            if (b.deviceEvent == 'mode' || b.deviceEvent == 'log') ...[
              const SizedBox(height: 12),
              KInput(
                controller: _match,
                height: 40,
                placeholder: b.deviceEvent == 'mode' ? 'Only this mode (HOLD…), or empty for any' : 'Only messages containing…',
                style: KText.bodySm,
              ),
            ],
          ],
        );
      case TriggerSource.timer:
        return Row(
          children: [
            Seg(
              small: true,
              items: const ['EVERY', 'ONCE AFTER'],
              value: b.repeat ? 'EVERY' : 'ONCE AFTER',
              onChanged: (v) => setState(() => b.repeat = v == 'EVERY'),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 90,
              child: KInput(
                controller: _seconds,
                height: 36,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: KText.mono(13),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 8),
            Text('seconds', style: KText.bodySm.copyWith(color: K.textMuted)),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return KDialogPanel(
      title: widget.existing == null ? 'Add trigger' : 'Edit trigger',
      width: 600,
      onClose: () => Navigator.pop(context),
      footer: [
        KButton('Cancel', variant: KButtonVariant.ghost, onPressed: () => Navigator.pop(context)),
        KButton(widget.existing == null ? 'Add trigger' : 'Save', onPressed: _valid ? _save : null),
      ],
      children: [
        _field(
          'Event',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              KInput(controller: _event, height: 40, placeholder: 'The name the script receives', style: KText.bodySm, onChanged: (_) => setState(() {})),
              if (widget.events.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final e in widget.events)
                      Pressable(
                        onTap: () => setState(() => _event.text = e),
                        builder: (_, _, _) => KTag(e, tone: _event.text == e ? TagTone.accent : TagTone.neutral, height: 26),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
        _field(
          'Fired by',
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final s in TriggerSource.values)
                Pressable(
                  onTap: () => setState(() => b.source = s),
                  builder: (_, _, _) => KTag(s.label, tone: b.source == s ? TagTone.accent : TagTone.neutral, height: 30),
                ),
            ],
          ),
        ),
        _sourceFields(),
        Text(
          'The script receives “${_event.text.isEmpty ? '…' : _event.text}” in the handler of that name, or in @dev.on_trigger. '
          'Conditions, events and timers run in dash.',
          style: KText.bodySm.copyWith(color: K.textMuted),
        ),
      ],
    );
  }
}

/// A key's label as bindings store it: `D`, `SPACE`, `F1`, `ARROW UP`.
String keyLabelOf(LogicalKeyboardKey k) => (k == LogicalKeyboardKey.space ? 'Space' : k.keyLabel).toUpperCase();

/// The operator's limits for a script.
Future<void> showLimitsDialog(BuildContext context, ScriptLimits lim, {required VoidCallback onChanged, required DeviceKind? kind}) => showKDialog<void>(
  context,
  builder: (ctx) => StatefulBuilder(
    builder: (ctx, set) {
      void change(void Function() f) {
        set(f);
        onChanged();
      }

      Widget slider(String title, String desc, double v, double min, double max, double step, String Function(double) fmt, ValueChanged<double> on) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title, style: KText.bodyMd.copyWith(color: K.textPrimary)),
              ),
              Text(fmt(v), style: KText.mono(13)),
            ],
          ),
          const SizedBox(height: 4),
          Text(desc, style: KText.bodySm.copyWith(color: K.textMuted)),
          KSlider(value: v.clamp(min, max), min: min, max: max, step: step, onChanged: (x) => change(() => on(x))),
        ],
      );
      Widget toggle(String title, String desc, bool v, ValueChanged<bool> on) => Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: KText.bodyMd.copyWith(color: K.textPrimary)),
                const SizedBox(height: 4),
                Text(desc, style: KText.bodySm.copyWith(color: K.textMuted)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          KSwitch(checked: v, onChanged: (x) => change(() => on(x))),
        ],
      );
      final flies = kind == null || kind == DeviceKind.drone;
      return KDialogPanel(
        title: 'Limits',
        width: 560,
        onClose: () => Navigator.pop(ctx),
        footer: [KButton('Done', onPressed: () => Navigator.pop(ctx))],
        children: [
          Text('Set here, not in the script: the script cannot change them.', style: KText.bodySm.copyWith(color: K.textMuted)),
          slider(
            'Maximum speed',
            'The script’s sticks are scaled to this, and its speed limit capped.',
            lim.maxSpeed,
            .1,
            1,
            .05,
            (v) => '${(v * 100).round()} %',
            (v) => lim.maxSpeed = v,
          ),
          slider(
            'Geofence',
            'Beyond this distance from home, the script loses the sticks and the device holds.',
            lim.fence,
            0,
            500,
            5,
            (v) => v == 0 ? 'off' : '${v.round()} m',
            (v) => lim.fence = v,
          ),
          if (flies)
            slider(
              'Ceiling',
              'Above this height, the same for drones.',
              lim.ceiling,
              0,
              120,
              5,
              (v) => v == 0 ? 'off' : '${v.round()} m',
              (v) => lim.ceiling = v,
            ),
          toggle('Allow arming and take-off', 'Otherwise the script can only move a device you armed.', lim.allowArm, (v) => lim.allowArm = v),
          toggle('Allow parameter writes', 'For tuning scripts. They can change how the device behaves.', lim.allowParams, (v) => lim.allowParams = v),
        ],
      );
    },
  ),
);
