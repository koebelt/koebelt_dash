import 'dart:ui';

/// Lengths, speeds and temperatures as shown: metric, or imperial (feet,
/// mph, °F). Telemetry, settings, sequences and the protocol stay metric;
/// only what is shown and typed in converts.
bool imperial = false;

/// Countries that measure in feet and miles.
const _imperialCountries = {'US', 'LR', 'MM'};

/// Settings > Units: 'metric', 'imperial', or empty for the system region's.
void useUnits(String setting, [List<Locale>? system]) {
  if (setting.isNotEmpty) {
    imperial = setting == 'imperial';
    return;
  }
  imperial = regionIsImperial(system);
}

/// Whether the system's region measures in feet and miles.
bool regionIsImperial([List<Locale>? system]) => _imperialCountries.contains((system ?? PlatformDispatcher.instance.locales).firstOrNull?.countryCode);

const _ft = 3.28084, _mph = 2.23694;

/// Metres as shown (m or ft).
double len(double m) => imperial ? m * _ft : m;

/// A length typed in the unit shown, back to metres.
double lenToMetres(double shown) => imperial ? shown / _ft : shown;
String get lenUnit => imperial ? 'ft' : 'm';

/// "12 m" or "39 ft".
String lenText(double m, [int digits = 0]) => '${len(m).toStringAsFixed(digits)} $lenUnit';

/// Metres per second as shown (m/s or mph).
double speed(double mps) => imperial ? mps * _mph : mps;
String get speedUnit => imperial ? 'mph' : 'm/s';
String speedText(double mps, [int digits = 1]) => '${speed(mps).toStringAsFixed(digits)} $speedUnit';

/// Degrees Celsius as shown (°C or °F).
double temp(double c) => imperial ? c * 9 / 5 + 32 : c;
double tempToCelsius(double shown) => imperial ? (shown - 32) * 5 / 9 : shown;
String get tempUnit => imperial ? '°F' : '°C';
String tempText(double c, [int digits = 0]) => '${temp(c).toStringAsFixed(digits)} $tempUnit';

/// A metric unit as shown, with how to convert values to it and back; other
/// units (V, A, %, rad…) pass through.
({String unit, double Function(double) shown, double Function(double) metric}) convertUnit(String unit) => switch (unit) {
  'm' => (unit: lenUnit, shown: len, metric: lenToMetres),
  'm/s' => (unit: speedUnit, shown: speed, metric: (v) => imperial ? v / _mph : v),
  '°C' => (unit: tempUnit, shown: temp, metric: tempToCelsius),
  _ => (unit: unit, shown: (v) => v, metric: (v) => v),
};
