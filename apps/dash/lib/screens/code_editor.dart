import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/tokens.dart';
import '../ui/components.dart';

/// The koebelt_dash_scripts API, for completion: name, what it is.
const scriptApi = <String, String>{
  'tlm': 'latest telemetry (20 Hz)',
  'next_tlm()': 'wait for the next telemetry',
  'sticks()': 'throttle, yaw, pitch, roll / steer, −1…1',
  'release()': 'hand the sticks back',
  'mode()': 'set the mode: "HOLD", "MANUAL"…',
  'arm()': 'arm (needs leave in Limits)',
  'disarm()': 'disarm',
  'speed_limit()': 'device speed limit, 0.1–1',
  'cmd()': 'a command of this kind of device',
  'stop()': 'STOP, every device',
  'params': 'parameters: dev.params["KEY"]',
  'setting()': 'a slider or switch in dash',
  'trigger()': 'decorator: a button, switch or value in dash',
  'on_trigger': 'decorator: any other trigger',
  'on_stop': 'decorator: dash took the sticks, or STOP',
  'on_takeover': 'decorator: the operator took the sticks',
  'plot()': 'show and record a value',
  'mark()': 'an event on the recording',
  'notify()': 'a message to the operator',
  'store': 'a dict kept between runs',
  'run()': 'wait for triggers',
  'name': 'the device name',
  'kind': 'drone, rover, arm, bench, rocket',
  'simulated': 'True for a simulated device',
};
const scriptTlm = <String, String>{
  'pos': '[x, y, z] m from home (x east, y north)',
  'alt': 'height above home, m',
  'vel': '[vx, vy, vz] m/s',
  'speed': 'm/s',
  'heading': 'compass degrees',
  'roll': 'rad',
  'pitch': 'rad',
  'yaw': 'rad',
  'mode': '"HOLD", "MANUAL"…',
  'armed': 'True / False',
  'battery': 'percent',
  'voltage': 'V',
  'gps': '(lat, lon, alt) or None',
  'failsafe': 'True while in failsafe',
  'estop': 'True while STOP is on',
  'joints': 'arm joint angles, rad',
  'custom': 'the device’s own channels',
};
const scriptTopLevel = <String, String>{
  'connect()': 'the device selected in dash',
  'every()': 'a steady loop: for _ in every(0.05)',
  'wait()': 'sleep, seconds',
  'pid()': 'PID controller: pid(kp, ki, kd)',
  'lowpass()': 'low-pass filter, Hz',
  'rate_limit()': 'smooth changes, per second',
  'clamp()': 'limit to −1…1',
  'distance()': 'metres between positions',
  'bearing()': 'compass bearing between positions',
  'angle_diff()': 'shortest turn between headings',
  'geo_distance()': 'metres between GPS positions',
  'geo_bearing()': 'bearing between GPS positions',
};

const _keywords = {
  'from', 'import', 'def', 'for', 'in', 'if', 'not', 'continue', 'return', 'and', 'or', 'while', 'True', 'False', 'None', 'as', //
  'with', 'else', 'elif', 'lambda', 'class', 'try', 'except', 'finally', 'raise', 'pass', 'break', 'global', 'nonlocal', 'is', 'yield',
};

final _tokens = RegExp(
  r'''("""[\s\S]*?(?:"""|$)|'\'\'[\s\S]*?(?:'\'\'|$))|(#[^\n]*)|("(?:\\.|[^"\\\n])*"?|'(?:\\.|[^'\\\n])*'?)|(@[A-Za-z_][\w.]*)|\b(\d+(?:\.\d+)?)\b|\b([A-Za-z_]\w*)\b(?=\s*\()|\b([A-Za-z_]\w*)\b''',
);

/// Colour runs of Python source: (start, end, colour).
List<(int, int, Color)> pythonRuns(String src) {
  final out = <(int, int, Color)>[];
  for (final m in _tokens.allMatches(src)) {
    final t = m[0]!;
    final Color? c = m[1] != null || m[3] != null
        ? K.positive
        : m[2] != null
        ? K.textFaint
        : m[4] != null || m[5] != null
        ? K.warning
        : m[6] != null
        ? (_keywords.contains(t) ? K.accent : K.info)
        : _keywords.contains(t)
        ? K.accent
        : null;
    if (c != null) out.add((m.start, m.end, c));
  }
  return out;
}

/// A text controller that colours Python and marks an error line.
class PythonController extends TextEditingController {
  PythonController({super.text});

  /// 1-based line with a syntax error, underlined.
  int? errorLine;

  @override
  TextSpan buildTextSpan({required BuildContext context, TextStyle? style, required bool withComposing}) {
    final src = text;
    var errStart = -1, errEnd = -1;
    if (errorLine != null) {
      var line = 1, i = 0;
      while (line < errorLine! && i >= 0) {
        i = src.indexOf('\n', i) + 1;
        if (i == 0) i = -1;
        line++;
      }
      if (i >= 0) {
        errStart = i;
        final e = src.indexOf('\n', i);
        errEnd = e < 0 ? src.length : e;
      }
    }
    final children = <TextSpan>[];
    var at = 0;
    TextStyle? errStyle(TextStyle? s) => s?.copyWith(decoration: TextDecoration.underline, decorationColor: K.negative, decorationStyle: TextDecorationStyle.wavy);
    void add(int a, int b, Color? c) {
      // Split around the error line so it can be underlined.
      final cuts = <int>{a, b, if (errStart > a && errStart < b) errStart, if (errEnd > a && errEnd < b) errEnd}.toList()..sort();
      for (var k = 0; k < cuts.length - 1; k++) {
        final x = cuts[k], y = cuts[k + 1];
        final base = c == null ? const TextStyle() : TextStyle(color: c);
        final inErr = errStart >= 0 && x >= errStart && y <= errEnd;
        children.add(TextSpan(text: src.substring(x, y), style: inErr ? errStyle(base) : (c == null ? null : base)));
      }
    }

    for (final (a, b, c) in pythonRuns(src)) {
      if (a > at) add(at, a, null);
      add(a, b, c);
      at = b;
    }
    if (at < src.length) add(at, src.length, null);
    return TextSpan(style: style, children: children);
  }
}

/// What completion offers at the cursor: (text to insert, label, help), and
/// how many characters before the cursor it replaces.
({List<(String, String)> items, int replace}) completionsAt(String text, int cursor) {
  if (cursor < 0 || cursor > text.length) return (items: const [], replace: 0);
  final before = text.substring(0, cursor);
  final m = RegExp(r'([A-Za-z_][\w]*(?:\.[A-Za-z_]\w*)*\.)?([A-Za-z_]\w*)?$').firstMatch(before);
  if (m == null) return (items: const [], replace: 0);
  final owner = m[1] ?? '', word = m[2] ?? '';
  if (owner.isEmpty && word.length < 2) return (items: const [], replace: 0);
  final Map<String, String> pool = owner.endsWith('tlm.')
      ? scriptTlm
      : owner.isNotEmpty
      ? scriptApi
      : scriptTopLevel;
  if (owner.isNotEmpty && !RegExp(r'(dev|device|d)\.$|tlm\.$').hasMatch(owner)) return (items: const [], replace: 0);
  final items = [
    for (final e in pool.entries)
      if (e.key.startsWith(word) && e.key.replaceAll('()', '') != word) (e.key, e.value),
  ];
  return (items: items.take(8).toList(), replace: word.length);
}

/// A Python editor: line numbers, colours, indentation with Tab and Enter,
/// Cmd/Ctrl-S to save, Cmd/Ctrl-/ to comment, no line wrapping.
class CodeEditor extends StatefulWidget {
  const CodeEditor({super.key, required this.controller, this.focusNode, this.onSave, this.onChanged, this.fontSize = 13, this.readOnly = false});
  final PythonController controller;
  final FocusNode? focusNode;
  final VoidCallback? onSave;
  final VoidCallback? onChanged;
  final double fontSize;
  final bool readOnly;
  @override
  State<CodeEditor> createState() => CodeEditorState();
}

class CodeEditorState extends State<CodeEditor> {
  late final FocusNode _focus = widget.focusNode ?? FocusNode();
  final _v = ScrollController(), _h = ScrollController();

  PythonController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    c.addListener(_changed);
  }

  @override
  void didUpdateWidget(covariant CodeEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_changed);
      widget.controller.addListener(_changed);
    }
  }

  @override
  void dispose() {
    c.removeListener(_changed);
    if (widget.focusNode == null) _focus.dispose();
    _v.dispose();
    _h.dispose();
    super.dispose();
  }

  void _changed() => setState(() {});

  /// Replaces the selection (or inserts) and places the cursor after it.
  void insert(String s, {int replaceBefore = 0}) {
    final sel = c.selection, t = c.text;
    final start = math.max(0, (sel.isValid ? sel.start : t.length) - replaceBefore), end = sel.isValid ? sel.end : t.length;
    c.value = TextEditingValue(text: t.replaceRange(start, end, s), selection: TextSelection.collapsed(offset: start + s.length));
    widget.onChanged?.call();
    _focus.requestFocus();
  }

  String _lineBefore() {
    final t = c.text, at = c.selection.isValid ? c.selection.start : t.length;
    return t.substring(t.lastIndexOf('\n', math.max(0, at - 1)) + 1, at);
  }

  /// Indents or dedents the selected lines (Tab with a selection, Shift-Tab).
  void _shiftLines(bool dedent) {
    final t = c.text, sel = c.selection;
    final from = t.lastIndexOf('\n', math.max(0, sel.start - 1)) + 1;
    final to = sel.end;
    final lines = t.substring(from, to).split('\n');
    final out = [for (final l in lines) dedent ? l.replaceFirst(RegExp(r'^ {1,4}'), '') : '    $l'];
    final s = out.join('\n');
    c.value = TextEditingValue(text: t.replaceRange(from, to, s), selection: TextSelection(baseOffset: from, extentOffset: from + s.length));
    widget.onChanged?.call();
  }

  void _toggleComment() {
    final t = c.text, sel = c.selection;
    final from = t.lastIndexOf('\n', math.max(0, sel.start - 1)) + 1;
    var to = t.indexOf('\n', sel.end);
    if (to < 0) to = t.length;
    final lines = t.substring(from, to).split('\n');
    final all = lines.where((l) => l.trim().isNotEmpty).every((l) => l.trimLeft().startsWith('#'));
    final out = [
      for (final l in lines)
        if (l.trim().isEmpty)
          l
        else if (all)
          l.replaceFirst(RegExp(r'# ?'), '')
        else
          l.replaceFirstMapped(RegExp(r'^(\s*)'), (m) => '${m[1]}# '),
    ].join('\n');
    c.value = TextEditingValue(text: t.replaceRange(from, to, out), selection: TextSelection(baseOffset: from, extentOffset: from + out.length));
    widget.onChanged?.call();
  }

  KeyEventResult _key(FocusNode _, KeyEvent e) {
    if (widget.readOnly || (e is! KeyDownEvent && e is! KeyRepeatEvent)) return KeyEventResult.ignored;
    final k = HardwareKeyboard.instance, mod = k.isMetaPressed || k.isControlPressed;
    final sel = c.selection;
    if (e.logicalKey == LogicalKeyboardKey.tab) {
      if (k.isShiftPressed || (sel.isValid && !sel.isCollapsed)) {
        _shiftLines(k.isShiftPressed);
      } else {
        insert('    ');
      }
      return KeyEventResult.handled;
    }
    if (e.logicalKey == LogicalKeyboardKey.enter && !mod) {
      final line = _lineBefore();
      var indent = RegExp(r'^\s*').firstMatch(line)![0]!;
      if (line.trimRight().endsWith(':')) indent += '    ';
      insert('\n$indent');
      return KeyEventResult.handled;
    }
    if (mod && e.logicalKey == LogicalKeyboardKey.keyS) {
      widget.onSave?.call();
      return KeyEventResult.handled;
    }
    if (mod && e.logicalKey == LogicalKeyboardKey.slash) {
      _toggleComment();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final fs = widget.fontSize, lh = fs * 1.6;
    final style = KText.mono(fs, color: K.textSecondary, height: 1.6, w: FontWeight.w400);
    final lines = '\n'.allMatches(c.text).length + 1;
    final longest = c.text.split('\n').fold<int>(0, (m, l) => math.max(m, l.length));
    // JetBrains Mono advances 0.6 em per character.
    final contentW = longest * fs * .6 + fs * 4;
    final at = c.selection.isValid ? '\n'.allMatches(c.text.substring(0, math.min(c.selection.start, c.text.length))).length + 1 : 0;
    return ColoredBox(
      color: K.surfaceSunken,
      child: LayoutBuilder(
        builder: (context, box) => Scrollbar(
          controller: _v,
          child: SingleChildScrollView(
            controller: _v,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: fs * 3.6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var i = 1; i <= lines; i++)
                        SizedBox(
                          height: lh,
                          child: Text(
                            '$i',
                            style: KText.mono(fs - 1, color: i == c.errorLine ? K.negative : (i == at ? K.textSecondary : K.textFaint), height: lh / (fs - 1)),
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(width: fs),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _h,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: math.max(box.maxWidth - fs * 4.6, contentW),
                      child: Focus(
                        onKeyEvent: _key,
                        skipTraversal: true,
                        child: TextField(
                          controller: c,
                          focusNode: _focus,
                          readOnly: widget.readOnly,
                          maxLines: null,
                          style: style,
                          strutStyle: StrutStyle(fontFamily: fontMono, fontSize: fs, height: 1.6, forceStrutHeight: true),
                          cursorColor: K.accent,
                          autocorrect: false,
                          enableSuggestions: false,
                          smartQuotesType: SmartQuotesType.disabled,
                          smartDashesType: SmartDashesType.disabled,
                          keyboardType: TextInputType.multiline,
                          scrollPhysics: const NeverScrollableScrollPhysics(),
                          decoration: const InputDecoration.collapsed(hintText: null),
                          onChanged: (_) => widget.onChanged?.call(),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Completion suggestions for the editor's cursor, as a strip of chips.
class CompletionBar extends StatelessWidget {
  const CompletionBar({super.key, required this.editor, required this.controller});
  final GlobalKey<CodeEditorState> editor;
  final PythonController controller;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final at = controller.selection.isValid && controller.selection.isCollapsed ? controller.selection.start : -1;
      final s = completionsAt(controller.text, at);
      if (s.items.isEmpty) return const SizedBox.shrink();
      return Container(
        height: 36,
        decoration: const BoxDecoration(
          color: K.surfaceRaised,
          border: Border(top: BorderSide(color: K.borderHairline)),
        ),
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          children: [
            for (final (name, help) in s.items)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Tooltip(
                  message: help,
                  child: Pressable(
                    onTap: () => editor.currentState?.insert(name.endsWith('()') ? name.substring(0, name.length - 1) : name, replaceBefore: s.replace),
                    builder: (_, hover, _) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: hover ? K.surfaceHover : K.surfaceSunken,
                        border: Border.all(color: K.borderHairline),
                        borderRadius: BorderRadius.circular(K.radiusControl),
                      ),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: name, style: KText.mono(12, color: K.textPrimary)),
                            TextSpan(text: '  $help', style: KText.mono(11, color: K.textMuted, w: FontWeight.w400)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}

/// The keys Python needs that phone keyboards hide, above the keyboard.
class CodeKeyRow extends StatelessWidget {
  const CodeKeyRow({super.key, required this.editor});
  final GlobalKey<CodeEditorState> editor;
  @override
  Widget build(BuildContext context) {
    final keys = <(String, String)>[('TAB', '    '), (':', ':'), ('( )', '()'), ('[ ]', '[]'), ('=', '='), ('"', '"'), ('.', '.'), ('#', '# ')];
    return Container(
      height: 46,
      decoration: const BoxDecoration(
        color: K.surfaceRaised,
        border: Border(top: BorderSide(color: K.borderHairline)),
      ),
      child: Row(
        children: [
          for (final (label, text) in keys)
            Expanded(
              child: Pressable(
                onTap: () {
                  final e = editor.currentState;
                  if (e == null) return;
                  e.insert(text);
                  // Brackets: the cursor goes between them.
                  if (text == '()' || text == '[]') {
                    final c = e.c;
                    c.selection = TextSelection.collapsed(offset: c.selection.start - 1);
                  }
                },
                builder: (_, hover, _) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: hover ? K.surfacePage : K.surfaceHover, borderRadius: BorderRadius.circular(K.radiusControl)),
                  child: Text(label, style: KText.mono(label.length > 3 ? 11 : 14, color: K.textPrimary)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
