// The app's text in each language. Strings live in app_<locale>.arb (English
// the reference); `flutter gen-l10n` writes app_localizations*.dart from them.
//
// Text meant for AI assistants (MCP), logs and the device protocol stays in
// English and does not come from here.
import 'dart:ui' show Locale, PlatformDispatcher;

import 'app_localizations.dart';
import 'guides_de.dart';
import 'guides_es.dart';
import 'guides_fr.dart';
import 'guides_pt.dart';

export 'app_localizations.dart';

/// The text in the language shown, for widgets and for the rest of the app
/// (alerts, device kinds, errors) alike: `t.navLive`.
AppLocalizations t = lookupAppLocalizations(const Locale('en'));

/// Each language the app has, by its own name, as Settings > Language lists them.
const languageNames = {'en': 'English', 'de': 'Deutsch', 'es': 'Español', 'fr': 'Français', 'pt': 'Português (Brasil)'};

/// The language to show: the one chosen in Settings ([setting], `fr` or
/// `pt_BR`), else the first of the system's the app has, else English.
Locale resolveLocale(String setting, [List<Locale>? system]) {
  Locale parse(String s) {
    final p = s.split('_');
    return Locale(p[0], p.length > 1 ? p[1] : null);
  }

  bool has(Locale l) => AppLocalizations.supportedLocales.any((s) => s == l);
  if (setting.isNotEmpty && has(parse(setting))) return parse(setting);
  for (final l in system ?? PlatformDispatcher.instance.locales) {
    final full = Locale(l.languageCode, l.countryCode);
    if (has(full)) return full;
    if (has(Locale(l.languageCode))) return Locale(l.languageCode);
  }
  return const Locale('en');
}

/// Switches [t] to [locale]'s text.
void useLocale(Locale locale) => t = lookupAppLocalizations(locale);

/// "a, b and c", in the language shown.
String joinAnd(List<String> items) => items.length < 2 ? items.join() : '${items.sublist(0, items.length - 1).join(', ')} ${t.and} ${items.last}';

/// [t], where a local `t` names something else (telemetry, a time).
AppLocalizations get tr => t;

/// "a, b or c", in the language shown.
String joinOr(List<String> items) => items.length < 2 ? items.join() : '${items.sublist(0, items.length - 1).join(', ')} ${t.orLower} ${items.last}';

/// [t] again, where both `t` and `tr` name something else.
AppLocalizations get appText => t;

/// Guide text in the language shown: [en] is the English source; where the
/// language has no translation for it (yet), the English shows.
String tg(String en) => (guideTables[t.localeName]?[en]) ?? en;

/// The guide translations, by language.
const guideTables = {'fr': guidesFr, 'es': guidesEs, 'de': guidesDe, 'pt': guidesPt};
