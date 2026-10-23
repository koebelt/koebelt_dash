/// Completion and signature help for the in-app Python editor: the
/// koebelt_dash_scripts API, the script's own names, Python's keywords, and
/// what dash knows about the device the script runs on.
library;

enum CompletionKind { method, field, function, variable, keyword, value, module }

class Completion {
  const Completion(this.label, {this.detail = '', this.kind = CompletionKind.field, String? insert, this.cursorBack = 0})
    : insert = insert ?? label;

  /// What the list shows, what goes into the code, and how far back the
  /// cursor goes after it (inside the parentheses, inside quotes).
  final String label, detail, insert;
  final CompletionKind kind;
  final int cursorBack;
}

/// A callable's signature: parameters with what each does.
class Signature {
  const Signature(this.name, this.params, this.doc);
  final String name, doc;
  final List<(String, String)> params;

  String get text => '$name(${params.map((p) => p.$1).join(', ')})';
}

/// What dash knows about the device the script runs on.
class CompletionContext {
  const CompletionContext({this.kind, this.sticks = const [], this.tlm = const [], this.programs = const [], this.steps = const [], this.channels = const []});
  final String? kind;
  final List<String> sticks, tlm, programs, steps, channels;
}

Signature _sig(String name, String params, String doc) => Signature(name, [
  for (final p in params.split(';').where((p) => p.trim().isNotEmpty))
    (p.split('—').first.trim(), p.contains('—') ? p.split('—').last.trim() : ''),
], doc);

/// The device's API (koebelt_dash_scripts.client.Device).
final deviceApi = <String, Signature?>{
  'tlm': null,
  'next_tlm': _sig('next_tlm', 'timeout=1.0 — seconds to wait', 'Waits for the next telemetry and returns it.'),
  'sticks': _sig('sticks', '**axes — throttle, yaw, pitch, roll (drone) or throttle, steer (rover), −1…1', 'Sets the sticks until changed; scaled to the script\'s speed limit; the operator\'s sticks win.'),
  'release': _sig('release', '', 'Hands the sticks back; the device holds.'),
  'mode': _sig('mode', 'mode — "HOLD", "MANUAL", "AUTO", "RTH"…', 'Switches the device\'s mode.'),
  'arm': _sig('arm', '', 'Arms (needs Allow arming in the script\'s Limits).'),
  'disarm': _sig('disarm', '', 'Disarms.'),
  'speed_limit': _sig('speed_limit', 'v — 0.1–1, capped by the script\'s limit', 'The device\'s speed limit.'),
  'cmd': _sig('cmd', 'name — the command; **args — its arguments', 'A command of this kind of device: release, sethome, countdown…'),
  'stop': _sig('stop', '', 'STOP: every device, at once.'),
  'takeoff': _sig('takeoff', 'alt=6 — metres; wait=True — return once there', 'Drones: arms and climbs (needs Allow arming).'),
  'goto': _sig('goto', 'x — metres east of home; y — metres north; z=None — metres up (drones); wait=True', 'Goes there; returns once there.'),
  'land': _sig('land', 'wait=True', 'Lands.'),
  'rth': _sig('rth', 'wait=True', 'Drones: returns home and lands.'),
  'pose': _sig('pose', '*joints — degrees, J1, J2…; wait=True', 'Arms: moves to joint angles.'),
  'gripper': _sig('gripper', 'open_pct — 0 closed … 100 open; wait=True', 'Arms: opens or closes the gripper.'),
  'home': _sig('home', 'wait=True', 'Arms: the home pose.'),
  'throttle': _sig('throttle', 'pct — percent; seconds — how long; wait=True', 'Benches: holds a throttle.'),
  'ramp': _sig('ramp', 'start — percent; end — percent; seconds — over; wait=True', 'Benches: ramps the throttle.'),
  'run_program': _sig('run_program', 'name — a program from the Program screen; wait=True', 'Runs a program (on the device when it can store it).'),
  'pause_program': _sig('pause_program', '', 'Pauses the running program.'),
  'resume_program': _sig('resume_program', '', 'Resumes it.'),
  'stop_program': _sig('stop_program', '', 'Stops it.'),
  'camera': null,
  'cameras': null,
  'overlay': _sig('overlay', 'boxes — (x, y, w, h, label) tuples or an ultralytics result; width=None; height=None — for boxes in pixels', 'Draws boxes over the camera in dash.'),
  'params': null,
  'setting': _sig('setting', 'name — shown in dash; default — a number or True/False; min=None; max=None; label=None', 'A slider or switch in dash; read .value.'),
  'trigger': _sig('trigger', 'name — the event; kind="button" — "button", "switch" or "value"; key=None — e.g. "D"; gamepad=None — e.g. "LT"', 'Decorator: runs the function when the trigger fires.'),
  'on_trigger': null,
  'on_stop': null,
  'on_takeover': null,
  'plot': _sig('plot', 'name — channel name; value — a number', 'Shows and records a value (channel script:<name>).'),
  'mark': _sig('mark', 'text', 'An event on the recording\'s timeline.'),
  'notify': _sig('notify', 'text; level="info" — "info", "warn", "err"', 'A message to the operator in dash.'),
  'store': null,
  'run': _sig('run', '', 'Waits until dash closes the connection: for scripts that only react to triggers.'),
  'close': _sig('close', '', 'Closes the connection.'),
  'name': null,
  'kind': null,
  'simulated': null,
  'released': null,
  'taken_over': null,
  'hz': null,
  'info': null,
};

const _deviceDocs = {
  'tlm': 'latest telemetry (20 Hz)',
  'camera': 'the first camera: .frame(), .frames()',
  'cameras': 'every camera',
  'params': 'parameters: dev.params["KEY"], .set(), .save()',
  'on_trigger': 'decorator: any other trigger (name, value)',
  'on_stop': 'decorator: dash took the sticks, or STOP',
  'on_takeover': 'decorator: the operator took the sticks (True/False)',
  'store': 'a dict kept between runs',
  'name': 'the device name',
  'kind': 'drone, rover, arm, bench, rocket',
  'simulated': 'True for a simulated device',
  'released': 'why dash took the sticks, or None',
  'taken_over': 'True while the operator holds the sticks',
  'hz': 'the loop rate dash shows',
  'info': 'what dash says about the device',
};

const tlmFields = {
  'pos': '[x, y, z] m from home (x east, y north)',
  'alt': 'height above home, m',
  'vel': '[vx, vy, vz] m/s',
  'speed': 'm/s',
  'heading': 'compass degrees',
  'roll': 'rad',
  'pitch': 'rad',
  'yaw': 'rad',
  'mode': '"HOLD", "MANUAL"…',
  'armed': 'True / False',
  'estop': 'True while STOP is on',
  'failsafe': 'True in failsafe',
  'battery': 'percent',
  'voltage': 'V',
  'current': 'A',
  'gps': '(lat, lon, alt) or None',
  'joints': 'arm joint angles, rad',
  'gripper': '0…1',
  'thrust': 'bench thrust',
  'rpm': 'bench RPM',
  'temp': '°C',
  'latency': 's',
  'drive': '"none", "script", "operator"',
  'custom': 'the device\'s own channels',
  'age': 'seconds since it arrived',
  'raw': 'everything, as a dict',
};

final cameraApi = <String, Signature?>{
  'frame': _sig('frame', 'timeout=5.0', 'The newest frame, H×W×3 BGR numpy array.'),
  'frames': _sig('frames', 'timeout=5.0', 'Each new frame, newest first.'),
  'jpeg': _sig('jpeg', 'timeout=5.0', 'The newest frame as the camera sends it.'),
  'label': null,
  'url': null,
  'fps': null,
  'close': _sig('close', '', 'Stops reading the stream.'),
};

final paramsApi = <String, Signature?>{
  'all': _sig('all', '', 'Every parameter, as a dict.'),
  'set': _sig('set', '**values — KEY=value', 'Writes parameters (needs Allow parameter writes).'),
  'save': _sig('save', '', 'Saves them to the device\'s flash.'),
};

final topLevel = <String, Signature?>{
  'connect': _sig('connect', 'device=None — a name, else the one selected in dash; requires=None — e.g. ["drone", "gps"]', 'The device, from koebelt dash.'),
  'every': _sig('every', 'seconds — the period', 'A steady loop: for _ in every(0.05):'),
  'wait': _sig('wait', 'seconds', 'Sleeps.'),
  'pid': _sig('pid', 'kp; ki=0.0; kd=0.0; limit=1.0', 'A PID controller: .update(error).'),
  'lowpass': _sig('lowpass', 'hz — cut-off', 'A low-pass filter: .update(x).'),
  'rate_limit': _sig('rate_limit', 'per_second; start=0.0', 'Smooth changes: .update(target).'),
  'clamp': _sig('clamp', 'x; lo=-1.0; hi=1.0', 'Limits a value.'),
  'distance': _sig('distance', 'a; b=(0, 0, 0)', 'Metres between local positions.'),
  'bearing': _sig('bearing', 'a; b', 'Compass bearing from a to b, degrees.'),
  'angle_diff': _sig('angle_diff', 'target; current', 'Shortest turn between headings, −180…180.'),
  'geo_distance': _sig('geo_distance', 'lat1; lon1; lat2; lon2', 'Metres between GPS positions.'),
  'geo_bearing': _sig('geo_bearing', 'lat1; lon1; lat2; lon2', 'Bearing between GPS positions.'),
  'ScriptError': null,
};

const _keywords = [
  'and', 'as', 'assert', 'break', 'class', 'continue', 'def', 'del', 'elif', 'else', 'except', 'False', 'finally', 'for', 'from', //
  'global', 'if', 'import', 'in', 'is', 'lambda', 'None', 'nonlocal', 'not', 'or', 'pass', 'raise', 'return', 'True', 'try', 'while', 'with', 'yield',
];
const _builtins = ['print', 'range', 'len', 'abs', 'min', 'max', 'round', 'int', 'float', 'str', 'list', 'dict', 'enumerate', 'zip', 'sorted', 'sum', 'isinstance'];

/// Names in the script bound to a type of the API: `dev = connect()`,
/// `t = dev.tlm`, `cam = dev.camera`, `speed = dev.setting(…)`.
Map<String, String> _types(String text) {
  final out = <String, String>{};
  for (final m in RegExp(r'^\s*(\w+)\s*=\s*(?:\w+\.)?connect\(', multiLine: true).allMatches(text)) {
    out[m[1]!] = 'device';
  }
  for (var pass = 0; pass < 2; pass++) {
    for (final m in RegExp(r'^\s*(\w+)\s*=\s*(\w+)\.(tlm|next_tlm\(\)|camera|params|setting\()', multiLine: true).allMatches(text)) {
      if (out[m[2]] != 'device') continue;
      out[m[1]!] = switch (m[3]!) {
        'tlm' || 'next_tlm()' => 'tlm',
        'camera' => 'camera',
        'params' => 'params',
        _ => 'setting',
      };
    }
  }
  return out;
}

/// The script's own names: variables, functions, imports.
Set<String> _ownNames(String text) => {
  for (final m in RegExp(r'^\s*(?:def|class)\s+(\w+)|^\s*(\w+)\s*=(?!=)|^\s*for\s+(\w+)\s+in|import\s+(\w+)(?:\s*$|,)', multiLine: true).allMatches(text))
    for (var g = 1; g <= 4; g++)
      if (m[g] != null && m[g] != '_') m[g]!,
};

/// What can complete at [cursor], and how many characters before it the
/// chosen one replaces.
({List<Completion> items, int replace}) completeAt(String text, int cursor, [CompletionContext ctx = const CompletionContext()]) {
  if (cursor < 0 || cursor > text.length) return (items: const [], replace: 0);
  final before = text.substring(0, cursor);
  final line = before.substring(before.lastIndexOf('\n') + 1);
  if (RegExp(r'^\s*#').hasMatch(line)) return (items: const [], replace: 0);
  final types = _types(text);

  // Inside a string argument: program names, trigger kinds, modes.
  final str = RegExp(r'(\w+)\.(run_program|mode|trigger|cmd)\(\s*(?:\w+\s*=\s*)?"([^"]*)$|kind\s*=\s*"([^"]*)$').firstMatch(line);
  if (str != null) {
    final typed = str[3] ?? str[4] ?? '';
    final pool = str[4] != null
        ? ['button', 'switch', 'value']
        : switch (str[2]) {
            'run_program' => ctx.programs,
            'mode' => ['HOLD', 'MANUAL', 'AUTO', if (ctx.kind == 'drone') ...['RTH', 'LAND', 'TAKEOFF']],
            _ => const <String>[],
          };
    return (items: [for (final p in _rank(pool, typed)) Completion(p, kind: CompletionKind.value)], replace: typed.length);
  }

  // Inside sticks( ): the axes of this kind of device.
  final sticks = RegExp(r'(\w+)\.sticks\(([^()]*)$').firstMatch(line);
  if (sticks != null && types[sticks[1]] == 'device') {
    final args = sticks[2]!;
    final typed = RegExp(r'(\w*)$').firstMatch(args)![1]!;
    final used = RegExp(r'(\w+)\s*=').allMatches(args).map((m) => m[1]).toSet();
    // A new argument, not the value of the one being typed.
    if (!args.split(',').last.contains('=')) {
      final axes = ctx.sticks.isEmpty ? ['throttle', 'yaw', 'pitch', 'roll', 'steer'] : ctx.sticks;
      return (
        items: [
          for (final a in _rank(axes.where((a) => !used.contains(a)), typed)) Completion('$a=', detail: '−1…1', kind: CompletionKind.value),
        ],
        replace: typed.length,
      );
    }
  }

  final m = RegExp(r'([A-Za-z_][\w]*(?:\(\))?)\.([A-Za-z_]\w*)?$|([A-Za-z_]\w*)$').firstMatch(before);
  if (m == null) return (items: const [], replace: 0);
  if (m[1] != null) {
    // A member: what is before the dot?
    final owner = m[1]!.replaceAll('()', ''), typed = m[2] ?? '';
    final ownerChain = RegExp(r'(\w+)\.(\w+)\.(\w*)$').firstMatch(before);
    String? type = types[owner];
    if (ownerChain != null && types[ownerChain[1]] == 'device') {
      type = switch (ownerChain[2]) {
        'tlm' => 'tlm',
        'camera' => 'camera',
        'params' => 'params',
        _ => null,
      };
    }
    if (owner == 'next_tlm' || before.endsWith('next_tlm().$typed')) type = 'tlm';
    final items = <Completion>[];
    switch (type) {
      case 'device':
        for (final e in _rankMap(deviceApi, typed)) {
          final s = deviceApi[e];
          items.add(
            s == null
                ? Completion(e, detail: _deviceDocs[e] ?? '', kind: CompletionKind.field)
                : Completion('$e()', detail: s.doc, kind: CompletionKind.method, insert: '$e()', cursorBack: s.params.isEmpty ? 0 : 1),
          );
        }
      case 'tlm':
        final fields = {...tlmFields, for (final f in ctx.tlm) f: tlmFields[f] ?? 'sent by this device', for (final c in ctx.channels) c: 'this device\'s channel'};
        for (final f in _rank(fields.keys, typed)) {
          items.add(Completion(f, detail: fields[f]!, kind: CompletionKind.field));
        }
      case 'camera':
        for (final e in _rankMap(cameraApi, typed)) {
          final s = cameraApi[e];
          items.add(s == null ? Completion(e) : Completion('$e()', detail: s.doc, kind: CompletionKind.method, insert: '$e()', cursorBack: s.params.isEmpty ? 0 : 1));
        }
      case 'params':
        for (final e in _rankMap(paramsApi, typed)) {
          final s = paramsApi[e]!;
          items.add(Completion('$e()', detail: s.doc, kind: CompletionKind.method, insert: '$e()', cursorBack: s.params.isEmpty ? 0 : 1));
        }
      case 'setting':
        for (final f in _rank(['value', 'name'], typed)) {
          items.add(Completion(f, detail: f == 'value' ? 'the operator\'s current value' : '', kind: CompletionKind.field));
        }
    }
    return (items: items.take(12).toList(), replace: typed.length);
  }

  // A plain name: the API's functions, the script's names, keywords.
  final typed = m[3]!;
  if (typed.length < 2) return (items: const [], replace: 0);
  final own = _ownNames(text)..remove(typed);
  final items = <Completion>[
    for (final e in _rankMap(topLevel, typed))
      topLevel[e] == null
          ? Completion(e, kind: CompletionKind.function)
          : Completion('$e()', detail: topLevel[e]!.doc, kind: CompletionKind.function, insert: '$e()', cursorBack: topLevel[e]!.params.isEmpty ? 0 : 1),
    for (final n in _rank(own, typed)) Completion(n, detail: types[n] == null ? 'in this script' : 'a ${types[n]}', kind: CompletionKind.variable),
    for (final k in _rank(_keywords, typed)) Completion(k, kind: CompletionKind.keyword),
    for (final b in _rank(_builtins, typed)) Completion('$b()', kind: CompletionKind.function, insert: '$b()', cursorBack: 1),
  ];
  return (items: items.take(12).toList(), replace: typed.length);
}

/// Prefix matches first, then names that contain what was typed.
List<String> _rank(Iterable<String> names, String typed) {
  final t = typed.toLowerCase();
  final pre = <String>[], has = <String>[];
  for (final n in names) {
    final l = n.toLowerCase();
    if (l == t) continue;
    if (l.startsWith(t)) {
      pre.add(n);
    } else if (t.length >= 2 && l.contains(t)) {
      has.add(n);
    }
  }
  return [...pre, ...has];
}

List<String> _rankMap(Map<String, Signature?> m, String typed) => _rank(m.keys, typed);

/// The call the cursor is in, and which argument: for the hint above it.
({Signature sig, int arg})? signatureAt(String text, int cursor) {
  if (cursor < 0 || cursor > text.length) return null;
  final before = text.substring(0, cursor);
  // Back to the unclosed "(" of this call.
  var depth = 0, args = 0;
  for (var i = before.length - 1; i >= 0; i--) {
    final ch = before[i];
    if (ch == '\n' && depth == 0 && i < before.length - 200) return null;
    if (ch == ')') depth++;
    if (ch == '(') {
      if (depth == 0) {
        final m = RegExp(r'(?:(\w+)\.)?(\w+)$').firstMatch(before.substring(0, i));
        if (m == null) return null;
        final types = _types(text);
        final owner = m[1], name = m[2]!;
        Signature? sig;
        if (owner == null) {
          sig = topLevel[name];
        } else if (types[owner] == 'device') {
          sig = deviceApi[name];
        } else if (owner == 'camera' || types[owner] == 'camera') {
          sig = cameraApi[name];
        } else if (owner == 'params' || types[owner] == 'params') {
          sig = paramsApi[name];
        }
        if (sig == null) return null;
        return (sig: sig, arg: args.clamp(0, sig.params.isEmpty ? 0 : sig.params.length - 1));
      }
      depth--;
    }
    if (ch == ',' && depth == 0) args++;
  }
  return null;
}
