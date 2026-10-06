import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/dash.dart';
import '../theme/tokens.dart';
import '../ui/components.dart';
import 'video_rec.dart';

/// The camera recorded with the replayed session, at the replay time.
class RecordedVideo extends StatefulWidget {
  const RecordedVideo(this.d, {super.key, this.fit = BoxFit.contain, this.compact = false});
  final Dash d;
  final BoxFit fit;
  final bool compact;
  @override
  State<RecordedVideo> createState() => _RecordedVideoState();
}

class _RecordedVideoState extends State<RecordedVideo> {
  VideoTrack? _track;
  String? _for;
  ui.Image? _image;
  int _shown = -1, _wanted = -1;
  bool _loading = false, _missing = false;

  @override
  void initState() {
    super.initState();
    widget.d.frame.addListener(_tick);
    _tick();
  }

  @override
  void dispose() {
    widget.d.frame.removeListener(_tick);
    _image?.dispose();
    super.dispose();
  }

  void _tick() {
    final r = widget.d.replay;
    if (r == null) return;
    if (_for != r.session.id) {
      _for = r.session.id;
      _track = null;
      _shown = _wanted = -1;
      _missing = false;
      widget.d.replayVideo(r.session).then((t) {
        if (!mounted || _for != r.session.id) return;
        setState(() {
          _track = t;
          _missing = t == null || t.length == 0;
        });
      });
      return;
    }
    final t = _track;
    if (t == null) return;
    _wanted = t.frameAt(r.t);
    if (_wanted != _shown && !_loading) unawaited(_load());
  }

  /// One decode at a time; a seek while decoding jumps to the newest frame.
  Future<void> _load() async {
    final t = _track;
    if (t == null || _wanted < 0) return;
    _loading = true;
    final i = _wanted;
    try {
      final codec = await ui.instantiateImageCodec(await t.jpeg(i));
      final f = await codec.getNextFrame();
      codec.dispose();
      if (!mounted) {
        f.image.dispose();
        return;
      }
      setState(() {
        _image?.dispose();
        _image = f.image;
        _shown = i;
      });
    } catch (_) {
      _shown = i; // skip a corrupt frame
    } finally {
      _loading = false;
      if (mounted && _wanted != _shown) unawaited(_load());
    }
  }

  @override
  Widget build(BuildContext context) {
    final img = _image;
    return ColoredBox(
      color: const Color(0xFF050505),
      child: img != null
          ? SizedBox.expand(
              child: RawImage(image: img, fit: widget.fit),
            )
          : Center(
              child: MonoLabel(_missing ? 'No video in this recording' : 'Loading video', color: K.textMuted, size: widget.compact ? 10 : 11),
            ),
    );
  }
}
