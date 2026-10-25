// Check, with a real Python: the development venv in
// libs/python-dash-scripts/.venv (koebelt-dash-scripts installed), or
// KDASH_SCRIPTS_PYTHON.
@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:koebelt_dash/scripts/check.dart';

String? _python() {
  final env = Platform.environment['KDASH_SCRIPTS_PYTHON'];
  if (env != null) return env;
  final venv = File('../../libs/python-dash-scripts/.venv/bin/python');
  return venv.existsSync() ? venv.absolute.path : null;
}

void main() {
  final python = _python();
  final skip = python == null ? 'no Python' : false;

  test('a script that builds: nothing to say', () async {
    final r = await checkScript(python!, '''
import json
from koebelt_dash_scripts import connect, every

dev = connect()
for t in every(0.05):
    dev.sticks(throttle=0.2)
    print(json.dumps({"t": t}))
''');
    expect(r, isEmpty);
    expect(describeCheck(r!), contains('it compiles'));
  }, skip: skip);

  test(
    'what would stop it, each on its line',
    () async {
      final dir = Directory.systemTemp.createTempSync('kdash_check');
      File('${dir.path}/helpers_kdash.py').writeAsStringSync('X = 1\n');
      final r = (await checkScript(python!, '''
import no_such_module_kdash
import helpers_kdash
from koebelt_dash_scripts import connect, pidd

try:
    import also_missing_kdash
except ImportError:
    pass

dev = connect()
dev.goto()
dev.run_sequence("x", wiat=True)
dev.flyy()
pritn(helpers_kdash.X)
''', folder: dir.path))!;
      dir.deleteSync(recursive: true);
      String at(int line) => r.where((p) => p.line == line).map((p) => p.message).join(' | ');
      expect(at(1), contains('no module “no_such_module_kdash”'));
      expect(at(2), isEmpty, reason: 'a module next to the script imports');
      expect(at(3), contains('did you mean “pid”'));
      expect(r.singleWhere((p) => p.line == 6).warning, isTrue, reason: 'an import in try: may be optional');
      expect(at(11), contains("missing a required argument: 'x'"));
      expect(at(12), contains("unexpected keyword argument 'wiat'"));
      expect(at(13), contains('the device has no “flyy”'));
      expect(at(14), contains('“pritn” is not defined (did you mean “print”?)'));
      expect(describeCheck(r), 'Check: 6 errors, 1 warning');
    },
    skip: skip,
    timeout: const Timeout(Duration(seconds: 90)),
  );

  test('syntax, and what only compiling finds', () async {
    expect((await checkScript(python!, 'x = (1,\n'))!.single.line, 1);
    final r = (await checkScript(python, 'x = 1\nreturn x\n'))!;
    expect(r.single.line, 2);
    expect(r.single.message, contains('outside function'));
  }, skip: skip);
}
