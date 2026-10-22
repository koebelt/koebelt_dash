# koebelt/dash script API, version 1

How scripts (the `koebelt-dash-scripts` Python package, or any other client)
talk to koebelt/dash. The devices never see these messages: dash checks each
one against the operator's limits, then acts on the device with the
koebelt/link protocol ([PROTOCOL.md](PROTOCOL.md)).

## Connecting

A WebSocket to `ws://127.0.0.1:47920/scripts`, JSON text messages, one object
each, with a `t` (type).

dash writes where it listens to `~/.koebelt/dash-api.json` (Windows:
`%USERPROFILE%\.koebelt\dash-api.json`):

```json
{"url": "ws://127.0.0.1:47920/scripts", "token": "9f2c…", "pid": 4242, "app": "1.3.0"}
```

A script dash starts gets the same in `KOEBELT_DASH_URL` and
`KOEBELT_DASH_TOKEN`, which take precedence.

The first message must be `hello` with the token; anything else closes the
connection with `{"t":"bye","why":"…"}`.

```json
→ {"t":"hello","v":1,"token":"9f2c…","name":"follow_me.py","pid":5120}
← {"t":"welcome","v":1,"app":"1.3.0","devices":[{"id":"sim-mule","name":"Mule","kind":"rover","sim":true,"focus":true}]}
```

## Requests and results

Messages with an `id` get a result:

```json
← {"t":"res","id":7,"ok":true,"value":…}
← {"t":"res","id":8,"ok":false,"err":"Arming is not allowed for this script (Limits in dash)."}
```

## Script → dash

| `t` | Fields | |
|---|---|---|
| `use` | `device`: id or name, or absent for the device selected in dash | Chooses the device. `value`: id, name, kind, sim, lib, limits. Telemetry starts. |
| `sticks` | `a`: `{"throttle":0.5,"steer":-0.2}` | Named sticks for the kind (drone: `throttle yaw pitch roll`; rover: `throttle steer`) or raw axes `lx ly rx ry`, −1…1. The first call takes the device's sticks. They hold until changed. |
| `release` | | Gives the sticks back; the device holds. |
| `cmd` | `c`, `a` | `mode` `{m}`, `arm`, `disarm`, `speed` `{v}`, `params` (value: the parameters), `pset` `{KEY: value}`, `psave`, `stop` (STOP, always allowed), or a kind-specific command sent as is (`release`, `sethome`, `countdown`…). |
| `setting` | `name`, `value`, `min`, `max`, `label` | Declares a setting shown in dash. `value`: the current one (the operator's, if they changed it). |
| `trigger` | `name`, `kind` (`button`, `switch`, `value`), `key`, `gamepad`, `min`, `max` | Declares a trigger the operator can fire and bind. |
| `print` | `text`, `level` | A console line in dash. |
| `plot` | `name`, `v` | A value shown and recorded as channel `script:<name>`. |
| `mark` | `text` | An event on the recording's timeline. |
| `notify` | `text`, `level` | A message to the operator. |
| `ka` | `hz` | Keep-alive. The client library sends it every 100 ms, with the script's loop rate when it uses `every()`. |

## dash → script

| `t` | Fields | |
|---|---|---|
| `tlm` | `d` | 20 Hz, the device's telemetry: `pos` (m from home), `vel`, `roll` `pitch` `yaw` (rad), `speed`, `heading` (°), `mode`, `armed`, `estop`, `failsafe`, `latency`, `drive` (`none`, `script`, `operator`), and what the device has: `lat` `lon` `galt`, `voltage` `current` `battery`, `rssi`, `acc` `gyro`, `joints`, `gripper`, `thrust`… and `custom` channels. |
| `setting` | `name`, `value` | The operator changed a setting. |
| `fire` | `name`, `value` | A trigger fired. |
| `takeover` | `on` | The operator moved the sticks (`true`), or gave them back (`false`). While on, `sticks` are ignored. |
| `released` | `why` | The script lost the sticks: watchdog, geofence, ceiling, STOP, disconnection. The device holds, and `sticks` are refused until the operator resumes the script. |
| `resumed` | | The operator resumed the script: it may drive again. |
| `stop` | | STOP was pressed. |

## Safety

- Sticks are scaled by the script's speed limit (operator setting, 60 % by
  default), and `speed` is capped by it.
- `arm`, `mode TAKEOFF`, `pset` and `psave` are refused unless the operator
  allowed them for the script.
- Moving the operator's sticks beyond 15 % takes over until the operator
  resumes.
- A script that drives and sends nothing for 0.5 s, disconnects, takes the
  device beyond its geofence (horizontal distance from home) or, for drones,
  above its ceiling, loses the sticks and the device switches to HOLD. It
  cannot take them again until the operator resumes it in dash.
- STOP releases every script and refuses their commands until the operator
  clears it.
