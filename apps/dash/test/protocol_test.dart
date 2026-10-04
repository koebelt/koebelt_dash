import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:koebelt_dash/core/model.dart';
import 'package:koebelt_dash/link/protocol.dart';
import 'package:koebelt_dash/link/session.dart';

void main() {
  final vectors = (jsonDecode(File('../../protocol/vectors.json').readAsStringSync())['vectors'] as List).cast<Map<String, dynamic>>();

  group('shared protocol vectors', () {
    for (final v in vectors) {
      test(v['name'], () {
        final m = decodeMsg(v['wire'])!;
        final want = (v['decoded'] as Map).cast<String, dynamic>();
        if (m['t'] == 'pc') {
          final pts = decodePoints(m['d']);
          expect(pts, want['points_m']);
          return;
        }
        for (final e in want.entries) {
          expect(m[e.key], e.value, reason: e.key);
        }
      });
    }
  });

  test('rejects non-messages', () {
    expect(decodeMsg('[1,2]'), isNull);
    expect(decodeMsg('{"x":1}'), isNull);
    expect(decodeMsg('not json'), isNull);
  });

  test('point cloud round-trips at centimetre precision', () {
    final pts = [
      [1.234, -5.678, 0.0],
      [-300.0, 300.0, 12.01],
    ];
    final back = decodePoints(encodePoints(pts));
    for (var i = 0; i < pts.length; i++) {
      for (var k = 0; k < 3; k++) {
        expect(back[i][k], closeTo(pts[i][k], .006));
      }
    }
  });

  test('line decoder reassembles split frames', () {
    final ld = LineDecoder();
    final bytes = utf8.encode('{"t":"a"}\n{"t":"b","x"');
    expect(ld.add(bytes).map((m) => m['t']).toList(), ['a']);
    expect(ld.add(utf8.encode(':1}\n\n')).map((m) => m['t']).toList(), ['b']);
  });

  test('params without layout are grouped by prefix', () {
    final g = parseParams({
      't': 'params',
      'p': [
        ['RATE_RLL_P', .135, 0, .5, .001, ''],
        ['RATE_PIT_P', .135, 0, .5, .001, ''],
        ['MAX_TILT', 35, 10, 60, 1, 'deg'],
      ],
    }, DeviceKind.generic);
    expect(g.map((e) => e.name), ['RATE', 'MAX']);
    expect(g.first.params.length, 2);
    expect(g.last.params.single.unit, 'deg');
  });
}
