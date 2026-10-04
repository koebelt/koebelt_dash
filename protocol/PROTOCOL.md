# KoebeltLink protocol · v1

The wire protocol between a device running a KoebeltLink library and the
koebelt dash app. Every library in `libs/` and the app in `apps/dash`
implement this document; `protocol/vectors.json` holds messages that every
implementation must encode and decode identically.

## Design goals

- Implementable in a few hundred lines on an ESP32, in Python, in Rust
  `no_std`, and in Dart.
- Human-readable on the wire so a serial monitor is a debugger.
- One message format for every transport.

## Framing

A **message** is a single JSON object, UTF-8, with a string field `t`
(type). Unknown fields must be ignored, unknown types must be ignored.

| Transport     | Framing                                                                 |
|---------------|-------------------------------------------------------------------------|
| UDP (Wi-Fi)   | One message per datagram. Device listens on port **47800**.             |
| USB serial    | Newline-delimited JSON (`\n` terminated). 115200 baud by default.       |
| BLE           | Newline-delimited JSON split across GATT writes/notifications.          |
| Radio         | Newline-delimited JSON through a radio modem on a serial port (SiK, HC-12, XBee, LoRa). See [Radio links](#radio-links). |

### UDP discovery

- Devices broadcast an `announce` message to `255.255.255.255:47801` once per
  second while not connected to an app.
- The app may also broadcast a `discover` message to port 47800; every device
  replies with `announce` to the sender.
- After `hello`, the device sends everything to the address the `hello` came
  from.

### Serial and radio discovery

On serial and radio links the device writes its `announce` message to the
link once per second while no session is open, so the app can identify the
device on the far side of a radio before pairing. The app may write
`discover` to get one immediately.

### BLE service

Nordic-UART-compatible layout so generic BLE tools work:

| Role           | UUID                                   |
|----------------|----------------------------------------|
| Service        | `6e400001-b5a3-f393-e0a9-e50e24dcca9e` |
| RX (app→dev)   | `6e400002-b5a3-f393-e0a9-e50e24dcca9e` (write without response) |
| TX (dev→app)   | `6e400003-b5a3-f393-e0a9-e50e24dcca9e` (notify)                 |

The advertised local name is the device name. The advertisement's
manufacturer data (company id `0xFFFF`) holds the ASCII string `KL1`.

## Device kinds

`drone`, `rover`, `arm`, `rocket`, `bench`, `generic`. The kind picks the
app's default dashboard, the control screen and the 3D model.

## Modes

`AUTO`, `MANUAL`, `HOLD`, `TAKEOFF`, `LAND`, `RTH` (drones, rovers, arms)
Rockets use flight phases: `PAD`, `COUNT`, `BOOST`, `COAST`, `DROGUE`,
`MAIN`, `LANDED`. Test benches: `IDLE`, `MANUAL`, `RAMP`, `STEPS`, `CUTOFF`.

## Messages · device → app

### `announce`
```json
{"t":"announce","v":1,"id":"kite-03","name":"Kite-03","kind":"drone","lib":"arduino/1.5.0","pair":"4F7-K2Q"}
```
`pair` is present only while the device is in pairing mode.

### `hello` (reply to the app's `hello`)
```json
{"t":"hello","v":1,"id":"kite-03","name":"Kite-03","kind":"drone","model":"Quadcopter · 1.4 kg",
 "fw":"2.4.1","lib":"arduino/1.5.0","sensors":["GPS","IMU","BARO","LIDAR"],"ok":true}
```
`ok:false` with `err:"key"` when the pairing key does not match.

Optional `video` lists camera streams the app can show (see [Video](#video)):
```json
"video":[{"id":"cam","url":":81/stream","fmt":"mjpeg","label":"Front"}]
```

### `chan` · channel declarations
Sent after `hello` and whenever a channel is added.
```json
{"t":"chan","ch":[{"id":"motor_temp","axes":["M1","M2","M3","M4"],"unit":"C","hz":10}]}
```

### `tlm` · telemetry
The latest value of each channel since the last frame. Sent at the telemetry
rate the app asked for (`rate`), default 30 Hz. Arrays are fixed-order per
channel.
```json
{"t":"tlm","ts":123456,"d":{"imu":[0.1,0.0,9.8,0.0,0.01,0.2],"bat":[16.4,12.0,86]}}
```

Built-in channels:

| id       | values                                              | unit            |
|----------|-----------------------------------------------------|-----------------|
| `imu`    | ax, ay, az, gx, gy, gz                              | m/s², rad/s     |
| `att`    | roll, pitch, yaw                                    | rad             |
| `pos`    | x, y, z (local ENU from home)                       | m               |
| `vel`    | vx, vy, vz                                          | m/s             |
| `gps`    | lat, lon, alt, sats                                 | deg, deg, m, -  |
| `bat`    | volts, amps, percent                                | V, A, %         |
| `rssi`   | rssi                                                | dBm             |
| `joints` | j1 … j6                                             | rad             |
| `tool`   | x, y, z, gripper (0–1)                              | m, -            |
| `ft`     | fx, fy, fz                                          | N               |
| `thrust` | thrust, torque                                      | N, N·m          |
| `rpm`    | rpm                                                 | rpm             |
| `temp`   | temperature                                         | °C              |
| `throttle` | commanded throttle output (0–1)                   | -               |
| `rocket` | max altitude, phase time, countdown                 | m, s, s         |

Custom channels use any other id and are declared with `chan`.

### `state`
Sent on change and at 2 Hz.
```json
{"t":"state","mode":"AUTO","armed":true,"estop":false,"fs":false,
 "ext":{"pyro":["OK","OK","OK","-"],"cutoff":"Current limit","seq":{"kind":"RAMP","t":2.1}}}
```
`fs` is true while the device's own failsafe is active. `ext` carries
kind-specific state.

### `pc` · point cloud
```json
{"t":"pc","f":"i16cm","n":1200,"d":"<base64>"}
```
`d` is `n` little-endian int16 triplets (x, y, z) in centimetres, in the
local frame. Sent at most at 10 Hz.

### `tracks` · radar / safety scanner targets
```json
{"t":"tracks","d":[["T1",18.2,0.61],["T2",32.0,2.4]]}
```
Each entry: id, range (m), bearing (rad, clockwise from north / device
forward for arms).

### `params` · parameter table
Sent after `hello`.
```json
{"t":"params","p":[["RATE_RLL_P",0.135,0,0.5,0.001,""],["MAX_TILT",35,10,60,1,"deg"]]}
```
Entry: key, value, min, max, step, unit, and an optional seventh element,
the human label. Without a layout the app groups parameters by the prefix
before the first underscore. A device may send an explicit layout:

```json
"layout":[{"cat":"Rate PID","name":"Roll rate","chart":["gx"],"keys":["RATE_RLL_P","RATE_RLL_I"]}]
```

`chart` lists app history channels drawn above the group as live response.
Large tables may be split: every message but the last carries `"more":true`
and the app concatenates them.

### `pack` · parameter write acknowledgement
```json
{"t":"pack","ok":true,"keys":["RATE_RLL_P"]}
```

### `pong`
```json
{"t":"pong","ts":1712345678}
```
Echoes `ts` from `ping` so the app can measure round-trip latency.

### `paired`
```json
{"t":"paired","id":"kite-03"}
```

### `log`
```json
{"t":"log","lvl":"warn","msg":"GPS lost"}
```

## Messages · app → device

| Message | Example | Notes |
|---------|---------|-------|
| `discover` | `{"t":"discover"}` | UDP broadcast only. |
| `hello` | `{"t":"hello","v":1,"app":"dash/0.9.2","key":"a1b2…"}` | Starts a session. `key` is omitted for unpaired devices in open mode. |
| `pair` | `{"t":"pair","code":"4F7-K2Q","key":"<32 hex>"}` | Device stores `key` if `code` matches its pairing code. |
| `ctl` | `{"t":"ctl","s":812,"lx":0,"ly":0.4,"rx":0,"ry":-0.1}` | Four normalised axes −1…1. Sent at 20 Hz while a session is open, also when all zero: it is the heartbeat for the failsafe. |
| `jog` | `{"t":"jog","j":[0,0,1,0,0,0]}` | Arm joint jog velocity per joint, −1…1. |
| `cart` | `{"t":"cart","v":[0,0,-1]}` | Arm Cartesian jog, −1…1 per axis. |
| `mode` | `{"t":"mode","m":"RTH"}` | |
| `arm` | `{"t":"arm","v":true}` | |
| `stop` | `{"t":"stop"}` | Emergency stop. Sent three times, 30 ms apart. The device must cut actuators and disarm. |
| `reset` | `{"t":"reset"}` | Clears the stop. The device stays disarmed. |
| `cmd` | `{"t":"cmd","c":"countdown","a":{"s":10}}` | Kind-specific commands, see below. |
| `pset` | `{"t":"pset","p":{"RATE_RLL_P":0.14}}` | Write parameters. |
| `psave` | `{"t":"psave"}` | Persist parameters to flash. |
| `rate` | `{"t":"rate","hz":30}` | Telemetry rate. |
| `fs` | `{"t":"fs","action":"RTH","ms":1800}` | Failsafe action (HOLD, RTH, LAND) and timeout chosen in the app. |
| `speed` | `{"t":"speed","v":0.5}` | Speed limit 0.1–1. |
| `ping` | `{"t":"ping","ts":1712345678}` | 1 Hz. |
| `bye` | `{"t":"bye"}` | Ends the session. The device keeps its current mode; drones switch to hold. |

### `cmd` values

| Kind   | `c`         | `a`                           |
|--------|-------------|-------------------------------|
| drone  | `takeoff`   | `{"alt":10}` arm, climb to alt (m), then HOLD |
| drone, rover | `goto` | `{"x":15,"y":0,"z":10}` fly/drive to a point (m, ENU from home; `z` drones only). Report `AUTO` while moving, `HOLD` on arrival |
| arm    | `pose`      | `{"j":[0,-0.5,1.1,0,0.6,0]}` joint targets (rad), mode MANUAL |
| arm    | `home`      | –  move to the home pose     |
| drone, rover | `sethome` | – current position becomes home: `pos` restarts at (0, 0), RTH returns here |
| arm    | `sethome`   | `{"j":[…]}` joint angles (rad) that `home` moves to; current joints when omitted |
| arm    | `gripper`   | `{"v":0.9}` open fraction     |
| rocket | `countdown` | `{"s":10}`                    |
| rocket | `abort`     | –                             |
| rocket | `deploy`    | `{"ch":0}` pyro channel       |
| rocket | `reset`     | –                             |
| bench  | `throttle`  | `{"v":0.5}`                   |
| bench  | `seq`       | `{"kind":"RAMP"}` / `{"kind":"STEPS"}` / `{"kind":null}` to stop |
| bench  | `clear`     | – clears a cutoff             |

## Radio links

A radio link is a pair of radio modems: one on the device's UART, its twin
on a serial port of the computer or phone running the app. Both ends speak
newline-delimited JSON as on USB serial; the radio is transparent. Because
air time is scarce, both ends follow a shared **profile** (the same table is
in `vectors.json` under `radio`):

| id      | Radio                                    | Baud   | Telemetry | Control |
|---------|------------------------------------------|--------|-----------|---------|
| `sik`   | SiK telemetry radios (3DR, Holybro, RFD900) | 57600 | 5 Hz | 10 Hz |
| `lora`  | LoRa UART module or LoRa ground station   | 115200 | 2 Hz | none  |
| `hc12`  | HC-12 433 MHz                             | 9600   | 2 Hz | 5 Hz  |
| `xbee`  | XBee / DigiMesh, transparent mode         | 57600  | 5 Hz | 10 Hz |
| `other` | Any transparent serial radio              | 57600  | 2 Hz | 5 Hz  |

On a radio link the device:

- caps telemetry at the profile rate, whatever `rate` asks;
- sends `state` on change and every 2 s instead of 2 Hz;
- sends no `pc` or `tracks`;
- at 2 Hz or less sends only `pos`, `att`, `gps`, `bat` and `rocket`, and no
  custom channels.

The app sends its `ctl` heartbeat at the profile's control rate and pings
every 5 s. Devices should use a failsafe timeout of at least 1.5 s on radio.

**Telemetry-only links** (control rate "none") carry no control: the
device ignores every message except `stop`, `ping`, `rate` and `bye` on
them. A STOP still goes through, slowly. Use another link (Wi-Fi, BLE or a
SiK radio) to fly or drive.

LoRa modules on SPI (not UART) need a small ground-station board that
passes packets to USB serial; the app sees that board as a `lora` radio.

## Serial bridge modules

Bluetooth modules with a UART (HM-10 and clones, HC-05/HC-06, JDY, HC-08,
RN4870, DFRobot Bluno) pass bytes between the app and the board's serial
port, so the board speaks newline-delimited JSON as on USB serial. Their
UART is usually 9600 baud, so the device sends telemetry at a rate set by
the module's baud, the same rule in every library:

| UART baud    | Telemetry          |
|--------------|--------------------|
| ≤ 19200      | 2 Hz, compact set  |
| ≤ 57600      | 5 Hz               |
| above        | 10 Hz              |

No `pc` or `tracks`, `state` every 2 s, control accepted. The app paces its
writes to the module (20-byte packets, 25 ms apart), sends `ctl` at 5 Hz
and asks for 5 Hz telemetry. It recognises these BLE services:

| Module | Service | App writes | App subscribes |
|--------|---------|-----------|----------------|
| HM-10 family | `ffe0` | `ffe1` | `ffe1` |
| DFRobot Bluno | `dfb0` | `dfb1` | `dfb1` |
| Microchip RN4870 / BM70 | `49535343-fe7d-4ae5-8fa9-9fafd205e455` | `…8841-43f4-a8d4-ecbe34729bb3` | `…1e4d-4bd9-ba61-23c647249616` |

Bluetooth Classic modules (HC-05, HC-06) are paired in the operating
system and appear to the app as serial ports.

## Video

Video does not travel over KoebeltLink. A device declares camera streams in
`hello`; the app opens them itself.

| Field   | Meaning |
|---------|---------|
| `id`    | Stream id, unique per device. |
| `url`   | `http://…` or `:port/path`. The short form means "this device's IP", for devices on Wi-Fi that do not know the address the app reached them on. |
| `fmt`   | `mjpeg`: HTTP `multipart/x-mixed-replace` with one JPEG per part (ESP32-CAM, mjpg-streamer, ustreamer). `jpeg`: a still image the app polls. |
| `label` | Optional name shown in the app. |

Parts should carry `Content-Length`; the app falls back to the boundary when
they do not. Servers should send the newest frame to each client rather
than queueing, so a slow link drops frames instead of building latency.

## Failsafe

The library, not the app, owns the failsafe. When armed and no `ctl`
arrives for the configured timeout (default 1.8 s), the library switches to
the configured failsafe mode and calls the user's mode handler. It returns
control when `ctl` packets resume **and** the app sends a new `mode`.

Rockets ignore the failsafe; test benches cut the motor.

## Pairing

1. The app shows a pairing code (7 characters, `XXX-XXX`, valid 10 minutes).
2. The device calls `pair(code)`; it adds `pair` to its `announce`.
3. The app, while listening, matches the code, then sends `pair` with a
   random 128-bit key.
4. The device stores the key and answers `paired`. From then on it only
   accepts `hello` messages carrying that key.

The key authenticates the session; the protocol does not encrypt. Use WPA2
on the Wi-Fi link, BLE bonding, and the radios' own encryption where they
have it (XBee, RFD900x: AES) for confidentiality.

## Sequences

These are command names inside the existing `cmd` message, not changes to
the wire format: a device that does not implement one simply ignores it.

The app's Program screen runs sequences step by step using the commands
above plus `mode`, `arm` and `speed`. It checks each step's completion
against telemetry (position within 1 m / 0.6 m, joints within 0.03 rad, mode
and armed state) and stops the sequence on STOP, manual stick input or
disconnect, and pauses it on link loss. The device needs no sequence
support of its own beyond handling these commands; its failsafe keeps
running as usual.
