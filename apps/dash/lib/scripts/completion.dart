/// Completion and signature help for the in-app Python editor: the
/// koebelt_dash_scripts API, the script's own names, Python's keywords, and
/// what dash knows about the device the script runs on.
library;

import 'introspect.dart' show Member;

enum CompletionKind { method, field, function, variable, keyword, value, module, klass, file, folder }

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
  const CompletionContext({
    this.kind,
    this.sticks = const [],
    this.tlm = const [],
    this.programs = const [],
    this.steps = const [],
    this.channels = const [],
    this.members,
    this.installed,
    this.files,
  });
  final String? kind;
  final List<String> sticks, tlm, programs, steps, channels;

  /// The members of a module or class by dotted path (numpy.linalg,
  /// cv2.VideoCapture), as the script's Python reports them; null while not
  /// known yet (asking starts the lookup).
  final Map<String, Member>? Function(String path)? members;

  /// The installed top-level modules, null until known.
  final List<String>? Function()? installed;

  /// The entries of a folder relative to the script's: (name, is a folder).
  final List<(String, bool)> Function(String dir)? files;
}

/// Calls that take a file, for path completion without a "/" typed yet.
const _fileCalls = {
  'open', 'Path', 'YOLO', 'imread', 'imwrite', 'VideoCapture', 'load', 'loadtxt', 'save', 'savetxt', 'read_csv', 'read_json', //
  'to_csv', 'listdir', 'exists', 'isfile', 'isdir', 'join', 'mkdir', 'remove', 'rename', 'glob',
};

/// What the script's imports bind: name → dotted path. `import numpy as np`
/// → np: numpy; `from cv2 import VideoCapture as VC` → VC: cv2.VideoCapture;
/// `cap = cv2.VideoCapture(0)` → cap: cv2.VideoCapture (a class, for its members).
Map<String, String> importsOf(String text, [Map<String, Member>? Function(String path)? members]) {
  final out = <String, String>{};
  for (final m in RegExp(r'^\s*import\s+([\w.]+(?:\s+as\s+\w+)?(?:\s*,\s*[\w.]+(?:\s+as\s+\w+)?)*)', multiLine: true).allMatches(text)) {
    for (final part in m[1]!.split(',')) {
      final p = part.trim().split(RegExp(r'\s+as\s+'));
      if (p.length == 2) {
        out[p[1]] = p[0];
      } else {
        out[p[0].split('.').first] = p[0].split('.').first;
      }
    }
  }
  for (final m in RegExp(r'^\s*from\s+([\w.]+)\s+import\s+\(?([\w\s,]+)', multiLine: true).allMatches(text)) {
    if (m[1] == 'koebelt_dash_scripts' || m[1]!.startsWith('koebelt_dash_scripts.')) continue;
    for (final part in m[2]!.split(',')) {
      final p = part.trim().split(RegExp(r'\s+as\s+'));
      if (p.first.isEmpty) continue;
      out[p.length == 2 ? p[1] : p[0]] = '${m[1]}.${p[0]}';
    }
  }
  // Instances of a library's classes: x = np.ndarray(…), cap = VideoCapture(0).
  if (members != null) {
    for (final m in RegExp(r'^\s*(\w+)\s*=\s*([\w.]+)\(', multiLine: true).allMatches(text)) {
      final path = resolvePath(m[2]!, out);
      if (path == null || out.containsKey(m[1])) continue;
      final dot = path.lastIndexOf('.');
      if (dot < 0) continue;
      final owner = members(path.substring(0, dot));
      if (owner?[path.substring(dot + 1)]?.kind == 'class') out[m[1]!] = path;
    }
  }
  return out;
}

/// `np.linalg` → numpy.linalg, with the script's imports; null if the first
/// name is not an import.
String? resolvePath(String chain, Map<String, String> imports) {
  final parts = chain.split('.');
  final head = imports[parts.first];
  if (head == null) return null;
  return [head, ...parts.skip(1)].join('.');
}

/// "(a, b=1, *, c=None)" → its parameters, top-level commas only.
List<(String, String)> _paramsOf(String sig) {
  final inner = sig.startsWith('(') ? sig.substring(1, sig.lastIndexOf(')') < 0 ? sig.length : sig.lastIndexOf(')')) : sig;
  final out = <(String, String)>[];
  var depth = 0, start = 0;
  for (var i = 0; i <= inner.length; i++) {
    final ch = i < inner.length ? inner[i] : ',';
    if ('([{'.contains(ch)) depth++;
    if (')]}'.contains(ch)) depth--;
    if (ch == ',' && depth == 0) {
      final p = inner.substring(start, i).trim();
      if (p.isNotEmpty && p != 'self' && p != '/' && p != '*') out.add((p, ''));
      start = i + 1;
    }
  }
  return out;
}

Completion _memberItem(String name, Member m) => switch (m.kind) {
  'function' => Completion('$name()', detail: m.doc, kind: CompletionKind.function, insert: '$name()', cursorBack: _paramsOf(m.sig).isEmpty ? 0 : 1),
  'class' => Completion(name, detail: m.doc, kind: CompletionKind.klass),
  'module' => Completion(name, detail: m.doc.isEmpty ? 'module' : m.doc, kind: CompletionKind.module),
  _ => Completion(name, detail: m.doc, kind: CompletionKind.field),
};

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

  // import x / from x import y: modules and their members, from the script's Python.
  final imp = RegExp(r'^\s*(?:import|from)\s+([\w.]*)$').firstMatch(line);
  if (imp != null) {
    final path = imp[1]!, dot = path.lastIndexOf('.');
    final typed = path.substring(dot + 1);
    if (dot < 0) {
      final mods = {'koebelt_dash_scripts', ...?ctx.installed?.call()};
      return (items: [for (final n in _rank(mods, typed)) Completion(n, kind: CompletionKind.module)], replace: typed.length);
    }
    final m = ctx.members?.call(path.substring(0, dot)) ?? const {};
    return (
      items: [for (final n in _rank(m.keys.where((k) => m[k]!.kind == 'module'), typed)) Completion(n, kind: CompletionKind.module)],
      replace: typed.length,
    );
  }
  final from = RegExp(r'^\s*from\s+([\w.]+)\s+import\s+(?:\(?[\w\s,]*,\s*)?\(?(\w*)$').firstMatch(line);
  if (from != null) {
    final typed = from[2]!;
    if (from[1] == 'koebelt_dash_scripts') {
      return (items: [for (final n in _rank(topLevel.keys, typed)) Completion(n, detail: topLevel[n]?.doc ?? '', kind: CompletionKind.function)], replace: typed.length);
    }
    final m = ctx.members?.call(from[1]!) ?? const {};
    return (items: [for (final n in _rank(m.keys, typed).take(40)) _memberItem(n, m[n]!)].map((c) => Completion(c.label.replaceAll('()', ''), detail: c.detail, kind: c.kind)).toList(), replace: typed.length);
  }

  // File paths, relative to the script's folder, inside a string.
  final quote = RegExp(r'''(\w*)\(?\s*[rRbBfF]?(["'])([^"'\n]*)$''').firstMatch(line);
  if (quote != null && ctx.files != null && RegExp(quote[2]!).allMatches(line).length.isOdd) {
    final typed = quote[3]!, slash = typed.lastIndexOf('/');
    // ./models and models are the same folder.
    final dir = slash < 0 ? '' : typed.substring(0, slash).replaceFirst(RegExp(r'^\./?'), ''), prefix = typed.substring(slash + 1);
    final entries = ctx.files!(dir);
    final looksLikePath = typed.contains('/') || typed.startsWith('.') || _fileCalls.contains(quote[1]) || (prefix.isNotEmpty && entries.any((e) => e.$1.startsWith(prefix)));
    if (looksLikePath) {
      final hits = [
        for (final e in entries)
          if (e.$1.toLowerCase().startsWith(prefix.toLowerCase()) && (prefix.startsWith('.') || !e.$1.startsWith('.')) && e.$1 != prefix) e,
      ]..sort((a, b) => a.$2 == b.$2 ? a.$1.compareTo(b.$1) : (a.$2 ? -1 : 1));
      if (hits.isNotEmpty || typed.contains('/')) {
        return (
          items: [for (final e in hits.take(20)) Completion(e.$2 ? '${e.$1}/' : e.$1, kind: e.$2 ? CompletionKind.folder : CompletionKind.file)],
          replace: prefix.length,
        );
      }
    }
  }

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
    if (type == null && ctx.members != null) {
      // A library: np. / np.linalg. / cap. (an instance of a library class)
      final chain = RegExp(r'([\w.]+)\.\w*$').firstMatch(before)![1]!;
      final path = resolvePath(chain, importsOf(text, ctx.members));
      final m = path == null ? null : ctx.members!(path);
      if (m != null) {
        for (final n in _rank(m.keys, typed).take(40)) {
          items.add(_memberItem(n, m[n]!));
        }
        return (items: items, replace: typed.length);
      }
    }
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
({Signature sig, int arg})? signatureAt(String text, int cursor, [Map<String, Member>? Function(String path)? members]) {
  if (cursor < 0 || cursor > text.length) return null;
  final before = text.substring(0, cursor);
  // Back to the unclosed "(" of this call.
  var depth = 0, args = 0;
  for (var i = before.length - 1; i >= 0; i--) {
    final ch = before[i];
    if (ch == '\n' && depth == 0 && i < before.length - 200) return null;
    // Commas inside [ ] and { } (a list, a dict) are not between arguments.
    if (ch == ']' || ch == '}') depth++;
    if ((ch == '[' || ch == '{') && depth > 0) depth--;
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
        if (sig == null && members != null) {
          final chainM = RegExp(r'([\w.]+)$').firstMatch(before.substring(0, i));
          final path = chainM == null ? null : resolvePath(chainM[1]!, importsOf(text, members));
          if (path != null && path.contains('.')) {
            final dot = path.lastIndexOf('.');
            final mem = members(path.substring(0, dot))?[path.substring(dot + 1)];
            if (mem != null && (mem.kind == 'function' || mem.kind == 'class')) sig = Signature(path.substring(dot + 1), _paramsOf(mem.sig), mem.doc);
          }
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
