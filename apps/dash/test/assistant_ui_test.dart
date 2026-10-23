// The assistant UI: the settings section, the header chip, and an approval
// card answered by the operator. Pictures with CAPTURE_DIR=/tmp/x.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koebelt_dash/app.dart';
import 'package:koebelt_dash/core/dash.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _loadFonts() async {
  for (final fam in ['Archivo', 'JetBrainsMono']) {
    final l = FontLoader(fam);
    for (final w in [400, 500, 600, 700]) {
      l.addFont(rootBundle.load('assets/fonts/$fam-$w.ttf'));
    }
    await l.load();
  }
}

void main() {
  final shots = Platform.environment['CAPTURE_DIR'];

  testWidgets('an assistant connects, asks to move real hardware, and the operator approves', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.runAsync(_loadFonts);
    final d = Dash();
    await tester.runAsync(() async {
      await d.init();
      await d.scripts.start(port: 0);
      d.mcp.enabled = true;
      await d.connect(d.addSimulated(simTemplates().firstWhere((t) => t.id == 'mule')).id);
    });
    // The simulated rover stands in for real hardware here.
    d.mcp.isReal = (_) => true;
    // testWidgets installs a fake HttpClient that answers 400: this talks to a real server.
    HttpOverrides.global = null;
    // Made in the real zone, so its connection timers are real ones.
    late final HttpClient http;
    await tester.runAsync(() async => http = HttpClient());
    String? session;
    Future<Map> rpc(String method, Map params) async {
      final req = await http.postUrl(Uri.parse('http://127.0.0.1:${d.scripts.port}/mcp'));
      // No keep-alive: its idle timer would outlive the test.
      req.persistentConnection = false;
      req.headers.contentType = ContentType.json;
      if (session != null) req.headers.set('mcp-session-id', session!);
      req.write(jsonEncode({'jsonrpc': '2.0', 'id': 1, 'method': method, 'params': params}));
      final res = await req.close();
      session ??= res.headers.value('mcp-session-id');
      return jsonDecode(await utf8.decoder.bind(res).join()) as Map;
    }

    final key = GlobalKey();
    Future<void> show(String screen, {required bool phone}) async {
      final (size, scale, top, bottom) = phone ? (const Size(440, 956), 2.0, 62.0, 34.0) : (const Size(1440, 900), 1.0, 0.0, 0.0);
      tester.view.physicalSize = size * scale;
      tester.view.devicePixelRatio = scale;
      tester.view.padding = FakeViewPadding(top: top * scale, bottom: bottom * scale);
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(brightness: Brightness.dark),
            home: Scaffold(body: DashApp(key: UniqueKey(), dash: d, initial: screen)),
          ),
        ),
      );
    }

    Future<void> settle([int n = 15]) async {
      for (var i = 0; i < n; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
        await tester.pump(const Duration(milliseconds: 30));
      }
    }

    Future<void> shot(String name, double scale) async {
      if (shots == null) return;
      await tester.runAsync(() async {
        final b = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final img = await b.toImage(pixelRatio: scale);
        final png = await img.toByteData(format: ui.ImageByteFormat.png);
        await File('$shots/$name.png').writeAsBytes(png!.buffer.asUint8List());
      });
    }

    addTearDown(tester.view.reset);
    await tester.runAsync(() => rpc('initialize', {'protocolVersion': '2025-06-18', 'clientInfo': {'name': 'claude-code'}}));

    await show('settings', phone: false);
    await settle();
    await tester.scrollUntilVisible(find.text('Connect a client'), 300, scrollable: find.byType(Scrollable).first);
    await settle(5);
    expect(find.text('CLAUDE CODE · 0 ACTIONS'), findsOneWidget, reason: 'the header chip');
    await shot('ai_settings_desktop', 1);

    await show('live', phone: false);
    await settle();
    late Future<Map> call;
    await tester.runAsync(() async {
      call = rpc('tools/call', {'name': 'command', 'arguments': {'action': 'mode', 'm': 'hold'}});
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await settle();
    expect(find.text('Switch Mule to HOLD'), findsOneWidget);
    await shot('ai_approval_desktop', 1);

    await show('control', phone: true);
    await settle();
    await shot('ai_approval_phone', 2);
    await tester.tap(find.text('APPROVE'));
    await settle();
    final r = await tester.runAsync(() => call);
    expect('${r!['result']['content'][0]['text']}', contains('HOLD'));
    expect(find.text('Switch Mule to HOLD'), findsNothing);

    await tester.runAsync(() async {
      http.close(force: true);
      await d.scripts.stop();
      await d.disconnectAll();
    });
    await tester.pumpWidget(const SizedBox());
    // Past the HTTP client's 15 s keep-alive timer.
    await tester.pump(const Duration(seconds: 20));
  });
}
