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
import 'package:koebelt_dash/core/model.dart';
import 'package:koebelt_dash/core/store.dart';
import 'package:koebelt_dash/core/updater.dart';
import 'package:koebelt_dash/ui/components.dart' show KDialogPanel;
import 'package:shared_preferences/shared_preferences.dart';

/// 2.0.0 drops arduino before 2.0.0; 1.1.0 supports everything.
MockClient _github() {
  const dl = 'https://github.com/koebelt/koebelt_dash/releases/download';
  final dmg = utf8.encode('disk image');
  Map<String, dynamic> rel(String v, String date, List<String> files, String notes) => {
    'tag_name': 'app-v$v',
    'draft': false,
    'prerelease': false,
    'body': notes,
    'html_url': 'https://github.com/koebelt/koebelt_dash/releases/tag/app-v$v',
    'published_at': date,
    'assets': [
      for (final f in files) {'name': f, 'browser_download_url': '$dl/app-v$v/$f'},
    ],
  };
  return MockClient((req) async {
    final u = req.url.toString();
    if (u.contains('api.github.com')) {
      return http.Response(
        jsonEncode([
          rel('2.0.0', '2027-03-02T10:00:00Z', [
            'koebelt-dash-2.0.0-macos.dmg',
            'SHA256SUMS',
            'compat.json',
          ], '## Protocol 2\n- Faster telemetry; needs koebelt/link 2.0.0 on the device.'),
          rel('1.2.0', '2026-12-01T10:00:00Z', ['koebelt-dash-1.2.0-macos.dmg', 'SHA256SUMS', 'compat.json'], '- Small fixes.'),
          rel('1.1.0', '2026-10-16T09:00:00Z', ['koebelt-dash-1.1.0-macos.dmg', 'SHA256SUMS'], '- Updates in one click.'),
          rel('1.0.0', '2026-10-15T22:00:00Z', ['koebelt-dash-1.0.0-macos.dmg'], '- First release.'),
        ]),
        200,
      );
    }
    if (u.contains('app-v2.0.0/compat.json')) return http.Response('{"protocol": 2, "minLib": {"arduino": "2.0.0", "python": "2.0.0", "rust": "2.0.0"}}', 200);
    if (u.endsWith('compat.json')) return http.Response('{"protocol": 1, "minLib": {"arduino": "1.0.0", "python": "1.0.0", "rust": "1.0.0"}}', 200);
    if (u.endsWith('SHA256SUMS')) {
      final v = RegExp(r'app-v([0-9.]+)').firstMatch(u)![1]!;
      return http.Response('${sha256.convert(dmg)}  koebelt-dash-$v-macos.dmg\n', 200);
    }
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

  testWidgets('an update that would leave a device behind says so, and any version can be chosen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    if (shots != null) await tester.runAsync(_loadFonts);
    final installed = <String>[];
    final store = Store();
    final dash = Dash(
      store: store,
      updater: Updater(
        store,
        current: '1.1.0',
        os: 'macos',
        enabled: true,
        client: _github(),
        installer: (os, f, v) async => installed.add(v),
        downloadDir: () => Directory.systemTemp.createTemp('kdash-compat-ui'),
      ),
    );
    await tester.runAsync(() async {
      await dash.init();
      // Two paired devices, as last seen: one on the old Arduino library.
      dash.devices.addAll([
        DeviceInfo(id: 'kite', name: 'Kite', kind: DeviceKind.drone, transport: TransportKind.udp, lib: 'arduino/1.0.0', protocol: 1),
        DeviceInfo(id: 'mule', name: 'Mule', kind: DeviceKind.rover, transport: TransportKind.udp, lib: 'rust/2.0.0', protocol: 1),
      ]);
      await dash.updater.check();
    });
    expect(dash.updater.available!.version, '2.0.0');

    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: MaterialApp(
          theme: ThemeData(brightness: Brightness.dark),
          home: Scaffold(
            body: DashApp(dash: dash, initial: 'settings'),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    Finder inDialog(Finder f) => find.descendant(of: find.byType(KDialogPanel).last, matching: f);
    Future<void> settle() async {
      for (var i = 0; i < 6; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
        await tester.pump(const Duration(milliseconds: 200));
      }
    }

    Future<void> shot(String name) async {
      if (shots == null) return;
      await tester.runAsync(() async {
        final b = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final img = await b.toImage(pixelRatio: 1);
        final png = await img.toByteData(format: ui.ImageByteFormat.png);
        await File('$shots/compat_$name.png').writeAsBytes(png!.buffer.asUint8List());
      });
    }

    // The update dialog warns about Kite, and the button becomes "Update anyway".
    await tester.tap(find.text('UPDATE 2.0.0'));
    await settle();
    expect(find.text('NOT COMPATIBLE WITH ONE OF YOUR DEVICES'), findsOneWidget);
    expect(find.textContaining('Kite: it runs koebelt/link arduino/1.0.0, and this version needs arduino/2.0.0 or later'), findsOneWidget);
    expect(
      find.descendant(of: find.byType(KDialogPanel), matching: find.textContaining('Mule')),
      findsNothing,
      reason: 'Mule already runs rust/2.0.0',
    );
    expect(find.text('UPDATE ANYWAY'), findsOneWidget);
    await shot('update');

    // Choose another version instead: the picker marks each one.
    await tester.tap(find.text('CHOOSE ANOTHER VERSION'));
    await settle();
    await shot('picker');
    expect(inDialog(find.text('Choose a version')), findsOneWidget);
    expect(inDialog(find.text('INSTALLED')), findsOneWidget);
    expect(inDialog(find.text('LATEST')), findsOneWidget);
    expect(inDialog(find.text('Not for Kite')), findsOneWidget, reason: '2.0.0');
    expect(inDialog(find.text('Works with your devices')), findsNWidgets(3), reason: '1.2.0, 1.1.0 (installed) and 1.0.0');

    // 1.2.0 still supports Kite: it installs without a warning.
    await tester.tap(inDialog(find.text('UPDATE')).at(1)); // 2.0.0, then 1.2.0
    await settle();
    expect(inDialog(find.text('koebelt dash 1.2.0')), findsOneWidget);
    expect(find.textContaining('NOT COMPATIBLE'), findsNothing);
    await tester.runAsync(() async {
      await tester.tap(find.text('UPDATE NOW'));
      for (var i = 0; i < 50 && installed.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    });
    expect(installed, ['1.2.0']);

    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(dash.disconnectAll);
    await tester.pump(const Duration(seconds: 10));
  });

  testWidgets('a connected device this version does not support shows in the alert chip', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final dash = Dash();
    await tester.runAsync(() async {
      await dash.init();
      await dash.connect(dash.addSimulated(simTemplates()[0]).id);
    });
    expect(issuesOf(dash).where((i) => i.key.startsWith('compat-')), isEmpty, reason: 'the simulator is always supported');
    final kite = dash.links.values.first;
    kite.compatProblem = dash.compat.copyWith(minLib: {'sim': '9.0.0'}).problem(kite.info.lib, kite.info.protocol);
    final issue = issuesOf(dash).firstWhere((i) => i.key == 'compat-${kite.id}');
    expect(issue.title, '${kite.info.name} · Library too old');
    expect(issue.body, contains('install an older koebelt dash in Settings > Updates'));
    await tester.runAsync(dash.disconnectAll);
    await tester.pump(const Duration(seconds: 10));
  });
}
