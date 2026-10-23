import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';

import '../core/model.dart';

/// A script in the library: a `.py` file, or a folder with a `main.py` and
/// the files it needs (a model, a config…), as a `.zip` import makes.
class ScriptFile {
  ScriptFile(this.file, this.name);

  /// The file dash runs.
  final File file;

  /// The first line of the script's docstring, else its file name.
  final String name;
  String get path => file.path;

  /// What the list shows under the name: `follow_me.py`, or `follow/` for a folder.
  String get label {
    final parent = file.parent.uri.pathSegments.where((s) => s.isNotEmpty).last;
    final base = file.uri.pathSegments.last;
    return base == 'main.py' && _isFolderScript ? '$parent/' : base;
  }

  bool get _isFolderScript => file.uri.pathSegments.last == 'main.py';

  /// The file or folder the library manages (deleting, renaming).
  FileSystemEntity get entry => _isFolderScript ? file.parent : file;
}

/// The scripts folder: `~/Documents/koebelt/dash-scripts` on computers, the
/// app's documents on phones and tablets (visible in Files / the file manager).
class ScriptLibrary {
  ScriptLibrary(this.dir);
  final Directory dir;

  static Future<Directory> defaultDir() async {
    if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
      final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '.';
      return Directory('$home${Platform.pathSeparator}Documents${Platform.pathSeparator}koebelt${Platform.pathSeparator}dash-scripts');
    }
    return Directory('${(await getApplicationDocumentsDirectory()).path}/dash-scripts');
  }

  Directory get trash => Directory('${dir.path}/.trash');

  Future<List<ScriptFile>> list() async {
    if (!await dir.exists()) return [];
    final out = <ScriptFile>[];
    await for (final e in dir.list()) {
      final base = e.uri.pathSegments.where((s) => s.isNotEmpty).last;
      if (base.startsWith('.') || base.startsWith('_')) continue;
      if (e is File && base.endsWith('.py')) {
        out.add(ScriptFile(e, await _title(e)));
      } else if (e is Directory) {
        final main = File('${e.path}/main.py');
        if (await main.exists()) out.add(ScriptFile(main, await _title(main, fallback: base)));
      }
    }
    out.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return out;
  }

  /// The first line of the module docstring, or a title made from the name.
  static Future<String> _title(File f, {String? fallback}) async {
    try {
      final src = await f.readAsString();
      final m = RegExp(r'^\s*(?:#[^\n]*\n\s*)*[rbuRBU]?("""|' "'''" r')\s*([^\n]+)').firstMatch(src);
      if (m != null) {
        final line = m[2]!.split(m[1]!).first.trim().replaceAll(RegExp(r'[.\s]+$'), '');
        if (line.isNotEmpty) return line;
      }
    } catch (_) {}
    return titleOf(fallback ?? f.uri.pathSegments.last.replaceAll(RegExp(r'\.py$'), ''));
  }

  /// `follow_me` → `Follow me`.
  static String titleOf(String stem) {
    final s = stem.replaceAll(RegExp(r'[_-]+'), ' ').trim();
    return s.isEmpty ? 'Script' : s[0].toUpperCase() + s.substring(1);
  }

  /// `Follow me!` → `follow_me`.
  static String fileStem(String name) {
    final s = name.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'^_+|_+$'), '');
    return s.isEmpty ? 'script' : s;
  }

  /// A free path for [stem] (`follow_me.py`, `follow_me_2.py`…).
  Future<String> _free(String stem, {String ext = '.py'}) async {
    for (var n = 1;; n++) {
      final p = '${dir.path}/${n == 1 ? stem : '${stem}_$n'}$ext';
      if (!await File(p).exists() && !await Directory(p).exists()) return p;
    }
  }

  Future<File> create(String name, String source) async {
    await dir.create(recursive: true);
    final f = File(await _free(fileStem(name)));
    await f.writeAsString(source);
    return f;
  }

  /// A `.py` file, or a `.zip` with a script and its files (its `main.py`, or
  /// its only `.py` at the top, is the one dash runs).
  Future<File> import(String fileName, List<int> bytes) async {
    await dir.create(recursive: true);
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.py')) {
      final f = File(await _free(fileStem(fileName.substring(0, fileName.length - 3))));
      await f.writeAsBytes(bytes);
      return f;
    }
    if (!lower.endsWith('.zip')) throw const FormatException('Import a Python file (.py) or a .zip with one.');
    final zip = ZipDecoder().decodeBytes(bytes);
    final files = zip.files.where((e) => e.isFile && !e.name.startsWith('__MACOSX/') && !e.name.split('/').last.startsWith('.')).toList();
    // A zip of a folder has everything under one top folder: drop it.
    final tops = files.map((e) => e.name.split('/').first).toSet();
    final strip = tops.length == 1 && files.every((e) => e.name.contains('/')) ? '${tops.single}/' : '';
    final rel = {for (final e in files) e.name.substring(strip.length): e};
    final mainName = rel.containsKey('main.py')
        ? 'main.py'
        : rel.keys.where((k) => k.endsWith('.py') && !k.contains('/')).length == 1
        ? rel.keys.singleWhere((k) => k.endsWith('.py') && !k.contains('/'))
        : null;
    if (mainName == null) throw const FormatException('The .zip needs a main.py, or a single .py file at its top.');
    final folder = Directory(await _free(fileStem(fileName.substring(0, fileName.length - 4)), ext: ''));
    for (final e in rel.entries) {
      if (e.key.split('/').contains('..')) continue;
      final out = File('${folder.path}/${e.key == mainName ? 'main.py' : e.key}');
      await out.parent.create(recursive: true);
      await out.writeAsBytes(e.value.content);
    }
    return File('${folder.path}/main.py');
  }

  /// A script as a file to share: the `.py`, or a `.zip` of its folder.
  Future<({String name, List<int> bytes})> export(ScriptFile s) async {
    if (s.entry is File) return (name: s.file.uri.pathSegments.last, bytes: await s.file.readAsBytes());
    final a = Archive();
    final root = (s.entry as Directory).path;
    await for (final e in (s.entry as Directory).list(recursive: true)) {
      if (e is File) {
        final data = await e.readAsBytes();
        a.addFile(ArchiveFile(e.path.substring(root.length + 1).replaceAll('\\', '/'), data.length, data));
      }
    }
    return (name: '${s.label.replaceAll('/', '')}.zip', bytes: ZipEncoder().encode(a));
  }

  Future<File> duplicate(ScriptFile s) async {
    final stem = '${fileStem(s.label.replaceAll(RegExp(r'(\.py|/)$'), ''))}_copy';
    if (s.entry is File) {
      final f = File(await _free(stem));
      return s.file.copy(f.path);
    }
    final to = Directory(await _free(stem, ext: ''));
    await for (final e in (s.entry as Directory).list(recursive: true)) {
      if (e is File) {
        final out = File('${to.path}/${e.path.substring(s.entry.path.length + 1)}');
        await out.parent.create(recursive: true);
        await e.copy(out.path);
      }
    }
    return File('${to.path}/main.py');
  }

  /// Renames the file (or folder) after [name]; returns the file to run.
  Future<File> rename(ScriptFile s, String name) async {
    if (s.entry is File) {
      return s.file.rename(await _free(fileStem(name)));
    }
    final to = await (s.entry as Directory).rename(await _free(fileStem(name), ext: ''));
    return File('${to.path}/main.py');
  }

  /// Moves the script to the trash folder, from which it can be restored.
  Future<void> delete(ScriptFile s) async {
    await trash.create(recursive: true);
    final base = s.entry.uri.pathSegments.where((x) => x.isNotEmpty).last;
    final stamp = DateTime.now().toIso8601String().replaceAll(RegExp(r'[:.]'), '-');
    await s.entry.rename('${trash.path}/$stamp $base');
  }
}

/// What a new script starts from, for the selected device's kind.
String scriptTemplate(String template, DeviceKind kind, String title) {
  final sticks = switch (kind) {
    DeviceKind.drone => 'dev.sticks(throttle=0, yaw=0, pitch=0, roll=0)',
    DeviceKind.rover => 'dev.sticks(throttle=0, steer=0)',
    _ => '# dev.cmd(...)',
  };
  final head = '"""$title.\n\nRuns in your Python, driven by koebelt dash: STOP and the sticks always win.\n"""\n';
  switch (template) {
    case 'button':
      return '''${head}from koebelt_dash_scripts import connect

dev = connect()


@dev.trigger("Go", key="G")
def go():
    dev.notify("Go pressed")


dev.run()  # waits for triggers until the script is stopped
''';
    case 'loop':
    default:
      return '''${head}from koebelt_dash_scripts import connect, every

dev = connect()
speed = dev.setting("speed", 0.3, min=0, max=1)

for _ in every(0.05):  # 20 Hz
    t = dev.tlm
    $sticks
''';
  }
}

/// Templates offered by New script.
const scriptTemplates = {'loop': 'A control loop', 'button': 'A button action'};

/// JSON helpers for configs kept by the store.
Map<String, dynamic> jsonMap(Object? v) => v is Map ? v.cast<String, dynamic>() : <String, dynamic>{};
String prettyJson(Object v) => const JsonEncoder.withIndent(' ').convert(v);
