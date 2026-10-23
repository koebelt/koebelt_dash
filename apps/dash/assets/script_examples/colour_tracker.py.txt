"""Colour tracker.

Turns a rover towards the largest patch of a colour the camera sees, with
OpenCV, and shows what it tracks over the camera in dash.

    pip install opencv-python numpy
"""
import cv2
import numpy as np

from koebelt_dash_scripts import connect, pid

dev = connect()
hue = dev.setting("hue", 30, min=0, max=179)          # 30: yellow
speed = dev.setting("speed", 0.3, min=0, max=1)
steer = pid(1.5, 0, 0.1)

for frame in dev.camera.frames():
    h, w = frame.shape[:2]
    hsv = cv2.cvtColor(frame, cv2.COLOR_BGR2HSV)
    lo = np.array([max(0, hue.value - 10), 100, 80])
    hi = np.array([min(179, hue.value + 10), 255, 255])
    mask = cv2.inRange(hsv, lo, hi)
    contours, _ = cv2.findContours(mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    if not contours:
        dev.overlay([])
        dev.sticks(throttle=0, steer=0)
        continue
    x, y, bw, bh = cv2.boundingRect(max(contours, key=cv2.contourArea))
    dev.overlay([(x, y, bw, bh, "target")], width=w, height=h)
    offset = (x + bw / 2) / w - 0.5               # −0.5 left … 0.5 right
    dev.sticks(throttle=speed.value, steer=steer.update(offset))
