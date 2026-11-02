// A system in Traditional Chinese, which the app does not have: the first
// launch asks which language to use, once.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koebelt_dash/core/dash.dart';
import 'package:koebelt_dash/l10n/l10n.dart';
import 'package:koebelt_dash/ui/language_prompt.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _hant = Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant', countryCode: 'TW');

void main() {
  test('Traditional Chinese is told apart from Simplified', () {
    expect(systemIsTraditionalChinese([_hant]), isTrue);
    expect(systemIsTraditionalChinese([const Locale('zh', 'HK')]), isTrue);
    expect(systemIsTraditionalChinese([const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant')]), isTrue);
    expect(systemIsTraditionalChinese([const Locale('zh', 'CN')]), isFalse);
    expect(systemIsTraditionalChinese([const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans', countryCode: 'SG')]), isFalse);
    expect(systemIsTraditionalChinese([const Locale('en'), _hant]), isFalse, reason: 'the app follows English first');
    expect(systemIsTraditionalChinese([const Locale('xx'), _hant]), isTrue, reason: 'a language the app lacks is skipped');
  });

  Future<Dash> launch(WidgetTester tester) async {
    final d = Dash();
    await tester.runAsync(d.init);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(onPressed: () => askLanguageIfNeeded(context, d), child: const Text('launch')),
          ),
        ),
      ),
    );
    await tester.tap(find.text('launch'));
    await tester.pumpAndSettle();
    return d;
  }

  testWidgets('asks once, and keeps the choice', (tester) async {
    tester.platformDispatcher.localesTestValue = [_hant];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    SharedPreferences.setMockInitialValues({});
    final d = await launch(tester);
    expect(find.text('語言 · Language'), findsOneWidget);
    await tester.tap(find.text('ENGLISH'));
    await tester.pumpAndSettle();
    expect(d.settings.language, 'en');
    expect(d.settings.languageAsked, isTrue);

    // Not again, even with the language back on the system's.
    d.updateSettings((s) => s.language = '');
    await tester.tap(find.text('launch'));
    await tester.pumpAndSettle();
    expect(find.text('語言 · Language'), findsNothing);
  });

  testWidgets('closing it keeps Simplified Chinese, and does not ask again', (tester) async {
    tester.platformDispatcher.localesTestValue = [_hant];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    SharedPreferences.setMockInitialValues({});
    final d = await launch(tester);
    expect(find.text('語言 · Language'), findsOneWidget);
    await tester.tapAt(const Offset(2, 2));
    await tester.pumpAndSettle();
    expect(find.text('語言 · Language'), findsNothing);
    expect(d.settings.language, '');
    expect(d.settings.languageAsked, isTrue);
  });

  testWidgets('never asked on other systems', (tester) async {
    tester.platformDispatcher.localesTestValue = [const Locale('zh', 'CN')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    SharedPreferences.setMockInitialValues({});
    final d = await launch(tester);
    expect(find.text('語言 · Language'), findsNothing);
    expect(d.settings.languageAsked, isFalse);
  });
}
