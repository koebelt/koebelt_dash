import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../link/ble_transport.dart';
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
import 'gamepad.dart';
import 'model.dart';
import 'sequence.dart';
import 'store.dart';
import 'telemetry.dart';

class Settings {
  String control = 'joysticks'; // joysticks | sliders | tilt
  bool invertY = false;
  String failsafe = 'HOLD';
  bool haptics = true;
  int rateHz = 30;

  /// Map tiles: osm | topo | custom | none.
  String mapTiles = 'osm';

  /// URL template for custom tiles, `https://…/{z}/{x}/{y}.png`.
  String mapUrl = '';

  /// Credit line the custom tile provider requires.
  String mapAttribution = '';

  Map<String, dynamic> toJson() => {
    'control': control,
    'invertY': invertY,
    'failsafe': failsafe,
    'haptics': haptics,
    'rateHz': rateHz,
    'mapTiles': mapTiles,
    'mapUrl': mapUrl,
    'mapAttribution': mapAttribution,
  };
  void load(Map? j) {
    if (j == null) return;
    control = j['control'] ?? control;
    invertY = j['invertY'] ?? invertY;
    failsafe = j['failsafe'] ?? failsafe;
    haptics = j['haptics'] ?? haptics;
    rateHz = j['rateHz'] ?? rateHz;
    mapTiles = j['mapTiles'] ?? mapTiles;
    mapUrl = j['mapUrl'] ?? mapUrl;
    mapAttribution = j['mapAttribution'] ?? mapAttribution;
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
  });
  final String id, name, deviceId, deviceName, date;

  /// Wall-clock start of the recording (UTC), when known.
  final DateTime? startedAt;
  final DeviceKind kind;
  final List<Map<String, dynamic>> frames;
  final List<List<double>> cloud;
  bool fresh;
  final bool demo;
  double get dur => frames.length / 10;

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
  );
}

class Replay {
  Replay(this.session, this.tel);
  final Recording session;
  final Telemetry tel;
  double t = 0, speed = 1;
  bool playing = true;
}

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
class Dash extends ChangeNotifier implements SequenceHost, PadTarget {
  Dash({Store? store}) : store = store ?? Store();
  final Store store;

  /// Game controller mapping and the plugin listener.
  final pad = PadConfig();
  late final padMapper = PadMapper(pad, this);
  late final gamepads = GamepadInput(padMapper);

  final settings = Settings();
  final List<DeviceInfo> devices = [];
  String? deviceId, connecting, connectError;
  DeviceSession? session;
  final Map<String, SimDevice> _sims = {};

  Telemetry liveTel = Telemetry(DeviceKind.drone);
  final hist = History();
  Replay? replay;
  Telemetry get tel => replay?.tel ?? liveTel;

  DeviceInfo? get device => devices.where((d) => d.id == deviceId).firstOrNull;
  DeviceKind get kind => replay?.session.kind ?? device?.kind ?? DeviceKind.generic;
  bool get hasDevice => deviceId != null;

  /// True when what is on screen does not come from real hardware.
  bool get simulated => replay?.session.demo ?? device?.simulated ?? false;
  String get deviceName => replay?.session.deviceName ?? device?.name ?? 'the device';

  // control input
  final List<double> input = [0, 0, 0, 0]; // lx ly rx ry
  List<double> jog = List.filled(6, 0);
  double speed = .5;

  // link health
  double linkTest = 0, linkRestored = 0;
  bool _wasLost = false;
  double get latency => session?.latency ?? 0;

  /// Seconds since the link was lost, 0 when healthy.
  double get linkLostFor {
    if (replay != null || session == null) return 0;
    if (linkTest > 0) return 6 - linkTest;
    final s = session!.silence, limit = radio == null ? 1.0 : math.max(1.0, 3.0 / radio!.tlmHz);
    return s > limit ? s : 0;
  }

  /// Radio profile of the open link, null for Wi-Fi, BLE, USB and simulators.
  RadioModule? get radio => device?.transport == TransportKind.radio ? radioModule(device!.radio) : null;

  /// False on telemetry-only links (LoRa): sticks, modes and commands do not
  /// reach the device. STOP still does (protocol/PROTOCOL.md, "Radio links").
  bool get canControl => replay == null && (session?.controls ?? true);

  /// Camera streams the connected device declared.
  List<VideoStream> video = const [];
  final videoHub = VideoHub();

  /// The feed for a declared stream (shared connection).
  VideoFeed videoFeed(VideoStream s) => videoHub.feed(s, device);

  bool get linkLost => linkLostFor > 0;

  bool estopAck = false;

  /// Commanded bench throttle (0–1); the device reports only the output.
  double benchThrottle = 0;

  /// Public notify for UI-owned state (layout, layers, replay seek).
  void emit() => notifyListeners();

  // params
  final Map<String, List<ParamGroup>> paramGroups = {};
  final Map<String, Map<String, double>> paramDev = {}, paramDraft = {};
  final Map<String, String> paramWritten = {};
  bool paramWriting = false;
  bool _paramsMore = false;
  List _paramsAcc = [];
  String? fwVersion;

  // custom channels by device
  final Map<String, List<ChannelDef>> channels = {};
  final List<Msg> logs = [];

  // recording
  bool recording = false;
  double recStart = 0;
  List<Map<String, dynamic>>? _recFrames;
  double _recAcc = 0;
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
  int _scanners = 0;

  // sequences
  final Map<String, List<Sequence>> sequences = {};
  SequenceRunner? runner;

  // clock
  double t = 0;
  double _sampleAcc = 0, _notifyAcc = 0;

  /// Bumped every frame; painters repaint on it.
  final frame = ValueNotifier<int>(0);

  // ------------------------------------------------------------ lifecycle
  Future<void> init() async {
    await store.init();
    settings.load(store.readJson('kdash-settings-v1'));
    pad.load(store.readJson('kdash-pad-v1') as Map?);
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
    for (final r in await store.loadRecordings()) {
      try {
        sessions.add(Recording.fromJson(r));
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
        (kind == DeviceKind.drone || kind == DeviceKind.rover || kind == DeviceKind.generic);
  }

  @override
  void padAxes(List<double> v) {
    if (!padCanDrive) {
      input.fillRange(0, 4, 0);
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
    if (!hasDevice || replay != null) return;
    final s = liveTel, drone = kind == DeviceKind.drone;
    switch (a) {
      case PadAction.stop:
        emergencyStop();
      case PadAction.arm:
        if (!s.estop && canControl) setArmed(!s.armed);
      case PadAction.manual:
        setMode('MANUAL');
      case PadAction.hold:
        setMode('HOLD');
      case PadAction.auto:
        setMode('AUTO');
      case PadAction.rth:
        if (drone) setMode('RTH');
      case PadAction.takeoff:
        if (drone && s.armed) setMode('TAKEOFF');
      case PadAction.land:
        if (drone) setMode('LAND');
      case PadAction.record:
        recording ? stopRec() : startRec();
      case PadAction.slower:
        setSpeed(math.max(.1, ((speed - .1) * 10).roundToDouble() / 10));
      case PadAction.faster:
        setSpeed(math.min(1, ((speed + .1) * 10).roundToDouble() / 10));
    }
  }

  // ------------------------------------------------------------ frame loop
  void tick(double dt) {
    t += dt;
    // The live pose keeps its clock running even while a replay is shown.
    liveTel.animate(dt);
    replay?.tel.animate(dt);
    if (replay != null) {
      _replayStep(dt);
    } else if (session != null) {
      if (linkTest > 0) {
        linkTest -= dt;
        if (linkTest <= 0) {
          linkTest = 0;
          session?.holdHeartbeat = false;
        }
      }
      final lost = linkLost;
      if (_wasLost && !lost) {
        linkRestored = 2.5;
        notifyListeners();
      }
      if (!_wasLost && lost) {
        _haptic(heavy: true);
        notifyListeners();
      }
      _wasLost = lost;
    }
    if (linkRestored > 0) {
      linkRestored -= dt;
      if (linkRestored <= 0) {
        linkRestored = 0;
        notifyListeners();
      }
    }
    final r = runner;
    if (r != null && replay == null) {
      final before = (r.state, r.index);
      r.tick(dt);
      if ((r.state, r.index) != before) notifyListeners();
    }
    if (recording && replay == null) {
      _recAcc += dt;
      while (_recAcc > .1) {
        _recFrames!.add(liveTel.snapshot());
        _recAcc -= .1;
      }
    }
    _sampleAcc += dt;
    while (_sampleAcc > 1 / 30) {
      if (hasDevice || replay != null) {
        hist.sample(tel, latency);
        if (replay == null) tel.sampleTrail();
      }
      _sampleAcc -= 1 / 30;
    }
    frame.value++;
    _notifyAcc += dt;
    if (_notifyAcc > .1) {
      _notifyAcc = 0;
      notifyListeners();
    }
  }

  // ------------------------------------------------------------ connection
  Future<void> connect(String id) async {
    final d = devices.where((x) => x.id == id).firstOrNull;
    if (d == null || !d.online) return;
    if (replay != null) closeReplay();
    await disconnect(notify: false);
    connecting = id;
    connectError = null;
    notifyListeners();
    final Transport tr;
    switch (d.transport) {
      case TransportKind.sim:
        final lt = LoopbackTransport('Simulator');
        (_sims[id] ??= SimDevice(d)).attach(lt);
        tr = lt;
        await Future<void>.delayed(const Duration(milliseconds: 900));
      case TransportKind.udp:
        tr = UdpTransport(d.address);
      case TransportKind.ble:
        tr = BleTransport(d.address, name: d.name);
      case TransportKind.serial:
        tr = SerialTransport(d.address, baud: d.baud ?? 115200);
      case TransportKind.radio:
        final r = radioModule(d.radio);
        tr = SerialTransport(d.address, baud: d.baud ?? r.baud, radio: r);
    }
    if (connecting != id) return; // cancelled
    final r = d.transport == TransportKind.radio ? radioModule(d.radio) : null;
    final s = DeviceSession(
      tr,
      onMessage: (m) => _onMsg(id, m),
      key: d.key,
      ctlHz: r?.ctlHz ?? 20,
      pingEvery: r == null ? const Duration(seconds: 1) : const Duration(seconds: 5),
    );
    s.axes = () => input;
    // Fresh telemetry before the handshake: state and telemetry can arrive
    // right behind (or, over UDP, ahead of) the hello and must not be lost.
    liveTel = Telemetry(d.kind);
    hist.clear();
    try {
      final h = await s.open();
      if (connecting != id) {
        await s.close();
        return;
      }
      session = s;
      deviceId = id;
      d.online = true;
      if (h['name'] is String) d.name = h['name'];
      if (h['kind'] is String) d.kind = DeviceKind.parse(h['kind']);
      if (h['model'] is String && (h['model'] as String).isNotEmpty) d.model = h['model'];
      if (h['sensors'] is List && (h['sensors'] as List).isNotEmpty) d.sensors = List<String>.from(h['sensors']);
      fwVersion = h['fw'] as String?;
      video = [
        for (final v in (h['video'] as List? ?? const []))
          if (v is Map) VideoStream.fromJson(v),
      ];
      if (liveTel.kind != d.kind) liveTel = Telemetry(d.kind);
      estopAck = false;
      input.fillRange(0, 4, 0);
      s.send({'t': 'rate', 'hz': math.min(settings.rateHz, r?.tlmHz ?? 60)});
      s.send({'t': 'fs', 'action': settings.failsafe, 'ms': 1800});
      s.send({'t': 'speed', 'v': speed});
      _saveDevices();
    } catch (e) {
      connectError = e is TimeoutException ? 'No answer from ${d.name}' : '$e'.replaceFirst('Bad state: ', '');
      await s.close();
      if (d.simulated) _sims[id]?.detach();
    } finally {
      if (connecting == id) connecting = null;
      notifyListeners();
    }
  }

  Future<void> disconnect({bool notify = true}) async {
    if (recording) stopRec();
    runner?.stop('Stopped: disconnected');
    final s = session, id = deviceId;
    session = null;
    deviceId = null;
    connecting = null;
    linkTest = 0;
    linkRestored = 0;
    _wasLost = false;
    video = const [];
    videoHub.clear();
    input.fillRange(0, 4, 0);
    if (notify) notifyListeners();
    await s?.close();
    if (id != null) {
      // simulated devices keep running their physics off-line only while attached
      final sim = _sims[id];
      if (sim != null) Timer(const Duration(milliseconds: 100), sim.detach);
    }
  }

  void _onMsg(String id, Msg m) {
    if (id != deviceId && connecting != id) return;
    if (linkTest > 0 && m['t'] != 'pong' && m['t'] != 'tlm' && m['t'] != 'state') return;
    switch (m['t']) {
      case 'tlm':
        if (m['d'] is Map) liveTel.applyTlm((m['d'] as Map).cast<String, dynamic>(), ts: m['ts'] as num?);
        final d = device;
        if (d != null) d.battery = liveTel.battery.round();
      case 'state':
        final wasStop = liveTel.estop;
        liveTel.applyState(m);
        if (liveTel.estop && !wasStop) estopAck = false;
        if (liveTel.mode == 'IDLE' || liveTel.mode == 'CUTOFF' || liveTel.estop) benchThrottle = 0;
        notifyListeners();
      case 'pc':
        if (m['d'] is String) liveTel.addPoints(decodePoints(m['d']));
      case 'tracks':
        if (m['d'] is List) liveTel.applyTracks(m['d']);
      case 'params':
        // Large tables arrive in several messages flagged `more`; merge them.
        final merged = _paramsMore
            ? {
                ...m,
                'p': [..._paramsAcc, ...(m['p'] as List? ?? const [])],
              }
            : m;
        _paramsMore = m['more'] == true;
        _paramsAcc = List.of(merged['p'] as List? ?? const []);
        final g = parseParams(merged, device?.kind ?? DeviceKind.generic);
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
        paramWriting = false;
        final n = DateTime.now();
        paramWritten[id] = '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}:${n.second.toString().padLeft(2, '0')}';
        notifyListeners();
      case 'chan':
        channels[id] = [
          for (final c in (m['ch'] as List? ?? const []))
            ChannelDef('${c['id']}', List<String>.from(c['axes'] ?? const ['value']), '${c['unit'] ?? ''}', numOr(c['hz'], 10)),
        ];
        notifyListeners();
      case 'log':
        logs.add(m);
        if (logs.length > 200) logs.removeAt(0);
    }
  }

  // ------------------------------------------------------------ commands
  void _send(Msg m) {
    if (replay == null) session?.send(m);
  }

  void setMode(String m) {
    if (liveTel.estop || !canControl) return;
    _send({'t': 'mode', 'm': m});
    liveTel.mode = m;
    if (m == 'TAKEOFF') liveTel.armed = true;
    notifyListeners();
  }

  void setArmed(bool v) {
    _send({'t': 'arm', 'v': v});
    liveTel.armed = v;
    if (v && kind == DeviceKind.drone && liveTel.pos[2] < .2) liveTel.mode = 'HOLD';
    _haptic();
    notifyListeners();
  }

  void goManual() {
    if (runner?.state == RunState.running) runner!.stop('Stopped: manual control');
    final s = liveTel;
    if (s.mode != 'MANUAL' && s.armed && !s.estop) setMode('MANUAL');
  }

  void emergencyStop() {
    session?.sendStop();
    final s = liveTel;
    s.estop = true;
    s.armed = false;
    s.mode = kind == DeviceKind.rocket
        ? (s.mode == 'COUNT' ? 'PAD' : s.mode)
        : kind == DeviceKind.bench
        ? 'IDLE'
        : 'HOLD';
    input.fillRange(0, 4, 0);
    jog = List.filled(6, 0);
    benchThrottle = 0;
    estopAck = false;
    _haptic(heavy: true);
    notifyListeners();
  }

  void resetStop() {
    _send({'t': 'reset'});
    liveTel.estop = false;
    estopAck = false;
    notifyListeners();
  }

  void ackStop() {
    estopAck = true;
    notifyListeners();
  }

  void unackStop() {
    estopAck = false;
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

  void setSpeed(double v) {
    speed = v;
    _send({'t': 'speed', 'v': v});
    notifyListeners();
  }

  void setJog(int i, double v) {
    jog[i] = v;
    _send({'t': 'jog', 'j': jog});
  }

  void setCart(List<double> v) => _send({'t': 'cart', 'v': v});

  /// "Test failsafe": withholds the control heartbeat for six seconds.
  void dropLink() {
    if (session == null) return;
    linkTest = 6;
    session!.holdHeartbeat = true;
    input.fillRange(0, 4, 0);
    notifyListeners();
  }

  void updateSettings(void Function(Settings) f) {
    final before = settings.toJson();
    f(settings);
    if (before['failsafe'] != settings.failsafe) _send({'t': 'fs', 'action': settings.failsafe, 'ms': 1800});
    if (before['rateHz'] != settings.rateHz) _send({'t': 'rate', 'hz': math.min(settings.rateHz, radio?.tlmHz ?? 60)});
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

  void _haptic({bool heavy = false}) {
    if (!settings.haptics) return;
    heavy ? HapticFeedback.heavyImpact() : HapticFeedback.selectionClick();
  }

  void hapticTick() => _haptic();

  // ------------------------------------------------------------ recording
  void startRec() {
    if (!hasDevice || replay != null) return;
    recording = true;
    recStart = t;
    _recFrames = [];
    _recAcc = 0;
    notifyListeners();
  }

  void stopRec() {
    if (!recording) return;
    final fr = _recFrames!;
    recording = false;
    _recFrames = null;
    if (fr.length > 5) {
      final d = device!;
      final r = Recording(
        id: 's${DateTime.now().millisecondsSinceEpoch}',
        name: 'Session ${sessions.length + 1}',
        deviceId: d.id,
        kind: d.kind,
        deviceName: d.name,
        date: _date(DateTime.now()),
        frames: fr,
        cloud: liveTel.cloud.length > 6000 ? liveTel.cloud.sublist(0, 6000) : List.of(liveTel.cloud),
        fresh: true,
        startedAt: DateTime.now().subtract(Duration(milliseconds: fr.length * 100)),
      );
      sessions.insert(0, r);
      lastSaved = r;
      store.saveRecording(r.toJson());
    }
    notifyListeners();
  }

  void openReplay(String id) {
    final s = sessions.where((x) => x.id == id).firstOrNull;
    if (s == null) return;
    if (recording) stopRec();
    final tl = Telemetry(s.kind)
      ..predict = false
      ..addPoints(s.cloud);
    replay = Replay(s, tl);
    s.fresh = false;
    hist.clear();
    notifyListeners();
  }

  void closeReplay() {
    if (replay == null) return;
    replay = null;
    hist.clear();
    notifyListeners();
  }

  void _replayStep(double dt) {
    final r = replay!;
    if (r.playing) {
      r.t += dt * r.speed;
      if (r.t >= r.session.dur) {
        r.t = r.session.dur;
        r.playing = false;
        notifyListeners();
      }
    }
    final fr = r.session.frames;
    if (fr.isEmpty) return;
    final i = math.min(fr.length - 1, (r.t * 10).floor());
    r.tel.applyFrame(fr[i]);
    // Frames are 10 Hz: interpolate the pose between this frame and the next.
    if (i + 1 < fr.length) {
      final a = fr[i], b = fr[i + 1], k = (r.t * 10 - i).clamp(0.0, 1.0);
      List<double> l(Map f, String key) => [for (final e in f[key] as List) (e as num).toDouble()];
      double n(Map f, String key) => (f[key] as num).toDouble();
      final pa = l(a, 'pos'), pb = l(b, 'pos');
      r.tel.pos = [for (var j = 0; j < 3; j++) pa[j] + (pb[j] - pa[j]) * k];
      final ja = l(a, 'joints'), jb = l(b, 'joints');
      if (ja.length == jb.length) r.tel.joints = [for (var j = 0; j < ja.length; j++) ja[j] + (jb[j] - ja[j]) * k];
      double ang(String key) {
        var d = n(b, key) - n(a, key);
        d = math.atan2(math.sin(d), math.cos(d));
        return n(a, key) + d * k;
      }

      r.tel.yaw = ang('yaw');
      r.tel.roll = ang('roll');
      r.tel.pitch = ang('pitch');
    }
    final p = r.session.kind == DeviceKind.arm;
    r.tel.trail = [
      for (var k = 0; k <= i; k += 3)
        p ? armFk((fr[k]['joints'] as List).map((e) => (e as num).toDouble()).toList())[5] : (fr[k]['pos'] as List).map((e) => (e as num).toDouble()).toList(),
    ];
  }

  void seekReplay(double t) {
    replay?.t = t;
    notifyListeners();
  }

  Future<void> deleteRecording(String id) async {
    sessions.removeWhere((s) => s.id == id);
    if (replay?.session.id == id) closeReplay();
    notifyListeners(); // update the list now; the file is removed in the background
    await store.deleteRecording(id);
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
    final ch = changedParams, dr = draftParams!;
    if (ch.isEmpty) return;
    paramWriting = true;
    _send({
      't': 'pset',
      'p': {for (final k in ch) k: dr[k]},
    });
    notifyListeners();
    Timer(const Duration(seconds: 4), () {
      if (paramWriting) {
        paramWriting = false;
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

  void runSequence(Sequence q) {
    if (!hasDevice || replay != null || liveTel.estop) return;
    runner = SequenceRunner(q, this);
    notifyListeners();
  }

  void clearRunner() {
    runner = null;
    notifyListeners();
  }

  @override
  List<double> get seqPos => liveTel.pos;
  @override
  List<double> get seqJoints => liveTel.joints;
  @override
  String get seqMode => liveTel.mode;
  @override
  bool get seqArmed => liveTel.armed;
  @override
  bool get seqStopped => liveTel.estop;
  @override
  bool get seqLinkLost => linkLost;
  @override
  void seqSetMode(String m) => setMode(m);
  @override
  void seqSetArmed(bool v) => setArmed(v);
  @override
  void seqSetSpeed(double v) => setSpeed(v);
  @override
  void seqCmd(String c, Map<String, dynamic> a) {
    if (c == 'throttle') benchThrottle = numOr(a['v'], 0);
    cmd(c, a);
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
    if (deviceId == d.id) await disconnect();
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
      serialPorts().forEach(_onFound);
    }
  }

  void stopScan() {
    _scanners = math.max(0, _scanners - 1);
    if (_scanners == 0) {
      _lan?.stop();
      _ble?.stop();
      _lan = null;
      _ble = null;
    }
  }

  void _onFound(Found f) {
    if (devices.any((d) => d.id == f.id)) return;
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
    );
    if (f.pair != null && f.pair == currentPairCode && info.transport != TransportKind.sim) {
      final key = List.generate(16, (_) => math.Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0')).join();
      final Transport tr = switch (info.transport) {
        TransportKind.ble => BleTransport(info.address, name: info.name),
        TransportKind.serial => SerialTransport(info.address),
        TransportKind.radio => SerialTransport(info.address, baud: radioModule(info.radio).baud, radio: radioModule(info.radio)),
        _ => UdpTransport(info.address),
      };
      try {
        await tr.open();
        final ok = tr.messages.firstWhere((m) => m['t'] == 'paired').timeout(const Duration(seconds: 5));
        tr.send({'t': 'pair', 'code': f.pair, 'key': key});
        await ok;
        info.key = key;
      } catch (e) {
        return 'Pairing failed: no answer from ${f.name}';
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
  void addManual(String name, String host, DeviceKind kind) {
    devices.add(DeviceInfo(id: 'udp:$host', name: name, kind: kind, transport: TransportKind.udp, address: host, via: 'Wi-Fi · $host'));
    _saveDevices();
    notifyListeners();
  }

  @override
  void dispose() {
    gamepads.dispose();
    session?.close();
    for (final s in _sims.values) {
      s.detach();
    }
    frame.dispose();
    super.dispose();
  }
}
