// koebelt-dash-mcp: MCP over stdio, relayed to koebelt dash.
//
// MCP clients that start a command (Claude Desktop's config file…) run this
// program; it relays each JSON-RPC message from stdin to dash's MCP server
// (http://127.0.0.1:47920/mcp, or what ~/.koebelt/dash-api.json says) and
// writes dash's answers to stdout, one per line. If dash is not running it
// starts it (macOS) and waits for it.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

const version = '1.3.0-beta.4';

Uri findDash() {
  final env = Platform.environment['KOEBELT_DASH_MCP_URL'];
  if (env != null) return Uri.parse(env);
  final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '.';
  try {
    final j = jsonDecode(File('$home/.koebelt/dash-api.json').readAsStringSync()) as Map;
    if (j['mcp'] is String) return Uri.parse(j['mcp'] as String);
  } catch (_) {}
  return Uri.parse('http://127.0.0.1:47920/mcp');
}

class Bridge {
  Bridge(this.url, this.out, {this.launch = true});
  Uri url;
  final IOSink out;
  final bool launch;
  final http = HttpClient()..connectionTimeout = const Duration(seconds: 3);
  String? session;
  bool _launched = false;

  /// The initialize in flight: other messages wait for its session.
  Future<void>? _init;

  void write(Object msg) => out.writeln(jsonEncode(msg));

  Future<void> handle(String line) async {
    if (line.trim().isEmpty) return;
    Object? msg;
    try {
      msg = jsonDecode(line);
    } catch (_) {
      return write({
        'jsonrpc': '2.0',
        'id': null,
        'error': {'code': -32700, 'message': 'Parse error'},
      });
    }
    final id = msg is Map ? msg['id'] : null;
    if (msg is Map && msg['method'] == 'initialize') {
      final done = Completer<void>();
      _init = done.future;
      try {
        return await _send(line, id);
      } finally {
        done.complete();
      }
    }
    await _init;
    await _send(line, id);
  }

  Future<void> _send(String line, Object? id) async {
    for (var attempt = 0;; attempt++) {
      try {
        final req = await http.postUrl(url);
        req.headers.contentType = ContentType.json;
        req.headers.set('accept', 'application/json, text/event-stream');
        if (session != null) req.headers.set('mcp-session-id', session!);
        req.write(line);
        final res = await req.close();
        session = res.headers.value('mcp-session-id') ?? session;
        final body = await utf8.decoder.bind(res).join();
        if (body.trim().isNotEmpty && id != null) out.writeln(jsonEncode(jsonDecode(body)));
        return;
      } on SocketException {
        // dash is not running (yet): start it once, then wait up to 20 s.
        if (launch && !_launched) {
          _launched = true;
          await _startDash();
        }
        if (attempt >= 40 || !launch) {
          if (id != null) {
            write({
              'jsonrpc': '2.0',
              'id': id,
              'error': {'code': -32000, 'message': 'koebelt dash is not running at $url. Open it, and turn on Settings > AI assistants.'},
            });
          }
          return;
        }
        await Future<void>.delayed(const Duration(milliseconds: 500));
        url = findDash();
      }
    }
  }

  Future<void> _startDash() async {
    try {
      if (Platform.isMacOS) {
        await Process.run('open', ['-g', '-b', 'com.koebelt.dash']);
      } else {
        // The app sits next to this program on Windows and Linux.
        final dir = File(Platform.resolvedExecutable).parent.path;
        for (final n in ['koebelt_dash.exe', 'koebelt_dash', 'koebelt-dash']) {
          final f = File('$dir${Platform.pathSeparator}$n');
          if (f.existsSync()) {
            await Process.start(f.path, [], mode: ProcessStartMode.detached);
            break;
          }
        }
      }
    } catch (_) {}
  }
}

Future<void> main(List<String> args) async {
  if (args.contains('--version')) {
    stdout.writeln(version);
    return;
  }
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln('koebelt-dash-mcp: MCP over stdio for koebelt dash. Add it to an MCP client as a command; dash must have Settings > AI assistants on.');
    return;
  }
  final b = Bridge(findDash(), stdout, launch: !args.contains('--no-launch'));
  final pending = <Future<void>>[];
  // Each message on its own: a tool waiting for the operator must not hold up a ping.
  await for (final line in stdin.transform(utf8.decoder).transform(const LineSplitter())) {
    final f = b.handle(line);
    pending.add(f);
    unawaited(f.whenComplete(() => pending.remove(f)));
  }
  await Future.wait(List.of(pending));
  b.http.close(force: true);
}
