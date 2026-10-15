import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// koebelt dash 1.0.0 ran in the macOS App Sandbox, which keeps settings and
/// recordings in ~/Library/Containers/com.koebelt.dash. Later versions update
/// themselves and run outside it, where the same data lives in ~/Library. On
/// the first launch outside the sandbox this copies it across, once; the old
/// container is left untouched.
///
/// Must run before SharedPreferences is first used. The files are read here,
/// in this process: macOS only lets the app that owns a container read it.
Future<void> migrateFromSandbox() async {
  if (!Platform.isMacOS || Platform.environment.containsKey('APP_SANDBOX_CONTAINER_ID')) return;
  try {
    final home = Platform.environment['HOME'];
    if (home == null) return;
    final container = '$home/Library/Containers/com.koebelt.dash/Data/Library';
    if (!Directory(container).existsSync()) return;
    final support = await getApplicationSupportDirectory();
    final marker = File('${support.path}/.migrated-from-sandbox');
    if (marker.existsSync()) return;

    // Preferences: only into an empty domain, so nothing newer is overwritten.
    final plist = File('$container/Preferences/com.koebelt.dash.plist');
    final has = await Process.run('/usr/bin/defaults', ['read', 'com.koebelt.dash']);
    if (plist.existsSync() && has.exitCode != 0) {
      final tmp = File('${Directory.systemTemp.path}/kdash-prefs-${DateTime.now().microsecondsSinceEpoch}.plist');
      await tmp.writeAsBytes(await plist.readAsBytes());
      await Process.run('/usr/bin/defaults', ['import', 'com.koebelt.dash', tmp.path]);
      await tmp.delete();
    }

    // Recordings and other files: copied where nothing exists yet.
    final old = Directory('$container/Application Support/com.koebelt.dash');
    if (old.existsSync()) {
      await for (final e in old.list(recursive: true, followLinks: false)) {
        if (e is! File) continue;
        final dest = File('${support.path}${e.path.substring(old.path.length)}');
        if (dest.existsSync()) continue;
        await dest.parent.create(recursive: true);
        await e.copy(dest.path);
      }
    }
    await support.create(recursive: true);
    await marker.writeAsString(DateTime.now().toIso8601String());
  } catch (e) {
    // Not fatal: the app starts with fresh settings and the old data stays put.
    debugPrint('sandbox migration skipped: $e');
  }
}
