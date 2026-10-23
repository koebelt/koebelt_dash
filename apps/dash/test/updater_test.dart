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

Map<String, dynamic> _release(String tag, {List<String> files = const [], bool draft = false, bool pre = false}) => {
  'tag_name': tag,
  'draft': draft,
  'prerelease': pre,
  'body': '## What changed\n- Updates install themselves',
  'html_url': 'https://github.com/koebelt/koebelt_dash/releases/tag/$tag',
  'published_at': '2026-11-02T10:00:00Z',
  'assets': [
    for (final f in files) {'name': f, 'browser_download_url': '$_dl/$tag/$f'},
  ],
};

/// A fake GitHub: the releases list, one installer file and its checksums.
MockClient _github({required List<Map<String, dynamic>> releases, List<int>? file, String? sums}) => MockClient((req) async {
  final u = req.url.toString();
  if (u.startsWith('https://api.github.com/repos/koebelt/koebelt_dash/releases')) return http.Response(jsonEncode(releases), 200);
  if (u.endsWith('/SHA256SUMS') && sums != null) return http.Response(sums, 200);
  if (u.endsWith('.dmg') && file != null) return http.Response.bytes(file, 200);
  return http.Response('not found', 404);
});

Future<Store> _store() async {
  SharedPreferences.setMockInitialValues({});
  return Store()..init();
}

void main() {
  test('versions compare numerically', () {
    expect(compareVersions('1.10.0', '1.9.2'), 1);
    expect(compareVersions('1.0.0', '1.0'), 0);
    expect(compareVersions('1.0.0', '1.0.1'), -1);
  });

  test('finds the newest app release that has this platform\'s file', () async {
    final u = Updater(
      await _store(),
      current: '1.0.0',
      os: 'macos',
      enabled: true,
      client: _github(
        releases: [
          _release('link-v1.4.0'), // a library release, not the app
          _release('app-v1.3.0', files: ['koebelt-dash-1.3.0-macos.dmg'], draft: true),
          _release('app-v1.2.0', files: ['koebelt-dash-1.2.0-macos.dmg'], pre: true),
          _release('app-v1.1.0', files: ['koebelt-dash-1.1.0-macos.dmg', 'SHA256SUMS']),
          _release('app-v1.0.0', files: ['koebelt-dash-1.0.0-macos.dmg']),
        ],
      ),
    );
    await u.check();
    expect(u.state, UpdateState.available);
    expect(u.available!.version, '1.1.0');
    expect(u.nudge, isTrue);

    u.skip();
    expect(u.nudge, isFalse, reason: 'a skipped version stops reminding');
  });

  test('betas: offered only after opting in, or to someone running one; the release always wins', () async {
    List<Map<String, dynamic>> rel(List<String> vs) => [
      for (final v in vs) _release('app-v$v', files: ['koebelt-dash-$v-macos.dmg'], pre: v.contains('-')),
    ];
    final stable = Updater(await _store(), current: '1.2.3', os: 'macos', enabled: true, client: _github(releases: rel(['1.3.0-beta.1', '1.2.3'])));
    await stable.check();
    expect(stable.state, UpdateState.upToDate, reason: 'a stable user is not offered a beta');
    expect(stable.betas, isFalse);
    stable.setBetas(true);
    await stable.check();
    expect(stable.available!.version, '1.3.0-beta.1');

    final tester = Updater(await _store(), current: '1.3.0-beta.1', os: 'macos', enabled: true, client: _github(releases: rel(['1.3.0-beta.2', '1.3.0-beta.1'])));
    expect(tester.betas, isTrue, reason: 'running a beta');
    await tester.check();
    expect(tester.available!.version, '1.3.0-beta.2');

    final done = Updater(await _store(), current: '1.3.0-beta.2', os: 'macos', enabled: true, client: _github(releases: rel(['1.3.0', '1.3.0-beta.2'])));
    await done.check();
    expect(done.available!.version, '1.3.0', reason: 'the release after its betas');
  });

  test('up to date when the newest release is this one, or lacks this platform', () async {
    final u = Updater(
      await _store(),
      current: '1.1.0',
      os: 'linux',
      enabled: true,
      client: _github(
        releases: [
          _release('app-v1.2.0', files: ['koebelt-dash-1.2.0-macos.dmg']),
          _release('app-v1.1.0', files: ['koebelt-dash-1.1.0-linux-x64.tar.gz']),
        ],
      ),
    );
    await u.check();
    expect(u.state, UpdateState.upToDate);
  });

  test('builds without the GitHub channel never check', () async {
    var asked = false;
    final u = Updater(
      await _store(),
      enabled: false,
      client: MockClient((_) async {
        asked = true;
        return http.Response('[]', 200);
      }),
    );
    await u.check();
    expect(asked, isFalse);
    expect(u.state, UpdateState.idle);
  });

  group('install', () {
    final bytes = utf8.encode('a notarized disk image');
    final good = '${sha256.convert(bytes)}  koebelt-dash-1.1.0-macos.dmg\n';
    final releases = [
      _release('app-v1.1.0', files: ['koebelt-dash-1.1.0-macos.dmg', 'SHA256SUMS']),
    ];

    Future<(Updater, List<String>)> ready(String? sums, {List<Map<String, dynamic>>? rel}) async {
      final installed = <String>[];
      final u = Updater(
        await _store(),
        current: '1.0.0',
        os: 'macos',
        enabled: true,
        client: _github(releases: rel ?? releases, file: bytes, sums: sums),
        installer: (os, File f, v) async => installed.add('$os ${f.path.split('/').last} $v ${f.readAsStringSync()}'),
        downloadDir: () => Directory.systemTemp.createTemp('kdash-update-test'),
      );
      await u.check();
      return (u, installed);
    }

    test('downloads, verifies the checksum, then installs', () async {
      final (u, installed) = await ready(good);
      await u.install();
      expect(u.error, isNull);
      expect(installed, ['macos koebelt-dash-1.1.0-macos.dmg 1.1.0 a notarized disk image']);
      expect(u.progress, 1);
    });

    test('a file that does not match the checksum is not installed', () async {
      final (u, installed) = await ready('${'0' * 64}  koebelt-dash-1.1.0-macos.dmg\n');
      await u.install();
      expect(installed, isEmpty);
      expect(u.state, UpdateState.failed);
      expect(u.error, contains('does not match'));
    });

    test('a release without checksums is not installed', () async {
      final (u, installed) = await ready(null, rel: [
        _release('app-v1.1.0', files: ['koebelt-dash-1.1.0-macos.dmg']),
      ]);
      await u.install();
      expect(installed, isEmpty);
      expect(u.error, contains('without checksums'));
    });
  });
}
