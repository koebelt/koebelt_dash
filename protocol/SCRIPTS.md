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
| `use` | `device`: id or name, or absent for the device chosen on the script's page, else the one selected in dash | Chooses the device. `value`: id, name, kind, sim, lib, limits, `cameras` (id, absolute url, fmt, label: scripts read the stream directly), `steps` (the Program steps this kind has). Telemetry starts. |
| `sticks` | `a`: `{"throttle":0.5,"steer":-0.2}` | Named sticks for the kind (drone: `throttle yaw pitch roll`; rover: `throttle steer`) or raw axes `lx ly rx ry`, −1…1. The first call takes the device's sticks. They hold until changed. |
| `release` | | Gives the sticks back; the device holds. |
| `cmd` | `c`, `a` | `mode` `{m}`, `arm`, `disarm`, `speed` `{v}`, `params` (value: the parameters), `pset` `{KEY: value}`, `psave`, `stop` (STOP, always allowed), `step` `{type, …fields, wait}` (one Program step: `takeoff` `{alt}`, `goto` `{x, y, z}`, `land`, `rth`, `pose` `{j1…j6}` (°), `gripper` `{open}` (%), `home`, `throttle` `{pct, s}`, `ramp` `{from, to, s}`, `wait` `{s}`), `program` `{name, wait}` (a sequence from the Program screen), `seqctl` `{c: pause, resume, stop}`, or a kind-specific command sent as is (`release`, `sethome`, `countdown`…). With `wait` (the default), `step` and `program` answer when they end: ok, or why they failed or were interrupted. |
| `setting` | `name`, `value`, `min`, `max`, `label` | Declares a setting shown in dash. `value`: the current one (the operator's, if they changed it). |
| `trigger` | `name`, `kind` (`button`, `switch`, `value`), `key`, `gamepad`, `min`, `max` | Declares a trigger the operator can fire and bind. |
| `print` | `text`, `level` | A console line in dash. |
| `plot` | `name`, `v` | A value shown and recorded as channel `script:<name>`. |
| `overlay` | `boxes`: `[[x, y, w, h, label], …]` | Boxes drawn over the device's camera in dash, normalised 0–1 from the top left; they fade a second after the last message. |
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
- `arm`, `mode TAKEOFF`, `pset`, `psave`, a `takeoff` step and a program that
  arms or takes off are refused unless the operator allowed them for the
  script. A `goto` beyond the geofence or above the ceiling is refused.
- Moving the operator's sticks beyond 15 % takes over until the operator
  resumes.
- A script that drives and sends nothing for 0.5 s, disconnects, takes the
  device beyond its geofence (horizontal distance from home) or, for drones,
  above its ceiling, loses the sticks and the device switches to HOLD. It
  cannot take them again until the operator resumes it in dash.
- STOP releases every script and refuses their commands until the operator
  clears it.

## Script hosts

Phones and tablets run scripts on a script host: a computer on the same
network running `koebelt-dash-scripts host`. The host runs the script in its
Python, and the script connects back to dash on the phone, with a token for
that run only. dash on the phone then listens on the network; from there it
accepts only the tokens of runs it started.

**Finding hosts.** dash broadcasts a UDP datagram to port 47922; hosts
answer to the sender:

```json
→ {"t":"hostdiscover"}
← {"t":"host","v":1,"name":"Bench PC","port":47921,"python":"3.12.6","pkg":"1.3.0"}
```

**Talking to a host.** A WebSocket to `ws://<host>:47921/host`, JSON text
messages.

Pairing, once, with the code the host prints (it changes after each use):

```json
→ {"t":"pair","code":"K7Q-2MX","name":"Thomas’s iPhone"}
← {"t":"paired","token":"<32 hex>","name":"Bench PC","port":47921,"python":"3.12.6","pkg":"1.3.0"}
```

A wrong code gets `{"t":"bye","why":"Wrong pairing code."}`. The host keeps
its paired phones in `~/.koebelt/script-host.json`; `koebelt-dash-scripts
host --forget` unpairs them all.

Running a script:

```json
→ {"t":"hello","token":"<pairing token>"}
← {"t":"welcome","name":"Bench PC",…}
→ {"t":"run","name":"follow.py","main":"main.py","files":{"main.py":"<base64>","model/yolo.pt":"<base64>"},"dashPort":47920,"dashToken":"<run token>"}
← {"t":"started","pid":5120,"python":"3.12.6"}
← {"t":"out","level":"out","text":"following on Mule"}
→ {"t":"stop"}
← {"t":"exit","code":0}
```

The host writes the files to a temporary folder, runs `main` there with
`KOEBELT_DASH_URL` set to `ws://<the phone's address>:<dashPort>/scripts`
and `KOEBELT_DASH_TOKEN` to the run token, and deletes the folder when the
script ends. Closing the connection stops the script.

