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
            Expanded(child: MonoLabel('${d.sessions.length} ${d.sessions.length == 1 ? 'session' : 'sessions'}', maxLines: 1)),
            KButton(
              'Import',
              size: KSize.sm,
              variant: KButtonVariant.ghost,
              iconLeft: const KIcon('upload', size: 14),
              onPressed: d.recording ? null : () => importRecording(context, d),
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
        for (final s in d.sessions)
          Pressable(
            onTap: () => d.openReplay(s.id),
            builder: (_, hover, _) {
              final on = R?.session.id == s.id;
              return Container(
                padding: const EdgeInsets.fromLTRB(12, 14, 4, 14),
                decoration: BoxDecoration(
                  color: on || hover ? K.surfaceHover : Colors.transparent,
                  border: Border(
                    bottom: const BorderSide(color: K.borderHairline),
                    left: BorderSide(color: on ? K.accent : Colors.transparent, width: 2),
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
                              text: s.name,
                              style: KText.bodyMd,
                              children: [
                                if (s.fresh)
                                  const WidgetSpan(
                                    alignment: PlaceholderAlignment.middle,
                                    child: Padding(
                                      padding: EdgeInsets.only(left: 8),
                                      child: KTag('New', tone: TagTone.accent, height: 20),
                                    ),
                                  ),
                                if (s.hasVideo)
                                  const WidgetSpan(
                                    alignment: PlaceholderAlignment.middle,
                                    child: Padding(
                                      padding: EdgeInsets.only(left: 8),
                                      child: KTag('Video', tone: TagTone.info, height: 20),
                                    ),
                                  ),
                                if (s.demo)
                                  const WidgetSpan(
                                    alignment: PlaceholderAlignment.middle,
                                    child: Padding(
                                      padding: EdgeInsets.only(left: 8),
                                      child: SimTag(text: 'Demo', height: 20),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          MonoLabel('${s.deviceName} · ${s.date} · ${mmss(s.dur)}'),
                        ],
                      ),
                    ),
                    KIconButton(
                      'download',
                      label: 'Export ${s.name}',
                      size: KSize.sm,
                      variant: KIconButtonVariant.bare,
                      onPressed: () => showExportDialog(context, s),
                    ),
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
          ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: KButton(
            d.hasSamples ? 'Remove sample recordings' : 'Load sample recordings',
            size: KSize.sm,
            variant: KButtonVariant.ghost,
            onPressed: d.hasSamples ? d.removeSamples : d.loadSamples,
          ),
        ),
      ],
    );
  }

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
    final ids = switch (R.session.kind) {
      DeviceKind.arm => ['joints', 'power'],
      DeviceKind.bench => ['thrust', 'rpm'],
      DeviceKind.rover => ['gyro', 'power'],
      _ => ['accel', 'alt'],
    };
    final player = Column(
      children: [
        Expanded(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: phone ? 240 : 300),
            child: Container(
              color: K.surfaceDeep,
              child: Stack(
                children: [
                  Positioned.fill(child: R.session.hasVideo && d.replayView == 'video' ? RecordedVideo(d) : Scene3D(d, view: 'orbit')),
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: Row(
                      children: [
                        Expanded(child: KBadge('Replay · ${R.session.name}', tone: Tone.info)),
                        if (R.session.hasVideo) ...[
                          Container(
                            color: K.inkA60,
                            child: Seg(
                              items: const ['3D', 'VIDEO'],
                              value: d.replayView == 'video' ? 'VIDEO' : '3D',
                              small: true,
                              onChanged: (v) {
                                d.replayView = v == 'VIDEO' ? 'video' : '3d';
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
                      if (!R.playing && R.t >= R.session.dur) R.t = 0;
                      R.playing = !R.playing;
                      d.emit();
                    },
                  ),
                  SizedBox(
                    width: math.max(200, (wide ? w - 320 : w) - (phone ? 32 : 40) - 48 - 150 - 24),
                    child: Row(
                      children: [
                        SizedBox(width: 44, child: Text(mmss(R.t), style: KText.mono(12))),
                        const SizedBox(width: 12),
                        Expanded(
                          child: KSlider(value: R.t, min: 0, max: math.max(.1, R.session.dur), onChanged: d.seekReplay),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 44,
                          child: Text(
                            mmss(R.session.dur),
                            textAlign: TextAlign.right,
                            style: KText.mono(12, color: K.textMuted),
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
