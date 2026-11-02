// The app's languages: each has every string English has, with the same
// placeholders, and the language shown is the one chosen, else the system's.
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:koebelt_dash/app.dart' show navLabel;
import 'package:koebelt_dash/l10n/l10n.dart';
import 'package:koebelt_dash/screens/guides_data.dart' show guideTexts;

Map<String, dynamic> _arb(String locale) => jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync()) as Map<String, dynamic>;

Set<String> _placeholders(String s) => RegExp(r'(?<![=\w])\{(\w+)\s*[,}]').allMatches(s).map((m) => m[1]!).toSet();

void main() {
  final en = _arb('en');
  final keys = en.keys.where((k) => !k.startsWith('@')).toSet();
  final locales = [
    for (final f in Directory('lib/l10n').listSync())
      if (RegExp(r'app_(\w+)\.arb$').firstMatch(f.path) case final m? when m[1] != 'en') m[1]!,
  ];

  test('every language has every string, with the same placeholders', () {
    expect(locales, isNotEmpty);
    for (final l in locales) {
      final arb = _arb(l);
      final have = arb.keys.where((k) => !k.startsWith('@')).toSet();
      expect(keys.difference(have), isEmpty, reason: '$l lacks these');
      expect(have.difference(keys), isEmpty, reason: '$l has strings English does not');
      for (final k in keys) {
        expect(_placeholders(arb[k] as String), _placeholders(en[k] as String), reason: '$l: $k');
      }
    }
  });

  test('each language has a name in Settings', () {
    for (final l in ['en', ...locales]) {
      expect(languageNames.containsKey(l), isTrue, reason: l);
    }
  });

  test('the language chosen, else the system\'s, else English', () {
    expect(resolveLocale('fr', [const Locale('de')]), const Locale('fr'));
    expect(resolveLocale('', [const Locale('fr', 'CA'), const Locale('en')]), const Locale('fr'));
    expect(resolveLocale('', [const Locale('xx'), const Locale('fr')]), const Locale('fr'));
    expect(resolveLocale('', [const Locale('xx')]), const Locale('en'));
    expect(resolveLocale('xx', [const Locale('xx')]), const Locale('en'), reason: 'a setting the app no longer has');
  });

  test('the guides are translated in full, and nothing is left from older text', () {
    final texts = guideTexts().toSet();
    for (final MapEntry(key: lang, value: table) in guideTables.entries) {
      expect(texts.difference(table.keys.toSet()), isEmpty, reason: '$lang lacks these (run the guide extraction again)');
      expect(table.keys.toSet().difference(texts), isEmpty, reason: '$lang still has these, no longer in the guides');
    }
  });

  test('the text follows the language', () {
    useLocale(const Locale('fr'));
    expect(navLabel('settings'), 'Réglages');
    useLocale(const Locale('en'));
    expect(navLabel('settings'), 'Settings');
  });
}
