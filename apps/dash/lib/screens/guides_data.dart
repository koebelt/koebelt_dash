// Integration guides. Every snippet here compiles against the libraries in
// libs/ — keep them in sync when an API changes.

import 'guides_connections.dart';
import 'guides_devices.dart';
import 'guides_features.dart';
import 'guides_more.dart';

export 'guides_connections.dart';
export 'guides_devices.dart';
export 'guides_features.dart';
export 'guides_more.dart';

const repoUrl = 'https://github.com/koebelt/koebelt_dash';

class Platform {
  const Platform(this.id, this.name, this.lang, this.pkg, this.install, this.boards, this.fit, this.path);
  final String id, name, lang, pkg, install, boards, fit, path;
}

const platforms = [
  Platform(
    'arduino',
    'Arduino / ESP32',
    'cpp',
    'KoebeltLink',
    'Library Manager',
    'ESP32, ESP32-S3, RP2040 W, Teensy 4.1',
    'Flight controllers, small rovers, sensor boards',
    'libs/arduino',
  ),
  Platform(
    'python',
    'Python',
    'python',
    'koebelt-link',
    'pip',
    'Raspberry Pi, Jetson, any Linux or macOS',
    'Companion computers, robot arms over USB',
    'libs/python',
  ),
  Platform('ros2', 'ROS 2', 'bash', 'koebelt_link_ros', 'apt', 'Humble, Jazzy', 'Robots that already publish ROS topics', 'libs/ros2'),
  Platform('rust', 'Rust', 'rust', 'koebelt-link', 'cargo', 'std and no_std (embassy, embedded-hal)', 'Custom firmware, high-rate control loops', 'libs/rust'),
];

class Step {
  const Step(this.t, this.p, [this.c = const {}]) : pair = false, bullets = const [], note = null, warn = false, table = null, complete = false;

  const Step.rich(
    this.t,
    this.p, {
    this.c = const {},
    this.pair = false,
    this.bullets = const [],
    this.note,
    this.warn = false,
    this.table,
    this.complete = false,
  });

  final String t, p;

  /// Code per platform: platform id -> [language, code].
  final Map<String, List<String>> c;
  final bool pair;
  final List<String> bullets;

  /// A tip, or a warning when [warn] is set.
  final String? note;
  final bool warn;
  final List<List<String>>? table;

  /// The snippets are complete programs. test/guides_snippets_test.dart
  /// compiles (C++, Rust) or checks (Python, YAML) them against libs/.
  final bool complete;
}

class Guide {
  const Guide(this.id, this.title, this.sub, this.mins, this.steps, {this.platforms, this.table, this.section = 'more', this.kind});
  final String id, title, sub;
  final int mins;
  final List<Step> steps;
  final List<String>? platforms;
  final List<List<String>>? table;

  /// 'connections', 'devices' or 'more'.
  final String section;

  /// Device kind for device examples (drone, rover, arm, rocket, bench, generic).
  final String? kind;
}

Guide quickstart(String pair) => Guide('quickstart', 'Quickstart', "Install the library, stream two sensors, take control input and pair with this app.", 15, [
  const Step('Install the library', "Add the library to your project. It has no runtime dependencies beyond the platform's network stack.", {
    'arduino': [
      'cpp',
      '// Arduino IDE: Sketch > Include Library > Manage Libraries\n// search "KoebeltLink" and install 1.0.x\n\n// PlatformIO: platformio.ini\nlib_deps = koebelt/KoebeltLink@^1.0.0',
    ],
    'python': ['bash', 'pip install koebelt-link\n\n# optional extras\npip install "koebelt-link[ble,serial]"'],
    'ros2': [
      'bash',
      'sudo apt install ros-humble-koebelt-link-ros\n# or build from source\ncd ~/ros2_ws/src && git clone https://github.com/koebelt/koebelt_dash\ncolcon build --packages-select koebelt_link_ros',
    ],
    'rust': ['bash', 'cargo add koebelt-link\n# embedded, no allocator\ncargo add koebelt-link --no-default-features --features embassy'],
  }),
  const Step(
    'Declare the device',
    'Give the device a name and a kind. The kind picks the default dashboard, controls and 3D model in the app: drone, rover, arm, rocket, bench or generic.',
    {
      'arduino': [
        'cpp',
        '#include <KoebeltLink.h>\n\nKLink link("Kite-03", KLink::DRONE);\n\nvoid setup() {\n  link.begin(WIFI_SSID, WIFI_PASS);   // or link.beginBLE()\n}\n\nvoid loop() {\n  link.update();                      // call every loop, non-blocking\n}',
      ],
      'python': [
        'python',
        'from koebelt_link import Device\n\ndev = Device("Mule-2", kind="rover")\ndev.connect(wifi=True)   # or ble=True, serial="/dev/ttyUSB0"',
      ],
      'ros2': ['yaml', '# config/device.yaml\nname: Cell-B\nkind: arm\ntransport: wifi'],
      'rust': ['rust', 'use koebelt_link::{Device, Kind};\n\nlet mut dev = Device::new("Kite-04", Kind::Drone)\n    .wifi(SSID, PASS)\n    .start()?;'],
    },
  ),
  const Step(
    'Stream sensors',
    'Publish values at the rate you read them. The library batches and down-samples to the telemetry rate set in the app, so publishing faster than the link is fine.',
    {
      'arduino': [
        'cpp',
        'void loop() {\n  imu.read();\n  link.imu(imu.ax, imu.ay, imu.az, imu.gx, imu.gy, imu.gz);\n  link.gps(gps.lat, gps.lon, gps.alt);\n  link.battery(vbat, pct);\n  link.update();\n}',
      ],
      'python': [
        'python',
        'from koebelt_link import Vec3\n\nwhile True:\n    dev.publish("imu", accel=Vec3(*imu.accel()), gyro=Vec3(*imu.gyro()))\n    dev.publish("lidar", points=lidar.scan())   # Nx3 array\n    dev.tick(hz=50)',
      ],
      'ros2': [
        'yaml',
        '# map existing topics to app channels\nsensors:\n  imu:    /imu/data          # sensor_msgs/Imu\n  lidar:  /points            # sensor_msgs/PointCloud2\n  joints: /joint_states      # sensor_msgs/JointState\n  power:  /battery_state',
      ],
      'rust': ['rust', 'loop {\n    let (a, g) = imu.read()?;\n    dev.imu(a, g)?;\n    dev.battery(adc.vbat(), pct)?;\n    dev.tick().await;\n}'],
    },
  ),
  const Step(
    'Receive control input',
    'Stick, slider and tilt input all arrive as the same four normalised axes from −1 to 1, plus the selected mode. Robot arms receive joint or Cartesian jog commands instead.',
    {
      'arduino': [
        'cpp',
        'link.onControl([](const KControl& c) {\n  throttle = c.ly;  yaw = c.lx;\n  pitch    = c.ry;  roll = c.rx;\n});\n\nlink.onMode([](KMode m) {\n  if (m == KMode::RTH) nav.returnHome();\n});',
      ],
      'python': [
        'python',
        '@dev.on_control\ndef drive(c):\n    motors.set(speed=c.ry, turn=c.lx)\n\n@dev.on_mode\ndef mode(m):\n    print("mode ->", m)   # AUTO, MANUAL, HOLD',
      ],
      'ros2': [
        'yaml',
        'controls:\n  twist: /cmd_vel                         # rovers, geometry_msgs/Twist\n  jog:   /servo_node/delta_joint_cmds      # arms, MoveIt Servo\n  mode:  /koebelt/mode',
      ],
      'rust': ['rust', 'if let Some(c) = dev.poll_control() {\n    mixer.apply(c.lx, c.ly, c.rx, c.ry);\n}'],
    },
  ),
  const Step(
    'Handle stop and failsafe',
    'STOP in the app must always reach your motors. Register a stop handler and a failsafe timeout; the library fires the failsafe itself if control packets stop arriving, even if the app crashes.',
    {
      'arduino': [
        'cpp',
        'link.onStop([] { motors.cut(); });\nlink.onArm([](bool armed) { motors.enable(armed); });\n\n// no packet for 1.8 s -> hold position\nlink.failsafe(1800, KMode::HOLD);',
      ],
      'python': ['python', '@dev.on_stop\ndef stop():\n    motors.brake()\n\ndev.failsafe(timeout=1.8, action="hold")'],
      'ros2': ['yaml', 'safety:\n  stop_service: /robot/estop     # std_srvs/Trigger\n  failsafe_timeout: 1.8\n  failsafe_action: hold'],
      'rust': ['rust', 'dev.on_stop(|| motors.cut());\ndev.failsafe(Duration::from_millis(1800), Mode::Hold);'],
    },
  ),
  Step.rich(
    'Pair with this app',
    'Pass the pairing code below once. The device stores the key and reconnects on its own afterwards.',
    pair: true,
    c: {
      'arduino': ['cpp', 'void setup() {\n  link.begin(WIFI_SSID, WIFI_PASS);\n  link.pair("$pair");   // remove after first pairing\n}'],
      'python': ['python', 'dev.pair("$pair")'],
      'ros2': ['bash', 'ros2 launch koebelt_link_ros bridge.launch.py \\\n  config:=config/device.yaml pair:=$pair'],
      'rust': ['rust', 'dev.pair("$pair")?;'],
    },
  ),
  const Step.rich(
    'Where next',
    'The quickstart covers the basics. The guides below go deeper:',
    bullets: [
      'Connections: how Wi-Fi, BLE, USB serial and radio links work, which boards connect as they are (ArduPilot, PX4, Betaflight, INAV, Tello), and how to fix discovery problems.',
      'Video, map and controllers: show a camera, put the device on a map, drive with a gamepad.',
      'Device examples: a complete program for a drone, rover, robot arm, rocket, thrust bench and a custom device.',
      'Custom sensors and fields: stream any value, add tunable parameters and your own commands.',
    ],
  ),
]);

/// Every guide except the quickstart, in display order.
const guides = [...connectionGuides, ...deviceGuides, ...featureGuides, ...moreGuides];
