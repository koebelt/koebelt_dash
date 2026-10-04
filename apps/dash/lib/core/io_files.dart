import 'dart:convert';
import 'dart:io';

Future<List<Map<String, dynamic>>> readAll(String dir) async {
  final d = Directory(dir);
  if (!await d.exists()) return [];
  final out = <Map<String, dynamic>>[];
  await for (final f in d.list()) {
    if (f is! File || !f.path.endsWith('.json')) continue;
    try {
      out.add(jsonDecode(await f.readAsString()) as Map<String, dynamic>);
    } catch (_) {}
  }
  return out;
}

Future<void> write(String dir, String name, String content) async {
  await Directory(dir).create(recursive: true);
  await File('$dir/$name').writeAsString(content);
}

Future<void> delete(String dir, String name) async {
  final f = File('$dir/$name');
  if (await f.exists()) await f.delete();
}
