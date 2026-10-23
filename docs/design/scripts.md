# Scripts (koebelt/dash 1.3) — design

Status: built for koebelt/dash 1.3. Where the build differs from this design, the code and protocol/SCRIPTS.md are right.

## 1. Goal

Let makers control their devices automatically with Python: from simple
behaviours (hold, circle, patrol) to heavy machine learning on the camera
image (OpenCV, PyTorch, YOLO). The script runs in the maker's own Python, with
any package they like. koebelt/dash stays in charge of safety: STOP, takeover,
limits and the failsafe always work, whatever the script does.

The same Python API serves two uses:

- **Scripts managed by dash.** A Scripts screen, on every platform, where
  scripts are created, imported, edited and launched, with their console,
  settings and triggers. On a computer they run in its Python; on a phone or
  tablet they run on a computer the phone is paired with (a *script host*,
  section 2).
- **External control.** A script started anywhere else (a terminal, Jupyter,
  a ROS node) connects to a running dash the same way.

## 2. How it runs

```
 ┌──────────── computer ─────────────┐            ┌──────── device ───────┐
 │ python my_script.py               │            │ firmware with         │
 │   koebelt_dash_scripts (PyPI)     │            │ koebelt/link          │
 │        │ WebSocket, 127.0.0.1     │            │                       │
 │        ▼                          │  Wi-Fi /   │                       │
 │ koebelt/dash  ── safety layer ────┼── BLE ────►│                       │
 └───────────────────────────────────┘            └───────────────────────┘
```

- dash opens a **script API** on `127.0.0.1` (a WebSocket). Scripts never talk
  to the device directly: every command passes dash's safety layer, which is
  also what keeps the 20 Hz heartbeat to the device.
- When dash starts a script, it passes the address and a one-time token in
  environment variables, so `connect()` needs no arguments.
- A script started by hand finds dash on the same computer automatically.
- **Phones and tablets.** dash on iPhone, iPad or Android cannot run the
  scripts itself: no ML libraries exist there, and the App Store forbids
  loading downloaded code. They are still created, edited and launched from
  the phone; they *run* on a **script host**, a computer on the same network:
  - a computer running dash (Settings > Scripts > "Be a script host"), or
  - a headless one (a laptop on the field, a Jetson, a Raspberry Pi 5):
    `pip install koebelt-dash-scripts` then `koebelt-dash-scripts host`.

  The phone pairs with the host once, with a code shown on the host. When the
  operator presses Run on the phone, the phone sends the script, its settings
  and its trigger bindings; the host runs it in its Python and the script
  connects back to the phone's dash, which keeps the device link, the live
  view, takeover and STOP in the operator's hand. The console streams back to
  the phone. If the host or the network drops, the watchdog (section 5) holds
  the device.
- A computer running dash can be a host for other computers too, and a script
  started by hand anywhere on the network can connect to a phone's dash after
  the same pairing ("Allow scripts from this network", off by default).

### Python interpreter

Settings > Scripts > Python: dash lists the interpreters it finds (system,
Homebrew, pyenv, conda, venvs next to the script) and accepts a path. If
`koebelt-dash-scripts` is missing from it, dash offers to install it with
`pip install koebelt-dash-scripts` (shown, then run, on a click). A script can also
choose its own interpreter with a first-line comment:
`# python: ~/venvs/vision/bin/python`.

## 3. The Python API (`pip install koebelt-dash-scripts`)

```python
from koebelt_dash_scripts import connect
dev = connect()            # the device selected in dash (or connect("Kite"))
```

### Reading the device

| | |
|---|---|
| `dev.tlm` | Latest telemetry: `pos` (x, y, z m from home), `gps` (lat, lon, alt) when available, `alt`, `att` (roll, pitch, yaw °), `speed`, `heading`, `battery` (V, %), `link` (rssi, latency), `mode`, `armed`, `failsafe`, `estop`. Attribute access, always the newest value. |
| `dev.sensor("imu")` | Any channel the device sends, including custom ones the firmware declares (`motor_temp`…). Returns the latest sample; `.history(s)` the last s seconds as a numpy array. |
| `dev.points()` | Lidar point cloud as an N×3 numpy array. |
| `dev.tracks()` | Detected tracks as the device reports them. |
| `dev.camera.frame()` / `dev.camera.frames()` | Camera image(s) as numpy arrays (H×W×3, BGR so OpenCV takes them directly). `frames()` yields the newest frame each time and drops the ones the script was too slow for. |
| `dev.params` | Parameters: `dev.params["MAX_TILT"]`. |
| `dev.home` | Home position. |
| `dev.info` | Name, kind (drone, rover, arm, bench, rocket), model, library version. |
| `devices()` | All connected devices, for scripts that coordinate several. |

### Acting on it

| | |
|---|---|
| `dev.sticks(...)` | Continuous control, −1…1 per axis, by name for the kind: `throttle, yaw, pitch, roll` (drone), `throttle, steer` (rover). Holds until changed; dash keeps sending at 20 Hz. |
| `dev.jog(j)`, `dev.cart(v)` | Arms: joint or Cartesian jog. |
| `dev.takeoff(alt)`, `dev.goto(x, y, z)`, `dev.land()`, `dev.rth()`, `dev.pose(...)`, `dev.gripper(open)`, `dev.throttle(pct, s)`, `dev.ramp(...)` | The Program steps, one at a time. Each returns when the device reports it done (or `wait=False`). |
| `dev.mode("HOLD")`, `dev.arm()`, `dev.disarm()`, `dev.speed_limit(0.5)`, `dev.cmd(name, **args)` | Modes, arming, speed limit, kind-specific commands. |
| `dev.run_program("Survey square")` | Runs a stored Program sequence on the device (it keeps running if the link drops). `pause()`, `resume()`, `stop()`. |
| `dev.params.set(**values)` | Writes parameters (for auto-tuning). `dev.params.save()` persists them. |
| `dev.record(True)` | Starts or stops a recording in dash. |

### Showing things in dash

| | |
|---|---|
| `print()` | Goes to the script's console in dash. |
| `dev.plot(name, value)` | Publishes a value as a channel: it can be put on a Live tile and is saved in recordings and exports, next to the device's own data. |
| `dev.mark(text)` | A marker on the recording's timeline. |
| `dev.notify(text, level="info")` | A message in dash's alerts. |
| `dev.overlay(boxes)` | Draws boxes and labels over the camera tile (to see what the model sees). |

### Settings and storage

```python
speed = dev.setting("speed", 0.4, min=0, max=1)   # slider in dash
patrol = dev.setting("patrol", False)              # switch in dash
...
speed.value
```

`dev.store` is a small dictionary that dash keeps between runs of the script.

### Helpers (`koebelt_dash_scripts.tools`)

`pid(kp, ki, kd, limit=1)`, `lowpass(hz)`, `clamp`, `rate_limit`,
`vec` (2D/3D maths), `distance`, `bearing`, `geofence(radius, ceiling)`,
`follow_path(points)`, `every(seconds)` (a steady loop that reports its real
rate to dash), `wait(seconds)`, and a small `StateMachine`.

### Lifecycle

```python
@dev.on_start
def start(): ...
@dev.on_stop          # also called on STOP, takeover and errors
def stop(): ...
```

## 4. Triggers

Triggers let the operator, or a condition, fire an event in a running script:
"drop the payload", "start patrol", "next waypoint". There are two sides.

### The script declares what it reacts to

```python
@dev.trigger("Drop payload")                 # a button
def drop():
    dev.cmd("release")

@dev.trigger("Patrol", kind="switch")        # on/off
def patrol(on):
    ...

@dev.trigger("Target height", kind="value", min=2, max=30)
def height(v):
    ...

@dev.on_trigger                              # any trigger, including ones
def any_trigger(name, value):                # the operator adds in dash
    print(name, value)
```

A script may suggest bindings: `@dev.trigger("Drop payload", key="D",
gamepad="Y")`. The operator can change them.

### The operator adds and binds triggers in dash

On the script's page, **Triggers** lists the script's triggers and an
**Add trigger** button. Each trigger has a name (the event the script
receives) and one or more sources:

| Source | Fires |
|---|---|
| On-screen button / switch / slider | On the script's page, and optionally pinned to the Control screen next to the sticks |
| Game controller button | Through the existing controller mapping (a new "Script" group next to the built-in actions; a button does one thing, as today) |
| Keyboard key | Desktop; ignored while typing in a text field |
| Condition | A telemetry rule, built from a picker (field, comparison, value, held for N s) or typed as a short expression: `battery.pct < 25 for 3s`, `home.distance > 80`, `motor_temp.max > 70 and armed`. The two stay in sync: a picked rule shows as its expression, and an expression that fits the picker shows in it. Fires once when it becomes true (and with `false` when it clears, for switches). The expression language is small and safe: fields, numbers, comparisons, `and` / `or` / `not`, `abs`, `min`, `max`, `for Ns`; no Python, so conditions also work on phones without a host |
| Device event | Mode changed, armed / disarmed, failsafe, sequence finished, a device log message matching a text |
| Timer | Every N s, or once after N s |

Triggers the operator adds that the script has no handler for go to
`@dev.on_trigger`; if there is none, the console says so.

Triggers can also **start or stop a script** (Settings of each script:
"Start with…"), e.g. a gamepad button that starts "Follow me".

Bindings are saved per script, by file path, so they come back next time.

## 5. Safety

These hold whatever the script does:

1. **STOP** stops the device and kills the script process.
2. **Takeover.** Moving the sticks (on screen or on a controller) beyond the
   deadzone pauses the script's control: the script keeps running and
   receives `on_takeover`, but its commands are ignored until the operator
   presses Resume.
3. **Limits per script**, set in dash, not in the script: maximum speed,
   ceiling, geofence radius from home, and which commands are allowed
   (arming, take-off, parameter writes are off until the operator allows
   them). Commands outside the limits are clipped or refused, with a console
   line saying why.
4. **Watchdog.** If the script exits, crashes, or sends no command and no
   keep-alive for 0.5 s while it controls the sticks, dash switches the device
   to HOLD (LAND for drones without position hold) and shows why. The client
   library sends the keep-alive by itself while the script is alive, so a
   slow model (say 200 ms per frame) does not trip it; a hung script does.
5. The **device's own failsafe** still applies if dash itself goes quiet.
6. A script never runs on a device without the operator pressing Run (or a
   start trigger the operator configured). Scripts from the network (phones)
   need the pairing code first.

## 6. The Scripts screen (every platform)

A new **Scripts** entry: in the sidebar and rail on desktop and tablet, under
Program on phones (Program gets two tabs, Sequences and Scripts, so the tab
bar stays at five).

### The library

- **Create**: New script, blank or from a template (empty loop, hold, follow
  with YOLO, button action…). It starts with the right `connect()` and
  `every()` boilerplate for the selected device's kind.
- **Import**: from a file (`.py`, or a `.zip` with the script and its extra
  files such as a model), from the share sheet / "Open with" on phones, by
  drag and drop on desktop, or from a URL (a GitHub file or gist).
- **Examples** shipped with the app, copied into the library on use.
- Duplicate, rename, delete, **export / share** (the `.py`, or a `.zip`
  with its bindings and limits).
- Storage: a folder on disk on desktop (default
  `~/Documents/koebelt/dash-scripts`, so an external editor and git work too);
  the app's documents on phones, visible in the Files app (iOS) and the file
  manager (Android).

### The editor (built in)

- Python syntax highlighting, line numbers, indentation, find / replace,
  undo.
- Completion and hover help for the `koebelt_dash_scripts` API (from a bundled
  description of it; no language server needed).
- A check before running (syntax errors underlined, from the host's
  Python); a traceback in the console links to its line.
- On phones: a key row above the keyboard with Tab, `:`, `()`, `[]`, `=`,
  `"`, and undo.
- "Open in external editor" on desktop; dash reloads the file when it changes
  on disk.

### The script page

- Header: name, target device, where it runs (this computer or a host, with
  its interpreter), **Run / Stop**.
- Settings (sliders, switches) and trigger buttons, generated from the
  script.
- Console: stdout, stderr, the real loop rate, tracebacks.
- Triggers and their bindings (section 4), limits (section 5).
- A small live view of the device.

**Simulated devices** work too, which is how a script is tested before it
goes near hardware. While a script runs, its buttons, switches and STOP also
show on Control.

## 7. Wire format (dash ↔ script)

JSON messages over a WebSocket, binary messages for camera frames and point
clouds. It is versioned (`{"t":"hello","v":1}`) and documented next to
`protocol/PROTOCOL.md`, so clients in other languages are possible later.
Commands carry ids; dash answers with `ok` or the reason it refused them.

## 8. MCP server

An MCP server lets an AI assistant (Claude Desktop, Claude Code, Cursor, any
MCP client) work with dash as a knowledgeable co-pilot: learn the docs,
write and fix scripts, use the app, look at devices and recordings, and act
on hardware with the operator's approval.

### Packaged with the app, no Python needed

The server is part of dash itself (Dart), on every platform:

- **Streamable HTTP** on `http://127.0.0.1:<port>/mcp`, for clients that take
  a URL (Claude Code: `claude mcp add --transport http koebelt-dash <url>`).
- **stdio**, for clients that launch a command (Claude Desktop's config
  file): a small bridge, `koebelt-dash-mcp`, ships inside the app (compiled
  Dart, a few MB, signed with the app). It finds the running dash and relays
  to it; if dash is not running, it starts it.
- **One-click install** where the client supports it (Claude Desktop's MCP
  bundle file, a Cursor install link), from Settings > AI assistants.
- **Phones and tablets**: the same HTTP server, opened on the local network
  after pairing (a code and a token, like script hosts), so an assistant on a
  computer can use dash on the phone while it is open.

Settings > AI assistants: on/off (off by default), the copy-paste snippet
for each client, the one-click installs, which assistant is connected now,
and what it may do without asking (below).

Only the tools that run Python (checking and running scripts) need a script
host; everything else works with dash alone. The Python package stays what
scripts import, not something MCP needs.

### Tools

**Learn** (no approval)

| Tool | Does |
|---|---|
| `search_docs` | Searches the guides, the protocol, the koebelt/link and script API references and the examples; returns the relevant passages |
| `read_doc` | A whole guide or reference page |

The same documents are exposed as MCP resources, and MCP prompts give
starting points: "Write a script for my device", "Explain this recording",
"Help me tune this parameter", "Set up a new device with koebelt/link".

**Look** (no approval)

| Tool | Does |
|---|---|
| `list_devices` | Connected and paired devices: name, kind, link, mode, armed, library version |
| `get_telemetry` | Latest telemetry, or a summary over the last N seconds |
| `get_sensor` | A channel's recent samples (downsampled) |
| `get_camera_frame` | The current camera image, as an image the assistant can see |
| `get_params` | Parameters, with ranges and units |
| `list_recordings` / `get_recording` | Recorded sessions; a summary, an excerpt around a time, or one channel |
| `screenshot` | What dash shows right now, so the assistant can see what the operator sees |
| `get_alerts` | Current alerts and why |

**Write scripts and programs** (no approval; nothing moves)

| Tool | Does |
|---|---|
| `list_scripts` / `read_script` / `write_script` / `delete_script` | The script library, as in the editor. Deletes go to a trash the operator can restore from |
| `check_script` | Syntax and API check on the host's Python |
| `list_programs` / `write_program` | Program sequences |
| `write_trigger` | Adds or changes a trigger and its binding, including condition expressions |

**Use the app** (no approval; visible to the operator)

| Tool | Does |
|---|---|
| `open` | Shows a screen, a script, a recording or a guide |
| `add_simulated_device` | Adds a simulated device of a kind |
| `connect` / `disconnect` | Connects to a paired device (pairing a new one stays with the operator) |
| `set_layout` | Changes Live's tiles and layout |
| `record` / `export_recording` | Starts or stops a recording; exports one (CSV, GPX…) |
| `get_settings` / `set_setting` | App settings except safety ones (failsafe, limits, STOP, what the assistant may do), which the assistant can read but never change |

**Act** (approval on real hardware; free on simulated devices and replays)

| Tool | Does |
|---|---|
| `run_script` / `stop_script` / `script_output` | Runs a script on a device, reads its console, stops it |
| `fire_trigger` | Fires a running script's trigger |
| `run_program` | Runs a Program sequence |
| `command` | One action: mode, arm, take off, go to, land, RTH, gripper… |
| `set_params` | Writes parameters |
| `stop` | STOP. Always allowed, never asks |

### Operator in the loop

- On real hardware, every **Act** tool shows an approval card in dash: what,
  on which device, with the limits that apply, and Approve / Refuse. The
  assistant gets "approved", "refused" or "timed out" (30 s).
- The operator can allow a class of actions for the rest of the session
  ("run scripts on Mule", "parameter writes on the bench"). Arming and take-off
  always ask.
- Simulated devices and replays never ask, so an assistant can iterate on a
  script against the simulator freely, then ask once to run it for real.
- Everything goes through the same safety layer as scripts (section 5):
  limits, takeover, watchdog, STOP. The assistant cannot change limits,
  safety settings, or what it is allowed to do.
- A banner shows while an assistant is connected, with a button to disconnect
  it. dash logs its actions (shown in Settings > AI assistants, saved with
  recordings).

### Privacy

dash sends nothing to any AI service. The MCP client the user installs talks
to its own model provider; what it sends (telemetry, camera frames, scripts)
is between the user and that provider. The privacy page gets a line saying
so, and the settings page says it too.

## 9. Packaging

- `koebelt-dash-scripts` on PyPI (imported as `koebelt_dash_scripts`), in
  `libs/python-dash-scripts/`, released with the app (`app-v*`), MIT. Depends
  on `numpy` and `websockets` only; OpenCV, torch and others stay the user's
  choice. Its command line: `koebelt-dash-scripts host` (section 2).
- `koebelt-dash-mcp`, the stdio bridge, built per platform in the app release
  and shipped inside the app (macOS bundle, Windows install folder, Linux
  tarball), signed and notarized with it.
- Examples: hold altitude, circle home, patrol waypoints, follow a person
  with YOLO, color tracking with OpenCV, auto-tune a PID gain, a payload drop
  on a button.
- Guides: a new "Scripts" section in the in-app guides.
- App Store and Play builds: no Python inside, only the network API (allowed).

## 10. Testing

- The Python client against a dash test harness (the protocol), in CI.
- dash's safety layer: unit tests for limits, takeover, watchdog, STOP.
- End to end: a script driving a simulated device in CI, including a crash, a
  hang and a takeover.
- Each example runs against the simulator in CI (the YOLO one with a stub
  model).
- The MCP server with an MCP test client, over HTTP and through the stdio
  bridge: each tool, the approval flow (approved, refused, timed out, allowed
  for the session), that real hardware is never moved without approval, and
  that safety settings cannot be changed.
- The condition expression language: parser and evaluation, including
  invalid input.

## 11. Later (not in 1.3)

- Scripts that run on the device itself, in koebelt/link.
- An assistant built into dash (today it comes through MCP, with the user's
  own client).

## 12. Decisions

- Phones and tablets run scripts on a script host only.
- The package is `koebelt-dash-scripts`.
- Conditions: picker and short expressions, kept in sync.
- Default scripts folder: `~/Documents/koebelt/dash-scripts`.
- MCP: packaged with the app; it can act on real hardware with approval, and
  also learn the docs, write scripts and use the app.
