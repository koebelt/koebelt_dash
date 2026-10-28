import 'package:flutter/material.dart';

import '../core/dash.dart';
import '../core/model.dart';
import '../theme/tokens.dart';
import '../ui/components.dart';
import '../ui/mark.dart';
import 'recorded_video.dart';
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
    if (d.replay?.session.hasVideo ?? false) return RecordedVideo(d, fit: widget.fit, compact: widget.compact);
    String? msg;
    if (d.replay != null) {
      msg = 'This recording has no video.';
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
          if (img != null && d.replay == null) _ScriptBoxes(d, Size(img.width.toDouble(), img.height.toDouble()), widget.fit),
          if (msg != null)
            // A small tile: the message shrinks rather than overflowing.
            LayoutBuilder(
              builder: (_, c) => Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: SizedBox(
                    width: c.maxWidth,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (msg == 'Connecting…') ...[const MarkMotion(MarkLoop.loading, size: 48, gap: Color(0xFF050505)), const SizedBox(height: 10)],
                          Text(
                            msg!,
                            textAlign: TextAlign.center,
                            style: (small ? KText.label() : KText.bodySm).copyWith(color: K.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ),
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

/// What a script sees: the boxes it draws with dev.overlay(), for a second
/// after each update.
class _ScriptBoxes extends StatelessWidget {
  const _ScriptBoxes(this.d, this.image, this.fit);
  final Dash d;
  final Size image;
  final BoxFit fit;
  @override
  Widget build(BuildContext context) {
    final o = d.focus?.overlay;
    if (o == null || DateTime.now().difference(o.at) > const Duration(seconds: 1) || o.boxes.isEmpty) return const SizedBox.shrink();
    return IgnorePointer(child: CustomPaint(painter: _BoxPainter(o.boxes, image, fit)));
  }
}

class _BoxPainter extends CustomPainter {
  _BoxPainter(this.boxes, this.image, this.fit);
  final List<({double x, double y, double w, double h, String label})> boxes;
  final Size image;
  final BoxFit fit;
  @override
  void paint(Canvas canvas, Size size) {
    final fs = applyBoxFit(fit, image, size);
    final dst = Alignment.center.inscribe(fs.destination, Offset.zero & size);
    final src = Alignment.center.inscribe(fs.source, Offset.zero & image);
    final line = Paint()
      ..color = K.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final b in boxes) {
      // Normalised image coordinates → the part of the image on screen.
      Offset at(double x, double y) =>
          Offset(dst.left + (x * image.width - src.left) / src.width * dst.width, dst.top + (y * image.height - src.top) / src.height * dst.height);
      final r = Rect.fromPoints(at(b.x, b.y), at(b.x + b.w, b.y + b.h));
      canvas.drawRect(r, line);
      if (b.label.isEmpty) continue;
      final tp = TextPainter(
        text: TextSpan(
          text: b.label.toUpperCase(),
          style: KText.mono(10, color: K.textOnAccent),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final tag = Rect.fromLTWH(r.left - 1, r.top - tp.height - 4, tp.width + 8, tp.height + 4);
      canvas.drawRect(tag, Paint()..color = K.accent);
      tp.paint(canvas, tag.topLeft + const Offset(4, 2));
    }
  }

  @override
  bool shouldRepaint(_BoxPainter old) => old.boxes != boxes || old.image != image || old.fit != fit;
}
