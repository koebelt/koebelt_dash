import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart';

import '../screens/guides_data.dart';

/// A bundled text, gzip-compressed (tools/assets/sync_app_assets.py): App
/// Store Connect refuses an iOS app holding readable Python as unsigned code.
Future<String> loadBundledText(AssetBundle bundle, String asset) async {
  final data = await bundle.load(asset);
  return utf8.decode(const GZipDecoder().decodeBytes(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes)));
}

/// The bundled examples' assets, sorted.
Future<List<String>> bundledExamples(AssetBundle bundle) async {
  final manifest = await AssetManifest.loadFromAssetBundle(bundle);
  return manifest.listAssets().where((a) => a.startsWith('assets/script_examples/') && a.endsWith('.py.gz')).toList()..sort();
}

/// An example's file name: drive_square.py.
String exampleName(String asset) => asset.split('/').last.replaceAll(RegExp(r'\.gz$'), '');

/// A document an assistant can read: a guide, a reference, an example.
class Doc {
  const Doc(this.id, this.title, this.text);
  final String id, title, text;
}

/// A guide as Markdown, every platform's code included.
String guideMarkdown(Guide g) {
  final b = StringBuffer('# ${g.title}\n\n${g.sub}\n');
  for (final s in g.steps) {
    b.write('\n## ${s.t}\n\n${s.p}\n');
    for (final x in s.bullets) {
      b.write('- $x\n');
    }
    if (s.note != null) b.write('\n${s.warn ? 'Warning' : 'Note'}: ${s.note}\n');
    for (final row in s.table ?? const <List<String>>[]) {
      b.write('| ${row.join(' | ')} |\n');
    }
    for (final e in s.c.entries) {
      b.write('\n${platforms.where((p) => p.id == e.key).firstOrNull?.name ?? e.key}:\n```${e.value[0]}\n${e.value[1]}\n```\n');
    }
  }
  for (final row in g.table ?? const <List<String>>[]) {
    b.write('| ${row.join(' | ')} |\n');
  }
  return b.toString();
}

/// Everything assistants can read: the guides, the protocols, the script
/// API and its examples.
Future<List<Doc>> loadDocs(AssetBundle bundle) async {
  final docs = <Doc>[
    for (final g in [quickstart('<pairing code from the app>'), ...guides]) Doc('guide:${g.id}', g.title, guideMarkdown(g)),
  ];
  const refs = {
    'assets/docs/SCRIPTS_API.md.gz': ('ref:scripts-api', 'Python script API (koebelt-dash-scripts)'),
    'assets/docs/SCRIPTS.md.gz': ('ref:scripts-protocol', 'Script API messages and script hosts'),
    'assets/docs/PROTOCOL.md.gz': ('ref:protocol', 'koebelt/link device protocol'),
  };
  for (final e in refs.entries) {
    try {
      docs.add(Doc(e.value.$1, e.value.$2, await loadBundledText(bundle, e.key)));
    } catch (_) {}
  }
  try {
    for (final a in await bundledExamples(bundle)) {
      final name = exampleName(a);
      docs.add(Doc('example:$name', 'Example script: $name', await loadBundledText(bundle, a)));
    }
  } catch (_) {}
  return docs;
}

/// Passages that match a query best: (doc, heading, text), most relevant first.
List<({Doc doc, String passage})> searchDocs(List<Doc> docs, String query, {int limit = 6}) {
  final words = query.toLowerCase().split(RegExp(r'[^a-z0-9_]+')).where((w) => w.length > 1).toSet();
  if (words.isEmpty) return const [];
  final hits = <({Doc doc, String passage, double score})>[];
  for (final d in docs) {
    // Passages: sections between headings, or the whole of a short document.
    final parts = d.text.split(RegExp(r'\n(?=#{1,3} )'));
    for (final p in parts) {
      final lower = p.toLowerCase();
      var score = 0.0;
      for (final w in words) {
        final n = RegExp(RegExp.escape(w)).allMatches(lower).length;
        if (n > 0) score += 1 + n * .2;
      }
      if (d.title.toLowerCase().contains(query.toLowerCase())) score += 2;
      if (score > 0) hits.add((doc: d, passage: p.length > 2400 ? '${p.substring(0, 2400)}…' : p, score: score / (1 + p.length / 4000)));
    }
  }
  hits.sort((a, b) => b.score.compareTo(a.score));
  return [for (final h in hits.take(limit)) (doc: h.doc, passage: h.passage)];
}
