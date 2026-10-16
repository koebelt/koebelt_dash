import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:koebelt_dash/core/store.dart';
import 'package:koebelt_dash/core/updater.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _dl = 'https://github.com/koebelt/koebelt_dash/releases/download';

/// 1.0.0 without checksums or compat.json, 1.1.0 with checksums, 2.0.0 with
/// both and a minimum arduino/2.0.0.
MockClient _github() {
  final dmg = utf8.encode('disk image');
  Map<String, dynamic> rel(String v, List<String> files) => {
    'tag_name': 'app-v$v',
    'draft': false,
    'prerelease': false,
    'body': 'notes $v',
    'html_url': 'https://github.com/koebelt/koebelt_dash/releases/tag/app-v$v',
    'published_at': '2026-10-1${v[0]}T10:00:00Z',
    'assets': [
      for (final f in files) {'name': f, 'browser_download_url': '$_dl/app-v$v/$f'},
    ],
  };
  return MockClient((req) async {
    final u = req.url.toString();
    if (u.contains('api.github.com')) {
      return http.Response(
        jsonEncode([
          rel('1.1.0', ['koebelt-dash-1.1.0-macos.dmg', 'koebelt-dash-1.1.0-android.apk', 'SHA256SUMS']),
          rel('2.0.0', ['koebelt-dash-2.0.0-macos.dmg', 'koebelt-dash-2.0.0-android.apk', 'SHA256SUMS', 'compat.json']),
          rel('1.0.0', ['koebelt-dash-1.0.0-macos.dmg']),
          {'tag_name': 'link-v1.0.0', 'draft': false, 'prerelease': false, 'assets': []},
        ]),
        200,
      );
    }
    if (u.endsWith('compat.json')) return http.Response('{"protocol": 2, "minLib": {"arduino": "2.0.0"}}', 200);
    if (u.endsWith('SHA256SUMS')) {
      final v = RegExp(r'app-v([0-9.]+)').firstMatch(u)![1]!;
      return http.Response('${sha256.convert(dmg)}  koebelt-dash-$v-macos.dmg\n', 200);
    }
    if (u.endsWith('.dmg')) return http.Response.bytes(dmg, 200);
    return http.Response('', 404);
  });
}

Future<Updater> _updater({String current = '1.1.0', String os = 'macos', List<String>? installed}) async {
  SharedPreferences.setMockInitialValues({});
  final u = Updater(
    Store()..init(),
    current: current,
    os: os,
    enabled: true,
    client: _github(),
    installer: (os, f, v) async => installed?.add(v),
    downloadDir: () => Directory.systemTemp.createTemp('kdash-versions'),
  );
  await u.check();
  return u;
}

void main() {
  test('lists every app release, newest first, and finds the latest', () async {
    final u = await _updater();
    expect(u.releases.map((r) => r.version), ['2.0.0', '1.1.0', '1.0.0'], reason: 'library releases left out');
    expect(u.latest!.version, '2.0.0');
    expect(u.available!.version, '2.0.0');
  });

  test('reads each release’s compat.json, and treats older ones as supporting everything', () async {
    final u = await _updater();
    final c2 = await u.compatOf(u.releases.first);
    expect(c2!.minLib['arduino'], '2.0.0');
    final c1 = await u.compatOf(u.releases[1]);
    expect(c1!.minLib, isEmpty, reason: '1.1.0 published no compat.json');
  });

  test('says why a version cannot be installed from the app', () async {
    final u = await _updater();
    final byV = {for (final r in u.releases) r.version: r};
    expect(u.cannotInstall(byV['1.1.0']!), contains('the version you have'));
    expect(u.cannotInstall(byV['1.0.0']!), contains('without checksums'));
    expect(u.cannotInstall(byV['2.0.0']!), isNull);

    final android = await _updater(current: '2.0.0', os: 'android');
    final older = android.releases.firstWhere((r) => r.version == '1.1.0');
    expect(android.cannotInstall(older), contains('uninstall'), reason: 'Android refuses to downgrade in place');
  });

  test('installs an older version, and then stops reminding about the newest', () async {
    final installed = <String>[];
    final u = await _updater(current: '2.0.0', installed: installed);
    expect(u.nudge, isFalse);
    await u.install(u.releases.firstWhere((r) => r.version == '1.1.0'));
    expect(installed, ['1.1.0']);
    expect(u.skipped, '2.0.0', reason: 'chosen on purpose: no nagging until a newer release');
  });

  test('refuses a version the app cannot install, without downloading anything', () async {
    final installed = <String>[];
    final u = await _updater(installed: installed);
    await u.install(u.releases.firstWhere((r) => r.version == '1.0.0'));
    expect(installed, isEmpty);
    expect(u.state, UpdateState.failed);
    expect(u.error, contains('without checksums'));
  });
}
