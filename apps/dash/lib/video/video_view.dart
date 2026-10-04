import 'package:flutter/material.dart';

import '../core/dash.dart';
import '../core/model.dart';
import '../theme/tokens.dart';
import '../ui/components.dart';
import 'video_hub.dart';

/// Live picture from one of the device's cameras, with a small status line.
/// Several views of the same stream share one connection.
class VideoView extends StatefulWidget {
  const VideoView(this.d, {super.key, this.fit = BoxFit.contain, this.osd = true, this.compact = false});
  final Dash d;
  final BoxFit fit;
  final bool osd, compact;
  @override
  State<VideoView> createState() => _VideoViewState();
}

class _VideoViewState extends State<VideoView> {
  VideoFeed? _feed;
  int _index = 0;

  VideoStream? get _stream {
    final v = widget.d.video;
    if (v.isEmpty) return null;
    return v[_index.clamp(0, v.length - 1)];
  }

  @override
  void initState() {
    super.initState();
    widget.d.addListener(_sync);
    _sync();
  }

  /// Follows the device's declared streams (they change on reconnect).
  void _sync() {
    final s = _stream;
    final f = s == null ? null : widget.d.videoFeed(s);
    if (identical(f, _feed)) return;
    _feed?.removeListener(_changed);
    _feed?.release();
    _feed = f;
    f?.acquire();
    f?.addListener(_changed);
    if (mounted) setState(() {});
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.d.removeListener(_sync);
    _feed?.removeListener(_changed);
    _feed?.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.d, f = _feed, s = _stream;
    final img = f?.image;
    String? msg;
    if (d.replay != null) {
      msg = 'Video is not recorded. Replays show telemetry only.';
    } else if (s == null) {
      msg = d.hasDevice ? 'No camera. Devices declare cameras with video() in the library.' : 'Not connected';
    } else if (f!.url == null) {
      msg = 'This camera is reached by IP address. Connect to ${d.deviceName} over Wi-Fi to see it.';
    } else if (img == null || !f.live) {
      msg = f.status == 'Idle' || f.status == 'Live' ? 'Connecting…' : f.status;
    }
    final small = widget.compact;
    return ColoredBox(
      color: const Color(0xFF050505),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (img != null) RawImage(image: img, fit: widget.fit, filterQuality: FilterQuality.medium, opacity: AlwaysStoppedAnimation(f!.live ? 1 : .35)),
          if (msg != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (msg == 'Connecting…') ...[const ScanDot(), const SizedBox(height: 10)],
                    Text(
                      msg,
                      textAlign: TextAlign.center,
                      style: (small ? KText.label() : KText.bodySm).copyWith(color: K.textMuted),
                    ),
                  ],
                ),
              ),
            ),
          if (widget.osd && s != null && f != null)
            Positioned(
              left: 10,
              bottom: 10,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: K.inkA62, borderRadius: BorderRadius.circular(K.radiusControl)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PulseDot(color: f.live ? K.negative : K.ink300),
                      const SizedBox(width: 6),
                      MonoLabel(
                        [
                          (s.label.isEmpty ? s.id : s.label).toUpperCase(),
                          if (img != null && !small) '${img.width}×${img.height}',
                          if (f.live) '${f.fps.round()} FPS',
                          if (f.live && !small) f.kBps >= 1000 ? '${(f.kBps / 1000).toStringAsFixed(1)} MB/S' : '${f.kBps.round()} KB/S',
                        ].join(' · '),
                        color: K.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (d.video.length > 1 && !small)
            Positioned(
              right: 10,
              bottom: 10,
              child: Seg(
                small: true,
                items: [for (final v in d.video) (v.label.isEmpty ? v.id : v.label).toUpperCase()],
                value: (s!.label.isEmpty ? s.id : s.label).toUpperCase(),
                onChanged: (v) {
                  _index = d.video.indexWhere((x) => (x.label.isEmpty ? x.id : x.label).toUpperCase() == v);
                  _sync();
                },
              ),
            ),
        ],
      ),
    );
  }
}
