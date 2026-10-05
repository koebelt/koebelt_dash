# koebelt/dash

A cross-platform companion app for people who build drones, rovers, robot
arms, rockets and test benches, plus **koebelt/link**, the small library that
connects your hardware to it.

```
┌───────────────┐   Wi-Fi (UDP) · BLE · USB serial · radio  ┌──────────────────┐
│ your device   │ ────────────── koebelt/link ─────────────▶ │  koebelt/dash    │
│ + koebelt/link│ ◀──────── control · stop · params ──────── │ phone/tablet/desk│
└───────────────┘                                            └──────────────────┘
```

## Repository

| Path | What |
|------|------|
| [`protocol/`](protocol/) | The wire protocol (`PROTOCOL.md`) and shared test vectors every implementation checks against. |
| [`apps/dash/`](apps/dash/) | The Flutter app: iOS, Android, macOS, Windows and Linux. |
| [`libs/arduino/KoebeltLink/`](libs/arduino/KoebeltLink/) | C++ library for ESP32, RP2040 W, Teensy and other Arduino boards. |
| [`libs/python/`](libs/python/) | `koebelt-link` for Raspberry Pi, Jetson and any Linux/macOS computer, plus a network simulator. |
| [`libs/rust/`](libs/rust/) | `koebelt-link` crate: `no_std` core with no dependencies, plus a `std` layer. |
| [`libs/ros2/koebelt_link_ros/`](libs/ros2/koebelt_link_ros/) | ROS 2 bridge node that maps existing topics to the app. |

## Features

- **Live**: HUD over a 3D scene (orbit, chase, top), a map or the device's camera, with lidar point cloud,
  trajectory and radar tracks, and a drag-and-resize widget grid saved per device and screen
  size. There is also a wall of sensor tiles, and every sensor opens a detail view with
  pause, min/max/mean and per-channel toggles.
- **Control**: virtual sticks, spring sliders or phone tilt for drones and
  rovers; joint and Cartesian jog, home pose and gripper for arms; arm, countdown,
  abort and manual deploy for rockets; throttle, presets and ramp/step sequences
  with current and temperature cutoffs for thrust benches.
- **Video**: devices declare MJPEG camera streams (ESP32-CAM, Raspberry Pi
  camera, webcams, ROS image topics); the app shows them behind the HUD, as
  the drive screen background for first-person driving and flying, and as a
  tile. One connection per stream, newest frame only, so latency stays low.
- **Map**: OpenStreetMap or OpenTopoMap tiles restyled dark (or your own tile
  URL and attribution), with the device's heading, track, home point and the
  running sequence's waypoints. Viewed tiles stay on the device and are shown
  without signal; caching otherwise follows the tile server's headers, the
  app sends its own User-Agent and always shows the attribution, per the
  OpenStreetMap tile usage policy. No bulk downloading. For an app with many
  users, use a tile provider with a key instead of the free OSM servers.
- **Game controllers**: Xbox, PlayStation, Switch Pro and generic gamepads
  over USB or Bluetooth, and RC transmitters in joystick mode. Mode 2 by
  default, every axis and button can be learned, with dead zone and expo.
- **Third-party Bluetooth modules**: HM-10 and its clones, DFRobot Bluno and
  Microchip RN4870 are found over Bluetooth LE like koebelt/link devices; HC-05 /
  HC-06 Classic modules paired with the computer show up under Bluetooth. The
  app paces itself to the module's slow UART and asks the board behind it for
  its name and pairing code.
- **Radio links**: SiK, XBee, HC-12 and LoRa radios through a USB modem,
  with shared rate profiles so both ends agree on what fits through the air.
  LoRa is telemetry only (STOP still gets through).
- **Safety**: a STOP button on every screen (sent three times, and the device
  disarms). The failsafe runs on the device, which switches to hold, RTH or land on
  its own after 1.8 s without control packets, even if the app crashes. A failsafe test
  in Settings withholds the heartbeat for 6 s.
- **Program**: build step sequences per device. Drones get take-off, waypoints,
  land and return home; rovers get waypoints; arms get poses captured from the
  current position and the gripper; benches get throttle holds and ramps. All
  kinds get waits, modes, arming and custom commands. A live plan or throttle
  profile shows the sequence. Runs stop on STOP, stick input or disconnect,
  and pause on link loss.
- **Tune**: parameter tables declared by the firmware, with search, a live
  response chart per group, unsaved-change tracking, revert and write-to-device.
- **Replay**: record sessions at 10 Hz, then scrub and play them back at 1, 2 or 4×.
- **Boards that connect as they are**: ArduPilot and PX4 vehicles over
  MAVLink (USB, telemetry radios, Wi-Fi on UDP 14550): telemetry, map,
  parameters, arming, modes, sticks, take-off, go to, return, land and STOP.
  Betaflight and INAV flight controllers over MSP (telemetry, PID tuning,
  STOP), and the DJI Tello over its SDK. Flight controllers and boards on USB
  are recognised by their USB id and asked what they run, so they show up by
  name and connect with one tap.
- **Devices and pairing**: discovery over the LAN (UDP broadcast), BLE and USB
  serial; radio links set up by type, with the app listening for the device on
  the far side; 10-minute pairing codes with per-device keys, and adding a
  device by IP address.
- **Guides**: an in-app quickstart for Arduino, Python, ROS 2 and Rust. Every
  snippet in it is compiled or tested against the real libraries.
- **Simulated devices, one at a time**: the pairing dialog has a Simulated tab
  (drone, rover, arm, rocket, test bench). Add only the ones you want; they are
  marked SIM everywhere, come with example sequences, and speak the same
  protocol as real devices with sensor sets a hobby build would have. Sample
  recordings are loaded from the Replay screen and marked Demo.
- **Home**: "Set home" (Control, Program) makes the current position the origin
  for return-to-home, the Home readout and waypoints; arms save the current
  pose as their home pose.
- **Tiles follow the data**: dashboard tiles appear only for channels the device
  actually sends.

## Library support

Every library implements the whole protocol. What differs is what each
platform can do:

| | Arduino | Python | Rust | ROS 2 bridge |
|---|---|---|---|---|
| Wi-Fi (UDP) | ESP32, ESP8266, Pico W, UNO R4 WiFi, Nano 33 IoT, MKR WiFi 1010 / 1000, Nano RP2040 Connect, Portenta, GIGA | yes | yes, `std` | yes |
| Any networking library (`beginUdp(udp)`): W5500/ENC28J60 Ethernet, QNEthernet, WiFiEspAT, WiFi101 | yes | – | any `Transport` | – |
| BLE peripheral | ESP32 (Bluedroid or NimBLE), nRF52 (Bluefruit), Nano 33 BLE / IoT, UNO R4 WiFi (ArduinoBLE) | yes (`bless`) | `no_std`: your stack implements `Transport` | yes |
| Bluetooth serial modules (HM-10 family, HC-05/06, RN4870, Bluno) | `beginModule()` | `module=` | `.module()` | – |
| USB serial | any `Stream` | yes (`pyserial`) | yes (`stty`, no deps) | yes |
| Radio: SiK, XBee, HC-12, LoRa UART | `beginRadio()` | `radio=` | `.radio()` | `radio:` |
| LoRa on SPI | `fallback(LORA)` | via a UART module | via a UART module | via a UART module |
| Several links, fallback | yes | yes | yes (`Fallback`) | `fallback:` |
| All telemetry channels, points, tracks, log | yes | yes | yes | from topics |
| Custom channels, parameters with labels | yes | yes | yes | yes |
| Saved parameters (`psave`) | ESP32 flash | file | file | file |
| Pairing key storage | ESP32 flash | file | file | file |
| Video | `video()` + ESP32-CAM example | `MjpegServer`, `camera()` | `MjpegServer` | `video:` topic |
| `no_std` / embedded | — | — | yes | — |

## Quick start

```bash
# app
cd apps/dash && flutter run -d macos        # or an emulator, a phone…

# a simulated rover on your network, to test the real Wi-Fi path
cd libs/python && python3 -m venv .venv && .venv/bin/pip install -e .
.venv/bin/koebelt-link-sim --kind rover
# in the app: Devices > Pair device (it appears via LAN discovery)
```

## Tests

| Component | Command | Covers |
|-----------|---------|--------|
| App | `cd apps/dash && flutter test` | MAVLink against a pymavlink vehicle over UDP (needs `pip install pymavlink` in the venv), MSP against a simulated Betaflight board, Tello against a fake drone, board recognition, protocol vectors, codec, full sessions against the simulator (stop, failsafe, params), Python interop over UDP, MJPEG parsing and the simulated camera end to end, radio profiles and heartbeat rates, controller mapping and driving a simulated drone |
| App screenshots | `CAPTURE_DIR=/tmp/shots flutter test test/capture_test.dart` (and `capture_features_test.dart`) | renders the screens at phone, tablet and desktop sizes |
| Python | `cd libs/python && .venv/bin/python -m pytest` | vectors, handshake, control, stop, failsafe, params, pairing, point cloud over real UDP; radio rates and telemetry-only rules; MJPEG server |
| Arduino core | `make -C libs/arduino/KoebeltLink/test` | same behaviours on the host with a fake transport, radio profiles, video declaration, plus a compile check of every guide snippet |
| Rust | `cd libs/rust && cargo test` | JSON codec, UDP device end to end, radio links over a stream, fallback on failsafe, saved parameters, MJPEG server, `no_std` build (`--no-default-features --features embassy`) |
| ROS 2 | `pytest libs/ros2/koebelt_link_ros/test` | conversion helpers (the node itself needs a ROS install) |

## Design

The UI follows the KOEBELT design system (Claude Design project
`koebelt/dash`): dark-only surfaces, lime `#DCFB47` as the single accent,
Archivo for text and JetBrains Mono for labels. Tokens are in
`apps/dash/lib/theme/tokens.dart`.
