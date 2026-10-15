import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/dash.dart';
import '../core/updater.dart';
import '../link/protocol.dart' show appVersion;
import '../theme/tokens.dart';
import '../ui/components.dart';
import '../ui/icons.dart';
import 'guides_data.dart' show repoUrl;
import 'settings.dart' show SetRow;

/// Top-bar pill while an update is waiting, downloading or installing.
class UpdateChip extends StatelessWidget {
  const UpdateChip({super.key, required this.d, this.compact = false, this.gap = 0});
  final Dash d;
  final bool compact;

  /// Space before the pill, only while it shows.
  final double gap;

  @override
  Widget build(BuildContext context) {
    final u = d.updater;
    final busy = u.state == UpdateState.downloading || u.state == UpdateState.installing;
    if (!u.nudge && !busy) return const SizedBox.shrink();
    final text = switch (u.state) {
      UpdateState.downloading => 'UPDATING ${(u.progress * 100).round()}%',
      UpdateState.installing => 'INSTALLING',
      _ => compact ? 'UPDATE' : 'UPDATE ${u.available!.version}',
    };
    return Padding(
      padding: EdgeInsets.only(left: gap),
      child: Tooltip(
        message: busy ? 'koebelt dash is updating' : 'koebelt dash ${u.available!.version} is available',
        child: GestureDetector(
          onTap: () => showUpdateDialog(context, d),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Container(
              height: 30,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: K.accent),
                borderRadius: BorderRadius.circular(K.radiusControl),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const KIcon('download', size: 14, color: K.textAccent),
                  const SizedBox(width: 8),
                  MonoLabel(text, color: K.textAccent, maxLines: 1),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The update, its notes and one button that installs it.
Future<void> showUpdateDialog(BuildContext context, Dash d) => showKDialog<void>(
  context,
  builder: (ctx) => ListenableBuilder(
    listenable: d,
    builder: (ctx, _) {
      final u = d.updater, rel = u.available;
      final busy = u.state == UpdateState.downloading || u.state == UpdateState.installing;
      final linked = d.links.isNotEmpty;
      return KDialogPanel(
        title: rel == null ? 'koebelt dash is up to date' : 'koebelt dash ${rel.version}',
        width: 560,
        onClose: () => Navigator.pop(ctx),
        footer: [
          if (rel != null && !busy) ...[
            KButton(
              'Skip this version',
              variant: KButtonVariant.ghost,
              onPressed: () {
                u.skip();
                Navigator.pop(ctx);
              },
            ),
            KButton('Later', variant: KButtonVariant.ghost, onPressed: () => Navigator.pop(ctx)),
          ],
          if (rel != null)
            KButton(
              busy ? (u.state == UpdateState.installing ? 'Installing…' : 'Downloading ${(u.progress * 100).round()}%') : 'Update now',
              iconLeft: const KIcon('download', size: 16),
              onPressed: busy || d.updateBlocked ? null : u.install,
            ),
        ],
        children: [
          if (rel != null) ...[
            Text('You have $appVersion. ${updateHowText(u.os)}', style: KText.bodySm.copyWith(color: K.textSecondary)),
            if (d.updateBlocked)
              const KNotice(
                tone: Tone.warning,
                title: 'Disarm first',
                child: Text('A connected device is armed. Updating closes the app, which drops the link; disarm it, then update.'),
              )
            else if (linked)
              KNotice(
                tone: Tone.info,
                title: 'Devices will disconnect',
                child: Text(
                  'Updating closes the app, so ${d.links.length == 1 ? 'the connected device' : 'the ${d.links.length} connected devices'} lose the link and their failsafe takes over until you reconnect.',
                ),
              ),
            if (busy) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: u.state == UpdateState.installing ? null : u.progress,
                  minHeight: 4,
                  color: K.accent,
                  backgroundColor: K.surfaceSunken,
                ),
              ),
            ],
            if (u.error != null) KNotice(tone: Tone.negative, title: 'Not updated', child: Text(u.error!)),
            const MonoLabel("What's new"),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: SingleChildScrollView(child: ReleaseNotes(rel.notes)),
            ),
            KButton(
              'Full release notes',
              size: KSize.sm,
              variant: KButtonVariant.ghost,
              iconRight: const KIcon('arrow-up-right', size: 14),
              onPressed: () => launchUrl(Uri.parse(rel.url)),
            ),
          ],
        ],
      );
    },
  ),
);

/// What happens when you press Update, per platform.
String updateHowText(String os) => switch (os) {
  'android' => 'The update downloads here and Android asks you to confirm the install.',
  _ => 'The update downloads, is checked against the release, and koebelt dash restarts on the new version.',
};

/// Settings > Updates.
class UpdatesSection extends StatelessWidget {
  const UpdatesSection({super.key, required this.d, required this.phone});
  final Dash d;
  final bool phone;

  @override
  Widget build(BuildContext context) {
    final u = d.updater;
    if (!u.enabled) {
      return SetRow(
        phone: phone,
        title: 'Version $appVersion',
        desc:
            'This build does not update itself: the App Store and TestFlight update theirs, and the downloads from GitHub check for new versions on their own.',
        child: KButton(
          'Releases',
          size: KSize.sm,
          variant: KButtonVariant.ghost,
          iconRight: const KIcon('arrow-up-right', size: 14),
          onPressed: () => launchUrl(Uri.parse('$repoUrl/releases')),
        ),
      );
    }
    final status = switch (u.state) {
      UpdateState.checking => 'Checking…',
      UpdateState.upToDate => 'Up to date.',
      UpdateState.available => '${u.available!.version} is available.',
      UpdateState.downloading => 'Downloading ${u.available!.version}… ${(u.progress * 100).round()}%',
      UpdateState.installing => 'Installing ${u.available!.version}…',
      UpdateState.failed => u.error ?? 'Something went wrong.',
      UpdateState.idle => 'Not checked yet.',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SetRow(
          phone: phone,
          title: 'Version $appVersion',
          desc: status,
          child: u.state == UpdateState.available || u.state == UpdateState.downloading || u.state == UpdateState.installing
              ? KButton(
                  'Update to ${u.available!.version}',
                  size: KSize.sm,
                  iconLeft: const KIcon('download', size: 14),
                  onPressed: () => showUpdateDialog(context, d),
                )
              : KButton('Check now', size: KSize.sm, variant: KButtonVariant.secondary, onPressed: u.state == UpdateState.checking ? null : u.check),
        ),
        SetRow(
          phone: phone,
          title: 'Check for updates automatically',
          desc: 'At launch and once a day, koebelt dash asks GitHub for the latest release. Nothing else is sent.',
          child: KSwitch(checked: u.auto, onChanged: u.setAuto),
        ),
      ],
    );
  }
}

/// Release notes are Markdown on GitHub; this shows their headings, bullets
/// and paragraphs as plain text, and leaves tables to the full notes.
class ReleaseNotes extends StatelessWidget {
  const ReleaseNotes(this.md, {super.key});
  final String md;

  static String _inline(String s) => s.replaceAll('**', '').replaceAll('`', '').replaceAllMapped(RegExp(r'\[([^\]]+)\]\([^)]+\)'), (m) => m[1]!);

  @override
  Widget build(BuildContext context) {
    final out = <Widget>[];
    for (final raw in md.split('\n')) {
      final l = raw.trimRight();
      if (l.trim().isEmpty || l.trimLeft().startsWith('|')) continue;
      if (l.startsWith('#')) {
        out.add(Padding(padding: const EdgeInsets.only(top: 12, bottom: 6), child: MonoLabel(_inline(l.replaceFirst(RegExp(r'^#+\s*'), '')).toUpperCase())));
      } else if (RegExp(r'^\s*[-*]\s').hasMatch(l)) {
        out.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('·  ', style: KText.bodySm.copyWith(color: K.textMuted)),
                Expanded(
                  child: Text(_inline(l.replaceFirst(RegExp(r'^\s*[-*]\s+'), '')), style: KText.bodySm.copyWith(color: K.textSecondary)),
                ),
              ],
            ),
          ),
        );
      } else {
        out.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(_inline(l), style: KText.bodySm.copyWith(color: K.textSecondary)),
          ),
        );
      }
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: out);
  }
}
