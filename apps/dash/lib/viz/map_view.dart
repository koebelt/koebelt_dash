import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'dart:async';
import 'dart:io';

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:http/retry.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:path_provider/path_provider.dart';

import '../core/dash.dart';
import '../core/model.dart';
import '../core/sequence.dart';
import '../core/telemetry.dart';
import '../link/protocol.dart' show appVersion;
import '../screens/guides_data.dart' show repoUrl;
import '../theme/tokens.dart';
import '../ui/components.dart';
import 'viz.dart' show fleetColor;
import '../ui/icons.dart';

/// Tile sources offered in Settings.
class TileSource {
  const TileSource(this.id, this.name, this.url, this.attribution, {this.dark = false, this.link, this.mapbox = false, this.size = 256});
  final String id, name, url, attribution;

  /// Where tapping the attribution goes (the licence or copyright page).
  final String? link;

  /// Restyle light tiles to fit the dark interface.
  final bool dark;

  /// Mapbox: its logo and "Improve this map" on the map, and no stale tiles
  /// offline beyond what its cache headers allow.
  final bool mapbox;

  /// Tile size in pixels.
  final int size;
}

/// The app's Mapbox token, given at build time (--dart-define=MAPBOX_TOKEN):
/// never in the repository.
const appMapboxToken = String.fromEnvironment('MAPBOX_TOKEN');

/// Mapbox styles: (id, name, Mapbox style).
const mapboxStyles = [('dark', 'Dark', 'mapbox/dark-v11'), ('outdoors', 'Outdoors', 'mapbox/outdoors-v12'), ('satellite', 'Satellite', 'mapbox/satellite-streets-v12')];

/// The token for Mapbox tiles: the user's own, else the app's; empty without either.
String mapboxTokenFor(Settings st) => st.mapboxToken.trim().isNotEmpty ? st.mapboxToken.trim() : appMapboxToken;

/// Identifies the app to tile servers: app name, version, where to find it
/// and a contact.
const tileUserAgent = 'koebelt-dash/$appVersion (+$repoUrl; $contactEmail)';

/// Contact for tile servers and package registries.
const contactEmail = 'contact@koebelt.com';

/// The tile source the settings select, or null for the plain grid (no
/// tiles, a bad custom URL, or Mapbox without a token).
TileSource? tileSourceFor(Settings st) {
  if (st.mapTiles == 'custom') {
    return st.mapUrl.contains('{z}') ? TileSource('custom', 'Custom', st.mapUrl, st.mapAttribution.trim().isEmpty ? 'Custom tiles' : st.mapAttribution.trim()) : null;
  }
  final style = mapboxStyles.where((s) => s.$1 == st.mapTiles).firstOrNull;
  final token = mapboxTokenFor(st);
  if (style == null || token.isEmpty) return null;
  // 512-pixel tiles at twice the density: sharp on phones, a quarter of the requests.
  return TileSource(
    style.$1,
    'Mapbox ${style.$2}',
    'https://api.mapbox.com/styles/v1/${style.$3}/tiles/512/{z}/{x}/{y}@2x?access_token=$token',
    '© Mapbox © OpenStreetMap',
    link: 'https://www.mapbox.com/about/maps/',
    mapbox: true,
    size: 512,
  );
}

/// Why the map shows no tiles, for the Settings page; null when it does.
String? tilesProblem(Settings st) {
  if (st.mapTiles == 'none') return null;
  if (st.mapTiles == 'custom') return st.mapUrl.contains('{z}') ? null : 'The tile URL needs {z}, {x} and {y}.';
  return mapboxTokenFor(st).isEmpty ? 'This build has no Mapbox token: enter your own below, or choose another source.' : null;
}

MapCachingProvider _cache = const DisabledMapCachingProvider();

/// Keeps viewed tiles on disk (in the app's support directory, not the OS
/// cache). Freshness follows the tile server's own cache headers.
Future<void> initMapCache() async {
  try {
    final dir = await getApplicationSupportDirectory();
    _cache = BuiltInMapCachingProvider.getOrCreateInstance(cacheDirectory: '${dir.path}/map_tiles', maxCacheSize: 500 * 1024 * 1024);
  } catch (_) {
    _cache = const DisabledMapCachingProvider();
  }
}

/// Offline, a stale cached tile is better than a blank one. When a
/// revalidation request (one carrying If-None-Match / If-Modified-Since,
/// so a cached copy exists) cannot reach the server, answer it locally with
/// 304 Not Modified and `max-age=0`: the cached tile is shown, stays stale,
/// and is revalidated with the server as soon as there is a connection.
/// Nothing extra is ever sent to the tile server.
class OfflineTileClient extends http.BaseClient {
  OfflineTileClient([http.Client? inner]) : _inner = inner ?? http.Client();
  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    try {
      return await _inner.send(request);
    } catch (e) {
      final h = request.headers.keys.map((k) => k.toLowerCase());
      if (e is http.ClientException || e is SocketException || e is TimeoutException) {
        if (h.contains('if-none-match') || h.contains('if-modified-since')) {
          return http.StreamedResponse(const Stream.empty(), HttpStatus.notModified, request: request, headers: {'cache-control': 'max-age=0'});
        }
      }
      rethrow;
    }
  }

  @override
  void close() => _inner.close();
}

/// Required credit for the tiles on screen. Screens that draw tiles over
/// the map (the HUD, the drive screen) put this on top so it is never hidden.
/// Mapbox also requires its logo and an "Improve this map" link.
class MapAttribution extends StatelessWidget {
  const MapAttribution(this.src, {super.key});
  final TileSource src;
  @override
  Widget build(BuildContext context) {
    Widget link(String text, String? url) => Pressable(
      onTap: url == null ? null : () => launchUrl(Uri.parse(url)),
      builder: (_, h, _) => Text(text, style: KText.bodySm.copyWith(fontSize: 10, height: 1.2, color: h ? K.textPrimary : K.textSecondary)),
    );
    final credit = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(color: K.inkA70, borderRadius: BorderRadius.circular(3)),
      child: src.mapbox
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                link('© Mapbox', 'https://www.mapbox.com/about/maps/'),
                const SizedBox(width: 6),
                link('© OpenStreetMap', 'https://www.openstreetmap.org/copyright'),
                const SizedBox(width: 6),
                link('Improve this map', 'https://apps.mapbox.com/feedback/'),
              ],
            )
          : link(src.attribution, src.link),
    );
    if (!src.mapbox) return credit;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SvgPicture.asset('assets/mapbox-logo.svg', height: 18, semanticsLabel: 'Mapbox'),
        const SizedBox(width: 6),
        credit,
      ],
    );
  }
}

/// Grey-inverted tiles: light OpenStreetMap styles become a dark map.
const _darkMatrix = <double>[
  -.16, -.54, -.054, 0, 214, //
  -.16, -.54, -.054, 0, 212,
  -.16, -.54, -.054, 0, 210,
  0, 0, 0, 1, 0,
];

LatLng _offset(LatLng home, double x, double y) => LatLng(home.latitude + y / 111111, home.longitude + x / (111111 * math.cos(home.latitude * math.pi / 180)));

/// Map of the device's GPS position, track, home point and the running
/// sequence's waypoints. Works for live devices and replays.
class MapView extends StatefulWidget {
  const MapView(this.d, {super.key, this.interactive = true, this.controls = true, this.attribution = true});
  final Dash d;
  final bool interactive, controls;

  /// False when the host screen shows [MapAttribution] above its own overlays.
  final bool attribution;
  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  final _map = MapController();
  bool _follow = true, _ready = false;
  double _zoom = 17;

  @override
  void initState() {
    super.initState();
    widget.d.frame.addListener(_tick);
  }

  @override
  void dispose() {
    widget.d.frame.removeListener(_tick);
    _map.dispose();
    super.dispose();
  }

  Telemetry get t => widget.d.tel;
  bool get _hasFix => t.seen.contains('gps') && (t.lat != 0 || t.lon != 0);
  LatLng get _here => LatLng(t.lat, t.lon);

  /// Origin of the local frame. Devices that report a local position use
  /// GPS minus that offset (x east, y north); others use the first fix.
  LatLng? get _home {
    if (!_hasFix) return null;
    if (t.seen.contains('pos')) {
      final h = _offset(_here, -t.pos[0], -t.pos[1]);
      return h;
    }
    final g = t.gpsTrail.isEmpty ? null : t.gpsTrail.first;
    return g == null ? _here : LatLng(g[0], g[1]);
  }

  int _frame = 0;
  void _tick() {
    if (!mounted || !_hasFix) return;
    // ~15 Hz is plenty for a map, and keeps tile layout work down.
    if (_frame++ % 4 != 0) return;
    if (_follow && _ready) {
      _map.move(_here, _map.camera.zoom);
    }
    setState(() {});
  }

  List<LatLng> _track() {
    final rp = widget.d.replay;
    if (rp != null) {
      // Whole flight path from the recording.
      return [
        for (final f in rp.session.frames)
          if ((f['lat'] as num? ?? 0) != 0) LatLng((f['lat'] as num).toDouble(), (f['lon'] as num).toDouble()),
      ];
    }
    return [for (final g in t.gpsTrail) LatLng(g[0], g[1])];
  }

  /// Planned `goto` targets of the running (or paused) sequence.
  List<LatLng> _waypoints(LatLng home) {
    final r = widget.d.runner;
    if (r == null || r.state == RunState.done || widget.d.replay != null) return const [];
    return [
      for (final s in r.seq.steps)
        if (s.type == 'goto') _offset(home, s.n('x'), s.n('y')),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.d, st = d.settings;
    if (!_hasFix) {
      return ColoredBox(
        color: K.surfaceDeep,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              d.hasDevice || d.replay != null ? 'Waiting for a GPS fix' : 'Not connected',
              textAlign: TextAlign.center,
              style: KText.bodySm.copyWith(color: K.textMuted),
            ),
          ),
        ),
      );
    }
    final here = _here, home = _home!;
    final src = tileSourceFor(st);
    final track = _track(), wps = _waypoints(home);
    // The other connected devices, or the rest of the replayed session: arrow, name, track.
    final others = [
      for (final c in d.companions)
        if (c.tel.seen.contains('gps') && (c.tel.lat != 0 || c.tel.lon != 0)) c,
    ];
    final hdg = (90 - t.heading) * math.pi / 180; // map: east = 0, CCW
    Widget? tiles;
    if (src != null) {
      tiles = TileLayer(
        urlTemplate: src.url,
        maxNativeZoom: src.mapbox ? 22 : 19,
        tileDimension: src.size,
        zoomOffset: src.size == 512 ? -1 : 0,
        tileProvider: NetworkTileProvider(
          headers: {'User-Agent': tileUserAgent},
          // Mapbox: cached only as its headers allow, so no stale tiles offline.
          httpClient: RetryClient(src.mapbox ? http.Client() : OfflineTileClient()),
          silenceExceptions: true,
          cachingProvider: _cache,
        ),
        evictErrorTileStrategy: EvictErrorTileStrategy.notVisibleRespectMargin,
        tileBuilder: src.dark
            ? (context, tile, _) => ColorFiltered(colorFilter: const ColorFilter.matrix(_darkMatrix), child: tile)
            : src.mapbox
            ? null
            : (context, tile, _) => Opacity(opacity: .8, child: tile),
      );
    }
    return Stack(
      children: [
        FlutterMap(
          mapController: _map,
          options: MapOptions(
            initialCenter: here,
            initialZoom: _zoom,
            maxZoom: 21,
            minZoom: 3,
            backgroundColor: K.surfaceDeep,
            interactionOptions: InteractionOptions(flags: widget.interactive ? InteractiveFlag.all & ~InteractiveFlag.rotate : InteractiveFlag.none),
            onMapReady: () => _ready = true,
            onPositionChanged: (cam, gesture) {
              _zoom = cam.zoom;
              if (gesture && _follow) setState(() => _follow = false);
            },
          ),
          children: [
            ?tiles,
            if (src == null) _GridLayer(label: widget.controls),
            if (wps.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [here, ...wps],
                    color: K.info,
                    strokeWidth: 1.5,
                    pattern: StrokePattern.dashed(segments: const [6, 5]),
                  ),
                ],
              ),
            if (others.isNotEmpty)
              PolylineLayer(
                polylines: [
                  for (final c in others)
                    if (c.tel.gpsTrail.length > 1)
                      Polyline(points: [for (final g in c.tel.gpsTrail) LatLng(g[0], g[1])], color: fleetColor(d, c.id).withValues(alpha: .5), strokeWidth: 2),
                ],
              ),
            if (track.length > 1)
              PolylineLayer(
                polylines: [Polyline(points: track, color: K.accent.withValues(alpha: .75), strokeWidth: 2.5)],
              ),
            MarkerLayer(
              markers: [
                for (final c in others) ...[
                  Marker(
                    point: LatLng(c.tel.lat, c.tel.lon),
                    width: 120,
                    height: 20,
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 18),
                      child: MonoLabel(c.name, size: 9, color: fleetColor(d, c.id), maxLines: 1),
                    ),
                  ),
                  Marker(
                    point: LatLng(c.tel.lat, c.tel.lon),
                    width: 30,
                    height: 30,
                    child: GestureDetector(
                      onTap: () => d.showCompanion(c.id),
                      child: Transform.rotate(
                        angle: -(90 - c.tel.heading) * math.pi / 180,
                        child: CustomPaint(painter: _Arrow(fleetColor(d, c.id), .8)),
                      ),
                    ),
                  ),
                ],
                Marker(point: home, width: 72, height: 22, alignment: Alignment.centerRight, child: const _HomeMark()),
                for (final (i, w) in wps.indexed) Marker(point: w, width: 18, height: 18, child: _Waypoint(i + 1)),
                Marker(
                  point: here,
                  width: 34,
                  height: 34,
                  child: Transform.rotate(
                    angle: -hdg,
                    child: CustomPaint(painter: _Arrow()),
                  ),
                ),
              ],
            ),
          ],
        ),
        if (src != null && widget.attribution) Positioned(right: 6, bottom: 6, child: MapAttribution(src)),
        if (widget.controls)
          Positioned(
            right: 10,
            top: 0,
            bottom: 0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _MapBtn('plus', 'Zoom in', () => _map.move(_map.camera.center, math.min(21, _map.camera.zoom + 1))),
                const SizedBox(height: 6),
                _MapBtn('minus', 'Zoom out', () => _map.move(_map.camera.center, math.max(3, _map.camera.zoom - 1))),
                const SizedBox(height: 6),
                _MapBtn('crosshair', _follow ? 'Following' : 'Follow device', () {
                  setState(() => _follow = true);
                  _map.move(_here, _map.camera.zoom);
                }, on: _follow),
              ],
            ),
          ),
        if (widget.controls)
          Positioned(
            left: 10,
            bottom: 8,
            child: IgnorePointer(
              child: MonoLabel(
                '${here.latitude.toStringAsFixed(6)}  ${here.longitude.toStringAsFixed(6)}  ·  HOME ${metresBetween(home.latitude, home.longitude, here.latitude, here.longitude).round()} M',
                size: 9,
                color: K.textSecondary,
              ),
            ),
          ),
      ],
    );
  }
}

class _MapBtn extends StatelessWidget {
  const _MapBtn(this.icon, this.label, this.onTap, {this.on = false});
  final String icon, label;
  final VoidCallback onTap;
  final bool on;
  @override
  Widget build(BuildContext context) => Tooltip(
    message: label,
    child: Pressable(
      onTap: onTap,
      builder: (_, h, _) => Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: on ? K.surfaceAccentSoft : (h ? K.surfaceRaised : K.inkA70),
          border: Border.all(color: on ? K.limeA32 : K.borderSubtle),
          borderRadius: BorderRadius.circular(K.radiusControl),
        ),
        child: Center(child: KIcon(icon, size: 16, color: on ? K.accent : K.textPrimary)),
      ),
    ),
  );
}

class _HomeMark extends StatelessWidget {
  const _HomeMark();
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: K.ink050, width: 1.5),
        ),
      ),
      const SizedBox(width: 4),
      const MonoLabel('HOME', size: 9, color: K.ink050),
    ],
  );
}

class _Waypoint extends StatelessWidget {
  const _Waypoint(this.n);
  final int n;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: K.inkA70,
      shape: BoxShape.circle,
      border: Border.all(color: K.info, width: 1.5),
    ),
    child: Center(child: MonoLabel('$n', size: 8, color: K.info)),
  );
}

class _Arrow extends CustomPainter {
  _Arrow([this.color = K.accent, this.scale = 1.0]);
  final Color color;
  final double scale;
  @override
  void paint(Canvas c, Size s) {
    final m = s.center(Offset.zero), k = scale;
    final p = Path()
      ..moveTo(m.dx + 13 * k, m.dy)
      ..lineTo(m.dx - 9 * k, m.dy - 9 * k)
      ..lineTo(m.dx - 4 * k, m.dy)
      ..lineTo(m.dx - 9 * k, m.dy + 9 * k)
      ..close();
    c.drawPath(
      p,
      Paint()
        ..color = K.ink900
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    c.drawPath(p, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _Arrow o) => o.color != color;
}

/// Metre grid when no tile source is set (offline, or tiles turned off).
class _GridLayer extends StatelessWidget {
  const _GridLayer({required this.label});
  final bool label;
  @override
  Widget build(BuildContext context) {
    final cam = MapCamera.of(context);
    return CustomPaint(size: Size.infinite, painter: _GridPainter(cam, label));
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter(this.cam, this.label);
  final MapCamera cam;
  final bool label;
  @override
  void paint(Canvas c, Size s) {
    // Pick a step that gives 40–120 px between lines.
    final mpp = 156543.03392 * math.cos(cam.center.latitude * math.pi / 180) / math.pow(2, cam.zoom);
    var step = 1.0;
    while (step / mpp < 40) {
      step *= step.toString().startsWith('2') ? 2.5 : 2;
    }
    final px = step / mpp;
    final p = Paint()
      ..color = K.borderHairline
      ..strokeWidth = 1;
    final o = cam.projectAtZoom(cam.center);
    final ox = (s.width / 2 - o.dx) % px, oy = (s.height / 2 - o.dy) % px;
    for (var x = ox; x < s.width; x += px) {
      c.drawLine(Offset(x, 0), Offset(x, s.height), p);
    }
    for (var y = oy; y < s.height; y += px) {
      c.drawLine(Offset(0, y), Offset(s.width, y), p);
    }
    if (!label) return;
    final tp = TextPainter(
      text: TextSpan(text: 'GRID ${step >= 1000 ? '${(step / 1000).toStringAsFixed(0)} KM' : '${step.round()} M'}', style: KText.label(size: 9)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, Offset(10, s.height - 34));
    tp.dispose();
  }

  @override
  bool shouldRepaint(covariant _GridPainter o) => true;
}

/// Whether the map has anything to show for the current device.
bool hasMap(Dash d) => d.tel.seen.contains('gps') && d.kind != DeviceKind.arm && d.kind != DeviceKind.bench;
