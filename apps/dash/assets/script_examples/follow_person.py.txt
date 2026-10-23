"""Follow a person.

A rover follows the person a YOLO model sees on its camera, and shows the
detections over the camera in dash. Runs on a GPU when there is one.

    pip install ultralytics
"""
from ultralytics import YOLO

from koebelt_dash_scripts import connect, pid

model = YOLO("yolov8n.pt")
dev = connect()
speed = dev.setting("speed", 0.4, min=0, max=1)
steer = pid(1.2, 0, 0.1)

for frame in dev.camera.frames():
    result = model(frame, verbose=False)[0]
    dev.overlay(result)
    people = [b for b in result.boxes if int(b.cls) == 0]
    if not people:
        dev.sticks(throttle=0, steer=0)
        continue
    biggest = max(people, key=lambda b: float(b.xywhn[0][2] * b.xywhn[0][3]))
    x = float(biggest.xywhn[0][0]) - 0.5         # −0.5 left … 0.5 right
    near = float(biggest.xywhn[0][3]) > 0.6      # tall in the picture: close
    dev.sticks(throttle=0 if near else speed.value, steer=steer.update(-x))
