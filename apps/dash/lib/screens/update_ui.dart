import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/compat.dart';
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

/// A release, its notes and one button that installs it: the update by
/// default, or [pick], a version chosen in Settings (older ones too). Before
/// installing, it checks the release's compat.json against the library
/// versions the paired devices last reported.
Future<void> showUpdateDialog(BuildContext context, Dash d, [AppRelease? pick]) => showKDialog<void>(
  context,
  builder: (ctx) => ListenableBuilder(
    listenable: d,
    builder: (ctx, _) {
      final u = d.updater, rel = pick ?? u.available;
      final busy = u.state == UpdateState.downloading || u.state == UpdateState.installing;
      final linked = d.links.isNotEmpty;
      final older = rel != null && compareVersions(rel.version, u.current) < 0;
      final blockedWhy = rel == null ? null : u.cannotInstall(rel);
      return KDialogPanel(
        title: rel == null ? 'koebelt dash is up to date' : 'koebelt dash ${rel.version}',
        width: 600,
        onClose: () => Navigator.pop(ctx),
        footer: [
          if (rel != null && !busy) ...[
            if (pick == null)
              KButton(
                'Skip this version',
                variant: KButtonVariant.ghost,
                onPressed: () {
                  u.skip();
                  Navigator.pop(ctx);
                },
              ),
            KButton(pick == null ? 'Later' : 'Cancel', variant: KButtonVariant.ghost, onPressed: () => Navigator.pop(ctx)),
          ],
          if (rel != null && blockedWhy == null)
            FutureBuilder<Compat?>(
              future: u.compatOf(rel),
              builder: (_, snap) {
                final bad = snap.data?.incompatible(d.devices) ?? const [];
                return KButton(
                  busy
                      ? (u.state == UpdateState.installing ? 'Installing…' : 'Downloading ${(u.progress * 100).round()}%')
                      : bad.isNotEmpty
                      ? (older ? 'Install anyway' : 'Update anyway')
                      : (older ? 'Install ${rel.version}' : 'Update now'),
                  iconLeft: const KIcon('download', size: 16),
                  variant: bad.isNotEmpty && !busy ? KButtonVariant.secondary : KButtonVariant.primary,
                  onPressed: busy || d.updateBlocked || snap.connectionState != ConnectionState.done ? null : () => u.install(rel),
                );
              },
            ),
        ],
        children: [
          if (rel != null) ...[
            Text(
              older
                  ? 'You have $appVersion; this is an older version. Settings and recordings made with a newer version may not all open in it, and it will not remind you about newer ones until the next release.'
                  : 'You have $appVersion. ${updateHowText(u.os)}',
              style: KText.bodySm.copyWith(color: K.textSecondary),
            ),
            if (blockedWhy != null) KNotice(tone: Tone.info, title: 'Not from the app', child: Text(blockedWhy)),
            FutureBuilder<Compat?>(
              future: u.compatOf(rel),
              builder: (_, snap) {
                if (snap.connectionState != ConnectionState.done) return const MonoLabel('Checking compatibility with your devices…');
                final c = snap.data;
                if (c == null) {
                  return const KNotice(
                    tone: Tone.warning,
                    title: 'Compatibility unknown',
                    child: Text('Could not read which koebelt/link versions this release supports.'),
                  );
                }
                final bad = c.incompatible(d.devices);
                if (bad.isEmpty) return const SizedBox.shrink();
                return KNotice(
                  tone: Tone.warning,
                  title: 'Not compatible with ${bad.length == 1 ? 'one of your devices' : '${bad.length} of your devices'}',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final b in bad) Text('${b.device.name}: ${b.why}.'),
                      const SizedBox(height: 8),
                      Text(
                        'Update the koebelt/link library on ${bad.length == 1 ? 'it' : 'them'} first, or keep your version and choose another in Settings > Updates.',
                        style: KText.bodySm.copyWith(color: K.textMuted),
                      ),
                    ],
                  ),
                );
              },
            ),
            if (d.updateBlocked)
              const KNotice(
                tone: Tone.warning,
                title: 'Disarm first',
                child: Text('A connected device is armed. Updating closes the app, which drops the link; disarm it, then update.'),
              )
            else if (linked && blockedWhy == null)
              KNotice(
                tone: Tone.info,
                title: 'Devices will disconnect',
                child: Text(
                  'Installing closes the app, so ${d.links.length == 1 ? 'the connected device' : 'the ${d.links.length} connected devices'} lose the link and their failsafe takes over until you reconnect.',
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
            if (u.error != null && u.installing?.version == rel.version) KNotice(tone: Tone.negative, title: 'Not installed', child: Text(u.error!)),
            MonoLabel(older ? 'In this version' : "What's new"),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: SingleChildScrollView(child: ReleaseNotes(rel.notes)),
            ),
            Wrap(
              spacing: 8,
              children: [
                KButton(
                  'Full release notes',
                  size: KSize.sm,
                  variant: KButtonVariant.ghost,
                  iconRight: const KIcon('arrow-up-right', size: 14),
                  onPressed: () => launchUrl(Uri.parse(rel.url)),
                ),
                if (pick == null && !busy)
                  KButton(
                    'Choose another version',
                    size: KSize.sm,
                    variant: KButtonVariant.ghost,
                    onPressed: () {
                      Navigator.pop(ctx);
                      showVersionPicker(context, d);
                    },
                  ),
              ],
            ),
          ],
        ],
      );
    },
  ),
);

/// Every release, newest first, with whether it works with your devices;
/// choosing one opens [showUpdateDialog] for it.
Future<void> showVersionPicker(BuildContext context, Dash d) {
  final u = d.updater;
  if (u.releases.isEmpty && u.state != UpdateState.checking) u.check();
  return showKDialog<void>(
    context,
    builder: (ctx) => ListenableBuilder(
      listenable: d,
      builder: (ctx, _) => KDialogPanel(
        title: 'Choose a version',
        width: 600,
        onClose: () => Navigator.pop(ctx),
        footer: [KButton('Close', variant: KButtonVariant.ghost, onPressed: () => Navigator.pop(ctx))],
        children: [
          Text(
            'Install any published version, newer or older. Each one says whether it works with the koebelt/link versions your devices reported when they last connected.',
            style: KText.bodySm.copyWith(color: K.textSecondary),
          ),
          if (u.releases.isEmpty)
            MonoLabel(u.state == UpdateState.checking ? 'Asking GitHub…' : (u.error ?? 'No releases found.'))
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 420),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [for (final r in u.releases) _VersionRow(d: d, r: r, onPick: () => showUpdateDialog(context, d, r))],
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class _VersionRow extends StatelessWidget {
  const _VersionRow({required this.d, required this.r, required this.onPick});
  final Dash d;
  final AppRelease r;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final u = d.updater;
    final isCurrent = r.version == u.current, isLatest = u.latest?.version == r.version;
    final why = u.cannotInstall(r);
    final date = r.date == null ? '' : '${r.date!.year}-${r.date!.month.toString().padLeft(2, '0')}-${r.date!.day.toString().padLeft(2, '0')}';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: K.borderHairline)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(r.version, style: KText.mono(14, color: K.textPrimary)),
                    if (isCurrent) const KTag('Installed', tone: TagTone.accent, height: 20),
                    if (isLatest && !isCurrent) const KTag('Latest', tone: TagTone.info, height: 20),
                    if (date.isNotEmpty) MonoLabel(date),
                  ],
                ),
                const SizedBox(height: 6),
                FutureBuilder<Compat?>(
                  future: u.compatOf(r),
                  builder: (_, snap) {
                    if (snap.connectionState != ConnectionState.done) return const MonoLabel('Checking…');
                    final bad = snap.data?.incompatible(d.devices);
                    final text = bad == null
                        ? 'Compatibility unknown'
                        : bad.isEmpty
                        ? (d.devices.any((x) => x.lib != null) ? 'Works with your devices' : 'No devices to check yet')
                        : 'Not for ${bad.map((b) => b.device.name).join(', ')}';
                    return Text(text, style: KText.bodySm.copyWith(color: bad != null && bad.isNotEmpty ? K.warning : K.textMuted));
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (!isCurrent)
            Tooltip(
              message: why ?? '',
              child: KButton(
                why == null ? (compareVersions(r.version, u.current) < 0 ? 'Install' : 'Update') : 'Details',
                size: KSize.sm,
                variant: KButtonVariant.secondary,
                onPressed: onPick,
              ),
            ),
        ],
      ),
    );
  }
}

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
    final busyWith = u.installing?.version ?? u.available?.version;
    final status = switch (u.state) {
      UpdateState.checking => 'Checking…',
      UpdateState.upToDate => 'Up to date.',
      UpdateState.available => '${u.available!.version} is available.',
      UpdateState.downloading => 'Downloading $busyWith… ${(u.progress * 100).round()}%',
      UpdateState.installing => 'Installing $busyWith…',
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
          child: u.available != null && u.state != UpdateState.checking
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
          title: 'Choose a version',
          desc: 'Install any published version, older ones too, with whether it works with your devices’ koebelt/link libraries.',
          child: KButton('Versions', size: KSize.sm, variant: KButtonVariant.secondary, onPressed: () => showVersionPicker(context, d)),
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
