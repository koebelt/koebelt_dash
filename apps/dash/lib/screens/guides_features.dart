// Guides: live video, the map, game controllers, alerts, recordings.
import 'guides_data.dart';

const featureGuides = [
  Guide(
    'video',
    'Live video',
    'Show a camera in the app: ESP32-CAM, a Raspberry Pi camera, a USB webcam or a ROS image topic.',
    10,
    section: 'features',
    platforms: ['arduino', 'python', 'rust', 'ros2'],
    [
      Step.rich(
        'How video gets to the app',
        'Video does not go through the koebelt/link messages: it is far too heavy. The device serves MJPEG over HTTP, the format of ESP32-CAM, mjpg-streamer and most webcam servers, and only tells the app where to find it, in its hello. The app opens the stream itself and shows it:',
        bullets: [
          'as the CAM view behind the HUD on the Live screen,',
          'as the background of the drive screen (Control > CAM), for first-person driving and flying,',
          'as a Camera tile on the wall layout, with a full-screen detail view.',
        ],
        table: [
          ['Declared as', 'Means'],
          [':81/stream', 'Port and path on the device\'s own IP. Use this on Wi-Fi: the device does not need to know its address.'],
          ['http://10.0.0.5:8080/video', 'A full URL, for a separate IP camera or a server on another machine.'],
        ],
        note: 'Video needs an IP link: Wi-Fi, Ethernet or a phone hotspot. It is not available over BLE, USB serial or radio links, even if telemetry is.',
      ),
      Step.rich(
        'Declare a camera',
        'One line. Declare it before the app connects; it is part of the hello.',
        complete: true,
        c: {
          'arduino': [
            'cpp',
            r'''#include <KoebeltLink.h>

KLink link("Mule", KLink::ROVER);

void setup() {
  link.begin("your-ssid", "your-password");
  // An IP camera on the same network (any MJPEG URL works).
  link.video("http://192.168.1.50:8080/video", "cam", "mjpeg", "Front");
}

void loop() {
  link.battery(12.1, 70);
  link.update();
}''',
          ],
          'python': [
            'python',
            r'''# A USB webcam or Raspberry Pi camera through OpenCV:
# pip install "koebelt-link[camera]"
from koebelt_link import Device

dev = Device("Mule", kind="rover")
dev.connect(wifi=True)
dev.camera(0, port=8081, fps=15, width=640, label="Front")   # serves :8081/stream


def loop():
    dev.battery(12.1, 70)


dev.run(hz=50, loop=loop)''',
          ],
          'rust': [
            'rust',
            r'''// Raspberry Pi camera, no extra crates: let the camera tool write MJPEG to
// stdin and serve each frame.
//   rpicam-vid -t 0 --codec mjpeg --width 640 --height 480 -o - | ./mule
use std::io::Read;

use koebelt_link::{Device, Kind, MjpegServer};

fn main() -> std::io::Result<()> {
    let mut dev = Device::new("Mule", Kind::Rover).wifi("", "").start()?;
    let cam = MjpegServer::bind(8081)?;
    dev.video(&cam.url(), "cam", "Front");

    // Split the stream into JPEGs (start FF D8 … end FF D9) on a thread.
    std::thread::spawn(move || {
        let (mut buf, mut chunk) = (Vec::new(), [0u8; 65536]);
        let mut stdin = std::io::stdin();
        while let Ok(n) = stdin.read(&mut chunk) {
            if n == 0 {
                break;
            }
            buf.extend_from_slice(&chunk[..n]);
            while let Some(end) = buf.windows(2).position(|w| w == [0xFF, 0xD9]) {
                let frame: Vec<u8> = buf.drain(..end + 2).collect();
                if let Some(start) = frame.windows(2).position(|w| w == [0xFF, 0xD8]) {
                    cam.push(&frame[start..]);
                }
            }
        }
    });

    loop {
        dev.battery(12.1, 70.0)?;
        dev.tick_blocking(50.0);
    }
}''',
          ],
          'ros2': [
            'yaml',
            'name: Mule\nkind: rover\ntransport: wifi\n# sensor_msgs/CompressedImage with JPEG data (image_transport "compressed")\nvideo:\n  topic: /camera/image_raw/compressed\n  port: 8081\n  label: Front',
          ],
        },
      ),
      Step.rich(
        'ESP32-CAM',
        'The AI-Thinker ESP32-CAM serves its own MJPEG stream. The library\'s CameraRover example starts the camera, serves /stream on port 81 and declares it; the core of it:',
        c: {
          'arduino': [
            'cpp',
            r'''// Board: AI Thinker ESP32-CAM, PSRAM enabled. Full sketch:
// libs/arduino/KoebeltLink/examples/CameraRover
if (startCamera()) {                        // esp_camera_init + httpd on port 81
  link.video(":81/stream", "cam", "mjpeg", "Front");
}''',
          ],
          'python': [
            'bash',
            '# On a Raspberry Pi, the Python camera() helper replaces this.\n# Or serve with ustreamer and declare it:\nustreamer --device /dev/video0 --port 8081 &',
          ],
          'rust': ['bash', '# Or serve with ustreamer and declare ":8081/stream":\nustreamer --device /dev/video0 --port 8081 &'],
        },
        bullets: [
          'Frame size: VGA (640×480) at quality 12 is a good start, 15–25 fps on a clear Wi-Fi link. Drop to QVGA when the picture stutters.',
          'Use CAMERA_GRAB_LATEST and two frame buffers: the app always gets the newest frame, so latency stays low instead of queueing.',
          'The ESP32-CAM serves one viewer at a time. The app shares one connection between all its views.',
        ],
      ),
      Step.rich(
        'Latency and bandwidth',
        'The status line under the picture shows resolution, frame rate and data rate. If the picture lags:',
        bullets: [
          'Lower the resolution or the JPEG quality before the frame rate: 320×240 at 15 fps is plenty to drive by.',
          'Put the device on the phone\'s hotspot instead of a busy router.',
          'Serve the newest frame, never a queue. The libraries\' MJPEG servers and the ESP32 example already do.',
          'Video is not recorded with sessions: replays show telemetry only.',
        ],
      ),
    ],
  ),
  Guide(
    'map',
    'Map and GPS',
    'Put the device on a real map: what to send, how home is placed, and offline tiles.',
    6,
    section: 'features',
    platforms: ['arduino', 'python', 'rust', 'ros2'],
    [
      Step.rich(
        'Send a GPS fix',
        'The map appears as soon as the device sends gps: a MAP view on the Live and drive screens, and the GPS tile becomes a small map. Send the local position too, if you have it: the app places home from the two, and draws the running sequence\'s waypoints in the right place.',
        c: {
          'arduino': ['cpp', 'link.gps(lat, lon, altitudeM, satellites);\nlink.position(xEast, yNorth, up);      // metres from home'],
          'python': ['python', 'dev.gps(lat, lon, alt, sats)\ndev.position(x_east, y_north, up)'],
          'rust': ['rust', 'dev.link.gps(lat, lon, alt, sats);\ndev.position([x_east, y_north, up])?;'],
          'ros2': ['yaml', 'sensors:\n  gps:  /fix     # sensor_msgs/NavSatFix\n  odom: /odom    # nav_msgs/Odometry, x east and y north'],
        },
        table: [
          ['You send', 'Home on the map', 'Track'],
          ['gps and pos', 'GPS minus the local position', 'GPS fixes'],
          ['gps only', 'The first fix of the session', 'GPS fixes'],
          ['pos only', 'No map: use the 3D views', '–'],
        ],
        note: 'pos must be in metres, x east, y north, from home: the same frame the goto command and Set home use.',
      ),
      Step.rich(
        'On the map',
        'The device is the lime arrow, pointing along its heading. Home is the ringed point, the track is the line behind it, and numbered blue points are the goto steps of the sequence that is running. Drag to look around; the follow button brings the map back to the device. Replays show the whole recorded path.',
      ),
      Step.rich(
        'Tiles and offline use',
        'Settings > Map picks the background:',
        table: [
          ['Setting', 'Tiles'],
          ['OSM', 'OpenStreetMap, restyled dark. The default; a community-run server for light personal use.'],
          ['TOPO', 'OpenTopoMap: contours and terrain, good for fields and hills.'],
          ['CUSTOM', 'Your own URL template with {z}, {x} and {y} and the provider\'s attribution: satellite imagery, or any provider you have a key for.'],
          ['NONE', 'A metre grid only.'],
        ],
        bullets: [
          'Tiles you have looked at stay on this device. Without signal the app shows them even when the server would call them out of date, and checks them again once it is back online. Look at your field once with signal before going out.',
          'There is no "download this area" button on purpose: the OpenStreetMap tile policy forbids bulk downloading. For a fully offline map, use a provider that allows it under CUSTOM.',
          'The app identifies itself to tile servers and always shows the attribution, as the OpenStreetMap tile usage policy requires. Do not remove either in a fork.',
          'Building something with many users? Do not ship it on the free OpenStreetMap servers: use a provider with a key (MapTiler, Stadia Maps, Thunderforest, or your own tile server) under CUSTOM.',
        ],
      ),
    ],
  ),
  Guide(
    'controllers',
    'Game controllers',
    'Drive and fly with a USB or Bluetooth gamepad, or an RC transmitter in joystick mode.',
    5,
    section: 'features',
    platforms: [],
    [
      Step.rich(
        'Connect a controller',
        'Pair a Bluetooth controller in the phone or computer\'s system settings, or plug one in over USB. The app sees it at once: Settings > Game controller lists it, and the drive screen shows a Pad chip.',
        bullets: [
          'Xbox, PlayStation and Switch Pro controllers work on every platform, wired or Bluetooth.',
          'Generic USB gamepads and RC transmitters in USB joystick mode (EdgeTX, OpenTX) work on Android, Windows and Linux. macOS and iOS only expose controllers Apple supports.',
          'On Android, a controller and the phone\'s USB port can be in use at the same time with a USB-C hub.',
        ],
      ),
      Step.rich(
        'Default layout',
        'Mode 2, like most RC transmitters:',
        table: [
          ['Control', 'Drone', 'Ground robot', 'Robot arm'],
          ['Left stick', 'Throttle (up/down), yaw', 'Steer (left/right)', 'J1 base, J2 shoulder · Cartesian: tool forward/back, left/right'],
          ['Right stick', 'Pitch, roll', 'Drive (up/down)', 'J3, J4 (J5, J6 with Wrist) · Cartesian: tool up/down'],
          ['B / Circle', 'STOP, at once', 'STOP, at once', 'STOP, at once'],
          ['Start / Options, hold 1 s', 'Arm / disarm', 'Arm / disarm', 'Arm / disarm'],
          ['A / Cross, X / Square, Y / Triangle', 'Manual, Hold, Return home', 'Manual, Hold', 'Manual, Hold'],
          ['D-pad up, hold 1 s / down', 'Take off / Land', '–', '–'],
          ['D-pad left / right', '–', '–', 'Joint ↔ Cartesian / Wrist'],
          ['Right stick press', '–', '–', 'Gripper open / close'],
          ['Bumpers', 'Speed limit −10 % / +10 %', 'Speed limit −10 % / +10 %', 'Speed limit −10 % / +10 %'],
          ['Back / Share', 'Start or stop recording', 'Start or stop recording', 'Start or stop recording'],
        ],
      ),
      Step.rich(
        'Change the mapping',
        'Settings > Game controller shows every axis and button live. Press Learn next to a row and move the stick or press the button you want; for sticks, push the direction that should be positive (up, right). That covers RC transmitters, whose channels arrive as plain axes: learn each one. Dead zone and expo soften the centre for fine control.',
        note: 'The controller only drives an armed drone, ground robot or arm, and only while you move it: let go and the on-screen sticks work again. Buttons work on every kind of device. STOP on the controller is as good as the STOP button.',
      ),
    ],
  ),
  Guide('alerts', 'Alerts', 'Warnings for a low battery, a weak signal, altitude and distance limits, with sound and vibration.', 3, section: 'features', [
    Step.rich(
      'What is watched',
      'Settings > Alerts lists every limit with a switch and a value. An alert fires once its value has been past the limit for a second, so a single noisy reading does not set it off, and clears when the value is back by a small margin.',
      table: [
        ['Alert', 'Default', 'Needs the device to send'],
        ['Battery low', 'Below 25 %', 'bat with a percentage'],
        ['Battery critical', 'Below 10 %, repeats until acknowledged', 'bat with a percentage'],
        ['Battery voltage', 'Off; set it for your pack', 'bat'],
        ['Weak signal', 'Below −85 dBm', 'rssi'],
        ['High latency', 'Above 400 ms', 'Nothing: the app measures it'],
        ['Altitude ceiling', 'Above 120 m, drones', 'pos'],
        ['Distance from home', 'Above 300 m, drones and ground robots', 'pos'],
        ['Temperature', 'Above 70 °C', 'temp'],
      ],
      note: 'An alert only watches values the device actually sends: a rover without a battery monitor never shows a battery alert.',
    ),
    Step.rich(
      'When one fires',
      'A banner appears under the top bar, orange for warnings and red for critical alerts, with the value and the limit. OK hides it until the value clears and crosses the limit again. Computers play the system alert sound; phones vibrate when haptics are on. A lost link sounds the same way. Alerts are not checked during replays.',
    ),
  ]),
  Guide(
    'recordings',
    'Recordings and flight logs',
    'Record at the full telemetry rate, export, and open ArduPilot and PX4 logs in the replay view.',
    4,
    section: 'features',
    [
      Step.rich(
        'Recording',
        'Record (on the Replay screen, the drive screens or a controller button) keeps every telemetry message at the rate set in Settings > Telemetry rate, up to 60 Hz, each with its own time. A device that goes quiet still gets two frames a second, so mode changes and gaps stay on the timeline.',
        note: 'Video is not recorded with sessions: replays show telemetry only.',
      ),
      Step.rich(
        'Import',
        'Import on the Replay screen opens a file and plays it like any session: the 3D views, the map, the charts and export all work on it.',
        table: [
          ['File', 'From', 'What comes in'],
          ['.json', 'Export from koebelt/dash', 'Everything, as recorded'],
          ['.bin', 'ArduPilot flight controller, from the SD card or Mission Planner', 'Attitude, IMU, GPS and position, battery, flight modes, arming'],
          ['.tlog', 'Mission Planner, QGroundControl, MAVProxy', 'What the ground station received, read like a live MAVLink link'],
          ['.ulg', 'PX4 flight controller, from the SD card or QGroundControl', 'Attitude, IMU, local position, GPS, battery, flight modes, arming'],
        ],
        bullets: [
          'Flight controller logs are thinned to 50 frames a second; that is plenty for replay and keeps the file small.',
          'Positions are metres from home: the AHRS home in ArduPilot logs, the first GPS fix otherwise, and PX4\'s local position frame.',
        ],
      ),
    ],
  ),
];
