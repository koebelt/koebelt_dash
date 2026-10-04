// Programmable sequences: an ordered list of steps the app executes on the
// connected device, checking each step's completion against telemetry.
import 'dart:math' as math;

import 'model.dart';

/// A numeric or choice input of a step.
class StepField {
  const StepField(this.key, this.label, this.def, {this.min = 0, this.max = 100, this.step = 1, this.unit = '', this.choices});
  final String key, label, unit;
  final double def, min, max, step;

  /// When set, the field is a choice (stored as a string) instead of a number.
  final List<String>? choices;
  bool get isChoice => choices != null;
}

class StepDef {
  const StepDef(this.type, this.label, this.kinds, this.fields, {this.capture});
  final String type, label;
  final Set<DeviceKind> kinds;
  final List<StepField> fields;

  /// "Use current position/pose" support: 'pos' or 'joints'.
  final String? capture;
}

const _all = {DeviceKind.drone, DeviceKind.rover, DeviceKind.arm, DeviceKind.rocket, DeviceKind.bench, DeviceKind.generic};

List<String> modesFor(DeviceKind k) => switch (k) {
  DeviceKind.drone => const ['AUTO', 'MANUAL', 'HOLD'],
  DeviceKind.rover || DeviceKind.arm || DeviceKind.generic => const ['AUTO', 'MANUAL', 'HOLD'],
  DeviceKind.rocket => const ['PAD'],
  DeviceKind.bench => const ['IDLE'],
};

List<StepDef> stepDefs(DeviceKind kind) => [
  if (kind == DeviceKind.drone) ...[
    const StepDef('takeoff', 'Take off', {DeviceKind.drone}, [StepField('alt', 'Altitude', 6, min: 1, max: 120, step: .5, unit: 'm')]),
    const StepDef(
      'goto',
      'Fly to',
      {DeviceKind.drone},
      [
        StepField('x', 'East', 0, min: -500, max: 500, step: .5, unit: 'm'),
        StepField('y', 'North', 0, min: -500, max: 500, step: .5, unit: 'm'),
        StepField('z', 'Altitude', 8, min: 1, max: 120, step: .5, unit: 'm'),
      ],
      capture: 'pos',
    ),
    const StepDef('land', 'Land', {DeviceKind.drone}, []),
    const StepDef('rth', 'Return home', {DeviceKind.drone}, []),
  ],
  if (kind == DeviceKind.rover)
    const StepDef(
      'goto',
      'Drive to',
      {DeviceKind.rover},
      [StepField('x', 'East', 0, min: -500, max: 500, step: .5, unit: 'm'), StepField('y', 'North', 0, min: -500, max: 500, step: .5, unit: 'm')],
      capture: 'pos',
    ),
  if (kind == DeviceKind.arm) ...[
    StepDef(
      'pose',
      'Move to pose',
      const {DeviceKind.arm},
      [
        for (var i = 1; i <= 6; i++) StepField('j$i', 'J$i', const [0.0, -28.6, 63.0, 0.0, 34.4, 0.0][i - 1], min: -360, max: 360, step: 1, unit: '°'),
      ],
      capture: 'joints',
    ),
    const StepDef('gripper', 'Gripper', {DeviceKind.arm}, [StepField('open', 'Open', 90, min: 0, max: 100, step: 5, unit: '%')]),
    const StepDef('home', 'Home pose', {DeviceKind.arm}, []),
  ],
  if (kind == DeviceKind.bench) ...[
    const StepDef(
      'throttle',
      'Throttle',
      {DeviceKind.bench},
      [StepField('pct', 'Throttle', 50, min: 0, max: 100, step: 1, unit: '%'), StepField('s', 'Hold', 3, min: 0, max: 600, step: .5, unit: 's')],
    ),
    const StepDef(
      'ramp',
      'Ramp',
      {DeviceKind.bench},
      [
        StepField('from', 'From', 0, min: 0, max: 100, step: 1, unit: '%'),
        StepField('to', 'To', 100, min: 0, max: 100, step: 1, unit: '%'),
        StepField('s', 'Over', 10, min: .5, max: 600, step: .5, unit: 's'),
      ],
    ),
  ],
  const StepDef('wait', 'Wait', _all, [StepField('s', 'Duration', 2, min: 0, max: 3600, step: .5, unit: 's')]),
  if (kind != DeviceKind.rocket && kind != DeviceKind.bench) StepDef('mode', 'Set mode', _all, [StepField('m', 'Mode', 0, choices: modesFor(kind))]),
  const StepDef('arm', 'Arm / disarm', _all, [
    StepField('v', 'State', 0, choices: ['ARM', 'DISARM']),
  ]),
  if (kind != DeviceKind.rocket && kind != DeviceKind.bench)
    const StepDef('speed', 'Speed limit', _all, [StepField('pct', 'Limit', 50, min: 10, max: 100, step: 5, unit: '%')]),
  const StepDef('cmd', 'Custom command', _all, [StepField('name', 'Command', 0, choices: []), StepField('v', 'Value', 0, min: -10000, max: 10000, step: .1)]),
];

StepDef? stepDef(DeviceKind kind, String type) => stepDefs(kind).where((d) => d.type == type).firstOrNull;

class SeqStep {
  SeqStep(this.type, this.p);
  final String type;
  final Map<String, dynamic> p;

  factory SeqStep.fresh(StepDef d) => SeqStep(d.type, {for (final f in d.fields) f.key: f.isChoice ? (f.choices!.isEmpty ? '' : f.choices!.first) : f.def});

  double n(String k, [double d = 0]) => (p[k] as num?)?.toDouble() ?? d;
  String s(String k) => '${p[k] ?? ''}';

  SeqStep copy() => SeqStep(type, {...p});
  Map<String, dynamic> toJson() => {'type': type, 'p': p};
  factory SeqStep.fromJson(Map j) => SeqStep(j['type'], Map<String, dynamic>.from(j['p'] ?? const {}));

  /// One-line summary used in lists and the run status.
  String summary(DeviceKind kind) {
    String f(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
    return switch (type) {
      'takeoff' => 'Take off to ${f(n('alt'))} m',
      'goto' => kind == DeviceKind.drone ? 'Fly to ${f(n('x'))}, ${f(n('y'))} m at ${f(n('z'))} m' : 'Drive to ${f(n('x'))}, ${f(n('y'))} m',
      'land' => 'Land',
      'rth' => 'Return home and land',
      'pose' => 'Move to pose ${[for (var i = 1; i <= 6; i++) f(n('j$i'))].join(' / ')}°',
      'gripper' => 'Gripper ${f(n('open'))}% open',
      'home' => 'Home pose',
      'throttle' => 'Throttle ${f(n('pct'))}% for ${f(n('s'))} s',
      'ramp' => 'Ramp ${f(n('from'))} to ${f(n('to'))}% over ${f(n('s'))} s',
      'wait' => 'Wait ${f(n('s'))} s',
      'mode' => 'Mode ${s('m')}',
      'arm' => s('v') == 'ARM' ? 'Arm' : 'Disarm',
      'speed' => 'Speed limit ${f(n('pct'))}%',
      'cmd' => 'Command ${s('name').isEmpty ? '—' : s('name')} = ${f(n('v'))}',
      _ => type,
    };
  }

  /// Nominal duration for time-based steps (preview); null when it depends on the device.
  double? get duration => switch (type) {
    'wait' || 'throttle' || 'ramp' => n('s'),
    'gripper' => .8,
    _ => null,
  };
}

class Sequence {
  Sequence({required this.id, required this.name, required this.kind, required this.steps});
  final String id;
  String name;
  final DeviceKind kind;
  final List<SeqStep> steps;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'kind': kind.name,
    'steps': [for (final s in steps) s.toJson()],
  };
  factory Sequence.fromJson(Map j) => Sequence(
    id: j['id'],
    name: j['name'],
    kind: DeviceKind.parse(j['kind']),
    steps: [for (final s in (j['steps'] as List? ?? const [])) SeqStep.fromJson(s)],
  );

  Sequence copyAs(String id, String name) => Sequence(id: id, name: name, kind: kind, steps: [for (final s in steps) s.copy()]);
}

/// Example programs for the simulated devices.
List<Sequence> exampleSequences(String deviceId, DeviceKind kind) {
  Sequence q(String name, List<SeqStep> steps) => Sequence(id: 'ex-$deviceId-${name.hashCode.abs()}', name: name, kind: kind, steps: steps);
  return switch (kind) {
    DeviceKind.drone => [
      q('Survey square', [
        SeqStep('takeoff', {'alt': 10.0}),
        SeqStep('goto', {'x': 15.0, 'y': 0.0, 'z': 10.0}),
        SeqStep('goto', {'x': 15.0, 'y': 15.0, 'z': 10.0}),
        SeqStep('wait', {'s': 2.0}),
        SeqStep('goto', {'x': 0.0, 'y': 15.0, 'z': 12.0}),
        SeqStep('goto', {'x': 0.0, 'y': 0.0, 'z': 10.0}),
        SeqStep('land', {}),
      ]),
    ],
    DeviceKind.rover => [
      q('Patrol loop', [
        SeqStep('speed', {'pct': 60.0}),
        SeqStep('goto', {'x': 10.0, 'y': 0.0}),
        SeqStep('goto', {'x': 10.0, 'y': 8.0}),
        SeqStep('wait', {'s': 3.0}),
        SeqStep('goto', {'x': 0.0, 'y': 8.0}),
        SeqStep('goto', {'x': 0.0, 'y': 0.0}),
      ]),
    ],
    DeviceKind.arm => [
      q('Pick and place', [
        SeqStep('home', {}),
        SeqStep('gripper', {'open': 90.0}),
        SeqStep('pose', {'j1': 40.0, 'j2': -10.0, 'j3': 80.0, 'j4': 0.0, 'j5': 60.0, 'j6': 0.0}),
        SeqStep('gripper', {'open': 10.0}),
        SeqStep('pose', {'j1': -40.0, 'j2': -20.0, 'j3': 70.0, 'j4': 0.0, 'j5': 50.0, 'j6': 90.0}),
        SeqStep('gripper', {'open': 90.0}),
        SeqStep('home', {}),
      ]),
    ],
    DeviceKind.bench => [
      q('Step and ramp test', [
        SeqStep('arm', {'v': 'ARM'}),
        SeqStep('throttle', {'pct': 20.0, 's': 3.0}),
        SeqStep('throttle', {'pct': 40.0, 's': 3.0}),
        SeqStep('ramp', {'from': 40.0, 'to': 80.0, 's': 8.0}),
        SeqStep('throttle', {'pct': 0.0, 's': 2.0}),
        SeqStep('arm', {'v': 'DISARM'}),
      ]),
    ],
    _ => const [],
  };
}

enum RunState { running, paused, done, failed }

/// What the runner needs from the app. Implemented by [Dash].
abstract class SequenceHost {
  // telemetry
  List<double> get seqPos;
  List<double> get seqJoints;
  String get seqMode;
  bool get seqArmed;
  bool get seqStopped;
  bool get seqLinkLost;
  // commands
  void seqSetMode(String m);
  void seqSetArmed(bool v);
  void seqSetSpeed(double v);
  void seqCmd(String c, Map<String, dynamic> a);
}

/// Executes a [Sequence] step by step.
class SequenceRunner {
  SequenceRunner(this.seq, this.host);
  final Sequence seq;
  final SequenceHost host;

  RunState state = RunState.running;
  int index = 0;
  double stepT = 0, totalT = 0;
  String message = '';
  bool _entered = false;
  double _lastThr = -1, _sendAcc = 0, _still = 0;
  List<double> _lastJoints = const [];

  SeqStep? get step => index < seq.steps.length ? seq.steps[index] : null;

  /// 0…1 for time-based steps, or null.
  double? get stepProgress {
    final s = step, d = s?.duration;
    if (s == null || d == null || d <= 0) return null;
    return (stepT / d).clamp(0, 1);
  }

  void pause([String why = 'Paused']) {
    if (state != RunState.running) return;
    state = RunState.paused;
    message = why;
    if (step?.type == 'ramp' || step?.type == 'throttle') host.seqCmd('throttle', {'v': 0});
  }

  void resume() {
    if (state != RunState.paused) return;
    state = RunState.running;
    message = '';
    _entered = false; // re-issue the current step's command
    stepT = 0;
  }

  void stop(String why) {
    if (state == RunState.done || state == RunState.failed) return;
    state = RunState.failed;
    message = why;
    if (seq.kind == DeviceKind.bench) host.seqCmd('throttle', {'v': 0});
    if (seq.kind == DeviceKind.drone || seq.kind == DeviceKind.rover) {
      if (host.seqArmed && !host.seqStopped) host.seqSetMode('HOLD');
    }
  }

  void tick(double dt) {
    if (state != RunState.running) return;
    if (host.seqStopped) return stop('Stopped: emergency stop');
    if (host.seqLinkLost) return pause('Paused: link lost');
    final s = step;
    if (s == null) {
      state = RunState.done;
      message = 'Completed in ${totalT.toStringAsFixed(1)} s';
      return;
    }
    totalT += dt;
    if (!_entered) {
      _entered = true;
      stepT = 0;
      _lastThr = -1;
      _enter(s);
    }
    stepT += dt;
    final r = _check(s, dt);
    if (r == true) {
      index++;
      _entered = false;
    } else if (r == null) {
      stop('Step ${index + 1} timed out: ${s.summary(seq.kind)}');
    }
  }

  void _enter(SeqStep s) {
    switch (s.type) {
      case 'takeoff':
        host.seqCmd('takeoff', {'alt': s.n('alt', 6)});
      case 'goto':
        host.seqCmd('goto', {'x': s.n('x'), 'y': s.n('y'), if (seq.kind == DeviceKind.drone) 'z': s.n('z', 8)});
      case 'land':
        host.seqSetMode('LAND');
      case 'rth':
        host.seqSetMode('RTH');
      case 'pose':
        host.seqCmd('pose', {
          'j': [for (var i = 1; i <= 6; i++) s.n('j$i') / 57.2958],
        });
      case 'home':
        host.seqCmd('home', {});
      case 'gripper':
        host.seqCmd('gripper', {'v': s.n('open', 90) / 100});
      case 'throttle':
        host.seqCmd('throttle', {'v': s.n('pct') / 100});
      case 'mode':
        host.seqSetMode(s.s('m'));
      case 'arm':
        host.seqSetArmed(s.s('v') == 'ARM');
      case 'speed':
        host.seqSetSpeed(s.n('pct', 50) / 100);
      case 'cmd':
        if (s.s('name').isNotEmpty) host.seqCmd(s.s('name'), {'v': s.n('v')});
    }
  }

  /// true = done, false = keep going, null = timed out.
  bool? _check(SeqStep s, double dt) {
    bool? within(double limit, bool ok) => ok ? true : (stepT > limit ? null : false);
    final p = host.seqPos;
    switch (s.type) {
      case 'wait':
        return stepT >= s.n('s');
      case 'takeoff':
        return within(60, stepT > .3 && host.seqMode != 'TAKEOFF' && p[2] > s.n('alt', 6) - .6);
      case 'goto':
        final dx = p[0] - s.n('x'), dy = p[1] - s.n('y');
        final dist = seq.kind == DeviceKind.drone ? math.sqrt(dx * dx + dy * dy + math.pow(p[2] - s.n('z', 8), 2)) : math.sqrt(dx * dx + dy * dy);
        message = '${dist.toStringAsFixed(1)} m to go';
        return within(300, dist < (seq.kind == DeviceKind.drone ? 1.0 : .6));
      case 'land' || 'rth':
        return within(300, stepT > .5 && (!host.seqArmed || (p[2] < .1 && host.seqMode != 'LAND' && host.seqMode != 'RTH')));
      case 'pose':
        final target = [for (var i = 1; i <= 6; i++) s.n('j$i') / 57.2958];
        final j = host.seqJoints;
        var err = 0.0;
        for (var i = 0; i < 6 && i < j.length; i++) {
          err = math.max(err, (j[i] - target[i]).abs());
        }
        return within(60, stepT > .2 && err < .03);
      case 'home':
        // The home pose lives on the device (settable), so wait for the arm to settle.
        final j = host.seqJoints;
        var moved = 0.0;
        for (var i = 0; i < 6 && i < j.length && i < _lastJoints.length; i++) {
          moved = math.max(moved, (j[i] - _lastJoints[i]).abs());
        }
        _lastJoints = List.of(j);
        _still = moved < 2e-4 ? _still + dt : 0;
        return within(60, stepT > .6 && _still > .4);
      case 'gripper':
        return stepT >= .8;
      case 'throttle':
        return stepT >= s.n('s');
      case 'ramp':
        final d = math.max(.001, s.n('s')), k = (stepT / d).clamp(0.0, 1.0);
        final thr = (s.n('from') + (s.n('to') - s.n('from')) * k) / 100;
        _sendAcc += dt;
        if (_sendAcc >= .1 && (thr - _lastThr).abs() >= .005) {
          _sendAcc = 0;
          _lastThr = thr;
          host.seqCmd('throttle', {'v': thr});
        }
        return stepT >= d;
      case 'mode':
        return within(3, host.seqMode == s.s('m'));
      case 'arm':
        return within(3, host.seqArmed == (s.s('v') == 'ARM'));
      default:
        return true;
    }
  }
}
