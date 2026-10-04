"""Runs a Python example from the app's guides against the real library.

Used by apps/dash/test/guides_snippets_test.dart:
    python tests/run_guide_example.py example.py

Transports are replaced by UDP on a random local port, run() ticks a few
times, and every registered callback is called with realistic arguments, so
a misspelled method, field or argument fails here instead of in the guide.
Cameras are a stand-in OpenCV module, and MJPEG servers bind a free port.
"""
import os
import runpy
import sys
import tempfile
import types

import koebelt_link.device as D
import koebelt_link.video as V
from koebelt_link import Control
from koebelt_link.protocol import RADIO_PROFILES

os.environ.setdefault("KOEBELT_LINK_HOME", tempfile.mkdtemp())
devices = []
_init = D.Device.__init__


def init(self, *a, **k):
    _init(self, *a, **k)
    devices.append(self)


def connect(self, wifi=False, ble=False, serial=None, *, radio=None, port=47800, baud=115200, fallback=None):
    assert wifi or ble or serial or radio, "connect() needs a transport"
    for r in [radio, (fallback or {}).get("radio")]:
        assert r is None or isinstance(r, str) or r[1] in RADIO_PROFILES, f"unknown radio {r}"
    for k in fallback or {}:
        assert k in ("serial", "wifi", "radio", "lora"), f"unknown fallback {k}"
    return D.Device.connect.__wrapped__(self, wifi=True, port=0)


connect.__wrapped__ = D.Device.connect

ARGS = {"x": 1.0, "y": 2.0, "z": 5.0, "alt": 5.0, "j": [0.0] * 6, "v": 0.5, "s": 3, "ch": 0, "kind": "RAMP"}
COMMANDS = ["goto", "takeoff", "pose", "home", "sethome", "gripper", "throttle", "seq", "clear",
            "countdown", "abort", "deploy", "reset", "vent", "lights"]


def exercise(dev):
    for name, cbs in dev._cb.items():
        for cb in cbs:
            if name == "control":
                cb(Control(0.1, 0.2, 0.3, 0.4))
            elif name == "mode":
                cb("HOLD")
            elif name == "arm":
                cb(True)
            elif name == "jog":
                cb([0.5, 0, 0, 0, 0, 0])
            elif name == "cart":
                cb([0.5, 0, 0])
            elif name == "cmd":
                for c in COMMANDS:
                    cb(c, dict(ARGS))
            else:
                cb()
    for p in dev.params.values():
        for cb in p._cbs:
            cb(p.value)


def run(self, hz=50, loop=None):
    for i in range(5):
        if i == 2:
            exercise(self)
        if loop:
            loop()
        self.tick()
    self.close()


# A stand-in for OpenCV: a camera that returns frames and encodes them.
class _Buf(bytes):
    def tobytes(self):
        return bytes(self)


class _Capture:
    def __init__(self, source):
        self.source = source

    def set(self, *a):
        return True

    def read(self):
        return True, object()

    def release(self):
        pass


cv2 = types.ModuleType("cv2")
cv2.VideoCapture = _Capture
cv2.CAP_PROP_FRAME_WIDTH = 3
cv2.IMWRITE_JPEG_QUALITY = 1
cv2.imencode = lambda ext, frame, params=None: (True, _Buf(b"\xff\xd8frame\xff\xd9"))
sys.modules.setdefault("cv2", cv2)

_mjpeg_init = V.MjpegServer.__init__
V.MjpegServer.__init__ = lambda self, port=8081, *a, **k: _mjpeg_init(self, 0, *a, **k)

D.Device.__init__ = init
D.Device.connect = connect
D.Device.run = run
runpy.run_path(sys.argv[1], run_name="__main__")
assert devices, "the example never created a Device"
print("ok")
