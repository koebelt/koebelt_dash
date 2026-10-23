# koebelt-dash-scripts

Control drones, robots and test rigs connected in
[koebelt/dash](https://koebelt.com/work/koebelt-dash) from Python: read their
telemetry, drive them, react to buttons and conditions, with any Python
package you like (OpenCV, PyTorch, YOLO…).

```sh
pip install koebelt-dash-scripts
```

```python
from koebelt_dash_scripts import connect, every, pid

dev = connect()                      # the device selected in koebelt dash
speed = dev.setting("speed", 0.4, min=0, max=1)   # a slider in dash
hold = pid(1.5, 0.0, 0.2)

@dev.trigger("Stop here", key="S")   # a button in dash
def stop_here():
    dev.mode("HOLD")

dev.mode("MANUAL")
for _ in every(0.05):                # 20 Hz
    error = 0.0 - dev.tlm.pos[0]     # stay on the north-south line
    dev.sticks(throttle=speed.value, steer=hold.update(error))
```

A script can say what it needs, and dash only runs it on a device that
fits:

```python
# requires: drone, rover     # a kind: any one of them
# requires: gps, camera      # capabilities: all of them
```

Capabilities are the sensors the device announces (`gps`, `imu`, `lidar`,
`camera`, `baro`…) and what dash sees on it (`battery`, `joints`, its own
channels such as `motor_temp`, `sequences`). `connect(requires=[...])` adds
more from the code.

Run it from koebelt dash (Scripts), or from a terminal while dash is open on
the same computer: it finds dash by itself.

With a model on the camera:

```python
from ultralytics import YOLO
from koebelt_dash_scripts import connect, pid

model = YOLO("yolov8n.pt")
dev = connect()
steer = pid(1.2, 0, 0.1)

for frame in dev.camera.frames():
    result = model(frame, verbose=False)[0]
    dev.overlay(result)                       # see what the model sees, in dash
    people = [b for b in result.boxes if int(b.cls) == 0]
    if not people:
        dev.sticks(throttle=0, steer=0)
        continue
    x = float(people[0].xywhn[0][0]) - 0.5    # −0.5 left … 0.5 right
    dev.sticks(throttle=0.4, steer=steer.update(-x))
```

## Script hosts: scripts for phones and tablets

koebelt dash on an iPhone, iPad or Android device sends its scripts to a
computer on the same network, which runs them with its own Python (and its
GPU), while the phone keeps the device link, the sticks and STOP:

```sh
pip install koebelt-dash-scripts
koebelt-dash-scripts host
```

It prints a pairing code; in dash: Scripts > Runs on > Add a script host. A
laptop on the field, a Raspberry Pi 5 or a Jetson all work. A computer
running koebelt dash can also be a host (Settings > Scripts).

## Safety

dash stays in charge, whatever the script does:

- STOP stops every device and ends the script.
- Moving the sticks in dash takes over; the script's sticks are ignored until
  you resume it.
- Each script has limits set in dash: maximum speed, geofence, ceiling.
  Arming, take-off and parameter writes are refused unless you allow them.
- If the script crashes, hangs or leaves the geofence, the device holds, and
  the script cannot drive again until you resume it.

## The API

| | |
|---|---|
| `connect(device=None)` | The device selected in dash, or the one with that name. |
| `dev.tlm` | Latest telemetry (20 Hz): `pos` (m from home, x east, y north), `alt`, `vel`, `speed`, `roll` `pitch` `yaw`, `heading`, `mode`, `armed`, `battery`, `gps`, `joints`… |
| `dev.next_tlm()` | Waits for the next telemetry. |
| `dev.sticks(...)` | −1…1, held until changed. Drones: `throttle yaw pitch roll`; rovers: `throttle steer`. |
| `dev.mode(m)`, `dev.arm()`, `dev.disarm()`, `dev.speed_limit(v)`, `dev.cmd(name, **args)`, `dev.stop()`, `dev.release()` | Commands. |
| `dev.takeoff(alt)`, `dev.goto(x, y, z)`, `dev.land()`, `dev.rth()`, `dev.pose(*deg)`, `dev.gripper(pct)`, `dev.home()`, `dev.throttle(pct, s)`, `dev.ramp(a, b, s)` | Steps, as in a sequence; they return once done (or at once with `wait=False`). |
| `dev.run_sequence(name)`, `dev.pause_sequence()`, `dev.resume_sequence()`, `dev.stop_sequence()` | Sequences from dash's Automate > Sequences, by name. |
| `dev.camera.frame()`, `for img in dev.camera.frames():` | The camera as numpy images (BGR, for OpenCV; needs `opencv-python` or `pillow`). The newest frame only: a slow model never falls behind. |
| `dev.overlay(boxes)` | Boxes over the camera in dash: `(x, y, w, h, label)` tuples or an ultralytics result. |
| `dev.params["KEY"]`, `dev.params.set(KEY=v)`, `dev.params.save()` | Parameters. |
| `dev.setting(name, default, min, max)` | A slider or switch in dash; read `.value`. |
| `@dev.trigger(name, kind, key, gamepad)` | A button (`button`), switch (`switch`) or number (`value`) in dash. |
| `@dev.on_trigger`, `@dev.on_stop`, `@dev.on_takeover` | Other events. |
| `dev.plot(name, v)`, `dev.mark(text)`, `dev.notify(text)` | Shown in dash and recorded. |
| `dev.store` | A dictionary kept between runs. |
| `dev.run()` | Waits, for scripts that only react to triggers. |
| `every(seconds)`, `wait(seconds)` | Steady loops; dash shows the real rate. |
| `pid`, `lowpass`, `rate_limit`, `clamp`, `distance`, `bearing`, `angle_diff`, `geo_distance`, `geo_bearing` | Helpers. |

## Errors

When something goes wrong, the error says what, points at the line of your
script, says why and how to fix it, and suggests the name you meant:

```
error[E0201]: “pitch” is not a stick of a rover
  --> follow_me.py:21
   |
21 |     dev.sticks(throttle=0.4, pitch=steer)
   |     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
   |
   = why: sticks are named for the kind of device
   = help: a rover has: throttle, steer, lx, ly, rx, ry
   = docs: https://github.com/koebelt/koebelt_dash/blob/main/libs/python-dash-scripts/ERRORS.md#e0201
```

Every code is explained in [ERRORS.md](ERRORS.md). Catch them as `ScriptError`
(`e.code`, `e.why`, `e.help`).

The messages between scripts and dash are documented in
[protocol/SCRIPTS.md](https://github.com/koebelt/koebelt_dash/blob/main/protocol/SCRIPTS.md).

MIT licence.
