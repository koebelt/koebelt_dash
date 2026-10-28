// koebelt/link v1 codec. See protocol/PROTOCOL.md.
import 'dart:convert';
import 'dart:typed_data';

const protocolVersion = 1;
const udpDevicePort = 47800;
const udpAnnouncePort = 47801;
const bleService = '6e400001-b5a3-f393-e0a9-e50e24dcca9e';
const bleRx = '6e400002-b5a3-f393-e0a9-e50e24dcca9e';
const bleTx = '6e400003-b5a3-f393-e0a9-e50e24dcca9e';
const appVersion = '1.3.0-rc.1';

typedef Msg = Map<String, dynamic>;

String encodeMsg(Msg m) => jsonEncode(m);

/// Returns null for anything that is not a JSON object with a string `t`.
Msg? decodeMsg(String s) {
  try {
    final v = jsonDecode(s);
    if (v is Map<String, dynamic> && v['t'] is String) return v;
  } catch (_) {}
  return null;
}

/// Splits a byte stream into newline-delimited messages (serial, BLE).
class LineDecoder {
  final _buf = BytesBuilder(copy: false);
  static const maxLine = 64 * 1024;

  Iterable<Msg> add(List<int> bytes) sync* {
    var start = 0;
    for (var i = 0; i < bytes.length; i++) {
      if (bytes[i] == 0x0A) {
        _buf.add(bytes.sublist(start, i));
        final line = utf8.decode(_buf.takeBytes(), allowMalformed: true).trim();
        start = i + 1;
        if (line.isEmpty) continue;
        final m = decodeMsg(line);
        if (m != null) yield m;
      }
    }
    if (start < bytes.length) _buf.add(bytes.sublist(start));
    if (_buf.length > maxLine) _buf.clear();
  }
}

/// `i16cm` point cloud: little-endian int16 x,y,z triplets in centimetres.
String encodePoints(List<List<double>> pts) {
  final b = ByteData(pts.length * 6);
  var o = 0;
  for (final p in pts) {
    for (var i = 0; i < 3; i++) {
      b.setInt16(o, (p[i] * 100).round().clamp(-32768, 32767), Endian.little);
      o += 2;
    }
  }
  return base64Encode(b.buffer.asUint8List());
}

List<List<double>> decodePoints(String d) {
  final bytes = base64Decode(d);
  final b = ByteData.sublistView(bytes);
  final n = bytes.length ~/ 6;
  return [
    for (var i = 0; i < n; i++)
      [b.getInt16(i * 6, Endian.little) / 100, b.getInt16(i * 6 + 2, Endian.little) / 100, b.getInt16(i * 6 + 4, Endian.little) / 100],
  ];
}

double numOr(dynamic v, double d) => v is num ? v.toDouble() : d;
