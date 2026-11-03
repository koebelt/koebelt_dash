// A virtual koebelt/link device. It runs the same physics as the design
// prototype (sim.js) and talks to the app only through protocol messages,
// exactly like firmware built on the libraries in libs/.
import 'dart:async';
import 'dart:math' as math;

import '../core/model.dart';
import '../core/sequence.dart';
import '../core/telemetry.dart';
import '../link/protocol.dart';
import '../link/transport.dart';
import 'environment.dart';
import 'param_defs.dart';
import 'sim_camera.dart';

final _rng = math.Random();
double _rnd([double a = 1]) => (_rng.nextDouble() * 2 - 1) * a;

class SimDevice {
  SimDevice(this.info) : kind = info.kind {
    params = {
      for (final c in paramDefs[kind]!)
        for (final g in c.groups)
          for (final p in g.params) p.key: p.def,
    };
    env = genEnv(kind);
    // Hobby-grade sensor sets: no radar on any simulated device.
    targets = [];
    battery = info.battery.toDouble();
    _resetForKind();
  }

  final DeviceInfo info;
  final DeviceKind kind;
  late Map<String, double> params;
  late List<List<double>> env;
  late List<SimTarget> targets;

  // ---- state (names follow sim.js) ----
  double t = 0;
  String mode = 'HOLD';
  bool armed = true, estop = false;
  List<double> input = [0, 0, 0, 0]; // lx ly rx ry
  List<double> jog = List.filled(6, 0);
  double speed = .5, gripper = .2;
  List<double> pos = [0, 0, 8], vel = [0, 0, 0];
  double yaw = 0, roll = 0, pitch = 0, yawRate = 0;
  List<double> acc = [0, 0, 9.81], gyro = [0, 0, 0];
  List<double> joints = [0, -0.5, 1.1, 0, 0.6, 0], torqueJ = List.filled(6, 0), ft = [0, 0, 0];
  double battery = 100, voltage = 16.4, current = 12, rssi = -52;
  double tuneNoise = 1;
  // rocket
  double maxAlt = 0, phaseT = 0, countdown = 0;
  List<double> rocketA = [0, 0, 0];
  List<String> pyro = ['OK', 'OK', 'OK', '-'];
  // bench
  double throttle = 0, thrOut = 0, rpm = 0, thrust = 0, torque = 0, temp = 24;
  String? seqKind, cutoff;
  double seqT = 0;
  // arm homing
  List<double>? _homeFrom;

  /// Arm home pose (settable) and the drone/rover home point in world metres.
  List<double> homePose = List.of(home);
  List<double> homeXY = [0, 0];
  List<double> _poseTo = home;
  double _homeT = 0, _poseDur = 1.4;
  // sequence targets
  double _takeoffAlt = 6;
  List<double> _goto = [0, 0, 8];
  bool _gotoActive = false;

  // failsafe (owned by the device, like the libraries)
  double fsTimeout = 1.8;
  String fsAction = 'HOLD';
  bool fsActive = false;
  double _sinceCtl = 0;
  bool _session = false;

  /// Onboard camera for vehicles (an HTTP MJPEG server on loopback).
  SimCamera? camera;

  // link
  LoopbackTransport? _link;
  StreamSubscription<Msg>? _sub;
  Timer? _timer;
  final _sw = Stopwatch();
  double _tlmAcc = 0, _stateAcc = 0, _pcAcc = 0, _trkAcc = 0;
  double rateHz = 30;
  List<double> _prevVel = [0, 0, 0];

  static const home = <double>[0, -0.5, 1.1, 0, 0.6, 0];

  double P(String k, double d) => params[k] ?? d;

  /// As a device is when it powers on: disarmed, in HOLD, on the ground.
  void _resetForKind() {
    mode = 'HOLD';
    armed = false;
    estop = false;
    pos = [0, 0, 0];
    if (kind == DeviceKind.rocket) {
      mode = 'PAD';
      armed = false;
      maxAlt = 0;
      phaseT = 0;
      pyro = ['OK', 'OK', 'OK', '-'];
    }
    if (kind == DeviceKind.bench) {
      mode = 'IDLE';
      armed = false;
      throttle = 0;
      rpm = 0;
      seqKind = null;
      temp = 24;
    }
    vel = [0, 0, 0];
    yaw = 0;
    joints = List.of(home);
  }

  // ---------------------------------------------------------------- proximity
  /// Proximity sensors as a hobby build fits them: four ultrasonic ones on a
  /// rover's bumpers; on a drone, a time-of-flight sensor forward and one
  /// down (its height above the ground).
  List<ProxSensor> get proxSensors => switch (kind) {
    DeviceKind.rover => const [
      ProxSensor('front', min: .02, max: 4, kind: 'ultrasonic'),
      ProxSensor('front_left', dir: -.6, min: .02, max: 4, kind: 'ultrasonic'),
      ProxSensor('front_right', dir: .6, min: .02, max: 4, kind: 'ultrasonic'),
      ProxSensor('rear', dir: math.pi, min: .02, max: 4, kind: 'ultrasonic'),
    ],
    DeviceKind.drone => const [
      ProxSensor('front', fov: .05, min: .05, max: 4, kind: 'tof'),
      ProxSensor('down', tilt: -1.571, fov: .05, min: .05, max: 8, kind: 'tof'),
    ],
    _ => const [],
  };

  /// What each sensor sees, in metres (−1: nothing in range): the scenery,
  /// the ball and the person the camera shows; the ground, for one looking down.
  List<double> proxReadings() {
    final ball = SimCamera.ballAt(t);
    final (feet, _) = SimCamera.personAt(t);
    final h = kind == DeviceKind.drone ? pos[2] : .3; // the sensors' height
    final out = <double>[];
    for (final s in proxSensors) {
      if (s.down) {
        out.add(pos[2] >= s.min && pos[2] <= s.max ? pos[2] : -1);
        continue;
      }
      // dir is clockwise from forward; yaw counter-clockwise from east.
      final a = yaw - s.dir, ca = math.cos(a), sa = math.sin(a), spread = math.tan(s.fov / 2);
      var best = double.infinity;
      // Something at (x, y, z), [r] wide and [vr] tall around it.
      void see(double x, double y, double z, double r, double vr) {
        final dx = x - pos[0], dy = y - pos[1];
        final along = dx * ca + dy * sa;
        if (along <= 0) return;
        final cone = along * spread + .05;
        if ((-dx * sa + dy * ca).abs() - r > cone || (z - h).abs() - vr > cone + .1) return;
        best = math.min(best, math.max(0.0, math.sqrt(dx * dx + dy * dy) - r));
      }

      for (final q in env) {
        if (q[2] > .05) see(q[0], q[1], q[2], 0, 0); // not the ground
      }
      see(ball[0], ball[1], ball[2], SimCamera.ballRadius, SimCamera.ballRadius);
      see(feet[0], feet[1], .88, .25, .88);
      out.add(best >= s.min && best <= s.max ? best : -1);
    }
    return out;
  }

  // ---------------------------------------------------------------- camera
  bool get hasCamera => kind.travels || kind == DeviceKind.rocket;

  /// Gimbal-levelled camera on drones, body-fixed on rovers, looking down
  /// along the body on rockets.
  CamPose cameraPose() => switch (kind) {
    DeviceKind.drone => CamPose([pos[0], pos[1], pos[2] - .1], yaw, -.22, 0),
    DeviceKind.plane => CamPose([pos[0] + math.cos(yaw) * .5, pos[1] + math.sin(yaw) * .5, math.max(pos[2], .3)], yaw, pitch - .12, roll),
    DeviceKind.rocket => CamPose([pos[0] + .15, pos[1], pos[2] + 2.4], yaw, -math.pi / 2 + .02, roll * .3), // nose cam looking aft
    _ => CamPose([pos[0] + math.cos(yaw) * .4, pos[1] + math.sin(yaw) * .4, .55], yaw, pitch - .06, roll),
  };

  String _osd() {
    final hdg = (((90 - yaw * 57.3) % 360 + 360) % 360).round().toString().padLeft(3, '0');
    final sp = hypot2(vel[0], vel[1]).toStringAsFixed(1);
    return switch (kind) {
      DeviceKind.drone || DeviceKind.plane => 'SIM CAM   ALT ${pos[2].toStringAsFixed(1)} M   HDG $hdg   $sp M/S',
      DeviceKind.rocket => 'SIM CAM   $mode   ALT ${pos[2].toStringAsFixed(0)} M',
      _ => 'SIM CAM   HDG $hdg   $sp M/S',
    };
  }

  // ---------------------------------------------------------------- link
  /// Power on and accept a session on [link].
  void attach(LoopbackTransport link) {
    detach();
    _link = link;
    if (hasCamera) {
      final cam = camera ??= SimCamera(kind: kind, pose: cameraPose, world: env, osd: _osd, now: () => t);
      unawaited(cam.start().catchError((_) {}));
    }
    _sub = link.deviceInbox.listen(_onMsg);
    _sw
      ..reset()
      ..start();
    var last = 0.0;
    _timer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      final now = _sw.elapsedMicroseconds / 1e6;
      final dt = math.min(.05, now - last);
      last = now;
      _tick(dt);
    });
  }

  void detach() {
    unawaited(camera?.stop());
    _timer?.cancel();
    _sub?.cancel();
    _timer = null;
    _sub = null;
    _link = null;
    _session = false;
  }

  void _send(Msg m) => _link?.deviceSend(m);

  void _onMsg(Msg m) {
    switch (m['t']) {
      case 'hello':
        _session = true;
        _sinceCtl = 0;
        _send({
          't': 'hello',
          'v': protocolVersion,
          'id': info.id,
          'name': info.name,
          'kind': kind.name,
          'model': info.model,
          if (info.body.isNotEmpty) 'body': info.body,
          'fw': '2.4.1',
          'lib': 'sim/1.0.0',
          'sensors': info.sensors,
          'seq': 64,
          if (proxSensors.isNotEmpty) 'prox': [for (final p in proxSensors) p.toJson()],
          if (camera?.running ?? false)
            'video': [
              {'id': 'cam', 'url': camera!.url, 'fmt': 'mjpeg', 'label': kind == DeviceKind.rocket ? 'Down cam' : 'FPV'},
            ],
          'ok': true,
        });
        _sendParams();
        _sendState();
        _sendCloud();
      case 'bye':
        _session = false;
        // A stored sequence carries on; otherwise a flying drone holds.
        if (kind.flies && armed && pos[2] > .2 && !_seqRunning) mode = 'HOLD';
        input = [0, 0, 0, 0];
      case 'ctl':
        _sinceCtl = 0;
        if (fsActive) fsActive = false;
        input = [numOr(m['lx'], 0), numOr(m['ly'], 0), numOr(m['rx'], 0), numOr(m['ry'], 0)];
      case 'jog':
        jog = [for (final v in m['j'] as List) (v as num).toDouble()];
      case 'cart':
        final v = [for (final x in m['v'] as List) (x as num).toDouble()];
        jog = [v[1], v[0], -v[2], 0, 0, 0];
      case 'mode':
        if (estop) break;
        mode = m['m'];
        _gotoActive = false;
        _homeFrom = null;
        _holdAt = null;
        if (kind.flies && mode == 'TAKEOFF') armed = true;
        _sendState();
      case 'arm':
        if (estop) break;
        armed = m['v'] == true;
        if (armed && kind.flies && pos[2] < .2) mode = 'HOLD';
        // A legged robot stands up when armed and sits down when disarmed.
        if (kind.walks) stance = armed ? 'stand' : 'sit';
        _sendState();
      case 'stop':
        _stop();
      case 'reset':
        estop = false;
        _sendState();
      case 'speed':
        speed = numOr(m['v'], .5).clamp(.1, 1);
      case 'rate':
        rateHz = numOr(m['hz'], 30).clamp(1, 60);
      case 'fs':
        fsAction = '${m['action'] ?? fsAction}';
        fsTimeout = numOr(m['ms'], fsTimeout * 1000) / 1000;
      case 'ping':
        _send({'t': 'pong', 'ts': m['ts']});
      case 'pset':
        final p = (m['p'] as Map).cast<String, dynamic>();
        final keys = <String>[];
        p.forEach((k, v) {
          if (params.containsKey(k) && v is num) {
            params[k] = v.toDouble();
            keys.add(k);
          }
        });
        if (kind == DeviceKind.drone) {
          tuneNoise = math
              .max(1.0, math.pow((P('RATE_RLL_P', .135) / .135) * (P('RATE_PIT_P', .135) / .135), .9) * math.max(1.0, P('RATE_RLL_D', .0036) / .0036))
              .toDouble();
        }
        Timer(const Duration(milliseconds: 700), () => _send({'t': 'pack', 'ok': true, 'keys': keys}));
      case 'cmd':
        _cmd('${m['c']}', (m['a'] as Map?)?.cast<String, dynamic>() ?? const {});
      case 'seq':
        _seqStore(m);
      case 'seqrun':
        final q = _seqStored;
        if (q == null || q.id != m['id'] || estop) break;
        _seq = SequenceRunner(q, _SimSeqHost(this));
        // Running the app's sequence: AUTO (protocol/PROTOCOL.md, Modes).
        if (armed && _modal) mode = 'AUTO';
        _sendState();
      case 'seqctl':
        final r = _seq;
        if (r == null) break;
        switch (m['c']) {
          case 'pause':
            r.pause();
          case 'resume':
            r.resume();
          case 'stop':
            r.stop('Stopped from the app');
        }
        _sendState();
    }
  }

  // ---------------------------------------------------------------- stored sequences
  // The device side of protocol/PROTOCOL.md "Sequences on the device": the
  // same runner the app uses, with this simulator as its host.
  Sequence? _seqStored;
  SequenceRunner? _seq;
  (RunState, int)? _seqLast;

  /// The kinds that use HOLD, MANUAL and AUTO.
  bool get _modal => kind.travels || kind == DeviceKind.arm || kind == DeviceKind.generic;

  bool get _seqRunning => _seq?.state == RunState.running || _seq?.state == RunState.paused;

  void _seqStore(Msg m) {
    final steps = m['steps'];
    String? err;
    final parsed = <SeqStep>[];
    if (steps is! List || steps.isEmpty) {
      err = 'No steps';
    } else if (steps.length > 64) {
      err = 'Too many steps: this device stores 64';
    } else {
      for (final w in steps) {
        final st = w is List && w.isNotEmpty ? SeqStep.fromWire(w) : null;
        if (st == null || stepDef(kind, st.type) == null) {
          err = 'Step "${st?.type ?? w}" is not supported on this device';
          break;
        }
        parsed.add(st);
      }
    }
    if (err == null) _seqStored = Sequence(id: '${m['id']}', name: '', kind: kind, steps: parsed);
    _send({'t': 'seqack', 'id': m['id'], 'ok': err == null, 'err': ?err});
  }

  void _seqTick(double dt) {
    final r = _seq;
    if (r == null) return;
    r.tick(dt);
    final now = (r.state, r.index);
    if (now != _seqLast) {
      _seqLast = now;
      // Done or stopped: AUTO ends, it holds.
      if ((r.state == RunState.done || r.state == RunState.failed) && mode == 'AUTO') mode = 'HOLD';
      _sendState();
    }
  }

  Map<String, dynamic>? get _seqExt {
    final r = _seq;
    if (r == null) return null;
    return {
      'id': r.seq.id,
      'i': r.index,
      'n': r.seq.steps.length,
      'st': switch (r.state) {
        RunState.running => 'run',
        RunState.paused => 'pause',
        RunState.done => 'done',
        RunState.failed => 'fail',
      },
      if (r.message.isNotEmpty) 'msg': r.message,
      if (r.stepProgress != null) 'p': (r.stepProgress! * 100).round() / 100,
    };
  }

  void _cmd(String c, Map<String, dynamic> a) {
    final live = armed && !estop;
    switch (c) {
      case 'home' || 'pose':
        if (!live) return;
        final to = c == 'home' ? homePose : [for (final v in (a['j'] as List? ?? homePose)) (v as num).toDouble()];
        if (to.length < 6) return;
        mode = 'MANUAL';
        _homeFrom = List.of(joints);
        _poseTo = to;
        var span = 0.0;
        for (var i = 0; i < 6; i++) {
          span = math.max(span, (to[i] - joints[i]).abs());
        }
        // joint speed MAX_J_SPD (deg/s) scaled by the app's speed limit
        _poseDur = math.max(.6, span / (P('MAX_J_SPD', 180) / 57.3 * speed * 1.2));
        _homeT = 0;
      case 'sethome':
        // Arms: current (or given) joints become the home pose. Vehicles: current position becomes the origin.
        if (kind == DeviceKind.arm) {
          final j = a['j'];
          homePose = j is List && j.length >= 6 ? [for (final v in j) (v as num).toDouble()] : List.of(joints);
        } else if (kind.travels) {
          homeXY = [pos[0], pos[1]];
          _goto = [pos[0], pos[1], pos[2]];
        }
        _send({'t': 'log', 'lvl': 'info', 'msg': 'Home set'});
      case 'takeoff':
        if (estop || !kind.flies) return;
        armed = true;
        _takeoffAlt = numOr(a['alt'], 6).clamp(1, P('FENCE_ALT', 120));
        mode = 'TAKEOFF';
      case 'goto':
        if (!live || !kind.travels) return;
        _goto = [numOr(a['x'], pos[0] - homeXY[0]) + homeXY[0], numOr(a['y'], pos[1] - homeXY[1]) + homeXY[1], numOr(a['z'], pos[2])];
        mode = 'AUTO';
        _gotoActive = true;
      case 'stance':
        // Sitting needs it still; standing back up works while armed.
        final v = '${a['v'] ?? ''}';
        if (v != 'stand' && v != 'sit') return;
        stance = v;
        if (v == 'sit') _gotoActive = false;
        _sendState();
      case 'gait':
        final v = '${a['v'] ?? ''}';
        if (v != 'walk' && v != 'trot') return;
        gait = v;
        _sendState();
      case 'gripper':
        if (!live) return;
        gripper = numOr(a['v'], gripper);
      case 'countdown':
        if (!live || mode != 'PAD') return;
        mode = 'COUNT';
        countdown = numOr(a['s'], P('COUNTDOWN', 10));
      case 'abort':
        if (mode == 'COUNT') {
          mode = 'PAD';
          armed = false;
        }
      case 'deploy':
        final ch = (a['ch'] as num?)?.toInt() ?? 0;
        if (pyro[ch] != 'OK') return;
        if (ch == 0 && mode == 'COAST') {
          pyro[0] = 'FIRED';
          mode = 'DROGUE';
          phaseT = 0;
        } else if (ch == 1 && (mode == 'COAST' || mode == 'DROGUE')) {
          pyro[1] = 'FIRED';
          mode = 'MAIN';
          phaseT = 0;
        }
      case 'reset':
        if (kind == DeviceKind.rocket) {
          mode = 'PAD';
          pos = [0, 0, 0];
          vel = [0, 0, 0];
          maxAlt = 0;
          phaseT = 0;
          pyro = ['OK', 'OK', 'OK', '-'];
          armed = false;
        }
      case 'throttle':
        if (seqKind != null) return;
        throttle = numOr(a['v'], 0).clamp(0, 1);
        mode = throttle > 0 ? 'MANUAL' : 'IDLE';
      case 'seq':
        final k = a['kind'];
        if (k == null) {
          seqKind = null;
          throttle = 0;
          mode = 'IDLE';
        } else if (live) {
          seqKind = '$k';
          seqT = 0;
          mode = seqKind!;
        }
      case 'clear':
        if (mode == 'CUTOFF') mode = 'IDLE';
        cutoff = null;
    }
    _sendState();
  }

  void _stop() {
    _seq?.stop('Stopped: emergency stop');
    _gotoActive = false;
    estop = true;
    armed = false;
    if (kind.walks) stance = 'sit';
    mode = kind == DeviceKind.rocket
        ? (mode == 'COUNT' ? 'PAD' : mode)
        : kind == DeviceKind.bench
        ? 'IDLE'
        : 'HOLD';
    throttle = 0;
    seqKind = null;
    input = [0, 0, 0, 0];
    jog = List.filled(6, 0);
    _sendState();
  }

  // ---------------------------------------------------------------- loop
  void _tick(double dt) {
    step(dt);
    _tlmAcc += dt;
    _stateAcc += dt;
    _pcAcc += dt;
    _trkAcc += dt;
    if (!_session) return;
    if (_tlmAcc >= 1 / rateHz) {
      _tlmAcc = 0;
      _send({'t': 'tlm', 'ts': (t * 1000).round(), 'd': tlmData()});
    }
    if (_stateAcc >= .5) _sendState();
    if (_pcAcc >= 1) {
      _pcAcc = 0;
      _sendCloud();
    }
    if (_trkAcc >= .1 && targets.isNotEmpty) {
      _trkAcc = 0;
      _send({
        't': 'tracks',
        'd': [
          for (final g in targets) [g.id, g.r, g.a],
        ],
      });
    }
    _link?.delayMs = (14 + hypot2(pos[0], pos[1]) * .12) / 2;
  }

  void _sendState() {
    _stateAcc = 0;
    _send(stateMsg());
  }

  Msg stateMsg() => {
    't': 'state',
    'mode': mode,
    'armed': armed,
    'estop': estop,
    'fs': fsActive,
    'ext': {
      if (kind == DeviceKind.rocket) 'pyro': pyro,
      if (kind.walks) ...{'stance': stance, 'gait': gait},
      if (cutoff != null) 'cutoff': cutoff,
      if (seqKind != null) 'seq': {'kind': seqKind, 't': seqT},
      'run': ?_seqExt,
    },
  };

  void _sendParams() {
    final cats = paramDefs[kind]!;
    _send({
      't': 'params',
      'p': [
        for (final c in cats)
          for (final g in c.groups)
            for (final p in g.params) [p.key, params[p.key], p.min, p.max, p.step, p.unit, p.label],
      ],
      'layout': [
        for (final c in cats)
          for (final g in c.groups)
            {
              'cat': c.cat,
              'name': g.name,
              'chart': ?g.chart,
              'keys': [for (final p in g.params) p.key],
            },
      ],
    });
  }

  /// A lidar scan: world points within sensor range of the device.
  /// Only the rover carries a lidar: a 2D 360° scanner (RPLidar class, 12 m)
  /// mounted 25 cm above ground. Obstacles in the scan plane are returned.
  void _sendCloud() {
    if (kind != DeviceKind.rover) return;
    final pts = [
      for (final q in env)
        if (q[2] > .1 && q[2] < 1.5 && hypot2(q[0] - pos[0], q[1] - pos[1]) <= 12) [q[0] - homeXY[0], q[1] - homeXY[1], .25],
    ];
    for (var o = 0; o < pts.length; o += 1500) {
      final chunk = pts.sublist(o, math.min(pts.length, o + 1500));
      _send({'t': 'pc', 'f': 'i16cm', 'n': chunk.length, 'd': encodePoints(chunk)});
    }
  }

  /// Telemetry each kind of hobby build would realistically report.
  Map<String, dynamic> tlmData() {
    final g = gps();
    final d = <String, dynamic>{
      'bat': [voltage, current, battery],
      'rssi': [rssi],
    };
    switch (kind) {
      case DeviceKind.drone || DeviceKind.plane || DeviceKind.rover || DeviceKind.boat || DeviceKind.legged || DeviceKind.rocket:
        // IMU, baro/rangefinder or wheel odometry, compass, GNSS
        d['imu'] = [...acc, ...gyro];
        d['att'] = [roll, pitch, yaw];
        d['pos'] = [pos[0] - homeXY[0], pos[1] - homeXY[1], pos[2]]; // local frame: metres from home
        d['vel'] = vel;
        d['gps'] = [g[0], g[1], pos[2], kind.drives ? 11 : 14];
        if (proxSensors.isNotEmpty) d['prox'] = [for (final v in proxReadings()) (v * 1000).round() / 1000];
        if (kind == DeviceKind.rocket) d['rocket'] = [maxAlt, phaseT, countdown];
      case DeviceKind.arm:
        // servo / stepper encoders and motor current; tool pose from forward kinematics
        final tip = armFk(joints)[5];
        d['joints'] = joints;
        d['tool'] = [...tip, gripper];
      case DeviceKind.bench:
        // load cell, optical tach, shunt, thermistor, vibration IMU
        d['imu'] = [...acc, ...gyro];
        d['thrust'] = [thrust, torque];
        d['rpm'] = [rpm];
        d['temp'] = [temp];
        d['throttle'] = [thrOut];
      case DeviceKind.generic:
        d['imu'] = [...acc, ...gyro];
    }
    return d;
  }

  List<double> gps() {
    const la0 = 47.37690, lo0 = 8.54170;
    final o = _field;
    return [la0 + (pos[1] + o[1]) / 111111, lo0 + (pos[0] + o[0]) / (111111 * math.cos(47.3769 * math.pi / 180))];
  }

  /// Where on the field this device starts (metres east, north), so several
  /// simulated devices show apart on the map. Numbered copies step aside.
  late final List<double> _field = () {
    const byKind = {
      DeviceKind.rover: [45.0, -30.0],
      DeviceKind.plane: [-130.0, -20.0],
      DeviceKind.boat: [90.0, 70.0],
      DeviceKind.legged: [-25.0, 35.0],
      DeviceKind.rocket: [-70.0, 55.0],
      DeviceKind.arm: [20.0, 60.0],
      DeviceKind.bench: [-40.0, -50.0],
    };
    final k = byKind[kind] ?? const [0.0, 0.0];
    final n = RegExp(r'-(\d+)$').firstMatch(info.id), m = n == null ? 0 : int.parse(n.group(1)!) - 1;
    return [k[0] + m * 18.0, k[1] - m * 12.0];
  }();

  /// Telemetry snapshot in the app's recording format (for seeded sessions).
  Map<String, dynamic> frame() {
    final tl = Telemetry(kind)
      ..applyTlm(tlmData())
      ..applyState(stateMsg())
      ..targets = [for (final g in targets) Track(g.id, g.r, g.a)];
    return tl.snapshot();
  }

  // ---------------------------------------------------------------- physics
  void step(double dt) {
    t += dt;
    if (_session) _sinceCtl += dt;
    _seqTick(dt);
    // While a stored sequence runs, a lost link does not interrupt it.
    if (_session && !fsActive && _sinceCtl > fsTimeout && kind != DeviceKind.rocket && !_seqRunning) {
      fsActive = true;
      input = [0, 0, 0, 0];
      jog = List.filled(6, 0);
      if (kind.flies) {
        mode = fsAction;
      } else if (kind == DeviceKind.bench) {
        throttle = 0;
        seqKind = null;
        mode = 'IDLE';
      } else {
        mode = 'HOLD';
      }
      _send({'t': 'log', 'lvl': 'warn', 'msg': 'Failsafe: no control for ${fsTimeout.toStringAsFixed(1)} s'});
      _sendState();
    }
    final live = armed && !estop;
    final inp = input;
    switch (kind) {
      case DeviceKind.drone:
        _drone(dt, live, inp);
      case DeviceKind.plane:
        _plane(dt, live, inp);
      case DeviceKind.rover:
        _rover(dt, live, inp);
      case DeviceKind.boat:
        _rover(dt, live, inp, boat: true);
      case DeviceKind.legged:
        _legged(dt, live, inp);
      case DeviceKind.rocket:
        _rocket(dt, live);
      case DeviceKind.bench:
        _bench(dt, live);
      default:
        _arm(dt, live);
    }
    final a = [for (var i = 0; i < 3; i++) (vel[i] - _prevVel[i]) / math.max(dt, 1e-3)];
    _prevVel = List.of(vel);
    final vib =
        tuneNoise *
        switch (kind) {
          DeviceKind.bench => .05 + rpm / 9000 * .9,
          DeviceKind.rocket => mode == 'BOOST' ? 1.2 : .05,
          DeviceKind.drone => pos[2] > .1 ? .08 : .03,
          DeviceKind.plane => pos[2] > .1 ? .12 : .2 * hypot2(vel[0], vel[1]) / 10,
          DeviceKind.rover => .25 * hypot2(vel[0], vel[1]),
          DeviceKind.boat => .05,
          DeviceKind.legged => .1 + hypot2(vel[0], vel[1]) * .4,
          _ => .03,
        };
    acc = [a[0] * .15 + _rnd(vib), a[1] * .15 + _rnd(vib), 9.81 + a[2] * .15 + _rnd(vib)];
    if (kind == DeviceKind.rocket) acc = [rocketA[0] + _rnd(vib), rocketA[1] + _rnd(vib), rocketA[2] + 9.81 + _rnd(vib)];
    gyro = [roll * 3 + _rnd(vib * .2), pitch * 3 + _rnd(vib * .2), yawRate + _rnd(vib * .1)];
    final drain = switch (kind) {
      DeviceKind.arm || DeviceKind.bench => 0.0,
      DeviceKind.rocket => .002,
      _ => current * .0012,
    };
    battery = math.max(0, battery - dt * drain);
    final (base, span) = switch (kind) {
      DeviceKind.drone => (13.2, 3.6),
      DeviceKind.plane || DeviceKind.boat => (14.0, 2.8),
      DeviceKind.rover => (22.0, 3.2),
      DeviceKind.legged => (7.0, 1.4),
      DeviceKind.rocket => (7.0, 1.4),
      DeviceKind.bench => (22.2, 0.0),
      _ => (48.0, 0.0),
    };
    voltage = base + battery / 100 * span - current * .02 + _rnd(.02);
    rssi = -48 - hypot2(pos[0], pos[1]) * .35 + _rnd(2);
    for (final g in targets) {
      g.a += g.va * dt;
      g.r += g.vr * dt;
      if (g.r > 45 || g.r < 6) g.vr *= -1;
    }
  }

  void _drone(double dt, bool live, List<double> inp) {
    var v = [0.0, 0, 0];
    var yr = 0.0;
    if (!live) {
      v = [0, 0, pos[2] > 0 ? -4 : 0];
    } else if (mode == 'MANUAL' || (mode == 'AUTO' && !_gotoActive)) {
      // MANUAL: the operator's sticks; AUTO without a goto: the sticks dash
      // sends for a script (centred: it holds).
      final f = inp[3] * 8 * speed * 2, rt = inp[2] * 8 * speed * 2;
      final c = math.cos(yaw), s = math.sin(yaw);
      v = [c * f + s * rt, s * f - c * rt, inp[1] * 3];
      yr = -inp[0] * 1.4;
    } else if (mode == 'LAND') {
      v = [0, 0, -1.5];
      if (pos[2] <= .05) {
        armed = false;
        mode = 'HOLD';
        _sendState();
      }
    } else if (mode == 'AUTO' && _gotoActive) {
      final d = [for (var i = 0; i < 3; i++) _goto[i] - pos[i]];
      final dist = hypot3(d[0], d[1], d[2]);
      final vmax = math.min(P('MAX_SPD_XY', 12), 8) * speed * 2;
      final sp = math.min(vmax, dist * .8);
      v = dist > 1e-3 ? [for (final x in d) x / dist * sp] : [0, 0, 0];
      v[2] = v[2].clamp(-P('MAX_DESC', 1.5), P('MAX_CLIMB', 3));
      if (hypot2(d[0], d[1]) > 1) {
        var dy = math.atan2(d[1], d[0]) - yaw;
        dy = math.atan2(math.sin(dy), math.cos(dy));
        yr = dy * 1.5;
      }
      if (dist < .4) {
        mode = 'HOLD';
        _gotoActive = false;
        _sendState();
      }
    } else if (mode == 'TAKEOFF') {
      v = [0, 0, (_takeoffAlt - pos[2]) * .9];
      if (pos[2] > _takeoffAlt - .2) {
        mode = 'HOLD';
        _sendState();
      }
    } else if (mode == 'RTH') {
      v = [(homeXY[0] - pos[0]) * .5, (homeXY[1] - pos[1]) * .5, (8 - pos[2]) * .6];
      if (hypot2(pos[0] - homeXY[0], pos[1] - homeXY[1]) < .5) {
        mode = 'LAND';
        _sendState();
      }
    }
    final k = math.min(1.0, dt * 3);
    vel = [for (var i = 0; i < 3; i++) vel[i] + (v[i] - vel[i]) * k];
    yawRate += (yr - yawRate) * k;
    pos = [for (var i = 0; i < 3; i++) pos[i] + vel[i] * dt];
    if (pos[2] < 0) {
      pos[2] = 0;
      vel[2] = 0;
    }
    yaw += yawRate * dt;
    final c = math.cos(yaw), s = math.sin(yaw);
    final fw = c * vel[0] + s * vel[1], lt = -s * vel[0] + c * vel[1];
    final air = pos[2] > .1 ? 1.0 : 0.0;
    pitch += ((-fw * .06 + _rnd(.01)) * air - pitch) * k;
    roll += ((-lt * .06 + _rnd(.01)) * air - roll) * k; // right wing down when sliding right
    current = live && pos[2] > .1 ? 14 + vel[2].abs() * 4 + hypot2(fw, lt) * .6 + _rnd(.8) : .4;
  }

  /// A ground robot, or with [boat] a boat: it keeps drifting, turns only
  /// while it moves, and the current pushes it.
  void _rover(double dt, bool live, List<double> inp, {bool boat = false}) {
    var sp = 0.0, tu = 0.0;
    if (live && mode == 'AUTO' && _gotoActive) {
      final dx = _goto[0] - pos[0], dy = _goto[1] - pos[1], dist = hypot2(dx, dy);
      var a = math.atan2(dy, dx) - yaw;
      a = math.atan2(math.sin(a), math.cos(a));
      // turn on the spot when facing away (a boat turns ahead slowly), slow down on approach
      sp = a.abs() > 1.2 && !boat ? 0 : math.min(P('MAX_SPD', 4) * speed * 2, dist * .9) * (boat ? math.max(.35, math.cos(a)) : math.cos(a).clamp(0, 1));
      tu = a * 1.8;
      if (dist < (boat ? P('WP_RADIUS', 1.5) * .6 : .3)) {
        mode = 'HOLD';
        _gotoActive = false;
        _sendState();
      }
    } else if (live && (mode == 'MANUAL' || mode == 'AUTO')) {
      // MANUAL: the operator's sticks; AUTO: the sticks dash sends for a script.
      sp = inp[3] * 4 * speed * 2;
      if (info.body == 'balancer') sp *= .4; // a balancing robot is slower
      tu = -inp[0] * 1.2 - inp[2] * .6;
    }
    final k = math.min(1.0, dt * (boat ? .8 : 2.5));
    final dir = math.cos(math.atan2(vel[1], vel[0]) - yaw);
    final cur = hypot2(vel[0], vel[1]) * (dir == 0 ? 1 : dir.sign);
    final ns = cur + (sp - cur) * k;
    // A boat's rudder needs water flowing past it.
    if (boat) tu *= (ns.abs() / 1.5).clamp(.15, 1.0);
    yawRate += (tu - yawRate) * k;
    yaw += yawRate * dt;
    vel = [math.cos(yaw) * ns, math.sin(yaw) * ns, 0];
    // A slow current to the north-east.
    final drift = boat ? const [.12, .06] : const [0.0, 0.0];
    pos = [pos[0] + (vel[0] + drift[0]) * dt, pos[1] + (vel[1] + drift[1]) * dt, 0];
    pitch = _rnd(.015) + math.sin(t * (boat ? 1.1 : 3)) * (boat ? .03 : .01 * ns);
    // On two wheels it balances: it leans into what it does, forward to
    // speed up, back to brake, and sways a little standing still.
    if (info.body == 'balancer') pitch = (-(ns - cur) / math.max(dt, 1e-3) * .06 - ns * .04).clamp(-.35, .35) + math.sin(t * 1.7) * .012;
    roll = _rnd(.015) + yawRate * ns * .02 + (boat ? math.sin(t * .8) * .04 : 0);
    current = 2 + ns.abs() * 2.2 + _rnd(.3);
  }

  /// A fixed-wing plane: it keeps flying forward above its minimum airspeed,
  /// turns by banking, circles to hold, takes off along a run and lands in a
  /// glide.
  void _plane(double dt, bool live, List<double> inp) {
    final minSp = P('ARSPD_MIN', 11), cruise = P('TRIM_ARSPD', 15), maxSp = P('ARSPD_MAX', 22);
    final bankMax = P('ROLL_LIMIT', 45) / 57.3;
    final air = pos[2] > .3;
    var gs = hypot2(vel[0], vel[1]); // speed along the heading
    var tSp = cruise, bank = 0.0, climb = 0.0;
    // Bank towards [heading], within the limit. Roll is positive with the
    // right wing down, and yaw counter-clockwise: a left turn banks negative.
    double steer(double heading) {
      var a = heading - yaw;
      a = math.atan2(math.sin(a), math.cos(a));
      return (-a * 1.4).clamp(-bankMax, bankMax);
    }

    // Circle around the current point (or home) at the loiter radius.
    double loiter(List<double> c) {
      final r = P('LOIT_RADIUS', 40), dx = pos[0] - c[0], dy = pos[1] - c[1], d = hypot2(dx, dy);
      final out = math.atan2(dy, dx), tangent = out + math.pi / 2;
      // Turning left round the centre, pulled in or out to the radius.
      return steer(tangent + ((d - r) / r).clamp(-1.0, 1.0) * .9);
    }

    if (!live) {
      // Disarmed or stopped: no thrust; it glides down, slowing.
      tSp = air ? minSp : 0;
      climb = air ? -5 : 0;
    } else if (!air && mode != 'TAKEOFF' && mode != 'LAND' && !(mode == 'MANUAL' && inp[1] > .2)) {
      tSp = 0; // on the ground, waiting
    } else if (mode == 'MANUAL' || (mode == 'AUTO' && !_gotoActive)) {
      tSp = minSp + (inp[1] + 1) / 2 * (maxSp - minSp);
      bank = inp[2] * bankMax;
      climb = air || gs > minSp ? inp[3] * P('CLMB_MAX', 4) : 0;
      _holdAt = null;
    } else if (mode == 'TAKEOFF') {
      // A run along the heading, then a climb to the take-off height.
      tSp = cruise;
      climb = gs > minSp ? P('CLMB_MAX', 4) : 0;
      if (pos[2] > _takeoffAlt - .5) {
        mode = 'HOLD';
        _sendState();
      }
    } else if (mode == 'HOLD') {
      _holdAt ??= [pos[0], pos[1], math.max(pos[2], 20)];
      bank = loiter(_holdAt!);
      climb = (_holdAt![2] - pos[2]) * .5;
    } else if (mode == 'AUTO' && _gotoActive) {
      final dx = _goto[0] - pos[0], dy = _goto[1] - pos[1];
      bank = steer(math.atan2(dy, dx));
      climb = (_goto[2] - pos[2]) * .5;
      tSp = cruise * (.7 + speed * .6);
      if (hypot2(dx, dy) < P('WP_RADIUS', 15)) {
        mode = 'HOLD';
        _gotoActive = false;
        _holdAt = [pos[0], pos[1], _goto[2]];
        _sendState();
      }
    } else if (mode == 'RTH') {
      final dx = homeXY[0] - pos[0], dy = homeXY[1] - pos[1];
      bank = hypot2(dx, dy) > P('LOIT_RADIUS', 40) * 1.5 ? steer(math.atan2(dy, dx)) : loiter(homeXY);
      climb = (P('RTL_ALT', 40) - pos[2]) * .5;
      if (hypot2(dx, dy) < P('LOIT_RADIUS', 40) * 1.5 && (pos[2] - P('RTL_ALT', 40)).abs() < 3) {
        mode = 'LAND';
        _sendState();
      }
    } else if (mode == 'LAND') {
      // A glide down that keeps turning back towards home; it rolls to a
      // stop once on the ground.
      tSp = air ? minSp : 0;
      climb = air ? -2 : 0;
      if (air && hypot2(homeXY[0] - pos[0], homeXY[1] - pos[1]) > 25) bank = steer(math.atan2(homeXY[1] - pos[1], homeXY[0] - pos[0])) * .6;
      if (!air && gs < .5) {
        armed = false;
        mode = 'HOLD';
        _holdAt = null;
        _sendState();
      }
    }
    climb = climb.clamp(-P('SINK_MAX', 3) * (live ? 1 : 2), P('CLMB_MAX', 4));
    gs += (tSp - gs) * math.min(1.0, dt * (air ? .6 : 1.2));
    if (gs < 0) gs = 0;
    roll += (bank - roll) * math.min(1.0, dt * 2);
    // Coordinated turn: rate = g · tan(bank) / speed, right bank turning right.
    yawRate = air && gs > 1 ? -9.81 * math.tan(roll) / gs : 0;
    yaw += yawRate * dt;
    vel = [math.cos(yaw) * gs, math.sin(yaw) * gs, climb];
    pos = [pos[0] + vel[0] * dt, pos[1] + vel[1] * dt, math.max(0.0, pos[2] + climb * dt)];
    if (pos[2] <= 0) {
      vel[2] = 0;
      if (roll.abs() > .05) roll *= .9;
    }
    pitch = gs > 1 ? math.atan2(vel[2], gs) + _rnd(.01) : 0;
    current = live && tSp > 0 ? 4 + (tSp - minSp).abs() * 1.2 + math.max(0.0, climb) * 2 + _rnd(.5) : .3;
  }

  /// Where a plane circles while it holds.
  List<double>? _holdAt;

  /// Legged robots: standing or sitting, the gait, and where in its stride.
  String stance = 'sit', gait = 'walk';

  /// A legged robot: walks forward, sideways and turning at once, its body
  /// at a height the left stick trims; sitting, it does not move.
  void _legged(double dt, bool live, List<double> inp) {
    final trot = gait == 'trot';
    final vmax = P('MAX_SPD', .6) * (trot ? 1.6 : 1) * speed * 2;
    var fwd = 0.0, side = 0.0, turn = 0.0, trim = 0.0;
    final up = live && stance == 'stand';
    if (up && mode == 'AUTO' && _gotoActive) {
      final dx = _goto[0] - pos[0], dy = _goto[1] - pos[1], dist = hypot2(dx, dy);
      var a = math.atan2(dy, dx) - yaw;
      a = math.atan2(math.sin(a), math.cos(a));
      // turn on the spot when facing away, slow down on approach
      fwd = a.abs() > .8 ? 0 : math.min(vmax, dist * .8) / math.max(vmax, 1e-3);
      turn = (a * 1.5).clamp(-1.0, 1.0);
      if (dist < .2) {
        mode = 'HOLD';
        _gotoActive = false;
        _sendState();
      }
    } else if (up && (mode == 'MANUAL' || mode == 'AUTO')) {
      fwd = inp[3];
      side = inp[2];
      turn = -inp[0];
      trim = inp[1];
    }
    // A humanoid stands about four times as tall, and crouches further.
    final tall = info.body == 'humanoid' ? 3.8 : 1.0;
    final h = (stance == 'stand' && live ? P('BODY_H', .22) + trim * .05 : .08) * tall;
    final k = math.min(1.0, dt * 4);
    final c = math.cos(yaw), s = math.sin(yaw);
    // Forward along the heading; sideways to the right.
    final want = [(c * fwd + s * side) * vmax, (s * fwd - c * side) * vmax];
    vel = [vel[0] + (want[0] - vel[0]) * k, vel[1] + (want[1] - vel[1]) * k, 0];
    yawRate += (turn * P('TURN_RATE', 90) / 57.3 - yawRate) * k;
    yaw += yawRate * dt;
    final moving = hypot2(vel[0], vel[1]) + yawRate.abs() * .2;
    _stride += dt * (trot ? 3.2 : 2.0) * (moving > .02 ? 1 : 0);
    final bob = moving > .02 ? math.sin(_stride * math.pi * 2 * 2) * .006 : 0.0;
    final z = pos[2] + (h - pos[2]) * math.min(1.0, dt * 3);
    pos = [pos[0] + vel[0] * dt, pos[1] + vel[1] * dt, z + bob];
    roll = moving > .02 ? math.sin(_stride * math.pi * 2) * (trot ? .04 : .02) + _rnd(.004) : _rnd(.002);
    pitch = (h - z) * 2 + _rnd(.004);
    current = up ? 2.5 + moving * 6 + _rnd(.3) : .6;
  }

  double _stride = 0;

  void _rocket(double dt, bool live) {
    const g = 9.81;
    var a = <double>[0, 0, -g];
    phaseT += dt;
    final ph = mode;
    final mainAlt = P('MAIN_ALT', 150);
    if (ph == 'COUNT') {
      countdown -= dt;
      if (countdown <= 0) {
        if (live) {
          mode = 'BOOST';
          phaseT = 0;
        } else {
          mode = 'PAD';
        }
        _sendState();
      }
    }
    if (ph == 'PAD' || ph == 'COUNT' || ph == 'LANDED') {
      vel = [0, 0, 0];
      a = [0, 0, 0];
    } else {
      if (ph == 'BOOST') {
        const th = 72.0, tl = .05;
        a = [math.sin(tl) * th * .8, math.sin(tl) * th * .6, math.cos(tl) * th - g];
        if (phaseT > 2.8) {
          mode = 'COAST';
          phaseT = 0;
          _sendState();
        }
      } else if (ph == 'COAST') {
        final v = hypot3(vel[0], vel[1], vel[2]);
        a = [for (var i = 0; i < 3; i++) -vel[i] * v * .0009 + (i == 2 ? -g : 0)];
        if (vel[2] <= 0 && phaseT > P('DROGUE_DELAY', 0)) {
          mode = 'DROGUE';
          pyro[0] = 'FIRED';
          phaseT = 0;
          _sendState();
        }
      } else if (ph == 'DROGUE' || ph == 'MAIN') {
        final tv = [3.0, 1.2, ph == 'DROGUE' ? -18.0 : -5.5];
        a = [for (var i = 0; i < 3; i++) (tv[i] - vel[i]) * 2];
        if (ph == 'DROGUE' && pos[2] < mainAlt) {
          mode = 'MAIN';
          pyro[1] = 'FIRED';
          _sendState();
        }
      }
      vel = [for (var i = 0; i < 3; i++) vel[i] + a[i] * dt];
      pos = [for (var i = 0; i < 3; i++) pos[i] + vel[i] * dt];
      if (pos[2] <= 0 && ph != 'BOOST') {
        pos[2] = 0;
        vel = [0, 0, 0];
        mode = 'LANDED';
        _sendState();
      }
    }
    rocketA = a;
    maxAlt = math.max(maxAlt, pos[2]);
    final fly = ph == 'BOOST' || ph == 'COAST', chute = ph == 'DROGUE' || ph == 'MAIN';
    pitch = fly
        ? .05 + _rnd(.01)
        : chute
        ? math.sin(t * 1.3) * .35
        : 0;
    roll = chute
        ? math.sin(t * 1.9) * .3
        : fly
        ? _rnd(.02)
        : 0;
    yawRate = fly
        ? 2.4 + _rnd(.2)
        : chute
        ? math.sin(t) * .6
        : 0;
    yaw += yawRate * dt;
    current = .3;
  }

  void _bench(double dt, bool live) {
    var thr = live ? throttle : 0.0;
    final mx = P('MAX_THROTTLE', 100) / 100;
    if (seqKind != null && live) {
      seqT += dt;
      final st = seqT;
      if (seqKind == 'RAMP') {
        final rt = P('RAMP_TIME', 10);
        thr = st < rt
            ? st / rt
            : st < rt + 2
            ? 1
            : 0;
        if (st > rt + 2) {
          seqKind = null;
          throttle = 0;
          mode = 'IDLE';
          _sendState();
        }
      } else {
        final ss = P('STEP_SIZE', 25) / 100, hd = P('STEP_HOLD', 3);
        final k = (st / hd).floor() + 1;
        thr = math.min(1, k * ss);
        if (k * ss > 1 + 1e-6) {
          seqKind = null;
          throttle = 0;
          thr = 0;
          mode = 'IDLE';
          _sendState();
        }
      }
    } else if (!live && seqKind != null) {
      seqKind = null;
    }
    thr = math.min(thr, mx);
    thrOut = thr;
    final k = math.min(1.0, dt * 3);
    rpm += (thr * 9000 - rpm) * k;
    thrust = (2.7e-7 * rpm * rpm) * P('CELL_SCALE', 1) + P('CELL_OFFSET', 0) + _rnd(.08);
    torque = thrust * .012 + _rnd(.002);
    current = math.max(.2, thrust * 1.6 + _rnd(.2));
    temp += (24 + current * 1.4 - temp) * dt * .03;
    if (current > P('MAX_CURRENT', 45) || temp > P('MAX_TEMP', 90)) {
      cutoff = current > P('MAX_CURRENT', 45) ? 'Current limit' : 'Temperature limit';
      throttle = 0;
      seqKind = null;
      mode = 'CUTOFF';
      _sendState();
    }
    pitch = _rnd(.003);
    roll = _rnd(.003);
    yawRate = 0;
  }

  void _arm(double dt, bool live) {
    var tgt = List.of(joints);
    // MANUAL: the operator's jog; AUTO: dash's (poses come as commands).
    final manual = mode == 'MANUAL' || mode == 'AUTO';
    if (_homeFrom != null) {
      _homeT += dt;
      final k = math.min(1.0, _homeT / _poseDur), e = 1 - math.pow(1 - k, 3);
      tgt = [for (var i = 0; i < 6; i++) _homeFrom![i] + (_poseTo[i] - _homeFrom![i]) * e];
      if (k >= 1) _homeFrom = null;
    } else if (live && manual) {
      tgt = [for (var i = 0; i < 6; i++) joints[i] + jog[i] * dt * 1.2 * speed * 2];
    }
    const lim = [
      [-3.0, 3.0],
      [-1.6, 1.2],
      [-0.2, 2.6],
      [-3.0, 3.0],
      [-1.8, 1.8],
      [-6.28, 6.28],
    ];
    final prev = List.of(joints);
    final k = math.min(1.0, dt * 4);
    joints = [for (var i = 0; i < 6; i++) (joints[i] + (tgt[i] - joints[i]) * (manual || _homeFrom != null ? 1 : k)).clamp(lim[i][0], lim[i][1])];
    final jv = [for (var i = 0; i < 6; i++) (joints[i] - prev[i]) / dt];
    const base = <double>[0, 0, 0, 1, 4, .5];
    torqueJ = [
      for (var i = 0; i < 6; i++)
        (i == 1
                ? math.sin(joints[1] + math.pi / 2) * 38
                : i == 2
                ? math.cos(joints[2]) * 18
                : base[i]) +
            jv[i] * 3 +
            _rnd(.6),
    ];
    pos = [0, 0, 0];
    ft = [_rnd(.5) + jv[0] * 2, _rnd(.5) + jv[1] * 2, -9.81 * (gripper > .5 ? 1.8 : .6) + _rnd(.4)];
    pitch = _rnd(.002);
    roll = _rnd(.002);
    current = 1.2 + jv[1].abs() * 3 + jv[2].abs() * 2;
  }

  /// Runs the device offline and returns recording frames at 10 Hz.
  static List<Map<String, dynamic>> record(DeviceInfo info, double secs) {
    final d = SimDevice(info)..t = _rng.nextDouble() * 50;
    d.pos = [0, 0, 0];
    if (info.kind == DeviceKind.drone) d.mode = 'TAKEOFF';
    if (info.kind == DeviceKind.rocket) {
      d.mode = 'BOOST';
      d.armed = true;
    }
    final out = <Map<String, dynamic>>[];
    for (var i = 0; i < secs * 30; i++) {
      d.step(1 / 30);
      if (info.kind == DeviceKind.drone && d.mode == 'HOLD') d.mode = 'AUTO';
      if (i % 3 == 0) out.add(d.frame());
    }
    return out;
  }
}

/// The simulator as the host of its own stored-sequence runner.
class _SimSeqHost implements SequenceHost {
  _SimSeqHost(this.d);
  final SimDevice d;
  @override
  List<double> get seqPos => [d.pos[0] - d.homeXY[0], d.pos[1] - d.homeXY[1], d.pos[2]];
  @override
  List<double> get seqJoints => d.joints;
  @override
  String get seqMode => d.mode;
  @override
  bool get seqArmed => d.armed;
  @override
  bool get seqStopped => d.estop;
  @override
  bool get seqLinkLost => false; // it runs on the device
  @override
  void seqSetMode(String m) => d._onMsg({'t': 'mode', 'm': m});
  @override
  void seqSetArmed(bool v) => d._onMsg({'t': 'arm', 'v': v});
  @override
  void seqSetSpeed(double v) => d._onMsg({'t': 'speed', 'v': v});
  @override
  void seqCmd(String c, Map<String, dynamic> a) => d._cmd(c, a);
}
