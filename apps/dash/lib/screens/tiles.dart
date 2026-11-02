import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../core/dash.dart';
import '../core/model.dart';
import '../theme/tokens.dart';
import '../ui/components.dart';
import '../video/video_view.dart';
import '../viz/map_view.dart';
import '../viz/prox.dart';
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

/// The built-in tiles, in the language shown (built once per language).
List<TileDef> get tiles => _tiles[t.localeName] ??= _builtIn();
final _tiles = <String, List<TileDef>>{};

List<TileDef> _builtIn() => [
  TileDef(
    id: 'readout',
    title: t.tileReadouts,
    types: {_D, _R, _A, _K, _B, _G},
    hudOnly: true,
    val: (_) => '',
    body: (d) => ReadoutBody(d),
    keys: ['alt', 'spd'],
    labels: [t.rdAlt, t.rdSpeed],
    unit: '',
    src: t.tileSrcFused,
  ),
  TileDef(
    id: 'attitude',
    needs: ['att'],
    title: t.tileAttitude,
    types: {_D, _R, _A, _K, _B, _G},
    val: (d) => 'R ${deg(d.tel.roll)}  P ${deg(d.tel.pitch)}',
    body: (d) => LiveCanvas(AttitudePainter(d)),
    keys: ['gx', 'gy', 'gz'],
    labels: [t.tileRollRate, t.tilePitchRate, t.tileYawRate],
    unit: 'rad/s',
    src: 'IMU · BMI088',
    sym: true,
  ),
  TileDef(
    id: 'accel',
    needs: ['imu'],
    title: t.tileAccelerometer,
    types: {_D, _R, _A, _K, _B, _G},
    tt: {_B: t.tileVibration, _K: t.tileAcc200},
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
    title: t.tileGyroscope,
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
    labels: [t.tileGroundSpeed],
    unit: 'm/s',
    src: 'GNSS',
  ),
  TileDef(
    id: 'alt',
    needs: ['pos'],
    title: t.altitude,
    types: {_D, _K, _G},
    val: (d) => '${d.tel.pos[2].toStringAsFixed(1)} m',
    body: (d) => LineChart(d, keys: const ['alt'], colors: const [VC.lime]),
    keys: ['alt'],
    labels: [t.tileAgl],
    unit: 'm',
    src: t.tileSrcBaroRange,
  ),
  TileDef(
    id: 'radar',
    needs: ['tracks'],
    title: t.tileRadar,
    types: {_D, _R, _A, _K, _B, _G},
    tt: {_A: t.tileSafetyScanner},
    val: (d) => t.tracks(d.tel.targets.length),
    body: (d) => LiveCanvas(RadarPainter(d)),
    keys: ['spd'],
    labels: [t.tileOwnSpeed],
    unit: 'm/s',
    src: t.tileSrcRadar,
  ),
  TileDef(
    id: 'lidar',
    needs: ['pc'],
    title: t.tileLidar,
    types: {_D, _R, _A, _K, _B, _G},
    val: (d) => t.points(d.tel.cloud.length),
    body: (d) => Scene3D(d, view: 'top', interactive: false, label: false, layers: const {'cloud': true, 'grid': true}),
    keys: ['spd'],
    labels: [t.tileOwnSpeed],
    unit: 'm/s',
    src: t.tileSrcLidar,
  ),
  TileDef(
    id: 'joints',
    needs: ['joints'],
    title: t.tileJoints,
    types: {_D, _R, _A, _K, _B, _G},
    val: (_) => t.axes(6),
    body: (d) => LiveCanvas(JointBarsPainter(d)),
    keys: ['j0', 'j1', 'j2', 'j3', 'j4', 'j5'],
    labels: ['J1', 'J2', 'J3', 'J4', 'J5', 'J6'],
    colors: j6,
    unit: 'rad',
    src: t.tileSrcJoints,
    sym: true,
  ),
  TileDef(
    id: 'ft',
    needs: ['ft'],
    title: t.tileForceTorque,
    types: {_D, _R, _A, _K, _B, _G},
    val: (d) => '${f1(d.tel.ft[2], 1)} N',
    body: (d) => LineChart(d, keys: const ['fx', 'fy', 'fz'], sym: true),
    keys: ['fx', 'fy', 'fz'],
    labels: ['Fx', 'Fy', 'Fz'],
    unit: 'N',
    src: t.tileSrcWrist,
    sym: true,
  ),
  TileDef(
    id: 'power',
    needs: ['bat'],
    title: t.rdPower,
    types: {_D, _R, _A, _K, _B, _G},
    val: (d) => d.kind == _A || d.kind == _B ? '${d.tel.current.toStringAsFixed(1)} A' : '${d.tel.battery.round()}%',
    body: (d) => LineChart(d, keys: const ['volt'], colors: const [VC.lime]),
    keys: ['volt', 'cur'],
    labels: [t.tileVoltage, t.rdCurrent],
    unit: 'V · A',
    src: t.tileSrcPower,
  ),
  TileDef(
    id: 'link',
    needs: ['rssi'],
    title: t.statLink,
    types: {_D, _R, _A, _K, _B, _G},
    val: (d) => '${d.tel.rssi.round()} dBm',
    body: (d) => LineChart(d, keys: const ['rssi'], colors: const [VC.info]),
    keys: ['rssi', 'lat'],
    labels: ['RSSI', t.statLatency],
    unit: 'dBm · ms',
    src: t.tileSrcRadio,
  ),
  TileDef(
    id: 'video',
    title: t.tileCamera,
    types: {_D, _R, _A, _K, _B, _G},
    when: (d) => d.video.isNotEmpty,
    val: (d) => d.video.isEmpty ? '' : (d.video.first.label.isEmpty ? d.video.first.id : d.video.first.label),
    body: (d) => VideoView(d, fit: BoxFit.cover, compact: true),
    keys: [],
    labels: [],
    unit: '',
    src: t.tileSrcCamera,
  ),
  TileDef(
    id: 'fleet',
    title: t.fleet,
    types: {_D, _R, _A, _K, _B, _G},
    when: (d) => d.links.length > 1,
    val: (d) => t.connectedCount(d.links.length),
    body: (d) => FleetTile(d),
    keys: [],
    labels: [],
    unit: '',
    src: t.tileSrcFleet,
  ),
  // rocket
  TileDef(
    id: 'phase',
    title: t.flightPhase,
    types: {_K},
    val: (d) => phaseLabel(d.tel.mode),
    body: (d) => FlightPhases(d),
    keys: ['alt', 'vz'],
    labels: [t.altitude, t.tileVerticalSpeed],
    unit: 'm · m/s',
    src: t.tileSrcPhase,
  ),
  TileDef(
    id: 'vspeed',
    needs: ['vel'],
    title: t.tileVerticalSpeed,
    types: {_K},
    val: (d) => '${f1(d.tel.vel[2], 1)} m/s',
    body: (d) => LineChart(d, keys: const ['vz'], colors: const [VC.lime], sym: true),
    keys: ['vz'],
    labels: ['Vz'],
    unit: 'm/s',
    src: t.tileSrcBaroImu,
    sym: true,
  ),
  TileDef(
    id: 'pyro',
    title: t.tilePyro,
    types: {_K},
    val: (d) => t.armedCount(d.tel.pyro.where((x) => x == 'OK').length),
    body: (d) => PyroBody(d),
    keys: ['volt'],
    labels: [t.tilePyroBus],
    unit: 'V',
    src: t.tileSrcPyro,
  ),
  // bench
  TileDef(
    id: 'thrust',
    needs: ['thrust'],
    title: t.rdThrust,
    types: {_D, _R, _A, _K, _B, _G},
    val: (d) => '${d.tel.thrust.toStringAsFixed(2)} N',
    body: (d) => LineChart(d, keys: const ['thr'], colors: const [VC.lime]),
    keys: ['thr'],
    labels: [t.rdThrust],
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
    src: t.tileSrcTacho,
  ),
  TileDef(
    id: 'torque',
    needs: ['thrust'],
    title: t.tileTorque,
    types: {_D, _R, _A, _K, _B, _G},
    val: (d) => '${d.tel.torque.toStringAsFixed(3)} N·m',
    body: (d) => LineChart(d, keys: const ['tq'], colors: const [VC.info]),
    keys: ['tq'],
    labels: [t.tileTorque],
    unit: 'N·m',
    src: t.tileSrcTorque,
  ),
  TileDef(
    id: 'temp',
    needs: ['temp'],
    title: t.tileMotorTemp,
    types: {_D, _R, _A, _K, _B, _G},
    val: (d) => '${d.tel.temp.toStringAsFixed(1)} °C',
    body: (d) => LineChart(d, keys: const ['tmp'], colors: const [VC.warn]),
    keys: ['tmp'],
    labels: [t.tileStator],
    unit: '°C',
    src: t.tileSrcNtc,
  ),
  TileDef(
    id: 'elec',
    needs: ['bat'],
    title: t.rdCurrent,
    types: {_B},
    val: (d) => '${d.tel.power.toStringAsFixed(0)} W',
    body: (d) => LineChart(d, keys: const ['cur'], colors: const [VC.info]),
    keys: ['cur', 'pw'],
    labels: [t.rdCurrent, t.rdPower],
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
      src: t.tileSrcCustom(c.hz.toStringAsFixed(0)),
    ),
];

/// Proximity sensors (the `prox` channel), when the device sends them: the
/// sensors from above, the nearest obstacle as the value, each sensor's
/// distance as a series.
List<TileDef> proxTiles(Dash d) {
  if (!d.tel.seen.contains('prox')) return const [];
  final ps = d.proxSensors;
  return [
    TileDef(
      id: 'prox',
      title: t.tileProximity,
      types: DeviceKind.values.toSet(),
      val: (d) {
        final n = d.nearest;
        if (n != null) return '${n.d.toStringAsFixed(2)} m · ${n.sensor.id.replaceAll('_', ' ')}';
        final down = [
          for (var i = 0; i < d.proxSensors.length && i < d.tel.prox.length; i++)
            if (d.proxSensors[i].down && d.tel.prox[i] >= 0) d.tel.prox[i],
        ];
        return down.isNotEmpty ? '↓ ${down.first.toStringAsFixed(1)} m' : t.proxClear;
      },
      body: (d) => LiveCanvas(ProxPainter(d)),
      keys: [for (var i = 0; i < ps.length; i++) 'prox:$i'],
      labels: [for (final p in ps) p.id.replaceAll('_', ' ')],
      colors: ps.length > 3 ? j6 : null,
      unit: 'm',
      src: ps.isEmpty ? t.tileSrcProx : {for (final p in ps) p.kind.isEmpty ? t.tileProximity.toLowerCase() : p.kind}.join(' · '),
    ),
  ];
}

/// What scripts show for the device: pictures and charts (dev.show,
/// dev.chart), and plotted series (dev.plot) drawn over time like telemetry.
List<TileDef> scriptTiles(Dash d) => [
  for (final v in d.scriptViews.values)
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
        src: '${t.tagScript} · ${v.script}',
      )
    else
      TileDef(
        id: v.tileId,
        title: v.name,
        types: DeviceKind.values.toSet(),
        val: (d) => v.ended
            ? t.viewEnded
            : v.kind == 'picture'
            ? '${v.width}×${v.height} · ${v.fps.toStringAsFixed(0)} fps'
            : v.series.length == 1
            ? '${v.chart} · ${t.points(v.series.values.first.length)}'
            : '${v.chart} · ${t.series(v.series.length)}',
        body: (d) => ScriptViewBody(v),
        keys: const [],
        labels: const [],
        unit: '',
        src: '${t.tagScript} · ${v.script}',
      ),
];

List<TileDef> tilesFor(Dash d) => [
  ...tiles.where((t) => t.types.contains(d.kind) && !t.hudOnly && (t.needs.isEmpty || t.needs.any(d.tel.seen.contains)) && (t.when?.call(d) ?? true)),
  ...customTiles(d),
  ...proxTiles(d),
  ...scriptTiles(d),
];
List<TileDef> allTiles(Dash d) => [tiles.first, ...tilesFor(d)];
TileDef? tileById(Dash d, String id) => [...tiles, ...customTiles(d), ...proxTiles(d), ...scriptTiles(d)].where((t) => t.id == id).firstOrNull;

const phases = ['PAD', 'COUNT', 'BOOST', 'COAST', 'DROGUE', 'MAIN', 'LANDED'];

/// A flight phase as shown, in the language shown.
String phaseLabel(String ph) => switch (ph) {
  'PAD' => t.phasePad,
  'COUNT' => t.phaseCount,
  'BOOST' => t.phaseBoost,
  'COAST' => t.phaseCoast,
  'DROGUE' => t.phaseDrogue,
  'MAIN' => t.phaseMain,
  'LANDED' => t.phaseLanded,
  _ => ph,
};

class ReadoutBody extends StatelessWidget {
  const ReadoutBody(this.d, {super.key});
  final Dash d;
  @override
  Widget build(BuildContext context) {
    final s = d.tel;
    final rd = switch (d.kind) {
      DeviceKind.arm => [
        [t.rdToolZ, s.armPts[5][2].toStringAsFixed(3), 'm'],
        [t.rdReach, hypot2(s.armPts[5][0], s.armPts[5][1]).toStringAsFixed(2), 'm'],
        [t.gripper, (s.gripper * 100).toStringAsFixed(0), '%'],
        [t.rdCurrent, s.current.toStringAsFixed(1), 'A'],
      ],
      DeviceKind.rocket => [
        [t.rdAlt, s.pos[2].toStringAsFixed(0), 'm'],
        [t.rdVz, f1(s.vel[2], 0), 'm/s'],
        [t.rdMax, s.maxAlt.toStringAsFixed(0), 'm'],
        [t.rdRange, s.range.toStringAsFixed(0), 'm'],
      ],
      DeviceKind.bench => [
        [t.rdThrust, s.thrust.toStringAsFixed(1), 'N'],
        [t.rdRpm, '${s.rpm.round()}', ''],
        [t.rdPower, s.power.toStringAsFixed(0), 'W'],
        [t.rdTemp, s.temp.toStringAsFixed(0), '°C'],
      ],
      _ => [
        [t.rdAlt, s.pos[2].toStringAsFixed(1), 'm'],
        [t.rdSpeed, s.speed.toStringAsFixed(1), 'm/s'],
        [t.rdHdg, s.heading.round().toString().padLeft(3, '0'), '°'],
        [t.rdHome, s.range.toStringAsFixed(0), 'm'],
      ],
    };
    return LayoutBuilder(
      builder: (context, c) {
        final cols = math.max(1, math.min(4, (c.maxWidth / 64).floor()));
        // Too short for a label over a value (a small phone): one line.
        if (c.maxHeight < 40) {
          return FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              spacing: 14,
              children: [
                for (final r in rd)
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: '${r[0].toUpperCase()} ', style: KText.label(size: 9)),
                        TextSpan(
                          text: r[1],
                          style: KText.mono(13, color: K.textPrimary),
                        ),
                        if (r[2].isNotEmpty)
                          TextSpan(
                            text: ' ${r[2]}',
                            style: KText.mono(10, color: K.textMuted),
                          ),
                      ],
                    ),
                    maxLines: 1,
                  ),
              ],
            ),
          );
        }
        return FitDown(
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
    return LayoutBuilder(
      builder: (_, c) {
        final rows = Column(
          mainAxisSize: c.maxHeight < phases.length * 14 ? MainAxisSize.min : MainAxisSize.max,
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
        return c.maxHeight < phases.length * 14 ? FitDown(alignment: Alignment.topLeft, child: rows) : rows;
      },
    );
  }
}

/// The rocket's pyro channels, in order, as shown.
List<String> get pyroNames => [t.pyroDrogue, t.pyroMain, t.pyroAirstart, t.pyroSpare];

class PyroBody extends StatelessWidget {
  const PyroBody(this.d, {super.key});
  final Dash d;
  @override
  Widget build(BuildContext context) {
    final py = d.tel.pyro;
    return LayoutBuilder(
      builder: (_, c) {
        final tight = c.maxHeight < 4 * 22;
        final rows = Column(
          mainAxisSize: tight ? MainAxisSize.min : MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (var i = 0; i < 4; i++)
              Row(
                children: [
                  Expanded(child: MonoLabel(pyroNames[i], size: 10, maxLines: 1)),
                  const SizedBox(width: 8),
                  Flexible(
                    flex: 3,
                    child: KBadge(
                      py[i] == 'OK'
                          ? t.pyroContinuity
                          : py[i] == 'FIRED'
                          ? t.pyroFired
                          : t.pyroNotWired,
                      tone: py[i] == 'FIRED'
                          ? Tone.accent
                          : py[i] == 'OK'
                          ? Tone.positive
                          : Tone.info,
                      dot: py[i] != '—',
                    ),
                  ),
                ],
              ),
          ],
        );
        return tight ? FitDown(alignment: Alignment.topLeft, child: rows) : rows;
      },
    );
  }
}

/// Default HUD widget placement on a 12×12 grid, per device kind and screen class.
List<HudItem> hudDefault(DeviceKind type, String cls) {
  final p = cls == 'phone' || cls == 'portrait';
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
                  // The title gives way to the value only down to half the row.
                  Flexible(child: MonoLabel(tile.titleFor(d.kind), maxLines: 1)),
                  const SizedBox(width: 8),
                  Flexible(
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
            final tel = l.tel, lost = l.linkLostFor > 0, alerts = l.alerts.shown.length, on = l.id == d.deviceId;
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
                  Flexible(
                    child: MonoLabel(
                      [
                        if (lost) t.statLost.toUpperCase() else tel.mode,
                        if (tel.seen.contains('bat')) '${tel.battery.round()}%',
                        if (alerts > 0) '⚠ $alerts',
                      ].join(' · '),
                      size: 9,
                      maxLines: 1,
                      color: lost || tel.estop ? K.negative : (alerts > 0 ? K.warning : K.textSecondary),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
    ],
  );
}
