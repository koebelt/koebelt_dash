import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../core/dash.dart';
import '../core/log_import.dart';
import '../core/save_io.dart';
import '../theme/tokens.dart';
import '../ui/components.dart';
import '../ui/mark.dart';

/// Picks a log file and imports it as a recording, then plays it.
Future<void> importRecording(BuildContext context, Dash d) async {
  final f = await openBytes('Recordings and flight logs', importExtensions);
  if (f == null || !context.mounted) return;
  await showKDialog(
    context,
    builder: (_) => _ImportDialog(d: d, name: f.$1, bytes: f.$2),
  );
}

class _ImportDialog extends StatefulWidget {
  const _ImportDialog({required this.d, required this.name, required this.bytes});
  final Dash d;
  final String name;
  final Uint8List bytes;
  @override
  State<_ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends State<_ImportDialog> {
  String? error;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    try {
      final r = await widget.d.importLog(widget.name, widget.bytes);
      if (!mounted) return;
      widget.d.openReplay(r.id);
      Navigator.pop(context);
    } on LogImportError catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (e) {
      if (mounted) setState(() => error = 'The file could not be read: $e');
    }
  }

  @override
  Widget build(BuildContext context) => KDialogPanel(
    title: 'Import ${widget.name}',
    width: 440,
    onClose: () => Navigator.pop(context),
    footer: [if (error != null) KButton('Close', variant: KButtonVariant.ghost, onPressed: () => Navigator.pop(context))],
    children: [
      if (error == null)
        const Row(
          children: [
            MarkMotion(MarkLoop.loading, size: 28, gap: K.surfaceRaised),
            SizedBox(width: 12),
            MonoLabel('Reading the log…'),
          ],
        )
      else
        KNotice(tone: Tone.negative, title: 'Not imported', child: Text(error!)),
      const MonoLabel('koebelt/dash JSON exports · ArduPilot .bin and .tlog · PX4 .ulg', height: 1.5, maxLines: 2),
    ],
  );
}
