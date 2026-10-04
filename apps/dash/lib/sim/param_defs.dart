// Parameter tables of the simulated devices (what their firmware would
// declare with `link.param(...)`). Sent to the app in the `params` message.
import 'dart:math' as math;

import '../core/model.dart';

class PDef {
  const PDef(this.key, this.label, this.def, this.min, this.max, this.step, this.unit);
  final String key, label, unit;
  final double def, min, max, step;
}

class PGroup {
  const PGroup(this.name, this.params, [this.chart]);
  final String name;
  final List<PDef> params;
  final List<String>? chart;
}

class PCat {
  const PCat(this.cat, this.groups);
  final String cat;
  final List<PGroup> groups;
}

double _p1(double x) => double.parse(x.toStringAsPrecision(1));
double _fx(double x, int n) => double.parse(x.toStringAsFixed(n));

List<PDef> _pid(String pre, double p, double i, double d, [double? ff]) {
  final pMax = _fx(p * 4, 3), pStep = _p1(p / 40);
  final iv = math.max(i, .05), dv = math.max(d, .005);
  return [
    PDef('${pre}_P', 'P gain', p, 0, pMax == 0 ? 1 : pMax, pStep == 0 ? .001 : pStep, ''),
    PDef('${pre}_I', 'I gain', i, 0, _fx(iv * 5, 3), _p1(iv / 50), ''),
    PDef('${pre}_D', 'D gain', d, 0, _fx(dv * 5, 4), _p1(dv / 50), ''),
    if (ff != null) PDef('${pre}_FF', 'Feed-forward', ff, 0, .5, .01, ''),
  ];
}

final Map<DeviceKind, List<PCat>> paramDefs = {
  DeviceKind.drone: [
    PCat('Rate PID', [
      PGroup('Roll rate', _pid('RATE_RLL', .135, .09, .0036, 0), ['gx']),
      PGroup('Pitch rate', _pid('RATE_PIT', .135, .09, .0036, 0), ['gy']),
      PGroup('Yaw rate', _pid('RATE_YAW', .18, .018, 0, 0), ['gz']),
    ]),
    PCat('Position', [
      PGroup(
        'Altitude hold',
        const [
          PDef('ALT_HOLD_P', 'Position P', 1, 0, 3, .05, ''),
          PDef('VEL_Z_P', 'Velocity P', 5, 0, 10, .1, ''),
          PDef('VEL_Z_I', 'Velocity I', 1, 0, 4, .05, ''),
        ],
        ['alt'],
      ),
      PGroup(
        'Horizontal',
        const [
          PDef('POS_XY_P', 'Position P', 1, 0, 3, .05, ''),
          PDef('VEL_XY_P', 'Velocity P', 2, 0, 6, .1, ''),
          PDef('VEL_XY_I', 'Velocity I', 1, 0, 4, .05, ''),
          PDef('VEL_XY_D', 'Velocity D', .5, 0, 2, .05, ''),
        ],
        ['spd'],
      ),
    ]),
    const PCat('Limits', [
      PGroup('Speed', [
        PDef('MAX_SPD_XY', 'Horizontal', 12, 1, 25, .5, 'm/s'),
        PDef('MAX_CLIMB', 'Climb', 3, .5, 8, .1, 'm/s'),
        PDef('MAX_DESC', 'Descent', 1.5, .3, 4, .1, 'm/s'),
      ]),
      PGroup('Attitude', [PDef('MAX_TILT', 'Max tilt', 35, 10, 60, 1, '°'), PDef('MAX_YAW_RATE', 'Max yaw rate', 90, 20, 360, 5, '°/s')]),
      PGroup('Geofence', [PDef('FENCE_RADIUS', 'Radius', 150, 10, 1000, 10, 'm'), PDef('FENCE_ALT', 'Ceiling', 120, 10, 500, 5, 'm')]),
    ]),
    const PCat('Filters', [
      PGroup(
        'Low-pass',
        [
          PDef('GYRO_LPF', 'Gyro', 80, 20, 250, 5, 'Hz'),
          PDef('DTERM_LPF', 'D-term', 40, 10, 150, 5, 'Hz'),
          PDef('ACC_LPF', 'Accelerometer', 20, 5, 100, 1, 'Hz'),
        ],
        ['gx', 'gy', 'gz'],
      ),
    ]),
  ],
  DeviceKind.rover: [
    PCat('Drive PID', [
      PGroup('Speed', _pid('SPD', .8, .2, .05), ['spd']),
      PGroup('Heading', _pid('HDG', 1.2, 0, .1), ['gz']),
    ]),
    const PCat('Limits', [
      PGroup('Motion', [
        PDef('MAX_SPD', 'Max speed', 4, .5, 8, .1, 'm/s'),
        PDef('MAX_ACC', 'Max accel', 2, .2, 5, .1, 'm/s²'),
        PDef('MAX_TURN', 'Max turn rate', 90, 20, 180, 5, '°/s'),
      ]),
      PGroup('Obstacles', [PDef('OBST_STOP', 'Stop distance', 1.5, .3, 5, .1, 'm'), PDef('OBST_SLOW', 'Slow-down distance', 4, 1, 10, .5, 'm')]),
    ]),
    const PCat('Geometry', [
      PGroup('Chassis', [
        PDef('WHEEL_BASE', 'Wheel base', .62, .2, 2, .01, 'm'),
        PDef('TRACK_W', 'Track width', .5, .2, 2, .01, 'm'),
        PDef('WHEEL_DIA', 'Wheel diameter', .25, .05, 1, .01, 'm'),
      ]),
    ]),
  ],
  DeviceKind.arm: [
    PCat('Joint gains', [
      for (var i = 0; i < 6; i++)
        PGroup(
          'J${i + 1}',
          [
            PDef('J${i + 1}_KP', 'Kp', const <double>[120, 140, 110, 60, 50, 30][i], 0, 400, 1, ''),
            PDef('J${i + 1}_KI', 'Ki', 2, 0, 20, .1, ''),
            PDef('J${i + 1}_KD', 'Kd', const <double>[8, 10, 7, 4, 3, 2][i], 0, 40, .1, ''),
          ],
          ['j$i'],
        ),
    ]),
    const PCat('Motion', [
      PGroup('Speed', [
        PDef('MAX_J_SPD', 'Joint speed', 180, 10, 360, 5, '°/s'),
        PDef('MAX_TCP_SPD', 'TCP speed', 1, .05, 2, .05, 'm/s'),
        PDef('MAX_TCP_ACC', 'TCP accel', 2.5, .1, 8, .1, 'm/s²'),
      ]),
    ]),
    const PCat('Tool', [
      PGroup(
        'Payload',
        [
          PDef('PAYLOAD', 'Mass', 2.4, 0, 5, .1, 'kg'),
          PDef('TCP_X', 'TCP offset X', 0, -.3, .3, .005, 'm'),
          PDef('TCP_Z', 'TCP offset Z', .14, 0, .5, .005, 'm'),
        ],
        ['fz'],
      ),
    ]),
    const PCat('Safety', [
      PGroup('Protective stop', [
        PDef('COLL_SENS', 'Collision sensitivity', 70, 10, 100, 5, '%'),
        PDef('SAFE_ZONE', 'Safety zone radius', 1.9, .5, 4, .1, 'm'),
        PDef('REDUCED_SPD', 'Reduced speed', 25, 5, 100, 5, '%'),
      ]),
    ]),
  ],
  DeviceKind.rocket: const [
    PCat('Recovery', [
      PGroup(
        'Deployment',
        [
          PDef('DROGUE_DELAY', 'Drogue delay after apogee', 0, 0, 5, .1, 's'),
          PDef('MAIN_ALT', 'Main deploy altitude', 150, 50, 500, 10, 'm'),
          PDef('APOGEE_LOCKOUT', 'Apogee lockout after launch', 6, 1, 20, .5, 's'),
        ],
        ['alt'],
      ),
    ]),
    PCat('Launch', [
      PGroup('Detection', [PDef('COUNTDOWN', 'Countdown length', 10, 3, 30, 1, 's'), PDef('LAUNCH_G', 'Launch detect threshold', 3, 1.5, 10, .5, 'g')], ['az']),
    ]),
    PCat('Pyro', [
      PGroup('Firing', [PDef('PYRO_PULSE', 'Pulse length', 500, 100, 2000, 50, 'ms'), PDef('PYRO_MIN_V', 'Minimum bus voltage', 7.2, 5, 12, .1, 'V')]),
    ]),
    PCat('Logging', [
      PGroup('On-board log', [PDef('LOG_RATE', 'IMU log rate', 200, 50, 1000, 50, 'Hz'), PDef('TLM_RATE', 'Radio telemetry rate', 10, 1, 30, 1, 'Hz')]),
    ]),
  ],
  DeviceKind.bench: const [
    PCat('Calibration', [
      PGroup('Load cell', [PDef('CELL_SCALE', 'Scale factor', 1, .9, 1.1, .001, ''), PDef('CELL_OFFSET', 'Zero offset', 0, -5, 5, .01, 'N')], ['thr']),
      PGroup('Motor', [PDef('POLES', 'Motor poles', 14, 2, 40, 2, ''), PDef('PROP_D', 'Prop diameter', 10, 3, 30, .5, 'in')]),
    ]),
    PCat('Limits', [
      PGroup(
        'Cutoffs',
        [
          PDef('MAX_THROTTLE', 'Max throttle', 100, 10, 100, 5, '%'),
          PDef('MAX_CURRENT', 'Current cutoff', 45, 5, 120, 1, 'A'),
          PDef('MAX_TEMP', 'Temperature cutoff', 90, 40, 150, 1, '°C'),
        ],
        ['cur'],
      ),
    ]),
    PCat('Sequence', [
      PGroup('Ramp', [PDef('RAMP_TIME', 'Ramp duration', 10, 2, 60, 1, 's')]),
      PGroup('Steps', [PDef('STEP_SIZE', 'Step size', 25, 5, 50, 5, '%'), PDef('STEP_HOLD', 'Hold per step', 3, 1, 20, .5, 's')]),
    ]),
  ],
  DeviceKind.generic: const [],
};
