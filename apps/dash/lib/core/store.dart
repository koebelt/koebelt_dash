import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'io_files.dart' as files;

/// Small persistence layer: preferences for settings/devices/layouts,
/// JSON files for recordings (preferences if the files directory is unavailable).
class Store {
  Store({this.recordingsRoot});

  /// Folder for recordings instead of the app's support directory (tests).
  final String? recordingsRoot;
  SharedPreferences? _p;

  Future<void> init() async {
    try {
      _p = await SharedPreferences.getInstance();
    } catch (e) {
      debugPrint('prefs unavailable: $e');
    }
  }

  dynamic readJson(String key) {
    final s = _p?.getString(key);
    if (s == null) return null;
    try {
      return jsonDecode(s);
    } catch (_) {
      return null;
    }
  }

  void writeJson(String key, Object? v) {
    if (v == null) {
      _p?.remove(key);
    } else {
      _p?.setString(key, jsonEncode(v));
    }
  }

  /// Where recordings (and their video) live; null when the platform has
  /// no files directory.
  Future<String?> recordingsDir() => _dir();

  Future<String?> _dir() async {
    if (recordingsRoot != null) return recordingsRoot;
    try {
      return '${(await getApplicationSupportDirectory()).path}/recordings';
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> loadRecordings() async {
    final d = await _dir();
    if (d == null) {
      final l = readJson('kdash-recordings-v1');
      return l is List ? l.cast<Map<String, dynamic>>() : [];
    }
    return files.readAll(d);
  }

  Future<void> saveRecording(Map<String, dynamic> r) async {
    final d = await _dir();
    if (d == null) {
      final l = (readJson('kdash-recordings-v1') as List?) ?? [];
      writeJson('kdash-recordings-v1', [r, ...l].take(5).toList());
      return;
    }
    await files.writeCompressed(d, '${r['id']}.json', jsonEncode(r));
  }

  Future<void> deleteRecording(String id, {String? video}) async {
    final d = await _dir();
    if (d == null) {
      final l = (readJson('kdash-recordings-v1') as List?) ?? [];
      writeJson('kdash-recordings-v1', l.where((e) => e['id'] != id).toList());
      return;
    }
    await files.delete(d, '$id.json');
    await files.delete(d, video ?? '$id.kdv'); // its video, if any
  }
}
