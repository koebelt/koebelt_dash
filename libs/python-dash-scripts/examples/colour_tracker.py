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
import cv2
import numpy as np

from koebelt_dash_scripts import connect, pid

dev = connect()
dev.mode("MANUAL")                               # sticks drive it (AUTO ignores them)
hue = dev.setting("hue", 30, min=0, max=179)          # 30: yellow
speed = dev.setting("speed", 0.3, min=0, max=1)
steer = pid(1.5, 0, 0.1)
last = 0.0                                       # where it was last seen

for frame in dev.camera.frames():
    h, w = frame.shape[:2]
    hsv = cv2.cvtColor(frame, cv2.COLOR_BGR2HSV)
    lo = np.array([max(0, hue.value - 10), 100, 80])
    hi = np.array([min(179, hue.value + 10), 255, 255])
    mask = cv2.inRange(hsv, lo, hi)
    dev.show("mask", mask)                       # a Live widget: what the colour filter keeps
    contours, _ = cv2.findContours(mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    if not contours:
        dev.overlay([])
        dev.sticks(throttle=0, steer=0.4 if last >= 0 else -0.4)   # look for it
        continue
    x, y, bw, bh = cv2.boundingRect(max(contours, key=cv2.contourArea))
    dev.overlay([(x, y, bw, bh, "target")], width=w, height=h)
    offset = (x + bw / 2) / w - 0.5               # −0.5 left … 0.5 right
    dev.plot("offset", offset)                    # drawn over time in Live
    last = offset
    near = bh / h > 0.25                          # big in the picture: close
    # Positive steer turns right, as a positive offset is right of centre.
    dev.sticks(throttle=0 if near else speed.value, steer=steer.update(offset))
