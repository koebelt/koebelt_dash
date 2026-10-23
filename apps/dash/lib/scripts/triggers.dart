import '../core/model.dart';
import 'conditions.dart';
import 'script_hub.dart' show ScriptLimits;

/// What fires a trigger.
enum TriggerSource {
  button('Button'),
  toggle('Switch'),
  slider('Slider'),
  key('Key'),
  pad('Controller'),
  condition('Condition'),
  event('Device event'),
  timer('Timer');

  const TriggerSource(this.label);
  final String label;
}

/// Device events a trigger can follow.
const deviceEvents = {
  'mode': 'Mode changes',
  'armed': 'Armed',
  'disarmed': 'Disarmed',
  'failsafe': 'Failsafe',
  'linklost': 'Link lost',
  'seqdone': 'Sequence finished',
  'log': 'Device message',
};

/// One way an event reaches a script: an operator input, a condition, a
/// device event or a timer. Several bindings can fire the same event.
class TriggerBinding {
  TriggerBinding(this.event, this.source, {this.key, this.pad, this.expr, this.both = false, this.deviceEvent, this.match, this.seconds = 5, this.repeat = true, this.pinned = false, this.min = 0, this.max = 1});

  /// The name the script receives (`@dev.trigger("Drop payload")`).
  String event;
  TriggerSource source;

  /// Keyboard key label (`D`, `Space`, `F1`), controller source (`n:a`).
  String? key, pad;

  /// Condition expression; [both] also fires `false` when it clears.
  String? expr;
  bool both;

  /// Device event (a [deviceEvents] key) and, for modes and messages, the text to match.
  String? deviceEvent, match;

  /// Timer period or delay; [repeat] false fires once after [seconds].
  double seconds;
  bool repeat;

  /// On-screen controls also show on Control, next to the sticks.
  bool pinned;
  double min, max;

  bool get onScreen => source == TriggerSource.button || source == TriggerSource.toggle || source == TriggerSource.slider;

  Map<String, dynamic> toJson() => {
    'event': event,
    'source': source.name,
    'key': ?key,
    'pad': ?pad,
    'expr': ?expr,
    if (both) 'both': true,
    'deviceEvent': ?deviceEvent,
    'match': ?match,
    if (source == TriggerSource.timer) ...{'seconds': seconds, 'repeat': repeat},
    if (pinned) 'pinned': true,
    if (source == TriggerSource.slider) ...{'min': min, 'max': max},
  };

  factory TriggerBinding.fromJson(Map j) => TriggerBinding(
    '${j['event']}',
    TriggerSource.values.asNameMap()['${j['source']}'] ?? TriggerSource.button,
    key: j['key'] as String?,
    pad: j['pad'] as String?,
    expr: j['expr'] as String?,
    both: j['both'] == true,
    deviceEvent: j['deviceEvent'] as String?,
    match: j['match'] as String?,
    seconds: (j['seconds'] as num?)?.toDouble() ?? 5,
    repeat: j['repeat'] != false,
    pinned: j['pinned'] == true,
    min: (j['min'] as num?)?.toDouble() ?? 0,
    max: (j['max'] as num?)?.toDouble() ?? 1,
  );

  /// One line describing what fires it, for lists.
  String describe(String Function(String src) padLabel) => switch (source) {
    TriggerSource.button => 'Button${pinned ? ', on Control' : ''}',
    TriggerSource.toggle => 'Switch${pinned ? ', on Control' : ''}',
    TriggerSource.slider => 'Slider${pinned ? ', on Control' : ''}',
    TriggerSource.key => 'Key ${key ?? '—'}',
    TriggerSource.pad => 'Controller ${pad == null ? '—' : padLabel(pad!)}',
    TriggerSource.condition => expr ?? '—',
    TriggerSource.event => '${deviceEvents[deviceEvent] ?? 'Device event'}${match == null || match!.isEmpty ? '' : ': $match'}',
    TriggerSource.timer => repeat ? 'Every ${_n(seconds)} s' : 'Once after ${_n(seconds)} s',
  };
}

String _n(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();

/// What dash keeps for a script: the interpreter, the device, the limits,
/// and the trigger bindings. Keyed by the script's path.
class ScriptConfig {
  ScriptConfig();

  /// The interpreter, the device, and the script host (its key) or null for this computer.
  String? python, device, host;
  ScriptLimits limits = ScriptLimits();
  final List<TriggerBinding> bindings = [];

  /// Values of switches and sliders, so keys and controllers can toggle them.
  final Map<String, Object> values = {};

  Map<String, dynamic> toJson() => {
    'python': ?python,
    'device': ?device,
    'host': ?host,
    'limits': limits.toJson(),
    'bindings': [for (final b in bindings) b.toJson()],
  };

  factory ScriptConfig.fromJson(Map j) {
    final c = ScriptConfig()
      ..python = j['python'] as String?
      ..device = j['device'] as String?
      ..host = j['host'] as String?;
    final l = j['limits'];
    if (l is Map) {
      c.limits = ScriptLimits(
        maxSpeed: (l['maxSpeed'] as num?)?.toDouble() ?? .6,
        fence: (l['fence'] as num?)?.toDouble() ?? 50,
        ceiling: (l['ceiling'] as num?)?.toDouble() ?? 30,
        allowArm: l['allowArm'] == true,
        allowParams: l['allowParams'] == true,
      );
    }
    for (final b in (j['bindings'] as List?) ?? const []) {
      if (b is Map) c.bindings.add(TriggerBinding.fromJson(b));
    }
    return c;
  }

  /// When a script declares a trigger: an on-screen control for it, and the
  /// key and controller button it suggests, unless the operator already set
  /// it up (their bindings win).
  bool adopt(Map<String, dynamic> decl) {
    final name = '${decl['name']}';
    if (bindings.any((b) => b.event == name)) return false;
    final kind = '${decl['kind'] ?? 'button'}';
    bindings.add(
      TriggerBinding(
        name,
        kind == 'switch'
            ? TriggerSource.toggle
            : kind == 'value'
            ? TriggerSource.slider
            : TriggerSource.button,
        min: (decl['min'] as num?)?.toDouble() ?? 0,
        max: (decl['max'] as num?)?.toDouble() ?? 1,
      ),
    );
    final key = decl['key'];
    if (key is String && key.isNotEmpty) bindings.add(TriggerBinding(name, TriggerSource.key, key: key.toUpperCase()));
    final pad = decl['gamepad'];
    if (pad is String && pad.isNotEmpty) bindings.add(TriggerBinding(name, TriggerSource.pad, pad: padSourceFor(pad)));
    return true;
  }
}

/// A script's suggested controller button (`Y`, `LB`, `start`) as the
/// controller mapping names normalised buttons.
String padSourceFor(String s) {
  const names = {
    'a': 'a',
    'b': 'b',
    'x': 'x',
    'y': 'y',
    'lb': 'leftBumper',
    'rb': 'rightBumper',
    'lt': 'leftTrigger',
    'rt': 'rightTrigger',
    'start': 'start',
    'back': 'back',
    'select': 'back',
    'up': 'dpadUp',
    'down': 'dpadDown',
    'left': 'dpadLeft',
    'right': 'dpadRight',
    'ls': 'leftStick',
    'rs': 'rightStick',
  };
  return s.contains(':') ? s : 'n:${names[s.toLowerCase()] ?? s}';
}

/// The live state of a script's automatic triggers (conditions, device
/// events, timers), stepped by the hub.
class TriggerState {
  final Map<TriggerBinding, ConditionWatch> watches = {};
  final Map<TriggerBinding, double> timers = {};
  String? lastMode;
  bool? lastArmed, lastFailsafe, lastLost;
  Object? lastRun;
  int logsSeen = 0;

  /// The condition watch for a binding, rebuilt when its expression changes;
  /// null if the expression does not parse.
  ConditionWatch? watch(TriggerBinding b) {
    final w = watches[b];
    if (w != null && w.condition.source == b.expr) return w;
    try {
      return watches[b] = ConditionWatch(Condition.parse(b.expr ?? ''));
    } on ConditionError {
      watches.remove(b);
      return null;
    }
  }
}

/// The control a trigger shows on screen for a declared kind.
TriggerSource sourceForKind(String kind) => kind == 'switch'
    ? TriggerSource.toggle
    : kind == 'value'
    ? TriggerSource.slider
    : TriggerSource.button;

/// For tests and lists: whether a device kind has sticks a script can drive.
bool drivable(DeviceKind k) => k == DeviceKind.drone || k == DeviceKind.rover;
