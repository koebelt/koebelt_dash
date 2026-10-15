import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:koebelt_dash/app.dart';
import 'package:koebelt_dash/core/dash.dart';
import 'package:koebelt_dash/core/store.dart';
import 'package:koebelt_dash/core/updater.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A fake GitHub with a 1.1.0 release for macOS.
MockClient _github(List<int> dmg) {
  const dl = 'https://github.com/koebelt/koebelt_dash/releases/download/app-v1.1.0';
  return MockClient((req) async {
    final u = req.url.toString();
    if (u.contains('api.github.com')) {
      return http.Response(
        jsonEncode([
          {
            'tag_name': 'app-v1.1.0',
            'draft': false,
            'prerelease': false,
            'html_url': 'https://github.com/koebelt/koebelt_dash/releases/tag/app-v1.1.0',
            'body': '## What changed\n\n- **Updates** install themselves from Settings or the top bar.\n- Replay shows alerts on the timeline.\n\n| a | b |\n|---|---|',
            'assets': [
              {'name': 'koebelt-dash-1.1.0-macos.dmg', 'browser_download_url': '$dl/koebelt-dash-1.1.0-macos.dmg'},
              {'name': 'SHA256SUMS', 'browser_download_url': '$dl/SHA256SUMS'},
            ],
          },
        ]),
        200,
      );
    }
    if (u.endsWith('SHA256SUMS')) return http.Response('${sha256.convert(dmg)}  koebelt-dash-1.1.0-macos.dmg\n', 200);
    if (u.endsWith('.dmg')) return http.Response.bytes(dmg, 200);
    return http.Response('', 404);
  });
}

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

  testWidgets('an available update shows in the top bar and Settings, and installs in one click', (tester) async {
    SharedPreferences.setMockInitialValues({});
    if (shots != null) await tester.runAsync(_loadFonts);
    final installed = <String>[];
    final store = Store();
    final dash = Dash(
      store: store,
      updater: Updater(
        store,
        current: '1.0.0',
        os: 'macos',
        enabled: true,
        client: _github(utf8.encode('disk image')),
        installer: (os, f, v) async => installed.add('$os $v'),
        downloadDir: () => Directory.systemTemp.createTemp('kdash-ui-update'),
      ),
    );
    await tester.runAsync(() async {
      await dash.init();
      await dash.updater.check();
    });
    expect(dash.updater.state, UpdateState.available);

    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final key = GlobalKey();
    // Around the whole app, so dialogs are in the screenshots too.
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: MaterialApp(
          theme: ThemeData(brightness: Brightness.dark),
          home: Scaffold(body: DashApp(dash: dash, initial: 'settings')),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    Future<void> shot(String name) async {
      if (shots == null) return;
      await tester.runAsync(() async {
        final b = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final img = await b.toImage(pixelRatio: 1);
        final png = await img.toByteData(format: ui.ImageByteFormat.png);
        await File('$shots/update_$name.png').writeAsBytes(png!.buffer.asUint8List());
      });
    }

    expect(find.text('UPDATE 1.1.0'), findsOneWidget, reason: 'top-bar chip');
    await tester.scrollUntilVisible(find.text('UPDATE TO 1.1.0'), 300, scrollable: find.byType(Scrollable).last);
    expect(find.text('1.1.0 is available.'), findsOneWidget);
    await shot('settings');

    await tester.tap(find.text('UPDATE 1.1.0'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('koebelt dash 1.1.0'), findsOneWidget);
    expect(find.textContaining('install themselves from Settings'), findsOneWidget, reason: 'notes, with the Markdown stripped');
    await shot('dialog');

    await tester.runAsync(() async {
      await tester.tap(find.text('UPDATE NOW'));
      for (var i = 0; i < 50 && installed.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    });
    expect(installed, ['macos 1.1.0']);

    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(dash.disconnectAll);
    await tester.pump(const Duration(seconds: 10));
  });

  testWidgets('no update while a connected device is armed', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = Store();
    final dash = Dash(
      store: store,
      updater: Updater(store, current: '1.0.0', os: 'macos', enabled: true, client: _github(utf8.encode('x')), installer: (os, f, v) async => fail('must not install')),
    );
    await tester.runAsync(() async {
      await dash.init();
      await dash.connect(dash.addSimulated(simTemplates()[0]).id);
      await dash.updater.check();
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    dash.liveTel.armed = true;
    expect(dash.updateBlocked, isTrue);

    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: DashApp(dash: dash, initial: 'settings'))));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('UPDATE 1.1.0'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('DISARM FIRST'), findsOneWidget);
    await tester.tap(find.text('UPDATE NOW'), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 100));
    expect(dash.updater.state, UpdateState.available, reason: 'the button is disabled');

    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(dash.disconnectAll);
    await tester.pump(const Duration(seconds: 10));
  });
}
