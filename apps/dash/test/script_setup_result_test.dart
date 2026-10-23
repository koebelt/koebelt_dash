@TestOn('mac-os || linux')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:koebelt_dash/core/dash.dart';
import 'package:koebelt_dash/scripts/script_hub.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A stand-in "python": answers the version probe, and pip as told.
Future<String> _fakePython(Directory dir, {required bool pipWorks}) async {
  final f = File('${dir.path}/python');
  await f.writeAsString('''#!/bin/sh
if [ "\$1" = "-c" ]; then echo "3.12.0 1.3.0b3"; exit 0; fi
if [ "\$2" = "pip" ]; then
  ${pipWorks ? 'echo "Successfully installed koebelt-dash-scripts-1.3.0b3"; exit 0' : 'echo "ERROR: No matching distribution found" >&2; exit 1'}
fi
''');
  await Process.run('chmod', ['+x', f.path]);
  return f.path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a successful update says so for a few seconds, then the message goes', () async {
    SharedPreferences.setMockInitialValues({});
    final d = Dash();
    await d.init();
    final py = await _fakePython(await Directory.systemTemp.createTemp('kdash-py'), pipWorks: true);
    await d.scripts.installInto(py, upgrade: true);
    expect(d.scripts.setupResult?.ok, isTrue);
    expect(d.scripts.setupResult?.text, 'koebelt-dash-scripts 1.3.0-beta.3 is up to date in this Python.');
    await Future<void>.delayed(ScriptHub.resultShown + const Duration(milliseconds: 300));
    expect(d.scripts.setupResult, isNull, reason: 'gone after a few seconds');
  });

  test('a failed one stays, with pip’s reason, until dismissed', () async {
    SharedPreferences.setMockInitialValues({});
    final d = Dash();
    await d.init();
    final py = await _fakePython(await Directory.systemTemp.createTemp('kdash-py'), pipWorks: false);
    await d.scripts.installInto(py, upgrade: true);
    expect(d.scripts.setupResult?.ok, isFalse);
    expect(d.scripts.setupResult?.text, contains('No matching distribution'));
    await Future<void>.delayed(ScriptHub.resultShown + const Duration(milliseconds: 300));
    expect(d.scripts.setupResult, isNotNull, reason: 'a failure stays');
    d.scripts.dismissResult();
    expect(d.scripts.setupResult, isNull);
  });
}
