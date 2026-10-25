// What a real Python says its modules hold. Needs a Python: the development
// venv in libs/python-dash-scripts/.venv, or KDASH_SCRIPTS_PYTHON.
@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:koebelt_dash/scripts/introspect.dart';

String? _python() {
  final env = Platform.environment['KDASH_SCRIPTS_PYTHON'];
  if (env != null) return env;
  final venv = File('../../libs/python-dash-scripts/.venv/bin/python');
  return venv.existsSync() ? venv.absolute.path : null;
}

void main() {
  final python = _python();

  Future<Map<String, Member>?> members(PythonIntrospector p, String path) async {
    for (var i = 0; i < 200; i++) {
      final m = p.membersOf(path);
      if (m != null || p.errors.containsKey(path)) return m;
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    return null;
  }

  test(
    'modules, submodules and classes, with signatures and docs',
    () async {
      final p = PythonIntrospector(python!);
      final json = (await members(p, 'json'))!;
      expect(json['dumps']!.kind, 'function');
      expect(json['dumps']!.sig, startsWith('(obj'));
      expect(json['dumps']!.doc, isNotEmpty);
      expect(json.keys.where((k) => k.startsWith('_')), isEmpty, reason: 'no private names');
      expect((await members(p, 'os.path'))!['join']!.kind, 'function');
      expect((await members(p, 'collections.OrderedDict'))!.keys, contains('popitem'), reason: 'a class\'s members');
      expect(await members(p, 'no_such_module_kdash'), isNull);
      expect(p.errors['no_such_module_kdash'], contains('no module'));
      p.needModules();
      for (var i = 0; i < 200 && p.installed == null; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      // (An editable install, as in the development venv, is not listed: the
      // editor always offers koebelt_dash_scripts itself.)
      expect(p.installed, containsAll(['json', 'websockets']));
    },
    skip: python == null ? 'no Python' : false,
    timeout: const Timeout(Duration(seconds: 60)),
  );

  test(
    'a whole docstring, for the hover card',
    () async {
      final p = PythonIntrospector(python!);
      Member? d;
      for (var i = 0; i < 200 && !p.docs.containsKey('json.dumps'); i++) {
        d = p.docOf('json.dumps');
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      d = p.docOf('json.dumps');
      expect(d!.kind, 'function');
      expect(d.doc.split('\n').length, greaterThan(5), reason: 'more than the first line');
      for (var i = 0; i < 200 && !p.docs.containsKey('builtins.nope_kdash'); i++) {
        p.docOf('builtins.nope_kdash');
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      expect(p.docOf('builtins.nope_kdash'), isNull);
    },
    skip: python == null ? 'no Python' : false,
    timeout: const Timeout(Duration(seconds: 60)),
  );

  test(
    'which imports a Python lacks, modules next to the script counting',
    () async {
      final p = PythonIntrospector(python!);
      final dir = Directory.systemTemp.createTempSync('kdash_imports');
      File('${dir.path}/helpers_kdash.py').writeAsStringSync('X = 1\n');
      List<String>? miss;
      for (var i = 0; i < 200 && miss == null; i++) {
        miss = p.missing(['json', 'helpers_kdash', 'no_such_module_kdash'], dir.path);
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      expect(miss, ['no_such_module_kdash']);
      dir.deleteSync(recursive: true);
    },
    skip: python == null ? 'no Python' : false,
    timeout: const Timeout(Duration(seconds: 60)),
  );
}
