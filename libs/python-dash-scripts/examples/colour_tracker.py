"""Colour tracker.

Turns a rover towards the largest patch of a colour the camera sees, with
OpenCV. dash shows what it tracks over the camera, the mask it sees in a
Live widget, and the offset it steers by on a chart. It stops when the
patch is close and turns to keep it centred; when it loses it, it turns
the way it went. On a simulated rover it follows the yellow ball that
rolls near home.

    pip install opencv-python numpy
"""
# requires: rover
# requires: camera
import time

import cv2
import numpy as np

from koebelt_dash_scripts import connect, pid

dev = connect()
dev.mode("MANUAL")                               # sticks drive it (AUTO ignores them)
for _ in range(40):                              # its telemetry says so within a moment
    if dev.next_tlm().mode == "MANUAL":
        break
else:
    print(f"warning: {dev.name} stays in {dev.tlm.mode}, not MANUAL: it may ignore the sticks")
print(f"info: tracking a colour with {dev.name}, mode {dev.tlm.mode}")
hue = dev.setting("hue", 30, min=0, max=179)          # 30: yellow
speed = dev.setting("speed", 0.3, min=0, max=1)
steer = pid(1.5, 0, 0.1)
last = 0.0                                       # where it was last seen
seen = False
seen_at = 0.0                                    # when it was last in view
said = 0.0                                       # when the last debug line went out

for frame in dev.camera.frames():
    h, w = frame.shape[:2]
    hsv = cv2.cvtColor(frame, cv2.COLOR_BGR2HSV)
    lo = np.array([max(0, hue.value - 10), 100, 80])
    hi = np.array([min(179, hue.value + 10), 255, 255])
    mask = cv2.inRange(hsv, lo, hi)
    dev.show("mask", mask)                       # a Live widget: what the colour filter keeps
    contours, _ = cv2.findContours(mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    if not contours:
        if time.monotonic() - seen_at < 0.7:
            continue                                 # missed a frame or two: keep going
        if seen:
            print("info: lost it, turning " + ("right" if last >= 0 else "left") + " to look")
            seen = False
        dev.overlay([])
        dev.sticks(throttle=0, steer=0.4 if last >= 0 else -0.4)   # look for it
        if time.monotonic() - said > 1:
            said = time.monotonic()
            print(f"debug: no patch of hue {hue.value:.0f}, mode {dev.tlm.mode}")
        continue
    seen_at = time.monotonic()
    if not seen:
        print("info: found it, following")
        seen = True
    x, y, bw, bh = cv2.boundingRect(max(contours, key=cv2.contourArea))
    dev.overlay([(x, y, bw, bh, "target")], width=w, height=h)
    offset = (x + bw / 2) / w - 0.5               # −0.5 left … 0.5 right
    dev.plot("offset", offset)                    # drawn over time in Live
    last = offset
    near = bh / h > 0.25                          # big in the picture: close
    # Positive steer turns right, as a positive offset is right of centre.
    s, t = steer.update(offset), 0 if near else speed.value
    dev.sticks(throttle=t, steer=s)
    if time.monotonic() - said > 1:
        said = time.monotonic()
        print(f"debug: patch {bw}x{bh} px, offset {offset:+.2f}, steer {s:+.2f}, throttle {t:.2f}{', close: waiting' if near else ''}")
