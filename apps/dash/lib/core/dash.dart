import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../link/ble_transport.dart';
import '../link/board_discovery.dart';
import '../link/bytes.dart';
import '../link/mavlink_adapter.dart';
import '../link/msp.dart';
import '../link/tello.dart';
import '../link/discovery.dart';
import '../link/protocol.dart';
import '../link/radio.dart';
import '../link/session.dart';
import '../link/transport.dart';
import '../link/serial_io.dart';
import '../link/udp_io.dart';
import '../sim/environment.dart';
import '../sim/sim_device.dart';
import '../video/video_hub.dart';
import '../video/video_rec.dart';
import 'alerts.dart';
import 'compat.dart';
import 'device_link.dart';
import 'gamepad.dart';
import 'log_import.dart';
import 'model.dart';
import '../mcp/mcp_server.dart';
import '../scripts/script_hub.dart';
import '../scripts/script_runner.dart' show ScriptState;
import '../scripts/views.dart';
import 'sequence.dart';
import 'store.dart';
import 'telemetry.dart';
import 'updater.dart';
import 'updater_install.dart' show beforeUpdateQuit;

class Settings {
  String control = 'joysticks'; // joysticks | sliders | tilt
  bool invertY = false;
  String failsafe = 'HOLD';
  bool haptics = true;
  int rateHz = 30;

  /// Map tiles: osm | topo | custom | none.
  /// dark, outdoors, satellite (Mapbox), custom or none.
  String mapTiles = 'dark';

  /// The user's own Mapbox token, instead of the app's.
  String mapboxToken = '';

  /// URL template for custom tiles, `https://…/{z}/{x}/{y}.png`.
  String mapUrl = '';

  /// Credit line the custom tile provider requires.
  String mapAttribution = '';

  /// Keep the device's camera with recordings, at most this many frames a second.
  bool recordVideo = true;
  int videoFps = 10;

  Map<String, dynamic> toJson() => {
    'control': control,
    'invertY': invertY,
    'failsafe': failsafe,
    'haptics': haptics,
    'rateHz': rateHz,
    'mapTiles': mapTiles,
    'mapboxToken': mapboxToken,
    'mapUrl': mapUrl,
    'mapAttribution': mapAttribution,
    'recordVideo': recordVideo,
    'videoFps': videoFps,
  };
  void load(Map? j) {
    if (j == null) return;
    control = j['control'] ?? control;
    invertY = j['invertY'] ?? invertY;
    failsafe = j['failsafe'] ?? failsafe;
    haptics = j['haptics'] ?? haptics;
    rateHz = j['rateHz'] ?? rateHz;
    // OpenStreetMap and OpenTopoMap went: their closest Mapbox styles.
    mapTiles = const {'osm': 'dark', 'topo': 'outdoors'}[j['mapTiles']] ?? j['mapTiles'] ?? mapTiles;
    mapboxToken = j['mapboxToken'] ?? mapboxToken;
    mapUrl = j['mapUrl'] ?? mapUrl;
    mapAttribution = j['mapAttribution'] ?? mapAttribution;
    recordVideo = j['recordVideo'] ?? recordVideo;
    videoFps = j['videoFps'] ?? videoFps;
  }
}

class Recording {
  Recording({
    required this.id,
    required this.name,
    required this.deviceId,
    required this.kind,
    required this.deviceName,
    required this.date,
    required this.frames,
    this.cloud = const [],
    this.fresh = false,
    this.demo = false,
    this.startedAt,
    this.video,
    this.group,
    List<RecEvent>? events,
    List<Map<String, dynamic>>? views,
  }) : events = events ?? [],
       views = views ?? [];
  final String id, name, deviceId, deviceName, date;

  /// Wall-clock start of the recording (UTC), when known.
  final DateTime? startedAt;
  final DeviceKind kind;
  final List<Map<String, dynamic>> frames;

  /// The camera recorded with the session: `file` (next to the recording),
  /// `frames`, `label`. Null without video.
  Map<String, dynamic>? video;

  /// Recordings made together (several devices recorded at once) share it.
  final String? group;

  /// What happened while recording: alerts, link losses, STOP.
  final List<RecEvent> events;

  /// What scripts showed while recording (lib/scripts/views.dart): pictures
  /// and charts in files next to it, plots' series names.
  List<Map<String, dynamic>> views;

  /// Where the video file is on this device (set when loaded or recorded),
  /// and the folder of the views' files.
  String? videoPath, filesDir;
  bool get hasVideo => video != null && videoPath != null;
  final List<List<double>> cloud;
  bool fresh;
  final bool demo;

  /// Seconds from the start of frame [i]. Frames carry their time in `t`
  /// (recorded at the telemetry rate); older recordings are 10 Hz without it.
  double timeAt(int i) => (frames[i]['t'] as num?)?.toDouble() ?? i / 10;

  double get dur => frames.isEmpty ? 0 : (frames.last['t'] is num ? timeAt(frames.length - 1) : frames.length / 10);

  /// Average frame rate.
  double get rateHz => frames.length < 2 || dur <= 0 ? 10 : (frames.length - 1) / timeAt(frames.length - 1).clamp(1e-3, double.infinity);

  /// Last frame at or before [t] seconds.
  int frameAt(double t) {
    if (frames.isEmpty) return 0;
    if (frames.first['t'] is! num) return (t * 10).floor().clamp(0, frames.length - 1);
    var lo = 0, hi = frames.length - 1;
    while (lo < hi) {
      final mid = (lo + hi + 1) >> 1;
      if (timeAt(mid) <= t) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    return lo;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'deviceId': deviceId,
    'kind': kind.name,
    'deviceName': deviceName,
    'date': date,
    'frames': frames,
    'cloud': encodePoints(cloud),
    if (startedAt != null) 'startedAt': startedAt!.toUtc().toIso8601String(),
    'video': ?video,
    'group': ?group,
    if (events.isNotEmpty) 'events': [for (final e in events) e.toJson()],
    if (views.isNotEmpty) 'views': views,
  };
  factory Recording.fromJson(Map<String, dynamic> j) => Recording(
    id: j['id'],
    name: j['name'],
    deviceId: j['deviceId'],
    kind: DeviceKind.parse(j['kind']),
    deviceName: j['deviceName'],
    date: j['date'],
    frames: (j['frames'] as List).cast<Map<String, dynamic>>(),
    cloud: j['cloud'] is String ? decodePoints(j['cloud']) : const [],
    startedAt: j['startedAt'] is String ? DateTime.tryParse(j['startedAt']) : null,
    video: (j['video'] as Map?)?.cast<String, dynamic>(),
    group: j['group'] as String?,
    events: [
      for (final e in j['events'] as List? ?? const [])
        if (e is Map) RecEvent.fromJson(e),
    ],
    views: [
      for (final v in j['views'] as List? ?? const [])
        if (v is Map) v.cast<String, dynamic>(),
    ],
  );
}

/// Something that happened during a recording, at [t] seconds.
class RecEvent {
  const RecEvent(this.t, this.kind, this.text, {this.critical = false});

  /// 'alert', 'lost', 'restored' or 'stop'.
  final String kind, text;
  final double t;
  final bool critical;

  Map<String, dynamic> toJson() => {'t': (t * 1000).round() / 1000, 'k': kind, 'x': text, if (critical) 'c': true};
  factory RecEvent.fromJson(Map j) => RecEvent((j['t'] as num?)?.toDouble() ?? 0, '${j['k'] ?? 'alert'}', '${j['x'] ?? ''}', critical: j['c'] == true);
}

class Replay {
  Replay(this.session, this.tel, {this.mates = const []});
  final Recording session;
  final Telemetry tel;

  /// The other devices recorded in the same session, played on the same
  /// clock (their frames are timed from the same start).
  final List<({Recording rec, Telemetry tel})> mates;
  double t = 0, speed = 1;
  bool playing = true;

  /// The whole session: the longest of its recordings.
  double get dur => mates.fold(session.dur, (m, x) => math.max(m, x.rec.dur));
}

/// A device drawn next to the one shown: another connected device, or
/// another device of the replayed session.
typedef Companion = ({String id, String name, Telemetry tel});

class HudItem {
  HudItem(this.id, this.x, this.y, this.w, this.h);
  final String id;
  int x, y, w, h;
  HudItem copy() => HudItem(id, x, y, w, h);
  Map<String, dynamic> toJson() => {'id': id, 'x': x, 'y': y, 'w': w, 'h': h};
  factory HudItem.fromJson(Map j) => HudItem(j['id'], j['x'], j['y'], j['w'], j['h']);
}

String _date(DateTime n) {
  const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  String p(int v) => v.toString().padLeft(2, '0');
  return '${p(n.day)} ${m[n.month - 1]} · ${p(n.hour)}:${p(n.minute)}';
}

/// Simulated devices offered in the pairing dialog, one per kind. They run in
/// the app and speak the real protocol; add only the ones you want.
List<DeviceInfo> simTemplates() => [
  DeviceInfo(
    id: 'kite',
    name: 'Kite',
    kind: DeviceKind.drone,
    model: 'Quadcopter · 1.4 kg',
    battery: 86,
    sensors: ['IMU', 'BARO', 'COMPASS', 'GPS', 'RANGEFINDER', 'CAMERA'],
  ),
  DeviceInfo(
    id: 'mule',
    name: 'Mule',
    kind: DeviceKind.rover,
    model: '4WD ground robot',
    battery: 64,
    sensors: ['IMU', 'GPS', 'WHEEL ODOM', '2D LIDAR', 'CAMERA'],
  ),
  DeviceInfo(id: 'cell', name: 'Cell arm', kind: DeviceKind.arm, model: '6-axis desktop arm · 1 kg payload', sensors: ['JOINT ENCODERS', 'MOTOR CURRENT']),
  DeviceInfo(
    id: 'nova',
    name: 'Nova',
    kind: DeviceKind.rocket,
    model: 'Mid-power rocket · H128 motor',
    sensors: ['IMU 200 G', 'BARO', 'GPS', 'PYRO ×4', 'CAMERA'],
  ),
  DeviceInfo(
    id: 'bench',
    name: 'Thrust bench',
    kind: DeviceKind.bench,
    model: 'Motor test stand · 25 kg load cell',
    sensors: ['LOAD CELL', 'RPM', 'CURRENT', 'TEMP', 'VIBRATION'],
  ),
];

/// App state. The Flutter counterpart of the design's `SIM` object.
class Dash extends ChangeNotifier implements PadTarget {
  Dash({Store? store, this._updater}) : store = store ?? Store();
  final Store store;

  /// In-app updates for the builds published on GitHub (core/updater.dart).
  late final Updater updater = _updater ?? Updater(store);
  final Updater? _updater;

  /// Updating restarts the app, which drops every link; not while armed.
  bool get updateBlocked => links.values.any((l) => l.tel.armed);

  /// Which koebelt/link versions this app works with (compat.json).
  Compat compat = Compat.legacy;

  /// Game controller mapping and the plugin listener.
  /// Python scripts and (later) MCP clients: see scripts/script_hub.dart.
  late final scripts = ScriptHub(this);

  /// AI assistants over MCP (mcp/mcp_server.dart), on the same local server.
  late final mcp = McpServer(this);

  final pad = PadConfig();
  late final padMapper = PadMapper(pad, this);
  late final gamepads = GamepadInput(padMapper);

  final settings = Settings();

  /// Limit alerts (battery, signal, altitude…) and their settings.
  final alertPrefs = AlertPrefs();
  final List<DeviceInfo> devices = [];

  /// Connected devices by id, and the one the screens show and the sticks
  /// drive ([deviceId]). The others keep their sessions, heartbeats (centred
  /// sticks: they hold), alerts, sequences and recordings.
  final Map<String, DeviceLink> links = {};
  String? deviceId, connecting, connectError;

  /// Most devices connected at once (phones manage about 7 BLE links).
  static const maxLinks = 8;
  final Map<String, SimDevice> _sims = {};

  /// A simulated device's simulator, for tests (to place it).
  @visibleForTesting
  SimDevice? simOf(String id) => _sims[id];

  DeviceLink? get focus => deviceId == null ? null : links[deviceId];
  DeviceSession? get session => focus?.session;

  // Shown when nothing is connected, so screens always have something to draw.
  Telemetry _idleTel = Telemetry(DeviceKind.drone);
  final _idleHist = History(), _replayHist = History();
  final List<double> _idleInput = [0, 0, 0, 0];

  Telemetry get liveTel => focus?.tel ?? _idleTel;
  set liveTel(Telemetry t) => focus == null ? _idleTel = t : focus!.tel = t;
  History get hist => replay != null ? _replayHist : focus?.hist ?? _idleHist;
  Replay? replay;
  Telemetry get tel => replay?.tel ?? liveTel;

  DeviceInfo? get device => focus?.info;

  /// The proximity sensors of the device on screen, or of the replayed
  /// recording's device; numbered ones when the device did not say.
  List<ProxSensor> get proxSensors {
    final id = replay?.session.deviceId ?? focus?.info.id;
    final declared = devices.where((x) => x.id == id).firstOrNull?.prox ?? focus?.info.prox ?? const [];
    final n = tel.prox.length;
    return [for (var i = 0; i < n; i++) i < declared.length ? declared[i] : ProxSensor('${i + 1}')];
  }

  /// The nearest thing a proximity sensor sees, or null if none does.
  ({ProxSensor sensor, double d})? get nearest {
    final ps = proxSensors;
    ({ProxSensor sensor, double d})? best;
    for (var i = 0; i < ps.length && i < tel.prox.length; i++) {
      final v = tel.prox[i];
      if (v >= 0 && !ps[i].down && (best == null || v < best.d)) best = (sensor: ps[i], d: v);
    }
    return best;
  }

  DeviceKind get kind => replay?.session.kind ?? device?.kind ?? DeviceKind.generic;
  bool get hasDevice => focus != null;

  /// True when what is on screen does not come from real hardware.
  bool get simulated => replay?.session.demo ?? device?.simulated ?? false;
  String get deviceName => replay?.session.deviceName ?? device?.name ?? 'the device';

  // control input (the focused device)
  List<double> get input => focus?.input ?? _idleInput;
  List<double> get jog => focus?.jog ?? List.filled(6, 0);
  set jog(List<double> v) => focus?.jog = v;
  double get speed => focus?.speed ?? .5;

  /// Arms: what the controller sticks move ('Joint' or 'Cartesian', the
  /// tabs of the arm panel), and whether the right stick is on the wrist.
  String armFrame = 'Joint';
  bool armWrist = false;
  List<double> _padCart = const [0, 0, 0];

  // link health (the focused device)
  double get linkTest => focus?.linkTest ?? 0;
  double get linkRestored => focus?.linkRestored ?? 0;
  double get latency => session?.latency ?? 0;

  /// Seconds since the focused device's link was lost, 0 when healthy.
  double get linkLostFor => replay != null ? 0 : focus?.linkLostFor ?? 0;

  /// Rates for slow links; null for fast links. See [linkRatesFor].
  static ({int ctlHz, int tlmHz})? linkRates(DeviceInfo d) => linkRatesFor(d);

  /// Radio profile of the open link, null for Wi-Fi, BLE, USB and simulators.
  RadioModule? get radio => device?.transport == TransportKind.radio ? radioModule(device!.radio) : null;

  /// False on telemetry-only links (LoRa): sticks, modes and commands do not
  /// reach the device. STOP still does (protocol/PROTOCOL.md, "Radio links").
  bool get canControl => replay == null && (session?.controls ?? true);

  /// Camera streams the focused device declared.
  List<VideoStream> get video => focus?.video ?? const [];
  final videoHub = VideoHub();

  /// The feed for a declared stream (shared connection).
  VideoFeed videoFeed(VideoStream s, [DeviceInfo? on]) => videoHub.feed(s, on ?? device);

  bool get linkLost => linkLostFor > 0;

  /// Limit alerts of the focused device.
  AlertMonitor get alerts => focus?.alerts ?? _idleAlerts;
  final _idleAlerts = AlertMonitor();

  bool get estopAck => focus?.estopAck ?? false;

  /// Commanded bench throttle (0–1); the device reports only the output.
  double get benchThrottle => focus?.benchThrottle ?? 0;
  set benchThrottle(double v) => focus?.benchThrottle = v;

  /// Public notify for UI-owned state (layout, layers, replay seek).
  void emit() => notifyListeners();

  // params
  final Map<String, List<ParamGroup>> paramGroups = {};
  final Map<String, Map<String, double>> paramDev = {}, paramDraft = {};
  final Map<String, String> paramWritten = {};
  bool get paramWriting => focus?.paramWriting ?? false;
  String? get fwVersion => focus?.fwVersion;

  // custom channels by device
  final Map<String, List<ChannelDef>> channels = {};
  List<Msg> get logs => focus?.logs ?? const [];

  // recording: every connected device, from one clock
  bool recording = false;
  double recStart = 0;
  final _recClock = Stopwatch();
  Recording? lastSaved;
  final List<Recording> sessions = [];

  // ui state
  String layout = 'hud';

  /// Main view of the Live screen (chase, orbit, top, map, cam) and the
  /// background of the drive screen.
  String liveView = 'chase', controlView = 'chase';
  Map<String, bool> layers = {'cloud': true, 'trail': true, 'grid': true, 'radar': true};
  String platform = 'arduino';
  Map<String, List<HudItem>> hud = {};

  // pairing
  late String pairCode = _newCode();
  DateTime pairExpires = DateTime.now().add(const Duration(minutes: 10));
  final Map<String, Found> found = {};
  LanDiscovery? _lan;
  BleDiscovery? _ble;
  MavlinkUdpDiscovery? _mav;
  TelloDiscovery? _tello;
  UsbBoardScanner? _usb;
  int _scanners = 0;

  // sequences
  final Map<String, List<Sequence>> sequences = {};

  /// The focused device's sequence run.
  SequenceRunner? get runner => focus?.runner;

  /// Steps the focused device can store and run itself (its `hello` `seq`);
  /// 0 when the app runs sequences step by step.
  int get seqCap => focus?.seqCap ?? 0;

  // clock
  double t = 0;
  double _sampleAcc = 0, _notifyAcc = 0;

  /// Bumped every frame; painters repaint on it.
  final frame = ValueNotifier<int>(0);

  // ------------------------------------------------------------ lifecycle
  Future<void> init() async {
    await store.init();
    compat = await Compat.bundled();
    updater.addListener(notifyListeners);
    beforeUpdateQuit = disconnectAll;
    updater.start();
    settings.load(store.readJson('kdash-settings-v1'));
    pad.load(store.readJson('kdash-pad-v1') as Map?);
    scripts.load();
    mcp.load();
    padMapper.onFreeButton = scripts.onPad;
    alertPrefs.load(store.readJson('kdash-alerts-v1') as Map?);
    gamepads.addListener(notifyListeners);
    unawaited(gamepads.start());
    final hj = store.readJson('kdash-hud-v1');
    if (hj is Map) {
      hud = {
        for (final e in hj.entries) '${e.key}': [for (final i in e.value as List) HudItem.fromJson(i)],
      };
    }
    final sj = store.readJson('kdash-seq-v1');
    if (sj is Map) {
      for (final e in sj.entries) {
        sequences['${e.key}'] = [for (final q in e.value as List) Sequence.fromJson(q)];
      }
    }
    final saved = store.readJson('kdash-devices-v1');
    if (saved is List) {
      for (final j in saved) {
        final d = DeviceInfo.fromJson((j as Map).cast<String, dynamic>());
        if (!devices.any((x) => x.id == d.id)) devices.add(d);
      }
    }
    final dir = await store.recordingsDir();
    for (final r in await store.loadRecordings()) {
      try {
        final rec = Recording.fromJson(r);
        if (rec.video != null && dir != null) rec.videoPath = '$dir/${rec.video!['file']}';
        rec.filesDir = dir;
        sessions.add(rec);
      } catch (_) {}
    }
    sessions.sort((a, b) => b.id.compareTo(a.id));
    notifyListeners();
  }

  bool get hasSamples => sessions.any((s) => s.demo);

  /// Adds three sample recordings made with simulated devices (marked Demo).
  void loadSamples() {
    if (!hasSamples) _seedRecordings();
    notifyListeners();
  }

  void removeSamples() {
    if (replay?.session.demo ?? false) closeReplay();
    sessions.removeWhere((s) => s.demo);
    notifyListeners();
  }

  void _seedRecordings() {
    Recording seed(DeviceKind k, String name, double secs, String date, String id, String dn) => Recording(
      id: 'seed-$name',
      name: name,
      deviceId: id,
      kind: k,
      deviceName: dn,
      date: date,
      frames: SimDevice.record(DeviceInfo(id: id, name: dn, kind: k), secs),
      cloud: genEnv(k),
      demo: true,
    );
    sessions.addAll([
      seed(DeviceKind.drone, 'Survey loop · north field', 48, '28 Sep · 16:42', 'sim-kite', 'Kite'),
      seed(DeviceKind.arm, 'Pick and place · tray 3', 30, '27 Sep · 10:15', 'sim-cell', 'Cell arm'),
      seed(DeviceKind.rocket, 'Launch · H128 · field B', 85, '21 Sep · 11:03', 'sim-nova', 'Nova'),
    ]);
  }

  void _saveDevices() => store.writeJson('kdash-devices-v1', [for (final d in devices) d.toJson()]);
  void saveSettings() => store.writeJson('kdash-settings-v1', settings.toJson());
  void savePad() {
    store.writeJson('kdash-pad-v1', pad.toJson());
    notifyListeners();
  }

  // ------------------------------------------------------------ game controller
  /// True when controller sticks may move the device right now.
  bool get padCanDrive {
    final s = liveTel;
    return hasDevice &&
        replay == null &&
        canControl &&
        !linkLost &&
        s.armed &&
        !s.estop &&
        (kind == DeviceKind.drone || kind == DeviceKind.rover || kind == DeviceKind.arm || kind == DeviceKind.generic);
  }

  @override
  void padAxes(List<double> v) {
    if (!padCanDrive) {
      input.fillRange(0, 4, 0);
      return;
    }
    if (kind == DeviceKind.arm) {
      _padArm(v);
      return;
    }
    final drone = kind != DeviceKind.rover;
    input[0] = v[0];
    input[1] = drone ? v[1] : 0;
    input[2] = drone ? v[2] : 0;
    input[3] = v[3];
    if (input.any((x) => x != 0)) goManual();
  }

  @override
  void padAction(PadAction a) {
    if (a == PadAction.stop && links.isNotEmpty) return emergencyStop(); // also during replays
    if (!hasDevice || replay != null) return;
    final s = liveTel, drone = kind == DeviceKind.drone;
    switch (a) {
      case PadAction.stop:
        emergencyStop();
      case PadAction.arm:
        if (!s.estop && canControl) setArmed(!s.armed);
      case PadAction.manual:
        operatorMode('MANUAL');
      case PadAction.hold:
        operatorMode('HOLD');
      case PadAction.auto:
        // AUTO is dash's while a script drives: give the sticks back to it.
        final l = focus;
        if (l != null) scripts.resume(l);
      case PadAction.rth:
        if (drone) operatorMode('RTH');
      case PadAction.takeoff:
        if (drone && s.armed) operatorMode('TAKEOFF');
      case PadAction.land:
        if (drone) operatorMode('LAND');
      case PadAction.record:
        recording ? stopRec() : startRec();
      case PadAction.slower:
        setSpeed(math.max(.1, ((speed - .1) * 10).roundToDouble() / 10));
      case PadAction.faster:
        setSpeed(math.min(1, ((speed + .1) * 10).roundToDouble() / 10));
      case PadAction.armFrame:
        if (kind == DeviceKind.arm) setArmFrame(armFrame == 'Joint' ? 'Cartesian' : 'Joint');
      case PadAction.armWrist:
        if (kind == DeviceKind.arm) {
          _stopArmJog();
          armWrist = !armWrist;
          notifyListeners();
        }
      case PadAction.nextDevice:
        focusNext();
      case PadAction.gripper:
        if (kind == DeviceKind.arm && s.armed && !s.estop && canControl) cmd('gripper', {'v': s.gripper > .5 ? .1 : .9});
    }
  }

  /// Arm jog from the sticks (lx, ly, rx, ry; up and right positive).
  /// Joint: left stick J1 (base) and J2 (shoulder), right stick J3 and J4,
  /// or J5 and J6 with the wrist toggle. Cartesian: left stick moves the
  /// tool forward / back and left / right, right stick up / down.
  void _padArm(List<double> v) {
    if (v.any((x) => x != 0)) goManual();
    if (armFrame == 'Cartesian') {
      final c = [v[1], -v[0], v[3]];
      if (!listEquals(c, _padCart)) {
        _padCart = c;
        setCart(c);
      }
      return;
    }
    final j = [v[0], v[1], 0.0, 0.0, 0.0, 0.0];
    j[armWrist ? 4 : 2] = v[3];
    j[armWrist ? 5 : 3] = v[2];
    if (listEquals(j, jog)) return;
    jog = j;
    _send({'t': 'jog', 'j': jog});
  }

  /// Switches the arm jog frame (panel tab and controller), stopping any jog.
  void setArmFrame(String f) {
    if (f == armFrame) return;
    _stopArmJog();
    armFrame = f;
    notifyListeners();
  }

  void _stopArmJog() {
    if (jog.any((x) => x != 0)) {
      jog = List.filled(6, 0);
      _send({'t': 'jog', 'j': jog});
    }
    if (_padCart.any((x) => x != 0)) {
      _padCart = const [0, 0, 0];
      setCart(_padCart);
    }
  }

  // ------------------------------------------------------------ frame loop
  void tick(double dt) {
    t += dt;
    // Live poses keep their clocks running even while a replay is shown.
    for (final l in links.values) {
      l.tel.animate(dt);
    }
    replay?.tel.animate(dt);
    if (replay != null) _replayStep(dt);
    for (final l in links.values) {
      _tickLink(l, dt);
    }
    scripts.tick(dt);
    // Frames come with telemetry; a quiet device still gets two a second,
    // so mode changes and gaps stay on the timeline.
    if (recording) {
      for (final l in links.values) {
        if (_recNow - l.recLast > .5) _recFrame(l, force: true);
      }
    }
    _sampleAcc += dt;
    while (_sampleAcc > 1 / 30) {
      for (final l in links.values) {
        l.hist.sample(l.tel, l.session.latency);
        l.tel.sampleTrail();
      }
      if (replay != null) _replayHist.sample(replay!.tel, 0);
      _sampleAcc -= 1 / 30;
    }
    frame.value++;
    _notifyAcc += dt;
    if (_notifyAcc > .1) {
      _notifyAcc = 0;
      notifyListeners();
    }
  }

  void _tickLink(DeviceLink l, double dt) {
    if (l.linkTest > 0) {
      l.linkTest -= dt;
      if (l.linkTest <= 0) {
        l.linkTest = 0;
        l.session.holdHeartbeat = false;
      }
    }
    final lost = l.linkLostFor > 0;
    if (l.wasLost && !lost) {
      l.linkRestored = 2.5;
      _event(l, 'restored', 'Link restored');
      notifyListeners();
    }
    if (!l.wasLost && lost) {
      _alertOut(AlertLevel.critical);
      _event(l, 'lost', 'Link lost', critical: true);
      notifyListeners();
    }
    l.wasLost = lost;
    if (l.linkRestored > 0) {
      l.linkRestored -= dt;
      if (l.linkRestored <= 0) {
        l.linkRestored = 0;
        notifyListeners();
      }
    }
    // Checked 5 times a second, on fresh data only; not while replaying.
    l.alertAcc += dt;
    if (l.alertAcc >= .2) {
      final before = l.alerts.active.keys.toSet();
      if (!lost && replay == null && l.alerts.step(l.alertAcc, l.tel, l.kind, l.session.latency, alertPrefs, _alertOut)) {
        for (final a in l.alerts.active.values) {
          if (!before.contains(a.rule.id)) {
            _event(l, 'alert', '${a.rule.label} · ${a.rule.fmt(a.value)}', critical: a.rule.level == AlertLevel.critical);
          }
        }
        notifyListeners();
      }
      l.alertAcc = 0;
    }
    final r = l.runner;
    if (r != null) {
      final before = (r.state, r.index);
      r.tick(dt);
      if ((r.state, r.index) != before) notifyListeners();
    }
  }

  // ------------------------------------------------------------ connection
  /// Adapter for a board with its own firmware (ArduPilot, PX4, Betaflight,
  /// INAV, Tello), over the device's link.
  Transport boardTransport(DeviceInfo d) {
    if (d.proto == 'tello') return TelloTransport(host: d.address);
    final radio = d.transport == TransportKind.radio ? radioModule(d.radio) : null;
    final ByteLink link;
    if (d.transport == TransportKind.udp) {
      final i = d.address.lastIndexOf(':');
      final host = i > 0 ? d.address.substring(0, i) : d.address;
      final port = i > 0 ? int.tryParse(d.address.substring(i + 1)) ?? 0 : 0;
      link = HubByteLink(host: host, port: port, localPort: mavlinkGcsPort, name: 'Wi-Fi · $host');
    } else {
      link = SerialByteLink(d.address, baud: d.baud ?? radio?.baud ?? 115200, name: radio == null ? 'USB · ${d.address}' : 'Radio · ${radio.name}');
    }
    return d.proto == 'msp' ? MspTransport(link) : MavlinkTransport(link);
  }

  /// Links being opened (state and telemetry can arrive with the hello).
  final Map<String, DeviceLink> _opening = {};

  /// Connects [id] and focuses it. Devices already connected stay connected.
  Future<void> connect(String id) async {
    final d = devices.where((x) => x.id == id).firstOrNull;
    if (d == null || !d.online) return;
    if (replay != null) closeReplay();
    if (links.containsKey(id)) return focusDevice(id);
    if (links.length >= maxLinks) {
      connectError = 'At most $maxLinks devices at once. Disconnect one first.';
      notifyListeners();
      return;
    }
    connecting = id;
    connectError = null;
    notifyListeners();
    final Transport tr;
    if (d.proto != 'koebelt') {
      tr = boardTransport(d);
    } else {
      switch (d.transport) {
        case TransportKind.sim:
          final lt = LoopbackTransport('Simulator');
          (_sims[id] ??= SimDevice(d)).attach(lt);
          tr = lt;
          await Future<void>.delayed(const Duration(milliseconds: 900));
        case TransportKind.udp:
          tr = UdpTransport(d.address);
        case TransportKind.ble:
          tr = BleTransport(d.address, name: d.name, profile: bleProfile(d.module));
        case TransportKind.serial:
          tr = SerialTransport(d.address, baud: d.baud ?? 115200);
        case TransportKind.radio:
          final r = radioModule(d.radio);
          tr = SerialTransport(d.address, baud: d.baud ?? r.baud, radio: r);
      }
    }
    if (connecting != id) return; // cancelled
    final r = linkRates(d);
    final s = DeviceSession(
      tr,
      onMessage: (m) => _onMsg(id, m),
      key: d.key,
      // MSP is a configuration link: no stick heartbeat (STOP still works).
      ctlHz: d.proto == 'msp' ? 0 : r?.ctlHz ?? 20,
      pingEvery: r == null ? const Duration(seconds: 1) : const Duration(seconds: 5),
    );
    // Fresh telemetry before the handshake: state and telemetry can arrive
    // right behind (or, over UDP, ahead of) the hello and must not be lost.
    final l = DeviceLink(d, s, Telemetry(d.kind));
    // A script's sticks, unless the operator moves theirs (takeover).
    s.axes = () => l.drive?.axes(l.input) ?? l.input;
    _opening[id] = l;
    try {
      final h = await s.open();
      if (connecting != id) {
        await s.close();
        return;
      }
      d.online = true;
      if (h['name'] is String) d.name = h['name'];
      if (h['kind'] is String) d.kind = DeviceKind.parse(h['kind']);
      if (h['model'] is String && (h['model'] as String).isNotEmpty) d.model = h['model'];
      if (h['sensors'] is List && (h['sensors'] as List).isNotEmpty) d.sensors = List<String>.from(h['sensors']);
      d.prox = [for (final p in h['prox'] as List? ?? const []) ?ProxSensor.fromJson(p)];
      l.tel.proxDown = [for (final p in d.prox) p.down];
      l.fwVersion = h['fw'] as String?;
      l.seqCap = (h['seq'] as num?)?.toInt() ?? 0;
      // Remembered so an app update can be checked against it (core/compat.dart).
      if (h['lib'] is String) d.lib = h['lib'];
      if (h['v'] is num) d.protocol = (h['v'] as num).toInt();
      l.compatProblem = compat.problem(d.lib, d.protocol);
      l.video = [
        for (final v in (h['video'] as List? ?? const []))
          if (v is Map) VideoStream.fromJson(v),
      ];
      if (l.tel.kind != d.kind) l.tel = Telemetry(d.kind);
      links[id] = l;
      _focus(id);
      s.send({'t': 'rate', 'hz': math.min(settings.rateHz, r?.tlmHz ?? 60)});
      s.send({'t': 'fs', 'action': settings.failsafe, 'ms': 1800});
      s.send({'t': 'speed', 'v': l.speed});
      if (recording) _recStartLink(l);
      _saveDevices();
    } catch (e) {
      connectError = e is TimeoutException ? 'No answer from ${d.name}' : '$e'.replaceFirst('Bad state: ', '');
      await s.close();
      if (d.simulated) _sims[id]?.detach();
    } finally {
      _opening.remove(id);
      if (connecting == id) connecting = null;
      notifyListeners();
    }
  }

  /// Shows [id] on the screens and gives it the sticks. The device that had
  /// them gets centred sticks, so it holds instead of keeping the last input.
  void focusDevice(String id) {
    if (!links.containsKey(id) || id == deviceId) return;
    _focus(id);
    notifyListeners();
  }

  /// Focuses the [i]th connected device (in connection order).
  void focusNth(int i) {
    final ids = links.keys.toList();
    if (i < ids.length) focusDevice(ids[i]);
  }

  /// Focuses the next connected device, round the list.
  void focusNext() {
    final ids = links.keys.toList();
    if (ids.length < 2) return;
    focusDevice(ids[(ids.indexOf(deviceId ?? '') + 1) % ids.length]);
  }

  void _focus(String id) {
    final old = focus;
    if (old != null) {
      old.input.fillRange(0, 4, 0);
      if (old.jog.any((x) => x != 0)) {
        old.jog = List.filled(6, 0);
        old.session.send({'t': 'jog', 'j': old.jog});
      }
      if (_padCart.any((x) => x != 0)) {
        _padCart = const [0, 0, 0];
        old.session.send({'t': 'cart', 'v': _padCart});
      }
    }
    deviceId = id;
  }

  /// Disconnects [id] (the focused device by default). Focus moves to
  /// another connected device, if any.
  Future<void> disconnect({String? id, bool notify = true}) async {
    id ??= deviceId;
    if (connecting != null && (id == null || id == connecting)) connecting = null;
    final l = id == null ? null : links.remove(id);
    if (l == null) {
      if (notify) notifyListeners();
      return;
    }
    if (recording) {
      _recStopLink(l);
      if (links.isEmpty) _endRecording();
    }
    // A sequence running on the device carries on without the app.
    if (!(l.runner?.onDevice ?? false)) l.runner?.stop('Stopped: disconnected');
    videoHub.clearDevice(id!);
    if (deviceId == id) {
      deviceId = links.keys.isEmpty ? null : links.keys.last;
      armWrist = false;
    }
    if (notify) notifyListeners();
    await l.session.close();
    // simulated devices keep running their physics off-line only while
    // attached (unless connected again in the meantime)
    final sim = _sims[id];
    if (sim != null) {
      Timer(const Duration(milliseconds: 100), () {
        if (!links.containsKey(id) && connecting != id) sim.detach();
      });
    }
  }

  Future<void> disconnectAll() async {
    for (final id in links.keys.toList()) {
      await disconnect(id: id, notify: false);
    }
    notifyListeners();
  }

  void _onMsg(String id, Msg m) {
    final l = links[id] ?? _opening[id];
    if (l == null) return;
    if (l.linkTest > 0 && m['t'] != 'pong' && m['t'] != 'tlm' && m['t'] != 'state') return;
    final tel = l.tel;
    switch (m['t']) {
      case 'tlm':
        if (m['d'] is Map) tel.applyTlm((m['d'] as Map).cast<String, dynamic>(), ts: m['ts'] as num?);
        if (recording) _recFrame(l);
        l.info.battery = tel.battery.round();
      case 'state':
        final wasStop = tel.estop;
        tel.applyState(m);
        // Connected: a disarmed device starts in HOLD. An armed one is left
        // as it is (it may be flying, or running a sequence of its own).
        if (!l.modeChecked) {
          l.modeChecked = true;
          if (!tel.armed && !tel.estop && modal(l.kind) && tel.mode != 'HOLD' && !nativeModes(l)) _setMode(l, 'HOLD');
        }
        final run = (m['ext'] as Map?)?['run'];
        if (run is Map) _onRunState(l, run);
        if (tel.estop && !wasStop) l.estopAck = false;
        if (tel.mode == 'IDLE' || tel.mode == 'CUTOFF' || tel.estop) l.benchThrottle = 0;
        notifyListeners();
      case 'pc':
        if (m['d'] is String) tel.addPoints(decodePoints(m['d']));
      case 'tracks':
        if (m['d'] is List) tel.applyTracks(m['d']);
      case 'params':
        // Large tables arrive in several messages flagged `more`; merge them.
        final merged = l.paramsMore
            ? {
                ...m,
                'p': [...l.paramsAcc, ...(m['p'] as List? ?? const [])],
              }
            : m;
        l.paramsMore = m['more'] == true;
        l.paramsAcc = List.of(merged['p'] as List? ?? const []);
        final g = parseParams(merged, l.kind);
        paramGroups[id] = g;
        final vals = {
          for (final gr in g)
            for (final p in gr.params) p.key: p.def,
        };
        paramDev[id] = vals;
        paramDraft[id] = {...vals};
        notifyListeners();
      case 'pack':
        final dev = paramDev[id], dr = paramDraft[id];
        final keys = List<String>.from(m['keys'] ?? const []);
        if (dev != null && dr != null) {
          for (final k in keys) {
            dev[k] = dr[k] ?? dev[k]!;
          }
        }
        l.paramWriting = false;
        final n = DateTime.now();
        paramWritten[id] = '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}:${n.second.toString().padLeft(2, '0')}';
        notifyListeners();
      case 'chan':
        channels[id] = [
          for (final c in (m['ch'] as List? ?? const []))
            ChannelDef('${c['id']}', List<String>.from(c['axes'] ?? const ['value']), '${c['unit'] ?? ''}', numOr(c['hz'], 10)),
        ];
        notifyListeners();
      case 'seqack':
        _onSeqAck(l, m);
      case 'log':
        l.logs.add(m);
        if (l.logs.length > 200) l.logs.removeAt(0);
    }
  }

  // ------------------------------------------------------------ commands
  // Public commands act on the focused device; sequences use the link they run on.
  void _send(Msg m) => _sendTo(focus, m);

  void _sendTo(DeviceLink? l, Msg m) {
    if (replay == null) l?.session.send(m);
  }

  /// For scripts: a message to a given device, mode and arming through the
  /// same paths as the screens, and an event on its recording's timeline.
  void sendTo(DeviceLink l, Msg m) => _sendTo(l, m);
  SequenceHost linkHost(DeviceLink l) => _LinkHost(this, l);
  void scriptEvent(DeviceLink l, String text) => _event(l, 'script', text);

  void setMode(String m) => _setMode(focus, m);

  /// ArduPilot and PX4 keep their own modes: their AUTO runs their stored
  /// mission, and they take dash's sticks only in a stick mode.
  bool nativeModes(DeviceLink l) => l.session.transport is MavlinkTransport;

  /// The kinds that use HOLD, MANUAL and AUTO (rockets and benches have their own).
  static bool modal(DeviceKind k) => k == DeviceKind.drone || k == DeviceKind.rover || k == DeviceKind.arm || k == DeviceKind.generic;

  /// What drives [l] in AUTO: a sequence or a script; null if neither.
  String? automationOf(DeviceLink l) {
    final r = l.runner;
    if (r != null && (r.state == RunState.running || r.state == RunState.paused)) return 'Sequence · ${r.seq.name}';
    final dr = l.drive;
    if (dr != null && !dr.paused) return 'Script · ${dr.conn.name}';
    return null;
  }

  String? get automation => focus == null ? null : automationOf(focus!);

  /// A script runs (started here, on a host, or from outside dash).
  bool get scriptRunning => scripts.runs.any((r) => r.state == ScriptState.running) || scripts.conns.isNotEmpty;

  /// A sequence runs on a connected device (or is paused).
  bool get sequenceRunning => links.values.any((l) => l.runner?.state == RunState.running || l.runner?.state == RunState.paused);

  /// The operator chooses MANUAL or HOLD. During a sequence or a script,
  /// that takes the device back from it first.
  void operatorMode(String m) {
    final l = focus;
    if (l != null) {
      final r = l.runner;
      if (r != null && r.state == RunState.running) r.stop('Stopped: you took control');
      final dr = l.drive;
      if (dr != null && !dr.paused) {
        dr.paused = true;
        scripts.takeover(dr);
      }
    }
    setMode(m);
  }

  void _setMode(DeviceLink? l, String m) {
    final t = l?.tel ?? _idleTel;
    if (t.estop || !(replay == null && (l?.session.controls ?? true))) return;
    _sendTo(l, {'t': 'mode', 'm': m});
    t.mode = m;
    if (m == 'TAKEOFF') t.armed = true;
    notifyListeners();
  }

  void setArmed(bool v) => _setArmed(focus, v);

  void _setArmed(DeviceLink? l, bool v) {
    final t = l?.tel ?? _idleTel;
    _sendTo(l, {'t': 'arm', 'v': v});
    t.armed = v;
    // Armed: in the operator's hands (MANUAL), or a sequence's or a script's
    // if one drives it (AUTO).
    if (v && l != null && modal(l.kind)) _setMode(l, automationOf(l) != null && !nativeModes(l) ? 'AUTO' : 'MANUAL');
    _haptic();
    notifyListeners();
  }

  void goManual() {
    if (runner?.state == RunState.running) runner!.stop('Stopped: manual control');
    final s = liveTel;
    if (s.mode != 'MANUAL' && s.armed && !s.estop) setMode('MANUAL');
  }

  /// STOP: every connected device, at once.
  void emergencyStop() {
    scripts.onStop();
    for (final l in links.values) {
      if (!l.tel.estop) _event(l, 'stop', 'STOP', critical: true);
      l.session.sendStop();
      final s = l.tel;
      s.estop = true;
      s.armed = false;
      s.mode = l.kind == DeviceKind.rocket
          ? (s.mode == 'COUNT' ? 'PAD' : s.mode)
          : l.kind == DeviceKind.bench
          ? 'IDLE'
          : 'HOLD';
      l.input.fillRange(0, 4, 0);
      l.jog = List.filled(6, 0);
      l.benchThrottle = 0;
      l.estopAck = false;
    }
    _haptic(heavy: true);
    notifyListeners();
  }

  /// Clears the stop on every device that is stopped (STOP stops them all).
  /// They stay disarmed.
  void resetStop() {
    for (final l in links.values) {
      if (!l.tel.estop) continue;
      // Like STOP, it reaches the devices during a replay too.
      l.session.send({'t': 'reset'});
      l.tel.estop = false;
      l.estopAck = false;
    }
    notifyListeners();
  }

  void ackStop() {
    focus?.estopAck = true;
    notifyListeners();
  }

  void unackStop() {
    focus?.estopAck = false;
    notifyListeners();
  }

  void cmd(String c, [Map<String, dynamic>? a]) {
    _send({'t': 'cmd', 'c': c, 'a': ?a});
    notifyListeners();
  }

  /// Makes the current position the home point (drones, rovers), or the
  /// current joint angles the home pose (arms). The local frame restarts, so
  /// the trail and the point-cloud map are cleared.
  void setHome() {
    if (kind == DeviceKind.arm) {
      cmd('sethome', {'j': List.of(liveTel.joints)});
      return;
    }
    cmd('sethome');
    liveTel.resetEnvironment();
    notifyListeners();
  }

  void setSpeed(double v) => _setSpeed(focus, v);

  void _setSpeed(DeviceLink? l, double v) {
    l?.speed = v;
    _sendTo(l, {'t': 'speed', 'v': v});
    notifyListeners();
  }

  void setJog(int i, double v) {
    final l = focus;
    if (l == null) return;
    l.jog[i] = v;
    _send({'t': 'jog', 'j': l.jog});
  }

  void setCart(List<double> v) => _send({'t': 'cart', 'v': v});

  /// "Test failsafe": withholds the focused device's control heartbeat for six seconds.
  void dropLink() {
    final l = focus;
    if (l == null) return;
    l.linkTest = 6;
    l.session.holdHeartbeat = true;
    l.input.fillRange(0, 4, 0);
    notifyListeners();
  }

  void updateSettings(void Function(Settings) f) {
    final before = settings.toJson();
    f(settings);
    for (final l in links.values) {
      if (before['failsafe'] != settings.failsafe) _sendTo(l, {'t': 'fs', 'action': settings.failsafe, 'ms': 1800});
      if (before['rateHz'] != settings.rateHz) _sendTo(l, {'t': 'rate', 'hz': math.min(settings.rateHz, l.rates?.tlmHz ?? 60)});
    }
    saveSettings();
    notifyListeners();
  }

  /// Adds a simulated device of the template's kind. Several of the same kind
  /// are numbered (Kite, Kite 2…).
  DeviceInfo addSimulated(DeviceInfo t) {
    var n = 1;
    String id() => n == 1 ? 'sim-${t.id}' : 'sim-${t.id}-$n';
    while (devices.any((d) => d.id == id())) {
      n++;
    }
    final d = DeviceInfo(
      id: id(),
      name: n == 1 ? t.name : '${t.name} $n',
      kind: t.kind,
      model: t.model,
      battery: t.battery,
      sensors: t.sensors,
      via: 'Simulated in the app',
    );
    devices.add(d);
    _saveDevices();
    notifyListeners();
    return d;
  }

  /// Sound and vibration for an alert or a lost link.
  void _alertOut(AlertLevel l) {
    if (alertPrefs.sound) SystemSound.play(SystemSoundType.alert);
    if (!settings.haptics) return;
    l == AlertLevel.critical ? HapticFeedback.vibrate() : HapticFeedback.heavyImpact();
  }

  /// Hides an alert's banner until it clears and fires again ([on]: the
  /// device it belongs to, the focused one by default).
  void ackAlert(String id, {String? on}) {
    (on == null ? focus : links[on])?.alerts.ack(id);
    notifyListeners();
  }

  void updateAlerts(void Function(AlertPrefs) f) {
    f(alertPrefs);
    store.writeJson('kdash-alerts-v1', alertPrefs.toJson());
    notifyListeners();
  }

  void _haptic({bool heavy = false}) {
    if (!settings.haptics) return;
    heavy ? HapticFeedback.heavyImpact() : HapticFeedback.selectionClick();
  }

  void hapticTick() => _haptic();

  // ------------------------------------------------------------ recording
  // Record captures every connected device on one clock; each becomes its
  // own recording, grouped by the session's start.
  String? _recId;
  int _recLinks = 0, _recNumber = 1;
  double get _recNow => _recClock.elapsedMicroseconds / 1e6;

  void startRec() {
    if (!hasDevice || replay != null) return;
    recording = true;
    recStart = t;
    _recId = 's${DateTime.now().millisecondsSinceEpoch}';
    _recLinks = 0;
    _recNumber = sessions.where((s) => s.group == null).length + {for (final s in sessions) ?s.group}.length + 1;
    _recClock
      ..reset()
      ..start();
    for (final l in links.values) {
      _recStartLink(l);
    }
    notifyListeners();
  }

  /// Recording id for [l]: the session id, plus the device when several are recorded.
  String _recIdFor(DeviceLink l) => '${_recId!}-${l.id.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_')}';

  /// Notes [text] in [l]'s recording, when it is recording.
  void _event(DeviceLink l, String kind, String text, {bool critical = false}) {
    if (l.recFrames != null) l.recEvents.add(RecEvent(_recNow, kind, text, critical: critical));
  }

  void _recStartLink(DeviceLink l) {
    _recLinks++;
    l.recEvents = [];
    l.recFrames = [];
    l.recLast = -1;
    _recFrame(l);
    if (settings.recordVideo && l.video.isNotEmpty) unawaited(_startVideo(l, _recIdFor(l), l.video.first));
    // What scripts show, from now on.
    final id = _recIdFor(l);
    unawaited(
      store.recordingsDir().then((dir) {
        if (dir != null && l.recFrames != null) l.recViews = ViewRecorder(dir, id, () => _recNow, settings.videoFps.toDouble());
      }),
    );
  }

  /// Keeps what a script shows in [l]'s recording, when it is recording.
  void recordView(DeviceLink l, ScriptView v) {
    if (l.recFrames != null) l.recViews?.add(v);
  }

  /// Keeps the camera open while recording, even when no screen shows it,
  /// and writes its frames next to the recording.
  Future<void> _startVideo(DeviceLink l, String id, VideoStream s) async {
    final dir = await store.recordingsDir();
    if (dir == null || l.recFrames == null) return;
    await Directory(dir).create(recursive: true);
    final rec = VideoRecorder('$dir/$id.kdv', clock: () => _recNow, maxFps: settings.videoFps.toDouble());
    try {
      await rec.open();
    } catch (e) {
      debugPrint('video recording unavailable: $e');
      return;
    }
    if (l.recFrames == null || !recording) {
      await rec.close();
      return;
    }
    final f = videoFeed(s, l.info)..acquire();
    void tap(Uint8List b) => rec.add(b);
    f.taps.add(tap);
    l.vid = (rec: rec, feed: f, stream: s, tap: tap);
  }

  /// Stops the camera recording; the video description, or null without one.
  Future<Map<String, dynamic>?> _stopVideo(DeviceLink l, String id, {required bool keep}) async {
    final v = l.vid;
    l.vid = null;
    if (v == null) return null;
    v.feed.taps.remove(v.tap);
    v.feed.release();
    final rec = v.rec, n = await rec.close();
    if (!keep || n == 0) {
      try {
        await File(rec.path).delete();
      } catch (_) {}
      return null;
    }
    return {'file': '$id.kdv', 'frames': n, 'label': v.stream.label.isEmpty ? 'Camera' : v.stream.label};
  }

  /// One frame per telemetry message, up to the telemetry rate set in
  /// Settings (devices that send several partial messages per cycle do not
  /// multiply frames).
  void _recFrame(DeviceLink l, {bool force = false}) {
    final fr = l.recFrames;
    if (fr == null) return;
    final now = _recNow;
    if (!force && l.recLast >= 0 && now - l.recLast < .9 / settings.rateHz) return;
    l.recLast = now;
    fr.add(l.tel.snapshot()..['t'] = (now * 1000).round() / 1000);
  }

  void stopRec() {
    if (!recording) return;
    // Focused device last, so lastSaved is the one on screen.
    for (final l in [...links.values.where((l) => l != focus), ?focus]) {
      _recStopLink(l);
    }
    _endRecording();
    notifyListeners();
  }

  void _endRecording() {
    recording = false;
    _recId = null;
    _recClock.stop();
  }

  void _recStopLink(DeviceLink l) {
    final fr = l.recFrames;
    if (fr == null || _recId == null) return;
    l.recFrames = null;
    final group = _recId!, several = _recLinks > 1;
    final id = several ? _recIdFor(l) : group;
    final keep = fr.length > 5;
    final videoDone = _stopVideo(l, _recIdFor(l), keep: keep);
    final vr = l.recViews;
    l.recViews = null;
    final viewsDone =
        vr?.close(
          keep: keep,
          write: (file, text) => File('${vr.dir}/$file').writeAsString(text),
          delete: (file) async {
            try {
              await File('${vr.dir}/$file').delete();
            } catch (_) {}
          },
        ) ??
        Future.value(const <Map<String, dynamic>>[]);
    if (!keep) return;
    final d = l.info, n = _recNumber;
    final r = Recording(
      id: id,
      name: several ? 'Session $n · ${d.name}' : 'Session $n',
      deviceId: d.id,
      kind: d.kind,
      deviceName: d.name,
      date: _date(DateTime.now()),
      frames: fr,
      cloud: l.tel.cloud.length > 6000 ? l.tel.cloud.sublist(0, 6000) : List.of(l.tel.cloud),
      fresh: true,
      startedAt: DateTime.now().subtract(Duration(microseconds: _recClock.elapsedMicroseconds)),
      group: several ? group : null,
      events: l.recEvents,
    );
    sessions.insert(0, r);
    lastSaved = r;
    // Saved once the video file is complete.
    unawaited(
      videoDone.then((v) async {
        r.views = await viewsDone;
        r.filesDir = vr?.dir;
        if (v != null) {
          r.video = v;
          final dir = await store.recordingsDir();
          if (dir != null) r.videoPath = '$dir/${v['file']}';
          notifyListeners();
        }
        await store.saveRecording(r.toJson());
      }),
    );
  }

  /// Adds a recording from a file: a koebelt/dash JSON export, an ArduPilot
  /// .bin or .tlog, or a PX4 .ulg. Parsed off the UI thread. Throws
  /// [LogImportError] with a message for the user.
  Future<Recording> importLog(String fileName, Uint8List bytes) async {
    final log = await Isolate.run(() => parseLog(fileName, bytes));
    final base = fileName.split(RegExp(r'[/\\]')).last;
    final r = Recording(
      id: 'i${DateTime.now().millisecondsSinceEpoch}',
      name: log.name ?? (base.contains('.') ? base.substring(0, base.lastIndexOf('.')) : base),
      deviceId: 'import',
      kind: log.kind,
      deviceName: log.deviceName,
      date: _date((log.startedAt ?? DateTime.now()).toLocal()),
      frames: log.frames,
      cloud: log.cloud,
      fresh: true,
      startedAt: log.startedAt,
    );
    sessions.insert(0, r);
    lastSaved = r;
    await store.saveRecording(r.toJson());
    notifyListeners();
    return r;
  }

  void openReplay(String id) {
    final s = sessions.where((x) => x.id == id).firstOrNull;
    if (s == null) return;
    if (recording) stopRec();
    Telemetry fresh(Recording r) => Telemetry(r.kind)
      ..predict = false
      ..proxDown = [for (final p in devices.where((x) => x.id == r.deviceId).firstOrNull?.prox ?? const <ProxSensor>[]) p.down]
      ..addPoints(r.cloud);
    replay = Replay(
      s,
      fresh(s),
      mates: [
        if (s.group != null)
          for (final m in sessions)
            if (m.group == s.group && m.id != s.id) (rec: m, tel: fresh(m)),
      ],
    );
    s.fresh = false;
    hist.clear();
    _viewPlayer?.close();
    _viewPlayer = s.views.isEmpty || s.filesDir == null ? null : ViewPlayer(s.views, s.filesDir!);
    notifyListeners();
  }

  /// The replayed recording's script views, played at the replay time.
  ViewPlayer? _viewPlayer;

  /// What scripts show for the device on screen: live, or as recorded in
  /// the open replay.
  Map<String, ScriptView> get scriptViews => replay != null ? (_viewPlayer?.views ?? const {}) : (focus?.views ?? const {});

  /// What the Replay screen shows: '3d' or 'video'.
  String replayView = '3d';

  /// The open replay's video, opened on first use.
  Future<VideoTrack?>? _track;
  String? _trackId;
  Future<VideoTrack?> replayVideo(Recording r) {
    if (_trackId != r.id || _track == null) {
      _closeTrack();
      _trackId = r.id;
      _track = r.hasVideo ? VideoTrack.open(r.videoPath!) : Future.value(null);
    }
    return _track!;
  }

  void _closeTrack() {
    final t = _track;
    _track = null;
    _trackId = null;
    t?.then((v) => v?.close());
  }

  void closeReplay() {
    if (replay == null) return;
    _closeTrack();
    _viewPlayer?.close();
    _viewPlayer = null;
    replay = null;
    hist.clear();
    notifyListeners();
  }

  void _replayStep(double dt) {
    final r = replay!;
    if (r.playing) {
      r.t += dt * r.speed;
      if (r.t >= r.dur) {
        r.t = r.dur;
        r.playing = false;
        notifyListeners();
      }
    }
    _applyAt(r.session, r.tel, r.t);
    unawaited(_viewPlayer?.seek(r.t));
    for (final m in r.mates) {
      m.tel.animate(dt);
      _applyAt(m.rec, m.tel, r.t, gpsTrail: true);
    }
  }

  /// Puts [tel] where [s] was at [at] seconds, interpolating between frames.
  void _applyAt(Recording s, Telemetry tel, double at, {bool gpsTrail = false}) {
    final fr = s.frames;
    if (fr.isEmpty) return;
    final r = (tel: tel, t: at), i = s.frameAt(at);
    r.tel.applyFrame(fr[i]);
    // Interpolate the pose between this frame and the next.
    if (i + 1 < fr.length) {
      final t0 = s.timeAt(i), t1 = s.timeAt(i + 1);
      final a = fr[i], b = fr[i + 1], k = t1 > t0 ? ((r.t - t0) / (t1 - t0)).clamp(0.0, 1.0) : 0.0;
      List<double> l(Map f, String key) => [for (final e in f[key] as List? ?? const []) (e as num).toDouble()];
      double n(Map f, String key) => (f[key] as num?)?.toDouble() ?? 0;
      final pa = l(a, 'pos'), pb = l(b, 'pos');
      if (pa.length == 3 && pb.length == 3) r.tel.pos = [for (var j = 0; j < 3; j++) pa[j] + (pb[j] - pa[j]) * k];
      final ja = l(a, 'joints'), jb = l(b, 'joints');
      if (ja.isNotEmpty && ja.length == jb.length) r.tel.joints = [for (var j = 0; j < ja.length; j++) ja[j] + (jb[j] - ja[j]) * k];
      double ang(String key) {
        var d = n(b, key) - n(a, key);
        d = math.atan2(math.sin(d), math.cos(d));
        return n(a, key) + d * k;
      }

      r.tel.yaw = ang('yaw');
      r.tel.roll = ang('roll');
      r.tel.pitch = ang('pitch');
    }
    final p = s.kind == DeviceKind.arm, step = math.max(1, (s.rateHz * .3).round());
    if (gpsTrail) {
      r.tel.gpsTrail = [
        for (var k = 0; k <= i; k += step)
          if ((fr[k]['lat'] as num? ?? 0) != 0) [(fr[k]['lat'] as num).toDouble(), (fr[k]['lon'] as num).toDouble()],
      ];
    }
    r.tel.trail = [
      for (var k = 0; k <= i; k += step)
        p && fr[k]['joints'] is List
            ? armFk((fr[k]['joints'] as List).map((e) => (e as num).toDouble()).toList())[5]
            : (fr[k]['pos'] as List? ?? const [0, 0, 0]).map((e) => (e as num).toDouble()).toList(),
    ];
  }

  /// Drawn with the device shown: the other connected devices, or during a
  /// replay the other devices of the session (once they have started).
  List<Companion> get companions {
    final r = replay;
    if (r != null) {
      return [
        for (final m in r.mates)
          if (m.rec.frames.isNotEmpty && r.t >= m.rec.timeAt(0)) (id: m.rec.id, name: m.rec.deviceName, tel: m.tel),
      ];
    }
    return [
      for (final l in links.values)
        if (l.id != deviceId) (id: l.id, name: l.info.name, tel: l.tel),
    ];
  }

  /// Shows a companion: focuses that device, or replays that device's
  /// recording at the same moment.
  void showCompanion(String id) {
    final r = replay;
    if (r == null) return focusDevice(id);
    final t = r.t, playing = r.playing, speed = r.speed;
    openReplay(id);
    replay!
      ..t = t
      ..playing = playing
      ..speed = speed;
    notifyListeners();
  }

  void seekReplay(double t) {
    replay?.t = t;
    notifyListeners();
  }

  Future<void> deleteRecording(String id) async {
    final s = sessions.where((x) => x.id == id).firstOrNull;
    sessions.removeWhere((s) => s.id == id);
    if (replay?.session.id == id) closeReplay();
    notifyListeners(); // update the list now; the file is removed in the background
    await store.deleteRecording(
      id,
      video: s?.video?['file'] as String?,
      also: [
        for (final v in s?.views ?? const <Map>[])
          if (v['file'] is String) v['file'] as String,
      ],
    );
  }

  // ------------------------------------------------------------ params
  Map<String, double>? get devParams => deviceId == null ? null : paramDev[deviceId];
  Map<String, double>? get draftParams => deviceId == null ? null : paramDraft[deviceId];

  List<String> get changedParams {
    final dev = devParams, dr = draftParams;
    if (dev == null || dr == null) return const [];
    return [
      for (final k in dr.keys)
        if ((dr[k]! - (dev[k] ?? 0)).abs() > 1e-9) k,
    ];
  }

  void setParam(String k, double v) {
    draftParams?[k] = v;
    notifyListeners();
  }

  void revertParams([Iterable<String>? keys]) {
    final dev = devParams, dr = draftParams;
    if (dev == null || dr == null) return;
    for (final k in keys ?? dr.keys.toList()) {
      dr[k] = dev[k] ?? dr[k]!;
    }
    notifyListeners();
  }

  void writeParams() {
    final ch = changedParams, dr = draftParams!, l = focus;
    if (ch.isEmpty || l == null) return;
    l.paramWriting = true;
    _send({
      't': 'pset',
      'p': {for (final k in ch) k: dr[k]},
    });
    notifyListeners();
    Timer(const Duration(seconds: 4), () {
      if (l.paramWriting) {
        l.paramWriting = false;
        notifyListeners();
      }
    });
  }

  // ------------------------------------------------------------ sequences
  List<Sequence> sequencesFor(String id) {
    final d = devices.where((x) => x.id == id).firstOrNull;
    return sequences.putIfAbsent(id, () => d != null && d.simulated ? exampleSequences(id, d.kind) : []);
  }

  void saveSequences() {
    store.writeJson('kdash-seq-v1', {
      for (final e in sequences.entries) e.key: [for (final q in e.value) q.toJson()],
    });
    notifyListeners();
  }

  /// Runs [q] on the focused device: on the device itself when it can store
  /// sequences (it then keeps going if the link drops), otherwise from the
  /// app, step by step. Each connected device can run its own.
  void runSequence(Sequence q) {
    final l = focus;
    if (l != null) runSequenceOn(l, q);
  }

  /// Runs a sequence on a given device (scripts run steps on theirs).
  void runSequenceOn(DeviceLink l, Sequence q) {
    if (replay != null || l.tel.estop) return;
    final host = _LinkHost(this, l);
    if (l.seqCap >= q.steps.length && q.steps.isNotEmpty && canControl) {
      final r = DeviceSequenceRunner(q, host, (m) => _sendTo(l, m.cast<String, dynamic>()));
      l.runner = r;
      _sendTo(l, r.uploadMsg().cast<String, dynamic>());
    } else {
      l.runner = SequenceRunner(q, host);
      // dash drives it now.
      if (l.tel.armed && modal(l.kind) && !nativeModes(l)) _setMode(l, 'AUTO');
    }
    notifyListeners();
  }

  void _onSeqAck(DeviceLink l, Msg m) {
    final r = l.runner;
    if (r is! DeviceSequenceRunner || m['id'] != r.seq.id || !r.uploading) return;
    if (m['ok'] == true) {
      r.accepted();
    } else {
      // The device cannot hold this one (a step it does not support, too
      // long): run it from the app instead.
      l.runner = SequenceRunner(r.seq, _LinkHost(this, l))..message = 'Running from the app: ${m['err'] ?? 'the device declined it'}';
    }
    notifyListeners();
  }

  /// `state.ext.run`: progress of a sequence running on the device. Picks a
  /// run up again after a reconnect.
  void _onRunState(DeviceLink l, Map run) {
    var r = l.runner;
    if (r is! DeviceSequenceRunner || r.seq.id != run['id']) {
      final st = run['st'];
      if (st != 'run' && st != 'pause') return;
      final q = sequencesFor(l.id).where((x) => x.id == run['id']).firstOrNull;
      if (q == null) return;
      r = DeviceSequenceRunner(q, _LinkHost(this, l), (m) => _sendTo(l, m.cast<String, dynamic>()))..uploading = false;
      l.runner = r;
    }
    if (r.uploading) return;
    r.apply(run);
  }

  void clearRunner() {
    focus?.runner = null;
    notifyListeners();
  }

  // ------------------------------------------------------------ HUD layouts
  String _hudKey(String cls) => '$deviceId:$cls';
  List<HudItem>? savedHud(String cls) => hud[_hudKey(cls)];
  void saveHud(String cls, List<HudItem>? l) {
    if (l == null) {
      hud.remove(_hudKey(cls));
    } else {
      hud[_hudKey(cls)] = l;
    }
    store.writeJson('kdash-hud-v1', {
      for (final e in hud.entries) e.key: [for (final i in e.value) i.toJson()],
    });
    notifyListeners();
  }

  // ------------------------------------------------------------ devices & pairing
  Future<void> removeDevice(DeviceInfo d) async {
    if (links.containsKey(d.id)) await disconnect(id: d.id);
    if (connecting == d.id) connecting = null;
    devices.removeWhere((x) => x.id == d.id);
    hud.removeWhere((k, _) => k.startsWith('${d.id}:'));
    store.writeJson('kdash-hud-v1', {
      for (final e in hud.entries) e.key: [for (final i in e.value) i.toJson()],
    });
    paramDev.remove(d.id);
    paramDraft.remove(d.id);
    _sims.remove(d.id)?.detach();
    _saveDevices();
    notifyListeners();
  }

  static String _newCode() {
    const a = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
    final r = math.Random.secure();
    String p() => List.generate(3, (_) => a[r.nextInt(a.length)]).join();
    return '${p()}-${p()}';
  }

  String get currentPairCode {
    if (DateTime.now().isAfter(pairExpires)) {
      pairCode = _newCode();
      pairExpires = DateTime.now().add(const Duration(minutes: 10));
    }
    return pairCode;
  }

  /// Starts LAN, BLE and USB discovery. Reference-counted; call [stopScan] once per call.
  void startScan() {
    _scanners++;
    if (_scanners == 1) {
      found.clear();
      _lan = LanDiscovery()..start(_onFound);
      _ble = BleDiscovery()..start(_onFound);
      _mav = MavlinkUdpDiscovery()..start(_onFound);
      _tello = TelloDiscovery()..start(_onFound);
      serialPorts().forEach(_onFound);
      // Flight controllers and boards on USB say what they run when asked.
      _usb = UsbBoardScanner()..start(_onFound, skip: (path) => devices.any((d) => d.address == path) || links.values.any((l) => l.info.address == path));
    }
  }

  void stopScan() {
    _scanners = math.max(0, _scanners - 1);
    if (_scanners == 0) {
      _lan?.stop();
      _ble?.stop();
      _mav?.stop();
      _tello?.stop();
      _usb?.stop();
      _lan = null;
      _ble = null;
      _mav = null;
      _tello = null;
      _usb = null;
    }
  }

  void _onFound(Found f) {
    if (devices.any((d) => d.id == f.id || (f.transport != 'udp' && f.transport != 'ble' && d.address == f.address && d.proto == f.proto))) return;
    // An identified USB board replaces the plain port entry.
    if (f.transport == 'serial' && !f.id.startsWith('serial:')) found.remove('serial:${f.address}');
    found[f.id] = f;
    notifyListeners();
  }

  /// Adds a discovered device. Devices announcing our pairing code receive a
  /// fresh key; open-mode devices are added without one.
  Future<String?> pair(Found f) async {
    final kind = DeviceKind.parse(f.kind);
    final info = DeviceInfo(
      id: f.id,
      name: f.name,
      kind: kind,
      model: f.model,
      sensors: f.sensors,
      via: f.via,
      address: f.address,
      battery: f.transport == 'sim' ? 97 : 100,
      transport: switch (f.transport) {
        'sim' => TransportKind.sim,
        'ble' => TransportKind.ble,
        'serial' => TransportKind.serial,
        'radio' => TransportKind.radio,
        _ => TransportKind.udp,
      },
      radio: f.radio,
      proto: f.proto,
      module: f.module,
    );
    // Behind a third-party module the advertisement only names the module:
    // ask the board itself (name, kind, pairing code) over the same link.
    final listen = f.native && f.pair == null && info.module != null;
    if (f.native && info.transport != TransportKind.sim && (listen || f.pair == currentPairCode)) {
      final Transport tr = switch (info.transport) {
        TransportKind.ble => BleTransport(info.address, name: info.name, profile: bleProfile(info.module)),
        TransportKind.serial => SerialTransport(info.address, baud: info.baud ?? 115200),
        TransportKind.radio => SerialTransport(info.address, baud: radioModule(info.radio).baud, radio: radioModule(info.radio)),
        _ => UdpTransport(info.address),
      };
      try {
        await tr.open();
        var code = f.pair;
        if (listen) {
          final heard = tr.messages.firstWhere((m) => m['t'] == 'announce').timeout(const Duration(seconds: 4));
          tr.send({'t': 'discover', 'v': protocolVersion});
          try {
            final a = await heard;
            code = a['pair'] as String?;
            if (a['name'] is String) info.name = a['name'];
            if (a['kind'] is String) info.kind = DeviceKind.parse(a['kind']);
            if (a['model'] is String) info.model = a['model'];
          } on TimeoutException {
            // Not announcing: added in open mode, as before.
          }
        }
        if (code != null && code == currentPairCode) {
          final key = List.generate(16, (_) => math.Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0')).join();
          final ok = tr.messages.firstWhere((m) => m['t'] == 'paired').timeout(const Duration(seconds: 5));
          tr.send({'t': 'pair', 'code': code, 'key': key});
          await ok;
          info.key = key;
        }
      } catch (e) {
        return 'Pairing failed: no answer from ${info.name}';
      } finally {
        await tr.close();
      }
    }
    devices.add(info);
    found.remove(f.id);
    _saveDevices();
    notifyListeners();
    return null;
  }

  /// Adds a radio link: a radio modem on [path] at [baud]. Name and kind are
  /// learned from the device's `hello` on the first connect.
  DeviceInfo addRadio(String path, RadioModule r, {int? baud, String? name, DeviceKind kind = DeviceKind.generic}) {
    final id = 'radio:$path';
    devices.removeWhere((d) => d.id == id);
    final info = DeviceInfo(
      id: id,
      name: name ?? r.name,
      kind: kind,
      transport: TransportKind.radio,
      address: path,
      radio: r.id,
      baud: baud == null || baud == r.baud ? null : baud,
      via: 'Radio · ${r.name}',
    );
    devices.add(info);
    found.remove(id);
    _saveDevices();
    notifyListeners();
    return info;
  }

  /// Adds a Wi-Fi device by address (for networks that block broadcast).
  /// Adds a device by address (for networks that block broadcast). With
  /// [proto] `mavlink`, [host] may carry the vehicle's port ("192.168.4.1:14555").
  DeviceInfo addManual(String name, String host, DeviceKind kind, {String proto = 'koebelt'}) {
    final via = 'Wi-Fi · $host';
    final info = DeviceInfo(
      id: proto == 'koebelt' ? 'udp:$host' : '$proto:$host',
      name: name,
      kind: kind,
      transport: TransportKind.udp,
      address: host,
      via: via,
      proto: proto,
    );
    devices.removeWhere((d) => d.id == info.id);
    devices.add(info);
    _saveDevices();
    notifyListeners();
    return info;
  }

  @override
  void dispose() {
    scripts.dispose();
    gamepads.dispose();
    for (final l in links.values) {
      l.session.close();
    }
    for (final s in _sims.values) {
      s.detach();
    }
    frame.dispose();
    super.dispose();
  }
}

/// What a sequence runner needs, bound to the device it runs on (which may
/// not be the focused one).
class _LinkHost implements SequenceHost {
  _LinkHost(this.d, this.l);
  final Dash d;
  final DeviceLink l;
  @override
  List<double> get seqPos => l.tel.pos;
  @override
  List<double> get seqJoints => l.tel.joints;
  @override
  String get seqMode => l.tel.mode;
  @override
  bool get seqArmed => l.tel.armed;
  @override
  bool get seqStopped => l.tel.estop;
  @override
  bool get seqLinkLost => l.linkLostFor > 0;
  @override
  void seqSetMode(String m) => d._setMode(l, m);
  @override
  void seqSetArmed(bool v) => d._setArmed(l, v);
  @override
  void seqSetSpeed(double v) => d._setSpeed(l, v);
  @override
  void seqCmd(String c, Map<String, dynamic> a) {
    if (c == 'throttle') l.benchThrottle = numOr(a['v'], 0);
    d._sendTo(l, {'t': 'cmd', 'c': c, 'a': a});
    d.emit();
  }
}
