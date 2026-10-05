// Renders the app icon masters from the mark (brand/koebelt-dash-icon.svg):
// the #1D1A1B tile, rx 62 on a 280 viewBox, mark at 1:1.
// Run:  ICON_DIR=/tmp/icons flutter test test/gen_icons_test.dart
// then  python3 tool/icons.py /tmp/icons
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:koebelt_dash/ui/mark.dart';

const _tile = ui.Color(0xFF1D1A1B);

/// [inset]: share of the canvas the tile fills (macOS leaves a margin);
/// [rounded]: false for iOS, which rounds the opaque square itself.
Future<List<int>> _render(int px, {double inset = 1, bool rounded = true}) async {
  final rec = ui.PictureRecorder(), c = ui.Canvas(rec);
  final k = px * inset / 280;
  c.translate(px / 2, px / 2);
  c.scale(k);
  final paint = ui.Paint()..color = _tile;
  if (rounded) {
    c.drawRRect(ui.RRect.fromLTRBR(-140, -140, 140, 140, const ui.Radius.circular(62)), paint);
  } else {
    c.drawRect(const ui.Rect.fromLTRB(-140, -140, 140, 140), paint);
  }
  for (final p in staticMark()) {
    c.drawPath(ui.Path()..addPolygon(p.pts, true), ui.Paint()..color = p.color);
  }
  final img = await rec.endRecording().toImage(px, px);
  return (await img.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
}

void main() {
  final dir = Platform.environment['ICON_DIR'];
  test('render icon masters', () async {
    if (dir == null) return;
    Directory(dir).createSync(recursive: true);
    File('$dir/square.png').writeAsBytesSync(await _render(1024, rounded: false));
    File('$dir/rounded.png').writeAsBytesSync(await _render(1024));
    // Apple's macOS grid: an 824 px tile on a 1024 px canvas.
    File('$dir/macos.png').writeAsBytesSync(await _render(1024, inset: 824 / 1024));
  });
}
