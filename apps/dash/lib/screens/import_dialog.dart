import 'package:flutter/material.dart';

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
    final f = await openBytes('Recordings and flight logs', importExtensions);
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
      if (mounted) setState(() => error = 'The file could not be read: $e');
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
        title: 'Import',
        width: 480,
        onClose: () => Navigator.pop(context),
        footer: [KButton('Close', variant: KButtonVariant.ghost, onPressed: () => Navigator.pop(context))],
        children: [
          const MonoLabel('From a file'),
          Text('Opens as a session: replay, the map, the charts and export all work on it.', style: KText.bodySm.copyWith(color: K.textSecondary)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              format('.json', 'A recording exported from koebelt/dash'),
              format('.bin', 'ArduPilot log, from the SD card or Mission Planner'),
              format('.tlog', 'Ground station log: Mission Planner, QGroundControl, MAVProxy'),
              format('.ulg', 'PX4 log, from the SD card or QGroundControl'),
            ],
          ),
          if (busy)
            Row(
              children: [
                const MarkMotion(MarkLoop.loading, size: 28, gap: K.surfaceRaised),
                const SizedBox(width: 12),
                Expanded(child: MonoLabel('Reading $reading…', maxLines: 1)),
              ],
            )
          else
            Align(
              alignment: Alignment.centerLeft,
              child: KButton('Choose file…', iconLeft: const KIcon('upload', size: 16), onPressed: d.recording ? null : _choose),
            ),
          if (d.recording) const MonoLabel('Stop the recording first', height: 1.5),
          if (error != null) KNotice(tone: Tone.negative, title: 'Not imported', child: Text(error!)),
          hairline,
          const MonoLabel('Sample recordings'),
          Text(
            d.hasSamples
                ? 'The three demo sessions are in your list, marked Demo.'
                : 'Three demo sessions recorded with the simulated devices: a survey flight, a pick and place, a rocket launch.',
            style: KText.bodySm.copyWith(color: K.textSecondary),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: KButton(
              d.hasSamples ? 'Remove samples' : 'Load samples',
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
