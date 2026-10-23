import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:koebelt_dash/core/dash.dart';
import 'package:koebelt_dash/scripts/library.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// An MCP client over Streamable HTTP, as Claude Code talks to dash.
class _Client {
  _Client(this.url);
  final String url;
  final http = HttpClient();
  String? session;
  var _id = 0;

  Future<(int, Map<String, dynamic>?)> post(Object body, {Map<String, String> headers = const {}}) async {
    final req = await http.postUrl(Uri.parse(url));
    req.headers.contentType = ContentType.json;
    req.headers.set('accept', 'application/json, text/event-stream');
    if (session != null) req.headers.set('mcp-session-id', session!);
    headers.forEach(req.headers.set);
    req.write(jsonEncode(body));
    final res = await req.close();
    session = res.headers.value('mcp-session-id') ?? session;
    final text = await utf8.decoder.bind(res).join();
    return (res.statusCode, text.isEmpty ? null : (jsonDecode(text) as Map).cast<String, dynamic>());
  }

  Future<Map<String, dynamic>> rpc(String method, [Map<String, dynamic> params = const {}]) async {
    final (code, body) = await post({'jsonrpc': '2.0', 'id': ++_id, 'method': method, 'params': params});
    expect(code, 200, reason: '$body');
    if (body!['error'] != null) throw StateError('${body['error']['message']}');
    return (body['result'] as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> tool(String name, [Map<String, dynamic> args = const {}]) => rpc('tools/call', {'name': name, 'arguments': args});

  static String text(Map<String, dynamic> r) => (r['content'] as List).map((c) => c['text'] ?? '[${c['type']}]').join('\n');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // flutter_test answers every HTTP request with 400; these go to a real server.
  HttpOverrides.global = null;
  late Dash d;
  late _Client c;
  late Directory dir;
  Timer? ticker;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    d = Dash();
    await d.init();
    await d.scripts.start(port: 0);
    d.mcp.enabled = true;
    dir = await Directory.systemTemp.createTemp('kdash-mcp');
    d.mcp.library = ScriptLibrary(Directory('${dir.path}/dash scripts'));
    c = _Client('http://127.0.0.1:${d.scripts.port}/mcp');
    ticker = Timer.periodic(const Duration(milliseconds: 20), (_) => d.tick(.02));
  });

  tearDown(() async {
    ticker?.cancel();
    await d.scripts.stop();
    await d.disconnectAll();
    await dir.delete(recursive: true);
  });

  Future<void> init() async {
    final r = await c.rpc('initialize', {
      'protocolVersion': '2025-06-18',
      'capabilities': {},
      'clientInfo': {'name': 'claude-code', 'version': '2.0'},
    });
    expect(r['protocolVersion'], '2025-06-18');
    expect(r['serverInfo']['name'], 'koebelt-dash');
    expect(c.session, isNotNull);
    final (code, _) = await c.post({'jsonrpc': '2.0', 'method': 'notifications/initialized'});
    expect(code, 202);
  }

  test('off until enabled; no browsers; only this computer without a token', () async {
    d.mcp.enabled = false;
    var (code, body) = await c.post({'jsonrpc': '2.0', 'id': 1, 'method': 'initialize', 'params': {}});
    expect(code, 503);
    expect(body!['error']['message'], contains('Settings > AI assistants'));
    d.mcp.enabled = true;
    (code, body) = await c.post({'jsonrpc': '2.0', 'id': 1, 'method': 'initialize', 'params': {}}, headers: {'origin': 'https://evil.example'});
    expect(code, 403, reason: 'a web page cannot reach it');
    (code, _) = await c.post({'jsonrpc': '2.0', 'id': 1, 'method': 'ping'}, headers: {'origin': 'http://localhost:3000'});
    expect(code, 200);
  });

  test('handshake, tools, resources and prompts', () async {
    await init();
    expect(d.mcp.connected?.client, 'Claude Code');
    final tools = [for (final t in (await c.rpc('tools/list'))['tools'] as List) t['name']];
    expect(tools, containsAll(['search_docs', 'list_devices', 'write_script', 'run_script', 'command', 'stop']));
    final res = (await c.rpc('resources/list'))['resources'] as List;
    expect(res.map((r) => r['name']), containsAll(['guide:quickstart', 'ref:scripts-api', 'ref:protocol', 'example:drive_square.py']));
    final api = await c.rpc('resources/read', {'uri': 'koebelt://docs/ref:scripts-api'});
    expect(api['contents'][0]['text'], contains('koebelt-dash-scripts'));
    final prompts = [for (final p in (await c.rpc('prompts/list'))['prompts'] as List) p['name']];
    expect(prompts, contains('write_script'));
    final p = await c.rpc('prompts/get', {'name': 'write_script', 'arguments': {'task': 'follow a line'}});
    expect(p['messages'][0]['content']['text'], contains('follow a line'));
  });

  test('learn: search and read the docs', () async {
    await init();
    final hits = _Client.text(await c.tool('search_docs', {'query': 'failsafe timeout'}));
    expect(hits, contains('failsafe'));
    final idx = _Client.text(await c.tool('read_doc', {'id': 'index'}));
    expect(idx, contains('ref:scripts-protocol'));
    final r = await c.tool('read_doc', {'id': 'nope'});
    expect(r['isError'], isTrue);
  });

  test('use the app and look: a simulated rover, its telemetry and programs', () async {
    await init();
    expect(_Client.text(await c.tool('add_simulated_device', {'kind': 'rover'})), contains('simulated rover'));
    final devs = (await c.tool('list_devices'))['structuredContent']['devices'] as List;
    expect(devs.where((x) => x['connected'] == true).single['kind'], 'rover');
    final tel = (await c.tool('get_telemetry'))['structuredContent'] as Map;
    expect(tel['pos'], hasLength(3));
    expect((await c.tool('get_params'))['structuredContent']['params'], isNotEmpty);
    final w = await c.tool('write_program', {
      'name': 'Out and back',
      'steps': [
        {'type': 'goto', 'x': 3, 'y': 0},
        {'type': 'goto', 'x': 0, 'y': 0},
      ],
    });
    expect(_Client.text(w), contains('Created "Out and back" (2 steps)'));
    final bad = await c.tool('write_program', {
      'name': 'x',
      'steps': [
        {'type': 'takeoff'},
      ],
    });
    expect(_Client.text(bad), contains('not a step a rover has'));
    expect((await c.tool('set_setting', {'name': 'failsafe', 'value': 'LAND'}))['isError'], isTrue, reason: 'no safety settings');
    expect(_Client.text(await c.tool('set_setting', {'name': 'rateHz', 'value': 10})), contains('rateHz is now 10'));
  });

  test('write, check and read scripts; deletes go to the trash', () async {
    await init();
    expect(_Client.text(await c.tool('write_script', {'name': 'Circle', 'source': '"""Circle home."""\nprint(1)\n'})), contains('Created circle.py'));
    expect(_Client.text(await c.tool('write_script', {'name': 'Circle home', 'source': '"""Circle home."""\nprint(2)\n'})), contains('previous version is in the trash'));
    expect(_Client.text(await c.tool('read_script', {'name': 'circle'})), contains('print(2)'));
    final list = (await c.tool('list_scripts'))['structuredContent']['scripts'] as List;
    expect(list.single['name'], 'Circle home');
    final t = await c.tool('set_trigger', {'script': 'circle', 'event': 'Low', 'source': 'condition', 'expr': 'battery.pct <'});
    expect(_Client.text(t), contains('does not parse'));
    expect(_Client.text(await c.tool('set_trigger', {'script': 'circle', 'event': 'Low', 'source': 'condition', 'expr': 'battery.pct < 20'})), contains('battery.pct < 20'));
    await c.tool('delete_script', {'name': 'Circle home'});
    expect((await c.tool('list_scripts'))['structuredContent']['scripts'], isEmpty);
  });

  test('act: simulated devices go through; real hardware waits for the operator', () async {
    await init();
    await c.tool('add_simulated_device', {'kind': 'rover'});
    final sim = await c.tool('command', {'action': 'mode', 'm': 'manual'});
    expect(_Client.text(sim), contains('MANUAL'), reason: 'no approval on a simulated device');

    d.mcp.isReal = (_) => true;
    // Refused.
    var call = c.tool('command', {'action': 'mode', 'm': 'hold'});
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(d.mcp.approvals.single.title, 'Switch Mule to HOLD');
    expect(d.mcp.approvals.single.client, 'Claude Code');
    d.mcp.answer(d.mcp.approvals.single, false);
    expect(_Client.text(await call), contains('The operator refused'));
    expect(d.links.values.single.tel.mode, 'MANUAL');
    // Approved for the session: the next command goes through.
    call = c.tool('command', {'action': 'mode', 'm': 'hold'});
    await Future<void>.delayed(const Duration(milliseconds: 200));
    d.mcp.answer(d.mcp.approvals.single, true, forSession: true);
    expect(_Client.text(await call), contains('HOLD'));
    expect(_Client.text(await c.tool('command', {'action': 'mode', 'm': 'manual'})), contains('MANUAL'));
    // Arming always asks, even after "for this session".
    call = c.tool('command', {'action': 'arm'});
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(d.mcp.approvals.single.always, isTrue);
    d.mcp.answer(d.mcp.approvals.single, false, forSession: true);
    expect((await call)['isError'], isTrue);
    // STOP never asks.
    expect(_Client.text(await c.tool('stop')), contains('STOP'));
    expect(d.links.values.single.tel.estop, isTrue);
    // The activity log keeps it all.
    expect(d.mcp.activity.map((e) => e.tool), containsAll(['command', 'stop']));
  });
}
