// Guides: a complete example per device kind. Every program marked complete
// is compiled (C++, Rust) or checked (Python, YAML) by
// test/guides_snippets_test.dart.
import 'guides_data.dart';

const deviceGuides = [
  // ---------------------------------------------------------------- drone
  Guide(
    'ex-drone',
    'Drone',
    'A companion board next to the flight controller: telemetry, sticks, modes, waypoints.',
    15,
    section: 'devices',
    kind: 'drone',
    platforms: ['arduino', 'python', 'rust'],
    [
      Step.rich(
        'What the app gives you',
        'koebelt/link does not replace your flight controller (Betaflight, ArduPilot, PX4, your own). It runs next to it and passes data both ways.',
        bullets: [
          'Live: HUD over a 3D view with attitude, accelerometer, altitude and a GPS track; the drone model follows position, roll, pitch and yaw.',
          'Control: two sticks (throttle and yaw left, pitch and roll right), sliders or phone tilt; AUTO, MANUAL and HOLD, plus TAKEOFF, LAND and RTH.',
          'Program: sequences with take off, fly to waypoints, wait and land.',
          'Settings: what the drone does on link loss (hold, return home or land).',
        ],
      ),
      Step.rich(
        'Channels to send',
        'Positions are metres east, north and up from the home point (where it armed or where you pressed Set home).',
        table: [
          ['Call', 'Values', 'Used for'],
          ['attitude', 'roll, pitch, yaw (rad)', 'Attitude tile, 3D model, chase camera'],
          ['position', 'x east, y north, z up (m)', '3D view, altitude, Home distance, waypoints'],
          ['velocity', 'vx, vy, vz (m/s)', 'Speed, smooth motion between samples'],
          ['gps', 'lat, lon, alt, satellites', 'GPS tile, GPX export'],
          ['imu', 'accel (m/s²) and gyro (rad/s)', 'Accelerometer and gyroscope tiles'],
          ['battery', 'volts, percent, amps', 'Status bar, power tile'],
        ],
      ),
      Step.rich(
        'Commands to handle',
        'Besides sticks, the app sends:',
        bullets: [
          'mode: AUTO, MANUAL, HOLD, LAND, RTH (and TAKEOFF from the Control screen).',
          'takeoff {alt}: arm and climb, report TAKEOFF then HOLD.',
          'goto {x, y, z}: fly to the point, report AUTO while moving and HOLD on arrival.',
          'sethome: the current position becomes (0, 0).',
          'stop: cut the motors now. The library disarms and blocks everything else until reset.',
        ],
      ),
      Step.rich(
        'Complete example',
        'Replace the Fc structure with your flight-controller interface (MSP, MAVLink, SBUS…).',
        complete: true,
        c: {
          'arduino': [
            'cpp',
            r'''// Drone companion: an ESP32 next to the flight controller.
#include <KoebeltLink.h>

KLink klink("Kite", KLink::DRONE);

// ---- replace with your flight controller interface ----------------------
struct Fc {
  float roll = 0, pitch = 0, yaw = 0;      // rad
  float x = 0, y = 0, z = 0;               // m east / north / up from home
  float vx = 0, vy = 0, vz = 0;            // m/s
  float ax = 0, ay = 0, az = 9.81f, gx = 0, gy = 0, gz = 0;
  double lat = 47.3769, lon = 8.5417;
  float volts = 15.8f, amps = 0, pct = 80;
  void read() {}
  void sticks(float thr, float yawRate, float pitchCmd, float rollCmd) {}
  void setMode(KMode m) {}
  void arm(bool on) {}
  void killMotors() {}
  void takeOff(float alt) {}
  void goTo(float tx, float ty, float tz) {}
  bool arrived() { return true; }
  void setHomeHere() { x = y = 0; }
} fc;
// --------------------------------------------------------------------------

void setup() {
  Serial.begin(115200);
  klink.setModel("Quadcopter 5 in · 1.4 kg");
  klink.setSensors("IMU,BARO,COMPASS,GPS");
  klink.begin("your-ssid", "your-password");

  // Sticks arrive 20 times a second while the app is open, each −1…1.
  klink.onControl([](const KControl& c) {
    if (klink.mode() == KMode::MANUAL) fc.sticks(c.ly, c.lx, c.ry, c.rx);
  });
  klink.onMode([](KMode m) { fc.setMode(m); });   // AUTO, MANUAL, HOLD, LAND, RTH
  klink.onArm([](bool a) { fc.arm(a); });
  klink.onStop([] { fc.killMotors(); });          // STOP must always cut the motors
  klink.onCommand([](const char* c, JsonObjectConst a) {
    if (!strcmp(c, "takeoff")) {
      fc.takeOff(a["alt"] | 5.0f);
      klink.setMode(KMode::TAKEOFF);
    } else if (!strcmp(c, "goto")) {
      fc.goTo(a["x"] | fc.x, a["y"] | fc.y, a["z"] | fc.z);
      klink.setMode(KMode::AUTO);
    } else if (!strcmp(c, "sethome")) {
      fc.setHomeHere();
    }
  });
  klink.failsafe(1800, KMode::RTH);              // the app can change the action
}

void loop() {
  fc.read();
  klink.attitude(fc.roll, fc.pitch, fc.yaw);
  klink.position(fc.x, fc.y, fc.z);
  klink.velocity(fc.vx, fc.vy, fc.vz);
  klink.imu(fc.ax, fc.ay, fc.az, fc.gx, fc.gy, fc.gz);
  klink.gps(fc.lat, fc.lon, fc.z, 14);
  klink.battery(fc.volts, fc.pct, fc.amps);
  klink.rssi(WiFi.RSSI());
  if (klink.mode() == KMode::TAKEOFF && fc.arrived()) klink.setMode(KMode::HOLD);
  if (klink.mode() == KMode::AUTO && fc.arrived()) klink.setMode(KMode::HOLD);
  klink.update();
}''',
          ],
          'python': [
            'python',
            r'''"""Drone companion computer (Raspberry Pi next to the flight controller)."""
from koebelt_link import Device, Vec3


class FlightController:
    """Replace with your flight controller link (MAVLink with pymavlink, MSP…)."""

    roll = pitch = yaw = 0.0
    x = y = z = vx = vy = vz = 0.0
    lat, lon = 47.3769, 8.5417
    volts, amps, pct = 15.8, 0.0, 80.0
    accel, gyro = (0.0, 0.0, 9.81), (0.0, 0.0, 0.0)

    def read(self): ...
    def sticks(self, throttle, yaw, pitch, roll): ...
    def set_mode(self, mode): ...
    def arm(self, on): ...
    def kill(self): ...
    def take_off(self, alt): ...
    def go_to(self, x, y, z): ...
    def arrived(self): return True
    def set_home_here(self): ...


fc = FlightController()
dev = Device("Kite", kind="drone", model="Quadcopter 5 in · 1.4 kg", sensors=["IMU", "BARO", "COMPASS", "GPS"])
dev.connect(wifi=True)
dev.failsafe(timeout=1.8, action="rth")
dev.on_mode(fc.set_mode)
dev.on_arm(fc.arm)
dev.on_stop(fc.kill)          # STOP must always cut the motors


@dev.on_control
def sticks(c):
    if dev.mode == "MANUAL":
        fc.sticks(throttle=c.ly, yaw=c.lx, pitch=c.ry, roll=c.rx)


@dev.on_command
def command(name, a):
    if name == "takeoff":
        fc.take_off(a.get("alt", 5))
        dev.set_mode("TAKEOFF")
    elif name == "goto":
        fc.go_to(a["x"], a["y"], a.get("z", 5))
        dev.set_mode("AUTO")
    elif name == "sethome":
        fc.set_home_here()


def loop():
    fc.read()
    dev.publish("imu", accel=Vec3(*fc.accel), gyro=Vec3(*fc.gyro))
    dev.publish("att", roll=fc.roll, pitch=fc.pitch, yaw=fc.yaw)
    dev.publish("pos", x=fc.x, y=fc.y, z=fc.z)
    dev.publish("vel", vx=fc.vx, vy=fc.vy, vz=fc.vz)
    dev.gps(fc.lat, fc.lon, fc.z, sats=14)
    dev.battery(fc.volts, fc.pct, amps=fc.amps)
    if dev.mode in ("TAKEOFF", "AUTO") and fc.arrived():
        dev.set_mode("HOLD")


dev.run(hz=50, loop=loop)''',
          ],
          'rust': [
            'rust',
            r'''//! Drone companion on Linux (Raspberry Pi, Jetson).
use std::sync::{Arc, Mutex};
use std::time::Duration;

use koebelt_link::{Device, Kind, Mode};

/// Replace with your flight-controller link (MAVLink, MSP…).
#[derive(Default)]
struct Fc {
    pos: [f32; 3],
    att: [f32; 3],
    target: Option<[f32; 3]>,
}

fn main() -> std::io::Result<()> {
    let fc = Arc::new(Mutex::new(Fc::default()));
    let mut dev = Device::new("Kite", Kind::Drone).model("Quadcopter 5 in · 1.4 kg").wifi("", "").start()?;
    dev.failsafe(Duration::from_millis(1800), Mode::Rth);
    dev.on_stop(|| println!("STOP: cut the motors here"));
    let f = fc.clone();
    dev.on_command(move |name, args| {
        let mut fc = f.lock().unwrap();
        match name {
            "takeoff" => fc.target = Some([fc.pos[0], fc.pos[1], args.get("alt").unwrap_or(5.0)]),
            "goto" => fc.target = Some([args.get("x").unwrap_or(0.0), args.get("y").unwrap_or(0.0), args.get("z").unwrap_or(5.0)]),
            "sethome" => fc.pos = [0.0, 0.0, fc.pos[2]],
            _ => {}
        }
    });
    loop {
        let (pos, att, arrived) = {
            let fc = fc.lock().unwrap();
            (fc.pos, fc.att, fc.target.is_none())
        };
        dev.position(pos)?;
        dev.attitude(att[0], att[1], att[2])?;
        dev.imu([0.0, 0.0, 9.81], [0.0, 0.0, 0.0])?;
        dev.battery(15.8, 80.0)?;
        if let Some(c) = dev.poll_control() {
            let _ = (c.lx, c.ly, c.rx, c.ry); // forward to the flight controller in MANUAL
        }
        if arrived && dev.link.mode() == Mode::Auto {
            dev.link.set_mode(Mode::Hold);
        }
        dev.tick_blocking(50.0);
    }
}''',
          ],
        },
        warn: true,
        note: 'Test with propellers off first. Check that STOP and the failsafe (Settings > Test failsafe) do what you expect before every new flight setup.',
      ),
    ],
  ),

  // ---------------------------------------------------------------- rover
  Guide(
    'ex-rover',
    'Ground robot',
    'Differential drive with odometry, a 2D lidar, manual driving and waypoints.',
    15,
    section: 'devices',
    kind: 'rover',
    platforms: ['arduino', 'python', 'ros2'],
    [
      Step.rich(
        'What the app gives you',
        'Rovers get the same Live and Control screens as drones, without altitude: one stick steers, the other drives.',
        bullets: [
          'Live: the rover box in 3D, its trail, the lidar map, a GPS track and attitude.',
          'Control: steer and drive sticks or sliders, AUTO, MANUAL and HOLD, a speed limit.',
          'Program: drive to waypoints, wait, change the speed limit.',
          'Lidar points accumulate into a map around the rover (10 cm grid).',
        ],
      ),
      Step.rich(
        'Complete example',
        'Odometry and the lidar are stubs; plug in your encoders and your lidar driver (RPLidar, LD06…).',
        complete: true,
        c: {
          'arduino': [
            'cpp',
            r'''// Rover: differential drive, wheel odometry, 2D lidar, waypoints.
#include <KoebeltLink.h>

KLink klink("Mule", KLink::ROVER);
KParam maxSpeed, turnGain;

const int LEFT_PWM = 25, RIGHT_PWM = 26;   // motor driver inputs
float x = 0, y = 0, heading = 0, speed = 0; // odometry, metres from home
float goalX = 0, goalY = 0;
bool goingTo = false;
float scan[360][3];                         // lidar points, metres

void drive(float fwd, float turn) {         // each −1…1
  float l = constrain(fwd - turn, -1.0f, 1.0f), r = constrain(fwd + turn, -1.0f, 1.0f);
  analogWrite(LEFT_PWM, (int)(127 + l * 127));
  analogWrite(RIGHT_PWM, (int)(127 + r * 127));
  speed = fwd * (float)maxSpeed;
}

void readOdometry(float dt) {               // replace with your wheel encoders
  x += cosf(heading) * speed * dt;
  y += sinf(heading) * speed * dt;
}

int readLidar() {                           // replace with your lidar driver
  for (int i = 0; i < 360; i++) {
    float a = heading + i * 0.01745f;
    scan[i][0] = x + cosf(a) * 3;
    scan[i][1] = y + sinf(a) * 3;
    scan[i][2] = 0.2f;
  }
  return 360;
}

void setup() {
  pinMode(LEFT_PWM, OUTPUT);
  pinMode(RIGHT_PWM, OUTPUT);
  klink.setModel("4WD rover · 6 kg");
  klink.setSensors("IMU,WHEEL ODOM,2D LIDAR");
  klink.begin("your-ssid", "your-password");
  maxSpeed = klink.param("MAX_SPD", 1.5, 0.2, 4, "m/s");
  turnGain = klink.param("TURN_GAIN", 1.2, 0, 4);

  klink.onControl([](const KControl& c) {
    if (klink.mode() == KMode::MANUAL) drive(c.ry * klink.speedLimit() * 2, -c.lx);
  });
  klink.onStop([] { drive(0, 0); goingTo = false; });
  klink.onMode([](KMode m) {
    goingTo = false;
    if (m == KMode::HOLD) drive(0, 0);
  });
  klink.onCommand([](const char* c, JsonObjectConst a) {
    if (!strcmp(c, "goto")) {
      goalX = a["x"] | x;
      goalY = a["y"] | y;
      goingTo = true;
      klink.setMode(KMode::AUTO);
    } else if (!strcmp(c, "sethome")) {
      x = y = 0;
    }
  });
  klink.failsafe(1000, KMode::HOLD);
}

void loop() {
  static uint32_t last = millis(), lastScan = 0;
  float dt = (millis() - last) / 1000.0f;
  last = millis();
  readOdometry(dt);

  if (goingTo && klink.armed() && !klink.stopped()) {
    float dx = goalX - x, dy = goalY - y, dist = sqrtf(dx * dx + dy * dy);
    float err = atan2f(dy, dx) - heading;
    err = atan2f(sinf(err), cosf(err));
    if (dist < 0.3f) {
      drive(0, 0);
      goingTo = false;
      klink.setMode(KMode::HOLD);         // the app moves to the next step
    } else {
      drive(fminf(dist, (float)maxSpeed) / 4, err * turnGain);
    }
  }

  klink.position(x, y, 0);
  klink.attitude(0, 0, heading);
  klink.velocity(cosf(heading) * speed, sinf(heading) * speed, 0);
  klink.battery(12.4, 76);
  if (millis() - lastScan > 200) {         // 5 scans a second is plenty
    lastScan = millis();
    klink.points(scan, readLidar());
  }
  klink.update();
}''',
          ],
          'python': [
            'python',
            r'''"""Rover on a Raspberry Pi: differential drive, odometry, 2D lidar."""
import math

from koebelt_link import Device

dev = Device("Mule", kind="rover", model="4WD rover · 6 kg", sensors=["IMU", "WHEEL ODOM", "2D LIDAR"])
dev.connect(wifi=True)
dev.failsafe(timeout=1.0, action="hold")
max_speed = dev.param("MAX_SPD", 1.5, min=0.2, max=4, unit="m/s")
state = {"x": 0.0, "y": 0.0, "h": 0.0, "v": 0.0, "goal": None}


def drive(fwd, turn):
    """Replace with your motor driver."""
    state["v"] = fwd * max_speed.value


@dev.on_control
def sticks(c):
    if dev.mode == "MANUAL":
        drive(c.ry * dev.speed * 2, -c.lx)


@dev.on_stop
def stop():
    drive(0, 0)
    state["goal"] = None


@dev.on_command
def command(name, a):
    if name == "goto":
        state["goal"] = (a["x"], a["y"])
        dev.set_mode("AUTO")
    elif name == "sethome":
        state["x"] = state["y"] = 0.0


def loop():
    dt = 1 / 50
    state["x"] += math.cos(state["h"]) * state["v"] * dt   # replace with encoders
    state["y"] += math.sin(state["h"]) * state["v"] * dt
    goal = state["goal"]
    if goal and dev.armed and not dev.estop:
        dx, dy = goal[0] - state["x"], goal[1] - state["y"]
        if math.hypot(dx, dy) < 0.3:
            drive(0, 0)
            state["goal"] = None
            dev.set_mode("HOLD")
        else:
            err = math.atan2(dy, dx) - state["h"]
            drive(min(math.hypot(dx, dy), max_speed.value) / 4, math.atan2(math.sin(err), math.cos(err)))
    dev.publish("pos", x=state["x"], y=state["y"], z=0)
    dev.publish("att", roll=0, pitch=0, yaw=state["h"])
    dev.battery(12.4, 76)
    dev.publish("lidar", points=[(state["x"] + 3 * math.cos(a / 57.3), state["y"] + 3 * math.sin(a / 57.3), 0.2) for a in range(0, 360, 2)])


dev.run(hz=50, loop=loop)''',
          ],
          'ros2': [
            'yaml',
            r'''# A rover that already runs ROS 2 (Nav2, diff_drive_controller…)
name: Mule
kind: rover
transport: wifi

sensors:
  imu: /imu/data
  odom: /odom              # nav_msgs/Odometry -> position, velocity, heading
  lidar: /scan_cloud       # sensor_msgs/PointCloud2 (convert /scan with laser_geometry)
  gps: /fix
  power: /battery_state

controls:
  twist: /cmd_vel          # sticks -> Twist in MANUAL while armed
  mode: /koebelt/mode
  max_linear: 1.5
  max_angular: 2.0

safety:
  stop_service: /robot/estop
  failsafe_timeout: 1.0
  failsafe_action: hold''',
          ],
        },
      ),
    ],
  ),

  // ---------------------------------------------------------------- arm
  Guide(
    'ex-arm',
    'Robot arm',
    'Six joints: jog, Cartesian jog, poses, home pose and gripper.',
    15,
    section: 'devices',
    kind: 'arm',
    platforms: ['arduino', 'python', 'ros2'],
    [
      Step.rich(
        'What the app gives you',
        'The arm is drawn from its six joint angles with a standard 6-axis model.',
        bullets: [
          'Control: hold-to-jog buttons per joint or in X, Y and Z, Home pose, Set as home, gripper open and close, a speed limit.',
          'Program: move to poses (record them with "Use current pose"), gripper and wait steps.',
          'Live: joints bars, motor current, the arm in 3D.',
        ],
      ),
      Step.rich(
        'Commands to handle',
        'Arms get these instead of sticks:',
        bullets: [
          'jog [j1…j6]: joint velocities −1…1 while a button is held, all zero on release.',
          'cart [x, y, z]: Cartesian jog −1…1; translate it with your inverse kinematics.',
          'pose {j: [6 angles in rad]}: move there, then the app waits until the joints match.',
          'home: move to your home pose. sethome {j}: store a new home pose.',
          'gripper {v}: 0 closed … 1 open.',
        ],
      ),
      Step.rich(
        'Complete example',
        'Servos or steppers behind a simple position interface. Joint speed follows the app speed limit.',
        complete: true,
        c: {
          'arduino': [
            'cpp',
            r'''// 6-axis desktop arm with position-controlled servos.
#include <KoebeltLink.h>

KLink klink("Cell arm", KLink::ARM);
float joints[6] = {0, -0.5f, 1.1f, 0, 0.6f, 0};   // rad, measured
float target[6] = {0, -0.5f, 1.1f, 0, 0.6f, 0};   // rad
float jogVel[6] = {0};
float homePose[6] = {0, -0.5f, 1.1f, 0, 0.6f, 0};
float gripper = 0.5f;

void writeServos() {}                // replace: send target[] and gripper to the servos
void readEncoders() {                // replace: read the real joint angles
  for (int i = 0; i < 6; i++) joints[i] += (target[i] - joints[i]) * 0.2f;
}

void setPose(const float* p) {
  for (int i = 0; i < 6; i++) target[i] = p[i];
}

void setup() {
  klink.setModel("6-axis desktop arm · 1 kg payload");
  klink.setSensors("JOINT ENCODERS,MOTOR CURRENT");
  klink.beginBLE();                   // or klink.begin(ssid, pass) / klink.beginSerial(Serial)
  klink.onJog([](const float* v) {
    for (int i = 0; i < 6; i++) jogVel[i] = v[i];
  });
  klink.onStop([] {
    for (int i = 0; i < 6; i++) { jogVel[i] = 0; target[i] = joints[i]; }   // freeze where it is
  });
  klink.onCommand([](const char* c, JsonObjectConst a) {
    if (!strcmp(c, "pose")) {
      JsonArrayConst j = a["j"];
      for (int i = 0; i < 6 && i < (int)j.size(); i++) target[i] = j[i];
    } else if (!strcmp(c, "home")) {
      setPose(homePose);
    } else if (!strcmp(c, "sethome")) {
      JsonArrayConst j = a["j"];
      for (int i = 0; i < 6; i++) homePose[i] = i < (int)j.size() ? (float)j[i] : joints[i];
    } else if (!strcmp(c, "gripper")) {
      gripper = a["v"] | gripper;
    }
  });
}

void loop() {
  static uint32_t last = millis();
  float dt = (millis() - last) / 1000.0f;
  last = millis();
  if (klink.armed() && !klink.stopped()) {
    for (int i = 0; i < 6; i++) target[i] += jogVel[i] * 1.2f * klink.speedLimit() * 2 * dt;
    writeServos();
  }
  readEncoders();
  klink.joints(joints, 6);
  klink.tool(0.4f, 0, 0.6f, gripper);  // tool position from your forward kinematics
  klink.battery(12.0, 100, 1.4f);      // supply voltage and motor current
  klink.update();
}''',
          ],
          'python': [
            'python',
            r'''"""6-axis arm on USB or a Raspberry Pi."""
from koebelt_link import Device

dev = Device("Cell arm", kind="arm", model="6-axis desktop arm · 1 kg payload", sensors=["JOINT ENCODERS", "MOTOR CURRENT"])
dev.connect(wifi=True)                       # or serial="/dev/ttyACM0", ble=True
arm = {"joints": [0, -0.5, 1.1, 0, 0.6, 0], "target": [0, -0.5, 1.1, 0, 0.6, 0], "jog": [0.0] * 6, "gripper": 0.5}
home = list(arm["target"])


@dev.on_jog
def jog(v):
    arm["jog"] = v


@dev.on_stop
def stop():
    arm["jog"] = [0.0] * 6
    arm["target"] = list(arm["joints"])


@dev.on_command
def command(name, a):
    global home
    if name == "pose":
        arm["target"] = list(a["j"])
    elif name == "home":
        arm["target"] = list(home)
    elif name == "sethome":
        home = list(a.get("j", arm["joints"]))
    elif name == "gripper":
        arm["gripper"] = a["v"]


def loop():
    dt = 1 / 50
    if dev.armed and not dev.estop:
        arm["target"] = [t + v * 1.2 * dev.speed * 2 * dt for t, v in zip(arm["target"], arm["jog"])]
    arm["joints"] = [j + (t - j) * 0.2 for j, t in zip(arm["joints"], arm["target"])]   # replace with servos
    dev.publish("joints", arm["joints"])
    dev.publish("tool", x=0.4, y=0.0, z=0.6, gripper=arm["gripper"])
    dev.battery(12.0, 100, amps=1.4)


dev.run(hz=50, loop=loop)''',
          ],
          'ros2': [
            'yaml',
            r'''# An arm driven by ros2_control and MoveIt Servo
name: Cell arm
kind: arm
transport: wifi

sensors:
  joints: /joint_states          # sensor_msgs/JointState (first six positions)

controls:
  jog: /servo_node/delta_joint_cmds
  joint_names: [joint_1, joint_2, joint_3, joint_4, joint_5, joint_6]
  mode: /koebelt/mode

safety:
  stop_service: /arm/estop
  failsafe_timeout: 1.0
  failsafe_action: hold''',
          ],
        },
      ),
    ],
  ),

  // ---------------------------------------------------------------- rocket
  Guide(
    'ex-rocket',
    'Rocket',
    'A flight computer with pad checks, countdown, flight phases and pyro channels.',
    15,
    section: 'devices',
    kind: 'rocket',
    platforms: ['arduino', 'python'],
    [
      Step.rich(
        'What the app gives you',
        'Rockets fly their own state machine: the app watches, arms and counts down, but never steers.',
        bullets: [
          'Control: flight phase, pre-flight checks (pyro continuity, GPS, link, armed), arm, countdown, abort, manual deploy.',
          'Live: flight phase list, altitude, vertical speed, pyro channels, 200 G accelerometer.',
          'The failsafe does not apply to rockets: losing the link never changes the flight.',
        ],
      ),
      Step.rich(
        'Phases and commands',
        'Report the phase with setMode. The app shows it and enables the matching buttons.',
        table: [
          ['Phase', 'Meaning', 'Commands the app may send'],
          ['PAD', 'On the pad', 'arm, countdown {s}'],
          ['COUNT', 'Counting down', 'abort'],
          ['BOOST', 'Motor burning', '–'],
          ['COAST', 'Climbing, motor out', 'deploy {ch: 0}'],
          ['DROGUE', 'Drogue out, descending fast', 'deploy {ch: 1}'],
          ['MAIN', 'Main out', '–'],
          ['LANDED', 'On the ground', 'reset'],
        ],
      ),
      Step.rich(
        'Complete example',
        'Launch detection from acceleration and apogee from the barometer. Pyro outputs fire for PYRO_PULSE ms.',
        complete: true,
        c: {
          'arduino': [
            'cpp',
            r'''// Rocket flight computer: phases, pyro, countdown.
#include <KoebeltLink.h>
#include <LoRa.h>        // sandeepmistry/arduino-LoRa: include it so the IDE links it

KLink klink("Nova", KLink::ROCKET);
KParam mainAlt, pulseMs, launchG;
const int PYRO[2] = {12, 13}, SENSE[2] = {34, 35};   // fire and continuity pins
float alt = 0, maxAlt = 0, vz = 0, accelZ = 9.81f, countdown = 0;
uint32_t phaseStart = 0;
bool fired[2] = {false, false};

float readBaroAlt() { return alt; }          // replace with your barometer
float readAccelZ() { return 9.81f; }        // replace with your IMU (m/s², 200 G)

void phase(KMode m) {
  klink.setMode(m);
  phaseStart = millis();
}

void fire(int ch) {
  if (fired[ch] || !klink.armed()) return;
  digitalWrite(PYRO[ch], HIGH);
  delay((uint32_t)(float)pulseMs);          // short, so blocking is acceptable here
  digitalWrite(PYRO[ch], LOW);
  fired[ch] = true;
}

const char* continuity(int ch) {
  return fired[ch] ? "FIRED" : digitalRead(SENSE[ch]) == HIGH ? "OK" : "-";
}

void setup() {
  for (int i = 0; i < 2; i++) { pinMode(PYRO[i], OUTPUT); pinMode(SENSE[i], INPUT); }
  klink.setModel("Mid-power rocket · H128");
  klink.setSensors("IMU 200 G,BARO,GPS,PYRO x2");
  klink.begin("your-ssid", "your-password");
  klink.fallback(KLink::LORA, 868E6);         // keep telemetry beyond Wi-Fi range
  mainAlt = klink.param("MAIN_ALT", 150, 50, 500, "m");
  pulseMs = klink.param("PYRO_PULSE", 500, 100, 2000, "ms");
  launchG = klink.param("LAUNCH_G", 3, 1.5, 10, "g");
  klink.onCommand([](const char* c, JsonObjectConst a) {
    KMode m = klink.mode();
    if (!strcmp(c, "countdown") && m == KMode::PAD && klink.armed()) {
      countdown = a["s"] | 10.0f;
      phase(KMode::COUNT);
    } else if (!strcmp(c, "abort") && m == KMode::COUNT) {
      phase(KMode::PAD);
      klink.setArmed(false);
    } else if (!strcmp(c, "deploy")) {
      int ch = a["ch"] | 0;
      fire(ch);
      phase(ch == 0 ? KMode::DROGUE : KMode::MAIN);
    } else if (!strcmp(c, "reset") && m == KMode::LANDED) {
      maxAlt = 0;
      fired[0] = fired[1] = false;
      phase(KMode::PAD);
    }
  });
  klink.onStop([] { if (klink.mode() == KMode::COUNT) phase(KMode::PAD); });
}

void loop() {
  static uint32_t last = millis();
  float dt = (millis() - last) / 1000.0f;
  last = millis();
  float prev = alt;
  alt = readBaroAlt();
  accelZ = readAccelZ();
  vz = dt > 0 ? (alt - prev) / dt : 0;
  maxAlt = fmaxf(maxAlt, alt);

  switch (klink.mode()) {
    case KMode::COUNT:
      countdown -= dt;
      if (countdown <= 0) phase(KMode::BOOST);   // or wait for launch detection
      break;
    case KMode::PAD:
      if (klink.armed() && accelZ > (float)launchG * 9.81f) phase(KMode::BOOST);
      break;
    case KMode::BOOST:
      if (accelZ < 9.81f) phase(KMode::COAST);
      break;
    case KMode::COAST:
      if (vz < 0) { fire(0); phase(KMode::DROGUE); }
      break;
    case KMode::DROGUE:
      if (alt < (float)mainAlt) { fire(1); phase(KMode::MAIN); }
      break;
    case KMode::MAIN:
      if (alt < 2 && fabsf(vz) < 0.5f) phase(KMode::LANDED);
      break;
    default:
      break;
  }

  klink.position(0, 0, alt);
  klink.velocity(0, 0, vz);
  klink.imu(0, 0, accelZ, 0, 0, 0);
  klink.rocketState(maxAlt, (millis() - phaseStart) / 1000.0f, countdown);
  klink.setPyro(continuity(0), continuity(1), "-", "-");
  klink.battery(7.6, 90);
  klink.update();
}''',
          ],
          'python': [
            'python',
            r'''"""Rocket ground test rig or a Linux flight computer (phases and pyro)."""
import time

from koebelt_link import Device

dev = Device("Nova", kind="rocket", model="Mid-power rocket · H128", sensors=["IMU 200 G", "BARO", "GPS", "PYRO x2"])
dev.connect(wifi=True)
main_alt = dev.param("MAIN_ALT", 150, min=50, max=500, unit="m")
st = {"alt": 0.0, "max": 0.0, "vz": 0.0, "count": 0.0, "since": time.monotonic(), "pyro": ["OK", "OK", "-", "-"]}


def phase(name):
    dev.set_mode(name)
    st["since"] = time.monotonic()


def fire(ch):
    if dev.armed and st["pyro"][ch] == "OK":
        st["pyro"][ch] = "FIRED"     # drive the pyro output here


@dev.on_command
def command(name, a):
    if name == "countdown" and dev.mode == "PAD" and dev.armed:
        st["count"] = a.get("s", 10)
        phase("COUNT")
    elif name == "abort" and dev.mode == "COUNT":
        phase("PAD")
        dev.set_armed(False)
    elif name == "deploy":
        fire(a.get("ch", 0))
        phase("DROGUE" if a.get("ch", 0) == 0 else "MAIN")
    elif name == "reset" and dev.mode == "LANDED":
        st.update(max=0.0, pyro=["OK", "OK", "-", "-"])
        phase("PAD")


def loop():
    if dev.mode == "COUNT":
        st["count"] -= 1 / 20
        if st["count"] <= 0:
            phase("BOOST")
    # ... read the barometer into st["alt"], st["vz"] and run COAST/DROGUE/MAIN like the Arduino tab
    st["max"] = max(st["max"], st["alt"])
    dev.publish("pos", x=0, y=0, z=st["alt"])
    dev.publish("vel", vx=0, vy=0, vz=st["vz"])
    dev.publish("rocket", st["max"], time.monotonic() - st["since"], max(0.0, st["count"]))
    dev.set_state(pyro=st["pyro"])
    dev.battery(7.6, 90)


dev.set_mode("PAD")
dev.run(hz=20, loop=loop)''',
          ],
        },
        warn: true,
        note: 'Follow your rocketry association rules (NAR, Tripoli, national bodies). Keep the pyro channels physically disarmed (shunt or key switch) until the rocket is on the pad.',
      ),
    ],
  ),

  // ---------------------------------------------------------------- bench
  Guide(
    'ex-bench',
    'Thrust bench',
    'Motor and propeller testing: throttle, sequences, cutoffs and efficiency.',
    12,
    section: 'devices',
    kind: 'bench',
    platforms: ['arduino', 'python'],
    [
      Step.rich(
        'What the app gives you',
        'The test-bench screen is built for measurements rather than driving.',
        bullets: [
          'Throttle slider and 0/25/50/75/100 % presets, enabled only when armed.',
          'Ramp and step sequences, recorded automatically, with live thrust, RPM and current charts.',
          'Readouts for thrust, RPM, current, power, temperature and efficiency (g/W).',
          'Cutoff notices when your firmware stops the motor on a limit.',
        ],
      ),
      Step.rich(
        'Commands to handle',
        'Everything goes through commands:',
        bullets: [
          'throttle {v}: 0…1. Write it to the ESC.',
          'seq {kind: "RAMP" | "STEPS"} starts a built-in sequence; {kind: null} stops it. Report RAMP or STEPS while it runs and IDLE after.',
          'clear: acknowledge a cutoff. Report IDLE.',
          'Program sequences (Program tab) send throttle commands step by step, so they work without seq support.',
        ],
      ),
      Step.rich(
        'Complete example',
        'Load cell, optical tachometer, current shunt, thermistor. Limits are parameters you can change from the Tune screen.',
        complete: true,
        c: {
          'arduino': [
            'cpp',
            r'''// Thrust bench: ESC, load cell, tachometer, current, temperature.
#include <KoebeltLink.h>

KLink klink("Thrust bench", KLink::BENCH);
KParam maxCurrent, maxTemp, rampTime;
float throttle = 0, seqT = 0;
bool ramping = false;

void writeEsc(float t) {}                       // replace: 1000–2000 µs pulse on the ESC pin
float readThrustN() { return throttle * 18; }   // replace: HX711 load cell
float readRpm() { return throttle * 9000; }     // replace: optical tachometer
float readCurrentA() { return throttle * 30; }  // replace: shunt (INA228…)
float readTempC() { return 30; }                // replace: NTC thermistor

void setThrottle(float t) {
  throttle = constrain(t, 0.0f, 1.0f);
  writeEsc(throttle);
}

void setup() {
  klink.setModel("Motor test stand · 25 kg load cell");
  klink.setSensors("LOAD CELL,RPM,CURRENT,TEMP");
  klink.beginSerial(Serial);                     // USB: lowest latency on the bench
  maxCurrent = klink.param("MAX_CURRENT", 45, 5, 120, "A");
  maxTemp = klink.param("MAX_TEMP", 90, 40, 150, "C");
  rampTime = klink.param("RAMP_TIME", 10, 2, 60, "s");
  klink.onStop([] { ramping = false; setThrottle(0); });
  klink.onArm([](bool a) { if (!a) setThrottle(0); });
  klink.onCommand([](const char* c, JsonObjectConst a) {
    if (!strcmp(c, "throttle") && klink.armed()) {
      setThrottle(a["v"] | 0.0f);
      klink.setMode(throttle > 0 ? KMode::MANUAL : KMode::IDLE);
    } else if (!strcmp(c, "seq")) {
      ramping = klink.armed() && !a["kind"].isNull();
      seqT = 0;
      if (!ramping) setThrottle(0);
      klink.setMode(ramping ? KMode::RAMP : KMode::IDLE);
    } else if (!strcmp(c, "clear")) {
      klink.setCutoff(nullptr);
      klink.setMode(KMode::IDLE);
    }
  });
}

void loop() {
  static uint32_t last = millis();
  float dt = (millis() - last) / 1000.0f;
  last = millis();
  if (ramping) {
    seqT += dt;
    float rt = rampTime;
    setThrottle(seqT < rt ? seqT / rt : seqT < rt + 2 ? 1 : 0);
    if (seqT > rt + 2) { ramping = false; klink.setMode(KMode::IDLE); }
  }
  float amps = readCurrentA(), temp = readTempC(), thrust = readThrustN();
  if (amps > (float)maxCurrent || temp > (float)maxTemp) {   // the firmware enforces limits
    ramping = false;
    setThrottle(0);
    klink.setCutoff(amps > (float)maxCurrent ? "Current limit" : "Temperature limit");
    klink.setMode(KMode::CUTOFF);
  }
  klink.thrust(thrust, thrust * 0.012f);
  klink.rpm(readRpm());
  klink.battery(22.2f, 100, amps);
  klink.temperature(temp);
  klink.throttleOut(throttle);
  klink.update();
}''',
          ],
          'python': [
            'python',
            r'''"""Thrust bench on a Raspberry Pi (HX711 load cell, ESC via pigpio)."""
from koebelt_link import Device

dev = Device("Thrust bench", kind="bench", model="Motor test stand", sensors=["LOAD CELL", "RPM", "CURRENT", "TEMP"])
dev.connect(serial="/dev/ttyUSB0")            # or wifi=True
max_current = dev.param("MAX_CURRENT", 45, min=5, max=120, unit="A")
s = {"throttle": 0.0}


def set_throttle(v):
    s["throttle"] = max(0.0, min(1.0, v))     # write the ESC pulse here


dev.on_stop(lambda: set_throttle(0))


@dev.on_command
def command(name, a):
    if name == "throttle" and dev.armed:
        set_throttle(a["v"])
        dev.set_mode("MANUAL" if s["throttle"] > 0 else "IDLE")
    elif name == "clear":
        dev.set_state(cutoff=None)
        dev.set_mode("IDLE")


def loop():
    thrust, rpm, amps, temp = s["throttle"] * 18, s["throttle"] * 9000, s["throttle"] * 30, 30.0  # read sensors
    if amps > max_current.value:
        set_throttle(0)
        dev.set_state(cutoff="Current limit")
        dev.set_mode("CUTOFF")
    dev.publish("thrust", thrust=thrust, torque=thrust * 0.012)
    dev.publish("rpm", rpm=rpm)
    dev.publish("temp", temp=temp)
    dev.publish("throttle", throttle=s["throttle"])
    dev.battery(22.2, 100, amps=amps)


dev.run(hz=60, loop=loop)''',
          ],
        },
      ),
    ],
  ),

  // ---------------------------------------------------------------- generic
  Guide(
    'ex-generic',
    'Custom device',
    'Anything else, like a greenhouse controller: custom sensors, parameters and commands.',
    10,
    section: 'devices',
    kind: 'generic',
    platforms: ['arduino', 'python', 'rust'],
    [
      Step.rich(
        'What the app gives you',
        'A generic device has no kind-specific screen. Everything comes from what it declares:',
        bullets: [
          'Live: a tile and HUD widget for every channel you declare, with charts, values and the inspector.',
          'Tune: every parameter you declare, grouped by the prefix before the first underscore.',
          'Program: Wait and Custom command steps, so you can script your own actions.',
          'Replay and CSV export with one column per channel axis.',
        ],
      ),
      Step.rich(
        'Complete example',
        'A greenhouse: two climate sensors, four soil probes, a target temperature and a vent the app can open.',
        complete: true,
        c: {
          'arduino': [
            'cpp',
            r'''// Greenhouse controller: custom channels, parameters and commands.
#include <KoebeltLink.h>

KLink klink("Greenhouse", KLink::GENERIC);
KChannel climate, soil;
KParam targetTemp, ventOpenAt;
float ventPosition = 0;                  // 0 closed … 1 open

void setVent(float v) { ventPosition = constrain(v, 0.0f, 1.0f); }   // drive the actuator here

void setup() {
  klink.setModel("Greenhouse controller");
  klink.setSensors("SHT45,SOIL x4");
  klink.begin("your-ssid", "your-password");
  // id, axes, unit, nominal rate: each becomes a tile, a HUD widget and CSV columns
  climate = klink.channel("climate", {"Temp", "Humidity"}, "", 1);
  soil = klink.channel("soil_moisture", {"Bed 1", "Bed 2", "Bed 3", "Bed 4"}, "%", 0.2f);
  targetTemp = klink.param("CLIMATE_TARGET", 22, 10, 35, "C");
  ventOpenAt = klink.param("CLIMATE_VENT_AT", 26, 15, 40, "C");
  // Triggered from Program > Custom command, e.g. name "vent", value 0.5
  klink.onCommand([](const char* c, JsonObjectConst a) {
    if (!strcmp(c, "vent")) setVent(a["v"] | 0.0f);
  });
}

void loop() {
  static uint32_t lastClimate = 0, lastSoil = 0;
  if (millis() - lastClimate > 1000) {
    lastClimate = millis();
    float t = 24.5f, h = 61;             // read your sensor here
    climate.publish(t, h);
    if (t > (float)ventOpenAt) setVent(1);
  }
  if (millis() - lastSoil > 5000) {
    lastSoil = millis();
    soil.publish(analogRead(32) / 40.95f, analogRead(33) / 40.95f, analogRead(34) / 40.95f, analogRead(35) / 40.95f);
  }
  klink.update();
}''',
          ],
          'python': [
            'python',
            r'''"""Greenhouse controller on a Raspberry Pi."""
from koebelt_link import Device

dev = Device("Greenhouse", kind="generic", model="Greenhouse controller", sensors=["SHT45", "SOIL x4"])
dev.connect(wifi=True)
climate = dev.channel("climate", axes=["Temp", "Humidity"], unit="", hz=1)
soil = dev.channel("soil_moisture", axes=["Bed 1", "Bed 2", "Bed 3", "Bed 4"], unit="%", hz=0.2)
target = dev.param("CLIMATE_TARGET", 22, min=10, max=35, unit="C", label="Target temperature")
vent_at = dev.param("CLIMATE_VENT_AT", 26, min=15, max=40, unit="C", label="Open vent above")
vent = {"pos": 0.0}


@dev.on_command
def command(name, a):
    if name == "vent":                       # Program > Custom command "vent", value 0…1
        vent["pos"] = max(0.0, min(1.0, a.get("v", 0)))


def loop():
    t, h = 24.5, 61.0                        # read your sensor here
    climate.publish(t, h)
    soil.publish(42, 38, 55, 47)
    if t > vent_at.value:
        vent["pos"] = 1.0


dev.run(hz=1, loop=loop)''',
          ],
          'rust': [
            'rust',
            r'''//! Greenhouse controller on Linux.
use koebelt_link::{Device, Kind};

fn main() -> std::io::Result<()> {
    let mut dev = Device::new("Greenhouse", Kind::Generic).model("Greenhouse controller").wifi("", "").start()?;
    let climate = dev.channel("climate", &["Temp", "Humidity"], "", 1.0);
    let soil = dev.channel("soil_moisture", &["Bed 1", "Bed 2", "Bed 3", "Bed 4"], "%", 0.2);
    let vent_at = dev.link.param("CLIMATE_VENT_AT", 26.0, 15.0, 40.0, "C");
    dev.on_command(|name, args| {
        if name == "vent" {
            println!("vent -> {:?}", args.value()); // drive the actuator here
        }
    });
    loop {
        let (t, h) = (24.5, 61.0); // read your sensor here
        dev.publish(climate, &[t, h])?;
        dev.publish(soil, &[42.0, 38.0, 55.0, 47.0])?;
        if t > dev.link.param_value(vent_at) {
            println!("too warm: open the vent");
        }
        dev.tick_blocking(10.0);
    }
}''',
          ],
        },
      ),
    ],
  ),
];
