// Guides: how each connection works.
import 'guides_data.dart';

const connectionGuides = [
  Guide(
    'link',
    'How the link works',
    'One message format over every transport, and who is responsible for what.',
    6,
    section: 'connections',
    platforms: ['arduino', 'python', 'rust', 'ros2'],
    [
      Step.rich(
        'One message format everywhere',
        'Every message is one small JSON object with a type field t. Wi-Fi sends one message per UDP datagram; USB serial, BLE and radio links send one message per line. Because it is plain text, a serial monitor is enough to see what your device sends.',
        c: {
          'arduino': [
            'json',
            '{"t":"tlm","ts":81234,"d":{"imu":[0.1,0,9.8,0,0,0.2],"bat":[15.8,12.1,80]}}\n{"t":"state","mode":"AUTO","armed":true,"estop":false,"fs":false,"ext":{}}',
          ],
          'python': [
            'json',
            '{"t":"tlm","ts":81234,"d":{"imu":[0.1,0,9.8,0,0,0.2],"bat":[15.8,12.1,80]}}\n{"t":"state","mode":"AUTO","armed":true,"estop":false,"fs":false,"ext":{}}',
          ],
          'rust': [
            'json',
            '{"t":"tlm","ts":81234,"d":{"imu":[0.1,0,9.8,0,0,0.2],"bat":[15.8,12.1,80]}}\n{"t":"state","mode":"AUTO","armed":true,"estop":false,"fs":false,"ext":{}}',
          ],
          'ros2': [
            'json',
            '{"t":"tlm","ts":81234,"d":{"imu":[0.1,0,9.8,0,0,0.2],"bat":[15.8,12.1,80]}}\n{"t":"state","mode":"AUTO","armed":true,"estop":false,"fs":false,"ext":{}}',
          ],
        },
        note: 'The full specification is protocol/PROTOCOL.md in the repository. You never write these messages yourself: the library does.',
      ),
      Step.rich(
        'What happens when you connect',
        'The library answers the app and then keeps the session going on its own:',
        bullets: [
          'Hello: the app introduces itself (with the pairing key); the device answers with its name, kind, model and sensors.',
          'Description: the device sends its parameter table and its custom channels. The Tune screen and the extra tiles are built from them.',
          'Telemetry: the latest value of every channel you published, at the rate chosen in Settings (10, 30 or 60 Hz). Publishing faster is fine; older values are dropped.',
          'State: mode, armed, stop and failsafe, on every change and twice a second.',
          'Control: the app sends the four stick axes 20 times a second, even when they are zero. This is the heartbeat the failsafe watches.',
          'Ping: once a second, so the app can show latency.',
        ],
      ),
      Step.rich(
        'Who does what',
        'The app is a remote: it never closes a control loop over the radio. Your firmware keeps doing the real work.',
        table: [
          ['', 'App', 'Library on the device', 'Your code'],
          ['Sensors', 'Draws, records, exports', 'Batches, rate-limits, sends', 'Reads the hardware, publishes'],
          ['Sticks and modes', 'Sends axes 20×/s and mode changes', 'Calls your callbacks', 'Drives the motors'],
          [
            'Waypoints, poses',
            'Uploads sequences, or runs them step by step',
            'Stores and runs them, calls your handlers',
            'Navigates, reports AUTO then HOLD',
          ],
          ['STOP', 'Sends it three times', 'Calls onStop, disarms, blocks motion', 'Cuts the motors'],
          ['Link loss', 'Shows it in the top bar', 'Fires the failsafe after 1.8 s', 'Holds, returns home or lands'],
        ],
      ),
      Step.rich(
        'Choosing a transport',
        'You can open more than one transport. The first one is primary; the others take over telemetry when the failsafe trips. Radio links follow their radio\'s profile, and telemetry-only radios accept nothing but STOP.',
        table: [
          ['Transport', 'Typical latency', 'Range', 'Max telemetry', 'App platforms', 'Good for'],
          ['Wi-Fi (UDP)', '10–30 ms', '~100 m, more with a router', '60 Hz + point cloud + video', 'All', 'Most projects'],
          ['BLE', '30–60 ms', '~30 m', '30 Hz, small clouds', 'All', 'Arms, small robots, phones without Wi-Fi'],
          ['USB serial', '2–5 ms', 'Cable', '60 Hz + point cloud', 'macOS, Windows, Linux, Android', 'Bench work, arms'],
          ['Radio: SiK, XBee', '50–150 ms', '1–40 km', '5 Hz, control 10 Hz', 'Through a USB radio', 'Drones and rovers beyond Wi-Fi'],
          ['Radio: HC-12', '100–200 ms', '~1 km', '2 Hz, control 5 Hz', 'Through a USB radio', 'Cheap long-range control'],
          ['Radio: LoRa', '200–600 ms', '2–10 km', '2 Hz, telemetry only', 'Through a USB ground station', 'Rockets, long-range fallback'],
        ],
      ),
    ],
  ),
  Guide(
    'boards',
    'Supported boards',
    'Flight controllers, drones and boards that connect as they are, and those that run the koebelt/link library.',
    10,
    section: 'connections',
    platforms: [],
    [
      Step.rich(
        'Boards that connect as they are',
        'No library, no code: the app speaks their own protocol. Plug them in, power them on or join their Wi-Fi, then Devices > Pair device. They show up named, with what they run, and one tap connects.',
        table: [
          ['Board', 'Firmware', 'Link', 'In the app'],
          [
            'Pixhawk 6C / 6X, Cube Orange, Holybro, Matek, SpeedyBee, any ArduPilot board',
            'ArduPilot: Copter, Plane, Rover, Sub',
            'USB, telemetry radio, Wi-Fi (UDP 14550)',
            'Telemetry, map, Tune, arm, modes, sticks, take-off, go to, return, land, STOP',
          ],
          ['Pixhawk family with PX4', 'PX4', 'USB, telemetry radio, Wi-Fi (UDP 14550)', 'Same as ArduPilot'],
          [
            'Betaflight and INAV flight controllers (F4, F7, H7)',
            'Betaflight, INAV, EmuFlight',
            'USB',
            'Telemetry, PID tuning, STOP (disarm). Fly with your RC transmitter.',
          ],
          ['DJI / Ryze Tello, Tello EDU', 'Tello SDK', 'Wi-Fi: join TELLO-XXXXXX', 'Telemetry, take-off, sticks, land, short moves, STOP'],
        ],
      ),
      Step.rich(
        'Boards that run the library',
        'Everything else talks koebelt/link through the library on the board (or on the computer next to it):',
        table: [
          ['Board', 'Links'],
          ['ESP32, ESP32-S3, ESP32-C3, ESP32-CAM, Arduino Nano ESP32', 'Wi-Fi, Bluetooth LE, USB serial, radios'],
          ['ESP8266 (NodeMCU, Wemos D1 mini)', 'Wi-Fi, USB serial, radios'],
          ['Raspberry Pi Pico W', 'Wi-Fi, USB serial, radios'],
          ['Arduino UNO R4 WiFi', 'Wi-Fi, Bluetooth LE, USB serial'],
          ['Arduino Nano 33 IoT, MKR WiFi 1010, Nano RP2040 Connect', 'Wi-Fi, Bluetooth LE, USB serial'],
          ['Arduino Nano 33 BLE', 'Bluetooth LE, USB serial'],
          ['Teensy 4.x, STM32, any Arduino board', 'USB serial, radios'],
          ['Raspberry Pi, Jetson, any Linux or macOS computer', 'Python or Rust library, or the ROS 2 bridge'],
        ],
        note: 'On USB, the app recognises these boards by their USB id and asks them what they run, so a koebelt/link board shows up with its own name too.',
      ),
      Step.rich(
        'ArduPilot and PX4 (MAVLink)',
        'The app is a MAVLink ground station: it sends its heartbeat once a second, asks for telemetry, and maps its controls onto the autopilot\'s:',
        table: [
          ['App', 'ArduCopter', 'ArduPlane', 'ArduRover', 'PX4'],
          ['Manual (sticks)', 'ALT_HOLD', 'FBWA', 'MANUAL', 'ALTCTL'],
          ['Hold', 'LOITER', 'LOITER', 'HOLD', 'AUTO.LOITER'],
          ['Auto', 'AUTO', 'AUTO', 'AUTO', 'AUTO.MISSION'],
          ['Return home', 'RTL', 'RTL', 'RTL', 'AUTO.RTL'],
          ['Land', 'LAND', 'QLAND (VTOL)', 'HOLD', 'AUTO.LAND'],
          ['Take off', 'GUIDED + take-off', 'TAKEOFF', '–', 'take-off'],
        ],
        bullets: [
          'USB: plug the flight controller in. Pixhawk, Cube and other STM32 boards are recognised by their USB id and probed.',
          'Telemetry radio: Pair device > Radio > SiK telemetry radio, then Listen for device. SiK radios carry MAVLink as they are.',
          'Wi-Fi: anything that sends MAVLink to UDP port 14550 appears on its own: ESP8266/ESP32 telemetry bridges, a companion computer running mavlink-router or MAVProxy pointed at this device, or SITL. Or add it by IP address with MAVLink selected.',
          'Sticks are sent as MANUAL_CONTROL while armed in a manual mode. ArduPilot only accepts them from the ground station in SYSID_MYGCS (255, the default).',
          'Go to uses DO_REPOSITION. Sequences of take off, fly to, wait, land and return home are uploaded as a mission and flown in AUTO, so they carry on if the link drops. Both need a GPS fix and a home position.',
          'Parameters appear on the Tune screen, grouped by prefix. The autopilot saves them as soon as they are written.',
          'Tested against ArduCopter and ArduRover 4.7 and PX4 1.17 in simulation (SITL). You can run the same simulators yourself: tools/sitl in the repository.',
        ],
        warn: true,
        note: 'STOP force-disarms the vehicle: the motors stop even in flight, exactly as STOP does on every other device. Set FS_GCS_ENABLE (ArduPilot) or the data link loss action (PX4) so the vehicle acts on its own if the app goes away.',
      ),
      Step.rich(
        'Betaflight and INAV (MSP)',
        'Plug the flight controller in over USB; it shows up with its craft name and firmware. MSP is the configuration protocol of these firmwares, not a flight link, so the app:',
        bullets: [
          'shows attitude, altitude, battery, current, RSSI, GPS and the arming state;',
          'tunes the roll, pitch and yaw PID gains on the Tune screen, and Save writes them to the board;',
          'disarms on STOP (arming is disabled until you reset it in the app);',
          'does not send sticks: fly with your radio, as Betaflight is designed for.',
        ],
        note: 'Bench work only with props off: a quad on USB can still spin up if it is armed from the radio.',
      ),
      Step.rich(
        'Tello',
        'Join the Tello\'s Wi-Fi (TELLO-XXXXXX) from this phone or computer and open Pair device: the Tello appears under Wi-Fi. Arm, then Take off; sticks fly it in Manual, Hold hovers, Land lands, STOP stops the motors at once.',
        bullets: [
          'The Tello has no GPS. Its position in the app is worked out from its speed, so it drifts; Set home resets it.',
          'Go to sends short relative moves (20 cm to 5 m per axis).',
          'Its camera streams H.264, which the app does not show yet.',
        ],
      ),
    ],
  ),
  Guide(
    'wifi',
    'Wi-Fi',
    'Join a network, how the app finds the device, and what to do when it does not.',
    8,
    section: 'connections',
    platforms: ['arduino', 'python', 'rust', 'ros2'],
    [
      Step.rich(
        'Connect',
        'The device and the app must be on the same network. On ESP32 and Pico W the library joins it for you; on a computer it uses the network the OS is already on.',
        complete: true,
        c: {
          'arduino': [
            'cpp',
            r'''#include <KoebeltLink.h>
#include <WiFi.h>   // WiFi.localIP(), WiFi.RSSI()

KLink klink("Mule", KLink::ROVER);

void setup() {
  Serial.begin(115200);
  // Joins the network (15 s timeout) and listens on UDP 47800.
  if (!klink.begin("your-ssid", "your-password")) {
    Serial.println("Wi-Fi failed: check the name, the password and that it is 2.4 GHz");
  }
  Serial.print("IP address: ");
  Serial.println(WiFi.localIP());   // useful for "Add by IP address" in the app
}

void loop() {
  klink.battery(12.4, 80);
  klink.rssi(WiFi.RSSI());           // shown in the app's status bar
  klink.update();
}''',
          ],
          'python': [
            'python',
            r'''from koebelt_link import Device

dev = Device("Mule", kind="rover")
dev.connect(wifi=True)              # listens on UDP 47800 on every interface


def loop():
    dev.battery(12.4, 80)


dev.run(hz=50, loop=loop)''',
          ],
          'rust': [
            'rust',
            r'''use koebelt_link::{Device, Kind};

fn main() -> std::io::Result<()> {
    // On a computer the OS is already on the network; the credentials are ignored.
    let mut dev = Device::new("Mule", Kind::Rover).wifi("", "").start()?;
    loop {
        dev.battery(12.4, 80.0)?;
        dev.tick_blocking(50.0);
    }
}''',
          ],
          'ros2': ['yaml', 'name: Mule\nkind: rover\ntransport: wifi\nport: 47800'],
        },
        note: 'ESP32 boards only see 2.4 GHz networks. Name the 2.4 GHz band separately on your router if both bands share one name.',
      ),
      Step.rich(
        'How the app finds it',
        'Discovery uses two broadcasts on the local network, so no IP address needs typing:',
        table: [
          ['Port', 'Direction', 'What'],
          ['47801', 'Device to everyone', 'An announce message once a second while no app is connected: id, name, kind and the pairing code if pairing.'],
          ['47800', 'App to everyone', 'A discover message every two seconds while the Pair dialog is open. Every device answers with an announce.'],
          ['47800', 'App and device, both ways', 'The session itself, after the app says hello. The device only accepts commands from that app.'],
        ],
      ),
      Step.rich(
        'When the device does not show up',
        'Broadcasts are the first thing networks block. In order of likelihood:',
        bullets: [
          'Guest or "client isolation" networks stop devices from seeing each other. Use the main network or turn isolation off.',
          'The phone or laptop is on a different network (mobile data, a 5 GHz-only name, a VPN).',
          'A firewall on the computer running the app blocks UDP 47800 or 47801. Allow koebelt dash when the OS asks.',
          'Mesh routers and some offices drop broadcasts between access points. Use Pair device > add it by IP address instead; the device prints its IP on startup.',
          'On iOS the app needs the Local Network permission (Settings > koebelt dash).',
        ],
      ),
      Step.rich(
        'In the field: use the phone as hotspot',
        'Away from a router, turn on the phone or tablet hotspot and let the device join it. The app then reaches it directly. Hotspots usually allow broadcasts, so discovery still works.',
        note: 'Range on Wi-Fi is roughly 50–100 m line of sight with small antennas. Add a radio link as a fallback when you fly or drive further.',
      ),
    ],
  ),
  Guide(
    'ble',
    'Bluetooth LE',
    'The koebelt/link service, packet sizes, permissions and range.',
    6,
    section: 'connections',
    platforms: ['arduino', 'python', 'rust'],
    [
      Step.rich(
        'Advertise the service',
        'The device becomes a BLE peripheral with a Nordic-UART-style service. The app scans for that service and lists the device under Pair device > Nearby.',
        complete: true,
        c: {
          'arduino': [
            'cpp',
            r'''#include <KoebeltLink.h>

KLink klink("Cell arm", KLink::ARM);

void setup() {
  Serial.begin(115200);
  if (!klink.beginBLE()) Serial.println("This board has no Bluetooth (ESP32 only)");
}

void loop() {
  const float joints[6] = {0, -0.5, 1.1, 0, 0.6, 0};
  klink.joints(joints, 6);
  klink.update();
}''',
          ],
          'python': [
            'python',
            r'''# pip install "koebelt-link[ble]"   (uses bless; Linux with BlueZ, macOS or Windows)
from koebelt_link import Device

dev = Device("Cell arm", kind="arm")
dev.connect(ble=True)


def loop():
    dev.publish("joints", [0, -0.5, 1.1, 0, 0.6, 0])


dev.run(hz=30, loop=loop)''',
          ],
          'rust': [
            'rust',
            r'''// Cargo.toml: koebelt-link = { version = "1.0", features = ["ble"] }
// Linux (BlueZ): sudo apt install libdbus-1-dev pkg-config. macOS and Windows as they are.
use koebelt_link::{Device, Kind};

fn main() -> std::io::Result<()> {
    let mut dev = Device::new("Cell arm", Kind::Arm).ble().start()?;
    loop {
        dev.link.joints(&[0.0, -0.5, 1.1, 0.0, 0.6, 0.0]);
        dev.tick_blocking(30.0);
    }
}''',
          ],
        },
      ),
      Step.rich(
        'How it works',
        'BLE moves small packets, so messages are cut into pieces and joined again at each newline.',
        table: [
          ['Characteristic', 'UUID', 'Use'],
          ['Service', '6e400001-b5a3-f393-e0a9-e50e24dcca9e', 'Advertised; the app filters on it'],
          ['RX (write)', '6e400002-b5a3-f393-e0a9-e50e24dcca9e', 'App to device, write without response'],
          ['TX (notify)', '6e400003-b5a3-f393-e0a9-e50e24dcca9e', 'Device to app, notifications'],
        ],
        bullets: [
          'The app asks for an MTU of 247 bytes, so a typical telemetry message needs 1–3 packets.',
          'Keep the telemetry rate at 30 Hz or less, and send point clouds sparingly. BLE gives roughly 20–60 kB/s in practice.',
          'Range is about 30 m in the open, less through walls and bodies.',
        ],
      ),
      Step.rich(
        'Permissions',
        'The phone asks for Bluetooth access the first time you open Pair device. If you declined, turn it on in the system settings for koebelt dash. Android 11 and older also need location access to scan.',
        note: 'Generic BLE apps (nRF Connect, LightBlue) can talk to the device too. They are useful to check that it advertises.',
      ),
    ],
  ),
  Guide(
    'serial',
    'USB serial',
    'A cable link with the lowest latency, for bench work and arms.',
    5,
    section: 'connections',
    platforms: ['arduino', 'python', 'rust'],
    [
      Step.rich(
        'Use the USB port',
        'Messages are newline-terminated JSON at 115200 baud. Plug the board into the computer or Android phone running the app; it appears under Pair device > Nearby by its USB name.',
        complete: true,
        c: {
          'arduino': [
            'cpp',
            r'''#include <KoebeltLink.h>

KLink klink("Thrust bench", KLink::BENCH);

void setup() {
  Serial.begin(115200);
  klink.beginSerial(Serial);     // the USB port now belongs to koebelt/link
}

void loop() {
  klink.thrust(analogRead(34) * 0.01f);
  klink.update();
}''',
          ],
          'python': [
            'python',
            r'''# A Raspberry Pi talking to the app's computer through a USB-serial adapter.
# pip install "koebelt-link[serial]"
from koebelt_link import Device

dev = Device("Thrust bench", kind="bench")
dev.connect(serial="/dev/ttyUSB0", baud=115200)


def loop():
    dev.publish("thrust", thrust=1.2)


dev.run(hz=60, loop=loop)''',
          ],
          'rust': [
            'rust',
            r'''// A Raspberry Pi talking to the app's computer through a USB-serial adapter.
// The port is configured with stty, so the crate needs no dependencies.
use koebelt_link::{Device, Kind};

fn main() -> std::io::Result<()> {
    let mut dev = Device::new("Thrust bench", Kind::Bench).serial("/dev/ttyUSB0", 115200).start()?;
    loop {
        dev.link.thrust(1.2, 0.0);
        dev.tick_blocking(60.0);
    }
}''',
          ],
        },
        warn: true,
        note: 'Do not print debug text on the same port: it breaks the message stream. Use a second UART (Serial1) for debugging, or klink.log("…") to send it to the app.',
      ),
      Step.rich(
        'Platforms and permissions',
        'Where the app can open serial ports:',
        bullets: [
          'macOS, Windows, Linux: yes. The port is /dev/cu.usbserial-…, COM3 or /dev/ttyUSB0.',
          'Linux: add yourself to the dialout group (sudo usermod -aG dialout \$USER), then log out and in again.',
          'Android: yes, with a USB-OTG cable.',
          'iOS: no. Use Wi-Fi or BLE there.',
        ],
      ),
    ],
  ),
  Guide(
    'radio',
    'Radio links',
    'SiK, HC-12, XBee and LoRa radios: wiring, rates, fallback, and pairing them in the app.',
    12,
    section: 'connections',
    platforms: ['arduino', 'python', 'rust', 'ros2'],
    [
      Step.rich(
        'What a radio link is',
        'Two radio modems: one on the device\'s UART, its twin on a USB port of the computer or phone running the app. The radios are transparent, so both ends speak the same lines as USB serial. What changes is how much fits through the air, so both ends follow the radio\'s profile:',
        table: [
          ['Radio', 'App setting', 'Baud', 'Telemetry', 'Control', 'Range'],
          ['SiK: 3DR, Holybro, RFD900', 'SiK telemetry radio', '57600', '5 Hz, full set', '10 Hz', '1 km; 40 km for RFD900'],
          ['XBee / DigiMesh', 'XBee', '57600', '5 Hz, full set', '10 Hz', '100 m to 10 km by model'],
          ['HC-12 433 MHz', 'HC-12', '9600', '2 Hz, compact', '5 Hz', '~1 km'],
          ['LoRa module or ground station', 'LoRa ground station', '115200', '2 Hz, compact', 'None: STOP only', '2–10 km'],
          ['Anything else transparent', 'Other serial radio', 'yours', '2 Hz, compact', '5 Hz', '–'],
        ],
        bullets: [
          'Full set: every channel you publish, including custom channels. Compact: position, attitude, GPS, battery and rocket state only.',
          'No point clouds or radar tracks over any radio, and state every 2 s instead of twice a second.',
          'Video never goes over a radio; it needs Wi-Fi.',
        ],
      ),
      Step.rich(
        'On the device',
        'Wire the radio to a spare UART (not the USB port you debug on), start that UART at the radio\'s baud rate, and give it to the library with its type.',
        complete: true,
        c: {
          'arduino': [
            'cpp',
            r'''#include <KoebeltLink.h>

KLink klink("Mule", KLink::ROVER);
float speed = 0, turn = 0;

void setup() {
  // ESP32: radio TX -> GPIO16, radio RX -> GPIO17, GND, 5 V.
  Serial2.begin(kRadioProfile(KRadio::SIK).baud, SERIAL_8N1, 16, 17);
  klink.beginRadio(Serial2, KRadio::SIK);     // or KRadio::HC12, KRadio::XBEE, KRadio::LORA
  klink.onControl([](const KControl& c) { speed = c.ry; turn = c.lx; });
  klink.onStop([] { speed = turn = 0; });
  klink.failsafe(1500, KMode::HOLD);          // radios drop packets: give the failsafe some slack
}

void loop() {
  klink.position(0, 0, 0);
  klink.battery(12.1, 64);
  klink.update();
}''',
          ],
          'python': [
            'python',
            r'''# pip install "koebelt-link[serial]"
from koebelt_link import Device

dev = Device("Mule", kind="rover")
dev.connect(radio=("/dev/ttyAMA0", "sik"))   # sik, lora, hc12, xbee or other
dev.failsafe(timeout=1.5, action="hold")


@dev.on_control
def drive(c):
    print("drive", c.ry, "turn", c.lx)


def loop():
    dev.position(0, 0, 0)
    dev.battery(12.1, 64)


dev.run(hz=50, loop=loop)''',
          ],
          'rust': [
            'rust',
            r'''use std::time::Duration;

use koebelt_link::{Device, Kind, Mode, Radio};

fn main() -> std::io::Result<()> {
    // Opens the port at the radio's baud rate (configured with stty).
    let mut dev = Device::new("Mule", Kind::Rover).radio("/dev/ttyAMA0", Radio::Sik).start()?;
    dev.failsafe(Duration::from_millis(1500), Mode::Hold);
    dev.on_control(|c| println!("drive {} turn {}", c.ry, c.lx));
    loop {
        dev.position([0.0, 0.0, 0.0])?;
        dev.battery(12.1, 64.0)?;
        dev.tick_blocking(50.0);
    }
}''',
          ],
          'ros2': ['yaml', 'name: Mule\nkind: rover\ntransport: radio:/dev/ttyUSB1:sik    # sik, lora, hc12, xbee or other\nsafety:\n  failsafe_timeout: 1.5'],
        },
        note: 'On a Raspberry Pi the GPIO UART is /dev/ttyAMA0 (enable it with raspi-config, and turn off the serial console). A radio on a USB adapter is /dev/ttyUSB0.',
      ),
      Step.rich(
        'As a fallback behind Wi-Fi',
        'Keep Wi-Fi for video and full-rate telemetry, and let the radio carry on when Wi-Fi drops out. The first link is primary; when the failsafe trips, telemetry moves to the radio, and control resumes on whichever link the app uses.',
        c: {
          'arduino': [
            'cpp',
            'klink.begin("your-ssid", "your-password");\nSerial2.begin(57600, SERIAL_8N1, 16, 17);\nklink.beginRadio(Serial2, KRadio::SIK);   // second link = fallback',
          ],
          'python': ['python', 'dev.connect(wifi=True, fallback={"radio": ("/dev/ttyAMA0", "sik")})'],
          'rust': ['rust', 'let mut dev = Device::new("Mule", Kind::Rover).wifi("", "").radio("/dev/ttyAMA0", Radio::Sik).start()?;'],
          'ros2': ['yaml', 'transport: wifi\nfallback: radio:/dev/ttyUSB1:sik'],
        },
      ),
      Step.rich(
        'In the app',
        'Plug the twin radio into the computer or Android phone, then Devices > Pair device > Radio:',
        bullets: [
          'Pick the radio type. SiK radios and XBees are recognised by their USB name and preselected.',
          'Pick the USB port and check the baud rate: it is the serial speed between the app and its radio, set in the radio itself.',
          'Listen for device: the app opens the port and waits for the device\'s announcement, so you see its name and kind before adding it. A device in pairing mode gets a key over the radio.',
          'The device is listed with a Radio tag. Connect as usual; latency and failsafe work the same, at the radio\'s rates.',
        ],
        note: 'iOS cannot open USB serial adapters. Use radio links from Android, macOS, Windows or Linux.',
      ),
      Step.rich(
        'Setting up the radios',
        'Both radios of a pair must agree on everything except their position:',
        table: [
          ['Radio', 'Must match on both', 'How'],
          ['SiK', 'NETID, AIR_SPEED, frequency range, ECC', 'Mission Planner > SiK radio, or AT commands (+++, ATI5). Set MAVLINK=0 for plain data.'],
          ['HC-12', 'Channel (AT+C001) and mode (AT+FU3)', 'Hold SET low, send AT commands at 9600 baud.'],
          ['XBee', 'PAN ID (ID), channel, API mode off (AP=0)', 'XCTU.'],
          ['LoRa', 'Frequency, spreading factor, bandwidth', 'In both sketches (LoRa.begin(868E6) and friends).'],
        ],
        warn: true,
        note: 'Radio power and duty-cycle limits depend on the country: 868 MHz in Europe allows 1 % duty cycle on most channels. Check before you fly.',
      ),
      Step.rich(
        'LoRa: telemetry only',
        'LoRa reaches furthest but is far too slow for sticks. The device ignores everything on a LoRa link except STOP, ping, rate and bye, so nothing can arm or move it from there; STOP still gets through, within about a second. The app greys out the controls and says so. A LoRa radio on SPI is added with fallback(); a LoRa module with a UART (Ebyte E22, E32) is a radio like the others.',
        c: {
          'arduino': [
            'cpp',
            '// LoRa on SPI (sandeepmistry/LoRa library; include it in the sketch):\n#include <LoRa.h>\n\nklink.fallback(KLink::LORA, 868E6);        // 868 MHz Europe, 915 MHz Americas\n\n// A LoRa module with a UART (E22, E32) in transparent mode:\nSerial2.begin(115200, SERIAL_8N1, 16, 17);\nklink.beginRadio(Serial2, KRadio::LORA);',
          ],
          'python': ['python', 'dev.connect(wifi=True, fallback={"radio": ("/dev/ttyUSB1", "lora")})'],
          'rust': ['rust', 'let mut dev = Device::new("Nova", Kind::Rocket).wifi("", "").radio("/dev/ttyUSB1", Radio::Lora).start()?;'],
          'ros2': ['yaml', 'fallback: radio:/dev/ttyUSB1:lora'],
        },
      ),
      Step.rich(
        'The LoRa ground station',
        'SPI LoRa radios are not USB devices, so the app side needs a small board that passes packets to USB serial. In the app, add it as "LoRa ground station".',
        c: {
          'arduino': [
            'cpp',
            r'''// Ground station: LoRa <-> USB serial, one message per line.
#include <LoRa.h>

void setup() {
  Serial.begin(115200);
  LoRa.begin(868E6);
}

void loop() {
  int n = LoRa.parsePacket();
  if (n > 0) {
    while (LoRa.available()) Serial.write(LoRa.read());
    Serial.write('\n');
  }
  static String line;
  while (Serial.available()) {
    char c = Serial.read();
    if (c == '\n') {
      LoRa.beginPacket();
      LoRa.print(line);
      LoRa.endPacket();
      line = "";
    } else {
      line += c;
    }
  }
}''',
          ],
        },
      ),
    ],
  ),
  Guide(
    'chips',
    'Other Wi-Fi and Bluetooth chips',
    'Bluetooth modules on a UART, Ethernet, ESP-AT co-processors and other networking libraries.',
    8,
    section: 'connections',
    platforms: ['arduino', 'python', 'rust'],
    [
      Step.rich(
        'Bluetooth modules on a UART',
        'An HM-10, HC-05 or similar module turns any board with a spare serial port into a Bluetooth device, even an Arduino without radio. The module passes bytes through; the library sends telemetry at a rate its baud rate can carry.',
        complete: true,
        c: {
          'arduino': [
            'cpp',
            r'''#include <KoebeltLink.h>

KLink klink("Module-Bot", KLink::ROVER);
float speed = 0, turn = 0;

void setup() {
  // Module TX -> RX1, module RX -> TX1 (through a divider on 5 V boards).
  Serial1.begin(9600);               // the module's factory baud rate
  klink.beginModule(Serial1, 9600);   // 2 Hz telemetry; set the module to 115200 for 10 Hz
  klink.onControl([](const KControl& c) { speed = c.ry; turn = c.lx; });
  klink.onStop([] { speed = turn = 0; });
  klink.failsafe(1500, KMode::HOLD);
}

void loop() {
  klink.battery(7.4, 80);
  klink.update();
}''',
          ],
          'python': [
            'python',
            r'''# A Raspberry Pi with an HM-10 on its GPIO UART (enable it in raspi-config).
from koebelt_link import Device

dev = Device("Module-Bot", kind="rover")
dev.connect(module=("/dev/serial0", 9600))


@dev.on_control
def drive(c):
    print("drive", c.ry, "turn", c.lx)


def loop():
    dev.battery(7.4, 80)


dev.run(hz=50, loop=loop)''',
          ],
          'rust': [
            'rust',
            r'''use koebelt_link::{Device, Kind};

fn main() -> std::io::Result<()> {
    // An HM-10 on the Raspberry Pi's GPIO UART.
    let mut dev = Device::new("Module-Bot", Kind::Rover).module("/dev/serial0", 9600).start()?;
    dev.on_control(|c| println!("drive {} turn {}", c.ry, c.lx));
    loop {
        dev.battery(7.4, 80.0)?;
        dev.tick_blocking(50.0);
    }
}''',
          ],
        },
        table: [
          ['Module', 'Kind', 'In the app'],
          ['HM-10, HM-19, AT-09, BT05, JDY-08/23, HC-08, CC41', 'Bluetooth LE', 'Pair device > Nearby, under Bluetooth'],
          ['Microchip RN4870 / RN4871 / BM70', 'Bluetooth LE', 'Pair device > Nearby'],
          ['DFRobot Bluno boards', 'Bluetooth LE', 'Pair device > Nearby'],
          ['Adafruit Bluefruit LE UART Friend', 'Bluetooth LE (Nordic UART)', 'Pair device > Nearby'],
          ['HC-05, HC-06', 'Bluetooth Classic', 'Pair it in the computer\'s Bluetooth settings; it then appears under Bluetooth (desktop apps only)'],
        ],
        note: 'The app asks the board behind the module for its name and pairing code before adding it, so pairing works as with any other device. Modules are slow: the app sends sticks 5 times a second over them.',
      ),
      Step.rich(
        'Bluetooth stacks on the board',
        'beginBLE() uses whatever Bluetooth the board has:',
        table: [
          ['Board', 'Stack', 'Include in the sketch'],
          ['ESP32, ESP32-S3, ESP32-C3', 'Bluedroid (in the core)', 'nothing'],
          ['ESP32 with NimBLE-Arduino installed', 'NimBLE: about 100 KB less RAM', '#include <NimBLEDevice.h>'],
          ['Adafruit nRF52 (Feather nRF52840, ItsyBitsy, CLUE)', 'Bluefruit (in the core)', 'nothing'],
          ['Nano 33 BLE, Nano 33 IoT, UNO R4 WiFi, Nano RP2040 Connect', 'ArduinoBLE', '#include <ArduinoBLE.h>'],
        ],
      ),
      Step.rich(
        'Any networking library',
        'For network chips the library does not know, set the network up with its own library and hand over its UDP object. The library calls begin(47800) on it and does the rest:',
        c: {
          'arduino': [
            'cpp',
            r'''// W5500 / W5100 Ethernet (also EthernetENC for ENC28J60, QNEthernet on Teensy 4.1)
#include <Ethernet.h>
EthernetUDP udp;
Ethernet.begin(mac);
klink.beginUdp(udp);

// An ESP-01 running ESP-AT as Wi-Fi for a board without it (WiFiEspAT)
#include <WiFiEspAT.h>
WiFiUDP udp;
WiFi.init(Serial1);
WiFi.begin("ssid", "password");
klink.beginUdp(udp);''',
          ],
        },
        bullets: [
          'Built in, nothing to set up: ESP32, ESP8266, Raspberry Pi Pico W, UNO R4 WiFi (WiFiS3), Portenta, GIGA.',
          'Separate libraries, used once the sketch includes them: WiFiNINA (Nano 33 IoT, MKR WiFi 1010, Nano RP2040 Connect, Adafruit AirLift), WiFi101 (MKR1000, WINC1500).',
          'Anything else with an Arduino-style UDP class: pass it to beginUdp().',
        ],
        note: 'The Arduino IDE links a library only when the sketch includes it, so include your board\'s Wi-Fi or Bluetooth library at the top of the sketch.',
      ),
    ],
  ),
  Guide(
    'pairing',
    'Pairing and security',
    'Pairing codes, keys, open mode and what the key protects.',
    5,
    section: 'connections',
    platforms: ['arduino', 'python', 'rust', 'ros2'],
    [
      Step.rich(
        'How pairing works',
        'Pairing ties a device to this app with a random 128-bit key:',
        bullets: [
          'The app shows a 6-character code, valid 10 minutes (Guides > Quickstart > Pair with this app).',
          'You put the code in the firmware once. The device adds it to its announce.',
          'The app sees the matching code and sends a fresh key. The device stores it and answers paired.',
          'From then on the device only accepts sessions that present that key. Remove the pair call afterwards.',
        ],
        c: {
          'arduino': ['cpp', 'klink.pair("4F7-K2Q");   // once; the key is stored in flash (ESP32)'],
          'python': ['python', 'dev.pair("4F7-K2Q")    # key stored in ~/.config/koebelt-link/<id>.json'],
          'rust': ['rust', 'dev.pair("4F7-K2Q")?;   // key stored in ~/.config/koebelt-link/<id>.key'],
          'ros2': ['bash', 'ros2 launch koebelt_link_ros bridge.launch.py config:=config/device.yaml pair:=4F7-K2Q'],
        },
      ),
      Step.rich(
        'Open mode and unpairing',
        'A device that was never paired accepts any app on the network ("open mode"). That is convenient on a bench, but avoid it in public places. To start over, call unpair() (Arduino, Python), delete the key file (Rust), or remove the device in the app and pair again with a new code.',
        c: {
          'arduino': ['cpp', 'if (digitalRead(PAIR_BUTTON) == LOW) klink.unpair();'],
          'python': ['python', 'dev.unpair()'],
        },
      ),
      Step.rich(
        'What the key protects',
        'The key decides who may open a session; it does not encrypt the traffic.',
        bullets: [
          'Use WPA2 or WPA3 on Wi-Fi and BLE bonding if telemetry must stay private.',
          'Anyone on the same network can still see announce broadcasts (name and kind).',
          'The app only sends control to the device it is connected to, and the device only listens to that session.',
        ],
        warn: true,
        note: 'Pairing is not a safety feature. Keep a physical kill switch on anything that can hurt someone.',
      ),
    ],
  ),
];
