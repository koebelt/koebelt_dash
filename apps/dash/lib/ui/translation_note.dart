import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/l10n.dart';
import '../screens/guides_data.dart' show repoUrl;
import '../theme/tokens.dart';
import 'components.dart';

/// A quiet line saying the text shown was translated with AI, with a link to
/// the repository for corrections. Nothing in English.
class TranslationNote extends StatelessWidget {
  const TranslationNote({super.key});

  @override
  Widget build(BuildContext context) {
    if (t.localeName == 'en') return const SizedBox.shrink();
    final style = KText.bodySm.copyWith(color: K.textMuted, fontSize: 12);
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          TextSpan(text: '${t.translationNote} '),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: Pressable(
              onTap: () => launchUrl(Uri.parse(repoUrl)),
              builder: (context, hover, _) => Text(
                t.translationContribute,
                style: style.copyWith(
                  color: hover ? K.textPrimary : K.textSecondary,
                  decoration: TextDecoration.underline,
                  decorationColor: hover ? K.textPrimary : K.textMuted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
