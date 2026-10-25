import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/dash.dart';
import '../core/model.dart';
import '../theme/tokens.dart';
import '../ui/components.dart';
import '../scripts/views.dart';
import '../video/video_view.dart';
import '../viz/map_view.dart';
import '../viz/scene3d.dart';
import '../viz/script_views.dart';
import '../viz/viz.dart';

String deg(double r) => '${f1(r * 57.3, 1)}°';

class TileDef {
  const TileDef({
    required this.id,
    required this.title,
    required this.types,
    required this.val,
    required this.body,
    required this.keys,
    required this.labels,
    required this.unit,
    required this.src,
    this.tt = const {},
    this.colors,
    this.sym = false,
    this.hudOnly = false,
    this.needs = const [],
    this.when,
  });
  final String id, title, unit, src;
  final Set<DeviceKind> types;
  final Map<DeviceKind, String> tt;
  final String Function(Dash) val;
  final Widget Function(Dash) body;
  final List<String> keys, labels;
  final List<Color>? colors;
  final bool sym, hudOnly;

  /// Telemetry channels that feed this tile; it is offered when any has been received.
  final List<String> needs;

  /// Extra condition for tiles that do not come from telemetry (camera).
  final bool Function(Dash)? when;

  String titleFor(DeviceKind k) => tt[k] ?? title;
}

const _D = DeviceKind.drone, _R = DeviceKind.rover, _A = DeviceKind.arm, _K = DeviceKind.rocket, _B = DeviceKind.bench, _G = DeviceKind.generic;
const j6 = [VC.white, VC.info, VC.warn, VC.pos, VC.neg, VC.ink100];

final List<TileDef> tiles = [
  TileDef(
    id: 'readout',
    title: 'Readouts',
    types: {_D, _R, _A, _K, _B, _G},
    hudOnly: true,
    val: (_) => '',
    body: (d) => ReadoutBody(d),
    keys: ['alt', 'spd'],
    labels: ['Alt', 'Speed'],
    unit: '',
    src: 'Fused state',
  ),
  TileDef(
    id: 'attitude',
    needs: ['att'],
    title: 'Attitude',
    types: {_D, _R, _A, _K, _B, _G},
    val: (d) => 'R ${deg(d.tel.roll)}  P ${deg(d.tel.pitch)}',
    body: (d) => LiveCanvas(AttitudePainter(d)),
    keys: ['gx', 'gy', 'gz'],
    labels: ['Roll rate', 'Pitch rate', 'Yaw rate'],
    unit: 'rad/s',
    src: 'IMU · BMI088',
    sym: true,
  ),
  TileDef(
    id: 'accel',
    needs: ['imu'],
    title: 'Accelerometer',
    types: {_D, _R, _A, _K, _B, _G},
    tt: {_B: 'Vibration', _K: 'Accelerometer · 200 G'},
    val: (d) => '${f1(hypot3(d.tel.acc[0], d.tel.acc[1], d.tel.acc[2]) / 9.81, 2)} g',
    body: (d) => LineChart(d, keys: const ['ax', 'ay', 'az'], sym: true),
    keys: ['ax', 'ay', 'az'],
    labels: ['X', 'Y', 'Z'],
    unit: 'm/s²',
    src: 'IMU · BMI088',
    sym: true,
  ),
  TileDef(
    id: 'gyro',
    needs: ['imu'],
    title: 'Gyroscope',
    types: {_D, _R, _A, _K, _B, _G},
    val: (d) => '${f1(d.tel.gyro[2], 2)} rad/s',
    body: (d) => LineChart(d, keys: const ['gx', 'gy', 'gz'], sym: true),
    keys: ['gx', 'gy', 'gz'],
    labels: ['X', 'Y', 'Z'],
    unit: 'rad/s',
    src: 'IMU · BMI088',
    sym: true,
  ),
  TileDef(
    id: 'gps',
    needs: ['gps'],
    title: 'GPS',
    types: {_D, _R, _A, _K, _B, _G},
    val: (d) => '${d.tel.lat.toStringAsFixed(5)} ${d.tel.lon.toStringAsFixed(5)}',
    body: (d) => MapView(d, interactive: false, controls: false),
    keys: ['spd'],
    labels: ['Ground speed'],
    unit: 'm/s',
    src: 'GNSS',
  ),
  TileDef(
    id: 'alt',
    needs: ['pos'],
    title: 'Altitude',
    types: {_D, _K, _G},
    val: (d) => '${d.tel.pos[2].toStringAsFixed(1)} m',
    body: (d) => LineChart(d, keys: const ['alt'], colors: const [VC.lime]),
    keys: ['alt'],
    labels: ['AGL'],
    unit: 'm',
    src: 'Baro + rangefinder',
  ),
  TileDef(
    id: 'radar',
    needs: ['tracks'],
    title: 'Radar',
    types: {_D, _R, _A, _K, _B, _G},
    tt: {_A: 'Safety scanner'},
    val: (d) => '${d.tel.targets.length} tracks',
    body: (d) => LiveCanvas(RadarPainter(d)),
    keys: ['spd'],
    labels: ['Own speed'],
    unit: 'm/s',
    src: 'Radar / safety scanner',
  ),
  TileDef(
    id: 'lidar',
    needs: ['pc'],
    title: 'Lidar',
    types: {_D, _R, _A, _K, _B, _G},
    val: (d) => '${d.tel.cloud.length} pts',
    body: (d) => Scene3D(d, view: 'top', interactive: false, label: false, layers: const {'cloud': true, 'grid': true}),
    keys: ['spd'],
    labels: ['Own speed'],
    unit: 'm/s',
    src: 'Scanning lidar',
  ),
  TileDef(
    id: 'joints',
    needs: ['joints'],
    title: 'Joints',
    types: {_D, _R, _A, _K, _B, _G},
    val: (_) => '6 axes',
    body: (d) => LiveCanvas(JointBarsPainter(d)),
    keys: ['j0', 'j1', 'j2', 'j3', 'j4', 'j5'],
    labels: ['J1', 'J2', 'J3', 'J4', 'J5', 'J6'],
    colors: j6,
    unit: 'rad',
    src: 'Joint encoders',
    sym: true,
  ),
  TileDef(
    id: 'ft',
    needs: ['ft'],
    title: 'Force / torque',
    types: {_D, _R, _A, _K, _B, _G},
    val: (d) => '${f1(d.tel.ft[2], 1)} N',
    body: (d) => LineChart(d, keys: const ['fx', 'fy', 'fz'], sym: true),
    keys: ['fx', 'fy', 'fz'],
    labels: ['Fx', 'Fy', 'Fz'],
    unit: 'N',
    src: 'Wrist F/T sensor',
    sym: true,
  ),
  TileDef(
    id: 'power',
    needs: ['bat'],
    title: 'Power',
    types: {_D, _R, _A, _K, _B, _G},
    val: (d) => d.kind == _A || d.kind == _B ? '${d.tel.current.toStringAsFixed(1)} A' : '${d.tel.battery.round()}%',
    body: (d) => LineChart(d, keys: const ['volt'], colors: const [VC.lime]),
    keys: ['volt', 'cur'],
    labels: ['Voltage', 'Current'],
    unit: 'V · A',
    src: 'Power module',
  ),
  TileDef(
    id: 'link',
    needs: ['rssi'],
    title: 'Link',
    types: {_D, _R, _A, _K, _B, _G},
    val: (d) => '${d.tel.rssi.round()} dBm',
    body: (d) => LineChart(d, keys: const ['rssi'], colors: const [VC.info]),
    keys: ['rssi', 'lat'],
    labels: ['RSSI', 'Latency'],
    unit: 'dBm · ms',
    src: 'Radio link',
  ),
  TileDef(
    id: 'video',
    title: 'Camera',
    types: {_D, _R, _A, _K, _B, _G},
    when: (d) => d.video.isNotEmpty,
    val: (d) => d.video.isEmpty ? '' : (d.video.first.label.isEmpty ? d.video.first.id : d.video.first.label),
    body: (d) => VideoView(d, fit: BoxFit.cover, compact: true),
    keys: [],
    labels: [],
    unit: '',
    src: 'Device camera · MJPEG',
  ),
  TileDef(
    id: 'fleet',
    title: 'Fleet',
    types: {_D, _R, _A, _K, _B, _G},
    when: (d) => d.links.length > 1,
    val: (d) => '${d.links.length} connected',
    body: (d) => FleetTile(d),
    keys: [],
    labels: [],
    unit: '',
    src: 'Every connected device',
  ),
  // rocket
  TileDef(
    id: 'phase',
    title: 'Flight phase',
    types: {_K},
    val: (d) => phaseLabel[d.tel.mode] ?? d.tel.mode,
    body: (d) => FlightPhases(d),
    keys: ['alt', 'vz'],
    labels: ['Altitude', 'Vertical speed'],
    unit: 'm · m/s',
    src: 'Flight computer state machine',
  ),
  TileDef(
    id: 'vspeed',
    needs: ['vel'],
    title: 'Vertical speed',
    types: {_K},
    val: (d) => '${f1(d.tel.vel[2], 1)} m/s',
    body: (d) => LineChart(d, keys: const ['vz'], colors: const [VC.lime], sym: true),
    keys: ['vz'],
    labels: ['Vz'],
    unit: 'm/s',
    src: 'Baro + IMU fusion',
    sym: true,
  ),
  TileDef(
    id: 'pyro',
    title: 'Pyro channels',
    types: {_K},
    val: (d) => '${d.tel.pyro.where((x) => x == 'OK').length} armed',
    body: (d) => PyroBody(d),
    keys: ['volt'],
    labels: ['Pyro bus'],
    unit: 'V',
    src: '4-channel pyro board',
  ),
  // bench
  TileDef(
    id: 'thrust',
    needs: ['thrust'],
    title: 'Thrust',
    types: {_D, _R, _A, _K, _B, _G},
    val: (d) => '${d.tel.thrust.toStringAsFixed(2)} N',
    body: (d) => LineChart(d, keys: const ['thr'], colors: const [VC.lime]),
    keys: ['thr'],
    labels: ['Thrust'],
    unit: 'N',
    src: 'Load cell · HX711 · 80 Hz',
  ),
  TileDef(
    id: 'rpm',
    needs: ['rpm'],
    title: 'RPM',
    types: {_D, _R, _A, _K, _B, _G},
    val: (d) => '${d.tel.rpm.round()}',
    body: (d) => LineChart(d, keys: const ['rpm'], colors: const [VC.white]),
    keys: ['rpm'],
    labels: ['RPM'],
    unit: 'rpm',
    src: 'Optical tachometer',
  ),
  TileDef(
    id: 'torque',
    needs: ['thrust'],
    title: 'Torque',
    types: {_D, _R, _A, _K, _B, _G},
    val: (d) => '${d.tel.torque.toStringAsFixed(3)} N·m',
    body: (d) => LineChart(d, keys: const ['tq'], colors: const [VC.info]),
    keys: ['tq'],
    labels: ['Torque'],
    unit: 'N·m',
    src: 'Reaction torque cell',
  ),
  TileDef(
    id: 'temp',
    needs: ['temp'],
    title: 'Motor temp',
    types: {_D, _R, _A, _K, _B, _G},
    val: (d) => '${d.tel.temp.toStringAsFixed(1)} °C',
    body: (d) => LineChart(d, keys: const ['tmp'], colors: const [VC.warn]),
    keys: ['tmp'],
    labels: ['Stator'],
    unit: '°C',
    src: 'NTC thermistor',
  ),
  TileDef(
    id: 'elec',
    needs: ['bat'],
    title: 'Current',
    types: {_B},
    val: (d) => '${d.tel.power.toStringAsFixed(0)} W',
    body: (d) => LineChart(d, keys: const ['cur'], colors: const [VC.info]),
    keys: ['cur', 'pw'],
    labels: ['Current', 'Power'],
    unit: 'A · W',
    src: 'Shunt · INA228',
  ),
];

/// Tiles declared by the device with `chan` messages.
List<TileDef> customTiles(Dash d) => [
  for (final c in d.channels[d.deviceId] ?? const <ChannelDef>[])
    TileDef(
      id: 'c:${c.id}',
      title: c.id.replaceAll('_', ' '),
      types: DeviceKind.values.toSet(),
      val: (d) {
        final v = d.tel.custom[c.id];
        return v == null || v.isEmpty ? '—' : '${v.first.toStringAsFixed(1)} ${c.unit}';
      },
      body: (d) => LineChart(d, keys: [for (var i = 0; i < c.axes.length; i++) 'c:${c.id}:$i'], colors: c.axes.length > 3 ? j6 : axisColors),
      keys: [for (var i = 0; i < c.axes.length; i++) 'c:${c.id}:$i'],
      labels: c.axes,
      colors: c.axes.length > 3 ? j6 : null,
      unit: c.unit,
      src: 'Custom channel · ${c.hz.toStringAsFixed(0)} Hz',
    ),
];

/// What scripts show for the device: pictures and charts (dev.show,
/// dev.chart), and plotted series (dev.plot) drawn over time like telemetry.
List<TileDef> scriptTiles(Dash d) => [
  for (final v in d.focus?.views.values ?? const <ScriptView>[])
    if (v.kind == 'plot')
      TileDef(
        id: v.tileId,
        title: v.name,
        types: DeviceKind.values.toSet(),
        val: (d) {
          final x = d.tel.custom['script:${v.name}'];
          return x == null || x.isEmpty ? '—' : x.map((e) => e.toStringAsFixed(e.abs() < 10 ? 2 : 1)).join(' · ');
        },
        body: (d) => LineChart(
          d,
          keys: [for (var i = 0; i < v.labels.length; i++) 'c:script:${v.name}:$i'],
          labels: v.labels,
          colors: v.labels.length > 3 ? j6 : const [VC.lime, VC.info, VC.warn],
        ),
        keys: [for (var i = 0; i < v.labels.length; i++) 'c:script:${v.name}:$i'],
        labels: v.labels,
        colors: v.labels.length > 3 ? j6 : const [VC.lime, VC.info, VC.warn],
        unit: '',
        src: 'Script · ${v.script}',
      )
    else
      TileDef(
        id: v.tileId,
        title: v.name,
        types: DeviceKind.values.toSet(),
        val: (d) => v.ended
            ? 'ended'
            : v.kind == 'picture'
            ? '${v.width}×${v.height} · ${v.fps.toStringAsFixed(0)} fps'
            : v.series.length == 1
            ? '${v.chart} · ${v.series.values.first.length} points'
            : '${v.chart} · ${v.series.length} series',
        body: (d) => ScriptViewBody(v),
        keys: const [],
        labels: const [],
        unit: '',
        src: 'Script · ${v.script}',
      ),
];

List<TileDef> tilesFor(Dash d) => [
  ...tiles.where((t) => t.types.contains(d.kind) && !t.hudOnly && (t.needs.isEmpty || t.needs.any(d.tel.seen.contains)) && (t.when?.call(d) ?? true)),
  ...customTiles(d),
  ...scriptTiles(d),
];
List<TileDef> allTiles(Dash d) => [tiles.first, ...tilesFor(d)];
TileDef? tileById(Dash d, String id) => [...tiles, ...customTiles(d), ...scriptTiles(d)].where((t) => t.id == id).firstOrNull;

const phases = ['PAD', 'COUNT', 'BOOST', 'COAST', 'DROGUE', 'MAIN', 'LANDED'];
const phaseLabel = {'PAD': 'On pad', 'COUNT': 'Countdown', 'BOOST': 'Boost', 'COAST': 'Coast', 'DROGUE': 'Drogue', 'MAIN': 'Main', 'LANDED': 'Landed'};

class ReadoutBody extends StatelessWidget {
  const ReadoutBody(this.d, {super.key});
  final Dash d;
  @override
  Widget build(BuildContext context) {
    final s = d.tel;
    final rd = switch (d.kind) {
      DeviceKind.arm => [
        ['Tool Z', s.armPts[5][2].toStringAsFixed(3), 'm'],
        ['Reach', hypot2(s.armPts[5][0], s.armPts[5][1]).toStringAsFixed(2), 'm'],
        ['Gripper', (s.gripper * 100).toStringAsFixed(0), '%'],
        ['Current', s.current.toStringAsFixed(1), 'A'],
      ],
      DeviceKind.rocket => [
        ['Alt', s.pos[2].toStringAsFixed(0), 'm'],
        ['Vz', f1(s.vel[2], 0), 'm/s'],
        ['Max', s.maxAlt.toStringAsFixed(0), 'm'],
        ['Range', s.range.toStringAsFixed(0), 'm'],
      ],
      DeviceKind.bench => [
        ['Thrust', s.thrust.toStringAsFixed(1), 'N'],
        ['RPM', '${s.rpm.round()}', ''],
        ['Power', s.power.toStringAsFixed(0), 'W'],
        ['Temp', s.temp.toStringAsFixed(0), '°C'],
      ],
      _ => [
        ['Alt', s.pos[2].toStringAsFixed(1), 'm'],
        ['Speed', s.speed.toStringAsFixed(1), 'm/s'],
        ['Hdg', s.heading.round().toString().padLeft(3, '0'), '°'],
        ['Home', s.range.toStringAsFixed(0), 'm'],
      ],
    };
    return LayoutBuilder(
      builder: (context, c) {
        final cols = math.max(1, math.min(4, (c.maxWidth / 64).floor()));
        return Center(
          child: Wrap(
            spacing: 16,
            runSpacing: 10,
            children: [for (final r in rd) SizedBox(width: (c.maxWidth - 16 * (cols - 1)) / cols - .5, child: Readout(r[0], r[1], r[2]))],
          ),
        );
      },
    );
  }
}

class FlightPhases extends StatelessWidget {
  const FlightPhases(this.d, {super.key});
  final Dash d;
  @override
  Widget build(BuildContext context) {
    final s = d.tel, cur = phases.indexOf(s.mode);
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var i = 0; i < phases.length; i++)
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i == cur
                      ? K.accent
                      : i < cur
                      ? K.textPrimary
                      : Colors.transparent,
                  border: Border.all(color: i <= cur ? Colors.transparent : K.ink300),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                phases[i],
                style: KText.mono(
                  10,
                  color: i == cur
                      ? K.textAccent
                      : i < cur
                      ? K.textPrimary
                      : K.textFaint,
                  tracking: .1,
                ),
              ),
              if (i == cur) ...[
                const Spacer(),
                Text(
                  phases[i] == 'COUNT' ? 'T−${math.max(0, s.countdown).toStringAsFixed(1)}' : '+${s.phaseT.toStringAsFixed(1)}s',
                  style: KText.mono(10, color: K.textSecondary, tracking: .1),
                ),
              ],
            ],
          ),
      ],
    );
  }
}

const pyroNames = ['Drogue', 'Main', 'Airstart', 'Spare'];

class PyroBody extends StatelessWidget {
  const PyroBody(this.d, {super.key});
  final Dash d;
  @override
  Widget build(BuildContext context) {
    final py = d.tel.pyro;
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        for (var i = 0; i < 4; i++)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MonoLabel(pyroNames[i], size: 10),
              KBadge(
                py[i] == 'OK'
                    ? 'Continuity'
                    : py[i] == 'FIRED'
                    ? 'Fired'
                    : 'Not wired',
                tone: py[i] == 'FIRED'
                    ? Tone.accent
                    : py[i] == 'OK'
                    ? Tone.positive
                    : Tone.info,
                dot: py[i] != '—',
              ),
            ],
          ),
      ],
    );
  }
}

/// Default HUD widget placement on a 12×12 grid, per device kind and screen class.
List<HudItem> hudDefault(DeviceKind type, String cls) {
  final p = cls == 'phone';
  HudItem h(String id, int x, int y, int w, int hh) => HudItem(id, x, y, w, hh);
  // A phone held sideways: about 23 pt per grid row, so tiles are four rows
  // tall (about 90 pt, what a title and a chart need), in the corners, with
  // the middle left to the 3D view.
  if (cls == 'short') {
    return switch (type) {
      DeviceKind.rocket => [h('readout', 0, 0, 5, 4), h('phase', 9, 0, 3, 4), h('alt', 0, 8, 4, 4), h('pyro', 9, 8, 3, 4)],
      DeviceKind.bench => [h('readout', 0, 0, 5, 4), h('thrust', 0, 8, 5, 4), h('temp', 9, 8, 3, 4)],
      DeviceKind.arm => [h('readout', 0, 0, 5, 4), h('joints', 8, 0, 4, 8), h('power', 0, 8, 4, 4)],
      DeviceKind.rover => [h('readout', 0, 0, 5, 4), h('gps', 9, 0, 3, 4), h('attitude', 0, 8, 3, 4), h('lidar', 9, 8, 3, 4)],
      DeviceKind.drone => [h('readout', 0, 0, 5, 4), h('gps', 9, 0, 3, 4), h('attitude', 0, 8, 3, 4), h('alt', 9, 8, 3, 4)],
      DeviceKind.generic => [h('readout', 0, 0, 5, 4), h('attitude', 0, 8, 3, 4), h('power', 9, 8, 3, 4)],
    };
  }
  switch (type) {
    case DeviceKind.rocket:
      return p
          ? [h('readout', 0, 0, 12, 2), h('phase', 0, 8, 5, 4), h('alt', 5, 9, 7, 3)]
          : [h('readout', 0, 0, 5, 2), h('phase', 10, 0, 2, 4), h('alt', 0, 9, 4, 3), h('accel', 4, 10, 4, 2), h('pyro', 10, 9, 2, 3)];
    case DeviceKind.bench:
      return p
          ? [h('readout', 0, 0, 12, 2), h('thrust', 0, 8, 12, 4)]
          : [h('readout', 0, 0, 5, 2), h('thrust', 0, 8, 4, 4), h('rpm', 4, 9, 4, 3), h('temp', 10, 9, 2, 3)];
    case DeviceKind.arm:
      return p ? [h('readout', 0, 0, 12, 2), h('joints', 0, 8, 12, 4)] : [h('readout', 0, 0, 5, 2), h('joints', 0, 8, 3, 4), h('power', 3, 9, 4, 3)];
    case DeviceKind.rover:
      return p
          ? [h('readout', 0, 0, 12, 2), h('attitude', 0, 9, 6, 3), h('lidar', 6, 9, 6, 3)]
          : [h('readout', 0, 0, 5, 2), h('gps', 9, 0, 3, 4), h('attitude', 0, 9, 2, 3), h('gyro', 3, 10, 5, 2), h('lidar', 10, 9, 2, 3)];
    case DeviceKind.drone:
      return p
          ? [h('readout', 0, 0, 12, 2), h('attitude', 0, 9, 6, 3), h('alt', 6, 9, 6, 3)]
          : [h('readout', 0, 0, 5, 2), h('gps', 9, 0, 3, 4), h('attitude', 0, 9, 2, 3), h('accel', 3, 10, 5, 2), h('alt', 10, 9, 2, 3)];
    case DeviceKind.generic:
      return p
          ? [h('readout', 0, 0, 12, 2), h('attitude', 0, 9, 6, 3), h('power', 6, 9, 6, 3)]
          : [h('readout', 0, 0, 5, 2), h('attitude', 0, 9, 2, 3), h('accel', 3, 10, 5, 2), h('power', 10, 9, 2, 3)];
  }
}

/// Wall tile / replay tile: title + value header over a live body.
class Tile extends StatelessWidget {
  const Tile(this.d, this.tile, {super.key, this.onOpen, this.height, this.compact = false});
  final Dash d;
  final TileDef tile;
  final VoidCallback? onOpen;
  final double? height;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onOpen,
      cursor: onOpen == null ? SystemMouseCursors.basic : null,
      builder: (_, hover, _) => AnimatedContainer(
        duration: K.durFast,
        decoration: BoxDecoration(
          color: hover ? K.surfaceHover : K.surfaceRaised,
          border: Border.all(color: hover ? K.borderSubtle : K.borderHairline),
          borderRadius: BorderRadius.circular(K.radiusCard),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: compact ? const EdgeInsets.fromLTRB(12, 10, 12, 0) : const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Row(
                children: [
                  MonoLabel(tile.titleFor(d.kind), maxLines: 1),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(tile.val(d), textAlign: TextAlign.right, maxLines: 1, overflow: TextOverflow.ellipsis, style: KText.mono(12)),
                  ),
                ],
              ),
            ),
            if (height != null)
              SizedBox(
                height: height,
                child: Padding(padding: compact ? const EdgeInsets.fromLTRB(12, 8, 12, 10) : const EdgeInsets.fromLTRB(14, 10, 14, 12), child: tile.body(d)),
              )
            else
              Expanded(
                child: Padding(padding: compact ? const EdgeInsets.fromLTRB(12, 8, 12, 10) : const EdgeInsets.fromLTRB(14, 10, 14, 12), child: tile.body(d)),
              ),
          ],
        ),
      ),
    );
  }
}

/// Every connected device: mode, battery, link and alerts. Tap one to show it.
class FleetTile extends StatelessWidget {
  const FleetTile(this.d, {super.key});
  final Dash d;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.symmetric(vertical: 4),
    children: [
      for (final l in d.links.values)
        Pressable(
          onTap: () => d.focusDevice(l.id),
          builder: (_, h, _) {
            final t = l.tel, lost = l.linkLostFor > 0, alerts = l.alerts.shown.length, on = l.id == d.deviceId;
            return Container(
              color: on ? K.surfaceAccentSoft : (h ? K.whiteA06 : Colors.transparent),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: fleetColor(d, l.id), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(l.info.name, style: KText.bodySm, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 8),
                  MonoLabel(
                    [if (lost) 'LOST' else t.mode, if (t.seen.contains('bat')) '${t.battery.round()}%', if (alerts > 0) '⚠ $alerts'].join(' · '),
                    size: 9,
                    color: lost || t.estop ? K.negative : (alerts > 0 ? K.warning : K.textSecondary),
                  ),
                ],
              ),
            );
          },
        ),
    ],
  );
}
