import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:gamepads/gamepads.dart';

/// Game controllers over USB or Bluetooth: Xbox, PlayStation, Switch Pro and
/// generic HID gamepads, and RC transmitters in USB joystick mode. The OS
/// pairs Bluetooth controllers, so both arrive through the same plugin.
///
/// Inputs are named by source: `n:leftStickX` for the plugin's normalised
/// layout (known controllers), `r:<key>` for a raw platform key (anything
/// else, bound by "learning").

/// Things a button can do.
enum PadAction {
  stop('STOP', 'Emergency stop, immediately'),
  arm('Arm / disarm', 'Hold for one second'),
  manual('Manual', 'Switch to MANUAL'),
  hold('Hold', 'Switch to HOLD'),
  auto('Auto', 'Switch to AUTO'),
  rth('Return home', 'Switch to RTH (drones)'),
  takeoff('Take off', 'Hold for one second (drones)'),
  land('Land', 'Switch to LAND (drones)'),
  record('Record', 'Start or stop a recording'),
  slower('Speed down', 'Lower the speed limit 10 %'),
  faster('Speed up', 'Raise the speed limit 10 %'),
  armFrame('Joint / Cartesian', 'Arms: what the sticks move'),
  armWrist('Wrist', 'Arms: right stick moves J5 and J6 instead of J3 and J4'),
  gripper('Gripper', 'Arms: open or close');

  const PadAction(this.label, this.hint);
  final String label, hint;

  /// Actions that need a one-second hold so a bump cannot trigger them.
  bool get needsHold => this == arm || this == takeoff;
}

/// The four control axes (the protocol's lx, ly, rx, ry).
const padAxisNames = ['lx', 'ly', 'rx', 'ry'];

class AxisBinding {
  AxisBinding(this.src, {this.invert = false});
  String? src;
  bool invert;
  Map<String, dynamic> toJson() => {'src': src, 'inv': invert};
  factory AxisBinding.fromJson(Map j) => AxisBinding(j['src'] as String?, invert: j['inv'] == true);
}

/// Saved controller mapping. Defaults follow "mode 2": left stick throttle
/// and yaw, right stick pitch and roll; rovers steer left, drive right.
class PadConfig {
  bool enabled = true;
  double deadzone = .08;

  /// 0 = linear, 1 = fully cubic near the centre.
  double expo = .25;
  List<AxisBinding> axes = defaultAxes();
  Map<PadAction, String?> buttons = Map.of(defaultButtons);

  static List<AxisBinding> defaultAxes() => [
    AxisBinding('n:leftStickX'),
    AxisBinding('n:leftStickY'),
    AxisBinding('n:rightStickX'),
    AxisBinding('n:rightStickY'),
  ];

  static const defaultButtons = {
    PadAction.stop: 'n:b',
    PadAction.arm: 'n:start',
    PadAction.manual: 'n:a',
    PadAction.hold: 'n:x',
    PadAction.auto: null,
    PadAction.rth: 'n:y',
    PadAction.takeoff: 'n:dpadUp',
    PadAction.land: 'n:dpadDown',
    PadAction.record: 'n:back',
    PadAction.slower: 'n:leftBumper',
    PadAction.faster: 'n:rightBumper',
    PadAction.armFrame: 'n:dpadLeft',
    PadAction.armWrist: 'n:dpadRight',
    PadAction.gripper: 'n:rightStick',
  };

  void reset() {
    deadzone = .08;
    expo = .25;
    axes = defaultAxes();
    buttons = Map.of(defaultButtons);
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'deadzone': deadzone,
    'expo': expo,
    'axes': [for (final a in axes) a.toJson()],
    'buttons': {for (final e in buttons.entries) e.key.name: e.value},
  };

  void load(Map? j) {
    if (j == null) return;
    enabled = j['enabled'] ?? enabled;
    deadzone = (j['deadzone'] as num?)?.toDouble() ?? deadzone;
    expo = (j['expo'] as num?)?.toDouble() ?? expo;
    final a = j['axes'];
    if (a is List && a.length == 4) axes = [for (final x in a) AxisBinding.fromJson(x as Map)];
    final b = j['buttons'];
    if (b is Map) {
      for (final act in PadAction.values) {
        if (b.containsKey(act.name)) buttons[act] = b[act.name] as String?;
      }
    }
  }
}

/// What the mapper wants done; implemented by [Dash].
abstract class PadTarget {
  /// Writes the four control axes. Called only while the controller moves.
  void padAxes(List<double> v);
  void padAction(PadAction a);
}

/// Pure mapping logic: source values in, axes and actions out. No plugin
/// code here, so it is unit-tested with synthetic events.
class PadMapper {
  PadMapper(this.cfg, this.target);
  final PadConfig cfg;
  final PadTarget target;

  /// Latest value per source, after range calibration.
  final Map<String, double> values = {};

  /// Raw ranges seen per raw source, for axes that do not report −1…1
  /// (RC transmitters on Windows report 0…65535).
  final Map<String, (double, double)> _range = {};
  final Map<String, double> _pressedAt = {};
  final Set<PadAction> _fired = {};
  bool _wasActive = false;

  /// True while the controller's sticks are off centre.
  bool get driving => _wasActive;

  /// While set, the next deliberate input is bound to this slot instead of
  /// acting: `axis:0`…`axis:3` or `btn:<action>`.
  String? learning;
  Map<String, double> _learnRest = {};
  VoidCallback? onLearned;

  double get _now => DateTime.now().millisecondsSinceEpoch / 1000;

  double _calibrate(String src, double v) {
    if (src.startsWith('n:')) return v;
    final r = _range[src];
    final lo = math.min(r?.$1 ?? -1, v), hi = math.max(r?.$2 ?? 1, v);
    _range[src] = (lo, hi);
    if (lo >= -1.001 && hi <= 1.001) return v;
    final mid = (lo + hi) / 2, half = (hi - lo) / 2;
    return half <= 0 ? 0 : ((v - mid) / half).clamp(-1.0, 1.0);
  }

  void startLearning(String slot) {
    learning = slot;
    _learnRest = Map.of(values);
  }

  void cancelLearning() {
    learning = null;
    _settle?.cancel();
    _settle = null;
    _candidate = null;
  }

  /// Feeds one input change. [button] distinguishes digital inputs, which
  /// can only be bound to actions.
  void input(String src, double raw, {bool button = false}) {
    final v = _calibrate(src, raw);
    values[src] = v;
    final slot = learning;
    if (slot != null) {
      _learn(slot, src, v, button);
      return;
    }
    if (!cfg.enabled) return;
    for (final e in cfg.buttons.entries) {
      if (e.value == src) _button(e.key, v > .5);
    }
    if (cfg.axes.any((a) => a.src == src)) _pushAxes();
  }

  (String, bool)? _candidate;
  Timer? _settle;

  void _learn(String slot, String src, double v, bool button) {
    // Normalised sticks rest at 0; for an unseen raw axis the first value is its rest.
    final rest = _learnRest[src] ?? (button || src.startsWith('n:') ? 0 : v);
    final moved = button ? v > .5 : (v - rest).abs() > .5;
    if (!moved) {
      _learnRest.putIfAbsent(src, () => v);
      return;
    }
    if (slot.startsWith('axis:') && button) return;
    // Known controllers report each input twice, raw and normalised. Wait a
    // moment and prefer the normalised name: it is the same on every OS.
    final c = _candidate;
    if (c == null || (!c.$1.startsWith('n:') && src.startsWith('n:'))) _candidate = (src, v < rest);
    _settle ??= Timer(const Duration(milliseconds: 40), () => _bind(slot));
  }

  void _bind(String slot) {
    _settle = null;
    final c = _candidate;
    _candidate = null;
    if (c == null || learning != slot) return;
    final src = c.$1;
    if (slot.startsWith('axis:')) {
      final i = int.parse(slot.substring(5));
      // Learn the direction too: pushing up / right should read positive.
      cfg.axes[i] = AxisBinding(src, invert: c.$2);
    } else {
      final act = PadAction.values.byName(slot.substring(4));
      // One source per action; unbind it elsewhere so a press does one thing.
      for (final k in cfg.buttons.keys.toList()) {
        if (cfg.buttons[k] == src) cfg.buttons[k] = null;
      }
      cfg.buttons[act] = src;
    }
    learning = null;
    onLearned?.call();
  }

  double shape(double v) {
    final dz = cfg.deadzone, a = v.abs();
    if (a <= dz) return 0;
    final x = (a - dz) / (1 - dz);
    final y = (1 - cfg.expo) * x + cfg.expo * x * x * x;
    return v.sign * y.clamp(0.0, 1.0);
  }

  List<double> get axes => [for (final b in cfg.axes) b.src == null ? 0.0 : shape(values[b.src] ?? 0) * (b.invert ? -1 : 1)];

  void _pushAxes() {
    final a = axes;
    final active = a.any((x) => x != 0);
    // Only write while the controller is in use, plus one zero when it is
    // let go, so on-screen sticks still work with a controller plugged in.
    if (active || _wasActive) target.padAxes(a);
    _wasActive = active;
  }

  void _button(PadAction a, bool down) {
    if (!down) {
      _pressedAt.remove(a.name);
      _fired.remove(a);
      return;
    }
    if (_pressedAt.containsKey(a.name)) return;
    _pressedAt[a.name] = _now;
    if (!a.needsHold) {
      target.padAction(a);
      _fired.add(a);
    }
  }

  /// Called periodically: fires hold-to-act buttons after one second.
  void tick() {
    final now = _now;
    for (final a in PadAction.values) {
      if (!a.needsHold || _fired.contains(a)) continue;
      final t = _pressedAt[a.name];
      if (t != null && now - t >= 1) {
        _fired.add(a);
        target.padAction(a);
      }
    }
  }

  /// Progress 0…1 of a held hold-to-act button, for the UI.
  double holdProgress(PadAction a) {
    final t = _pressedAt[a.name];
    if (t == null || _fired.contains(a)) return 0;
    return ((_now - t) / 1).clamp(0.0, 1.0);
  }

  /// Controller gone: release everything.
  void releaseAll() {
    for (final k in values.keys.toList()) {
      values[k] = 0;
    }
    _pressedAt.clear();
    _fired.clear();
    if (_wasActive) target.padAxes(const [0, 0, 0, 0]);
    _wasActive = false;
  }
}

/// Connects the gamepads plugin to a [PadMapper].
class GamepadInput extends ChangeNotifier {
  GamepadInput(this.mapper);
  final PadMapper mapper;

  /// Connected controllers by id → name.
  final Map<String, String> pads = {};

  /// Name of the controller that moved last.
  String? active;
  bool available = true;

  final List<StreamSubscription> _subs = [];
  Timer? _tick;

  /// Raw inputs seen recently, for the mapping screen (`r:key` → value).
  Map<String, double> get values => mapper.values;

  Future<void> start() async {
    try {
      for (final p in await Gamepads.list()) {
        pads[p.id] = p.name;
      }
      _subs.add(
        Gamepads.connectionEvents.listen((e) {
          if (e.type == GamepadConnectionEventType.connected) {
            pads[e.gamepadId] = e.name;
          } else {
            pads.remove(e.gamepadId);
            if (pads.isEmpty) {
              active = null;
              mapper.releaseAll();
            }
          }
          notifyListeners();
        }),
      );
      _subs.add(
        Gamepads.events.listen((e) {
          _seen(e.gamepadId);
          mapper.input('r:${e.key}', e.value, button: e.type == KeyType.button);
        }),
      );
      _subs.add(
        Gamepads.normalizedEvents.listen((e) {
          _seen(e.gamepadId);
          final k = e.axis?.name ?? e.button!.name;
          mapper.input('n:$k', e.value, button: e.button != null);
        }),
      );
      _tick = Timer.periodic(const Duration(milliseconds: 50), (_) => mapper.tick());
    } catch (e) {
      // No plugin on this platform (tests, unsupported OS).
      available = false;
      debugPrint('gamepads unavailable: $e');
    }
    notifyListeners();
  }

  void _seen(String id) {
    final n = pads[id] ?? id;
    pads.putIfAbsent(id, () => n);
    if (active != n) {
      active = n;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }
}

/// Short human name for a source: `n:leftStickX` → "Left stick X".
String padSourceLabel(String? src) {
  if (src == null) return 'Not set';
  if (src.startsWith('r:')) return src.substring(2);
  final k = src.substring(2);
  const names = {
    'leftStickX': 'Left stick X',
    'leftStickY': 'Left stick Y',
    'rightStickX': 'Right stick X',
    'rightStickY': 'Right stick Y',
    'leftTrigger': 'Left trigger',
    'rightTrigger': 'Right trigger',
    'a': 'A / Cross',
    'b': 'B / Circle',
    'x': 'X / Square',
    'y': 'Y / Triangle',
    'leftBumper': 'Left bumper',
    'rightBumper': 'Right bumper',
    'back': 'Back / Share',
    'start': 'Start / Options',
    'home': 'Home',
    'leftStick': 'Left stick press',
    'rightStick': 'Right stick press',
    'dpadUp': 'D-pad up',
    'dpadDown': 'D-pad down',
    'dpadLeft': 'D-pad left',
    'dpadRight': 'D-pad right',
    'touchpad': 'Touchpad',
  };
  return names[k] ?? k;
}
