import 'package:flutter/material.dart';

import '../core/dash.dart';
import '../ui/components.dart';
import '../video/video_view.dart';
import '../viz/map_view.dart';
import '../viz/scene3d.dart';

/// The big picture behind the HUD: one of the 3D cameras, the map or a
/// device camera. Views: chase, orbit, top, map, cam.
class MainView extends StatelessWidget {
  const MainView(this.d, {super.key, required this.view, this.interactive = true, this.attribution = true});
  final Dash d;
  final String view;
  final bool interactive;

  /// False when the host screen draws [MapOverlayAttribution] above its overlays.
  final bool attribution;

  @override
  Widget build(BuildContext context) {
    final v = available(d, view);
    return switch (v) {
      'map' => MapView(d, interactive: interactive, controls: interactive, attribution: attribution),
      'cam' => VideoView(d, fit: BoxFit.cover),
      _ => Scene3D(d, view: v, layers: d.layers, interactive: interactive),
    };
  }

  /// Falls back to the chase camera when the map or camera is not available
  /// for this device (no GPS fix yet, no camera declared).
  static String available(Dash d, String view) => switch (view) {
    'map' when !hasMap(d) => 'chase',
    'cam' when d.video.isEmpty => 'chase',
    _ => view,
  };
}

/// Segmented items for the view switch; MAP and CAM appear when the device
/// has a GPS fix or a camera.
List<String> viewItems(Dash d, {bool cameras3d = true}) => [
  if (cameras3d) ...['CHASE', 'ORBIT', 'TOP'] else '3D',
  if (hasMap(d)) 'MAP',
  if (d.video.isNotEmpty) 'CAM',
];

/// View switch that keeps its value valid as MAP and CAM come and go.
class ViewSeg extends StatelessWidget {
  const ViewSeg(this.d, {super.key, required this.view, required this.onChanged, this.cameras3d = true});
  final Dash d;
  final String view;
  final ValueChanged<String> onChanged;
  final bool cameras3d;
  @override
  Widget build(BuildContext context) {
    final items = viewItems(d, cameras3d: cameras3d);
    final v = MainView.available(d, view);
    final label = cameras3d ? v.toUpperCase() : (v == 'map' || v == 'cam' ? v.toUpperCase() : '3D');
    return Seg(small: true, items: items, value: label, onChanged: (x) => onChanged(x == '3D' ? 'chase' : x.toLowerCase()));
  }
}

/// Map credit for screens that draw widgets over a background map: placed
/// last in their stack so tiles and controls never cover it.
class MapOverlayAttribution extends StatelessWidget {
  const MapOverlayAttribution(this.d, {super.key, required this.view});
  final Dash d;
  final String view;
  @override
  Widget build(BuildContext context) {
    final src = MainView.available(d, view) == 'map' ? tileSourceFor(d.settings) : null;
    return src == null ? const SizedBox.shrink() : MapAttribution(src);
  }
}
