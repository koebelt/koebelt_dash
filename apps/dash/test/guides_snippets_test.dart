// Every guide step marked `complete` is a whole program. This test builds or
// runs each one against the real libraries in libs/, so the guides cannot
// drift from the APIs. Each language is skipped when its toolchain is missing.
@TestOn('vm')
@Timeout(Duration(minutes: 5))
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:koebelt_dash/screens/guides_data.dart';

final root = Directory('../..').absolute.path;
final work = Directory.systemTemp.createTempSync('kl-guides');

/// (guide id, step index, platform, language, code) for every complete step.
List<(String, int, String, String, String)> examples() => [
  for (final g in [quickstart('ABC-123'), ...guides])
    for (final (i, s) in g.steps.indexed)
      if (s.complete)
        for (final e in s.c.entries) (g.id, i, e.key, e.value[0], e.value[1]),
];

bool has(String exe) => Process.runSync('which', [exe]).exitCode == 0;

void main() {
  final all = examples();

  test('every device kind has a complete example', () {
    final kinds = {
      for (final g in guides)
        if (g.kind != null && g.steps.any((s) => s.complete)) g.kind,
    };
    expect(kinds, containsAll(['drone', 'rover', 'arm', 'rocket', 'bench', 'generic']));
    expect(all.where((e) => e.$4 == 'cpp'), isNotEmpty);
  });

  test('Arduino examples compile and run setup/loop on the host', () {
    final ard = '$root/libs/arduino/KoebeltLink';
    final cpp = all.where((e) => e.$4 == 'cpp').toList();
    final failures = <String>[];
    for (final (id, i, _, _, code) in cpp) {
      final name = '${id}_$i';
      final f = File('${work.path}/$name.cpp')
        ..writeAsStringSync(
          '// The Arduino IDE adds this include to every sketch.\n#include <Arduino.h>\n$code\n\nuint32_t g_millis = 0;\nint main() {\n  setup();\n  for (int i = 0; i < 20; i++) { g_millis += 20; loop(); }\n  return 0;\n}\n',
        );
      final out = '${work.path}/$name';
      final r = Process.runSync('c++', [
        '-std=c++17',
        '-Wno-unused-parameter',
        '-I$ard/test/shim',
        '-I$ard/src',
        '$ard/src/KoebeltLink.cpp',
        '$ard/src/KoebeltLink_platform.cpp',
        f.path,
        '-o',
        out,
      ]);
      if (r.exitCode != 0) {
        failures.add('$name: ${(r.stderr as String).split('\n').where((l) => l.contains('error')).take(4).join('\n')}');
        continue;
      }
      final run = Process.runSync(out, []);
      if (run.exitCode != 0) failures.add('$name exited with ${run.exitCode}');
    }
    expect(failures, isEmpty, reason: failures.join('\n\n'));
  }, skip: has('c++') ? false : 'no C++ compiler');

  test('Rust examples build against the crate', () {
    final rs = all.where((e) => e.$4 == 'rust').toList();
    final crate = Directory('${work.path}/rust')..createSync();
    File('${crate.path}/Cargo.toml').writeAsStringSync('''
[package]
name = "guide-examples"
version = "0.0.0"
edition = "2024"
publish = false

[dependencies]
koebelt-link = { path = "$root/libs/rust" }
''');
    Directory('${crate.path}/src').createSync();
    File('${crate.path}/src/lib.rs').writeAsStringSync('');
    Directory('${crate.path}/examples').createSync();
    for (final (id, i, _, _, code) in rs) {
      File('${crate.path}/examples/${id.replaceAll('-', '_')}_$i.rs').writeAsStringSync(code);
    }
    final r = Process.runSync('cargo', [
      'build',
      '--examples',
      '--quiet',
      '--target-dir',
      '$root/libs/rust/target/guide-examples',
    ], workingDirectory: crate.path);
    expect(r.exitCode, 0, reason: '${r.stderr}');
  }, skip: has('cargo') ? false : 'no cargo');

  final py = File('$root/libs/python/.venv/bin/python');
  test('Python examples run against the library', () {
    final failures = <String>[];
    for (final (id, i, _, _, code) in all.where((e) => e.$4 == 'python')) {
      final f = File('${work.path}/${id}_$i.py')..writeAsStringSync(code);
      final r = Process.runSync(py.path, ['$root/libs/python/tests/run_guide_example.py', f.path]);
      if (r.exitCode != 0) failures.add('${id}_$i:\n${(r.stderr as String).trim().split('\n').reversed.take(6).toList().reversed.join('\n')}');
    }
    expect(failures, isEmpty, reason: failures.join('\n\n'));
  }, skip: py.existsSync() ? false : 'python venv not set up (libs/python)');

  test('ROS 2 configs only use keys the bridge understands', () {
    const check = r'''
import sys, yaml
top = {"name", "kind", "model", "transport", "fallback", "port", "sensors", "controls", "safety", "params", "channels", "video"}
sensors = {"imu", "lidar", "joints", "power", "odom", "gps"}
controls = {"twist", "jog", "mode", "max_linear", "max_angular", "joint_names"}
safety = {"stop_service", "failsafe_timeout", "failsafe_action"}
for path in sys.argv[1:]:
    c = yaml.safe_load(open(path))
    bad = (set(c) - top) | (set(c.get("sensors") or {}) - sensors) | (set(c.get("controls") or {}) - controls) | (set(c.get("safety") or {}) - safety)
    assert not bad, f"{path}: unknown keys {sorted(bad)}"
    assert c.get("kind") in ("drone", "rover", "arm", "rocket", "bench", "generic"), path
    assert set(c.get("video") or {}) <= {"topic", "port", "label"}, path
    for ch in c.get("channels") or []:
        assert {"id", "topic"} <= set(ch), f"{path}: channel needs id and topic"
''';
    final files = <String>[];
    for (final (id, i, _, _, code) in all.where((e) => e.$4 == 'yaml')) {
      files.add((File('${work.path}/${id}_$i.yaml')..writeAsStringSync(code)).path);
    }
    files.add('$root/libs/ros2/koebelt_link_ros/config/device.yaml');
    final r = Process.runSync(py.path, ['-c', check, ...files]);
    expect(r.exitCode, 0, reason: '${r.stderr}');
  }, skip: py.existsSync() ? false : 'python venv not set up (libs/python)');
}
