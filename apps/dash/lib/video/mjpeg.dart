import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// Splits an HTTP `multipart/x-mixed-replace` body (MJPEG) into frames.
///
/// Uses each part's Content-Length when the server sends one (ESP32
/// CameraWebServer, mjpg-streamer, ustreamer) and falls back to searching
/// for the boundary when it does not. Parts may be JPEG or PNG; whatever the
/// image codec can decode is passed through.
class MjpegParser {
  MjpegParser(String? boundary) : _boundary = boundary == null ? null : ascii.encode(boundary.replaceFirst(RegExp(r'^--'), ''));

  final List<int>? _boundary;
  final _buf = BytesBuilder(copy: false);
  Uint8List _data = Uint8List(0);
  int _len = -1; // body length of the current part, -1 = unknown
  bool _inBody = false;

  /// Upper bound for one frame, so a broken stream cannot eat memory.
  static const maxFrame = 8 * 1024 * 1024;

  /// Feeds bytes; returns the complete frames they finished.
  List<Uint8List> add(List<int> bytes) {
    _buf.add(bytes);
    if (_data.isNotEmpty) {
      final b = BytesBuilder(copy: false)
        ..add(_data)
        ..add(_buf.takeBytes());
      _data = b.takeBytes();
    } else {
      _data = _buf.takeBytes();
    }
    final out = <Uint8List>[];
    var pos = 0;
    while (true) {
      if (!_inBody) {
        final end = _find(_data, const [13, 10, 13, 10], pos);
        if (end < 0) {
          if (_data.length - pos > 16 * 1024) pos = _data.length; // garbage, resync
          break;
        }
        final head = latin1.decode(_data.sublist(pos, end), allowInvalid: true);
        _len = -1;
        for (final line in head.split('\r\n')) {
          final i = line.indexOf(':');
          if (i > 0 && line.substring(0, i).trim().toLowerCase() == 'content-length') {
            _len = int.tryParse(line.substring(i + 1).trim()) ?? -1;
          }
        }
        pos = end + 4;
        _inBody = true;
      }
      if (_len >= 0) {
        if (_len > maxFrame) {
          _reset();
          return out;
        }
        if (_data.length - pos < _len) break;
        out.add(Uint8List.sublistView(_data, pos, pos + _len));
        pos += _len;
        _inBody = false;
        continue;
      }
      final b = _boundary;
      final at = b == null ? _find(_data, const [0xFF, 0xD9], pos) : _find(_data, b, pos);
      if (at < 0) {
        if (_data.length - pos > maxFrame) _reset();
        break;
      }
      if (b == null) {
        // No boundary known: cut at the JPEG end marker.
        out.add(Uint8List.sublistView(_data, pos, at + 2));
        pos = at + 2;
      } else {
        // Body ends before "\r\n--boundary".
        var e = at;
        while (e > pos && _data[e - 1] == 45) {
          e--; // '-'
        }
        if (e - 2 >= pos && _data[e - 2] == 13 && _data[e - 1] == 10) e -= 2;
        if (e > pos) out.add(Uint8List.sublistView(_data, pos, e));
        pos = at; // the boundary line becomes part of the next header block
      }
      _inBody = false;
    }
    _data = pos >= _data.length ? Uint8List(0) : Uint8List.fromList(Uint8List.sublistView(_data, pos));
    return out;
  }

  void _reset() {
    _data = Uint8List(0);
    _inBody = false;
    _len = -1;
  }

  static int _find(Uint8List h, List<int> n, int from) {
    final last = h.length - n.length;
    outer:
    for (var i = from; i <= last; i++) {
      for (var j = 0; j < n.length; j++) {
        if (h[i + j] != n[j]) continue outer;
      }
      return i;
    }
    return -1;
  }
}

/// Boundary from a Content-Type header, or null.
String? boundaryOf(String? contentType) {
  if (contentType == null) return null;
  final m = RegExp(r'boundary="?([^";]+)"?', caseSensitive: false).firstMatch(contentType);
  return m?.group(1)?.trim();
}

/// Reads frames from an MJPEG URL, or polls a still-image URL (`fmt: jpeg`).
/// Reconnects with back-off until [close] is called.
class MjpegClient {
  MjpegClient(this.url, {this.snapshot = false, this.pollEvery = const Duration(milliseconds: 200)});
  final Uri url;
  final bool snapshot;
  final Duration pollEvery;

  final _frames = StreamController<Uint8List>.broadcast();
  final _status = StreamController<String>.broadcast();
  HttpClient? _http;
  bool _closed = false;
  int _bytes = 0;

  Stream<Uint8List> get frames => _frames.stream;

  /// Human-readable state changes: "Connecting", "No signal: …".
  Stream<String> get status => _status.stream;

  /// Bytes received since the last call.
  int takeBytes() {
    final b = _bytes;
    _bytes = 0;
    return b;
  }

  void start() => unawaited(_run());

  Future<void> _run() async {
    var backoff = 500;
    while (!_closed) {
      final http = _http = HttpClient()..connectionTimeout = const Duration(seconds: 4);
      try {
        _status.add('Connecting');
        if (snapshot) {
          await _poll(http);
        } else {
          await _stream(http);
        }
        backoff = 500;
      } catch (e) {
        if (_closed) break;
        _status.add('No signal: ${_short(e)}');
      } finally {
        http.close(force: true);
      }
      if (_closed) break;
      await Future<void>.delayed(Duration(milliseconds: backoff));
      backoff = (backoff * 2).clamp(500, 5000);
    }
  }

  Future<void> _stream(HttpClient http) async {
    final req = await http.getUrl(url);
    final res = await req.close();
    if (res.statusCode != 200) throw HttpException('HTTP ${res.statusCode}');
    final ct = res.headers.contentType?.toString() ?? res.headers.value('content-type');
    final isMultipart = ct != null && ct.toLowerCase().contains('multipart');
    if (!isMultipart) {
      // A plain image: show it and refresh like a snapshot source.
      final b = await res.fold<BytesBuilder>(BytesBuilder(copy: false), (a, c) => a..add(c));
      _emit(b.takeBytes());
      await _poll(http);
      return;
    }
    _status.add('Live');
    final p = MjpegParser(boundaryOf(ct));
    await for (final chunk in res.timeout(const Duration(seconds: 3))) {
      if (_closed) return;
      _bytes += chunk.length;
      for (final f in p.add(chunk)) {
        _emit(f);
      }
    }
    throw const HttpException('stream ended');
  }

  Future<void> _poll(HttpClient http) async {
    _status.add('Live');
    while (!_closed) {
      final t0 = DateTime.now();
      final req = await http.getUrl(url);
      final res = await req.close().timeout(const Duration(seconds: 3));
      if (res.statusCode != 200) throw HttpException('HTTP ${res.statusCode}');
      final b = await res.fold<BytesBuilder>(BytesBuilder(copy: false), (a, c) => a..add(c));
      final bytes = b.takeBytes();
      _bytes += bytes.length;
      _emit(bytes);
      final wait = pollEvery - DateTime.now().difference(t0);
      if (wait > Duration.zero) await Future<void>.delayed(wait);
    }
  }

  void _emit(Uint8List f) {
    if (!_closed && f.isNotEmpty) _frames.add(f);
  }

  static String _short(Object e) {
    final s = e is SocketException
        ? (e.osError?.message ?? e.message)
        : e is TimeoutException
        ? 'timed out'
        : e is HttpException
        ? e.message
        : '$e';
    return s.length > 60 ? '${s.substring(0, 60)}…' : s;
  }

  Future<void> close() async {
    _closed = true;
    _http?.close(force: true);
    await _frames.close();
    await _status.close();
  }
}
