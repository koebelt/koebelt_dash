import 'dart:convert';
import 'dart:io';

/// Recordings are gzip-compressed JSON (`.json.gz`); older ones plain `.json`.
Future<List<Map<String, dynamic>>> readAll(String dir) async {
  final d = Directory(dir);
  if (!await d.exists()) return [];
  final out = <Map<String, dynamic>>[];
  await for (final f in d.list()) {
    if (f is! File) continue;
    final gz = f.path.endsWith('.json.gz');
    if (!gz && !f.path.endsWith('.json')) continue;
    try {
      final bytes = await f.readAsBytes();
      out.add(jsonDecode(utf8.decode(gz ? gzip.decode(bytes) : bytes)) as Map<String, dynamic>);
    } catch (_) {}
  }
  return out;
}

Future<void> write(String dir, String name, String content) async {
  await Directory(dir).create(recursive: true);
  await File('$dir/$name').writeAsString(content);
}

/// Writes `name.gz`, compressed, and removes an older uncompressed `name`.
Future<void> writeCompressed(String dir, String name, String content) async {
  await Directory(dir).create(recursive: true);
  await File('$dir/$name.gz').writeAsBytes(gzip.encode(utf8.encode(content)));
  final old = File('$dir/$name');
  if (await old.exists()) await old.delete();
}

Future<void> delete(String dir, String name) async {
  for (final n in [name, '$name.gz']) {
    final f = File('$dir/$n');
    if (await f.exists()) await f.delete();
  }
}
