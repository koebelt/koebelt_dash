// Map tiles: Mapbox by default, with its token, credits and logo, and no
// stale tiles beyond its cache headers; custom sources keep the offline
// fallback (which never contacts the server).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
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

  test('Mapbox styles with a token, credited; without a token, no tiles and a reason', () {
    final st = Settings()..mapboxToken = 'pk.test';
    expect(st.mapTiles, 'dark', reason: 'the default');
    for (final (id, style) in [('dark', 'mapbox/dark-v11'), ('outdoors', 'mapbox/outdoors-v12'), ('satellite', 'mapbox/satellite-streets-v12')]) {
      st.mapTiles = id;
      final src = tileSourceFor(st)!;
      expect(src.url, 'https://api.mapbox.com/styles/v1/$style/tiles/512/{z}/{x}/{y}@2x?access_token=pk.test');
      expect(src.mapbox, isTrue);
      expect(src.size, 512);
      expect(src.dark, isFalse, reason: 'Mapbox styles are not recoloured');
      expect(src.attribution, '© Mapbox © OpenStreetMap');
    }
    st.mapboxToken = '';
    if (appMapboxToken.isEmpty) {
      expect(tileSourceFor(st), isNull);
      expect(tilesProblem(st), contains('no Mapbox token'));
    }
  });

  test('old settings move to the closest Mapbox style', () {
    expect((Settings()..load({'mapTiles': 'osm'})).mapTiles, 'dark');
    expect((Settings()..load({'mapTiles': 'topo'})).mapTiles, 'outdoors');
    expect((Settings()..load({'mapTiles': 'none'})).mapTiles, 'none');
  });

  test('custom tiles use your attribution', () {
    final st = Settings();
    st
      ..mapTiles = 'custom'
      ..mapUrl = 'https://tiles.example.com/{z}/{x}/{y}.png'
      ..mapAttribution = '© Example © OpenStreetMap contributors';
    expect(tileSourceFor(st)!.attribution, '© Example © OpenStreetMap contributors');
    st.mapTiles = 'none';
    expect(tileSourceFor(st), isNull);
  });

  testWidgets('attribution is drawn above everything else', (tester) async {
    final src = tileSourceFor(Settings()..mapboxToken = 'pk.test')!;
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
    expect(find.text('© Mapbox'), findsOneWidget);
    expect(find.text('© OpenStreetMap'), findsOneWidget);
    expect(find.text('Improve this map'), findsOneWidget, reason: 'Mapbox requires it');
    expect(find.byType(SvgPicture), findsOneWidget, reason: 'the Mapbox logo');
    final hit = tester.hitTestOnBinding(tester.getCenter(find.text('© Mapbox')));
    expect(hit.path.any((e) => e.target is RenderParagraph), isTrue);
  });
}
