import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/l10n.dart';
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
      UpdateState.downloading => t.updatingPct((u.progress * 100).round()).toUpperCase(),
      UpdateState.installing => t.installingState.toUpperCase(),
      _ => compact ? t.update.toUpperCase() : '${t.update.toUpperCase()} ${u.available!.version}',
    };
    return Padding(
      padding: EdgeInsets.only(left: gap),
      child: Tooltip(
        message: busy ? t.appUpdating : t.appAvailable(u.available!.version),
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
        title: rel == null ? t.appUpToDate : 'koebelt dash ${rel.version}',
        width: 600,
        onClose: () => Navigator.pop(ctx),
        footer: [
          if (rel != null && !busy) ...[
            if (pick == null)
              KButton(
                t.skipVersion,
                variant: KButtonVariant.ghost,
                onPressed: () {
                  u.skip();
                  Navigator.pop(ctx);
                },
              ),
            KButton(pick == null ? t.later : t.cancel, variant: KButtonVariant.ghost, onPressed: () => Navigator.pop(ctx)),
          ],
          if (rel != null && blockedWhy == null)
            FutureBuilder<Compat?>(
              future: u.compatOf(rel),
              builder: (_, snap) {
                final bad = snap.data?.incompatible(d.devices) ?? const [];
                return KButton(
                  busy
                      ? (u.state == UpdateState.installing ? t.installing : t.downloadingPct((u.progress * 100).round()))
                      : bad.isNotEmpty
                      ? (older ? t.installAnyway : t.updateAnyway)
                      : (older ? t.installVersion(rel.version) : t.updateNow),
                  iconLeft: const KIcon('download', size: 16),
                  variant: bad.isNotEmpty && !busy ? KButtonVariant.secondary : KButtonVariant.primary,
                  onPressed: busy || d.updateBlocked || snap.connectionState != ConnectionState.done ? null : () => u.install(rel),
                );
              },
            ),
        ],
        children: [
          if (rel != null) ...[
            Text(older ? t.youHaveOlder(appVersion) : '${t.youHave(appVersion)} ${updateHowText(u.os)}', style: KText.bodySm.copyWith(color: K.textSecondary)),
            if (blockedWhy != null) KNotice(tone: Tone.info, title: t.notFromApp, child: Text(blockedWhy)),
            FutureBuilder<Compat?>(
              future: u.compatOf(rel),
              builder: (_, snap) {
                if (snap.connectionState != ConnectionState.done) return MonoLabel(t.checkingCompat);
                final c = snap.data;
                if (c == null) {
                  return KNotice(tone: Tone.warning, title: t.compatUnknown, child: Text(t.compatUnknownBody));
                }
                final bad = c.incompatible(d.devices);
                if (bad.isEmpty) return const SizedBox.shrink();
                return KNotice(
                  tone: Tone.warning,
                  title: t.notCompatibleWith(bad.length),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final b in bad) Text('${b.device.name}: ${b.why}.'),
                      const SizedBox(height: 8),
                      Text(t.notCompatibleBody(bad.length), style: KText.bodySm.copyWith(color: K.textMuted)),
                    ],
                  ),
                );
              },
            ),
            if (d.updateBlocked)
              KNotice(tone: Tone.warning, title: t.disarmFirst, child: Text(t.disarmFirstBody))
            else if (linked && blockedWhy == null)
              KNotice(tone: Tone.info, title: t.devicesWillDisconnect, child: Text(t.devicesWillDisconnectBody(d.links.length))),
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
            if (u.error != null && u.installing?.version == rel.version) KNotice(tone: Tone.negative, title: t.notInstalled, child: Text(u.error!)),
            MonoLabel(older ? t.inThisVersion : t.whatsNew),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: SingleChildScrollView(child: ReleaseNotes(rel.notes)),
            ),
            Wrap(
              spacing: 8,
              children: [
                KButton(
                  t.fullNotes,
                  size: KSize.sm,
                  variant: KButtonVariant.ghost,
                  iconRight: const KIcon('arrow-up-right', size: 14),
                  onPressed: () => launchUrl(Uri.parse(rel.url)),
                ),
                if (pick == null && !busy)
                  KButton(
                    t.chooseAnotherVersion,
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
        title: t.chooseVersion,
        width: 600,
        onClose: () => Navigator.pop(ctx),
        footer: [KButton(t.close, variant: KButtonVariant.ghost, onPressed: () => Navigator.pop(ctx))],
        children: [
          Text(t.chooseVersionBody, style: KText.bodySm.copyWith(color: K.textSecondary)),
          if (u.releases.isEmpty)
            MonoLabel(u.state == UpdateState.checking ? t.askingGithub : (u.error ?? t.noReleases))
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
                    if (isCurrent) KTag(t.installed, tone: TagTone.accent, height: 20),
                    if (isLatest && !isCurrent) KTag(t.latest, tone: TagTone.info, height: 20),
                    if (date.isNotEmpty) MonoLabel(date),
                  ],
                ),
                const SizedBox(height: 6),
                FutureBuilder<Compat?>(
                  future: u.compatOf(r),
                  builder: (_, snap) {
                    if (snap.connectionState != ConnectionState.done) return MonoLabel(t.checkingShort);
                    final bad = snap.data?.incompatible(d.devices);
                    final text = bad == null
                        ? t.compatUnknown
                        : bad.isEmpty
                        ? (d.devices.any((x) => x.lib != null) ? t.worksWithDevices : t.noDevicesToCheck)
                        : t.notFor(bad.map((b) => b.device.name).join(', '));
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
                why == null ? (compareVersions(r.version, u.current) < 0 ? t.install : t.update) : t.details,
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
  'android' => t.updateHowAndroid,
  _ => t.updateHow,
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
        title: t.versionN(appVersion),
        desc: t.noSelfUpdate,
        child: KButton(
          t.releases,
          size: KSize.sm,
          variant: KButtonVariant.ghost,
          iconRight: const KIcon('arrow-up-right', size: 14),
          onPressed: () => launchUrl(Uri.parse('$repoUrl/releases')),
        ),
      );
    }
    final busyWith = u.installing?.version ?? u.available?.version;
    final status = switch (u.state) {
      UpdateState.checking => t.checkingShort,
      UpdateState.upToDate => t.upToDate,
      UpdateState.available => t.versionAvailable(u.available!.version),
      UpdateState.downloading => t.downloadingWhat('$busyWith', (u.progress * 100).round()),
      UpdateState.installing => t.installingWhat('$busyWith'),
      UpdateState.failed => u.error ?? t.somethingWrong,
      UpdateState.idle => t.notChecked,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SetRow(
          phone: phone,
          title: t.versionN(appVersion),
          desc: status,
          child: u.available != null && u.state != UpdateState.checking
              ? KButton(
                  t.updateTo(u.available!.version),
                  size: KSize.sm,
                  iconLeft: const KIcon('download', size: 14),
                  onPressed: () => showUpdateDialog(context, d),
                )
              : KButton(t.checkNow, size: KSize.sm, variant: KButtonVariant.secondary, onPressed: u.state == UpdateState.checking ? null : u.check),
        ),
        SetRow(
          phone: phone,
          title: t.chooseVersion,
          desc: t.chooseVersionDesc,
          child: KButton(t.versions, size: KSize.sm, variant: KButtonVariant.secondary, onPressed: () => showVersionPicker(context, d)),
        ),
        SetRow(
          phone: phone,
          title: t.betas,
          desc: t.betasDesc,
          child: KSwitch(checked: u.betas, onChanged: u.setBetas),
        ),
        SetRow(
          phone: phone,
          title: t.autoCheck,
          desc: t.autoCheckDesc,
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
