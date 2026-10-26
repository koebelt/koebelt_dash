import 'package:flutter_test/flutter_test.dart';
import 'package:koebelt_dash/scripts/script_runner.dart';

void main() {
  List<String> levels(String stream, String text) {
    final c = ConsoleLevels(stream);
    return [for (final l in text.split('\n')) c.levelOf(ConsoleLevels.clean(l))];
  }

  test('a traceback is an error, to its last line', () {
    expect(
      levels('err', 'Traceback (most recent call last):\n  File "s.py", line 3, in <module>\n    pritn(1)\nNameError: name \'pritn\' is not defined\nafter'),
      ['err', 'err', 'err', 'err', 'err'],
      reason: 'stderr without a level is an error too',
    );
    expect(levels('out', 'Traceback (most recent call last):\n  File "s.py", line 3\nValueError: x\nplain')[3], 'out');
  });

  test("the library's errors and warnings, with the lines that go with them", () {
    expect(levels('err', 'warning[W0101]: telemetry is old\n  --> s.py:4\n   |\n 4 | dev.tlm.alt\n   = help: wait for it\n\nnext'), [
      'warn',
      'warn',
      'warn',
      'warn',
      'warn',
      'warn',
      'err',
    ]);
    expect(levels('out', 'error[E0301]: arming is not allowed\n  = why: limits'), ['err', 'err']);
  });

  test('levels as logging and prints write them', () {
    expect(levels('err', 'DEBUG:root:frame 3'), ['debug']);
    expect(levels('err', 'INFO:ultralytics:loaded'), ['info']);
    expect(levels('err', 'WARNING:root:slow'), ['warn']);
    expect(levels('out', 'debug: x +0.12, steer +0.14'), ['debug']);
    expect(levels('out', 'info: found 1 person'), ['info']);
    expect(levels('out', '[ERROR] no camera'), ['err']);
    expect(levels('out', 'warning: in AUTO'), ['warn']);
    expect(levels('err', '/x/torch/nn.py:12: UserWarning: deprecated\n  warnings.warn("x")'), ['warn', 'warn']);
  });

  test('prints stay prints, words that only start like a level too', () {
    expect(levels('out', 'hello\nInformation about the run\nerrors: 0 so far'), ['out', 'out', 'out']);
  });

  test('colour codes and progress bars as a terminal shows them', () {
    expect(ConsoleLevels.clean('\x1b[KDownloading 11%\rDownloading 100%'), 'Downloading 100%');
    expect(ConsoleLevels.clean('\x1b[1;31merror[E0001]\x1b[0m: no device'), 'error[E0001]: no device');
  });
}
