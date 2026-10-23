# koebelt-dash-scripts errors

Every error from the library, or from koebelt dash refusing a request, has a code.
When a script does not catch one, it prints like this, pointing at the line of
your script that caused it:

```
error[E0301]: arming and take-off are not allowed for this script
  --> follow_me.py:14
   |
14 |     dev.arm()
   |     ^^^^^^^^^
   |
   = why: the script's limits in koebelt dash do not allow arming or take-off
   = help: in dash, open the script, then Limits > Allow arming and take-off; or arm the device yourself first
   = docs: https://github.com/koebelt/koebelt_dash/blob/main/libs/python-dash-scripts/ERRORS.md#e0301
```

In code, catch them as `ScriptError` (`e.code`, `e.title`, `e.why`, `e.help`); `Released` (E0102) is a
subclass, and so is `TelemetryFieldError` (E0501, also an `AttributeError`). Set `KOEBELT_DASH_TRACEBACK=1`
for the full Python traceback, `NO_COLOR=1` to turn colours off.

# Connecting

## E0001

**no device is connected in koebelt dash**

```python
dev = connect()            # with no device connected in dash
```

Why: connect() uses the device selected in dash, and none is connected.

Fix: connect a device in dash (Devices), or a simulated one (Devices > Pair > Simulated).

## E0002

**no connected device called “<name>”**

```python
dev = connect("Mul")       # the device is called Mule
```

Why: connect("<name>") looks for a connected device by name or id.

Fix: connected now: <the ones it has>.

## E0003

**this script has no device yet**

```python
dev.sticks(throttle=0.3)   # on a Device not made by connect()
```

Why: commands need a device, and connect() did not get one.

Fix: use the Device returned by connect().

## E0010

**koebelt dash is not running on this computer**

```python
dev = connect()            # dash is not open on this computer
```

Why: connect() looks for ~/.koebelt/dash-api.json, which dash writes when it starts.

Fix: open koebelt dash, or run the script from it (Scripts); on another computer, set KOEBELT_DASH_URL and KOEBELT_DASH_TOKEN.

## E0011

**cannot reach koebelt dash at <url>**

```python
dev = connect(url="ws://192.168.1.20:47920/scripts", token="…")
```

Why: <reason>.

Fix: check that dash is open; a script host needs the phone or computer running dash on the same network.

## E0012

**koebelt dash refused the connection**

```python
dev = connect(token="old")
```

Why: <reason>.

Fix: run the script from dash, or restart dash so that ~/.koebelt/dash-api.json is up to date.

## E0013

**the connection to koebelt dash closed**

```python
dev.sticks(throttle=0.3)   # after dash was closed
```

Why: dash was closed, or the script was stopped from it.

Fix: start the script again once dash is open.

## E0014

**koebelt dash did not answer “<request>” within <timeout> s**

```python
dev.mode("HOLD")           # dash does not answer
```

Why: dash is busy or stuck, or the network to it dropped.

Fix: try again; if it keeps happening, restart dash.

# Safety: the operator decides

## E0101

**STOP is on**

```python
dev.sticks(throttle=0.3)   # after STOP
```

Why: the operator pressed STOP, and dash refuses commands until they clear it.

Fix: clear STOP in dash, then run the script again; a script can react with @dev.on_stop.

## E0102

**this script lost the sticks: <why>**

```python
dev.sticks(throttle=0.3)   # after the watchdog or the geofence took the sticks
```

Why: dash took the sticks away for safety, and the script may not take them back by itself.

Fix: in dash, press Resume on the script (or on Control); handle it in the script with @dev.on_stop.

## E0103

**<other> already drives <device>**

```python
dev.sticks(throttle=0.3)   # another script drives this device
```

Why: one script at a time drives a device's sticks.

Fix: stop <other> in dash, or connect this script to another device.

# Driving

## E0201

**“<name>” is not a stick of a <kind>**

```python
dev.sticks(pitch=0.5)      # on a rover: throttle, steer
```

Why: sticks are named for the kind of device.

Fix: a <kind> has: <the ones it has>.

## E0202

**sticks() takes named axes**

```python
dev.sticks(0.5, 0.2)       # write dev.sticks(throttle=0.5, steer=0.2)
```

Why: each axis has a name, so a value cannot go to the wrong one.

Fix: dev.sticks(throttle=0.5, steer=-0.2); a drone has throttle, yaw, pitch, roll.

# Limits set in dash

## E0301

**arming and take-off are not allowed for this script**

```python
dev.arm()
```

Why: the script's limits in koebelt dash do not allow arming or take-off.

Fix: in dash, open the script, then Limits > Allow arming and take-off; or arm the device yourself first.

## E0302

**parameter writes are not allowed for this script**

```python
dev.params.set(MAX_TILT=40)
```

Why: the script's limits in koebelt dash do not allow writing parameters.

Fix: in dash, open the script, then Limits > Allow parameter writes.

## E0303

**that point is <distance> m from home, beyond the <fence> m geofence**

```python
dev.goto(200, 0)           # with a 50 m geofence
```

Why: the script's geofence keeps it within <fence> m of home.

Fix: aim closer to home, or raise the geofence in dash (the script's Limits).

## E0304

**<height> m is above the <ceiling> m ceiling**

```python
dev.takeoff(60)            # with a 30 m ceiling
```

Why: the script's ceiling keeps drones below <ceiling> m.

Fix: fly lower, or raise the ceiling in dash (the script's Limits).

# Steps and programs

## E0401

**a <kind> has no “<name>” step**

```python
dev.takeoff(5)             # on a rover
```

Why: Program steps depend on the kind of device.

Fix: a <kind> has: <the ones it has>.

## E0402

**no program called “<name>” on <device>**

```python
dev.run_program("Survey")  # it is called "Survey square"
```

Why: run_program() runs a sequence from dash's Program screen, by name.

Fix: programs on <device>: <the ones it has>.

## E0403

**“<running>” is already running**

```python
dev.goto(5, 0)             # while a program runs
```

Why: a device runs one sequence at a time.

Fix: wait for it, or dev.stop_program() first.

## E0404

**the device cannot run it now**

```python
dev.land()                 # while dash replays a recording
```

Why: it is stopped, disconnected, or replaying a recording in dash.

Fix: check the device in dash.

## E0405

**the step did not finish: <message>**

```python
dev.goto(30, 0)            # the operator took the sticks on the way
```

Why: the device, the operator or a safety check ended it.

Fix: look at what the device is doing in dash; the operator taking the sticks ends a step.

## E0406

**no program is running**

```python
dev.pause_program()        # nothing runs
```

Why: pause_program(), resume_program() and stop_program() act on a running one.

Fix: start one with dev.run_program("…").

# Reading telemetry

## E0501

**this device sends no “<name>”**

```python
dev.tlm.lidar              # the device sends no lidar field
```

Why: telemetry has the fields the device sends.

Fix: it sends: <the ones it has>.

## E0502

**no telemetry from the device yet**

```python
dev.tlm                    # right after connect(), before any telemetry
```

Why: the device has not sent any since the script connected.

Fix: check that it is connected and its link is up in dash.

# The camera

## E0601

**<device> has no camera**

```python
dev.camera.frame()         # the device has no camera
```

Why: the device declares no video stream.

Fix: add one in the firmware: video() in the koebelt/link library (see the Live video guide).

## E0602

**no picture from camera <camera> within <timeout> s**

```python
dev.camera.frame()         # the stream sends nothing
```

Why: <reason>.

Fix: check the camera in dash (Live > CAM); a camera reached by IP needs this computer on the same network.

## E0603

**camera frames need numpy and OpenCV or Pillow**

```python
dev.camera.frame()         # without opencv-python or pillow
```

Why: frames are decoded into numpy images.

Fix: pip install opencv-python   (or: pip install pillow numpy).

# Settings, triggers and loops

## E0701

**setting “<name>”: <reason>**

```python
dev.setting("speed", 0.4, min=1, max=0)
```

Why: settings become sliders (numbers) or switches (True/False) in dash.

Fix: dev.setting("speed", 0.4, min=0, max=1) or dev.setting("patrol", False).

## E0702

**trigger “<name>”: unknown kind “<kind>”**

```python
@dev.trigger("Go", kind="lever")
```

Why: a trigger is a button, a switch or a value.

Fix: kind="button", kind="switch" or kind="value".

## E0703

**every() needs a period above 0 s, not <seconds>**

```python
for _ in every(0):
```

Why: it is the time between two turns of the loop.

Fix: for _ in every(0.05):   # 20 times a second.

# Anything else

## E0900

**koebelt dash refused: <message>**

```python
…
```

Fix: if it looks like a bug, report it with the script on GitHub.

## E0901

**koebelt dash does not know “<message>”**

```python
…                          # a library newer or older than dash
```

Why: this library and dash disagree on the messages.

Fix: update koebelt dash and koebelt-dash-scripts to matching versions.

# Warnings

## W0201

**<name>=<value> is outside −1…1: dash uses <clamped>**

```python
dev.sticks(throttle=1.7)
```

Why: sticks go from −1 to 1.

Fix: clamp it yourself (koebelt_dash_scripts.clamp) to silence this.
