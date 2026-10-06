// Camera video recorded with a session. The device's MJPEG stream is already
// a sequence of JPEG frames, so recording keeps them as they arrive (capped
// at a frame rate) in a small file next to the recording:
//
//   "KDV1", then per frame: u32 time in ms from the recording start,
//   u32 length, the JPEG bytes (little-endian).
//
// Replays show the frame for the replay time; export writes an MJPEG AVI.
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

const _magic = [0x4B, 0x44, 0x56, 0x31]; // KDV1

/// Appends frames to a `.kdv` file while recording.
class VideoRecorder {
  VideoRecorder(this.path, {required this.clock, this.maxFps = 10});
  final String path;

  /// Seconds since the recording started (the telemetry frames' clock).
  final double Function() clock;
  final double maxFps;

  RandomAccessFile? _f;
  Future<void> _w = Future.value();
  double _last = -1;
  int frames = 0, bytes = 0;

  Future<void> open() async {
    final f = await File(path).open(mode: FileMode.write);
    await f.writeFrom(_magic);
    _f = f;
  }

  /// Keeps [jpeg] unless it comes sooner than the frame-rate cap allows.
  void add(Uint8List jpeg) {
    final f = _f;
    if (f == null || jpeg.length < 4) return;
    final t = clock();
    if (_last >= 0 && t - _last < .95 / maxFps) return;
    _last = t;
    frames++;
    bytes += jpeg.length;
    final head = ByteData(8)
      ..setUint32(0, (t * 1000).round(), Endian.little)
      ..setUint32(4, jpeg.length, Endian.little);
    _w = _w.then((_) => f.writeFrom(head.buffer.asUint8List())).then((_) => f.writeFrom(jpeg));
  }

  /// Flushes and closes; returns the number of frames kept.
  Future<int> close() async {
    final f = _f;
    _f = null;
    if (f == null) return frames;
    await _w;
    await f.close();
    return frames;
  }
}

/// A recorded video, opened for playback and export.
class VideoTrack {
  VideoTrack._(this._file, this.times, this._offsets, this._lengths);
  final RandomAccessFile _file;

  /// Frame times in seconds from the recording start.
  final List<double> times;
  final List<int> _offsets, _lengths;
  Future<void> _r = Future.value();

  int get length => times.length;
  double get duration => times.isEmpty ? 0 : times.last;

  /// Reads the index; null when the file is missing or not a video track.
  static Future<VideoTrack?> open(String path) async {
    final file = File(path);
    if (!await file.exists()) return null;
    final f = await file.open();
    try {
      final len = await f.length();
      final magic = await f.read(4);
      if (magic.length < 4 || !List.generate(4, (i) => magic[i] == _magic[i]).every((x) => x)) {
        await f.close();
        return null;
      }
      final times = <double>[], offs = <int>[], lens = <int>[];
      var pos = 4;
      while (pos + 8 <= len) {
        await f.setPosition(pos);
        final h = ByteData.sublistView(await f.read(8));
        final t = h.getUint32(0, Endian.little), n = h.getUint32(4, Endian.little);
        if (pos + 8 + n > len) break; // cut short (app quit while recording)
        times.add(t / 1000);
        offs.add(pos + 8);
        lens.add(n);
        pos += 8 + n;
      }
      return VideoTrack._(f, times, offs, lens);
    } catch (_) {
      await f.close();
      return null;
    }
  }

  /// The last frame at or before [t] seconds (the first before it starts).
  int frameAt(double t) {
    var lo = 0, hi = times.length - 1;
    if (hi < 0) return -1;
    while (lo < hi) {
      final mid = (lo + hi + 1) >> 1;
      if (times[mid] <= t) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    return lo;
  }

  /// JPEG bytes of frame [i]. Reads are queued, so callers may overlap.
  Future<Uint8List> jpeg(int i) {
    final c = Completer<Uint8List>();
    _r = _r.then((_) async {
      try {
        await _file.setPosition(_offsets[i]);
        c.complete(await _file.read(_lengths[i]));
      } catch (e) {
        c.completeError(e);
      }
    });
    return c.future;
  }

  Future<void> close() => _r.then((_) => _file.close());
}

bool isPng(Uint8List b) => b.length > 24 && b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4E && b[3] == 0x47;

/// Width and height of a JPEG (start-of-frame marker) or PNG (IHDR) frame.
(int, int)? frameSize(Uint8List b) {
  if (isPng(b)) return (b[16] << 24 | b[17] << 16 | b[18] << 8 | b[19], b[20] << 24 | b[21] << 16 | b[22] << 8 | b[23]);
  var i = 2;
  while (i + 9 < b.length) {
    if (b[i] != 0xFF) return null;
    final m = b[i + 1], len = b[i + 2] << 8 | b[i + 3];
    if (m >= 0xC0 && m <= 0xCF && m != 0xC4 && m != 0xC8 && m != 0xCC) {
      return (b[i + 7] << 8 | b[i + 8], b[i + 5] << 8 | b[i + 6]);
    }
    i += 2 + len;
  }
  return null;
}

/// The track as an MJPEG AVI (plays in VLC, ffmpeg, editors that take
/// MJPEG). Cameras send JPEG; the simulator's PNG frames become a PNG AVI.
/// AVI has one frame rate, so it uses the track's average; [onProgress]
/// gets 0…1.
Future<Uint8List> mjpegAvi(VideoTrack t, {void Function(double)? onProgress}) async {
  final n = t.length;
  if (n == 0) throw StateError('The video has no frames');
  final fps = n > 1 && t.duration > 0 ? (n - 1) / t.duration : 10.0;
  final first = await t.jpeg(0);
  final (w, h) = frameSize(first) ?? (640, 480);
  final codec = _fourcc(isPng(first) ? 'MPNG' : 'MJPG');

  final movi = BytesBuilder(copy: false);
  final idx = BytesBuilder(copy: false);
  var maxFrame = 0;
  for (var i = 0; i < n; i++) {
    final j = i == 0 ? first : await t.jpeg(i);
    if (j.length > maxFrame) maxFrame = j.length;
    final pad = j.length.isOdd ? 1 : 0;
    final offset = 4 + movi.length; // from the 'movi' fourcc
    movi
      ..add(_fourcc('00dc'))
      ..add(_u32(j.length))
      ..add(j);
    if (pad == 1) movi.addByte(0);
    idx
      ..add(_fourcc('00dc'))
      ..add(_u32(0x10)) // keyframe
      ..add(_u32(offset))
      ..add(_u32(j.length));
    if (i % 20 == 0) {
      onProgress?.call(i / n);
      await Future<void>.delayed(Duration.zero);
    }
  }
  final usPerFrame = (1e6 / fps).round(), rate = (fps * 1000).round();

  final avih = BytesBuilder()
    ..add(_u32(usPerFrame))
    ..add(_u32((maxFrame * fps).round()))
    ..add(_u32(0))
    ..add(_u32(0x10)) // AVIF_HASINDEX
    ..add(_u32(n))
    ..add(_u32(0))
    ..add(_u32(1))
    ..add(_u32(maxFrame))
    ..add(_u32(w))
    ..add(_u32(h))
    ..add(Uint8List(16));
  final strh = BytesBuilder()
    ..add(_fourcc('vids'))
    ..add(codec)
    ..add(_u32(0))
    ..add(Uint8List(4)) // priority, language
    ..add(_u32(0))
    ..add(_u32(1000)) // scale
    ..add(_u32(rate)) // rate / scale = fps
    ..add(_u32(0))
    ..add(_u32(n))
    ..add(_u32(maxFrame))
    ..add(_u32(0xFFFFFFFF))
    ..add(_u32(0))
    ..add(_u16(0))
    ..add(_u16(0))
    ..add(_u16(w))
    ..add(_u16(h));
  final strf = BytesBuilder()
    ..add(_u32(40))
    ..add(_u32(w))
    ..add(_u32(h))
    ..add(_u16(1))
    ..add(_u16(24))
    ..add(codec)
    ..add(_u32(w * h * 3))
    ..add(Uint8List(16));

  final strl = _list('strl', [_chunk('strh', strh.takeBytes()), _chunk('strf', strf.takeBytes())]);
  final hdrl = _list('hdrl', [_chunk('avih', avih.takeBytes()), strl]);
  final moviList = _list('movi', [movi.takeBytes()]);
  final body = BytesBuilder(copy: false)
    ..add(_fourcc('AVI '))
    ..add(hdrl)
    ..add(moviList)
    ..add(_chunk('idx1', idx.takeBytes()));
  final out = BytesBuilder(copy: false)
    ..add(_fourcc('RIFF'))
    ..add(_u32(body.length))
    ..add(body.takeBytes());
  onProgress?.call(1);
  return out.takeBytes();
}

Uint8List _fourcc(String s) => Uint8List.fromList(s.codeUnits);
Uint8List _u32(int v) => (ByteData(4)..setUint32(0, v, Endian.little)).buffer.asUint8List();
Uint8List _u16(int v) => (ByteData(2)..setUint16(0, v, Endian.little)).buffer.asUint8List();

Uint8List _chunk(String id, Uint8List data) {
  final b = BytesBuilder(copy: false)
    ..add(_fourcc(id))
    ..add(_u32(data.length))
    ..add(data);
  if (data.length.isOdd) b.addByte(0);
  return b.takeBytes();
}

Uint8List _list(String type, List<Uint8List> parts) {
  final body = BytesBuilder(copy: false)..add(_fourcc(type));
  for (final p in parts) {
    body.add(p);
  }
  final data = body.takeBytes();
  return (BytesBuilder(copy: false)
        ..add(_fourcc('LIST'))
        ..add(_u32(data.length))
        ..add(data))
      .takeBytes();
}
