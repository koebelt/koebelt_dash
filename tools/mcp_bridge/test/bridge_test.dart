import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

/// A stand-in for dash's MCP endpoint, then the bridge as a client starts it.
void main() {
  late HttpServer dash;
  final seen = <String>[];

  setUp(() async {
    seen.clear();
    dash = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    dash.listen((req) async {
      final m = jsonDecode(await utf8.decoder.bind(req).join()) as Map;
      seen.add('${m['method']} ${req.headers.value('mcp-session-id') ?? '-'}');
      if (m['id'] == null) {
        req.response.statusCode = 202;
      } else {
        if (m['method'] == 'initialize') req.response.headers.set('mcp-session-id', 's1');
        // A slow tool, as one waiting for the operator.
        if (m['method'] == 'tools/call') await Future<void>.delayed(const Duration(milliseconds: 400));
        req.response.headers.contentType = ContentType.json;
        req.response.write(jsonEncode({'jsonrpc': '2.0', 'id': m['id'], 'result': {'echo': m['method']}}));
      }
      await req.response.close();
    });
  });

  tearDown(() => dash.close(force: true));

  Future<List<Map>> talk(List<Map> msgs, {String? url}) async {
    final p = await Process.start(Platform.resolvedExecutable, [
      'run',
      'bin/koebelt_dash_mcp.dart',
      '--no-launch',
    ], environment: {'KOEBELT_DASH_MCP_URL': url ?? 'http://127.0.0.1:${dash.port}/mcp'});
    for (final m in msgs) {
      p.stdin.writeln(jsonEncode(m));
    }
    await p.stdin.close();
    final out = await p.stdout.transform(utf8.decoder).transform(const LineSplitter()).toList();
    await p.exitCode;
    return [for (final l in out) jsonDecode(l) as Map];
  }

  test('relays requests, keeps the session, stays quiet for notifications, and does not hold a ping behind a slow tool', () async {
    final out = await talk([
      {'jsonrpc': '2.0', 'id': 1, 'method': 'initialize', 'params': {}},
      {'jsonrpc': '2.0', 'method': 'notifications/initialized'},
      {'jsonrpc': '2.0', 'id': 2, 'method': 'tools/call', 'params': {}},
      {'jsonrpc': '2.0', 'id': 3, 'method': 'ping'},
    ]);
    expect(out.map((m) => m['id']), [1, 3, 2], reason: 'the ping answers before the slow tool');
    expect(out.first['result']['echo'], 'initialize');
    expect(seen.skip(1), everyElement(endsWith(' s1')), reason: 'the session after initialize');
  });

  test('says so when dash is not running', () async {
    final out = await talk([
      {'jsonrpc': '2.0', 'id': 1, 'method': 'initialize', 'params': {}},
    ], url: 'http://127.0.0.1:1/mcp');
    expect(out.single['error']['message'], contains('koebelt dash is not running'));
  });
}
