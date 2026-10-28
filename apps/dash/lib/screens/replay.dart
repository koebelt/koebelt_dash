import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/dash.dart';
import '../core/model.dart';
import '../ui/icons.dart';
import '../video/recorded_video.dart';
import 'export_dialog.dart';
import 'import_dialog.dart';
import '../theme/tokens.dart';
import '../ui/components.dart';
import '../viz/map_view.dart';
import '../viz/scene3d.dart';
import 'tiles.dart';

class ReplayScreen extends StatelessWidget {
  const ReplayScreen(this.d, {super.key, required this.w, required this.h});
  final Dash d;
  final double w, h;

  Widget _list(BuildContext context) {
    final R = d.replay;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Builder(
              builder: (_) {
                final n = sessionEntries(d.sessions).length;
                return Expanded(child: MonoLabel('$n ${n == 1 ? 'session' : 'sessions'}', maxLines: 1));
              },
            ),
            KButton(
              'Import',
              size: KSize.sm,
              variant: KButtonVariant.ghost,
              iconLeft: const KIcon('upload', size: 14),
              onPressed: () => showImportDialog(context, d),
            ),
            const SizedBox(width: 8),
            d.recording
                ? KButton(
                    'Stop · ${mmss(d.t - d.recStart)}',
                    size: KSize.sm,
                    variant: KButtonVariant.secondary,
                    iconLeft: const PulseDot(),
                    onPressed: d.stopRec,
                  )
                : KButton(
                    'Record',
                    size: KSize.sm,
                    variant: KButtonVariant.secondary,
                    iconLeft: const PulseDot(animate: false),
                    onPressed: R != null || !d.hasDevice ? null : d.startRec,
                  ),
          ],
        ),
        const SizedBox(height: 16),
        hairline,
        if (d.sessions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'No recordings yet. Record a connected device, or use Import for a file or the sample recordings.',
              style: KText.bodySm.copyWith(color: K.textMuted),
            ),
          ),
        for (final e in sessionEntries(d.sessions))
          if (e.length == 1) _rec(context, e.first) else _group(context, e),
      ],
    );
  }

  static Widget _tag(Widget t) => Padding(padding: const EdgeInsets.only(left: 8), child: t);

  /// A session recorded with several devices: one header, the devices below.
  Widget _group(BuildContext context, List<Recording> recs) {
    final first = recs.first, title = groupTitle(first);
    final dur = recs.map((r) => r.dur).reduce(math.max);
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: K.borderHairline)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 14, 4, 6),
            child: Row(
              children: [
                const KIcon('layers', size: 16, color: K.textSecondary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          text: title,
                          style: KText.bodyMd,
                          children: [
                            if (recs.any((r) => r.fresh))
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: _tag(const KTag('New', tone: TagTone.accent, height: 20)),
                              ),
                            if (recs.any((r) => r.hasVideo))
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: _tag(const KTag('Video', tone: TagTone.info, height: 20)),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      MonoLabel('${recs.length} devices · ${first.date} · ${mmss(dur)}'),
                    ],
                  ),
                ),
                KIconButton(
                  'trash',
                  label: 'Delete $title',
                  size: KSize.sm,
                  variant: KIconButtonVariant.bare,
                  onPressed: () => confirmDeleteGroup(context, d, recs),
                ),
              ],
            ),
          ),
          for (final r in recs) _rec(context, r, inGroup: true),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  /// One recording; inside a group it is named by its device and indented.
  Widget _rec(BuildContext context, Recording s, {bool inGroup = false}) => Pressable(
    onTap: () => d.openReplay(s.id),
    builder: (_, hover, _) {
      final on = d.replay?.session.id == s.id;
      return Container(
        margin: EdgeInsets.only(left: inGroup ? 20 : 0),
        padding: EdgeInsets.fromLTRB(12, inGroup ? 10 : 14, 4, inGroup ? 10 : 14),
        decoration: BoxDecoration(
          color: on || hover ? K.surfaceHover : Colors.transparent,
          border: Border(
            bottom: inGroup ? BorderSide.none : const BorderSide(color: K.borderHairline),
            left: BorderSide(color: on ? K.accent : (inGroup ? K.borderSubtle : Colors.transparent), width: 2),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges sit right after the title; the right edge is for actions.
                  Text.rich(
                    TextSpan(
                      text: inGroup ? s.deviceName : s.name,
                      style: inGroup ? KText.bodySm : KText.bodyMd,
                      children: [
                        if (s.fresh && !inGroup)
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: _tag(const KTag('New', tone: TagTone.accent, height: 20)),
                          ),
                        if (s.hasVideo)
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: _tag(const KTag('Video', tone: TagTone.info, height: 20)),
                          ),
                        if (s.demo)
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: _tag(const SimTag(text: 'Demo', height: 20)),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: inGroup ? 6 : 8),
                  MonoLabel(inGroup ? '${s.kind.label} · ${mmss(s.dur)}' : '${s.deviceName} · ${s.date} · ${mmss(s.dur)}'),
                ],
              ),
            ),
            KIconButton('download', label: 'Export ${s.name}', size: KSize.sm, variant: KIconButtonVariant.bare, onPressed: () => showExportDialog(context, s)),
            if (!s.demo)
              KIconButton(
                'trash',
                label: 'Delete ${s.name}',
                size: KSize.sm,
                variant: KIconButtonVariant.bare,
                onPressed: () => confirmDeleteRecording(context, d, s),
              ),
          ],
        ),
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final R = d.replay, phone = w < 600, wide = w >= 900;
    if (R == null) {
      return SingleChildScrollView(
        padding: phone ? const EdgeInsets.all(16) : const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHead(phone: phone, eyebrow: 'Recording and playback', title: 'Sessions'),
              SizedBox(height: phone ? 20 : 32),
              _list(context),
            ],
          ),
        ),
      );
    }
    // What the player can show: 3D always, a map with GPS, the camera when recorded.
    final views = ['3d', if (R.session.frames.any((f) => (f['lat'] as num? ?? 0) != 0)) 'map', if (R.session.hasVideo) 'video'];
    final view = views.contains(d.replayView) ? d.replayView : '3d';
    final ids = [
      ...switch (R.session.kind) {
        DeviceKind.arm => ['joints', 'power'],
        DeviceKind.bench => ['thrust', 'rpm'],
        DeviceKind.rover => ['gyro', 'power'],
        _ => ['accel', 'alt'],
      },
      // What scripts showed while recording.
      for (final v in d.scriptViews.values) v.tileId,
    ];
    // A short screen (a small phone, a phone sideways, a low window): the
    // player keeps a usable height and the page scrolls to the charts.
    final short = h < 640;
    Widget scene(Widget c) => short ? SizedBox(height: (h * .6).clamp(200.0, 360.0), child: c) : Expanded(child: c);
    Widget player = Column(
      children: [
        scene(
          Container(
            color: K.surfaceDeep,
            child: Stack(
              children: [
                Positioned.fill(
                  child: switch (view) {
                    'video' => RecordedVideo(d),
                    'map' => MapView(d),
                    _ => Scene3D(d, view: 'orbit'),
                  },
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  // On a phone the controls wrap below the title instead of overflowing.
                  child: phone
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            KBadge('Replay · ${R.session.name}', tone: Tone.info),
                            const SizedBox(height: 8),
                            Wrap(
                              runSpacing: 8,
                              children: [
                                // The other devices recorded in the same session, at the same moment.
                                if (R.session.group != null)
                                  Builder(
                                    builder: (_) {
                                      final mates = sessionEntries(d.sessions).firstWhere((e) => e.contains(R.session), orElse: () => [R.session]);
                                      if (mates.length < 2) return const SizedBox();
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 8),
                                        child: Container(
                                          color: K.inkA60,
                                          child: Seg(
                                            items: [for (final m in mates) m.deviceName.toUpperCase()],
                                            value: R.session.deviceName.toUpperCase(),
                                            small: true,
                                            onChanged: (v) => d.showCompanion(mates.firstWhere((m) => m.deviceName.toUpperCase() == v).id),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                if (views.length > 1) ...[
                                  Container(
                                    color: K.inkA60,
                                    child: Seg(
                                      items: [for (final v in views) v.toUpperCase()],
                                      value: view.toUpperCase(),
                                      small: true,
                                      onChanged: (v) {
                                        d.replayView = v.toLowerCase();
                                        d.emit();
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Container(
                                  color: K.inkA60,
                                  child: KButton(
                                    'Export',
                                    size: KSize.sm,
                                    variant: KButtonVariant.secondary,
                                    iconLeft: const KIcon('download', size: 14),
                                    onPressed: () => showExportDialog(context, R.session),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  color: K.inkA60,
                                  child: KButton('Exit to live', size: KSize.sm, variant: KButtonVariant.secondary, onPressed: d.closeReplay),
                                ),
                              ],
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(child: KBadge('Replay · ${R.session.name}', tone: Tone.info)),
                            // The other devices recorded in the same session, at the same moment.
                            if (R.session.group != null)
                              Builder(
                                builder: (_) {
                                  final mates = sessionEntries(d.sessions).firstWhere((e) => e.contains(R.session), orElse: () => [R.session]);
                                  if (mates.length < 2) return const SizedBox();
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Container(
                                      color: K.inkA60,
                                      child: Seg(
                                        items: [for (final m in mates) m.deviceName.toUpperCase()],
                                        value: R.session.deviceName.toUpperCase(),
                                        small: true,
                                        onChanged: (v) => d.showCompanion(mates.firstWhere((m) => m.deviceName.toUpperCase() == v).id),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            if (views.length > 1) ...[
                              Container(
                                color: K.inkA60,
                                child: Seg(
                                  items: [for (final v in views) v.toUpperCase()],
                                  value: view.toUpperCase(),
                                  small: true,
                                  onChanged: (v) {
                                    d.replayView = v.toLowerCase();
                                    d.emit();
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Container(
                              color: K.inkA60,
                              child: KButton(
                                'Export',
                                size: KSize.sm,
                                variant: KButtonVariant.secondary,
                                iconLeft: const KIcon('download', size: 14),
                                onPressed: () => showExportDialog(context, R.session),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              color: K.inkA60,
                              child: KButton('Exit to live', size: KSize.sm, variant: KButtonVariant.secondary, onPressed: d.closeReplay),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.all(phone ? 16 : 20),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: K.borderHairline)),
          ),
          child: Column(
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  KIconButton(
                    R.playing ? 'pause' : 'play',
                    label: R.playing ? 'Pause' : 'Play',
                    variant: KIconButtonVariant.solid,
                    size: KSize.lg,
                    onPressed: () {
                      if (!R.playing && R.t >= R.dur) R.t = 0;
                      R.playing = !R.playing;
                      d.emit();
                    },
                  ),
                  SizedBox(
                    width: math.max(200, (wide ? w - 320 : w) - (phone ? 32 : 40) - 48 - 150 - 24),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 44,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(mmss(R.t), style: KText.mono(12)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _EventMarks(d, R),
                              KSlider(value: R.t, min: 0, max: math.max(.1, R.dur), onChanged: d.seekReplay),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 44,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(mmss(R.dur), style: KText.mono(12, color: K.textMuted)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Seg(
                    small: true,
                    items: const ['1×', '2×', '4×'],
                    value: '${R.speed.round()}×',
                    onChanged: (v) {
                      R.speed = double.parse(v.replaceAll('×', ''));
                      d.emit();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              phone
                  ? Column(
                      children: [for (final id in ids) Padding(padding: const EdgeInsets.only(bottom: 12), child: Tile(d, tileById(d, id)!, height: 90))],
                    )
                  : Row(
                      children: [
                        for (var i = 0; i < ids.length; i++) ...[
                          if (i > 0) const SizedBox(width: 12),
                          Expanded(child: Tile(d, tileById(d, ids[i])!, height: 110)),
                        ],
                      ],
                    ),
            ],
          ),
        ),
      ],
    );
    if (short) player = SingleChildScrollView(child: player);
    if (wide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 320,
            decoration: const BoxDecoration(
              border: Border(right: BorderSide(color: K.borderHairline)),
            ),
            child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: _list(context)),
          ),
          Expanded(child: player),
        ],
      );
    }
    return player;
  }
}

/// Asks before deleting a recording; offers to export it first.
void confirmDeleteRecording(BuildContext context, Dash d, Recording s) {
  showKDialog(
    context,
    builder: (ctx) => KDialogPanel(
      title: 'Delete ${s.name}?',
      width: 440,
      onClose: () => Navigator.pop(ctx),
      footer: [
        KButton('Cancel', variant: KButtonVariant.ghost, onPressed: () => Navigator.pop(ctx)),
        KButton(
          'Export first',
          variant: KButtonVariant.secondary,
          onPressed: () {
            Navigator.pop(ctx);
            showExportDialog(context, s);
          },
        ),
        KButton(
          'Delete',
          variant: KButtonVariant.inverse,
          onPressed: () {
            Navigator.pop(ctx);
            d.deleteRecording(s.id);
          },
        ),
      ],
      children: [
        MonoLabel('${s.deviceName} · ${s.date} · ${mmss(s.dur)}', height: 1.5),
        const Text('The recording is removed from this device. This cannot be undone.'),
      ],
    ),
  );
}

/// Sessions in list order: a recording on its own, or every recording of a
/// multi-device session together, where its newest one is.
List<List<Recording>> sessionEntries(List<Recording> sessions) {
  final out = <List<Recording>>[], groups = <String, List<Recording>>{};
  for (final r in sessions) {
    final g = r.group;
    if (g == null) {
      out.add([r]);
    } else if (groups[g] case final l?) {
      l.add(r);
    } else {
      out.add(groups[g] = [r]);
    }
  }
  for (final l in groups.values) {
    l.sort((a, b) => a.deviceName.compareTo(b.deviceName));
  }
  return out;
}

/// "Session 4" from "Session 4 · Kite".
String groupTitle(Recording r) {
  final suffix = ' · ${r.deviceName}';
  return r.name.endsWith(suffix) ? r.name.substring(0, r.name.length - suffix.length) : r.name;
}

/// Asks before deleting a multi-device session and all its recordings.
void confirmDeleteGroup(BuildContext context, Dash d, List<Recording> recs) {
  final title = groupTitle(recs.first);
  showKDialog(
    context,
    builder: (ctx) => KDialogPanel(
      title: 'Delete $title?',
      width: 440,
      onClose: () => Navigator.pop(ctx),
      footer: [
        KButton('Cancel', variant: KButtonVariant.ghost, onPressed: () => Navigator.pop(ctx)),
        KButton(
          'Delete all ${recs.length}',
          variant: KButtonVariant.inverse,
          onPressed: () {
            Navigator.pop(ctx);
            for (final r in recs.where((r) => !r.demo)) {
              d.deleteRecording(r.id);
            }
          },
        ),
      ],
      children: [
        MonoLabel('${recs.map((r) => r.deviceName).join(', ')} · ${recs.first.date}', height: 1.5),
        const Text('Every device\'s recording of this session is removed from this device, with its video. This cannot be undone.'),
      ],
    ),
  );
}

/// Alerts, link losses and STOP over the replay timeline, aligned with the
/// slider's track. Hover for what happened; tap to jump there. In a
/// multi-device session, the other devices' events carry their name.
class _EventMarks extends StatelessWidget {
  const _EventMarks(this.d, this.r);
  final Dash d;
  final Replay r;

  @override
  Widget build(BuildContext context) {
    final events = [
      for (final e in r.session.events) (e, ''),
      for (final m in r.mates)
        for (final e in m.rec.events) (e, '${m.rec.deviceName} · '),
    ];
    if (events.isEmpty) return const SizedBox(height: 4);
    final dur = math.max(.1, r.dur);
    return SizedBox(
      height: 14,
      child: LayoutBuilder(
        builder: (_, c) {
          // RectangularSliderTrackShape leaves half the 14 px thumb at each end.
          final w = c.maxWidth - 14;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              for (final (e, who) in events)
                Positioned(
                  left: 7 + (e.t / dur).clamp(0.0, 1.0) * w - 6,
                  top: 0,
                  child: Tooltip(
                    message: '$who${e.text} · ${mmss(e.t)}',
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => d.seekReplay(e.t),
                      child: SizedBox(
                        width: 12,
                        height: 14,
                        child: Center(
                          child: Container(
                            width: 3,
                            height: who.isEmpty ? 12 : 8,
                            decoration: BoxDecoration(
                              color: e.kind == 'restored' ? K.positive : (e.critical ? K.negative : K.warning),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
