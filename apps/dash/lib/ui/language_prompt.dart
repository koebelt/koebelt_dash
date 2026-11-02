import 'package:flutter/material.dart';

import '../core/dash.dart';
import '../l10n/l10n.dart';
import '../theme/tokens.dart';
import 'components.dart';

/// On the first launch with the system in Traditional Chinese, which the app
/// does not have, asks which language to use instead. Asked once: closing it
/// keeps Simplified Chinese, and Settings > Language changes it later.
Future<void> askLanguageIfNeeded(BuildContext context, Dash d) async {
  if (!shouldAskLanguage(d)) return;
  d.updateSettings((s) => s.languageAsked = true);
  final picked = await showKDialog<String>(context, builder: (ctx) => const _LanguagePrompt());
  if (picked != null) d.updateSettings((s) => s.language = picked);
}

/// Whether [askLanguageIfNeeded] has a question to ask.
bool shouldAskLanguage(Dash d) =>
    !d.settings.languageAsked && d.settings.language.isEmpty && systemIsTraditionalChinese(WidgetsBinding.instance.platformDispatcher.locales);

class _LanguagePrompt extends StatelessWidget {
  const _LanguagePrompt();

  @override
  Widget build(BuildContext context) {
    // In both scripts and in English: the reader has neither as their own.
    final order = ['zh', 'en', ...languageNames.keys.where((k) => k != 'zh' && k != 'en')];
    return KDialogPanel(
      title: '語言 · Language',
      width: 460,
      onClose: () => Navigator.of(context).pop(),
      children: [
        Text('koebelt dash 尚未提供繁體中文。您想使用哪種語言？之後可在設定中更改。', style: KText.bodyMd.copyWith(color: K.textPrimary)),
        const Text('koebelt dash is not available in Traditional Chinese yet. Which language would you like? You can change it later in Settings.'),
        Wrap(
          spacing: K.s3,
          runSpacing: K.s3,
          children: [
            for (final (i, code) in order.indexed)
              KButton(
                languageNames[code]!,
                size: KSize.sm,
                variant: [KButtonVariant.primary, KButtonVariant.secondary].elementAtOrNull(i) ?? KButtonVariant.ghost,
                onPressed: () => Navigator.of(context).pop(code),
              ),
          ],
        ),
      ],
    );
  }
}
