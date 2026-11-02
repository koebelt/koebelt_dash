import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../core/dash.dart';
import '../core/log_import.dart';
import '../core/save_io.dart';
import '../theme/tokens.dart';
import '../ui/components.dart';
import '../ui/icons.dart';
import '../ui/mark.dart';

/// Import on the Replay screen: a recording or flight log from a file, or
/// the sample recordings.
void showImportDialog(BuildContext context, Dash d) {
  showKDialog(context, builder: (_) => _ImportDialog(d: d));
}

class _ImportDialog extends StatefulWidget {
  const _ImportDialog({required this.d});
  final Dash d;
  @override
  State<_ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends State<_ImportDialog> {
  /// File being read, and the error if it could not be.
  String? reading, error;

  Future<void> _choose() async {
    final f = await openBytes(t.recordingsAndLogs, importExtensions);
    if (f == null || !mounted) return;
    setState(() {
      reading = f.$1;
      error = null;
    });
    try {
      final r = await widget.d.importLog(f.$1, f.$2);
      if (!mounted) return;
      widget.d.openReplay(r.id);
      Navigator.pop(context);
    } on LogImportError catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (e) {
      if (mounted) setState(() => error = t.fileUnreadable('$e'));
    } finally {
      if (mounted) setState(() => reading = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.d, busy = reading != null;
    Widget format(String ext, String what) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 64, child: MonoLabel(ext, color: K.textPrimary)),
          Expanded(
            child: Text(what, style: KText.bodySm.copyWith(color: K.textSecondary)),
          ),
        ],
      ),
    );
    return ListenableBuilder(
      listenable: d,
      builder: (context, _) => KDialogPanel(
        title: t.import,
        width: 480,
        onClose: () => Navigator.pop(context),
        footer: [KButton(t.close, variant: KButtonVariant.ghost, onPressed: () => Navigator.pop(context))],
        children: [
          MonoLabel(t.fromFile),
          Text(t.fromFileDesc, style: KText.bodySm.copyWith(color: K.textSecondary)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [format('.json', t.fmtJson), format('.bin', t.fmtBin), format('.tlog', t.fmtTlog), format('.ulg', t.fmtUlg)],
          ),
          if (busy)
            Row(
              children: [
                const MarkMotion(MarkLoop.loading, size: 28, gap: K.surfaceRaised),
                const SizedBox(width: 12),
                Expanded(child: MonoLabel(t.reading(reading!), maxLines: 1)),
              ],
            )
          else
            Align(
              alignment: Alignment.centerLeft,
              child: KButton('Choose file…', iconLeft: const KIcon('upload', size: 16), onPressed: d.recording ? null : _choose),
            ),
          if (d.recording) MonoLabel(t.stopRecordingFirst, height: 1.5),
          if (error != null) KNotice(tone: Tone.negative, title: t.notImported, child: Text(error!)),
          hairline,
          MonoLabel(t.sampleRecordings),
          Text(d.hasSamples ? t.samplesIn : t.samplesDesc, style: KText.bodySm.copyWith(color: K.textSecondary)),
          Align(
            alignment: Alignment.centerLeft,
            child: KButton(
              d.hasSamples ? t.removeSamples : t.loadSamples,
              variant: KButtonVariant.secondary,
              iconLeft: KIcon(d.hasSamples ? 'trash' : 'replay', size: 16),
              onPressed: busy ? null : (d.hasSamples ? d.removeSamples : d.loadSamples),
            ),
          ),
        ],
      ),
    );
  }
}
