import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../link/protocol.dart' show appVersion;
import 'store.dart';
import 'updater_install.dart';

/// Which builds update themselves: the release workflow passes
/// `--dart-define=KDASH_UPDATES=github` to the macOS, Windows, Linux and
/// Android builds it publishes on GitHub. Store builds (TestFlight, later the
/// App Store and Google Play) and development builds leave it empty and never
/// check: their store updates them, or you do.
const updateChannel = String.fromEnvironment('KDASH_UPDATES');

const _repo = 'koebelt/koebelt_dash';
const _tagPrefix = 'app-v';
const _checkEvery = Duration(hours: 24);

/// The release asset for this platform, as app-release.yml names it.
String? assetFor(String version, String os) => switch (os) {
  'macos' => 'koebelt-dash-$version-macos.dmg',
  'windows' => 'koebelt-dash-$version-windows-x64-setup.exe',
  'linux' => 'koebelt-dash-$version-linux-x64.tar.gz',
  'android' => 'koebelt-dash-$version-android.apk',
  _ => null,
};

/// Compares dotted versions numerically: 1.10.0 > 1.9.2.
int compareVersions(String a, String b) {
  List<int> parts(String v) => [for (final p in v.split('.')) int.tryParse(p) ?? 0];
  final x = parts(a), y = parts(b);
  for (var i = 0; i < x.length || i < y.length; i++) {
    final d = (i < x.length ? x[i] : 0) - (i < y.length ? y[i] : 0);
    if (d != 0) return d.sign;
  }
  return 0;
}

class AppRelease {
  AppRelease({required this.version, required this.notes, required this.url, required this.assets, this.date});
  final String version, notes, url;

  /// Asset file name to download URL.
  final Map<String, String> assets;
  final DateTime? date;
}

enum UpdateState { idle, checking, upToDate, available, downloading, installing, failed }

/// Finds newer releases on GitHub and installs them in one step: download,
/// check the SHA-256 the release publishes, then hand over to the platform
/// (updater_install.dart), which swaps the app and starts it again.
class Updater extends ChangeNotifier {
  Updater(this.store, {http.Client? client, this.current = appVersion, String? os, bool? enabled, this.installer, this.downloadDir})
    : _client = client ?? http.Client(),
      os = os ?? Platform.operatingSystem,
      enabled = enabled ?? (updateChannel == 'github' && assetFor('0', Platform.operatingSystem) != null);

  final Store store;
  final http.Client _client;
  final String current, os;

  /// False in builds that do not update themselves (see [updateChannel]).
  final bool enabled;

  /// Replace [installUpdate] and [updateDownloadDir] in tests.
  final Future<void> Function(String os, File file, String version)? installer;
  final Future<Directory> Function()? downloadDir;

  UpdateState state = UpdateState.idle;
  AppRelease? available;
  double progress = 0;
  String? error;
  DateTime? lastCheck;

  /// Check at launch and once a day. Off: only when asked, in Settings.
  bool auto = true;

  /// A version the user chose to skip: no reminder until a newer one.
  String? skipped;

  Timer? _timer;

  void load() {
    final j = store.readJson('kdash-updates-v1');
    if (j is Map) {
      auto = j['auto'] as bool? ?? true;
      skipped = j['skipped'] as String?;
    }
  }

  void _save() => store.writeJson('kdash-updates-v1', {'auto': auto, 'skipped': ?skipped});

  void setAuto(bool v) {
    auto = v;
    _save();
    _schedule();
    notifyListeners();
  }

  /// Starts the daily check; the first one waits a few seconds so it never
  /// competes with connecting to a device at launch.
  void start({Duration delay = const Duration(seconds: 8)}) {
    if (!enabled) return;
    load();
    _timer?.cancel();
    if (auto) _timer = Timer(delay, () => unawaited(check()));
  }

  void _schedule() {
    _timer?.cancel();
    if (enabled && auto) _timer = Timer(_checkEvery, () => unawaited(check()));
  }

  /// Whether to show the update outside Settings (top bar, toast).
  bool get nudge => state == UpdateState.available && available != null && available!.version != skipped;

  void skip() {
    skipped = available?.version;
    _save();
    notifyListeners();
  }

  Future<void> check() async {
    if (!enabled || state == UpdateState.downloading || state == UpdateState.installing) return;
    state = UpdateState.checking;
    error = null;
    notifyListeners();
    try {
      final r = await _client
          .get(
            Uri.parse('https://api.github.com/repos/$_repo/releases?per_page=20'),
            headers: {'Accept': 'application/vnd.github+json', 'User-Agent': 'koebelt-dash/$current'},
          )
          .timeout(const Duration(seconds: 15));
      if (r.statusCode != 200) throw HttpException('GitHub answered ${r.statusCode}');
      AppRelease? best;
      for (final j in (jsonDecode(r.body) as List).cast<Map<String, dynamic>>()) {
        final tag = j['tag_name'] as String? ?? '';
        if (!tag.startsWith(_tagPrefix) || j['draft'] == true || j['prerelease'] == true) continue;
        final v = tag.substring(_tagPrefix.length);
        if (best != null && compareVersions(v, best.version) <= 0) continue;
        best = AppRelease(
          version: v,
          notes: j['body'] as String? ?? '',
          url: j['html_url'] as String? ?? 'https://github.com/$_repo/releases',
          date: DateTime.tryParse(j['published_at'] as String? ?? ''),
          assets: {for (final a in (j['assets'] as List? ?? const []).cast<Map>()) '${a['name']}': '${a['browser_download_url']}'},
        );
      }
      lastCheck = DateTime.now();
      // Only a release that has this platform's file counts.
      final file = best == null ? null : assetFor(best.version, os);
      if (best != null && compareVersions(best.version, current) > 0 && best.assets.containsKey(file)) {
        available = best;
        state = UpdateState.available;
      } else {
        available = null;
        state = UpdateState.upToDate;
      }
    } catch (e) {
      error = 'Could not check for updates: ${e is TimeoutException ? 'no answer from GitHub' : e}';
      state = UpdateState.failed;
    }
    _schedule();
    notifyListeners();
  }

  /// Downloads the update, checks it against the release's SHA256SUMS and
  /// installs it. On the desktop the app quits and the new version starts;
  /// on Android the system installer takes over.
  Future<void> install() async {
    final rel = available;
    if (rel == null || state == UpdateState.downloading || state == UpdateState.installing) return;
    final name = assetFor(rel.version, os)!;
    state = UpdateState.downloading;
    progress = 0;
    error = null;
    notifyListeners();
    try {
      final sums = rel.assets['SHA256SUMS'];
      if (sums == null) throw const UpdateError('This release has no checksums, so it cannot be verified. Download it from GitHub instead.');
      final expected = _sumFor(await _getText(sums), name);
      if (expected == null) throw UpdateError('$name is missing from the release checksums.');
      final dir = await (downloadDir ?? updateDownloadDir)();
      final file = File('${dir.path}/$name');
      final digest = await _download(rel.assets[name]!, file);
      if (digest != expected) {
        await file.delete();
        throw const UpdateError('The download does not match the release checksum. Nothing was installed.');
      }
      state = UpdateState.installing;
      notifyListeners();
      await (installer ?? installUpdate)(os, file, rel.version);
      // Android: the system installer is on screen; desktop: the app is
      // quitting. Either way the next state is a fresh launch.
    } catch (e) {
      error = e is UpdateError ? e.message : 'Update failed: $e';
      state = UpdateState.failed;
      notifyListeners();
    }
  }

  Future<String> _getText(String url) async {
    final r = await _client.get(Uri.parse(url), headers: {'User-Agent': 'koebelt-dash/$current'}).timeout(const Duration(seconds: 30));
    if (r.statusCode != 200) throw HttpException('GitHub answered ${r.statusCode}');
    return r.body;
  }

  static String? _sumFor(String sums, String name) {
    for (final line in const LineSplitter().convert(sums)) {
      final m = RegExp(r'^([0-9a-fA-F]{64})\s+\*?(.+)$').firstMatch(line.trim());
      if (m != null && m.group(2) == name) return m.group(1)!.toLowerCase();
    }
    return null;
  }

  /// Streams to [file], reporting progress, and returns its SHA-256.
  Future<String> _download(String url, File file) async {
    final res = await _client.send(http.Request('GET', Uri.parse(url))..headers['User-Agent'] = 'koebelt-dash/$current');
    if (res.statusCode != 200) throw HttpException('GitHub answered ${res.statusCode}');
    final total = res.contentLength ?? 0;
    final sink = file.openWrite();
    final hash = _DigestSink();
    final hasher = sha256.startChunkedConversion(hash);
    var got = 0, last = 0.0;
    await for (final chunk in res.stream.timeout(const Duration(seconds: 60))) {
      sink.add(chunk);
      hasher.add(chunk);
      got += chunk.length;
      if (total > 0) {
        progress = got / total;
        if (progress - last >= .01) {
          last = progress;
          notifyListeners();
        }
      }
    }
    await sink.close();
    hasher.close();
    return hash.value.toString();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

class _DigestSink implements Sink<Digest> {
  late Digest value;
  @override
  void add(Digest data) => value = data;
  @override
  void close() {}
}
