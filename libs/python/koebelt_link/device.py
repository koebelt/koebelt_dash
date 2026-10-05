"""The Device object: declare a device, stream sensors, receive control."""
from __future__ import annotations

import json
import math
import os
import re
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Callable, Dict, Iterable, List, Optional, Sequence, Tuple, Union

from . import __version__
from .protocol import COMPACT_FIELDS, KINDS, VERSION, Msg, encode_points
from .transports import RadioTransport, SerialTransport, Transport, UdpTransport

#: A radio port: "/dev/ttyUSB1" (SiK) or ("/dev/ttyUSB1", "hc12").
RadioPort = Union[str, Tuple[str, str]]

MODES = ("AUTO", "MANUAL", "HOLD", "TAKEOFF", "LAND", "RTH")


@dataclass
class Vec3:
    x: float = 0.0
    y: float = 0.0
    z: float = 0.0

    def __iter__(self):
        return iter((self.x, self.y, self.z))


@dataclass
class Control:
    """Four normalised axes, −1…1. Sticks, sliders and tilt all map here."""

    lx: float = 0.0
    ly: float = 0.0
    rx: float = 0.0
    ry: float = 0.0
    seq: int = 0

    @property
    def zero(self) -> bool:
        return not (self.lx or self.ly or self.rx or self.ry)


class Param:
    """A tunable value shown on the app's Tune screen."""

    def __init__(self, key: str, default: float, min: float, max: float, step: Optional[float], unit: str, label: Optional[str]):
        self.key = key
        self.value = float(default)
        self.default = float(default)
        self.min = float(min)
        self.max = float(max)
        self.step = float(step) if step else _auto_step(self.min, self.max)
        self.unit = unit
        self.label = label or key
        self._cbs: List[Callable[[float], Any]] = []

    def on_change(self, fn: Callable[[float], Any]) -> Callable[[float], Any]:
        self._cbs.append(fn)
        return fn

    def _set(self, v: float) -> None:
        v = max(self.min, min(self.max, float(v)))
        if v == self.value:
            return
        self.value = v
        for cb in self._cbs:
            cb(v)

    def __float__(self) -> float:
        return self.value

    def __repr__(self) -> str:
        return f"Param({self.key}={self.value}{self.unit})"


def _auto_step(lo: float, hi: float) -> float:
    span = hi - lo
    if span <= 0:
        return 0.01
    return 10 ** math.floor(math.log10(span / 100))


class Channel:
    """A custom telemetry channel with 1–6 axes."""

    def __init__(self, dev: "Device", id: str, axes: Sequence[str], unit: str, hz: float):
        if not 1 <= len(axes) <= 6:
            raise ValueError("a channel has 1 to 6 axes")
        self.dev, self.id, self.axes, self.unit, self.hz = dev, id, list(axes), unit, hz

    def publish(self, *values: float) -> None:
        if len(values) != len(self.axes):
            raise ValueError(f"{self.id} expects {len(self.axes)} values")
        self.dev._tlm[self.id] = [float(v) for v in values]


# Known channels: name -> field order accepted by publish(name, **fields)
_FIELDS = {
    "imu": ("accel", "gyro"),
    "att": ("roll", "pitch", "yaw"),
    "pos": ("x", "y", "z"),
    "vel": ("vx", "vy", "vz"),
    "gps": ("lat", "lon", "alt", "sats"),
    "bat": ("volts", "amps", "percent"),
    "rssi": ("rssi",),
    "joints": ("values",),
    "tool": ("x", "y", "z", "gripper"),
    "ft": ("fx", "fy", "fz"),
    "thrust": ("thrust", "torque"),
    "rpm": ("rpm",),
    "temp": ("temp",),
    "throttle": ("throttle",),
    "rocket": ("max_alt", "phase_time", "countdown"),
}
_ALIASES = {"battery": "bat", "power": "bat", "attitude": "att", "position": "pos", "velocity": "vel", "joint_states": "joints"}


class Device:
    """A koebelt/link device.

    >>> dev = Device("Mule-2", kind="rover")
    >>> dev.connect(wifi=True)
    >>> while True:
    ...     dev.publish("imu", accel=Vec3(0, 0, 9.81), gyro=Vec3())
    ...     dev.tick(hz=50)
    """

    def __init__(self, name: str, kind: str = "generic", *, id: Optional[str] = None, model: str = "", sensors: Optional[Iterable[str]] = None,
                 fw: str = "", state_dir: Optional[str] = None):
        if kind not in KINDS:
            raise ValueError(f"kind must be one of {KINDS}")
        self.name = name
        self.kind = kind
        self.id = id or re.sub(r"[^a-z0-9]+", "-", name.lower()).strip("-")
        self.model = model
        self.sensors = list(sensors or [])
        self.fw = fw
        self.transports: List[Transport] = []
        self._primary: Optional[Transport] = None
        self._active: Optional[Transport] = None

        self.control = Control()
        self.mode = "PAD" if kind == "rocket" else "IDLE" if kind == "bench" else "HOLD"
        self.armed = False
        self.estop = False
        self.speed = 0.5
        self.jog = [0.0] * 6
        self.cart = [0.0, 0.0, 0.0]
        self.ext: Dict[str, Any] = {}
        self.video_streams: List[Dict[str, str]] = []

        self.rate_hz = 30.0
        self.params: Dict[str, Param] = {}
        self.channels: Dict[str, Channel] = {}
        self._tlm: Dict[str, List[float]] = {}
        self._cloud: Optional[List[Sequence[float]]] = None
        self._tracks: Optional[list] = None

        self._fs_timeout = 1.8
        self._fs_action = "HOLD"
        self.failsafe_active = False
        self._last_ctl = 0.0
        self._session = False

        self._pair_code: Optional[str] = None
        self._state_dir = Path(state_dir or os.environ.get("KOEBELT_LINK_HOME", Path.home() / ".config" / "koebelt-link"))
        self.key: Optional[str] = None
        self._load()

        self._cb: Dict[str, List[Callable[..., Any]]] = {}
        self._t_tlm = self._t_state = self._t_announce = self._t_cloud = 0.0
        self._last_tick = time.monotonic()
        self._state_dirty = True

    # ------------------------------------------------------------ connection
    def connect(self, wifi: bool = False, ble: bool = False, serial: Optional[str] = None, *, radio: Optional[RadioPort] = None,
                module: Optional[Tuple[str, int]] = None, port: int = 47800, baud: int = 115200,
                fallback: Optional[Dict[str, Any]] = None) -> "Device":
        """Open transports. The first one is primary; `fallback` takes over when it goes quiet.

        `radio` is a radio modem on a serial port: "/dev/ttyUSB1" for a SiK
        radio, or (path, profile) with profile sik, lora, hc12, xbee or other.
        `module` is a Bluetooth serial module on a UART, (path, baud), e.g.
        ("/dev/serial0", 9600) for an HM-10 or HC-05.
        """
        if wifi:
            self._add(UdpTransport(port))
        if serial:
            self._add(SerialTransport(serial, baud))
        if radio:
            self._add(self._radio(radio))
        if module:
            self._add(SerialTransport(module[0], module[1]).use_module(module[1]))
        if ble:
            from .transports import BleTransport

            self._add(BleTransport(self.name))
        if not self.transports:
            raise ValueError("pick at least one transport: wifi=True, ble=True, serial='/dev/ttyUSB0', radio='/dev/ttyUSB1' or module=('/dev/serial0', 9600)")
        for k, v in (fallback or {}).items():
            if k == "serial":
                self._add(SerialTransport(v, baud))
            elif k == "wifi":
                self._add(UdpTransport(int(v) if v is not True else port))
            elif k == "radio":
                self._add(self._radio(v))
            elif k == "lora":
                # A LoRa UART modem; telemetry only.
                self._add(RadioTransport(v, "lora"))
            else:
                raise ValueError(f"unknown fallback transport {k!r}")
        return self

    @staticmethod
    def _radio(r: RadioPort) -> Transport:
        path, profile = (r, "sik") if isinstance(r, str) else r
        return RadioTransport(path, profile)

    def add_transport(self, t: Transport) -> "Device":
        """Use a custom transport (anything with poll/send)."""
        self._add(t)
        return self

    def _add(self, t: Transport) -> None:
        self.transports.append(t)
        if self._primary is None:
            self._primary = t

    def close(self) -> None:
        for t in self.transports:
            t.close()
        self.transports.clear()

    @property
    def connected(self) -> bool:
        return self._session and self.link_age < 3.0

    @property
    def link_age(self) -> float:
        """Seconds since the last control packet."""
        return time.monotonic() - self._last_ctl if self._last_ctl else math.inf

    # ------------------------------------------------------------ callbacks
    def _on(self, name: str, fn: Callable[..., Any]) -> Callable[..., Any]:
        self._cb.setdefault(name, []).append(fn)
        return fn

    def _emit(self, name: str, *args: Any) -> None:
        for fn in self._cb.get(name, []):
            fn(*args)

    def on_control(self, fn):
        """`fn(c: Control)` on every control packet (20 Hz while the app is open)."""
        return self._on("control", fn)

    def on_mode(self, fn):
        """`fn(mode: str)` when the mode changes (from the app or the failsafe)."""
        return self._on("mode", fn)

    def on_stop(self, fn):
        """`fn()` on emergency stop. Cut the motors here."""
        return self._on("stop", fn)

    def on_reset(self, fn):
        return self._on("reset", fn)

    def on_arm(self, fn):
        """`fn(armed: bool)`."""
        return self._on("arm", fn)

    def on_jog(self, fn):
        """`fn(joints: list[float])` joint jog velocities, −1…1 (arms)."""
        return self._on("jog", fn)

    def on_cart(self, fn):
        """`fn(v: list[float])` Cartesian jog x, y, z, −1…1 (arms)."""
        return self._on("cart", fn)

    def on_command(self, fn):
        """`fn(name: str, args: dict)` for kind-specific commands (countdown, deploy, throttle, home…)."""
        return self._on("cmd", fn)

    def on_params_written(self, fn):
        """`fn()` after the app wrote one or more parameters."""
        return self._on("params_written", fn)

    def on_connect(self, fn):
        return self._on("connect", fn)

    # ------------------------------------------------------------ safety
    def failsafe(self, timeout: float = 1.8, action: str = "hold") -> None:
        """Switch to `action` after `timeout` s without a control packet."""
        a = action.upper()
        if a not in ("HOLD", "RTH", "LAND"):
            raise ValueError("action must be hold, rth or land")
        self._fs_timeout, self._fs_action = float(timeout), a

    def set_mode(self, mode: str) -> None:
        """Report a mode change made by the device itself."""
        if mode != self.mode:
            self.mode = mode
            self._state_dirty = True

    def set_armed(self, armed: bool) -> None:
        if armed != self.armed:
            self.armed = armed
            self._state_dirty = True

    def video(self, url: str, id: str = "cam", fmt: str = "mjpeg", label: Optional[str] = None) -> None:
        """Declare a camera stream the app shows (MJPEG over HTTP). `url` may be
        ":8081/stream" (port and path on this machine's IP) or a full URL.
        See `koebelt_link.video.MjpegServer` to serve one."""
        v = {"id": id, "url": url, "fmt": fmt}
        if label:
            v["label"] = label
        self.video_streams = [x for x in self.video_streams if x["id"] != id] + [v]

    def camera(self, source: Any = 0, *, port: int = 8081, fps: float = 15, width: int = 640, label: Optional[str] = None):
        """Stream a camera (OpenCV source) and declare it. Returns the MjpegServer."""
        from .video import camera

        return camera(self, source, port=port, fps=fps, width=width, label=label)

    def set_state(self, **ext: Any) -> None:
        """Kind-specific state shown in the app, e.g. pyro=["OK","OK","-","-"], cutoff="Current limit"."""
        self.ext.update(ext)
        self._state_dirty = True

    # ------------------------------------------------------------ params
    def param(self, key: str, default: float, min: float = 0.0, max: Optional[float] = None, *, step: Optional[float] = None, unit: str = "",
              label: Optional[str] = None) -> Param:
        if max is None:
            max = default * 4 if default else 1.0
        p = Param(key, default, min, max, step, unit, label)
        saved = self._saved_params.get(key)
        if saved is not None:
            p.value = max_(p.min, min_(p.max, float(saved)))
        self.params[key] = p
        return p

    def save_params(self) -> None:
        """Persist current parameter values (and the pairing key) to disk."""
        self._saved_params = {k: p.value for k, p in self.params.items()}
        self._store()

    # ------------------------------------------------------------ channels
    def channel(self, id: str, axes: Sequence[str] = ("value",), unit: str = "", hz: float = 10) -> Channel:
        c = Channel(self, id, axes, unit, hz)
        self.channels[id] = c
        if self._session:
            self._send(self._chan_msg())
        return c

    # ------------------------------------------------------------ telemetry
    def publish(self, channel: str, *values: Any, **fields: Any) -> None:
        """Publish the latest reading of a channel.

        publish("imu", accel=Vec3(...), gyro=Vec3(...))
        publish("gps", lat=..., lon=..., alt=...)
        publish("lidar", points=nx3)       # point cloud
        publish("tracks", [("T1", range_m, bearing_rad), ...])
        publish("motor_temp", 41.0, 43.5)  # custom channel, positional
        """
        ch = _ALIASES.get(channel, channel)
        if ch in ("lidar", "points", "cloud"):
            pts = fields.get("points", values[0] if values else [])
            self._cloud = [tuple(float(v) for v in p[:3]) for p in pts]
            return
        if ch == "tracks":
            items = fields.get("tracks", values[0] if values else [])
            self._tracks = [[str(i), float(r), float(b)] for i, r, b in items]
            return
        if ch == "imu":
            a = fields.get("accel", values[0] if values else (0, 0, 0))
            g = fields.get("gyro", values[1] if len(values) > 1 else (0, 0, 0))
            self._tlm["imu"] = [float(v) for v in (*a, *g)]
            return
        if ch == "joints":
            v = fields.get("values", values[0] if len(values) == 1 and isinstance(values[0], (list, tuple)) else values)
            self._tlm["joints"] = [float(x) for x in v]
            return
        if ch in _FIELDS and fields:
            order = _FIELDS[ch]
            vals = []
            for k in order:
                if k in fields:
                    x = fields[k]
                    vals.extend(float(v) for v in x) if isinstance(x, (list, tuple, Vec3)) else vals.append(float(x))
                elif k in ("sats", "gripper", "percent", "torque"):
                    continue
                else:
                    raise ValueError(f"{channel} needs {k}")
            self._tlm[ch] = vals
            return
        flat: List[float] = []
        for v in values:
            flat.extend(float(x) for x in v) if isinstance(v, (list, tuple, Vec3)) else flat.append(float(v))
        self._tlm[ch] = flat

    # Shortcuts, same names as the Arduino and Rust libraries
    def _set(self, k: str, *v: Any) -> None:
        self._tlm[k] = [float(x) for x in v]

    def imu(self, ax, ay, az, gx, gy, gz) -> None:
        self._set("imu", ax, ay, az, gx, gy, gz)

    def attitude(self, roll, pitch, yaw) -> None:
        self._set("att", roll, pitch, yaw)

    def position(self, x, y, z) -> None:
        self._set("pos", x, y, z)

    def velocity(self, vx, vy, vz) -> None:
        self._set("vel", vx, vy, vz)

    def gps(self, lat, lon, alt, sats=0) -> None:
        self._set("gps", lat, lon, alt, sats)

    def battery(self, volts, percent, amps=0.0) -> None:
        self._set("bat", volts, amps, percent)

    def rssi(self, dbm) -> None:
        self._set("rssi", dbm)

    def joints(self, rad: Sequence[float]) -> None:
        self._set("joints", *list(rad)[:6])

    def tool(self, x, y, z, gripper=0.0) -> None:
        self._set("tool", x, y, z, gripper)

    def force_torque(self, fx, fy, fz) -> None:
        self._set("ft", fx, fy, fz)

    def thrust(self, newtons, torque=0.0) -> None:
        self._set("thrust", newtons, torque)

    def rpm(self, v) -> None:
        self._set("rpm", v)

    def temperature(self, c) -> None:
        self._set("temp", c)

    def throttle_out(self, v) -> None:
        self._set("throttle", v)

    def rocket_state(self, max_alt, phase_time, countdown=0.0) -> None:
        self._set("rocket", max_alt, phase_time, countdown)

    def points(self, xyz: Sequence[Sequence[float]]) -> None:
        """Point cloud in metres, local frame."""
        self.publish("points", points=xyz)

    def tracks(self, items: Sequence[Tuple[str, float, float]]) -> None:
        """Radar / scanner targets: (id, range m, bearing rad)."""
        self.publish("tracks", items)

    def log(self, msg: str, lvl: str = "info") -> None:
        self._send({"t": "log", "lvl": lvl, "msg": msg})

    # ------------------------------------------------------------ pairing
    def pair(self, code: str) -> None:
        """Enter pairing mode with the code shown in the app. The key is stored and reused."""
        self._pair_code = code.strip().upper()

    def unpair(self) -> None:
        self.key = None
        self._store()

    # ------------------------------------------------------------ loop
    def tick(self, hz: Optional[float] = None) -> None:
        """Process incoming messages and send due telemetry. Call it every loop.
        With `hz`, sleeps so the loop runs at that rate."""
        now = time.monotonic()
        for t in self.transports:
            for m in t.poll():
                self._handle(t, m, now)
        self._check_failsafe(now)
        self._outgoing(now)
        if hz:
            dt = 1.0 / hz - (time.monotonic() - self._last_tick)
            if dt > 0:
                time.sleep(dt)
        self._last_tick = time.monotonic()

    def run(self, hz: float = 50, loop: Optional[Callable[[], Any]] = None) -> None:
        """Blocking loop: calls `loop()` then `tick(hz)` forever."""
        try:
            while True:
                if loop:
                    loop()
                self.tick(hz)
        except KeyboardInterrupt:
            pass
        finally:
            self.close()

    # ------------------------------------------------------------ internals
    def _send(self, m: Msg) -> None:
        t = self._active or self._primary
        if t is not None:
            t.send(m)

    def _hello(self) -> Msg:
        m = {"t": "hello", "v": VERSION, "id": self.id, "name": self.name, "kind": self.kind, "model": self.model, "fw": self.fw,
             "lib": f"python/{__version__}", "sensors": self.sensors, "ok": True}
        if self.video_streams:
            m["video"] = self.video_streams
        return m

    def _announce(self) -> Msg:
        m = {"t": "announce", "v": VERSION, "id": self.id, "name": self.name, "kind": self.kind, "lib": f"python/{__version__}",
             "model": self.model, "sensors": self.sensors}
        if self._pair_code:
            m["pair"] = self._pair_code
        return m

    def _params_msg(self) -> Msg:
        return {"t": "params", "p": [[p.key, p.value, p.min, p.max, p.step, p.unit, p.label] for p in self.params.values()]}

    def _chan_msg(self) -> Msg:
        return {"t": "chan", "ch": [{"id": c.id, "axes": c.axes, "unit": c.unit, "hz": c.hz} for c in self.channels.values()]}

    def _state_msg(self) -> Msg:
        return {"t": "state", "mode": self.mode, "armed": self.armed, "estop": self.estop, "fs": self.failsafe_active, "ext": self.ext}

    def _set_mode(self, m: str) -> None:
        if m != self.mode:
            self.mode = m
            self._state_dirty = True
            self._emit("mode", m)

    def _handle(self, t: Transport, m: Msg, now: float) -> None:
        typ = m["t"]
        if typ == "discover" and isinstance(t, UdpTransport):
            t.reply(self._announce(), m["_from"])
            return
        if typ == "pair":
            if self._pair_code and str(m.get("code", "")).upper() == self._pair_code and m.get("key"):
                self.key = str(m["key"])
                self._pair_code = None
                self._store()
                t.send({"t": "paired", "id": self.id})
            return
        if typ == "hello":
            if self.key and m.get("key") != self.key:
                t.send({"t": "hello", "v": VERSION, "id": self.id, "ok": False, "err": "key"})
                if isinstance(t, UdpTransport):
                    t.drop_peer()
                return
            self._active = t
            self._session = True
            self._last_ctl = now
            t.send(self._hello())
            t.send(self._params_msg())
            if self.channels:
                t.send(self._chan_msg())
            t.send(self._state_msg())
            self._emit("connect")
            return
        if not self._session:
            return
        # Telemetry-only links: nothing that moves the device. A STOP is
        # still worth having, however slowly it arrives.
        if not t.accepts_control and typ not in ("stop", "ping", "rate", "bye"):
            return
        if typ == "ctl":
            self._last_ctl = now
            self._active = t
            if self.failsafe_active:
                self.failsafe_active = False
                self._state_dirty = True
            self.control = Control(float(m.get("lx", 0)), float(m.get("ly", 0)), float(m.get("rx", 0)), float(m.get("ry", 0)), int(m.get("s", 0)))
            if not self.estop:
                self._emit("control", self.control)
        elif typ == "ping":
            t.send({"t": "pong", "ts": m.get("ts")})
        elif typ == "stop":
            if not self.estop:
                self.estop = True
                self.armed = False
                self.control = Control()
                self._state_dirty = True
                self._emit("stop")
                self._emit("arm", False)
        elif typ == "reset":
            if self.estop:
                self.estop = False
                self._state_dirty = True
                self._emit("reset")
        elif typ == "arm":
            if not self.estop:
                v = bool(m.get("v"))
                if v != self.armed:
                    self.armed = v
                    self._state_dirty = True
                    self._emit("arm", v)
        elif typ == "mode":
            if not self.estop and isinstance(m.get("m"), str):
                self._set_mode(m["m"])
        elif typ == "jog":
            self.jog = [float(v) for v in m.get("j", [])][:6]
            if not self.estop:
                self._emit("jog", self.jog)
        elif typ == "cart":
            self.cart = [float(v) for v in m.get("v", [])][:3]
            if not self.estop:
                self._emit("cart", self.cart)
        elif typ == "cmd":
            if not self.estop or m.get("c") in ("abort", "clear", "reset"):
                self._emit("cmd", str(m.get("c")), m.get("a") or {})
        elif typ == "pset":
            keys = []
            for k, v in (m.get("p") or {}).items():
                p = self.params.get(k)
                if p is not None and isinstance(v, (int, float)):
                    p._set(v)
                    keys.append(k)
            t.send({"t": "pack", "ok": True, "keys": keys})
            if keys:
                self._emit("params_written")
        elif typ == "psave":
            self.save_params()
        elif typ == "rate":
            self.rate_hz = max(1.0, min(60.0, float(m.get("hz", 30))))
        elif typ == "speed":
            self.speed = max(0.1, min(1.0, float(m.get("v", 0.5))))
        elif typ == "fs":
            self._fs_action = str(m.get("action", self._fs_action)).upper()
            self._fs_timeout = float(m.get("ms", self._fs_timeout * 1000)) / 1000
        elif typ == "bye":
            self._session = False
            self.control = Control()
            if self.kind == "drone" and self.armed:
                self._set_mode("HOLD")
            if isinstance(t, UdpTransport):
                t.drop_peer()

    def _check_failsafe(self, now: float) -> None:
        if not self._session or self.failsafe_active or self.kind == "rocket":
            return
        if now - self._last_ctl <= self._fs_timeout:
            return
        self.failsafe_active = True
        self.control = Control()
        self._state_dirty = True
        self._emit("control", self.control)
        if self.kind == "drone":
            self._set_mode(self._fs_action)
        elif self.kind == "bench":
            self._set_mode("IDLE")
        elif self.armed:
            self._set_mode("HOLD")
        self._send({"t": "log", "lvl": "warn", "msg": f"Failsafe: no control for {self._fs_timeout:.1f} s"})
        # Fall back to the secondary transport for telemetry.
        others = [t for t in self.transports if t is not self._active]
        if others:
            self._active = others[0]

    def _outgoing(self, now: float) -> None:
        if not self._session:
            if now - self._t_announce >= 1.0:
                self._t_announce = now
                for t in self.transports:
                    t.announce(self._announce())
            return
        link = self._active or self._primary
        low = bool(link and link.low_bandwidth)
        cap = link.max_rate_hz if link else 0.0
        hz = min(self.rate_hz, cap) if cap > 0 else self.rate_hz
        if self._state_dirty or now - self._t_state >= (2.0 if low else 0.5):
            self._t_state = now
            self._state_dirty = False
            self._send(self._state_msg())
        if self._tlm and now - self._t_tlm >= 1.0 / hz:
            self._t_tlm = now
            d = self._tlm
            if 0 < cap <= 2:
                d = {k: v for k, v in d.items() if k in COMPACT_FIELDS}
            if d:
                self._send({"t": "tlm", "ts": int(now * 1000), "d": d})
            self._tlm = {}
        if low:
            # No bulk data over radio.
            self._tracks = self._cloud = None
        if self._tracks is not None:
            self._send({"t": "tracks", "d": self._tracks})
            self._tracks = None
        if self._cloud is not None and now - self._t_cloud >= 0.1:
            self._t_cloud = now
            pts = self._cloud
            self._cloud = None
            for i in range(0, len(pts), 1500):
                n, d = encode_points(pts[i : i + 1500])
                self._send({"t": "pc", "f": "i16cm", "n": n, "d": d})

    # ------------------------------------------------------------ persistence
    @property
    def _file(self) -> Path:
        return self._state_dir / f"{self.id}.json"

    def _load(self) -> None:
        self._saved_params: Dict[str, float] = {}
        try:
            j = json.loads(self._file.read_text())
            self.key = j.get("key")
            self._saved_params = j.get("params", {})
        except (OSError, ValueError):
            pass

    def _store(self) -> None:
        try:
            self._state_dir.mkdir(parents=True, exist_ok=True)
            self._file.write_text(json.dumps({"key": self.key, "params": self._saved_params}, indent=2))
        except OSError:
            pass


min_, max_ = min, max
