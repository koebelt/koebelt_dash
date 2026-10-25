// Guides: custom data, parameters, sequences and safety.
import 'guides_data.dart';

const moreGuides = [
  Guide(
    'custom',
    'Custom sensors and fields',
    'Stream any value: declare a channel, publish it, and see it as tiles, charts and CSV columns.',
    10,
    platforms: ['arduino', 'python', 'rust', 'ros2'],
    [
      Step.rich(
        'Built-in channels or custom ones',
        'Built-in channels (imu, gps, battery, joints, thrust…) feed the kind-specific views: the 3D model, the attitude indicator, the readouts. Anything else goes in a custom channel: a name, one to six values, a unit and a nominal rate.',
        table: [
          ['Field', 'Rules', 'Example'],
          ['id', 'Letters, digits and underscores. Underscores show as spaces in the app.', 'motor_temp'],
          ['axes', '1 to 6 names, one per value, in publish order.', 'M1, M2, M3, M4'],
          ['unit', 'Free text, shown after values and in CSV headers.', 'C'],
          ['hz', 'How often you expect to publish. Informational; the link rate still applies.', '10'],
        ],
      ),
      Step.rich(
        'Declare and publish',
        'Declare once at startup, publish whenever you have a reading. The latest value goes out with the next telemetry frame.',
        complete: true,
        c: {
          'arduino': [
            'cpp',
            r'''#include <KoebeltLink.h>

KLink klink("Kite", KLink::DRONE);
KChannel motorTemp, airspeed;

void setup() {
  klink.begin("your-ssid", "your-password");
  motorTemp = klink.channel("motor_temp", {"M1", "M2", "M3", "M4"}, "C", 10);
  airspeed = klink.channel("airspeed", {"value"}, "m/s", 20);
}

void loop() {
  motorTemp.publish(41.2, 43.0, 40.8, 42.5);   // one value per axis
  airspeed.publish(12.4);
  klink.update();
}''',
          ],
          'python': [
            'python',
            r'''from koebelt_link import Device

dev = Device("Kite", kind="drone")
dev.connect(wifi=True)
motor_temp = dev.channel("motor_temp", axes=["M1", "M2", "M3", "M4"], unit="C", hz=10)
airspeed = dev.channel("airspeed", axes=["value"], unit="m/s", hz=20)


def loop():
    motor_temp.publish(41.2, 43.0, 40.8, 42.5)
    airspeed.publish(12.4)


dev.run(hz=20, loop=loop)''',
          ],
          'rust': [
            'rust',
            r'''use koebelt_link::{Device, Kind};

fn main() -> std::io::Result<()> {
    let mut dev = Device::new("Kite", Kind::Drone).wifi("", "").start()?;
    let motor_temp = dev.channel("motor_temp", &["M1", "M2", "M3", "M4"], "C", 10.0);
    let airspeed = dev.channel("airspeed", &["value"], "m/s", 20.0);
    loop {
        dev.publish(motor_temp, &[41.2, 43.0, 40.8, 42.5])?;
        dev.publish(airspeed, &[12.4])?;
        dev.tick_blocking(20.0);
    }
}''',
          ],
          'ros2': [
            'yaml',
            r'''name: Kite
kind: drone
transport: wifi

# any numeric topic becomes a custom channel
channels:
  - id: motor_temp
    topic: /esc/temperatures       # std_msgs/Float32MultiArray
    type: Float32MultiArray
    axes: [M1, M2, M3, M4]
    unit: C
    hz: 10
  - id: airspeed
    topic: /airspeed               # std_msgs/Float64
    type: Float64
    unit: m/s
    hz: 20''',
          ],
        },
      ),
      Step.rich(
        'Where it shows up',
        'As soon as the device sends the channel, the app offers it everywhere:',
        bullets: [
          'Live > Wall: a tile with the latest value and a 10-second chart.',
          'Live > HUD > Edit layout > Add widget: place it over the 3D view.',
          'Tap the tile: the detail view with min, max, mean per axis, pause and the value inspector.',
          'Replay and Export: CSV columns named id_1, id_2… (motor_temp_1…motor_temp_4).',
        ],
        note: 'Tiles only appear for channels the device has actually sent. If one is missing, check that publish is called after the channel is declared.',
      ),
      Step.rich(
        'Limits',
        'Keep messages small, especially on BLE and radio links:',
        bullets: [
          'Arduino: 8 custom channels (KLINK_MAX_CHANNELS), 6 axes each. Change the limit with a #define before including the library.',
          'Rust: 8 channels, 6 axes. Python: no fixed limit.',
          'Custom channels are not sent over 2 Hz radios (LoRa, HC-12).',
          'One telemetry message should stay under about 1.4 kB on Wi-Fi; that is roughly 100 values.',
        ],
      ),
      Step.rich(
        'Your own commands',
        'The app can trigger anything on your device: in Automate > Sequences, add a Custom command step with a name and a value. Handle it like the built-in commands.',
        c: {
          'arduino': [
            'cpp',
            'klink.onCommand([](const char* c, JsonObjectConst a) {\n  if (!strcmp(c, "lights")) digitalWrite(LED_PIN, (a["v"] | 0) > 0 ? HIGH : LOW);\n});',
          ],
          'python': ['python', '@dev.on_command\ndef command(name, a):\n    if name == "lights":\n        lights.set(a.get("v", 0) > 0)'],
          'rust': ['rust', 'dev.on_command(|name, args| {\n    if name == "lights" {\n        lights.set(args.value().unwrap_or(0.0) > 0.0);\n    }\n});'],
        },
      ),
      Step.rich('Your own parameters', 'Any value you want to tune without reflashing becomes a parameter: see the next guide.'),
    ],
  ),
  Guide(
    'params',
    'Tunable parameters',
    'Make gains, limits and setpoints editable from the Tune screen and keep them across reboots.',
    8,
    platforms: ['arduino', 'python', 'rust'],
    [
      Step.rich(
        'Register a parameter',
        'Give each parameter a key, a default, a range and a unit. The Tune screen groups them by the prefix before the first underscore (RATE_RLL_P and RATE_PIT_P land under RATE). The step of the stepper is a hundredth of the range unless you set one.',
        c: {
          'arduino': [
            'cpp',
            'KParam rollP = klink.param("RATE_RLL_P", 0.135, 0.0, 0.5);\nKParam maxTilt = klink.param("MAX_TILT", 35, 10, 60, "deg");\nKParam cellScale = klink.param("CELL_SCALE", 1.0, 0.9, 1.1, "", 0.001);   // explicit step',
          ],
          'python': [
            'python',
            'roll_p = dev.param("RATE_RLL_P", 0.135, min=0, max=0.5)\nmax_tilt = dev.param("MAX_TILT", 35, min=10, max=60, unit="deg", label="Max tilt")\ncell = dev.param("CELL_SCALE", 1.0, min=0.9, max=1.1, step=0.001)',
          ],
          'rust': ['rust', 'let roll_p = dev.link.param("RATE_RLL_P", 0.135, 0.0, 0.5, "");\nlet value = dev.link.param_value(roll_p);'],
        },
      ),
      Step.rich(
        'React to writes',
        'Write to device sends only the changed values. They arrive in callbacks and stay in RAM until you save them.',
        c: {
          'arduino': [
            'cpp',
            'rollP.onChange([](float v) { rollPid.kp = v; });\n\nklink.onParamsWritten([] { klink.saveParams(); });   // ESP32: stored in NVS flash',
          ],
          'python': [
            'python',
            '@roll_p.on_change\ndef _(v):\n    roll_pid.kp = v\n\ndev.on_params_written(dev.save_params)   # ~/.config/koebelt-link/<id>.json',
          ],
          'rust': ['rust', 'dev.on_param(move |index, value| {\n    if index == roll_p {\n        println!("roll P -> {value}");\n    }\n});'],
        },
        note: 'Values are clamped to the range on the device, so a bad entry in the app can never exceed your limits.',
      ),
      Step.rich(
        'Watch the effect',
        'Groups whose first parameter matches a built-in chart show a live response above them (roll rate for RATE_RLL…). Write a gain, watch the chart, revert with one tap if it gets worse.',
      ),
    ],
  ),
  Guide(
    'sequences',
    'Run sequences',
    'Handle waypoints, poses, take-off and home so sequences can drive your device, with or without a link.',
    6,
    platforms: ['arduino', 'python', 'rust'],
    [
      Step.rich(
        'Handle the sequence commands',
        'Sequences send goto (x, y, z in metres from home), takeoff (alt) and pose (six joint angles in radians) as commands. They ride on the existing cmd message, so no protocol change is involved. Report AUTO while moving and HOLD on arrival; the app moves to the next step once your telemetry shows the target is reached. Handle sethome too: vehicles make the current position the origin, arms store the given joints as the home pose.',
        c: {
          'arduino': [
            'cpp',
            'klink.onCommand([](const char* c, JsonObjectConst a) {\n  if (!strcmp(c, "goto")) {\n    nav.goTo(a["x"] | 0.0f, a["y"] | 0.0f, a["z"] | 0.0f);\n    klink.setMode(KMode::AUTO);\n  }\n  if (!strcmp(c, "takeoff")) nav.takeOff(a["alt"] | 5.0f);\n});\n\n// in loop(): report arrival\nif (klink.mode() == KMode::AUTO && nav.arrived()) klink.setMode(KMode::HOLD);',
          ],
          'python': [
            'python',
            '@dev.on_command\ndef command(name, a):\n    if name == "goto":\n        nav.go_to(a["x"], a["y"], a.get("z", 0))\n        dev.set_mode("AUTO")\n    elif name == "pose":\n        arm.move_joints(a["j"])   # radians\n\n# in your loop\nif dev.mode == "AUTO" and nav.arrived():\n    dev.set_mode("HOLD")',
          ],
          'rust': [
            'rust',
            'dev.on_command(|name, args| {\n    if name == "goto" {\n        nav.go_to(args.get("x"), args.get("y"), args.get("z"));\n    }\n});',
          ],
        },
      ),
      Step.rich(
        'What the app checks',
        'Each step waits for evidence in your telemetry before the next one starts:',
        table: [
          ['Step', 'Done when', 'Times out after'],
          ['Take off', 'mode is no longer TAKEOFF and z is within 0.6 m of the target', '60 s'],
          ['Fly / drive to', 'position within 1 m (drones) or 0.6 m (rovers)', '300 s'],
          ['Land, return home', 'disarmed, or on the ground and no longer landing', '300 s'],
          ['Move to pose', 'every joint within 0.03 rad', '60 s'],
          ['Home pose', 'the joints stop moving', '60 s'],
          ['Throttle, ramp, wait', 'the time has passed', '–'],
        ],
        note: 'The device runs these same checks itself when the sequence is stored on it (next step).',
      ),
      Step.rich(
        'Stored on the device',
        'Devices running the koebelt/link library store the sequence: Run uploads it, and the device runs the steps through your own handlers above, checking its own telemetry. It keeps going when the link drops, and the app picks it up again when it reconnects. Nothing to add to your code.',
        table: [
          ['', 'Stored on the device', 'Run from the app'],
          ['When', 'koebelt/link, ArduPilot and PX4 (as a mission)', 'More steps than the device holds, steps a mission cannot hold'],
          ['Link drops', 'Carries on; the link-loss failsafe waits until it ends', 'Pauses; the failsafe takes over'],
          ['Stops on', 'STOP, Stop sequence, stick input in the app', 'STOP, stick input, disconnect'],
          ['Steps', 'Arduino: up to 32 (8 on AVR). Python: 64. Rust: 32', 'Any number'],
        ],
        bullets: [
          'Check klink.sequenceRunning() (Arduino), dev.sequence_running (Python) or dev.link.sequence_running() (Rust) to know whether your code is driving or a stored sequence is.',
          'Custom command steps reach onCommand with their value as "v".',
          'ArduPilot and PX4: take off, fly to, wait, land and return home become a mission flown in AUTO; leading arm steps happen before it starts. A sequence with other steps runs from the app.',
        ],
        note: 'A stored sequence keeps flying without a link: test it in the simulator or tethered first, and keep a hand on STOP or your RC transmitter.',
        warn: true,
      ),
    ],
  ),
  Guide(
    'safety',
    'Stop, arm and failsafe',
    'What STOP does, how arming works and what the failsafe guarantees.',
    7,
    platforms: ['arduino', 'python', 'rust'],
    [
      Step.rich(
        'STOP',
        'The red STOP button is on every screen. The app sends stop three times; the library then:',
        bullets: [
          'calls your stop handler: cut the motors there, without waiting for anything;',
          'disarms and zeroes the stick input;',
          'ignores mode changes, jog and motion commands until the app sends reset;',
          'stays disarmed after reset until you arm again.',
        ],
        c: {
          'arduino': [
            'cpp',
            'klink.onStop([] { motors.cut(); });\n\n// and in loop(), as a second guard:\nif (klink.stopped() || !klink.armed()) motors.cut();',
          ],
          'python': ['python', '@dev.on_stop\ndef stop():\n    motors.cut()\n\n# in your loop\nif dev.estop or not dev.armed:\n    motors.cut()'],
          'rust': ['rust', 'dev.on_stop(|| motors.cut());\n\n// in your loop\nif dev.link.stopped() || !dev.link.armed() {\n    motors.cut();\n}'],
        },
      ),
      Step.rich(
        'Failsafe',
        'The failsafe runs on the device, so it works even if the phone dies or the app crashes. The app sends sticks 20 times a second; when they stop for the timeout (1.8 s by default), the library acts:',
        table: [
          ['Kind', 'Action'],
          ['Drone', 'The mode chosen in Settings: HOLD, RTH or LAND'],
          ['Rover, arm, generic', 'HOLD when armed'],
          ['Test bench', 'IDLE: your mode handler should set the throttle to 0'],
          ['Rocket', 'Nothing: the flight continues'],
        ],
        c: {
          'arduino': ['cpp', 'klink.failsafe(1800, KMode::HOLD);\nklink.onMode([](KMode m) { nav.setMode(m); });   // the failsafe arrives here'],
          'python': ['python', 'dev.failsafe(timeout=1.8, action="hold")\ndev.on_mode(nav.set_mode)   # the failsafe arrives here'],
          'rust': ['rust', 'dev.failsafe(Duration::from_millis(1800), Mode::Hold);\ndev.on_mode(|m| nav.set_mode(m));'],
        },
        note: 'Test it: Settings > Test failsafe withholds the heartbeat for six seconds. Watch what the device does.',
      ),
      Step.rich(
        'Before it moves',
        'A short checklist for every new build:',
        bullets: [
          'A physical kill switch or a removable battery connector within reach.',
          'Propellers off, wheels off the ground or the arm clear of everything for the first test.',
          'Press STOP while it moves and check that everything stops.',
          'Run Test failsafe and check the action.',
        ],
        warn: true,
        note: 'koebelt/link is a convenience link, not a certified safety system.',
      ),
    ],
  ),
];
