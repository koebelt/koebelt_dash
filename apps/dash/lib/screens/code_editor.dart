import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../scripts/completion.dart';
import '../theme/tokens.dart';
import '../ui/components.dart';

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

  /// 1-based line with a syntax error, underlined, and what is wrong there
  /// (shown when the line is hovered).
  int? errorLine;
  String? errorMessage;

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
    TextStyle? errStyle(TextStyle? s) =>
        s?.copyWith(decoration: TextDecoration.underline, decorationColor: K.negative, decorationStyle: TextDecorationStyle.wavy);
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

/// A Python editor: line numbers, colours, indentation with Tab and Enter,
/// Cmd/Ctrl-S to save, Cmd/Ctrl-/ to comment, no line wrapping.
class CodeEditor extends StatefulWidget {
  const CodeEditor({
    super.key,
    required this.controller,
    this.focusNode,
    this.onSave,
    this.onChanged,
    this.fontSize = 13,
    this.readOnly = false,
    this.context,
    this.popup = true,
  });
  final PythonController controller;

  /// What dash knows about the script's device, for completion.
  final CompletionContext Function()? context;

  /// Completion in a popup at the cursor (desktop); phones use [CompletionBar].
  final bool popup;
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

  // Completion: the highlighted item, and Esc until the next edit.
  int _sel = 0;
  bool _dismissed = false;
  String _lastText = '';

  // Hover: where the pointer rested, the card it shows, and the wait first.
  Offset? _hoverPos;
  Timer? _hoverTimer;
  final _hoverCard = GlobalKey();

  ({List<Completion> items, int replace}) get completions {
    final at = c.selection.isValid && c.selection.isCollapsed ? c.selection.start : -1;
    return completeAt(c.text, at, widget.context?.call() ?? const CompletionContext());
  }

  /// Inserts a completion in place of what it completes.
  void accept(Completion item, int replace) {
    insert(item.insert, replaceBefore: replace);
    if (item.cursorBack > 0) c.selection = TextSelection.collapsed(offset: c.selection.start - item.cursorBack);
    _sel = 0;
  }

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
    _hoverTimer?.cancel();
    if (widget.focusNode == null) _focus.dispose();
    _v.dispose();
    _h.dispose();
    super.dispose();
  }

  void _changed() {
    if (c.text != _lastText) {
      _lastText = c.text;
      _dismissed = false;
      _sel = 0;
      _hoverPos = null;
    }
    setState(() {});
  }

  /// Replaces the selection (or inserts) and places the cursor after it.
  void insert(String s, {int replaceBefore = 0}) {
    final sel = c.selection, t = c.text;
    final start = math.max(0, (sel.isValid ? sel.start : t.length) - replaceBefore), end = sel.isValid ? sel.end : t.length;
    c.value = TextEditingValue(
      text: t.replaceRange(start, end, s),
      selection: TextSelection.collapsed(offset: start + s.length),
    );
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
    c.value = TextEditingValue(
      text: t.replaceRange(from, to, s),
      selection: TextSelection(baseOffset: from, extentOffset: from + s.length),
    );
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
        if (l.trim().isEmpty) l else if (all) l.replaceFirst(RegExp(r'# ?'), '') else l.replaceFirstMapped(RegExp(r'^(\s*)'), (m) => '${m[1]}# '),
    ].join('\n');
    c.value = TextEditingValue(
      text: t.replaceRange(from, to, out),
      selection: TextSelection(baseOffset: from, extentOffset: from + out.length),
    );
    widget.onChanged?.call();
  }

  KeyEventResult _key(FocusNode _, KeyEvent e) {
    if (widget.readOnly || (e is! KeyDownEvent && e is! KeyRepeatEvent)) return KeyEventResult.ignored;
    final k = HardwareKeyboard.instance, mod = k.isMetaPressed || k.isControlPressed;
    final sel = c.selection;
    // The completion popup: arrows choose, Tab or Enter insert, Esc closes.
    if (widget.popup && !_dismissed) {
      final comp = completions;
      if (comp.items.isNotEmpty) {
        final key = e.logicalKey;
        if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.arrowUp) {
          setState(() => _sel = (_sel + (key == LogicalKeyboardKey.arrowDown ? 1 : -1)) % comp.items.length);
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.tab || key == LogicalKeyboardKey.enter) {
          accept(comp.items[_sel.clamp(0, comp.items.length - 1)], comp.replace);
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.escape) {
          setState(() => _dismissed = true);
          return KeyEventResult.handled;
        }
      }
    }
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
    final gutter = fs * 3.6 + fs;
    return ColoredBox(
      color: K.surfaceSunken,
      child: LayoutBuilder(
        builder: (context, box) => MouseRegion(
          onHover: (e) => _pointer(e, fs, lh, gutter),
          onExit: (_) => _hideHover(),
          child: Stack(
            children: [
              Positioned.fill(child: _scroller(box, fs, lh, style, lines, contentW, at)),
              if (widget.popup && _focus.hasFocus) ..._overlays(box, fs, lh, gutter),
              if (_hoverPos != null) ..._hoverOverlay(box, fs, lh, gutter),
            ],
          ),
        ),
      ),
    );
  }

  /// The text under a point of the editor: its line (0-based) and the offset
  /// of the character there (null past the line's end).
  (int, int?) _textAt(Offset p, double fs, double lh, double gutter) {
    final v = _v.hasClients ? _v.offset : 0.0, h = _h.hasClients ? _h.offset : 0.0;
    final line = ((p.dy - 12 + v) / lh).floor(), col = ((p.dx - gutter + h) / (fs * .6)).floor();
    final lines = c.text.split('\n');
    if (line < 0 || line >= lines.length) return (-1, null);
    if (col < 0 || col >= lines[line].length) return (line, null);
    var off = 0;
    for (var i = 0; i < line; i++) {
      off += lines[i].length + 1;
    }
    return (line, off + col);
  }

  /// What a point is on, to tell when the pointer leaves it: a word, or the
  /// error line.
  Object? _hoverTarget(Offset p, double fs, double lh, double gutter) {
    final (line, off) = _textAt(p, fs, lh, gutter);
    if (off != null && RegExp(r'\w').hasMatch(c.text[off])) {
      var start = off;
      while (start > 0 && RegExp(r'\w').hasMatch(c.text[start - 1])) {
        start--;
      }
      return start;
    }
    return line + 1 == c.errorLine ? 'error' : null;
  }

  void _pointer(PointerHoverEvent e, double fs, double lh, double gutter) {
    // On the card: it stays (to read it, scroll it).
    final card = _hoverCard.currentContext?.findRenderObject() as RenderBox?;
    if (card != null && card.hasSize && (card.localToGlobal(Offset.zero) & card.size).contains(e.position)) return;
    final now = _hoverTarget(e.localPosition, fs, lh, gutter);
    if (_hoverPos != null) {
      if (now != null && now == _hoverTarget(_hoverPos!, fs, lh, gutter)) return;
      setState(() => _hoverPos = null);
    }
    _hoverTimer?.cancel();
    if (now == null) return;
    final p = e.localPosition;
    _hoverTimer = Timer(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _hoverPos = p);
    });
  }

  void _hideHover() {
    _hoverTimer?.cancel();
    if (_hoverPos != null) setState(() => _hoverPos = null);
  }

  /// The card about what the pointer rests on: the API's documentation, the
  /// script's own definitions, a library's docstring, the syntax error.
  List<Widget> _hoverOverlay(BoxConstraints box, double fs, double lh, double gutter) {
    final p = _hoverPos!;
    final (line, off) = _textAt(p, fs, lh, gutter);
    if (line < 0) return const [];
    final info = off == null ? null : hoverAt(c.text, off, widget.context?.call() ?? const CompletionContext());
    final error = line + 1 == c.errorLine ? c.errorMessage : null;
    if (info == null && error == null) return const [];
    final v = _v.hasClients ? _v.offset : 0.0, h = _h.hasClients ? _h.offset : 0.0;
    final lineStart = c.text.lastIndexOf('\n', math.max(0, (info?.start ?? 0) - 1)) + 1;
    final col = info == null ? ((p.dx - gutter + h) / (fs * .6)).floor() : info.start - lineStart;
    // Room for a docstring's 79 columns.
    final width = math.min(580.0, box.maxWidth - 16);
    final x = (gutter + col * fs * .6 - h).clamp(8.0, math.max(8.0, box.maxWidth - width - 8)).toDouble();
    final top = 12 + line * lh - v, bottom = top + lh;
    final above = top > box.maxHeight - bottom;
    return [
      Positioned(
        left: x,
        top: above ? null : bottom + 2,
        bottom: above ? box.maxHeight - top + 2 : null,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: width, maxHeight: math.max(60, (above ? top : box.maxHeight - bottom) - 10)),
          child: _HoverCard(key: _hoverCard, info: info, error: error),
        ),
      ),
    ];
  }

  /// The completion list and the signature hint, placed at the cursor (the
  /// font is monospace and lines do not wrap, so its position is arithmetic).
  List<Widget> _overlays(BoxConstraints box, double fs, double lh, double gutter) {
    if (!c.selection.isValid || !c.selection.isCollapsed) return const [];
    final at = c.selection.start.clamp(0, c.text.length);
    final before = c.text.substring(0, at);
    final line = '\n'.allMatches(before).length, col = at - (before.lastIndexOf('\n') + 1);
    final v = _v.hasClients ? _v.offset : 0.0, h = _h.hasClients ? _h.offset : 0.0;
    final x = (gutter + col * fs * .6 - h).clamp(8.0, math.max(8.0, box.maxWidth - 380)).toDouble();
    final top = 12 + line * lh - v, bottom = top + lh;
    final out = <Widget>[];
    final comp = _dismissed ? (items: const <Completion>[], replace: 0) : completions;
    if (comp.items.isNotEmpty) {
      final sel = _sel.clamp(0, comp.items.length - 1);
      final rows = math.min(comp.items.length, 8), height = rows * 30.0 + 2;
      final below = bottom + height + 4 < box.maxHeight || top < height + 4;
      out.add(
        Positioned(
          left: x,
          top: below ? bottom + 2 : null,
          bottom: below ? null : box.maxHeight - top + 2,
          width: 380,
          height: height,
          child: _CompletionPopup(items: comp.items, selected: sel, onPick: (i) => accept(comp.items[i], comp.replace)),
        ),
      );
    } else {
      final s = signatureAt(c.text, at, widget.context?.call().members);
      if (s != null && top > 0) {
        out.add(Positioned(left: x, bottom: box.maxHeight - top + 2, child: _SignatureHint(s.sig, s.arg)));
      }
    }
    return out;
  }

  Widget _scroller(BoxConstraints box, double fs, double lh, TextStyle style, int lines, double contentW, int at) => NotificationListener<ScrollNotification>(
    // The overlays follow the text as it scrolls.
    onNotification: (_) {
      if (widget.popup || _hoverPos != null) setState(() => _hoverPos = null);
      return false;
    },
    child: Scrollbar(
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
  );
}

/// A letter per kind, as code editors mark them: method, function, property…
const _kindIcon = {
  CompletionKind.method: 'm',
  CompletionKind.function: 'f',
  CompletionKind.field: 'p',
  CompletionKind.variable: 'v',
  CompletionKind.keyword: 'k',
  CompletionKind.value: '=',
  CompletionKind.module: 'M',
  CompletionKind.klass: 'C',
  CompletionKind.file: '·',
  CompletionKind.folder: '/',
};

/// A small popup's shadow: the overlay one is made for dialogs.
const _popupShadow = [BoxShadow(color: Color(0x66000000), blurRadius: 12, offset: Offset(0, 4))];

class _CompletionPopup extends StatelessWidget {
  const _CompletionPopup({required this.items, required this.selected, required this.onPick});
  final List<Completion> items;
  final int selected;
  final ValueChanged<int> onPick;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: K.surfaceRaised,
      border: Border.all(color: K.borderSubtle),
      borderRadius: BorderRadius.circular(K.radiusCard),
      boxShadow: _popupShadow,
    ),
    child: ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: items.length,
      itemExtent: 30,
      itemBuilder: (_, i) => Pressable(
        onTap: () => onPick(i),
        builder: (_, hover, _) => Container(
          color: i == selected ? K.limeA16 : (hover ? K.surfaceHover : null),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              SizedBox(
                width: 18,
                child: Text(_kindIcon[items[i].kind]!, style: KText.mono(11, color: K.textAccent)),
              ),
              Text(items[i].label, style: KText.mono(12, color: i == selected ? K.textPrimary : K.textSecondary)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  items[i].detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: KText.bodySm.copyWith(fontSize: 12, color: K.textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// The call's parameters, the current one highlighted, and what it does.
class _SignatureHint extends StatelessWidget {
  const _SignatureHint(this.sig, this.arg);
  final Signature sig;
  final int arg;
  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(maxWidth: 520),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: K.surfaceRaised,
      border: Border.all(color: K.borderSubtle),
      borderRadius: BorderRadius.circular(K.radiusCard),
      boxShadow: _popupShadow,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text.rich(
          TextSpan(
            style: KText.mono(12, color: K.textSecondary),
            children: [
              TextSpan(text: '${sig.name}('),
              for (var i = 0; i < sig.params.length; i++) ...[
                if (i > 0) const TextSpan(text: ', '),
                TextSpan(
                  text: sig.params[i].$1,
                  style: i == arg ? const TextStyle(color: K.accent, fontWeight: FontWeight.w600) : null,
                ),
              ],
              const TextSpan(text: ')'),
            ],
          ),
        ),
        if (sig.params.isNotEmpty && sig.params[arg].$2.isNotEmpty) Text(sig.params[arg].$2, style: KText.bodySm.copyWith(fontSize: 12, color: K.textPrimary)),
        Text(sig.doc, style: KText.bodySm.copyWith(fontSize: 12, color: K.textMuted)),
      ],
    ),
  );
}

/// What the pointer rests on: its signature, what it is, its documentation;
/// on the error line, the error.
class _HoverCard extends StatelessWidget {
  const _HoverCard({super.key, this.info, this.error});
  final HoverInfo? info;
  final String? error;
  @override
  Widget build(BuildContext context) {
    final i = info;
    final described = [
      for (final p in i?.params ?? const <(String, String)>[])
        if (p.$2.isNotEmpty) p,
    ];
    return Container(
      decoration: BoxDecoration(
        color: K.surfaceRaised,
        border: Border.all(color: error != null ? K.negative : K.borderSubtle),
        borderRadius: BorderRadius.circular(K.radiusCard),
        boxShadow: _popupShadow,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (error != null) Text(error!, style: KText.mono(12, color: K.negative)),
            if (error != null && i != null) const SizedBox(height: 8),
            if (i != null) ...[
              Text(
                i.title,
                style: KText.mono(12, color: K.textPrimary, w: FontWeight.w600),
              ),
              if (i.kind.isNotEmpty) Text(i.kind, style: KText.mono(11, color: K.textAccent)),
              if (described.isNotEmpty) ...[
                const SizedBox(height: 6),
                for (final p in described)
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: p.$1,
                          style: KText.mono(12, color: K.textSecondary),
                        ),
                        TextSpan(
                          text: '  ${p.$2}',
                          style: KText.bodySm.copyWith(fontSize: 12, color: K.textMuted),
                        ),
                      ],
                    ),
                  ),
              ],
              if (i.doc.isNotEmpty) ...[
                const SizedBox(height: 6),
                // Docstrings with several lines are laid out in plain text (numpy's
                // Parameters tables): monospace keeps them aligned.
                Text(
                  i.doc,
                  style: i.doc.contains('\n')
                      ? KText.mono(11.5, color: K.textSecondary, height: 1.45, w: FontWeight.w400)
                      : KText.bodySm.copyWith(fontSize: 12, color: K.textSecondary, height: 1.45),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// Completion as a strip of chips above the keyboard (phones), with the same
/// engine as the desktop popup.
class CompletionBar extends StatelessWidget {
  const CompletionBar({super.key, required this.editor, required this.controller, this.context});
  final GlobalKey<CodeEditorState> editor;
  final PythonController controller;
  final CompletionContext Function()? context;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (ctx, _) {
      final at = controller.selection.isValid && controller.selection.isCollapsed ? controller.selection.start : -1;
      final s = completeAt(controller.text, at, this.context?.call() ?? const CompletionContext());
      final sig = s.items.isEmpty ? signatureAt(controller.text, at, this.context?.call().members) : null;
      if (s.items.isEmpty && sig == null) return const SizedBox.shrink();
      return Container(
        height: 36,
        decoration: const BoxDecoration(
          color: K.surfaceRaised,
          border: Border(top: BorderSide(color: K.borderHairline)),
        ),
        child: sig != null
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${sig.sig.name}(${sig.sig.params.map((p) => p.$1).join(', ')})${sig.sig.params.isEmpty ? '' : '  ·  ${sig.sig.params[sig.arg].$1}'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: KText.mono(11, color: K.textSecondary),
                  ),
                ),
              )
            : ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                children: [
                  for (final item in s.items)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Pressable(
                        onTap: () => editor.currentState?.accept(item, s.replace),
                        builder: (_, hover, _) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: hover ? K.surfaceHover : K.surfaceSunken,
                            border: Border.all(color: K.borderHairline),
                            borderRadius: BorderRadius.circular(K.radiusControl),
                          ),
                          child: Text(item.label, style: KText.mono(12, color: K.textPrimary)),
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
