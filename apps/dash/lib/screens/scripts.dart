import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/dash.dart';
import '../core/save_io.dart';
import '../scripts/hosts.dart';
import '../scripts/library.dart';
import '../scripts/script_hub.dart';
import '../scripts/script_runner.dart';
import '../theme/tokens.dart';
import '../ui/components.dart';
import '../ui/icons.dart';
import 'code_editor.dart';
import 'script_panel.dart';

/// A scripts folder for the screens below it instead of the default (tests).
class ScriptsLibraryScope extends InheritedWidget {
  const ScriptsLibraryScope({super.key, required this.library, required super.child});
  final ScriptLibrary library;
  @override
  bool updateShouldNotify(ScriptsLibraryScope old) => old.library != library;
}

/// Scripts: the library, the editor, and running them (docs/design/scripts.md).
class ScriptsScreen extends StatefulWidget {
  const ScriptsScreen(this.d, {super.key, required this.w, required this.go, this.library});
  final Dash d;
  final double w;
  final ValueChanged<String> go;

  /// The folder to use instead of the default one (tests).
  final ScriptLibrary? library;
  @override
  State<ScriptsScreen> createState() => _ScriptsScreenState();
}

class _ScriptsScreenState extends State<ScriptsScreen> {
  ScriptLibrary? lib;
  List<ScriptFile> files = [];
  List<String> examples = [];
  String? selected;
  final code = PythonController();
  final _editor = GlobalKey<CodeEditorState>();
  String? _loaded, _diskText, _message;
  bool dirty = false;
  Timer? _autosave;
  StreamSubscription<FileSystemEvent>? _watch;

  /// Phones show one thing at a time: the list, a script, or its code.
  String phoneView = 'list';

  Dash get d => widget.d;
  bool get phone => widget.w < 600;
  ScriptFile? get current => files.where((f) => f.path == selected).firstOrNull;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final l = widget.library ?? context.getInheritedWidgetOfExactType<ScriptsLibraryScope>()?.library ?? ScriptLibrary(await ScriptLibrary.defaultDir());
    await l.dir.create(recursive: true);
    lib = l;
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      examples = manifest.listAssets().where((a) => a.startsWith('assets/script_examples/') && a.endsWith('.py')).toList()..sort();
    } catch (_) {}
    await _reload();
    if (FileSystemEntity.isWatchSupported) {
      _watch = l.dir.watch(recursive: true).listen((_) => _onDiskChange());
    }
    if (ScriptHub.canRunHere && d.scripts.pythons == null) unawaited(d.scripts.refreshPythons(near: l.dir));
  }

  @override
  void dispose() {
    _autosave?.cancel();
    if (dirty) _saveNow();
    _watch?.cancel();
    code.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final l = lib;
    if (l == null) return;
    final list = await l.list();
    if (!mounted) return;
    setState(() => files = list);
    if (selected == null || current == null) {
      final first = list.firstOrNull;
      if (first != null) await _open(first, show: false);
    }
  }

  Timer? _diskDebounce;
  void _onDiskChange() {
    _diskDebounce?.cancel();
    _diskDebounce = Timer(const Duration(milliseconds: 300), () async {
      await _reload();
      // Edited in another editor: take it, unless there are unsaved changes here.
      final f = current;
      if (f == null || dirty || !await f.file.exists()) return;
      final text = await f.file.readAsString();
      if (text != _diskText && mounted) {
        _diskText = text;
        setState(() => code.text = text);
      }
    });
  }

  Future<void> _open(ScriptFile f, {bool show = true}) async {
    if (dirty) await _saveNow();
    final text = await f.file.readAsString();
    if (!mounted) return;
    setState(() {
      selected = f.path;
      _loaded = f.path;
      _diskText = text;
      code.text = text;
      code.errorLine = null;
      _message = null;
      dirty = false;
      if (show && phone) phoneView = 'run';
    });
  }

  void _edited() {
    if (!dirty) setState(() => dirty = true);
    code.errorLine = null;
    _autosave?.cancel();
    _autosave = Timer(const Duration(milliseconds: 800), _saveNow);
  }

  Future<void> _saveNow() async {
    _autosave?.cancel();
    final path = _loaded;
    if (path == null || !dirty) return;
    final text = code.text;
    _diskText = text;
    await File(path).writeAsString(text);
    if (mounted) setState(() => dirty = false);
  }

  Future<void> _check() async {
    await _saveNow();
    final py = d.scripts.pythonFor(d.scripts.configFor(selected ?? '')) ?? d.scripts.pythons?.firstOrNull?.path;
    if (py == null) return;
    final r = await checkSyntax(py, code.text);
    if (!mounted) return;
    setState(() {
      code.errorLine = r?.line;
      _message = r == null ? 'No syntax errors.' : 'Line ${r.line}: ${r.message}';
    });
  }

  Future<void> _run() async {
    final f = current;
    if (f == null) return;
    await _saveNow();
    final cfg = d.scripts.configFor(f.path), host = d.scripts.hostFor(cfg);
    try {
      host == null ? await d.scripts.runFile(f.file, python: d.scripts.pythonFor(cfg)) : await d.scripts.runOnHost(f.file, host);
    } on HostError catch (e) {
      setState(() => _message = e.message);
    } catch (e) {
      setState(() => _message = 'Could not start: $e');
    }
  }

  Future<void> _new() async {
    final l = lib;
    if (l == null) return;
    final pick = await showKDialog<(String, String)>(context, builder: (ctx) => const _NewScriptDialog());
    if (pick == null) return;
    final f = await l.create(pick.$1, scriptTemplate(pick.$2, d.focus?.kind ?? d.kind, pick.$1));
    await _reload();
    final s = files.where((x) => x.path == f.path).firstOrNull;
    if (s != null) await _open(s);
    if (phone) setState(() => phoneView = 'edit');
  }

  Future<void> _import() async {
    final l = lib;
    if (l == null) return;
    final got = await openBytes('Python scripts', ['py', 'zip']);
    if (got == null) return;
    try {
      final f = await l.import(got.$1, got.$2);
      await _reload();
      final s = files.where((x) => x.path == f.path).firstOrNull;
      if (s != null) await _open(s);
    } on FormatException catch (e) {
      if (mounted) setState(() => _message = e.message);
    }
  }

  Future<void> _useExample(String asset) async {
    final l = lib;
    if (l == null) return;
    final text = await rootBundle.loadString(asset);
    final name = asset.split('/').last;
    final f = await l.import(name, utf8.encode(text));
    await _reload();
    final s = files.where((x) => x.path == f.path).firstOrNull;
    if (s != null) await _open(s);
  }

  Future<void> _rename(ScriptFile s) async {
    final name = await showKDialog<String>(context, builder: (ctx) => _NameDialog(title: 'Rename', initial: s.name));
    if (name == null || lib == null) return;
    await _saveNow();
    final to = await lib!.rename(s, name);
    d.scripts.moveConfig(s.path, to.path);
    selected = to.path;
    _loaded = to.path;
    await _reload();
  }

  Future<void> _delete(ScriptFile s) async {
    final ok = await showKDialog<bool>(
      context,
      builder: (ctx) => KDialogPanel(
        title: 'Delete “${s.name}”?',
        onClose: () => Navigator.pop(ctx),
        footer: [
          KButton('Cancel', variant: KButtonVariant.ghost, onPressed: () => Navigator.pop(ctx)),
          KButton('Delete', onPressed: () => Navigator.pop(ctx, true)),
        ],
        children: const [Text('It moves to the .trash folder inside the scripts folder, where you can get it back.')],
      ),
    );
    if (ok != true || lib == null) return;
    dirty = false;
    await lib!.delete(s);
    selected = null;
    _loaded = null;
    await _reload();
    if (phone) setState(() => phoneView = 'list');
  }

  Future<void> _export(ScriptFile s) async {
    final out = await lib!.export(s);
    await saveBytes(out.name, Uint8List.fromList(out.bytes), out.name.endsWith('.zip') ? 'application/zip' : 'text/x-python');
  }

  Future<void> _openExternally(String path, {bool reveal = false}) async {
    try {
      if (Platform.isMacOS) {
        await Process.run('open', reveal ? ['-R', path] : ['-t', path]);
      } else if (Platform.isWindows) {
        await Process.run('explorer', reveal ? ['/select,', path] : [path]);
      } else {
        await Process.run('xdg-open', [reveal ? File(path).parent.path : path]);
      }
    } catch (_) {}
  }

  /// VS Code when it is installed, else the system's text editor.
  Future<void> _openInEditor(String path) async {
    for (final code in ['code', '/usr/local/bin/code', '/opt/homebrew/bin/code']) {
      try {
        final r = await Process.run(code, [path], runInShell: Platform.isWindows);
        if (r.exitCode == 0) return;
      } catch (_) {}
    }
    await _openExternally(path);
  }

  // ----------------------------------------------------------------- views
  List<ConsoleLine> _consoleOf(ScriptFile f) {
    final run = d.scripts.runs.where((r) => r.file.path == f.path).lastOrNull;
    return run?.console ?? const [];
  }

  double? _hzOf(ScriptFile f) {
    final run = d.scripts.runs.where((r) => r.file.path == f.path).lastOrNull;
    return run == null || run.state != ScriptState.running ? null : d.scripts.connOf(run)?.hz;
  }

  Widget _badge(ScriptFile f) {
    final run = d.scripts.runs.where((r) => r.file.path == f.path).lastOrNull;
    if (run?.state == ScriptState.running) return const KBadge('RUNNING', tone: Tone.positive);
    if (run?.state == ScriptState.failed) return const KBadge('ERROR', tone: Tone.negative);
    return const SizedBox.shrink();
  }

  Widget _listItem(ScriptFile f) {
    final on = f.path == selected && !phone;
    return Pressable(
      onTap: () => _open(f),
      builder: (_, hover, _) => Container(
        margin: phone ? const EdgeInsets.only(bottom: 8) : EdgeInsets.zero,
        padding: EdgeInsets.symmetric(horizontal: phone ? 14 : 12, vertical: phone ? 14 : 10),
        decoration: BoxDecoration(
          color: on || hover ? K.surfaceHover : (phone ? K.surfaceRaised : null),
          border: phone ? Border.all(color: K.borderHairline) : Border(left: BorderSide(color: on ? K.accent : Colors.transparent, width: 2)),
          borderRadius: phone ? BorderRadius.circular(K.radiusCard) : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(f.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: KText.bodySm.copyWith(color: K.textPrimary, height: 1.3)),
                  const SizedBox(height: 4),
                  Text(f.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: KText.mono(11, color: K.textMuted)),
                ],
              ),
            ),
            _badge(f),
          ],
        ),
      ),
    );
  }

  Widget _examples() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const MonoLabel('Examples'),
      const SizedBox(height: 8),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final e in examples)
            Pressable(
              onTap: () => _useExample(e),
              builder: (_, _, _) => KTag(ScriptLibrary.titleOf(e.split('/').last.replaceAll('.py', '')), height: 28),
            ),
        ],
      ),
    ],
  );

  Widget _outside() {
    final outside = d.scripts.conns.where((c) => c.run == null).toList();
    if (outside.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const MonoLabel('Connected from outside dash'),
          const SizedBox(height: 8),
          for (final c in outside)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const PulseDot(color: K.positive, animate: false),
                  const SizedBox(width: 8),
                  Expanded(child: Text(c.name, style: KText.mono(12, color: K.textSecondary))),
                  if (c.blocked != null) KButton('Resume', size: KSize.sm, variant: KButtonVariant.ghost, onPressed: () => d.scripts.unblock(c)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _editorHeader(ScriptFile f) => Container(
    height: 52,
    padding: EdgeInsets.symmetric(horizontal: phone ? 8 : 16),
    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: K.borderHairline))),
    child: Row(
      children: [
        if (phone) ...[
          KIconButton('arrow-left', label: 'Back', variant: KIconButtonVariant.bare, onPressed: () => setState(() => phoneView = 'run')),
          const SizedBox(width: 4),
          Expanded(child: Text(f.label, overflow: TextOverflow.ellipsis, style: KText.labelMd())),
        ] else ...[
          Expanded(
            child: Row(
              children: [
                Flexible(flex: 3, child: Text(f.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: KText.headingXs)),
                const SizedBox(width: 12),
                Flexible(
                  flex: 2,
                  child: Text('${f.label} · ${dirty ? 'editing' : 'saved'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: KText.mono(12, color: K.textMuted)),
                ),
              ],
            ),
          ),
        ],
        if (ScriptHub.canRunHere)
          phone
              ? KIconButton('check', label: 'Check', size: KSize.sm, variant: KIconButtonVariant.bare, onPressed: _check)
              : KButton('Check', size: KSize.sm, variant: KButtonVariant.ghost, iconLeft: const KIcon('check', size: 14), onPressed: _check),
        if (!phone && ScriptHub.canRunHere) ...[
          const SizedBox(width: 4),
          KButton('Open in editor', size: KSize.sm, variant: KButtonVariant.ghost, iconLeft: const KIcon('arrow-up-right', size: 14), onPressed: () => _openInEditor(f.path)),
          _ScriptMenu(onRename: () => _rename(f), onDuplicate: () => _duplicate(f), onExport: () => _export(f), onReveal: () => _openExternally(f.path, reveal: true), onDelete: () => _delete(f)),
        ],
      ],
    ),
  );

  Future<void> _duplicate(ScriptFile f) async {
    final to = await lib!.duplicate(f);
    await _reload();
    final s = files.where((x) => x.path == to.path).firstOrNull;
    if (s != null) await _open(s);
  }

  Widget _messageBar() => _message == null
      ? const SizedBox.shrink()
      : Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: code.errorLine != null || _message!.startsWith('Could') ? const Color(0x33EE7A63) : K.surfaceRaised,
          child: Row(
            children: [
              Expanded(child: Text(_message!, style: KText.mono(12, color: code.errorLine != null ? K.negative : K.textSecondary))),
              Pressable(onTap: () => setState(() => _message = null), builder: (_, _, _) => const KIcon('x', size: 14, color: K.textMuted)),
            ],
          ),
        );

  void _goToLine(int line) {
    final lines = code.text.split('\n');
    var off = 0;
    for (var i = 0; i < line - 1 && i < lines.length; i++) {
      off += lines[i].length + 1;
    }
    code.selection = TextSelection.collapsed(offset: off.clamp(0, code.text.length));
    setState(() => code.errorLine = line);
  }

  @override
  Widget build(BuildContext context) {
    if (lib == null) return const Center(child: PulseDot(color: K.accent));
    return ListenableBuilder(listenable: d, builder: (context, _) => phone ? _phone() : _desktop());
  }

  Widget _desktop() {
    final f = current;
    final list = Container(
      width: 260,
      decoration: const BoxDecoration(border: Border(right: BorderSide(color: K.borderHairline))),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Expanded(child: MonoLabel('Scripts', color: K.textAccent)),
                KIconButton('plus', label: 'New script', size: KSize.sm, variant: KIconButtonVariant.bare, onPressed: _new),
                KIconButton('download', label: 'Import a .py or .zip', size: KSize.sm, variant: KIconButtonVariant.bare, onPressed: _import),
              ],
            ),
          ),
          const SizedBox(height: 10),
          for (final s in files) _listItem(s),
          if (files.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('No scripts yet. Start from an example, or press +.', style: KText.bodySm.copyWith(color: K.textMuted)),
            ),
          Padding(padding: const EdgeInsets.fromLTRB(16, 24, 16, 0), child: _examples()),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _outside()),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Pressable(
              onTap: () => _openExternally(lib!.dir.path),
              builder: (_, h, _) => Text(_short(lib!.dir.path), style: KText.mono(11, color: h ? K.textSecondary : K.textFaint)),
            ),
          ),
        ],
      ),
    );
    if (f == null) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          list,
          Expanded(
            child: Center(
              child: Text('Scripts drive your devices from Python. Create one, import one, or start from an example.', style: KText.bodyMd.copyWith(color: K.textMuted)),
            ),
          ),
        ],
      );
    }
    final editor = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _editorHeader(f),
        _messageBar(),
        Expanded(
          child: CodeEditor(key: _editor, controller: code, onChanged: _edited, onSave: _saveNow),
        ),
        CompletionBar(editor: _editor, controller: code),
        SizedBox(height: 200, child: ScriptConsole(lines: _consoleOf(f), hz: _hzOf(f), onLine: _goToLine)),
      ],
    );
    final run = Container(
      width: 340,
      decoration: const BoxDecoration(border: Border(left: BorderSide(color: K.borderHairline))),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [ScriptRunPanel(d: d, script: f, scriptsDir: lib!.dir, onRun: _run, phone: false)],
      ),
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        list,
        Expanded(child: editor),
        run,
      ],
    );
  }

  static String _short(String p) {
    final home = Platform.environment['HOME'] ?? '';
    return home.isNotEmpty && p.startsWith(home) ? '~${p.substring(home.length)}' : p;
  }

  Widget _phone() {
    final f = current;
    if (phoneView == 'edit' && f != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _editorHeader(f),
          _messageBar(),
          Expanded(
            child: CodeEditor(key: _editor, controller: code, onChanged: _edited, onSave: _saveNow, fontSize: 12),
          ),
          CompletionBar(editor: _editor, controller: code),
          CodeKeyRow(editor: _editor),
        ],
      );
    }
    if (phoneView == 'run' && f != null) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              KIconButton('arrow-left', label: 'Back', variant: KIconButtonVariant.bare, onPressed: () => setState(() => phoneView = 'list')),
              const SizedBox(width: 8),
              Expanded(child: Text(f.name, overflow: TextOverflow.ellipsis, style: KText.headingSm)),
              KButton('Edit', size: KSize.sm, variant: KButtonVariant.secondary, iconLeft: const KIcon('pencil', size: 14), onPressed: () => setState(() => phoneView = 'edit')),
            ],
          ),
          const SizedBox(height: 20),
          Panel(child: ScriptRunPanel(d: d, script: f, scriptsDir: lib!.dir, onRun: _run, phone: true)),
          const SizedBox(height: 24),
          SizedBox(height: 220, child: ScriptConsole(lines: _consoleOf(f), phone: true)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              KButton('Rename', size: KSize.sm, variant: KButtonVariant.ghost, onPressed: () => _rename(f)),
              KButton('Duplicate', size: KSize.sm, variant: KButtonVariant.ghost, onPressed: () => _duplicate(f)),
              KButton('Share', size: KSize.sm, variant: KButtonVariant.ghost, onPressed: () => _export(f)),
              KButton('Delete', size: KSize.sm, variant: KButtonVariant.ghost, onPressed: () => _delete(f)),
            ],
          ),
        ],
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: KButton('New', variant: KButtonVariant.secondary, iconLeft: const KIcon('plus', size: 16), onPressed: _new),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: KButton('Import', variant: KButtonVariant.secondary, iconLeft: const KIcon('download', size: 16), onPressed: _import),
            ),
          ],
        ),
        if (_message != null) ...[const SizedBox(height: 12), _messageBar()],
        const SizedBox(height: 16),
        for (final s in files) _listItem(s),
        if (files.isEmpty) Text('No scripts yet. Start from an example, or press New.', style: KText.bodySm.copyWith(color: K.textMuted)),
        const SizedBox(height: 16),
        _examples(),
      ],
    );
  }
}

class _ScriptMenu extends StatelessWidget {
  const _ScriptMenu({required this.onRename, required this.onDuplicate, required this.onExport, required this.onReveal, required this.onDelete});
  final VoidCallback onRename, onDuplicate, onExport, onReveal, onDelete;
  @override
  Widget build(BuildContext context) => PopupMenuButton<VoidCallback>(
    tooltip: 'More',
    color: K.surfaceRaised,
    icon: const KIcon('chevron-down', size: 16, color: K.textSecondary),
    onSelected: (f) => f(),
    itemBuilder: (_) => [
      for (final (label, f) in [('Rename', onRename), ('Duplicate', onDuplicate), ('Export', onExport), (Platform.isMacOS ? 'Show in Finder' : 'Show in folder', onReveal), ('Delete', onDelete)])
        PopupMenuItem(value: f, child: Text(label, style: KText.bodySm.copyWith(color: K.textPrimary))),
    ],
  );
}

class _NewScriptDialog extends StatefulWidget {
  const _NewScriptDialog();
  @override
  State<_NewScriptDialog> createState() => _NewScriptDialogState();
}

class _NewScriptDialogState extends State<_NewScriptDialog> {
  final _name = TextEditingController(text: 'My script');
  String template = scriptTemplates.keys.first;
  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => KDialogPanel(
    title: 'New script',
    onClose: () => Navigator.pop(context),
    footer: [
      KButton('Cancel', variant: KButtonVariant.ghost, onPressed: () => Navigator.pop(context)),
      KButton('Create', onPressed: () => Navigator.pop(context, (_name.text.trim().isEmpty ? 'My script' : _name.text.trim(), template))),
    ],
    children: [
      KInput(controller: _name, height: 40, style: KText.bodySm),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final e in scriptTemplates.entries)
            Pressable(
              onTap: () => setState(() => template = e.key),
              builder: (_, _, _) => KTag(e.value, tone: template == e.key ? TagTone.accent : TagTone.neutral, height: 30),
            ),
        ],
      ),
    ],
  );
}

class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.title, required this.initial});
  final String title, initial;
  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final _c = TextEditingController(text: widget.initial);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => KDialogPanel(
    title: widget.title,
    onClose: () => Navigator.pop(context),
    footer: [
      KButton('Cancel', variant: KButtonVariant.ghost, onPressed: () => Navigator.pop(context)),
      KButton('Save', onPressed: () => Navigator.pop(context, _c.text.trim().isEmpty ? null : _c.text.trim())),
    ],
    children: [KInput(controller: _c, height: 40, style: KText.bodySm)],
  );
}
