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

KLink klink("Mule", KLink::ROVER);

void setup() {
  klink.begin("your-ssid", "your-password");
  // An IP camera on the same network (any MJPEG URL works).
  klink.video("http://192.168.1.50:8080/video", "cam", "mjpeg", "Front");
}

void loop() {
  klink.battery(12.1, 70);
  klink.update();
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
  klink.video(":81/stream", "cam", "mjpeg", "Front");
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
          'Recordings keep the camera too (Settings > Recording): replays show it under VIDEO and in camera tiles, and export writes it as an MJPEG AVI.',
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
          'arduino': ['cpp', 'klink.gps(lat, lon, altitudeM, satellites);\nklink.position(xEast, yNorth, up);      // metres from home'],
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
          ['DARK', 'Mapbox Dark: streets and places in the app\'s colours. The default.'],
          ['OUTDOORS', 'Mapbox Outdoors: contours, trails and terrain, good for fields and hills.'],
          ['SATELLITE', 'Mapbox satellite imagery with roads and names: see the field as you fly over it.'],
          ['CUSTOM', 'Your own URL template with {z}, {x} and {y} and the provider\'s attribution, for any provider you have the right to use.'],
          ['NONE', 'A metre grid only.'],
        ],
        bullets: [
          'The Mapbox maps use the app\'s Mapbox account. To use your own (your quota, your styles\' terms), paste your public token in Settings > Map.',
          'Tiles you have looked at stay on this device for as long as Mapbox allows, so a field you looked at recently shows without signal. There is no "download this area": Mapbox\'s terms keep offline maps to its own SDKs. For a fully offline map, use a provider that allows it under CUSTOM.',
          'The map always shows the Mapbox logo and its credits, as Mapbox requires. Do not remove them in a fork; a fork needs its own Mapbox token.',
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
      'A chip appears in the top bar, orange for warnings and red for critical alerts, with the most urgent one and how many more; it never covers or moves the screen. Tap it for each alert with its value and limit. OK hides an alert until the value clears and crosses the limit again. Computers play the system alert sound; phones vibrate when haptics are on. A lost link shows there too, and sounds the same way. Alerts are not checked during replays; the ones that fired while recording show as marks on the replay timeline.',
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
        bullets: [
          'Only the channels the device sends are kept, rounded to what sensors resolve, and files are compressed: about 1 MB for 10 minutes of a drone at 30 Hz.',
          'The camera is recorded with the session when Settings > Recording > Record video is on, at most at the frame rate set there. The camera stays connected while recording, even when no screen shows it. Replays show it under VIDEO, and in the camera tiles and views.',
          'Alerts, link losses and STOP are kept with the recording: marks over the replay timeline (hover for what happened, tap to jump there), and an event column in the CSV export.',
          'Export: CSV, JSON and GPX for the telemetry, and Video as an MJPEG AVI (VLC, ffmpeg and most editors). The JSON export leaves the video out.',
        ],
      ),
      Step.rich(
        'Import',
        'Import on the Replay screen opens a file and plays it like any session: the 3D views, the map, the charts and export all work on it. The same menu loads, or removes, three sample recordings.',
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
  Guide(
    'fleet',
    'Several devices at once',
    'Connect a drone, a rover and an arm together: who gets the sticks, what STOP does, and what each one keeps doing.',
    3,
    section: 'features',
    [
      Step.rich(
        'Connect more than one',
        'Connect a device and then another, from the device name at the top left, the sidebar or the Devices screen: the first stays connected. Up to 8 at once. The screens show one device at a time, the one whose name is at the top left; tap another in that list, or press 1 to 9 on a keyboard, to show it.',
        table: [
          ['', 'Device shown', 'The other connected devices'],
          ['Sticks, sliders, tilt, controller', 'Drive it', 'Get centred sticks: they hold'],
          ['Failsafe', 'As usual', 'Does not trip: the heartbeat keeps going'],
          ['Alerts, lost link', 'In the top bar alert chip, and sound', 'In the same chip with its name and a Show button, and sound'],
          ['Sequences', 'Run', 'Keep running'],
          ['Record', 'Recorded', 'Recorded too, as its own recording'],
        ],
        note: 'Switching away from a device you are driving centres its sticks first, so it holds instead of keeping your last input.',
      ),
      Step.rich(
        'STOP stops them all',
        'With several devices connected the button reads STOP ALL: one press stops every connected device, as STOP does for one. Reset clears the stop on all of them; each stays disarmed until you arm it again.',
        warn: true,
      ),
      Step.rich(
        'Seeing them together',
        'The map shows every connected device with a GPS fix, each with its own colour, name and track; tap one to show it. The 3D views mark them too, placed by GPS. The Fleet widget (Edit layout > Add widget) lists them all with mode, battery, link and alerts. A controller button can cycle through them: Settings > Game controller > Next device.',
      ),
    ],
  ),
  Guide(
    'sequence-or-script',
    'Sequence or script?',
    'Two ways to automate a device: steps you put in order, or Python that decides. What each does best, and how they work together.',
    3,
    section: 'features',
    platforms: ['python'],
    [
      Step.rich(
        'Two ways to automate',
        'Both live in Automate. A sequence is a list of steps you put in order: take off, fly to, wait, land; drive to; move to a pose. No code, and the same steps each time. A script is a Python file: it reads the telemetry and the camera, decides what to do, and drives the device.',
        table: [
          ['', 'Sequence', 'Script'],
          ['You write', 'Steps, in the app', 'Python, in the app or any editor'],
          ['Decides', 'No: the same steps each time', 'Yes: conditions, loops, sensors, the camera'],
          ['Runs on', 'The device, when it can store sequences; otherwise dash runs the steps', 'A computer: this one, or a script host for phones and tablets'],
          ['If the link drops', 'A sequence stored on the device carries on', 'It can no longer drive: the device\'s failsafe takes over'],
          ['Packages', 'None needed', 'Any: NumPy, OpenCV, PyTorch, YOLO'],
          ['Started by', 'Run, on its page', 'Run, or a trigger: a button, a key, a controller, a condition, a timer'],
        ],
      ),
      Step.rich(
        'Which one',
        'Start with a sequence when the job is a fixed route or routine; reach for a script when the device has to react.',
        bullets: [
          'A sequence: a survey pattern, a test routine on a bench, a pick-and-place between poses you recorded, anything that must carry on if the link drops.',
          'A script: follow a line, land on a target the camera finds, hold a distance with a rangefinder, stop when a value crosses a limit, anything with a model.',
        ],
      ),
      Step(
        'Together',
        'A script can run a sequence by name and wait for it: the sequence does the flying, the script decides when. Here the camera looks for a landing pad, then the sequence "Land on pad" takes over.',
        {
          'python': [
            'python',
            r'''from koebelt_dash_scripts import connect, every

dev = connect()
for _ in every(0.2):
    if pad_in_view(dev.camera.frame()):   # your code: True when the pad is seen
        dev.run_sequence("Land on pad")    # returns once the sequence is done
        break''',
          ],
        },
      ),
    ],
  ),
  Guide(
    'scripts',
    'Scripts',
    'Drive a device from Python: behaviours, computer vision, machine learning, with the operator always in charge.',
    10,
    section: 'features',
    platforms: ['python'],
    [
      Step.rich(
        'What a script is',
        'A Python file that reads a device\'s telemetry and drives it through koebelt dash: sticks, steps, sequences, modes, commands. It runs in your own Python, so any package works: OpenCV, PyTorch, YOLO, NumPy.',
        bullets: [
          'On a computer, dash runs it with the Python you choose (Scripts > a script > Python). The first time, Set up Python creates a Python environment in the scripts folder with the koebelt-dash-scripts package.',
          'On a phone or tablet, it runs on a script host: a computer on the same network running koebelt-dash-scripts host. The phone keeps the device link, the sticks and STOP.',
          'Scripts live in Documents/koebelt/dash-scripts on computers, in the app\'s documents on phones. Edit them in dash, or in any editor.',
        ],
      ),
      Step(
        'A first script',
        'connect() gives the device selected in dash. every() runs the loop at a steady rate; dash shows the real one. A setting becomes a slider on the script\'s page.',
        {
          'python': [
            'python',
            r'''"""Drive north and hold the x = 0 line."""
from koebelt_dash_scripts import connect, every, pid

dev = connect()
speed = dev.setting("speed", 0.4, min=0, max=1)
keep = pid(1.5, 0.0, 0.2)

dev.mode("MANUAL")
for _ in every(0.05):                       # 20 Hz
    error = 0.0 - dev.tlm.pos[0]            # metres east of the line
    dev.sticks(throttle=speed.value, steer=keep.update(error))''',
          ],
        },
      ),
      Step(
        'Steps, sequences and the camera',
        'Steps (take off, go to, land…) and sequences wait until they are done. The camera gives NumPy images, newest first, so a slow model never falls behind; overlay() draws what it sees over the camera in dash.',
        {
          'python': [
            'python',
            r'''dev.takeoff(6)              # drones: needs arming allowed in Limits
dev.goto(10, 0, 6)          # metres east, north, up from home
dev.land()
dev.run_sequence("Survey square")

for frame in dev.camera.frames():           # pip install opencv-python
    boxes = find_targets(frame)             # your code: (x, y, w, h, label)
    dev.overlay(boxes, width=frame.shape[1], height=frame.shape[0])''',
          ],
        },
      ),
      Step.rich(
        'Triggers',
        'A script declares what it reacts to; you choose what fires it on the script\'s page: an on-screen button or switch (also on Control if pinned), a key, a controller button, a condition such as battery.pct < 25 for 3s, a device event, or a timer.',
        c: {
          'python': [
            'python',
            r'''@dev.trigger("Drop payload", key="D", gamepad="LT")
def drop():
    dev.cmd("release")

@dev.trigger("Patrol", kind="switch")
def patrol(on):
    ...

@dev.on_trigger                     # the ones you add in dash
def other(name, value):
    print(name, value)''',
          ],
        },
        note: 'A controller button already used by dash (STOP, arm, modes…) keeps its action: pick a free one for scripts.',
      ),
      Step.rich(
        'You stay in charge',
        'Whatever a script does:',
        bullets: [
          'STOP stops every device and ends the script.',
          'Moving the sticks takes over; the script waits until you press Resume.',
          'Limits, set in dash: maximum speed, geofence, ceiling. Arming, take-off and parameter writes are refused unless you allow them.',
          'If the script crashes, stops answering for half a second, or leaves the geofence, the device holds, and the script cannot drive again until you resume it.',
        ],
        warn: true,
        note: 'Test a script on a simulated device first (Devices > Pair > Simulated): same telemetry, same commands, nothing to break.',
      ),
      Step(
        'From a terminal, Jupyter or ROS',
        'A script started anywhere on the same computer finds dash by itself. On a computer without dash, set KOEBELT_DASH_URL and KOEBELT_DASH_TOKEN, as a script host does.',
        {
          'python': [
            'bash',
            '''pip install koebelt-dash-scripts
python my_script.py                  # dash open on this computer

# a script host for phones and tablets
koebelt-dash-scripts host''',
          ],
        },
      ),
    ],
  ),
  Guide(
    'assistants',
    'AI assistants',
    'Let Claude, Codex, OpenCode, Cursor or another MCP client read the docs, write scripts, use the app and, with your approval, act on devices.',
    5,
    section: 'features',
    platforms: ['python'],
    [
      Step.rich(
        'What an assistant can do',
        'koebelt dash speaks MCP, the protocol AI assistants use for tools. Turn it on in Settings > AI assistants, then connect the assistant you use.',
        bullets: [
          'Learn: search and read these guides, the protocols, the script API and its examples.',
          'Look: devices, telemetry, the camera, parameters, alerts, recordings, and the window itself.',
          'Write: scripts, sequences and triggers; check scripts with your Python.',
          'Use the app: add simulated devices, connect, record, export, open screens, change settings (not the safety ones).',
          'Act: run scripts and sequences, send commands, write parameters. On real hardware each waits for your approval; arming and take-off always ask. STOP never asks.',
        ],
        note: 'koebelt dash sends nothing to any AI service. The assistant you connect talks to its own provider, and what it reads in dash goes there.',
      ),
      Step(
        'Connect an assistant',
        'Settings > AI assistants shows the line for your client, with a copy button. Claude Code, for example:',
        {
          'python': ['bash', 'claude mcp add --transport http koebelt-dash http://127.0.0.1:47920/mcp'],
        },
      ),
      Step.rich(
        'Then ask',
        'For example:',
        bullets: [
          '“Write a script that makes the rover follow the yellow ball, test it on a simulated rover, then show me.”',
          '“Why did Kite drift at 01:20 in the last recording?”',
          '“Set up a Raspberry Pi rover with a motor driver and a GPS.”',
        ],
      ),
    ],
  ),
];
