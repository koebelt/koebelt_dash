import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

import '../core/model.dart';
import 'mjpeg.dart';

/// One camera stream, shared by every widget that shows it. Small cameras
/// (ESP32-CAM) serve a single client, so the app opens one connection per
/// stream and only while something on screen shows it.
class VideoFeed extends ChangeNotifier {
  VideoFeed(this.stream, this.url);
  final VideoStream stream;

  /// Resolved URL, or null when the stream cannot be reached on this link.
  final Uri? url;

  ui.Image? image;
  String status = 'Idle';
  double fps = 0;

  /// Kilobytes per second received.
  double kBps = 0;

  /// When the last frame arrived.
  DateTime? lastFrame;

  MjpegClient? _client;
  StreamSubscription? _fs, _ss;
  Timer? _stats;
  int _users = 0, _count = 0;
  bool _decoding = false;
  Uint8List? _pending;

  bool get live => image != null && lastFrame != null && DateTime.now().difference(lastFrame!) < const Duration(seconds: 2);

  void acquire() {
    if (_users++ == 0) _start();
  }

  void release() {
    if (--_users == 0) _stop();
  }

  void _start() {
    final u = url;
    if (u == null) return;
    final c = _client = MjpegClient(u, snapshot: stream.fmt == 'jpeg');
    _fs = c.frames.listen(_frame);
    _ss = c.status.listen((s) {
      status = s;
      notifyListeners();
    });
    _stats = Timer.periodic(const Duration(seconds: 1), (_) {
      fps = _count.toDouble();
      _count = 0;
      kBps = c.takeBytes() / 1000;
      notifyListeners();
    });
    c.start();
  }

  void _stop() {
    _fs?.cancel();
    _ss?.cancel();
    _stats?.cancel();
    unawaited(_client?.close());
    _client = null;
    status = 'Idle';
  }

  /// Decodes at most one frame at a time and drops the backlog, so a slow
  /// device never builds up latency.
  void _frame(Uint8List bytes) {
    if (_decoding) {
      _pending = bytes;
      return;
    }
    _decode(bytes);
  }

  Future<void> _decode(Uint8List bytes) async {
    _decoding = true;
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final f = await codec.getNextFrame();
      codec.dispose();
      if (_client == null) {
        f.image.dispose();
      } else {
        image?.dispose();
        image = f.image;
        lastFrame = DateTime.now();
        _count++;
        if (status != 'Live') status = 'Live';
        notifyListeners();
      }
    } catch (_) {
      // corrupt frame: skip it
    } finally {
      _decoding = false;
      final p = _pending;
      _pending = null;
      if (p != null && _client != null) unawaited(_decode(p));
    }
  }

  /// Stops for good (the device disconnected).
  void shutdown() {
    _stop();
    _users = -1 << 30; // never restart
    image = null;
    status = 'Disconnected';
    notifyListeners();
  }

  @override
  void dispose() {
    _stop();
    image?.dispose();
    image = null;
    super.dispose();
  }
}

/// Resolves a declared stream URL against the device address. Devices on
/// Wi-Fi may declare `:81/stream` (port and path only) because they do not
/// know the address the app reached them on.
Uri? resolveVideoUrl(String url, DeviceInfo? device) {
  if (url.startsWith('http://') || url.startsWith('https://')) return Uri.tryParse(url);
  if (url.startsWith(':') || url.startsWith('/')) {
    if (device == null || device.transport != TransportKind.udp) return null;
    final host = device.address.split(':').first;
    return Uri.tryParse('http://$host$url');
  }
  return null;
}

/// Feeds for the connected device's streams.
class VideoHub {
  final Map<String, VideoFeed> _feeds = {};

  VideoFeed feed(VideoStream s, DeviceInfo? device) => _feeds.putIfAbsent('${device?.id}|${s.id}|${s.url}', () => VideoFeed(s, resolveVideoUrl(s.url, device)));

  /// Closes every connection. Feeds are not disposed: widgets still holding
  /// one release it normally when they go away.
  void clear() {
    for (final f in _feeds.values) {
      f.shutdown();
    }
    _feeds.clear();
  }
}
