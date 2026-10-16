import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../link/protocol.dart' show appVersion;
import 'compat.dart';
import 'store.dart';
import 'updater_install.dart';

export 'compat.dart' show compareVersions;

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

class AppRelease {
  AppRelease({required this.version, required this.notes, required this.url, required this.assets, this.date});
  final String version, notes, url;

  /// Asset file name to download URL.
  final Map<String, String> assets;
  final DateTime? date;

  /// 1.0.0 published none, so the app cannot verify (or install) it.
  bool get hasChecksums => assets.containsKey('SHA256SUMS');

  /// Which libraries it works with (core/compat.dart); none before 1.2.0.
  String? get compatUrl => assets['compat.json'];
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

  /// The newest release newer than this one, with this platform's file.
  AppRelease? available;

  /// Every app release, newest first, for choosing a version in Settings.
  List<AppRelease> releases = const [];

  /// The release being downloaded or installed (any version, not only [available]).
  AppRelease? installing;
  final Map<String, Future<Compat?>> _compat = {};
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
      final all = <AppRelease>[];
      for (final j in (jsonDecode(r.body) as List).cast<Map<String, dynamic>>()) {
        final tag = j['tag_name'] as String? ?? '';
        if (!tag.startsWith(_tagPrefix) || j['draft'] == true || j['prerelease'] == true) continue;
        all.add(
          AppRelease(
            version: tag.substring(_tagPrefix.length),
            notes: j['body'] as String? ?? '',
            url: j['html_url'] as String? ?? 'https://github.com/$_repo/releases',
            date: DateTime.tryParse(j['published_at'] as String? ?? ''),
            assets: {for (final a in (j['assets'] as List? ?? const []).cast<Map>()) '${a['name']}': '${a['browser_download_url']}'},
          ),
        );
      }
      releases = all..sort((a, b) => compareVersions(b.version, a.version));
      lastCheck = DateTime.now();
      // Only a release that has this platform's file counts.
      final best = latest;
      if (best != null && compareVersions(best.version, current) > 0) {
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

  /// The newest release with this platform's file.
  AppRelease? get latest => releases.where((r) => r.assets.containsKey(assetFor(r.version, os))).firstOrNull;

  /// Which libraries [r] works with, from its compat.json; [Compat.legacy] for
  /// releases from before it was published, null when it could not be read.
  Future<Compat?> compatOf(AppRelease r) => _compat[r.version] ??= () async {
    final url = r.compatUrl;
    if (url == null) return Compat.legacy;
    try {
      return Compat.parse(await _getText(url));
    } catch (_) {
      _compat.remove(r.version);
      return null;
    }
  }();

  /// Why [r] cannot be installed from the app, or null when it can.
  String? cannotInstall(AppRelease r) {
    if (r.version == current) return 'This is the version you have.';
    if (!r.assets.containsKey(assetFor(r.version, os))) return 'This release has no $os version.';
    if (!r.hasChecksums) return 'It was published without checksums, so the app cannot check it. Download it from GitHub instead.';
    if (os == 'android' && compareVersions(r.version, current) < 0) {
      return 'Android does not install an older version over a newer one. To go back, uninstall koebelt dash (its data on this phone goes with it), then install the older APK from GitHub.';
    }
    return null;
  }

  /// Downloads a release ([available] by default, or any version chosen in
  /// Settings), checks it against the release's SHA256SUMS and installs it.
  /// On the desktop the app quits and that version starts; on Android the
  /// system installer takes over.
  Future<void> install([AppRelease? which]) async {
    final rel = which ?? available;
    if (rel == null || state == UpdateState.downloading || state == UpdateState.installing) return;
    if (cannotInstall(rel) case final why?) {
      error = why;
      state = UpdateState.failed;
      notifyListeners();
      return;
    }
    final name = assetFor(rel.version, os)!;
    installing = rel;
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
      // Chosen on purpose: no reminder about a newer one until there is another.
      final newest = latest;
      if (newest != null && compareVersions(rel.version, newest.version) < 0) {
        skipped = newest.version;
        _save();
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
