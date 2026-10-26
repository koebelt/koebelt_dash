"""Follow a person.

A rover follows the person a YOLO model sees on its camera, and shows the
detections over the camera in dash. It stops when they are close and turns
to keep them centred; when it loses them, it turns the way they went. Runs
on a GPU when there is one.

The console says what it does: info lines when it finds or loses someone,
a debug line each second (what it sees and how it steers), warnings when
something is off.

    pip install ultralytics
"""
# requires: rover
# requires: camera
import time

from ultralytics import YOLO

from koebelt_dash_scripts import connect, pid

print("info: loading the YOLO model (the first time, it downloads it)")
model = YOLO("yolov8n.pt")
dev = connect()
dev.mode("MANUAL")                               # sticks drive it (AUTO ignores them)
for _ in range(40):                              # its telemetry says so within a moment
    if dev.next_tlm().mode == "MANUAL":
        break
else:
    print(f"warning: {dev.name} stays in {dev.tlm.mode}, not MANUAL: it may ignore the sticks")
print(f"info: following people with {dev.name}, mode {dev.tlm.mode}")
speed = dev.setting("speed", 0.4, min=0, max=1)
steer = pid(1.2, 0, 0.1)
last = 0.0                                       # where they were last seen
seen = False
seen_at = 0.0                                    # when they were last in view
said = 0.0                                       # when the last debug line went out

for frame in dev.camera.frames():
    result = model(frame, verbose=False)[0]
    dev.overlay(result)
    people = [b for b in result.boxes if int(b.cls) == 0]
    if not people:
        if time.monotonic() - seen_at < 0.7:
            continue                                 # missed a frame or two: keep going
        if seen:
            print("info: lost them, turning " + ("right" if last >= 0 else "left") + " to look")
            seen = False
        turn = 0.4 if last >= 0 else -0.4
        dev.sticks(throttle=0, steer=turn)          # look for them
        if time.monotonic() - said > 1:
            said = time.monotonic()
            print(f"debug: nobody in view, steer {turn:+.2f}, mode {dev.tlm.mode}")
        continue
    seen_at = time.monotonic()
    if not seen:
        print(f"info: found {len(people)} {'person' if len(people) == 1 else 'people'}, following")
        seen = True
    biggest = max(people, key=lambda b: float(b.xywhn[0][2] * b.xywhn[0][3]))
    x = float(biggest.xywhn[0][0]) - 0.5         # −0.5 left … 0.5 right
    near = float(biggest.xywhn[0][3]) > 0.6      # tall in the picture: close
    last = x
    # Steer towards them: positive steer turns right, as x is right of centre.
    s, t = steer.update(x), 0 if near else speed.value
    dev.sticks(throttle=t, steer=s)
    if time.monotonic() - said > 1:
        said = time.monotonic()
        print(f"debug: {len(people)} in view, x {x:+.2f}, steer {s:+.2f}, throttle {t:.2f}{', close: waiting' if near else ''}, mode {dev.tlm.mode}")
