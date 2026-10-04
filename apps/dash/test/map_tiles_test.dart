// OpenStreetMap tile usage policy: identify the app, honour the server's
// caching (with an offline fallback that never contacts the server), and
// always show the attribution.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:koebelt_dash/core/dash.dart';
import 'package:koebelt_dash/viz/map_view.dart';

class _Down extends http.BaseClient {
  int calls = 0;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest r) async {
    calls++;
    throw http.ClientException('no network', r.url);
  }
}

void main() {
  test('User-Agent names the app, its version and where to find it', () {
    expect(tileUserAgent, startsWith('koebelt-dash/'));
    expect(tileUserAgent, contains('github.com/koebelt/koebelt_dash'));
    expect(tileUserAgent, contains('contact@koebelt.com'));
    expect(tileUserAgent, isNot(contains('flutter_map')));
  });

  test('offline: cached tiles get a local 304 that keeps them stale, new tiles fail', () async {
    final down = _Down(), c = OfflineTileClient(down);
    final reval = http.Request('GET', Uri.parse('https://tile.openstreetmap.org/1/0/0.png'))..headers['If-None-Match'] = '"abc"';
    final r = await c.send(reval);
    expect(r.statusCode, HttpStatus.notModified);
    expect(r.headers['cache-control'], 'max-age=0', reason: 'no extra freshness: revalidate once online');
    expect(down.calls, 1, reason: 'one real attempt, no retries of our own');
    final fresh = http.Request('GET', Uri.parse('https://tile.openstreetmap.org/1/0/1.png'));
    expect(() => c.send(fresh), throwsA(isA<http.ClientException>()));
  });

  test('every tile source carries an attribution; custom uses yours', () {
    final st = Settings();
    for (final id in ['osm', 'topo']) {
      st.mapTiles = id;
      expect(tileSourceFor(st)!.attribution, contains('OpenStreetMap contributors'));
    }
    st
      ..mapTiles = 'custom'
      ..mapUrl = 'https://tiles.example.com/{z}/{x}/{y}.png'
      ..mapAttribution = '© Example © OpenStreetMap contributors';
    expect(tileSourceFor(st)!.attribution, '© Example © OpenStreetMap contributors');
    st.mapTiles = 'none';
    expect(tileSourceFor(st), isNull);
  });

  testWidgets('attribution is drawn above everything else', (tester) async {
    final src = tileSources.first;
    await tester.pumpWidget(
      MaterialApp(
        home: Stack(
          children: [
            const Positioned.fill(child: ColoredBox(color: Colors.black)),
            // A HUD tile covering the bottom-right corner…
            const Positioned(right: 0, bottom: 0, width: 300, height: 200, child: ColoredBox(color: Colors.red)),
            // …and the credit placed last, as the HUD and drive screens do.
            Positioned(right: 4, bottom: 4, child: MapAttribution(src)),
          ],
        ),
      ),
    );
    final hit = tester.hitTestOnBinding(tester.getCenter(find.text(src.attribution)));
    expect(hit.path.any((e) => e.target is RenderParagraph), isTrue);
  });
}
