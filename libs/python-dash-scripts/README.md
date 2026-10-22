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

Run it from koebelt dash (Scripts), or from a terminal while dash is open on
the same computer: it finds dash by itself.

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
| `dev.params["KEY"]`, `dev.params.set(KEY=v)`, `dev.params.save()` | Parameters. |
| `dev.setting(name, default, min, max)` | A slider or switch in dash; read `.value`. |
| `@dev.trigger(name, kind, key, gamepad)` | A button (`button`), switch (`switch`) or number (`value`) in dash. |
| `@dev.on_trigger`, `@dev.on_stop`, `@dev.on_takeover` | Other events. |
| `dev.plot(name, v)`, `dev.mark(text)`, `dev.notify(text)` | Shown in dash and recorded. |
| `dev.store` | A dictionary kept between runs. |
| `dev.run()` | Waits, for scripts that only react to triggers. |
| `every(seconds)`, `wait(seconds)` | Steady loops; dash shows the real rate. |
| `pid`, `lowpass`, `rate_limit`, `clamp`, `distance`, `bearing`, `angle_diff`, `geo_distance`, `geo_bearing` | Helpers. |

The messages between scripts and dash are documented in
[protocol/SCRIPTS.md](https://github.com/koebelt/koebelt_dash/blob/main/protocol/SCRIPTS.md).

MIT licence.
