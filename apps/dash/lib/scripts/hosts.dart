import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'script_runner.dart';

/// Script hosts: computers running `koebelt-dash-scripts host`, where phones
/// and tablets run their scripts (protocol/SCRIPTS.md, Script hosts).
const hostPort = 47921, hostDiscoveryPort = 47922;

/// A host this dash is paired with.
class ScriptHost {
  ScriptHost({required this.name, required this.address, required this.port, required this.token, this.python = ''});
  String name, address, python;
  int port;
  final String token;

  String get key => '$address:$port';

  Map<String, dynamic> toJson() => {'name': name, 'address': address, 'port': port, 'token': token, 'python': python};
  factory ScriptHost.fromJson(Map j) => ScriptHost(
    name: '${j['name']}',
    address: '${j['address']}',
    port: (j['port'] as num?)?.toInt() ?? hostPort,
    token: '${j['token']}',
    python: '${j['python'] ?? ''}',
  );
}

/// A host answering on the network.
typedef FoundHost = ({String name, String address, int port, String python});

/// Asks the local network for script hosts, for [wait].
Future<List<FoundHost>> discoverHosts({Duration wait = const Duration(milliseconds: 1500), int port = hostDiscoveryPort}) async {
  final found = <String, FoundHost>{};
  RawDatagramSocket? s;
  try {
    s = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    s.broadcastEnabled = true;
    final probe = utf8.encode(jsonEncode({'t': 'hostdiscover'}));
    s.listen((e) {
      if (e != RawSocketEvent.read) return;
      final d = s!.receive();
      if (d == null) return;
      try {
        final m = jsonDecode(utf8.decode(d.data)) as Map;
        if (m['t'] != 'host') return;
        final h = (name: '${m['name']}', address: d.address.address, port: (m['port'] as num?)?.toInt() ?? hostPort, python: '${m['python'] ?? ''}');
        found['${h.address}:${h.port}'] = h;
      } catch (_) {}
    });
    for (var i = 0; i < 3; i++) {
      s.send(probe, InternetAddress('255.255.255.255'), port);
      s.send(probe, InternetAddress.loopbackIPv4, port);
      await Future<void>.delayed(wait ~/ 3);
    }
  } catch (_) {
    // No network, or broadcasts not allowed (iOS without the multicast
    // entitlement): the address can still be typed.
  } finally {
    s?.close();
  }
  return found.values.toList();
}

class HostError implements Exception {
  HostError(this.message);
  final String message;
  @override
  String toString() => message;
}

Future<WebSocket> _open(String address, int port) async {
  try {
    return await WebSocket.connect('ws://$address:$port/host').timeout(const Duration(seconds: 5));
  } catch (e) {
    throw HostError('No script host at $address:$port. Is `koebelt-dash-scripts host` running there?');
  }
}

/// Pairs with a host using the code it shows.
Future<ScriptHost> pairHost(String address, int port, String code, {required String myName}) async {
  final ws = await _open(address, port);
  try {
    ws.add(jsonEncode({'t': 'pair', 'code': code.trim(), 'name': myName}));
    final m = jsonDecode(await ws.first.timeout(const Duration(seconds: 5)) as String) as Map;
    if (m['t'] != 'paired') throw HostError('${m['why'] ?? 'The host refused.'}');
    return ScriptHost(name: '${m['name']}', address: address, port: port, token: '${m['token']}', python: '${m['python'] ?? ''}');
  } finally {
    await ws.close();
  }
}

/// A script running on a host. Its output comes back here; it connects to
/// this dash's script API ([dashPort]) with [token].
class RemoteRun extends ScriptRun {
  RemoteRun._(super.file, super.token, super.onChange, this.host, this._ws, this._runMsg) {
    _ws.listen(
      (data) {
        if (data is! String) return;
        final m = jsonDecode(data) as Map;
        switch (m['t']) {
          case 'welcome':
            _ws.add(jsonEncode(_runMsg));
            log('info', 'Sent to ${host.name}');
          case 'started':
            log('info', 'Started on ${host.name} with Python ${m['python'] ?? ''}');
          case 'out':
            log('${m['level'] ?? 'out'}', '${m['text']}');
          case 'exit':
            this.exitCode = (m['code'] as num?)?.toInt();
            state = this.exitCode == 0 || _stopping ? ScriptState.exited : ScriptState.failed;
            log(state == ScriptState.failed ? 'err' : 'info', _stopping ? 'Stopped' : 'Exited with code ${this.exitCode}');
            _ws.close();
          case 'bye':
            state = ScriptState.failed;
            log('err', '${m['why']}');
        }
      },
      onDone: () {
        if (state == ScriptState.running) {
          state = ScriptState.failed;
          log('err', 'Lost the connection to ${host.name}.');
        }
      },
      onError: (_) {},
    );
  }

  final ScriptHost host;
  final WebSocket _ws;
  final Map<String, dynamic> _runMsg;
  bool _stopping = false;

  @override
  String get where => host.name;

  @override
  Future<void> stop({Duration grace = const Duration(seconds: 2)}) async {
    if (state != ScriptState.running) return;
    _stopping = true;
    try {
      _ws.add(jsonEncode({'t': 'stop'}));
    } catch (_) {}
    for (var t = Duration.zero; t < grace + const Duration(seconds: 1) && state == ScriptState.running; t += const Duration(milliseconds: 50)) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    if (state == ScriptState.running) {
      state = ScriptState.exited;
      await _ws.close();
      onChange();
    }
  }

  /// Sends [file] (and, for a folder script, its folder) to [host] and runs it.
  static Future<RemoteRun> start(File file, ScriptHost host, {required int dashPort, required String token, required void Function() onChange}) async {
    final files = await _filesOf(file);
    final ws = await _open(host.address, host.port);
    final r = RemoteRun._(file, token, onChange, host, ws, {
      't': 'run',
      'name': file.uri.pathSegments.last,
      'main': files.main,
      'files': files.files,
      'dashPort': dashPort,
      'dashToken': token,
    });
    ws.add(jsonEncode({'t': 'hello', 'token': host.token}));
    return r;
  }
}

/// A script's files, base64 by relative path: the file alone, or its whole
/// folder for a folder script (main.py with a model, data…).
Future<({String main, Map<String, String> files})> _filesOf(File file) async {
  final base = file.uri.pathSegments.last;
  if (base != 'main.py') return (main: base, files: {base: base64Encode(await file.readAsBytes())});
  final root = file.parent;
  final out = <String, String>{};
  await for (final e in root.list(recursive: true)) {
    if (e is! File) continue;
    final rel = e.path.substring(root.path.length + 1).replaceAll('\\', '/');
    if (rel.split('/').any((p) => p.startsWith('.') || p == '__pycache__')) continue;
    out[rel] = base64Encode(await e.readAsBytes());
  }
  return (main: 'main.py', files: out);
}
