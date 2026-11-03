"""Runs a MicroPython example from the app's guides against koebelt_link.py.

Used by apps/dash/test/guides_snippets_test.dart:
    python tests/run_guide_example.py example.py

`machine` and `network` are stand-ins for the board's modules, links become
UDP on a random local port, run() ticks a few times, and every registered
callback is called with realistic arguments, so a misspelled method, field or
argument fails here instead of in the guide.
"""
import os
import runpy
import sys
import tempfile
import types

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
import koebelt_link as kl  # noqa: E402


class _Any:
    """A pin, a PWM output, a UART, an I2C bus, an ADC: accepts what they accept."""

    def __init__(self, *a, **k):
        self.v = 0

    def __call__(self, *a, **k):
        return self.v

    def __getattr__(self, name):
        return lambda *a, **k: 0

    def duty_u16(self, v=None):
        return 0 if v is None else None

    def read_u16(self):
        return 32768

    def any(self):
        return 0

    def read(self, n=None):
        return None

    def write(self, b):
        return len(b)


machine = types.ModuleType("machine")
for name in ("Pin", "PWM", "UART", "I2C", "SPI", "ADC", "Timer"):
    setattr(machine, name, type(name, (_Any,), {"OUT": 1, "IN": 0, "PULL_UP": 2}))
sys.modules["machine"] = machine

network = types.ModuleType("network")
network.STA_IF = 0


class _Wlan(_Any):
    def isconnected(self):
        return True

    def ifconfig(self):
        return ("192.168.1.50", "255.255.255.0", "192.168.1.1", "1.1.1.1")


network.WLAN = _Wlan
sys.modules["network"] = network

devices = []
_init = kl.Device.__init__
_connect = kl.Device.connect
state_dir = tempfile.mkdtemp()


def init(self, *a, **k):
    k.setdefault("state_file", os.path.join(state_dir, "%d.json" % len(devices)))
    _init(self, *a, **k)
    devices.append(self)


def connect(self, wifi=False, usb=False, serial=None, radio=None, module=None, port=47800, fallback=None):
    assert wifi or usb or serial is not None or radio is not None or module is not None, "connect() needs a link"
    for r in [radio, (fallback or {}).get("radio")]:
        assert r is None or not isinstance(r, tuple) or r[1] in kl.RADIO_PROFILES, "unknown radio %r" % (r,)
    return _connect(self, wifi=True, port=0)


ARGS = {"x": 1.0, "y": 2.0, "z": 5.0, "alt": 5.0, "j": [0.0] * 6, "v": 0.5, "s": 3, "ch": 0}
COMMANDS = ["goto", "takeoff", "pose", "home", "sethome", "gripper", "throttle", "clear", "countdown", "abort", "deploy", "reset"]


def exercise(dev):
    for name, cbs in dev._cb.items():
        for cb in cbs:
            if name == "control":
                cb(kl.Control(0.1, 0.2, 0.3, 0.4))
            elif name == "mode":
                cb("HOLD")
            elif name == "arm":
                cb(True)
            elif name in ("jog", "cart"):
                cb([0.5, 0, 0, 0, 0, 0][: 6 if name == "jog" else 3])
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
            self.armed = True
            exercise(self)
        if loop:
            loop()
        self.tick()
    self.close()


kl.Device.__init__ = init
kl.Device.connect = connect
kl.Device.run = run
runpy.run_path(sys.argv[1], run_name="__main__")
assert devices, "the example never created a Device"
print("ok")
