import 'package:flutter_test/flutter_test.dart';
import 'package:koebelt_dash/scripts/completion.dart';

void main() {
  const src = '''from koebelt_dash_scripts import connect, every, pid
robot = connect()
t = robot.tlm
speed = robot.setting("speed", 0.4)
steer_pid = pid(1.0)

def go_home():
    pass

''';
  List<String> at(String code, [CompletionContext ctx = const CompletionContext()]) => [for (final c in completeAt(code, code.length, ctx).items) c.label];

  test('any variable from connect() gets the device API, methods with parentheses', () {
    final r = completeAt('${src}robot.st', '${src}robot.st'.length);
    expect(r.items.map((c) => c.label), containsAll(['sticks()', 'stop()', 'store', 'stop_program()']));
    expect(r.items.first.label, 'sticks()', reason: 'prefix matches first');
    expect(r.replace, 2);
    final sticks = r.items.first;
    expect(sticks.insert, 'sticks()');
    expect(sticks.cursorBack, 1, reason: 'the cursor lands inside the parentheses');
    expect(at('${src}robot.'), hasLength(12), reason: 'everything, capped');
  });

  test('telemetry, camera, params and settings, directly or through a variable', () {
    expect(at('${src}t.he'), ['heading']);
    expect(at('${src}robot.tlm.batt'), ['battery']);
    expect(at('${src}robot.camera.fr'), ['frame()', 'frames()']);
    expect(at('${src}robot.params.s'), ['set()', 'save()']);
    expect(at('${src}speed.va'), ['value']);
    expect(at('${src}robot.next_tlm().al'), ['alt']);
  });

  test('what dash knows about the device: its sticks, fields, programs, channels', () {
    const rover = CompletionContext(kind: 'rover', sticks: ['throttle', 'steer'], tlm: ['pos', 'battery'], programs: ['Survey square', 'Back home'], channels: ['motor_temp']);
    expect(at('${src}robot.sticks(', rover), ['throttle=', 'steer=']);
    expect(at('${src}robot.sticks(throttle=0.4, ', rover), ['steer='], reason: 'not the one already given');
    expect(at('${src}robot.sticks(throttle=0.', rover), isEmpty, reason: 'typing a value');
    expect(at('${src}robot.run_program("', rover), ['Survey square', 'Back home']);
    expect(at('${src}robot.run_program("ba', rover), ['Back home']);
    expect(at('${src}t.motor', rover), ['motor_temp']);
    expect(at('${src}robot.mode("', const CompletionContext(kind: 'drone')), containsAll(['RTH', 'LAND']));
    expect(at('$src@robot.trigger("Go", kind="s'), ['switch']);
  });

  test('plain names: the API, the script\'s own names, keywords, builtins; fuzzy after prefixes', () {
    expect(at('${src}ev'), contains('every()'));
    expect(at('${src}go_'), ['go_home']);
    expect(at('${src}whi'), ['while']);
    expect(at('${src}pri'), ['print()']);
    expect(at('${src}pid_'), isEmpty);
    expect(at('${src}_pid'), ['steer_pid'], reason: 'contains, after prefixes');
    expect(at('${src}x'), isEmpty, reason: 'one letter is not enough');
    expect(at('$src# rob'), isEmpty, reason: 'not in comments');
  });

  test('signature help: the call, and the argument the cursor is on', () {
    final code = '${src}robot.goto(5, ';
    final s = signatureAt(code, code.length)!;
    expect(s.sig.text, 'goto(x, y, z=None, wait=True)');
    expect(s.arg, 1);
    expect(s.sig.params[1].$2, 'metres north');
    final c2 = '${src}robot.setting("gain", max(1, 2), ';
    expect(signatureAt(c2, c2.length)!.arg, 2, reason: 'commas inside a nested call do not count');
    final c3 = '${src}connect(';
    expect(signatureAt(c3, c3.length)!.sig.name, 'connect');
    final c4 = '${src}robot.goto(5, 0)\n';
    expect(signatureAt(c4, c4.length), isNull, reason: 'outside a call');
  });

  group('libraries and files', () {
    final lib = <String, Map<String, ({String kind, String sig, String doc})>>{
      'numpy': {
        'array': (kind: 'function', sig: '(object, dtype=None, *, copy=True)', doc: 'Create an array.'),
        'linalg': (kind: 'module', sig: '', doc: ''),
        'ndarray': (kind: 'class', sig: '(shape, dtype=float)', doc: 'An array object.'),
        'pi': (kind: 'value', sig: '', doc: 'float'),
      },
      'numpy.linalg': {
        'norm': (kind: 'function', sig: '(x, ord=None, axis=None)', doc: 'Matrix or vector norm.'),
      },
      'cv2': {
        'VideoCapture': (kind: 'class', sig: '(index)', doc: 'Video capture.'),
        'imread': (kind: 'function', sig: '(filename, flags=1)', doc: 'Loads an image.'),
      },
      'cv2.VideoCapture': {
        'read': (kind: 'function', sig: '()', doc: 'Grabs a frame.'),
        'release': (kind: 'function', sig: '()', doc: 'Closes the camera.'),
      },
    };
    final asked = <String>[];
    CompletionContext ctx() => CompletionContext(
      members: (p) {
        asked.add(p);
        return lib[p];
      },
      installed: () => ['numpy', 'cv2', 'ultralytics', 'math'],
      files: (dir) => switch (dir) {
        '' => [('models', true), ('data.csv', false), ('main.py', false), ('.venv', true)],
        'models' => [('yolov8n.pt', false), ('best.pt', false)],
        _ => const <(String, bool)>[],
      },
    );
    const imports = 'import numpy as np\nfrom cv2 import VideoCapture, imread\ncap = VideoCapture(0)\n';
    List<String> at2(String code) => [for (final c in completeAt(code, code.length, ctx()).items) c.label];

    test('import lines: installed modules, submodules, and names', () {
      expect(at2('import nu'), ['numpy']);
      expect(at2('import numpy.li'), ['linalg']);
      expect(at2('from cv2 import Vi'), ['VideoCapture']);
      expect(at2('from koebelt_dash_scripts import ev'), ['every']);
    });

    test('members of what the script imports, through aliases and instances', () {
      expect(at2('${imports}np.ar').first, 'array()', reason: 'prefixes first, then ndarray');
      expect(at2('${imports}np.linalg.no'), ['norm()']);
      expect(at2('${imports}np.'), containsAll(['array()', 'linalg', 'ndarray', 'pi']));
      expect(at2('${imports}cap.re'), ['read()', 'release()'], reason: 'cap is a cv2.VideoCapture');
      expect(asked, contains('numpy.linalg'));
    });

    test('signature help from the library', () {
      final code = '${imports}np.array([1, 2], ';
      final s = signatureAt(code, code.length, ctx().members)!;
      expect(s.sig.text, 'array(object, dtype=None, copy=True)');
      expect(s.arg, 1);
      expect(s.sig.doc, 'Create an array.');
    });

    test('file paths in strings, relative to the script', () {
      expect(at2('${imports}model = YOLO("'), ['models/', 'data.csv', 'main.py'], reason: 'a call that takes files; folders first, no hidden ones');
      expect(at2('${imports}model = YOLO("models/'), ['best.pt', 'yolov8n.pt']);
      expect(at2('${imports}open("da'), ['data.csv']);
      expect(at2('${imports}x = "./'), isNotEmpty);
      expect(at2('${imports}dev.notify("Hello wo'), isEmpty, reason: 'not every string is a path');
      final r = completeAt('${imports}YOLO("models/yo', '${imports}YOLO("models/yo'.length, ctx());
      expect(r.replace, 2, reason: 'only the file name part is replaced');
    });
  });

  group('hover', () {
    HoverInfo? at(String src, String word, [CompletionContext ctx = const CompletionContext()]) => hoverAt(src, src.lastIndexOf(word) + 1, ctx);
    const script = '''from koebelt_dash_scripts import connect, every
import numpy as np

dev = connect()
speed = dev.setting("speed", 0.5)

def climb(to, rate=1.0):
    """Climbs to a height, then holds."""
    dev.goto(0, 0, to)

for t in every(0.05):
    climb(dev.tlm.alt + 1)
    x = np.linalg.norm([1, 2])
''';
    final ctx = CompletionContext(
      members: (p) => switch (p) {
        'numpy' => {'linalg': (kind: 'module', sig: '', doc: 'Linear algebra.')},
        'numpy.linalg' => {'norm': (kind: 'function', sig: '(x, ord=None, axis=None)', doc: 'Matrix or vector norm.')},
        _ => null,
      },
      doc: (p) => p == 'numpy.linalg.norm' ? (kind: 'function', sig: '(x, ord=None, axis=None)', doc: 'Matrix or vector norm.\n\nThis function returns one of eight norms.') : null,
    );

    test('the API, with what each parameter does', () {
      final h = at(script, 'goto')!;
      expect(h.title, startsWith('dev.goto(x, y'));
      expect(h.params.first.$2, contains('east'));
      expect(h.doc, isNotEmpty);
      expect(at(script, 'every')!.doc, contains('steady loop'));
      expect(at(script, 'alt')!.kind, 'telemetry');
      expect(at(script, 'every')!.source, 'koebelt_dash_scripts');
    });

    test('the script\'s own functions, variables and parameters', () {
      final f = at(script, 'climb(dev')!;
      expect(f.title, 'climb(to, rate=1.0)');
      expect(f.kind, 'function');
      expect(f.source, 'line 7');
      expect(f.doc, 'Climbs to a height, then holds.');
      expect(at(script, 'dev.goto')!.kind, startsWith('device'));
      expect(at(script, 'speed =')!.kind, 'setting');
      expect(at(script, 'speed =')!.code, '= dev.setting("speed", 0.5)');
      expect(at(script, 'to)')!.source, 'climb()');
      expect(hoverAt(script, script.indexOf('for t') + 4)!.kind, startsWith('loop variable'));
    });

    test('libraries: the whole docstring once Python has it', () {
      final h = at(script, 'norm', ctx)!;
      expect(h.title, 'numpy.linalg.norm(x, ord=None, axis=None)');
      expect(h.doc, contains('eight norms'));
      expect(h.source, 'numpy.linalg');
      expect(at(script, 'np.', ctx)!.title, 'numpy');
    });

    test('nothing on keywords, comments and strings', () {
      expect(at(script, 'def'), isNull);
      expect(at(script, 'Climbs'), isNull);
      expect(at(script, '"speed"'), isNull);
      expect(hoverAt('# connect()', 3), isNull);
    });
  });
}
