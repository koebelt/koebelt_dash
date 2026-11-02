// Metric or imperial: only what is shown and typed converts; what is kept
// and sent stays metric.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koebelt_dash/core/units.dart' as u;

void main() {
  tearDown(() => u.imperial = false);

  test('the region decides, unless the setting does', () {
    u.useUnits('', [const Locale('en', 'US')]);
    expect(u.imperial, isTrue);
    u.useUnits('', [const Locale('en', 'GB')]);
    expect(u.imperial, isFalse);
    u.useUnits('', [const Locale('fr')]);
    expect(u.imperial, isFalse);
    u.useUnits('metric', [const Locale('en', 'US')]);
    expect(u.imperial, isFalse);
    u.useUnits('imperial', [const Locale('de', 'DE')]);
    expect(u.imperial, isTrue);
  });

  test('lengths, speeds and temperatures, both ways', () {
    u.imperial = true;
    expect(u.lenText(120), '394 ft');
    expect(u.speedText(10), '22.4 mph');
    expect(u.tempText(70), '158 °F');
    expect(u.lenToMetres(u.len(42.5)), closeTo(42.5, 1e-9));
    expect(u.tempToCelsius(u.temp(-12)), closeTo(-12, 1e-9));
    final c = u.convertUnit('m/s');
    expect(c.unit, 'mph');
    expect(c.metric(c.shown(3)), closeTo(3, 1e-9));
    expect(u.convertUnit('V').shown(12.6), 12.6, reason: 'other units pass through');

    u.imperial = false;
    expect(u.lenText(120), '120 m');
    expect(u.speedText(10), '10.0 m/s');
    expect(u.tempText(70), '70 °C');
  });
}
