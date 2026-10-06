import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../core/dash.dart';
import '../core/export.dart';
import '../core/save_io.dart';
import '../theme/tokens.dart';
import '../ui/components.dart';
import '../ui/mark.dart';
import '../video/video_rec.dart';

void showExportDialog(BuildContext context, Recording r) {
  showKDialog(context, builder: (ctx) => _ExportDialog(r: r));
}

class _ExportDialog extends StatefulWidget {
  const _ExportDialog({required this.r});
  final Recording r;
  @override
  State<_ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<_ExportDialog> {
  ExportFormat format = ExportFormat.csv;
  bool busy = false;
  double progress = 0;
  String? done, error;

  Future<void> _export() async {
    setState(() {
      busy = true;
      progress = 0;
      error = null;
      done = null;
    });
    try {
      void onProgress(double p) {
        if (mounted) setState(() => progress = p);
      }

      final Uint8List bytes;
      if (format == ExportFormat.video) {
        final t = await VideoTrack.open(widget.r.videoPath!);
        if (t == null) throw StateError('The video file is missing');
        try {
          bytes = await mjpegAvi(t, onProgress: onProgress);
        } finally {
          await t.close();
        }
      } else {
        bytes = utf8.encode(await exportRecordingAsync(widget.r, format, onProgress: onProgress));
      }
      final where = await saveBytes(exportFileName(widget.r, format), bytes, format.mime);
      setState(() => done = where);
    } catch (e) {
      setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.r, formats = formatsFor(r);
    final cols = format == ExportFormat.csv ? toCsv(r).split('\n')[1].split(',').length : null;
    return KDialogPanel(
      title: 'Export ${r.name}',
      width: 480,
      onClose: () => Navigator.pop(context),
      footer: [
        KButton(done != null ? 'Close' : 'Cancel', variant: KButtonVariant.ghost, onPressed: () => Navigator.pop(context)),
        KButton(busy ? 'Exporting…' : 'Export ${format.label}', onPressed: busy ? null : _export),
      ],
      children: [
        MonoLabel('${r.deviceName} · ${r.date} · ${mmss(r.dur)} · ${r.frames.length} frames'),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            hairline,
            for (final f in formats)
              Pressable(
                onTap: () => setState(() {
                  format = f;
                  done = null;
                }),
                builder: (_, h, _) => Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: K.borderHairline)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        margin: const EdgeInsets.only(top: 2, right: 12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: f == format ? K.accent : K.borderSubtle, width: f == format ? 5 : 1),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(f.label, style: KText.bodyMd.copyWith(color: h || f == format ? K.textPrimary : K.textSecondary)),
                            const SizedBox(height: 4),
                            Text(f.desc, style: KText.bodySm.copyWith(color: K.textMuted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        if (cols != null) MonoLabel('$cols columns · only channels this device sent', height: 1.5),
        if (!formats.contains(ExportFormat.gpx)) const MonoLabel('No GPS in this recording, so no GPX track', height: 1.5),
        if (busy)
          Row(
            children: [
              MarkMotion(MarkLoop.progress, size: 44, progress: progress, gap: K.surfaceRaised),
              const SizedBox(width: 12),
              MonoLabel('Encoding ${format.label} · ${(progress * 100).round()}%'),
            ],
          ),
        if (done != null) KNotice(tone: Tone.positive, title: 'Exported', child: Text(done!)),
        if (error != null) KNotice(tone: Tone.negative, title: 'Export failed', child: Text(error!)),
      ],
    );
  }
}
