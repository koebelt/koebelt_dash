import 'package:flutter_test/flutter_test.dart';
import 'package:koebelt_dash/scripts/conditions.dart';

void main() {
  final values = <String, Object>{
    'battery.pct': 22.0,
    'home.distance': 85.0,
    'armed': true,
    'mode': 'AUTO',
    'motor_temp.max': 71.5,
    'motor_temp[2]': 64.0,
    'alt': -2.0,
  };
  Object? f(List<String> p) => values[p.length > 1 && RegExp(r'^\d+$').hasMatch(p.last) ? '${p.first}[${p.last}]' : p.join('.')];
  bool t(String s) => Condition.parse(s).test(f);

  test('comparisons, logic and arithmetic', () {
    expect(t('battery.pct < 25'), isTrue);
    expect(t('battery.pct >= 25'), isFalse);
    expect(t('home.distance > 80 and armed'), isTrue);
    expect(t('home.distance > 80 and not armed'), isFalse);
    expect(t('battery.pct > 50 or motor_temp.max > 70'), isTrue);
    expect(t('mode == "auto"'), isTrue, reason: 'modes compare without case');
    expect(t("mode != 'HOLD'"), isTrue);
    expect(t('abs(alt) > 1'), isTrue);
    expect(t('max(battery.pct, 30) == 30'), isTrue);
    expect(t('motor_temp[2] + 10 > 70'), isTrue);
    expect(t('(battery.pct < 10 or armed) and home.distance / 2 > 40'), isTrue);
    expect(t('-alt == 2'), isTrue);
  });

  test('the for clause, and its units', () {
    expect(Condition.parse('battery.pct < 25 for 3s').holdFor, const Duration(seconds: 3));
    expect(Condition.parse('armed for 500ms').holdFor, const Duration(milliseconds: 500));
    expect(Condition.parse('armed for 2 min').holdFor, const Duration(minutes: 2));
    expect(Condition.parse('armed for 1.5').holdFor, const Duration(milliseconds: 1500));
    expect(Condition.parse('home.distance > 80 and armed').fields, {'home.distance', 'armed'});
  });

  test('mistakes say where and what', () {
    void bad(String s, Pattern msg) => expect(() => Condition.parse(s), throwsA(isA<ConditionError>().having((e) => e.message, 'message', contains(msg))));
    bad('', 'Empty');
    bad('battery.pct <', 'Expected a value at the end');
    bad('battery.pct < 25 armed', 'Expected "and", "or", "for"');
    bad('(armed', 'Expected ")"');
    bad('sqrt(alt) > 1', 'Unknown function "sqrt"');
    bad('battery.pct < 25 for', 'Expected a duration');
    bad('battery.pct ? 3', 'Unexpected "?"');
    expect(() => Condition.parse('lidar.max > 3').test(f), throwsA(isA<ConditionError>().having((e) => e.message, 'm', contains('No field "lidar.max"'))));
    expect(() => Condition.parse('mode > 3').test(f), throwsA(isA<ConditionError>()));
  });

  test('a watched condition fires once it has held, and clears', () {
    final w = ConditionWatch(Condition.parse('battery.pct < 25 for 1s'));
    expect(w.step(.5, f), isNull);
    expect(w.step(.4, f), isNull);
    expect(w.step(.2, f), isTrue, reason: 'held 1.1 s');
    expect(w.step(.2, f), isNull, reason: 'fires once');
    values['battery.pct'] = 30.0;
    expect(w.step(.1, f), isFalse);
    expect(w.step(.1, f), isNull);
    values['battery.pct'] = 22.0;
    expect(w.step(.5, f), isNull, reason: 'the clock restarted');
  });

  test('an unknown field does not fire and says why', () {
    final w = ConditionWatch(Condition.parse('lidar.max > 3'));
    expect(w.step(.1, f), isNull);
    expect(w.error, contains('lidar.max'));
  });

  test('the picker and expressions convert both ways when they can', () {
    expect(pickedFrom('battery.pct < 25 for 3s'), (field: 'battery.pct', op: '<', value: 25.0, seconds: 3.0));
    expect(pickedFrom('home.distance>80'), (field: 'home.distance', op: '>', value: 80.0, seconds: 0.0));
    expect(pickedFrom('battery.pct < 25 and armed'), isNull);
    expect(expressionOf((field: 'battery.pct', op: '<', value: 25, seconds: 3)), 'battery.pct < 25 for 3s');
    expect(expressionOf((field: 'alt', op: '>', value: 2.5, seconds: 0)), 'alt > 2.5');
  });
}
