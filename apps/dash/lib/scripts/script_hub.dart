import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

import '../core/dash.dart';
import '../core/device_link.dart';
import '../core/compat.dart' show compareVersions, fromPep440;
import '../core/model.dart';
import '../core/sequence.dart';
import '../link/protocol.dart';
import '../video/video_hub.dart' show resolveVideoUrl;
import 'fields.dart';
import 'hosts.dart';
import 'introspect.dart';
import 'requirements.dart';
import 'script_runner.dart';
import 'triggers.dart';
import 'views.dart';

/// The script API: Python scripts (koebelt-dash-scripts) connect here over a
/// WebSocket, and every command they send passes the safety layer below
/// before it reaches a device. See docs/design/scripts.md and
/// protocol/SCRIPTS.md for the messages.
const scriptApiVersion = 1;
const scriptApiPort = 47920;

/// What the operator lets a script do on a device. Set in dash, never by the
/// script.
class ScriptLimits {
  ScriptLimits({this.maxSpeed = .6, this.fence = 50, this.ceiling = 30, this.allowArm = false, this.allowParams = false});

  /// Fraction of full stick (0–1). Also sent as the device's speed limit.
  double maxSpeed;

  /// Metres from home, horizontally, and height above home; 0 = no limit.
  double fence, ceiling;
  bool allowArm, allowParams;

  Map<String, dynamic> toJson() => {'maxSpeed': maxSpeed, 'fence': fence, 'ceiling': ceiling, 'allowArm': allowArm, 'allowParams': allowParams};
}

/// Stick names per kind, as the protocol's axes (lx ly rx ry): drones fly
/// "mode 2", ground robots steer on the left and drive on the right.
const stickAxes = <DeviceKind, Map<String, int>>{
  DeviceKind.drone: {'yaw': 0, 'throttle': 1, 'roll': 2, 'pitch': 3},
  DeviceKind.rover: {'steer': 0, 'throttle': 3},
};

/// A request dash refuses, with its code (protocol/SCRIPTS.md, Errors).
class ScriptRefusal implements Exception {
  ScriptRefusal(this.code, this.message, [this.data]);
  final String code, message;
  final Map<String, Object?>? data;
  @override
  String toString() => message;
}

/// Maps named sticks (`throttle`, `steer`…) or raw axes (`lx`…) to the four
/// axes, clamped to −1…1. Unknown names are an error.
List<double> sticksFor(DeviceKind kind, Map a, List<double> current) {
  final names = stickAxes[kind] ?? const {};
  final out = List.of(current);
  for (final e in a.entries) {
    final i = names[e.key] ?? const {'lx': 0, 'ly': 1, 'rx': 2, 'ry': 3}[e.key];
    if (i == null) {
      throw ScriptRefusal(
        'E0201',
        '"${e.key}" is not a stick of a ${kind.name}${names.isEmpty ? '' : ' (${names.keys.join(', ')})'}',
        {'name': e.key, 'names': [...names.keys, 'lx', 'ly', 'rx', 'ry'], 'kind': kind.name},
      );
    }
    out[i] = (e.value as num).toDouble().clamp(-1.0, 1.0);
  }
  return out;
}

/// A script driving one device's sticks. The control heartbeat reads [axes]
/// 20 times a second; the operator's sticks win over the script's.
class ScriptDrive {
  ScriptDrive(this.conn, this.link);
  final ScriptConn conn;
  final DeviceLink link;
  final List<double> sticks = [0, 0, 0, 0];

  /// The operator took over: the script's sticks are ignored until Resume.
  bool paused = false;

  /// Beyond this, an operator stick counts as taking over.
  static const takeoverAt = .15;

  List<double> axes(List<double> operator) {
    if (operator.any((x) => x.abs() > takeoverAt)) {
      if (!paused) {
        paused = true;
        conn.hub.takeover(this);
      }
      return operator;
    }
    if (paused) return operator;
    final k = conn.limits.maxSpeed;
    return [for (final x in sticks) x * k];
  }
}

/// One connected script.
class ScriptConn {
  ScriptConn(this.hub, this.ws, this.name);
  final ScriptHub hub;
  final WebSocket ws;
  String name;
  int? pid;

  /// The operator's setup for this script (limits, bindings), by its path.
  ScriptConfig config = ScriptConfig();
  ScriptLimits get limits => config.limits;
  final triggerState = TriggerState();

  /// The path that keys its configuration: its file, or its name for a
  /// script started outside dash.
  String get configKey => run?.file.path ?? 'name:$name';

  /// The device this script works with (a link id), and whether it holds its sticks.
  String? device;
  ScriptDrive? drive;
  double lastSeen = 0;

  /// Why dash took the sticks away (watchdog, geofence, STOP…): the script
  /// cannot take them again until the operator resumes it.
  String? blocked;

  /// The script's own loop rate, from its keep-alives (every()).
  double? hz;

  /// Steps and sequences the script waits on: request id → (device, sequence id).
  final Map<Object, ({DeviceLink link, String seq})> pending = {};

  /// Declared by the script: settings (name → value, bounds) and triggers.
  final Map<String, Map<String, dynamic>> settings = {};
  final Map<String, Map<String, dynamic>> triggers = {};
  final List<ConsoleLine> console = [];

  void send(Map<String, dynamic> m) {
    try {
      ws.add(jsonEncode(m));
    } catch (_) {}
  }

  /// The process, when dash started the script.
  ScriptRun? run;

  void log(String level, String text) {
    console.add((at: DateTime.now(), level: level, text: text));
    if (console.length > 500) console.removeRange(0, console.length - 500);
    run?.log(level, text);
  }
}

class ScriptHub {
  ScriptHub(this.d);
  final Dash d;
  HttpServer? _server;
  final List<ScriptConn> conns = [];

  /// Scripts dash started, running or finished (the last few).
  final List<ScriptRun> runs = [];

  /// Whether the API listens on the local network, for scripts on script
  /// hosts. Only the tokens of runs dash started are accepted from there.
  bool lan = false;

  /// Script hosts this dash is paired with.
  final List<ScriptHost> hosts = [];
  static const _hostsKey = 'kdash-script-hosts-v1';

  void saveHosts() => d.store.writeJson(_hostsKey, [for (final h in hosts) h.toJson()]);

  void addHost(ScriptHost h) {
    hosts.removeWhere((x) => x.key == h.key || x.name == h.name);
    hosts.add(h);
    saveHosts();
    d.emit();
  }

  void forgetHost(ScriptHost h) {
    hosts.remove(h);
    for (final c in configs.values) {
      if (c.host == h.key) c.host = null;
    }
    saveHosts();
    saveConfigs();
    d.emit();
  }

  /// This computer as a script host for phones (`koebelt-dash-scripts host`,
  /// started by dash with the scripts' Python), its pairing code and output.
  Process? hostService;
  String? hostCode;
  final List<String> hostLog = [];

  Future<void> startHostService(String python) async {
    if (hostService != null) return;
    hostLog.clear();
    final p = await Process.start(python, ['-u', '-m', 'koebelt_dash_scripts', 'host']);
    hostService = p;
    void line(String l) {
      hostLog.add(l);
      if (hostLog.length > 50) hostLog.removeAt(0);
      final m = RegExp(r'(?:Pairing code:|Next pairing code:)\s*([A-Z0-9]{3}-[A-Z0-9]{3})').firstMatch(l);
      if (m != null) hostCode = m[1];
      d.emit();
    }

    p.stdout.transform(const SystemEncoding().decoder).transform(const LineSplitter()).listen(line);
    p.stderr.transform(const SystemEncoding().decoder).transform(const LineSplitter()).listen(line);
    unawaited(
      p.exitCode.then((_) {
        if (hostService == p) hostService = null;
        hostCode = null;
        d.emit();
      }),
    );
    d.emit();
  }

  void stopHostService() {
    hostService?.kill();
    hostService = null;
    hostCode = null;
    d.emit();
  }

  /// Where a script runs: its chosen host, else this computer, else (phones)
  /// the first paired host.
  ScriptHost? hostFor(ScriptConfig c) {
    final chosen = hosts.where((h) => h.key == c.host).firstOrNull;
    if (chosen != null) return chosen;
    return canRunHere ? null : hosts.firstOrNull;
  }

  /// Pythons found on this computer (null until looked for).
  List<PythonEnv>? pythons;
  bool findingPythons = false;

  /// Output of setting up a Python environment for scripts, while it runs.
  final List<String> setupLog = [];
  bool settingUp = false;

  /// Whether scripts can run here: computers only (phones use a script host).
  static bool get canRunHere => Platform.isMacOS || Platform.isLinux || Platform.isWindows;

  Future<void> refreshPythons({Directory? near}) async {
    if (findingPythons) return;
    findingPythons = true;
    d.emit();
    try {
      pythons = await findPythons(near: near);
    } finally {
      findingPythons = false;
      d.emit();
    }
  }

  /// The interpreter for a script: the one chosen for it, else the first
  /// with koebelt-dash-scripts.
  String? pythonFor(ScriptConfig c) => c.python ?? pythons?.where((p) => p.hasPackage).firstOrNull?.path;

  /// The newest koebelt-dash-scripts on PyPI that works with this app (a
  /// beta app takes betas), looked up at most once a day; null until then.
  String? latestPackage;
  DateTime? _packageChecked;

  /// Asks PyPI, on computers (where scripts run).
  Future<void> checkPackageUpdates({http.Client? client, bool force = false}) async {
    if (!canRunHere && client == null) return;
    if (!force && _packageChecked != null && DateTime.now().difference(_packageChecked!) < const Duration(days: 1)) return;
    _packageChecked = DateTime.now();
    final c = client ?? http.Client();
    try {
      final r = await c
          .get(Uri.parse('https://pypi.org/pypi/koebelt-dash-scripts/json'), headers: {'User-Agent': 'koebelt-dash/$appVersion'})
          .timeout(const Duration(seconds: 10));
      if (r.statusCode != 200) return;
      final releases = ((jsonDecode(r.body) as Map)['releases'] as Map).keys.cast<String>();
      final ok = [
        for (final v in releases.map(fromPep440))
          if (scriptsPackageAccepts(v)) v,
      ]..sort(compareVersions);
      latestPackage = ok.lastOrNull;
      d.emit();
    } catch (_) {
      // Offline: the panel just does not offer an update.
    } finally {
      if (client == null) c.close();
    }
  }

  /// Whether the Python at [path] has an older koebelt-dash-scripts than
  /// [latestPackage].
  bool packageOutdated(String? path) {
    final have = envOf(path)?.packageVersion, latest = latestPackage;
    return have != null && latest != null && compareVersions(fromPep440(have), latest) < 0;
  }

  /// What each Python's modules hold, for the editor's completion.
  final Map<String, PythonIntrospector> _introspectors = {};
  PythonIntrospector introspector(String python) => _introspectors.putIfAbsent(python, () => PythonIntrospector(python, onChange: d.emit));

  /// What dash knows of an interpreter, if it has looked at it.
  PythonEnv? envOf(String? path) => path == null ? null : pythons?.where((p) => p.path == path).firstOrNull;

  /// Looks at one interpreter again (chosen, or changed outside dash): its
  /// version and whether it has koebelt-dash-scripts.
  Future<void> recheckPython(String path) async {
    final p = await probePython(path);
    final list = [...?pythons]..removeWhere((x) => x.path == path);
    if (p != null) list.insert(0, p);
    pythons = list;
    d.emit();
  }

  /// Installs koebelt-dash-scripts into [python] (a virtual environment or
  /// conda; system Pythons often refuse, and say so).
  Future<void> installInto(String python, {bool upgrade = false}) async {
    if (settingUp) return;
    settingUp = true;
    setupLog.clear();
    setupResult = null;
    d.emit();
    String? failed;
    try {
      await installScriptsPackage(python, (l) {
        setupLog.add(l);
        d.emit();
      }, upgrade: upgrade);
      setupLog.add('Ready.');
    } catch (e) {
      final why = setupLog.where((l) => l.contains('externally-managed') || l.toLowerCase().contains('error')).firstOrNull;
      failed = why != null && why.contains('externally-managed')
          ? 'This Python is managed by the system and refuses packages: use a scripts environment instead.'
          : 'Failed: ${why ?? e}';
      setupLog.add(failed);
    } finally {
      settingUp = false;
      await recheckPython(python);
    }
    final v = envOf(python)?.packageVersion;
    _result(
      failed == null && v != null,
      failed ?? (v == null ? 'pip finished, but koebelt-dash-scripts is still not in this Python.' : 'koebelt-dash-scripts ${fromPep440(v)} is ${upgrade ? 'up to date' : 'installed'} in this Python.'),
    );
  }

  /// Packages the operator chose not to install ("python|module"), not
  /// offered again until dash restarts.
  final Set<String> declinedImports = {};

  /// Installs packages a script imports into [python]; true if pip did.
  Future<bool> installPackages(String python, List<String> packages) async {
    if (settingUp || packages.isEmpty) return false;
    settingUp = true;
    setupLog
      ..clear()
      ..add('Installing ${packages.join(', ')}');
    setupResult = null;
    d.emit();
    String? failed;
    try {
      await pipInstall(python, packages, (l) {
        setupLog.add(l);
        d.emit();
      });
    } catch (e) {
      final why = setupLog.where((l) => l.contains('externally-managed') || l.contains('ERROR')).firstOrNull;
      failed = why != null && why.contains('externally-managed')
          ? 'This Python is managed by the system and refuses packages: use a scripts environment instead.'
          : 'Failed: ${why?.replaceFirst('ERROR: ', '') ?? e}';
    } finally {
      settingUp = false;
      introspector(python).forgetInstalled();
    }
    _result(failed == null, failed ?? '${packages.join(', ')} ${packages.length == 1 ? 'is' : 'are'} installed in this Python.');
    return failed == null;
  }

  /// The outcome of the last install, update or setup, shown on the panel: a
  /// success for a few seconds, a failure until the next attempt.
  ({bool ok, String text})? setupResult;
  Timer? _resultTimer;
  static const resultShown = Duration(seconds: 6);

  void _result(bool ok, String text) {
    setupResult = (ok: ok, text: text);
    _resultTimer?.cancel();
    if (ok) {
      _resultTimer = Timer(resultShown, () {
        if (setupResult?.text == text) setupResult = null;
        d.emit();
      });
    }
    d.emit();
  }

  void dismissResult() {
    setupResult = null;
    d.emit();
  }

  /// Creates `<scripts folder>/.venv` with koebelt-dash-scripts, and makes it
  /// [cfg]'s interpreter.
  Future<void> setupPython(Directory scripts, {ScriptConfig? cfg}) async {
    final base = pythons?.firstOrNull?.path;
    if (base == null || settingUp) return;
    settingUp = true;
    setupLog.clear();
    setupResult = null;
    d.emit();
    String? venvPath, failed;
    try {
      final venv = await createScriptsVenv(base, Directory('${scripts.path}${Platform.pathSeparator}.venv'), (l) {
        setupLog.add(l);
        d.emit();
      });
      if (cfg != null) {
        cfg.python = venv;
        saveConfigs();
      }
      venvPath = venv;
      setupLog.add('Ready.');
    } catch (e) {
      failed = 'Failed: $e';
      setupLog.add(failed);
    } finally {
      settingUp = false;
      await refreshPythons(near: scripts);
    }
    final v = envOf(venvPath)?.packageVersion;
    _result(failed == null && v != null, failed ?? 'The scripts environment is ready, with koebelt-dash-scripts ${fromPep440(v ?? '?')}.');
  }

  /// The operator's setup per script (by path), kept by the store.
  final Map<String, ScriptConfig> configs = {};
  static const _configKey = 'kdash-scripts-v1';
  double _trigAcc = 0;

  void load() {
    final hj = d.store.readJson(_hostsKey);
    if (hj is List) {
      for (final h in hj) {
        if (h is Map) hosts.add(ScriptHost.fromJson(h));
      }
    }
    final j = d.store.readJson(_configKey);
    if (j is Map) {
      for (final e in j.entries) {
        if (e.value is Map) configs['${e.key}'] = ScriptConfig.fromJson(e.value as Map);
      }
    }
  }

  void saveConfigs() => d.store.writeJson(_configKey, {for (final e in configs.entries) e.key: e.value.toJson()});

  ScriptConfig configFor(String key) => configs[key] ??= ScriptConfig();

  /// Keeps a script's setup when its file is renamed.
  void moveConfig(String from, String to) {
    final c = configs.remove(from);
    if (c != null) configs[to] = c;
    saveConfigs();
  }
  String token = _newToken();
  double _tlmAcc = 0;

  /// A script that sends nothing for this long, while it drives, loses the
  /// device, which holds.
  static const watchdog = .5;

  int? get port => _server?.port;

  static String _newToken() {
    final r = math.Random.secure();
    return [for (var i = 0; i < 16; i++) r.nextInt(256).toRadixString(16).padLeft(2, '0')].join();
  }

  /// Opens the API on 127.0.0.1. [discovery]: where to write the address and
  /// token for scripts started by hand (null in tests).
  Future<void> start({int port = scriptApiPort, File? discovery, bool lan = false}) async {
    if (_server != null && (this.lan || !lan)) return;
    final old = _server;
    // Moving to the network: the same port, so scripts already connected stay.
    if (old != null) {
      port = old.port;
      await old.close();
    }
    final at = lan ? InternetAddress.anyIPv4 : InternetAddress.loopbackIPv4;
    try {
      _server = await HttpServer.bind(at, port);
    } on SocketException {
      _server = await HttpServer.bind(at, 0);
    }
    this.lan = lan;
    _server!.listen(_onRequest, onError: (_) {});
    if (discovery != null) {
      await discovery.parent.create(recursive: true);
      await discovery.writeAsString(
        jsonEncode({'url': 'ws://127.0.0.1:${_server!.port}/scripts', 'mcp': 'http://127.0.0.1:${_server!.port}/mcp', 'token': token, 'pid': pid, 'app': appVersion}),
      );
    }
  }

  Future<void> stop() async {
    for (final c in List.of(conns)) {
      await c.ws.close();
    }
    await _server?.close(force: true);
    _server = null;
  }

  /// `~/.koebelt/dash-api.json`, where koebelt_dash_scripts looks for dash.
  static File defaultDiscovery() {
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '.';
    return File('$home/.koebelt/dash-api.json');
  }

  Future<void> _onRequest(HttpRequest req) async {
    if (req.uri.path == '/mcp') return d.mcp.handle(req);
    if (req.uri.path != '/scripts' || !WebSocketTransformer.isUpgradeRequest(req)) {
      req.response.statusCode = HttpStatus.notFound;
      await req.response.close();
      return;
    }
    final ws = await WebSocketTransformer.upgrade(req);
    ScriptConn? c;
    ws.listen(
      (data) {
        if (data is! String) return;
        final Map<String, dynamic> m;
        try {
          m = (jsonDecode(data) as Map).cast<String, dynamic>();
        } catch (_) {
          return;
        }
        if (c == null) {
          // From the network, only a run's own token: the main one is for
          // scripts started by hand on this computer.
          final local = req.connectionInfo?.remoteAddress.isLoopback ?? false;
          final run = runs.where((r) => r.token == m['token'] && r.state == ScriptState.running).firstOrNull;
          if (m['t'] != 'hello' || (run == null && (m['token'] != token || !local))) {
            ws.add(jsonEncode({'t': 'bye', 'why': 'Wrong or missing token.'}));
            ws.close();
            return;
          }
          c = ScriptConn(this, ws, (m['name'] as String?) ?? 'script')..pid = (m['pid'] as num?)?.toInt();
          c!.run = run;
          c!.config = configFor(c!.configKey);
          c!.lastSeen = d.t;
          conns.add(c!);
          c!.log('info', 'Connected');
          c!.send({'t': 'welcome', 'v': scriptApiVersion, 'app': appVersion, 'devices': _devices()});
          d.emit();
          return;
        }
        c!.lastSeen = d.t;
        _onMsg(c!, m);
      },
      onDone: () {
        if (c != null) _gone(c!, 'The script ended.');
      },
      onError: (_) {},
    );
  }

  List<Map<String, dynamic>> _devices() => [
    for (final l in d.links.values) {'id': l.id, 'name': l.info.name, 'kind': l.kind.name, 'sim': l.info.simulated, 'focus': l.id == d.deviceId},
  ];

  DeviceLink? _link(ScriptConn c) => c.device == null ? null : d.links[c.device];

  /// The view [name] on [l], made the first time (a new Live widget).
  ScriptView _view(DeviceLink l, ScriptConn c, String name, String kind) {
    final v = l.views[name];
    if (v != null) return v;
    final made = l.views[name] = ScriptView(name, kind, c.name);
    d.emit();
    return made;
  }

  void _gone(ScriptConn c, String why) {
    if (!conns.remove(c)) return;
    _release(c, why);
    for (final l in d.links.values) {
      for (final v in l.views.values) {
        if (v.script == c.name && !conns.any((o) => o.name == c.name)) v.end();
      }
    }
    d.emit();
  }

  /// Takes the sticks back from a script; a device it drove holds. Unless the
  /// script asked for it, it stays [ScriptConn.blocked] until the operator
  /// resumes it.
  void _release(ScriptConn c, String why, {bool block = true}) {
    final dr = c.drive;
    if (dr == null) return;
    c.drive = null;
    if (block) c.blocked = why;
    if (dr.link.drive == dr) {
      dr.link.drive = null;
      final t = dr.link.tel;
      if (t.armed && !t.estop && dr.link.kind != DeviceKind.arm && dr.link.kind != DeviceKind.bench) {
        d.linkHost(dr.link).seqSetMode('HOLD');
      }
    }
    c.log('warn', why);
    c.send({'t': 'released', 'why': why});
  }

  /// A result; a refusal carries a code (protocol/SCRIPTS.md, Errors) and
  /// what a script needs to explain it (the names it could have used…).
  void _res(ScriptConn c, Object? id, {String? err, String? code, Map<String, Object?>? data, Object? value}) =>
      c.send({'t': 'res', 'id': id, 'ok': err == null, 'err': ?err, 'code': ?code, 'data': ?data, 'value': ?value});

  void _onMsg(ScriptConn c, Map<String, dynamic> m) {
    final id = m['id'];
    try {
      switch (m['t']) {
        case 'ka':
          c.hz = (m['hz'] as num?)?.toDouble() ?? c.hz;
          return;
        case 'use':
          final want = m['device'] as String?;
          DeviceLink? named(String n) => d.links.values.where((x) => x.id == n || x.info.name.toLowerCase() == n.toLowerCase()).firstOrNull;
          // No name: the device chosen on the script's page, else the selected one.
          final l = want != null ? named(want) : (c.config.device == null ? null : named(c.config.device!)) ?? d.focus;
          if (l == null) {
            final names = [for (final x in d.links.values) x.info.name];
            return want == null
                ? _res(c, id, err: 'No device is connected in koebelt dash.', code: 'E0001')
                : _res(c, id, err: 'No connected device called "$want".', code: 'E0002', data: {'name': want, 'names': names});
          }
          // What the script needs: its # requires: lines, and connect(requires=…).
          final source = c.run?.file.existsSync() ?? false ? c.run!.file.readAsStringSync() : '';
          final req = ScriptRequirements.parse(source, extra: [for (final r in (m['requires'] as List?) ?? const []) '$r']);
          final missing = req.missing(l.info, l);
          if (missing.isNotEmpty) {
            return _res(
              c,
              id,
              err: '${l.info.name} cannot run this script: it needs ${req.describe()}; it lacks ${missing.join(', ')}.',
              code: 'E0004',
              data: {'device': l.info.name, 'needs': req.describe(), 'missing': missing},
            );
          }
          if (c.device != l.id) _release(c, 'Switched device.', block: false);
          c.device = l.id;
          return _res(
            c,
            id,
            value: {
              'id': l.id,
              'name': l.info.name,
              'kind': l.kind.name,
              'sim': l.info.simulated,
              'lib': l.info.lib,
              'limits': c.limits.toJson(),
              'cameras': [
                // Absolute, as dash reaches them (a device may give a path on its own address).
                for (final v in l.video) {'id': v.id, 'url': resolveVideoUrl(v.url, l.info)?.toString(), 'fmt': v.fmt, 'label': v.label},
              ],
              'steps': [for (final s in stepDefs(l.kind)) s.type],
            },
          );
        case 'sticks':
          final l = _link(c);
          if (l == null) return _res(c, id, err: 'Call use() first.', code: 'E0003');
          if (l.tel.estop) return _res(c, id, err: 'STOP is on: the operator must clear it.', code: 'E0101');
          if (c.blocked != null) return _res(c, id, err: '${c.blocked} The operator must resume the script in dash.', code: 'E0102', data: {'why': c.blocked});
          final other = l.drive;
          if (other != null && other.conn != c) {
            return _res(c, id, err: 'Another script (${other.conn.name}) drives ${l.info.name}.', code: 'E0103', data: {'other': other.conn.name, 'device': l.info.name});
          }
          final dr = c.drive ??= ScriptDrive(c, l);
          l.drive = dr;
          dr.sticks.setAll(0, sticksFor(l.kind, (m['a'] as Map?) ?? const {}, dr.sticks));
          if (id != null) _res(c, id);
          return;
        case 'release':
          _release(c, 'Released by the script.', block: false);
          return _res(c, id);
        case 'cmd':
          return _cmd(c, id, m['c'] as String? ?? '', (m['a'] as Map?)?.cast<String, dynamic>() ?? const {});
        case 'setting':
          final name = m['name'] as String;
          final prev = c.settings[name];
          c.settings[name] = {...?prev, ...m, 'value': prev?['value'] ?? m['value']};
          d.emit();
          return _res(c, id, value: c.settings[name]!['value']);
        case 'trigger':
          c.triggers[m['name'] as String] = m;
          if (c.config.adopt(m)) saveConfigs();
          d.emit();
          return _res(c, id);
        case 'print':
          c.log((m['level'] as String?) ?? 'out', '${m['text']}');
          d.emit();
          return;
        case 'plot':
          // One value, or several series: v [..], labels [..]. They go
          // through telemetry, so Live draws them over time and recordings
          // keep them.
          final l = _link(c);
          if (l == null) return;
          final name = '${m['name']}', v = m['v'];
          l.tel.custom['script:$name'] = v is List ? [for (final x in v) (x as num?)?.toDouble() ?? double.nan] : [(v as num).toDouble()];
          final labels = m['labels'] is List ? [for (final x in m['labels'] as List) '$x'] : [name];
          _view(l, c, name, 'plot').plotFrom(labels, c.name);
          return;
        case 'view':
          // A picture (base64 JPEG or PNG) or a whole chart, shown as a Live widget.
          final l = _link(c);
          if (l == null) return;
          final view = _view(l, c, '${m['name']}', m['kind'] == 'chart' ? 'chart' : 'picture');
          m['kind'] == 'chart' ? view.chartFrom(m, c.name) : view.picture(m, c.name);
          return;
        case 'overlay':
          final l = _link(c);
          if (l == null) return;
          double n(Object? v) => (v as num?)?.toDouble() ?? 0;
          l.overlay = (
            boxes: [
              for (final b in (m['boxes'] as List? ?? const []).whereType<List>().take(100))
                if (b.length >= 4) (x: n(b[0]), y: n(b[1]), w: n(b[2]), h: n(b[3]), label: b.length > 4 ? '${b[4]}' : ''),
            ],
            at: DateTime.now(),
          );
          return;
        case 'mark':
          final l = _link(c);
          if (l != null) d.scriptEvent(l, '${m['text']}');
          return _res(c, id);
        case 'notify':
          c.log((m['level'] as String?) ?? 'info', '${m['text']}');
          d.emit();
          return _res(c, id);
        default:
          return _res(c, id, err: 'Unknown message "${m['t']}".', code: 'E0901', data: {'message': m['t']});
      }
    } catch (e) {
      if (e is ScriptRefusal) return _res(c, id, err: e.message, code: e.code, data: e.data);
      _res(c, id, err: e is ArgumentError ? '${e.message}' : '$e', code: 'E0900');
    }
  }

  void _cmd(ScriptConn c, Object? id, String cmd, Map<String, dynamic> a) {
    if (cmd == 'stop') {
      d.emergencyStop();
      return _res(c, id);
    }
    final l = _link(c);
    if (l == null) return _res(c, id, err: 'Call use() first.', code: 'E0003');
    if (l.tel.estop) return _res(c, id, err: 'STOP is on: the operator must clear it.', code: 'E0101');
    final h = d.linkHost(l), lim = c.limits;
    switch (cmd) {
      case 'mode':
        final mode = '${a['m']}'.toUpperCase();
        if (mode == 'TAKEOFF' && !lim.allowArm) return _res(c, id, err: 'Take-off is not allowed for this script (Limits in dash).', code: 'E0301');
        h.seqSetMode(mode);
      case 'arm':
        if (!lim.allowArm) return _res(c, id, err: 'Arming is not allowed for this script (Limits in dash).', code: 'E0301');
        h.seqSetArmed(a['v'] != false);
      case 'disarm':
        h.seqSetArmed(false);
      case 'speed':
        final v = (a['v'] as num).toDouble().clamp(.1, 1.0);
        h.seqSetSpeed(math.min(v, lim.maxSpeed));
      case 'params':
        return _res(c, id, value: d.paramDev[l.id] ?? const {});
      case 'step':
        return _step(c, id, l, a);
      case 'program':
        final name = '${a['name']}';
        final q = d.sequencesFor(l.id).where((x) => x.name.toLowerCase() == name.toLowerCase() || x.id == name).firstOrNull;
        if (q == null) {
          final names = [for (final x in d.sequencesFor(l.id)) x.name];
          return _res(c, id, err: 'No sequence called "$name" on ${l.info.name} (${names.join(', ')}).', code: 'E0402', data: {'name': name, 'names': names, 'device': l.info.name});
        }
        if (q.steps.any((st) => st.type == 'takeoff' || st.type == 'arm') && !lim.allowArm) {
          return _res(c, id, err: '"${q.name}" arms or takes off, which is not allowed for this script (Limits in dash).', code: 'E0301');
        }
        return _start(c, id, l, q, wait: a['wait'] != false);
      case 'seqctl':
        final r = l.runner;
        if (r == null) return _res(c, id, err: 'Nothing is running on ${l.info.name}.', code: 'E0406');
        // On-device runners pass these on to the device.
        switch (a['c']) {
          case 'pause':
            r.pause();
          case 'resume':
            r.resume();
          default:
            r.stop('Stopped by the script');
        }
        d.emit();
      case 'pset':
        if (!lim.allowParams) return _res(c, id, err: 'Parameter writes are not allowed for this script (Limits in dash).', code: 'E0302');
        d.sendTo(l, {'t': 'pset', 'p': a});
      case 'psave':
        if (!lim.allowParams) return _res(c, id, err: 'Parameter writes are not allowed for this script (Limits in dash).', code: 'E0302');
        d.sendTo(l, {'t': 'psave'});
      default:
        // Kind-specific commands (release, countdown, sethome…).
        h.seqCmd(cmd, a);
    }
    _res(c, id);
  }

  var _seqN = 0;

  /// One step (take off, go to, land…), run like a one-step sequence so it
  /// behaves exactly as in a sequence. The result comes when it is done.
  void _step(ScriptConn c, Object? id, DeviceLink l, Map<String, dynamic> a) {
    final type = '${a['type']}';
    final def = stepDef(l.kind, type);
    if (def == null) {
      final names = [for (final s in stepDefs(l.kind)) s.type];
      return _res(c, id, err: '"$type" is not a step a ${l.kind.name} has (${names.join(', ')}).', code: 'E0401', data: {'name': type, 'names': names, 'kind': l.kind.name});
    }
    final lim = c.limits;
    if ((type == 'takeoff' || type == 'arm') && !lim.allowArm) return _res(c, id, err: 'Take-off and arming are not allowed for this script (Limits in dash).', code: 'E0301');
    double n(String k) => (a[k] as num?)?.toDouble() ?? 0;
    if (type == 'goto') {
      final dist = math.sqrt(n('x') * n('x') + n('y') * n('y'));
      if (lim.fence > 0 && dist > lim.fence) {
        return _res(c, id, err: 'That is ${dist.round()} m from home, beyond the ${lim.fence.round()} m geofence.', code: 'E0303', data: {'distance': dist, 'fence': lim.fence});
      }
      if (lim.ceiling > 0 && l.kind == DeviceKind.drone && n('z') > lim.ceiling) {
        return _res(c, id, err: '${n('z')} m is above the ${lim.ceiling.round()} m ceiling.', code: 'E0304', data: {'height': n('z'), 'ceiling': lim.ceiling});
      }
    }
    if (type == 'takeoff' && lim.ceiling > 0 && n('alt') > lim.ceiling) {
      return _res(c, id, err: '${n('alt')} m is above the ${lim.ceiling.round()} m ceiling.', code: 'E0304', data: {'height': n('alt'), 'ceiling': lim.ceiling});
    }
    final st = SeqStep.fresh(def);
    for (final e in a.entries) {
      if (e.key != 'type' && e.key != 'wait' && st.p.containsKey(e.key)) st.p[e.key] = e.value;
    }
    final q = Sequence(id: 'script-${++_seqN}', name: '${c.name}: ${def.label}', kind: l.kind, steps: [st]);
    _start(c, id, l, q, wait: a['wait'] != false);
  }

  void _start(ScriptConn c, Object? id, DeviceLink l, Sequence q, {required bool wait}) {
    final busy = l.runner;
    if (busy != null && (busy.state == RunState.running || busy.state == RunState.paused)) {
      return _res(c, id, err: '"${busy.seq.name}" is running on ${l.info.name}: stop it first.', code: 'E0403', data: {'running': busy.seq.name});
    }
    d.runSequenceOn(l, q);
    if (l.runner?.seq != q) return _res(c, id, err: '${l.info.name} cannot run it now.', code: 'E0404');
    if (!wait || id == null) return _res(c, id);
    c.pending[id] = (link: l, seq: q.id);
  }

  /// Answers the steps and sequences scripts wait on, once they end.
  void _settle(ScriptConn c) {
    for (final e in c.pending.entries.toList()) {
      final l = e.value.link, r = l.runner;
      String? err;
      if (!d.links.containsKey(l.id)) {
        err = '${l.info.name} disconnected.';
      } else if (r == null || r.seq.id != e.value.seq) {
        err = 'Interrupted: another sequence started.';
      } else if (r.state == RunState.failed) {
        err = r.message.isEmpty ? 'The step failed.' : r.message;
      } else if (r.state != RunState.done) {
        continue;
      }
      c.pending.remove(e.key);
      _res(c, e.key, err: err, code: err == null ? null : 'E0405');
    }
  }

  /// The operator moved the sticks while a script drove.
  void takeover(ScriptDrive dr) {
    dr.conn.log('warn', 'Operator took over ${dr.link.info.name}');
    dr.conn.send({'t': 'takeover', 'on': true});
    d.emit();
  }

  /// Gives the sticks back to the script after a takeover.
  void resume(DeviceLink l) {
    final dr = l.drive;
    if (dr == null || !dr.paused) return;
    dr.paused = false;
    dr.conn.log('info', 'Control resumed');
    dr.conn.send({'t': 'takeover', 'on': false});
    d.emit();
  }

  /// Lets a script drive again after dash took the sticks away.
  void unblock(ScriptConn c) {
    if (c.blocked == null) return;
    c.blocked = null;
    c.log('info', 'Resumed by the operator');
    c.send({'t': 'resumed'});
    d.emit();
  }

  /// STOP: every script loses its device; scripts dash started are ended.
  void onStop() {
    for (final c in List.of(conns)) {
      _release(c, 'STOP');
      c.send({'t': 'stop'});
    }
    for (final r in runs) {
      if (r.state == ScriptState.running) {
        r.log('warn', 'STOP');
        r.stop(grace: const Duration(milliseconds: 300));
      }
    }
  }

  /// Runs a script file on this computer. The interpreter: [python], else the
  /// one the script names in its first lines (`# python: …`), else [fallback].
  Future<ScriptRun> runFile(File file, {String? python, String fallback = 'python3'}) async {
    if (_server == null) throw StateError('The script API is not running.');
    final py = python ?? pythonFromHeader(await file.readAsString()) ?? fallback;
    final r = await LocalRun.start(file, py, url: 'ws://127.0.0.1:${_server!.port}/scripts', token: _newToken(), onChange: d.emit);
    _track(r);
    return r;
  }

  /// Runs a script on a script host; it connects back over the network.
  Future<ScriptRun> runOnHost(File file, ScriptHost host) async {
    await start(lan: true);
    final r = await RemoteRun.start(file, host, dashPort: _server!.port, token: _newToken(), onChange: d.emit);
    _track(r);
    return r;
  }

  void _track(ScriptRun r) {
    runs.add(r);
    if (runs.length > 20) runs.removeAt(0);
    d.emit();
  }

  /// The connection of a script dash started, once it has connected.
  ScriptConn? connOf(ScriptRun r) => conns.where((c) => c.run == r).firstOrNull;

  /// A trigger fired by the operator or a condition.
  void fire(ScriptConn c, String name, [Object? value]) {
    c.log('trig', 'Trigger "$name"');
    c.send({'t': 'fire', 'name': name, 'value': ?value});
    d.emit();
  }

  /// The operator pressed a button, or a key or controller button bound to an
  /// event: switches toggle, sliders send their value, buttons fire.
  void press(ScriptConn c, String event) {
    final decl = c.triggers[event];
    final kind = '${decl?['kind'] ?? c.config.bindings.where((b) => b.event == event && b.onScreen).firstOrNull?.source.name ?? 'button'}';
    if (kind == 'switch' || kind == 'toggle') {
      final v = !(c.config.values[event] == true);
      c.config.values[event] = v;
      return fire(c, event, v);
    }
    if (kind == 'value' || kind == 'slider') return fire(c, event, c.config.values[event]);
    fire(c, event);
  }

  void setToggle(ScriptConn c, String event, bool v) {
    c.config.values[event] = v;
    fire(c, event, v);
  }

  void setSlider(ScriptConn c, String event, double v) {
    c.config.values[event] = v;
    fire(c, event, v);
  }

  /// A key pressed in dash (outside text fields). True if a trigger took it.
  bool onKey(String label) {
    var used = false;
    for (final c in List.of(conns)) {
      for (final b in c.config.bindings.where((b) => b.source == TriggerSource.key && b.key == label).toList()) {
        press(c, b.event);
        used = true;
      }
    }
    return used;
  }

  /// A controller button no built-in action uses.
  void onPad(String src) {
    for (final c in List.of(conns)) {
      for (final b in c.config.bindings.where((b) => b.source == TriggerSource.pad && b.pad == src).toList()) {
        press(c, b.event);
      }
    }
  }

  /// Conditions, device events and timers, 10 times a second.
  void _stepTriggers(ScriptConn c, double dt) {
    final l = _link(c);
    final st = c.triggerState;
    if (l == null) return;
    final t = l.tel, lost = l.linkLostFor > 0;
    final lookup = fieldsOf(l);
    for (final b in c.config.bindings.toList()) {
      switch (b.source) {
        case TriggerSource.condition:
          final r = st.watch(b)?.step(dt, lookup);
          if (r == true) fire(c, b.event, true);
          if (r == false && b.both) fire(c, b.event, false);
        case TriggerSource.timer:
          final acc = (st.timers[b] ?? 0) + dt;
          st.timers[b] = acc;
          if (acc >= b.seconds && b.seconds > 0) {
            if (b.repeat) {
              st.timers[b] = acc - b.seconds;
              fire(c, b.event);
            } else if (acc - dt < b.seconds) {
              fire(c, b.event);
            }
          }
        case TriggerSource.event:
          final m = b.match?.trim() ?? '';
          final hit = switch (b.deviceEvent) {
            'mode' => st.lastMode != null && st.lastMode != t.mode && (m.isEmpty || t.mode.toUpperCase() == m.toUpperCase()),
            'armed' => st.lastArmed == false && t.armed,
            'disarmed' => st.lastArmed == true && !t.armed,
            'failsafe' => st.lastFailsafe == false && t.failsafe,
            'linklost' => st.lastLost == false && lost,
            'seqdone' => st.lastRun != null && st.lastRun != l.runner?.state && '${l.runner?.state.name}' == 'done',
            'log' => l.logs.length > st.logsSeen && l.logs.skip(st.logsSeen).any((x) => m.isEmpty || '${x['msg']}'.toLowerCase().contains(m.toLowerCase())),
            _ => false,
          };
          if (hit) fire(c, b.event, b.deviceEvent == 'mode' ? t.mode : null);
        default:
      }
    }
    st.lastMode = t.mode;
    st.lastArmed = t.armed;
    st.lastFailsafe = t.failsafe;
    st.lastLost = lost;
    st.lastRun = l.runner?.state;
    st.logsSeen = l.logs.length;
  }

  /// A setting changed in dash.
  void setSetting(ScriptConn c, String name, Object value) {
    c.settings[name]?['value'] = value;
    c.send({'t': 'setting', 'name': name, 'value': value});
    d.emit();
  }

  void tick(double dt) {
    if (conns.isEmpty) return;
    for (final c in List.of(conns)) {
      if (c.pending.isNotEmpty) _settle(c);
      final dr = c.drive;
      if (dr == null) continue;
      if (!d.links.containsKey(dr.link.id)) {
        _release(c, '${dr.link.info.name} disconnected.');
        continue;
      }
      if (d.t - c.lastSeen > watchdog) {
        _release(c, 'The script stopped responding: ${dr.link.info.name} holds.');
        continue;
      }
      final p = dr.link.tel.pos, lim = c.limits;
      if (lim.fence > 0 && math.sqrt(p[0] * p[0] + p[1] * p[1]) > lim.fence) {
        _release(c, '${dr.link.info.name} left the ${lim.fence.round()} m geofence: it holds.');
      } else if (lim.ceiling > 0 && dr.link.kind == DeviceKind.drone && p[2] > lim.ceiling) {
        _release(c, '${dr.link.info.name} went above the ${lim.ceiling.round()} m ceiling: it holds.');
      }
    }
    _trigAcc += dt;
    if (_trigAcc >= .1) {
      for (final c in List.of(conns)) {
        _stepTriggers(c, _trigAcc);
      }
      _trigAcc = 0;
    }
    _tlmAcc += dt;
    if (_tlmAcc < .05) return;
    _tlmAcc = 0;
    for (final c in conns) {
      final l = _link(c);
      if (l == null) continue;
      final t = l.tel;
      c.send({
        't': 'tlm',
        'd': {
          ...t.snapshot()..remove('seen'),
          'speed': math.sqrt(t.vel[0] * t.vel[0] + t.vel[1] * t.vel[1] + t.vel[2] * t.vel[2]),
          'heading': t.heading,
          'estop': t.estop,
          'failsafe': t.failsafe,
          'latency': l.session.latency,
          'drive': c.drive == null ? 'none' : (c.drive!.paused ? 'operator' : 'script'),
        },
      });
    }
  }

  void dispose() {
    hostService?.kill();
    for (final r in runs) {
      r.stop(grace: Duration.zero);
    }
    stop();
  }
}
