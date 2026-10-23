import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../core/dash.dart';
import '../core/device_link.dart';
import '../core/export.dart';
import '../core/sequence.dart';
import '../link/protocol.dart';
import '../scripts/conditions.dart';
import '../scripts/library.dart';
import '../scripts/script_hub.dart';
import '../scripts/script_runner.dart';
import '../scripts/triggers.dart';
import 'docs.dart';

/// An action on real hardware waiting for the operator.
class Approval {
  Approval({required this.client, required this.title, required this.detail, required this.device, required this.cls, this.always = false});
  final String client, title, detail, device;

  /// The kind of action, for "allow for this session" (`script:<device>`…).
  final String cls;

  /// Arming and take-off: always asked.
  final bool always;
  final DateTime at = DateTime.now();
  final done = Completer<String>();
}

class McpSession {
  McpSession(this.id, this.client);
  final String id, client;
  DateTime seen = DateTime.now();
  int actions = 0;
}

typedef McpEntry = ({DateTime at, String client, String tool, String summary, bool ok});

class McpError implements Exception {
  McpError(this.message);
  final String message;
  @override
  String toString() => message;
}

/// The MCP server inside koebelt dash: AI assistants (Claude, Cursor, any MCP
/// client) read the docs, look at devices and recordings, write and run
/// scripts, use the app, and act on hardware with the operator's approval.
/// Streamable HTTP on /mcp of the script API's server (docs/design/scripts.md).
class McpServer {
  McpServer(this.d);
  final Dash d;

  /// Off until the operator turns it on (Settings > AI assistants).
  bool enabled = false;

  /// Whether assistants on other computers may connect (with [lanToken]).
  bool lan = false;
  String lanToken = _token();
  final Map<String, McpSession> sessions = {};
  final List<Approval> approvals = [];

  /// Kinds of action the operator allowed for the rest of this session.
  final Set<String> allowed = {};
  final List<McpEntry> activity = [];

  /// The whole app, for screenshots.
  final screenKey = GlobalKey();

  /// Shows a screen (set by the shell).
  void Function(String screen)? onOpen;

  /// The scripts folder (tests use their own).
  ScriptLibrary? library;

  /// What needs the operator's approval: real hardware (tests change it).
  bool Function(DeviceLink l) isReal = (l) => !l.info.simulated;
  List<Doc>? _docs;

  static const approvalTimeout = Duration(seconds: 30);
  static const _prefs = 'kdash-mcp-v1';
  static const versions = ['2025-11-25', '2025-06-18', '2025-03-26', '2024-11-05'];

  static String _token() {
    final r = math.Random.secure();
    return [for (var i = 0; i < 24; i++) r.nextInt(256).toRadixString(16).padLeft(2, '0')].join();
  }

  void load() {
    final j = d.store.readJson(_prefs);
    if (j is Map) {
      enabled = j['enabled'] == true;
      lan = j['lan'] == true;
      if (j['token'] is String) lanToken = j['token'] as String;
    }
  }

  void save() => d.store.writeJson(_prefs, {'enabled': enabled, 'lan': lan, 'token': lanToken});

  /// The assistant connected in the last ten minutes, if any.
  McpSession? get connected {
    final recent = sessions.values.where((s) => DateTime.now().difference(s.seen) < const Duration(minutes: 10)).toList()
      ..sort((a, b) => b.seen.compareTo(a.seen));
    return recent.firstOrNull;
  }

  void disconnectAll() {
    sessions.clear();
    for (final a in List.of(approvals)) {
      _answer(a, 'refused');
    }
    d.emit();
  }

  Future<ScriptLibrary> _lib() async => library ??= ScriptLibrary(await ScriptLibrary.defaultDir());

  // ------------------------------------------------------------------ HTTP
  Future<void> handle(HttpRequest req) async {
    final res = req.response;
    Future<void> fail(int status, String text) async {
      res.statusCode = status;
      res.headers.contentType = ContentType.json;
      res.write(jsonEncode({'jsonrpc': '2.0', 'id': null, 'error': {'code': -32000, 'message': text}}));
      await res.close();
    }

    // Browsers may not reach it (DNS rebinding): only no Origin, or a local one.
    final origin = req.headers.value('origin');
    if (origin != null && !RegExp(r'^https?://(localhost|127\.0\.0\.1|\[::1\])(:\d+)?$').hasMatch(origin)) {
      return fail(HttpStatus.forbidden, 'Origin not allowed.');
    }
    final local = req.connectionInfo?.remoteAddress.isLoopback ?? false;
    if (!local && (!lan || req.headers.value('authorization') != 'Bearer $lanToken')) {
      return fail(HttpStatus.unauthorized, 'Assistants on other computers need "From this network" on and its token (Settings > AI assistants).');
    }
    if (!enabled) return fail(HttpStatus.serviceUnavailable, 'AI assistants are off in koebelt dash: Settings > AI assistants.');
    if (req.method == 'DELETE') {
      sessions.remove(req.headers.value('mcp-session-id'));
      d.emit();
      res.statusCode = HttpStatus.ok;
      return res.close();
    }
    if (req.method != 'POST') {
      res.statusCode = HttpStatus.methodNotAllowed;
      res.headers.set('allow', 'POST, DELETE');
      return res.close();
    }
    final Object? body;
    try {
      body = jsonDecode(await utf8.decoder.bind(req).join());
    } catch (_) {
      return fail(HttpStatus.badRequest, 'Not JSON.');
    }
    final sid = req.headers.value('mcp-session-id');
    final msgs = body is List ? body : [body];
    final out = <Map<String, dynamic>>[];
    String? newSession;
    for (final m in msgs) {
      if (m is! Map || m['jsonrpc'] != '2.0') continue;
      final id = m['id'], method = '${m['method']}';
      if (method == 'initialize') {
        final client = '${((m['params'] as Map?)?['clientInfo'] as Map?)?['name'] ?? 'An assistant'}';
        final s = McpSession(_token().substring(0, 32), _clientLabel(client));
        sessions[s.id] = s;
        newSession = s.id;
        d.emit();
      }
      final session = sessions[newSession ?? sid];
      session?.seen = DateTime.now();
      if (id == null) continue; // a notification
      try {
        out.add({'jsonrpc': '2.0', 'id': id, 'result': await _request(method, (m['params'] as Map?)?.cast<String, dynamic>() ?? const {}, session)});
      } on McpError catch (e) {
        out.add({
          'jsonrpc': '2.0',
          'id': id,
          'error': {'code': -32602, 'message': e.message},
        });
      } catch (e) {
        out.add({
          'jsonrpc': '2.0',
          'id': id,
          'error': {'code': -32603, 'message': '$e'},
        });
      }
    }
    if (newSession != null) res.headers.set('mcp-session-id', newSession);
    if (out.isEmpty) {
      res.statusCode = HttpStatus.accepted;
      return res.close();
    }
    res.headers.contentType = ContentType.json;
    res.write(jsonEncode(body is List ? out : out.single));
    await res.close();
  }

  static String _clientLabel(String n) {
    final l = n.toLowerCase();
    if (l.contains('claude-code') || l.contains('claude code')) return 'Claude Code';
    if (l.contains('claude')) return 'Claude';
    if (l.contains('cursor')) return 'Cursor';
    if (l.contains('codex')) return 'Codex';
    if (l.contains('opencode')) return 'OpenCode';
    return n;
  }

  Future<Object?> _request(String method, Map<String, dynamic> p, McpSession? s) async {
    switch (method) {
      case 'initialize':
        final want = '${p['protocolVersion'] ?? versions.first}';
        return {
          'protocolVersion': versions.contains(want) ? want : versions.first,
          'capabilities': {
            'tools': {'listChanged': false},
            'resources': {'listChanged': false},
            'prompts': {'listChanged': false},
          },
          'serverInfo': {'name': 'koebelt-dash', 'title': 'koebelt dash', 'version': appVersion},
          'instructions': _instructions,
        };
      case 'ping':
        return {};
      case 'tools/list':
        return {'tools': _tools};
      case 'tools/call':
        return _call('${p['name']}', (p['arguments'] as Map?)?.cast<String, dynamic>() ?? const {}, s);
      case 'resources/list':
        final docs = await _allDocs();
        return {
          'resources': [
            for (final x in docs) {'uri': 'koebelt://docs/${x.id}', 'name': x.id, 'title': x.title, 'mimeType': x.id.startsWith('example:') ? 'text/x-python' : 'text/markdown'},
          ],
        };
      case 'resources/read':
        final uri = '${p['uri']}';
        final doc = (await _allDocs()).where((x) => 'koebelt://docs/${x.id}' == uri).firstOrNull;
        if (doc == null) throw McpError('No resource $uri');
        return {
          'contents': [
            {'uri': uri, 'mimeType': doc.id.startsWith('example:') ? 'text/x-python' : 'text/markdown', 'text': doc.text},
          ],
        };
      case 'prompts/list':
        return {
          'prompts': [
            for (final e in _prompts.entries) {'name': e.key, 'title': e.value.$1, 'description': e.value.$2, 'arguments': e.value.$3},
          ],
        };
      case 'prompts/get':
        final pr = _prompts['${p['name']}'];
        if (pr == null) throw McpError('No prompt ${p['name']}');
        final args = (p['arguments'] as Map?)?.cast<String, dynamic>() ?? const {};
        return {
          'description': pr.$2,
          'messages': [
            {
              'role': 'user',
              'content': {'type': 'text', 'text': pr.$4(args)},
            },
          ],
        };
      default:
        throw McpError('Unknown method $method');
    }
  }

  Future<List<Doc>> _allDocs() async => _docs ??= await loadDocs(rootBundle);

  static const _instructions =
      'koebelt dash is a ground station for drones, rovers, robot arms, rockets and test benches that makers build with the koebelt/link libraries. '
      'Use search_docs and read_doc to learn its guides and APIs before writing code. Scripts are Python files using koebelt-dash-scripts '
      '(ref:scripts-api); write them with write_script, check them with check_script, and test them on a simulated device first '
      '(add_simulated_device). Actions on real hardware wait for the operator to approve them in dash; simulated devices never ask. '
      'stop is always available. Positions are metres from home, x east, y north.';

  static final _prompts = <String, (String, String, List<Map<String, dynamic>>, String Function(Map<String, dynamic>))>{
    'write_script': (
      'Write a script for my device',
      'Write, check and test a koebelt dash script for a task.',
      [
        {'name': 'task', 'description': 'What the script should do', 'required': true},
      ],
      (a) =>
          'Write a koebelt dash script that does this: ${a['task']}. First read ref:scripts-api and one or two examples with read_doc, '
          'and look at the connected devices with list_devices. Write it with write_script, check it with check_script, '
          'then run it on a simulated device of the same kind and read script_output until it works. Ask me before running it on real hardware.',
    ),
    'explain_recording': (
      'Explain a recording',
      'Look into a recorded session and explain what happened.',
      [
        {'name': 'recording', 'description': 'Its name, or "latest"', 'required': false},
        {'name': 'question', 'description': 'What to look at', 'required': false},
      ],
      (a) =>
          'Look at the recording ${a['recording'] ?? 'latest'} with list_recordings and get_recording (summary first, then excerpts around interesting moments). '
          '${a['question'] ?? 'Explain what happened, and anything that looks wrong.'}',
    ),
    'tune_parameter': (
      'Help me tune a parameter',
      'Look at telemetry and parameters, and suggest changes.',
      [
        {'name': 'goal', 'description': 'What should behave better', 'required': true},
      ],
      (a) =>
          'Goal: ${a['goal']}. Read the parameters with get_params, the live behaviour with get_telemetry and get_history, and recent recordings. '
          'Explain what to change and why, one parameter at a time. Only write parameters with set_params after I agree.',
    ),
    'new_device': (
      'Set up a new device',
      'Guide me through connecting a new device with koebelt/link.',
      [
        {'name': 'device', 'description': 'The board and what it is (ESP32 rover, Raspberry Pi arm…)', 'required': true},
      ],
      (a) => 'I want to connect this to koebelt dash: ${a['device']}. Use search_docs and read_doc on the guides to give me the steps and the code for my board.',
    ),
  };

  // ------------------------------------------------------------------ tools
  static Map<String, dynamic> _tool(String name, String title, String description, Map<String, dynamic> props, {List<String> required = const [], bool readOnly = false, bool destructive = false}) => {
    'name': name,
    'title': title,
    'description': description,
    'inputSchema': {'type': 'object', 'properties': props, if (required.isNotEmpty) 'required': required},
    'annotations': {'readOnlyHint': readOnly, if (!readOnly) 'destructiveHint': destructive},
  };

  static const _dev = {'type': 'string', 'description': 'Device name; the one selected in dash if omitted'};
  static const _str = {'type': 'string'};
  static const _num = {'type': 'number'};

  static final _tools = [
    // Learn
    _tool('search_docs', 'Search the docs', 'Search the guides, the koebelt/link and script API references and the example scripts.', {'query': _str}, required: ['query'], readOnly: true),
    _tool('read_doc', 'Read a doc', 'Read a whole guide, reference or example by id (from search_docs or resources). id "index" lists them all.', {'id': _str}, required: ['id'], readOnly: true),
    // Look
    _tool('list_devices', 'List devices', 'Paired and connected devices: name, kind, connection, mode, armed, simulated, library.', {}, readOnly: true),
    _tool('get_telemetry', 'Get telemetry', 'Latest telemetry of a device: position (m from home), attitude, speed, mode, battery, sensors, link.', {'device': _dev}, readOnly: true),
    _tool('get_history', 'Get recent history', 'The last 10 seconds of a channel (alt, spd, volt, cur, ax, gz, j0…, custom channels), downsampled. Omit channel to list them.', {'device': _dev, 'channel': _str}, readOnly: true),
    _tool('get_camera_frame', 'Get a camera frame', 'The current picture from the device\'s camera.', {'device': _dev}, readOnly: true),
    _tool('get_params', 'Get parameters', 'The device\'s parameters with their values.', {'device': _dev}, readOnly: true),
    _tool('get_alerts', 'Get alerts', 'Current alerts, and recent messages from the device.', {'device': _dev}, readOnly: true),
    _tool('list_recordings', 'List recordings', 'Recorded sessions, newest first.', {}, readOnly: true),
    _tool(
      'get_recording',
      'Read a recording',
      'A recording\'s summary (duration, channels with min/max/mean, events), or with "around" (seconds) the frames ±5 s around that time.',
      {
        'recording': {'type': 'string', 'description': 'Name or id; "latest" for the newest'},
        'around': _num,
      },
      required: ['recording'],
      readOnly: true,
    ),
    _tool('screenshot', 'Screenshot', 'What koebelt dash shows right now.', {}, readOnly: true),
    // Write
    _tool('list_scripts', 'List scripts', 'Scripts in the scripts folder, with their state.', {}, readOnly: true),
    _tool('read_script', 'Read a script', 'A script\'s source.', {'name': _str}, required: ['name'], readOnly: true),
    _tool('write_script', 'Write a script', 'Creates or replaces a script (a replaced version goes to the trash). Start it with a docstring: its first line is the script\'s title.', {'name': _str, 'source': _str}, required: ['name', 'source']),
    _tool('delete_script', 'Delete a script', 'Moves a script to the trash folder, from which the operator can restore it.', {'name': _str}, required: ['name'], destructive: true),
    _tool('check_script', 'Check a script', 'Syntax check with the scripts\' Python.', {'name': _str}, required: ['name'], readOnly: true),
    _tool('list_sequences', 'List sequences', 'A device\'s sequences (Automate > Sequences), with their steps.', {'device': _dev}, readOnly: true),
    _tool(
      'write_sequence',
      'Write a sequence',
      'Creates or replaces a sequence (Automate > Sequences). steps: [{"type": "takeoff", "alt": 6}, {"type": "goto", "x": 10, "y": 0, "z": 8}, {"type": "wait", "s": 2}, {"type": "land"}…]; types depend on the kind (list_sequences shows them).',
      {
        'device': _dev,
        'name': _str,
        'steps': {
          'type': 'array',
          'items': {'type': 'object'},
        },
      },
      required: ['name', 'steps'],
    ),
    _tool(
      'set_trigger',
      'Set a trigger',
      'Adds a trigger to a script: source button, toggle, slider, key (key), condition (expr, e.g. "battery.pct < 25 for 3s"), event (deviceEvent: mode, armed, disarmed, failsafe, linklost, seqdone, log), timer (seconds, repeat). remove: true removes the event\'s triggers of that source.',
      {
        'script': _str,
        'event': _str,
        'source': {
          'type': 'string',
          'enum': [for (final s in TriggerSource.values) s.name],
        },
        'key': _str,
        'expr': _str,
        'deviceEvent': _str,
        'match': _str,
        'seconds': _num,
        'repeat': {'type': 'boolean'},
        'pinned': {'type': 'boolean'},
        'remove': {'type': 'boolean'},
      },
      required: ['script', 'event', 'source'],
    ),
    // Use the app
    _tool(
      'open',
      'Open a screen',
      'Shows a screen in dash. program is Automate > Sequences, scripts is Automate > Scripts.',
      {
        'screen': {
          'type': 'string',
          'enum': ['live', 'control', 'automate', 'program', 'scripts', 'params', 'replay', 'devices', 'guides', 'settings'],
        },
      },
      required: ['screen'],
    ),
    _tool(
      'add_simulated_device',
      'Add a simulated device',
      'Adds and connects a simulated device (no hardware): drone, rover, arm, rocket or bench.',
      {
        'kind': {
          'type': 'string',
          'enum': ['drone', 'rover', 'arm', 'rocket', 'bench'],
        },
      },
      required: ['kind'],
    ),
    _tool('connect', 'Connect a device', 'Connects a paired device.', {'device': _str}, required: ['device']),
    _tool('disconnect', 'Disconnect a device', 'Disconnects a device.', {'device': _str}, required: ['device']),
    _tool('record', 'Record', 'Starts or stops recording the connected devices.', {'on': {'type': 'boolean'}}, required: ['on']),
    _tool(
      'export_recording',
      'Export a recording',
      'A recording as CSV, JSON or GPX text.',
      {
        'recording': _str,
        'format': {
          'type': 'string',
          'enum': ['csv', 'json', 'gpx'],
        },
      },
      required: ['recording', 'format'],
      readOnly: true,
    ),
    _tool('get_settings', 'Get settings', 'The app\'s settings.', {}, readOnly: true),
    _tool('set_setting', 'Change a setting', 'Changes one setting: control, invertY, haptics, rateHz, mapTiles, recordVideo. Safety settings cannot be changed by an assistant.', {'name': _str, 'value': {}}, required: ['name', 'value']),
    // Act
    _tool('run_script', 'Run a script', 'Runs a script on a device. On real hardware the operator approves first.', {'name': _str, 'device': _dev}, required: ['name']),
    _tool('stop_script', 'Stop a script', 'Stops a running script; the device holds.', {'name': _str}, required: ['name']),
    _tool('script_output', 'Script output', 'A script\'s state and its last console lines.', {'name': _str, 'lines': _num}, required: ['name'], readOnly: true),
    _tool('fire_trigger', 'Fire a trigger', 'Fires a running script\'s trigger, with an optional value.', {'script': _str, 'event': _str, 'value': {}}, required: ['script', 'event']),
    _tool('run_sequence', 'Run a sequence', 'Runs a sequence on a device. On real hardware the operator approves first.', {'device': _dev, 'name': _str}, required: ['name']),
    _tool(
      'command',
      'Command a device',
      'One action: mode (m), arm, disarm, takeoff (alt), goto (x, y, z), land, rth, speed (v 0.1–1), home_pose, or a kind-specific command (cmd, args). On real hardware the operator approves first; arming and take-off always ask.',
      {
        'device': _dev,
        'action': _str,
        'm': _str,
        'alt': _num,
        'x': _num,
        'y': _num,
        'z': _num,
        'v': _num,
        'cmd': _str,
        'args': {'type': 'object'},
      },
      required: ['action'],
    ),
    _tool('set_params', 'Write parameters', 'Writes parameters: {"KEY": value}. On real hardware the operator approves first.', {'device': _dev, 'values': {'type': 'object'}}, required: ['values']),
    _tool('stop', 'STOP', 'Emergency stop of every device. Never asks.', {}, destructive: true),
  ];

  Map<String, dynamic> _text(String t, {bool error = false, Object? data}) => {
    'content': [
      {'type': 'text', 'text': t},
    ],
    if (data != null) 'structuredContent': data is Map ? data : {'result': data},
    'isError': error,
  };

  Map<String, dynamic> _json(Object data) => _text(const JsonEncoder.withIndent(' ').convert(data), data: data);

  Future<Map<String, dynamic>> _call(String tool, Map<String, dynamic> a, McpSession? s) async {
    final client = s?.client ?? 'An assistant';
    Map<String, dynamic> r;
    try {
      r = await _run(tool, a, client);
    } on McpError catch (e) {
      r = _text(e.message, error: true);
    } catch (e) {
      r = _text('$e', error: true);
    }
    if (s != null) s.actions++;
    final first = (r['content'] as List).first as Map;
    activity.add((at: DateTime.now(), client: client, tool: tool, summary: first['type'] == 'text' ? '${first['text']}'.split('\n').first : 'image', ok: r['isError'] != true));
    if (activity.length > 200) activity.removeAt(0);
    d.emit();
    return r;
  }

  DeviceLink _link(Object? name) {
    if (name == null || '$name'.isEmpty) {
      final f = d.focus;
      if (f == null) throw McpError('No device is connected. list_devices shows the paired ones; add_simulated_device adds one.');
      return f;
    }
    final n = '$name'.toLowerCase();
    final l = d.links.values.where((x) => x.id.toLowerCase() == n || x.info.name.toLowerCase() == n).firstOrNull;
    if (l == null) throw McpError('No connected device called "$name" (${d.links.values.map((x) => x.info.name).join(', ')}).');
    return l;
  }

  Future<ScriptFile> _script(String name) async {
    final list = await (await _lib()).list();
    final n = name.toLowerCase().replaceAll(RegExp(r'\.py$'), '');
    final f = list.where((x) => x.name.toLowerCase() == n || x.label.toLowerCase().replaceAll(RegExp(r'(\.py|/)$'), '') == n).firstOrNull;
    if (f == null) throw McpError('No script called "$name" (${list.map((x) => x.name).join(', ')}).');
    return f;
  }

  /// Waits for the operator when [l] is real hardware; simulated devices and
  /// classes allowed for the session go through.
  Future<void> _approve(String client, DeviceLink l, String cls, String title, String detail, {bool always = false}) async {
    if (!isReal(l)) return;
    if (!always && allowed.contains('$cls:${l.id}')) return;
    final a = Approval(client: client, title: title, detail: detail, device: l.info.name, cls: '$cls:${l.id}', always: always);
    approvals.add(a);
    d.emit();
    final r = await a.done.future.timeout(approvalTimeout, onTimeout: () => 'timed out');
    approvals.remove(a);
    d.emit();
    if (r != 'approved') throw McpError(r == 'refused' ? 'The operator refused: $title.' : 'Nobody approved "$title" within ${approvalTimeout.inSeconds} s.');
  }

  /// The operator's answer to an approval card.
  void answer(Approval a, bool approve, {bool forSession = false}) {
    if (approve && forSession && !a.always) allowed.add(a.cls);
    _answer(a, approve ? 'approved' : 'refused');
  }

  void _answer(Approval a, String r) {
    if (!a.done.isCompleted) a.done.complete(r);
    approvals.remove(a);
    d.emit();
  }

  String _limitsText(ScriptLimits l) =>
      '${(l.maxSpeed * 100).round()} % speed · ${l.fence == 0 ? 'no fence' : '${l.fence.round()} m fence'}${l.allowArm ? ' · may arm' : ''}${l.allowParams ? ' · may write parameters' : ''}';

  Future<Map<String, dynamic>> _run(String tool, Map<String, dynamic> a, String client) async {
    switch (tool) {
      // ---------------------------------------------------------------- learn
      case 'search_docs':
        final hits = searchDocs(await _allDocs(), '${a['query']}');
        if (hits.isEmpty) return _text('Nothing found. read_doc with id "index" lists every document.');
        return _text([for (final h in hits) '[${h.doc.id}] ${h.doc.title}\n${h.passage.trim()}'].join('\n\n---\n\n'));
      case 'read_doc':
        final docs = await _allDocs();
        if (a['id'] == 'index') return _text([for (final x in docs) '${x.id}: ${x.title}'].join('\n'));
        final doc = docs.where((x) => x.id == a['id']).firstOrNull;
        if (doc == null) throw McpError('No document "${a['id']}". read_doc with id "index" lists them.');
        return _text(doc.text);

      // ---------------------------------------------------------------- look
      case 'list_devices':
        return _json({
          'devices': [
            for (final x in d.devices)
              {
                'name': x.name,
                'kind': x.kind.name,
                'simulated': x.simulated,
                'connected': d.links.containsKey(x.id),
                'selected': x.id == d.deviceId,
                if (d.links[x.id] != null) ...{'mode': d.links[x.id]!.tel.mode, 'armed': d.links[x.id]!.tel.armed, 'stop': d.links[x.id]!.tel.estop},
                'library': ?x.lib,
                'transport': x.transport.name,
              },
          ],
        });
      case 'get_telemetry':
        final l = _link(a['device']), t = l.tel;
        return _json({
          'device': l.info.name,
          ...t.snapshot()..remove('seen'),
          'speed': t.speed,
          'heading': t.heading,
          'estop': t.estop,
          'failsafe': t.failsafe,
          'latencyMs': (l.session.latency * 1000).round(),
          'linkLost': l.linkLostFor > 0,
          'units': 'pos m from home (x east, y north, z up); roll/pitch/yaw rad; battery %',
        });
      case 'get_history':
        final l = _link(a['device']), ch = a['channel'];
        final keys = l.hist.ch.keys.where((k) => l.hist.ch[k]!.ordered.any((v) => v != null)).toList();
        if (ch == null || !l.hist.ch.containsKey(ch)) return _text('Channels with data: ${keys.join(', ')}', error: ch != null);
        final v = l.hist[ch].ordered.whereType<double>().toList();
        final step = math.max(1, v.length ~/ 20);
        return _json({
          'channel': ch,
          'seconds': 10,
          'samples': [for (var i = 0; i < v.length; i += step) double.parse(v[i].toStringAsFixed(4))],
          if (v.isNotEmpty) ...{'min': v.reduce(math.min), 'max': v.reduce(math.max), 'last': v.last},
        });
      case 'get_camera_frame':
        final l = _link(a['device']);
        if (l.video.isEmpty) throw McpError('${l.info.name} has no camera.');
        final f = d.videoFeed(l.video.first, l.info)..acquire();
        try {
          for (var i = 0; i < 60 && f.image == null; i++) {
            await Future<void>.delayed(const Duration(milliseconds: 50));
          }
          final img = f.image;
          if (img == null) throw McpError('No picture from ${l.info.name}\'s camera (${f.status}).');
          final png = await img.toByteData(format: ui.ImageByteFormat.png);
          return {
            'content': [
              {'type': 'image', 'data': base64Encode(png!.buffer.asUint8List()), 'mimeType': 'image/png'},
            ],
            'isError': false,
          };
        } finally {
          f.release();
        }
      case 'get_params':
        final l = _link(a['device']);
        final values = d.paramDev[l.id] ?? const {};
        final groups = d.paramGroups[l.id] ?? const [];
        return _json({
          'device': l.info.name,
          'params': [
            for (final g in groups)
              for (final p in g.params) {'key': p.key, 'label': p.label, 'value': values[p.key] ?? p.def, 'min': p.min, 'max': p.max, 'unit': p.unit, 'group': g.name},
          ],
        });
      case 'get_alerts':
        final l = _link(a['device']);
        return _json({
          'alerts': [for (final x in l.alerts.active.values) '${x.rule.label}: ${x.rule.fmt(x.value)}'],
          'messages': [for (final m in l.logs.reversed.take(20)) '${m['lvl'] ?? 'info'}: ${m['msg']}'],
        });
      case 'list_recordings':
        return _json({
          'recordings': [for (final r in d.sessions.take(50)) {'id': r.id, 'name': r.name, 'device': r.deviceName, 'kind': r.kind.name, 'date': r.date, 'seconds': r.dur.round(), 'sample': r.demo}],
        });
      case 'get_recording':
        final r = _recording(a['recording']);
        return _json(recordingSummary(r, around: (a['around'] as num?)?.toDouble()));
      case 'screenshot':
        final b = screenKey.currentContext?.findRenderObject();
        if (b is! RenderRepaintBoundary) throw McpError('The window is not available.');
        final img = await b.toImage(pixelRatio: 1);
        final png = await img.toByteData(format: ui.ImageByteFormat.png);
        return {
          'content': [
            {'type': 'image', 'data': base64Encode(png!.buffer.asUint8List()), 'mimeType': 'image/png'},
          ],
          'isError': false,
        };

      // ---------------------------------------------------------------- write
      case 'list_scripts':
        final list = await (await _lib()).list();
        return _json({
          'folder': (await _lib()).dir.path,
          'scripts': [
            for (final f in list)
              {
                'name': f.name,
                'file': f.label,
                'state': d.scripts.runs.where((r) => r.file.path == f.path).lastOrNull?.state.name ?? 'stopped',
                'triggers': [for (final b in d.scripts.configFor(f.path).bindings) '${b.event}: ${b.describe((s) => s)}'],
              },
          ],
        });
      case 'read_script':
        final f = await _script('${a['name']}');
        return _text(await f.file.readAsString());
      case 'write_script':
        final lib = await _lib();
        final name = '${a['name']}', src = '${a['source']}';
        ScriptFile? existing;
        try {
          existing = await _script(name);
        } on McpError {
          existing = null;
        }
        if (existing != null && existing.entry is File) {
          // Keep the previous version, as delete does.
          await lib.trash.create(recursive: true);
          await existing.file.copy('${lib.trash.path}/${DateTime.now().millisecondsSinceEpoch} ${existing.label}');
          await existing.file.writeAsString(src);
          return _text('Replaced ${existing.label} (the previous version is in the trash).');
        }
        if (existing != null) {
          await existing.file.writeAsString(src);
          return _text('Replaced ${existing.label}main.py.');
        }
        final f = await lib.create(name.replaceAll(RegExp(r'\.py$'), ''), src);
        return _text('Created ${f.uri.pathSegments.last} in ${lib.dir.path}.');
      case 'delete_script':
        final f = await _script('${a['name']}');
        await (await _lib()).delete(f);
        return _text('Moved ${f.label} to the trash.');
      case 'check_script':
        final f = await _script('${a['name']}');
        final py = d.scripts.pythonFor(d.scripts.configFor(f.path)) ?? d.scripts.pythons?.firstOrNull?.path;
        if (py == null) {
          await d.scripts.refreshPythons(near: (await _lib()).dir);
        }
        final py2 = py ?? d.scripts.pythons?.firstOrNull?.path;
        if (py2 == null) throw McpError('No Python on this computer to check with.');
        final r = await checkSyntax(py2, await f.file.readAsString());
        return _text(r == null ? 'No syntax errors.' : 'Line ${r.line}: ${r.message}', error: r != null);
      // (Called *_program in 1.3.0-beta.1 to beta.3.)
      case 'list_sequences' || 'list_programs':
        final l = _link(a['device']);
        return _json({
          'device': l.info.name,
          'stepTypes': {for (final s in stepDefs(l.kind)) s.type: [for (final f in s.fields) f.key]},
          'sequences': [
            for (final q in d.sequencesFor(l.id)) {'name': q.name, 'steps': [for (final st in q.steps) {'type': st.type, ...st.p}]},
          ],
        });
      case 'write_sequence' || 'write_program':
        final l = _link(a['device']);
        final steps = <SeqStep>[];
        for (final raw in (a['steps'] as List? ?? const [])) {
          final m = (raw as Map).cast<String, dynamic>();
          final def = stepDef(l.kind, '${m['type']}');
          if (def == null) throw McpError('"${m['type']}" is not a step a ${l.kind.name} has (${stepDefs(l.kind).map((s) => s.type).join(', ')}).');
          final st = SeqStep.fresh(def);
          for (final e in m.entries) {
            if (st.p.containsKey(e.key)) st.p[e.key] = e.value;
          }
          steps.add(st);
        }
        final list = d.sequencesFor(l.id), name = '${a['name']}';
        final old = list.where((q) => q.name.toLowerCase() == name.toLowerCase()).firstOrNull;
        final q = Sequence(id: old?.id ?? 'q${DateTime.now().microsecondsSinceEpoch}', name: name, kind: l.kind, steps: steps);
        if (old != null) list[list.indexOf(old)] = q;
        if (old == null) list.add(q);
        d.saveSequences();
        d.emit();
        return _text('${old == null ? 'Created' : 'Replaced'} "$name" (${steps.length} steps) on ${l.info.name}.');
      case 'set_trigger':
        final f = await _script('${a['script']}');
        final cfg = d.scripts.configFor(f.path);
        final source = TriggerSource.values.asNameMap()['${a['source']}'];
        if (source == null) throw McpError('Unknown source ${a['source']}.');
        if (a['remove'] == true) {
          cfg.bindings.removeWhere((b) => b.event == a['event'] && b.source == source);
        } else {
          if (source == TriggerSource.condition) {
            try {
              Condition.parse('${a['expr']}');
            } on ConditionError catch (e) {
              throw McpError('The condition does not parse: ${e.message}');
            }
          }
          cfg.bindings.add(
            TriggerBinding(
              '${a['event']}',
              source,
              key: (a['key'] as String?)?.toUpperCase(),
              expr: a['expr'] as String?,
              deviceEvent: a['deviceEvent'] as String?,
              match: a['match'] as String?,
              seconds: (a['seconds'] as num?)?.toDouble() ?? 5,
              repeat: a['repeat'] != false,
              pinned: a['pinned'] == true,
            ),
          );
        }
        d.scripts.saveConfigs();
        d.emit();
        return _text('Triggers of "${a['event']}": ${cfg.bindings.where((b) => b.event == a['event']).map((b) => b.describe((s) => s)).join('; ')}');

      // ---------------------------------------------------------------- app
      case 'open':
        onOpen?.call('${a['screen']}');
        return _text('Showing ${a['screen']}.');
      case 'add_simulated_device':
        final kind = '${a['kind']}';
        final t = simTemplates().where((x) => x.kind.name == kind).firstOrNull;
        if (t == null) throw McpError('No simulated $kind.');
        final dev = d.addSimulated(t);
        await d.connect(dev.id);
        return _text('Added and connected ${dev.name}, a simulated $kind.');
      case 'connect':
        final n = '${a['device']}'.toLowerCase();
        final dev = d.devices.where((x) => x.name.toLowerCase() == n || x.id.toLowerCase() == n).firstOrNull;
        if (dev == null) throw McpError('No paired device called "${a['device']}".');
        await d.connect(dev.id);
        return _text(d.links.containsKey(dev.id) ? 'Connected ${dev.name}.' : 'Could not connect ${dev.name}: ${d.connectError ?? 'it does not answer'}.', error: !d.links.containsKey(dev.id));
      case 'disconnect':
        final l = _link(a['device']);
        await d.disconnect(id: l.id);
        return _text('Disconnected ${l.info.name}.');
      case 'record':
        if (a['on'] == true && !d.recording) d.startRec();
        if (a['on'] != true && d.recording) d.stopRec();
        return _text(d.recording ? 'Recording.' : 'Not recording.');
      case 'export_recording':
        final r = _recording(a['recording']);
        final fmt = ExportFormat.values.asNameMap()['${a['format']}'];
        if (fmt == null || !formatsFor(r).contains(fmt)) throw McpError('${a['format']} is not available for this recording.');
        final text = exportRecording(r, fmt);
        return _text(text.length > 200000 ? '${text.substring(0, 200000)}\n… (cut at 200 000 characters)' : text);
      case 'get_settings':
        return _json(d.settings.toJson());
      case 'set_setting':
        const allowedKeys = {'control', 'invertY', 'haptics', 'rateHz', 'mapTiles', 'recordVideo'};
        final k = '${a['name']}';
        if (!allowedKeys.contains(k)) throw McpError('An assistant cannot change "$k" (only ${allowedKeys.join(', ')}).');
        final j = d.settings.toJson()..[k] = a['value'];
        d.updateSettings((s) => s.load(j));
        return _text('$k is now ${d.settings.toJson()[k]}.');

      // ---------------------------------------------------------------- act
      case 'run_script':
        final f = await _script('${a['name']}');
        final cfg = d.scripts.configFor(f.path);
        final l = _link(a['device']);
        cfg.device = l.info.name;
        d.scripts.saveConfigs();
        await _approve(client, l, 'script', 'Run “${f.name}” on ${l.info.name}', 'Limits: ${_limitsText(cfg.limits)}. The script stops when you take over or press STOP.');
        final host = d.scripts.hostFor(cfg);
        if (host == null && d.scripts.pythons == null) await d.scripts.refreshPythons(near: (await _lib()).dir);
        final run = host == null ? await d.scripts.runFile(f.file, python: d.scripts.pythonFor(cfg)) : await d.scripts.runOnHost(f.file, host);
        await Future<void>.delayed(const Duration(milliseconds: 800));
        return _text('Started “${f.name}” on ${l.info.name} (${run.where}). script_output shows its console.');
      case 'stop_script':
        final f = await _script('${a['name']}');
        final runs = d.scripts.runs.where((r) => r.file.path == f.path && r.state == ScriptState.running).toList();
        for (final r in runs) {
          await r.stop();
        }
        return _text(runs.isEmpty ? '“${f.name}” is not running.' : 'Stopped “${f.name}”.');
      case 'script_output':
        final f = await _script('${a['name']}');
        final r = d.scripts.runs.where((x) => x.file.path == f.path).lastOrNull;
        if (r == null) return _text('“${f.name}” has not run yet.');
        final n = (a['lines'] as num?)?.toInt() ?? 40;
        final c = d.scripts.connOf(r);
        return _text(
          'State: ${r.state.name}${r.exitCode == null ? '' : ' (exit ${r.exitCode})'}${c?.hz == null ? '' : ', ${c!.hz!.toStringAsFixed(1)} Hz'}'
          '${c?.blocked == null ? '' : '\nThe script lost the sticks: ${c!.blocked}'}\n\n${r.console.skip(math.max(0, r.console.length - n)).map((l) => l.text).join('\n')}',
        );
      case 'fire_trigger':
        final f = await _script('${a['script']}');
        final r = d.scripts.runs.where((x) => x.file.path == f.path && x.state == ScriptState.running).lastOrNull;
        final c = r == null ? null : d.scripts.connOf(r);
        if (c == null) throw McpError('“${f.name}” is not running.');
        final l = c.device == null ? null : d.links[c.device];
        if (l != null) await _approve(client, l, 'trigger', 'Fire “${a['event']}” in “${f.name}”', '');
        d.scripts.fire(c, '${a['event']}', a['value']);
        return _text('Fired “${a['event']}”.');
      case 'run_sequence' || 'run_program':
        final l = _link(a['device']);
        final q = d.sequencesFor(l.id).where((x) => x.name.toLowerCase() == '${a['name']}'.toLowerCase()).firstOrNull;
        if (q == null) throw McpError('No sequence "${a['name']}" on ${l.info.name}.');
        final arms = q.steps.any((st) => st.type == 'takeoff' || st.type == 'arm');
        await _approve(client, l, 'program', 'Run “${q.name}” on ${l.info.name}', '${q.steps.length} steps: ${q.steps.map((st) => st.summary(l.kind)).take(4).join(', ')}${q.steps.length > 4 ? '…' : ''}', always: arms);
        d.runSequenceOn(l, q);
        return _text('Running “${q.name}” on ${l.info.name}.');
      case 'command':
        return _command(client, a);
      case 'set_params':
        final l = _link(a['device']);
        final v = (a['values'] as Map? ?? const {}).map((k, x) => MapEntry('$k', (x as num).toDouble()));
        await _approve(client, l, 'params', 'Write ${v.length} parameter${v.length == 1 ? '' : 's'} on ${l.info.name}', v.entries.map((e) => '${e.key} = ${e.value}').join(', '));
        d.sendTo(l, {'t': 'pset', 'p': v});
        return _text('Wrote ${v.keys.join(', ')}. It is not saved to flash: the operator can save it in Tune.');
      case 'stop':
        d.emergencyStop();
        return _text('STOP: every device is stopped and disarmed. The operator clears it in dash.');
    }
    throw McpError('Unknown tool $tool.');
  }

  Future<Map<String, dynamic>> _command(String client, Map<String, dynamic> a) async {
    final l = _link(a['device']), action = '${a['action']}', h = d.linkHost(l);
    if (l.tel.estop) throw McpError('STOP is on: the operator must clear it.');
    double n(String k, double def) => (a[k] as num?)?.toDouble() ?? def;
    Future<void> ask(String title, {bool always = false}) => _approve(client, l, 'command', title, '', always: always);
    Future<String> step(String type, Map<String, Object> p, String title, {bool always = false}) async {
      final def = stepDef(l.kind, type);
      if (def == null) throw McpError('A ${l.kind.name} has no $type.');
      await ask(title, always: always);
      final st = SeqStep.fresh(def)..p.addAll(p);
      final q = Sequence(id: 'mcp-${DateTime.now().microsecondsSinceEpoch}', name: 'Assistant: ${def.label}', kind: l.kind, steps: [st]);
      d.runSequenceOn(l, q);
      for (var i = 0; i < 1200; i++) {
        final r = l.runner;
        if (r?.seq != q) return 'Interrupted: another sequence started.';
        if (r!.state == RunState.done) return '$title: done.';
        if (r.state == RunState.failed) return '$title failed: ${r.message}';
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      return '$title is still going.';
    }

    switch (action) {
      case 'mode':
        final m = '${a['m']}'.toUpperCase();
        await ask('Switch ${l.info.name} to $m', always: m == 'TAKEOFF');
        h.seqSetMode(m);
        return _text('${l.info.name} is in ${l.tel.mode}.');
      case 'arm':
        await ask('Arm ${l.info.name}', always: true);
        h.seqSetArmed(true);
        return _text('Armed ${l.info.name}.');
      case 'disarm':
        h.seqSetArmed(false);
        return _text('Disarmed ${l.info.name}.');
      case 'takeoff':
        return _text(await step('takeoff', {'alt': n('alt', 6)}, 'Take off to ${n('alt', 6)} m', always: true));
      case 'goto':
        return _text(await step('goto', {'x': n('x', 0), 'y': n('y', 0), if (a['z'] != null) 'z': n('z', 8)}, 'Go to ${n('x', 0)}, ${n('y', 0)}${a['z'] == null ? '' : ', ${n('z', 8)}'} m'));
      case 'land':
        return _text(await step('land', {}, 'Land'));
      case 'rth':
        return _text(await step('rth', {}, 'Return home'));
      case 'home_pose':
        return _text(await step('home', {}, 'Home pose'));
      case 'speed':
        final v = n('v', .5).clamp(.1, 1.0);
        await ask('Set the speed limit to ${(v * 100).round()} %');
        h.seqSetSpeed(v);
        return _text('Speed limit ${(v * 100).round()} %.');
      case 'cmd':
        final c = '${a['cmd']}';
        await ask('Send “$c” to ${l.info.name}');
        h.seqCmd(c, (a['args'] as Map?)?.cast<String, dynamic>() ?? const {});
        return _text('Sent $c.');
    }
    throw McpError('Unknown action "$action" (mode, arm, disarm, takeoff, goto, land, rth, speed, home_pose, cmd).');
  }

  Recording _recording(Object? name) {
    final n = '${name ?? 'latest'}'.toLowerCase();
    if (d.sessions.isEmpty) throw McpError('There are no recordings.');
    if (n == 'latest') return d.sessions.first;
    final r = d.sessions.where((x) => x.id.toLowerCase() == n || x.name.toLowerCase() == n).firstOrNull ?? d.sessions.where((x) => x.name.toLowerCase().contains(n)).firstOrNull;
    if (r == null) throw McpError('No recording "$name". list_recordings shows them.');
    return r;
  }
}

/// A recording for an assistant: what is in it, or the frames around a moment.
Map<String, dynamic> recordingSummary(Recording r, {double? around}) {
  final stats = <String, ({double min, double max, double sum, int n})>{};
  void add(String k, Object? v) {
    if (v is! num) return;
    final s = stats[k];
    final x = v.toDouble();
    stats[k] = s == null ? (min: x, max: x, sum: x, n: 1) : (min: math.min(s.min, x), max: math.max(s.max, x), sum: s.sum + x, n: s.n + 1);
  }

  for (final f in r.frames) {
    for (final e in f.entries) {
      if (e.key == 't') continue;
      if (e.value is List) {
        final l = e.value as List;
        for (var i = 0; i < l.length && i < 6; i++) {
          add('${e.key}[$i]', l[i]);
        }
      } else {
        add(e.key, e.value);
      }
    }
  }
  String f4(double v) => v.toStringAsFixed(4).replaceFirst(RegExp(r'\.?0+$'), '');
  final out = <String, dynamic>{
    'name': r.name,
    'device': r.deviceName,
    'kind': r.kind.name,
    'date': r.date,
    'seconds': double.parse(r.dur.toStringAsFixed(1)),
    'frames': r.frames.length,
    'events': [for (final e in r.events) '${e.t.toStringAsFixed(1)} s ${e.kind}: ${e.text}'],
    'modes': {
      for (var i = 0; i < r.frames.length; i++)
        if (i == 0 || r.frames[i]['mode'] != r.frames[i - 1]['mode']) r.timeAt(i).toStringAsFixed(1): r.frames[i]['mode'],
    },
  };
  if (around == null) {
    out['channels'] = {for (final e in stats.entries) e.key: 'min ${f4(e.value.min)} · max ${f4(e.value.max)} · mean ${f4(e.value.sum / e.value.n)}'};
    out['hint'] = 'Ask again with "around" (seconds) for the frames near a moment.';
  } else {
    final sel = [
      for (var i = 0; i < r.frames.length; i++)
        if ((r.timeAt(i) - around).abs() <= 5) r.frames[i],
    ];
    final step = math.max(1, sel.length ~/ 40);
    out['around'] = around;
    out['framesNear'] = [for (var i = 0; i < sel.length; i += step) sel[i]..remove('seen')];
  }
  return out;
}
