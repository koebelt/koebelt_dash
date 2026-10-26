"""The connection to koebelt/dash: a device a script reads and drives.

The messages are in protocol/SCRIPTS.md. A background thread receives
telemetry and events; handlers (triggers, settings, takeover) run on a second
thread, so a slow handler never delays telemetry, and a slow main loop (a
model taking 200 ms per frame) never trips dash's watchdog: keep-alives go
out from their own thread every 100 ms.
"""
from __future__ import annotations

import base64
import itertools
import json
import os
import pathlib
import queue
import sys
import threading
import time
from typing import Any, Callable, Dict, Iterator, List, Optional

from websockets.exceptions import ConnectionClosed
from websockets.sync.client import connect as ws_connect

from .camera import Camera, boxes_of
from .errors import Released, ScriptError, TelemetryFieldError, report, warn_once
from .visuals import chart_message, encode_image

API_VERSION = 1
DISCOVERY = pathlib.Path.home() / ".koebelt" / "dash-api.json"


class Telemetry:
    """The device's latest telemetry. Attributes are the fields dash sends
    (``pos``, ``vel``, ``roll``, ``mode``, ``armed``, ``battery``…, see
    protocol/SCRIPTS.md), plus ``alt``, ``gps`` and ``age``."""

    def __init__(self, data: Dict[str, Any], at: float):
        self.raw = data
        self._at = at

    @property
    def age(self) -> float:
        """Seconds since this telemetry arrived."""
        return time.monotonic() - self._at

    @property
    def alt(self) -> float:
        """Height above home, metres."""
        return float(self.raw.get("pos", [0, 0, 0])[2])

    @property
    def gps(self):
        """(lat, lon, alt) when the device has a GPS fix, else None."""
        if "lat" not in self.raw:
            return None
        return (self.raw["lat"], self.raw["lon"], self.raw.get("galt", 0.0))

    def __getattr__(self, name: str):
        if name.startswith("__"):
            raise AttributeError(name)
        try:
            return self.raw[name]
        except KeyError:
            raise TelemetryFieldError("E0501", {"name": name, "names": sorted([*self.raw, "alt", "gps", "age"])}) from None

    def __repr__(self):
        keys = ("mode", "armed", "pos", "speed", "battery")
        return "Telemetry(" + ", ".join(f"{k}={self.raw[k]!r}" for k in keys if k in self.raw) + ")"


class Setting:
    """A value the operator can change in dash while the script runs."""

    def __init__(self, name: str, value: Any):
        self.name = name
        self.value = value

    def __repr__(self):
        return f"Setting({self.name!r}, {self.value!r})"


class _Store(dict):
    """A dictionary saved to disk on every change, kept between runs."""

    def __init__(self, path: pathlib.Path):
        self._path = path
        try:
            super().__init__(json.loads(path.read_text()))
        except (OSError, ValueError):
            super().__init__()

    def _save(self):
        try:
            self._path.parent.mkdir(parents=True, exist_ok=True)
            self._path.write_text(json.dumps(self, indent=1))
        except OSError:
            pass

    def __setitem__(self, k, v):
        super().__setitem__(k, v)
        self._save()

    def __delitem__(self, k):
        super().__delitem__(k)
        self._save()

    def update(self, *a, **kw):
        super().update(*a, **kw)
        self._save()


class Params:
    """The device's parameters: ``dev.params["MAX_TILT"]``. Writing needs the
    operator's leave (Limits in dash)."""

    def __init__(self, dev: "Device"):
        self._dev = dev

    def all(self) -> Dict[str, float]:
        return dict(self._dev._call("cmd", c="params") or {})

    def __getitem__(self, key: str) -> float:
        values = self.all()
        if key not in values:
            raise KeyError(f"{key} (the device has: {', '.join(sorted(values))})")
        return values[key]

    def set(self, **values: float) -> None:
        self._dev._call("cmd", c="pset", a=values)

    def save(self) -> None:
        self._dev._call("cmd", c="psave")


def _find_dash(url: Optional[str], token: Optional[str]):
    url = url or os.environ.get("KOEBELT_DASH_URL")
    token = token or os.environ.get("KOEBELT_DASH_TOKEN")
    if url and token:
        return url, token
    try:
        found = json.loads(DISCOVERY.read_text())
    except (OSError, ValueError):
        raise ScriptError("E0010") from None
    return url or found["url"], token or found["token"]


class Device:
    """A device connected in koebelt dash, as a script sees it. Get one with
    :func:`connect`."""

    def __init__(self, ws, welcome: Dict[str, Any], name: str):
        self._ws = ws
        self._name = name
        self._send_lock = threading.Lock()
        self._ids = itertools.count(1)
        self._waiting: Dict[int, "queue.Queue[Dict[str, Any]]"] = {}
        self._tlm: Optional[Telemetry] = None
        self._tlm_ready = threading.Condition()
        self._events: "queue.Queue[tuple]" = queue.Queue()
        self._settings: Dict[str, Setting] = {}
        self._triggers: Dict[str, Callable] = {}
        self._any_trigger: List[Callable] = []
        self._on_stop: List[Callable] = []
        self._on_takeover: List[Callable] = []
        self._closed = threading.Event()
        self._store: Optional[_Store] = None
        self._shown: Dict[str, float] = {}
        self.hz: Optional[float] = None
        self.released: Optional[str] = None
        """Why dash took the sticks away, until the operator resumes the script."""
        self.taken_over = False
        """True while the operator holds the sticks."""
        self.app = welcome.get("app")
        self.devices = welcome.get("devices", [])
        self.params = Params(self)
        self.info: Dict[str, Any] = {}
        self.cameras: List[Camera] = []
        for target in (self._receive, self._dispatch, self._keepalive):
            threading.Thread(target=target, daemon=True, name=f"koebelt-dash-{target.__name__}").start()

    # ------------------------------------------------------------------ plumbing
    def _send(self, msg: Dict[str, Any]) -> None:
        with self._send_lock:
            self._ws.send(json.dumps(msg))

    def _call(self, t: str, timeout: float = 5, **fields) -> Any:
        if self._closed.is_set():
            raise ScriptError("E0013")
        i = next(self._ids)
        box: "queue.Queue[Dict[str, Any]]" = queue.Queue(1)
        self._waiting[i] = box
        try:
            self._send({"t": t, "id": i, **fields})
            try:
                res = box.get(timeout=timeout)
            except queue.Empty:
                raise ScriptError("E0014", {"request": t, "timeout": timeout}) from None
        finally:
            self._waiting.pop(i, None)
        if res.get("closed"):
            raise ScriptError("E0013")
        if not res.get("ok"):
            code = res.get("code") or "E0900"
            data = {**(res.get("data") or {}), "message": res.get("err") or "refused"}
            raise (Released if code == "E0102" else ScriptError)(code, data, res.get("err"))
        return res.get("value")

    def _receive(self) -> None:
        try:
            for raw in self._ws:
                m = json.loads(raw)
                t = m.get("t")
                if t == "res":
                    box = self._waiting.get(m.get("id"))
                    if box is not None:
                        box.put(m)
                elif t == "tlm":
                    with self._tlm_ready:
                        self._tlm = Telemetry(m["d"], time.monotonic())
                        self._tlm_ready.notify_all()
                elif t == "setting":
                    s = self._settings.get(m["name"])
                    if s is not None:
                        s.value = m["value"]
                elif t == "fire":
                    self._events.put(("fire", m["name"], m.get("value")))
                elif t == "takeover":
                    self.taken_over = bool(m.get("on"))
                    self._events.put(("takeover", self.taken_over))
                elif t == "released":
                    self.released = m.get("why") or "released"
                    print(f"koebelt dash: {self.released}", file=sys.stderr)
                    self._events.put(("stop", self.released))
                elif t == "resumed":
                    self.released = None
                elif t == "stop":
                    self._events.put(("stop", "STOP"))
        except ConnectionClosed:
            pass
        finally:
            self._closed.set()
            for box in list(self._waiting.values()):
                box.put({"ok": False, "closed": True})
            self._events.put(("closed",))

    def _dispatch(self) -> None:
        while True:
            ev = self._events.get()
            kind = ev[0]
            if kind == "closed":
                return
            handlers: List[Callable] = []
            args: tuple = ()
            if kind == "fire":
                _, name, value = ev
                h = self._triggers.get(name)
                if h is not None:
                    handlers, args = [h], (() if value is None else (value,))
                elif self._any_trigger:
                    handlers, args = self._any_trigger, (name, value)
                else:
                    print(f"koebelt dash: trigger '{name}' has no handler (add @dev.on_trigger)", file=sys.stderr)
            elif kind == "takeover":
                handlers, args = self._on_takeover, (ev[1],)
            elif kind == "stop":
                handlers, args = self._on_stop, ()
            for h in handlers:
                try:
                    h(*args)
                except Exception as e:
                    report(e)

    def _keepalive(self) -> None:
        while not self._closed.wait(0.1):
            try:
                self._send({"t": "ka", **({"hz": round(self.hz, 2)} if self.hz else {})})
            except Exception:
                return

    def _use(self, device: Optional[str], requires: Optional[List[str]] = None) -> None:
        self.info = self._call("use", device=device, **({"requires": list(requires)} if requires else {}))
        self.cameras = [Camera(c) for c in self.info.get("cameras", [])]
        with self._tlm_ready:
            self._tlm_ready.wait_for(lambda: self._tlm is not None, timeout=3)

    # ------------------------------------------------------------------ reading
    @property
    def name(self) -> str:
        return self.info.get("name", "")

    @property
    def kind(self) -> str:
        """drone, rover, arm, bench, rocket or generic."""
        return self.info.get("kind", "generic")

    @property
    def simulated(self) -> bool:
        return bool(self.info.get("sim"))

    @property
    def tlm(self) -> Telemetry:
        """The latest telemetry (20 Hz)."""
        if self._tlm is None:
            raise ScriptError("E0502")
        return self._tlm

    def next_tlm(self, timeout: float = 1.0) -> Telemetry:
        """Waits for the next telemetry message and returns it."""
        with self._tlm_ready:
            before = self._tlm
            if not self._tlm_ready.wait_for(lambda: self._tlm is not before, timeout=timeout):
                raise ScriptError("E0502")
            return self._tlm  # type: ignore[return-value]

    # ------------------------------------------------------------------ acting
    def sticks(self, *values: float, **axes: float) -> None:
        """Sets the sticks, −1…1, until changed. Drones: ``throttle``, ``yaw``,
        ``pitch``, ``roll``; rovers: ``throttle``, ``steer``; any device:
        ``lx``, ``ly``, ``rx``, ``ry``. dash scales them to the script's speed
        limit, and the operator's sticks win."""
        if values:
            raise ScriptError("E0202")
        for k, v in list(axes.items()):
            if not -1 <= v <= 1:
                axes[k] = max(-1.0, min(1.0, float(v)))
                warn_once("W0201", k, {"name": k, "value": round(float(v), 3), "clamped": axes[k]})
        self._call("sticks", a=axes)

    def release(self) -> None:
        """Hands the sticks back; the device holds."""
        self._call("release")

    def mode(self, mode: str) -> None:
        """Switches the device's mode: HOLD, or on drones TAKEOFF, LAND, RTH.
        dash chooses MANUAL and AUTO itself (AUTO while a script or a sequence
        drives the device, MANUAL when the operator does): asking for them
        does nothing."""
        self._call("cmd", c="mode", a={"m": mode})

    def arm(self) -> None:
        """Needs the operator's leave (Limits in dash)."""
        self._call("cmd", c="arm")

    def disarm(self) -> None:
        self._call("cmd", c="disarm")

    def speed_limit(self, v: float) -> None:
        """The device's speed limit, 0.1–1, capped by the script's."""
        self._call("cmd", c="speed", a={"v": v})

    def cmd(self, name: str, **args: Any) -> None:
        """A command of this kind of device: ``dev.cmd("release")``, ``dev.cmd("countdown", s=10)``…"""
        self._call("cmd", c=name, a=args)

    def stop(self) -> None:
        """STOP: every device, at once, as the STOP button."""
        self._call("cmd", c="stop")

    # ------------------------------------------------------------------ steps
    def _step(self, step: str, wait: bool, **args: Any) -> None:
        self._call("cmd", timeout=3600 if wait else 5, c="step", a={"type": step, "wait": wait, **args})

    def takeoff(self, alt: float = 6, *, wait: bool = True) -> None:
        """Drones: arms and climbs to ``alt`` metres (needs leave in Limits). Returns once there."""
        self._step("takeoff", wait, alt=alt)

    def goto(self, x: float, y: float, z: Optional[float] = None, *, wait: bool = True) -> None:
        """Goes to x metres east, y north of home (and z up, drones). Returns once there."""
        self._step("goto", wait, x=x, y=y, **({} if z is None else {"z": z}))

    def land(self, *, wait: bool = True) -> None:
        self._step("land", wait)

    def rth(self, *, wait: bool = True) -> None:
        """Drones: returns home and lands."""
        self._step("rth", wait)

    def pose(self, *joints: float, wait: bool = True) -> None:
        """Arms: moves to joint angles, degrees (J1, J2…)."""
        self._step("pose", wait, **{f"j{i + 1}": float(v) for i, v in enumerate(joints)})

    def gripper(self, open_pct: float, *, wait: bool = True) -> None:
        """Arms: 0 (closed) to 100 % open."""
        self._step("gripper", wait, open=open_pct)

    def home(self, *, wait: bool = True) -> None:
        """Arms: the home pose."""
        self._step("home", wait)

    def throttle(self, pct: float, seconds: float, *, wait: bool = True) -> None:
        """Test benches: holds a throttle for some seconds."""
        self._step("throttle", wait, pct=pct, s=seconds)

    def ramp(self, start: float, end: float, seconds: float, *, wait: bool = True) -> None:
        """Test benches: ramps the throttle from one percentage to another."""
        self._step("ramp", wait, **{"from": start, "to": end, "s": seconds})

    def run_sequence(self, name: str, *, wait: bool = True) -> None:
        """Runs a sequence from dash's Automate > Sequences, by name (on the
        device when it can store it: it keeps going if the link drops)."""
        self._call("cmd", timeout=24 * 3600 if wait else 5, c="program", a={"name": name, "wait": wait})

    def pause_sequence(self) -> None:
        """Pauses the running sequence."""
        self._call("cmd", c="seqctl", a={"c": "pause"})

    def resume_sequence(self) -> None:
        """Resumes it."""
        self._call("cmd", c="seqctl", a={"c": "resume"})

    def stop_sequence(self) -> None:
        """Stops it."""
        self._call("cmd", c="seqctl", a={"c": "stop"})

    # The names of 1.3.0b1–b3, for scripts written with them.
    run_program = run_sequence
    pause_program = pause_sequence
    resume_program = resume_sequence
    stop_program = stop_sequence

    # ------------------------------------------------------------------ proximity
    def proximity(self, sensor: Optional[str] = None) -> Any:
        """Proximity sensors (ultrasonic, infrared, time of flight): a dict of
        name → metres, None when nothing is in range. With a name, that
        sensor's distance::

            if (dev.proximity("front") or 9) < 0.5:
                dev.sticks(throttle=0)
        """
        names = [p.get("id", str(i + 1)) for i, p in enumerate(self.info.get("prox", []))]
        values = self.tlm.raw.get("prox", [])
        out = {(names[i] if i < len(names) else str(i + 1)): (float(v) if v >= 0 else None) for i, v in enumerate(values)}
        if sensor is None:
            return out
        if sensor not in out:
            raise ScriptError("E0503", {"name": sensor, "names": list(out)})
        return out[sensor]

    # ------------------------------------------------------------------ camera
    @property
    def camera(self) -> Camera:
        """The device's first camera."""
        if not self.cameras:
            raise ScriptError("E0601", {"device": self.name})
        return self.cameras[0]

    def overlay(self, boxes: Any, width: Optional[float] = None, height: Optional[float] = None) -> None:
        """Draws boxes over the camera picture in dash: (x, y, w, h[, label])
        tuples, normalised 0–1 (or in pixels with width and height), or an
        ultralytics result. They fade a second after the last call."""
        self._send({"t": "overlay", "boxes": boxes_of(boxes, width, height)})

    # ------------------------------------------------------------------ dash
    def setting(self, name: str, default: Any, *, min: Optional[float] = None, max: Optional[float] = None,
                label: Optional[str] = None) -> Setting:
        """A slider (numbers) or switch (True/False) in dash. Read ``.value``;
        the operator's last value is kept between runs."""
        if not isinstance(default, (bool, int, float)):
            raise ScriptError("E0701", {"name": name, "reason": f"the default must be a number or True/False, not {type(default).__name__}"})
        if min is not None and max is not None and min >= max:
            raise ScriptError("E0701", {"name": name, "reason": f"min ({min}) must be below max ({max})"})
        value = self._call("setting", name=name, value=default, min=min, max=max, label=label)
        s = self._settings[name] = Setting(name, value)
        return s

    def trigger(self, name: str, kind: str = "button", *, key: Optional[str] = None, gamepad: Optional[str] = None,
                min: Optional[float] = None, max: Optional[float] = None):
        """Decorator: runs the function when the trigger fires. ``kind``:
        ``button`` (no argument), ``switch`` (True/False) or ``value`` (a
        number). ``key`` and ``gamepad`` suggest bindings; the operator can
        change them."""
        if kind not in ("button", "switch", "value"):
            raise ScriptError("E0702", {"name": name, "kind": kind})

        def register(fn: Callable) -> Callable:
            self._triggers[name] = fn
            self._call("trigger", name=name, kind=kind, key=key, gamepad=gamepad, min=min, max=max)
            return fn
        return register

    def on_trigger(self, fn: Callable) -> Callable:
        """Decorator: ``fn(name, value)`` for triggers without their own handler."""
        self._any_trigger.append(fn)
        return fn

    def on_stop(self, fn: Callable) -> Callable:
        """Decorator: called when dash takes the sticks away or STOP is pressed."""
        self._on_stop.append(fn)
        return fn

    def on_takeover(self, fn: Callable) -> Callable:
        """Decorator: ``fn(True)`` when the operator takes the sticks, ``fn(False)`` when they give them back."""
        self._on_takeover.append(fn)
        return fn

    def plot(self, name: str, value: Optional[float] = None, **series: float) -> None:
        """Plots values over time in dash's Live view, a widget named
        ``name``, and records them (channel ``script:<name>``). One value, or
        several series on one chart::

            dev.plot("altitude", dev.tlm.alt)
            dev.plot("speed", target=2.0, actual=dev.tlm.speed)
        """
        if not series:
            if value is None:
                raise ScriptError("E0713", {"name": name})
            self._send({"t": "plot", "name": name, "v": float(value)})
            return
        labels = ([name] if value is not None else []) + list(series)
        values = ([float(value)] if value is not None else []) + [float(v) for v in series.values()]
        self._send({"t": "plot", "name": name, "v": values, "labels": labels})

    def show(self, name: str, image: Any, *, quality: int = 80, max_size: int = 960) -> bool:
        """Shows a picture in dash's Live view, a widget named ``name``: a
        numpy image (BGR, as OpenCV and dev.camera make them, or grey), a PIL
        image, a matplotlib figure, or JPEG/PNG bytes. Its largest side is
        scaled to ``max_size``. Up to 15 a second per name: calls in between
        are skipped and return False, so a fast loop never queues pictures."""
        now = time.monotonic()
        if now - self._shown.get(name, 0.0) < 1 / 15:
            return False
        self._shown[name] = now
        data, w, h = encode_image(image, quality, max_size)
        self._send({"t": "view", "name": name, "kind": "picture", "data": base64.b64encode(data).decode("ascii"), "w": w, "h": h})
        return True

    def chart(self, name: str, y: Any, *, x: Any = None, kind: str = "line", xlabel: str = "", ylabel: str = "") -> bool:
        """Draws a whole chart in dash's Live view, a widget named ``name``,
        redrawn at each call: ``y`` a list of numbers (or a numpy array), or a
        dict of named series; ``x`` their x values (else 0, 1, 2…); ``kind``
        line, bar or scatter. Up to 10 a second per name (calls in between
        are skipped and return False)::

            dev.chart("scan", distances, x=angles, kind="scatter")
            dev.chart("battery cells", {"volts": cells}, kind="bar")
        """
        msg = chart_message(name, y, x, kind, xlabel, ylabel)
        now = time.monotonic()
        if now - self._shown.get(name, 0.0) < 1 / 10:
            return False
        self._shown[name] = now
        self._send(msg)
        return True

    def mark(self, text: str) -> None:
        """An event on the recording's timeline."""
        self._call("mark", text=text)

    def notify(self, text: str, level: str = "info") -> None:
        """A message to the operator in dash (``info``, ``warn``, ``err``)."""
        self._call("notify", text=text, level=level)

    @property
    def store(self) -> dict:
        """A dictionary kept between runs of this script."""
        if self._store is None:
            safe = "".join(ch if ch.isalnum() or ch in "-_." else "_" for ch in self._name)
            self._store = _Store(DISCOVERY.parent / "script-store" / f"{safe}.json")
        return self._store

    def run(self) -> None:
        """Waits until dash closes the connection: for scripts that only react to triggers."""
        try:
            self._closed.wait()
        except KeyboardInterrupt:
            pass

    def close(self) -> None:
        for c in self.cameras:
            c.close()
        try:
            self._ws.close()
        finally:
            self._closed.set()

    def __enter__(self):
        return self

    def __exit__(self, *exc):
        self.close()

    def __repr__(self):
        return f"Device({self.name!r}, {self.kind}{', simulated' if self.simulated else ''})"


_current: Optional[Device] = None


def connect(device: Optional[str] = None, *, requires: Optional[List[str]] = None, url: Optional[str] = None,
            token: Optional[str] = None, name: Optional[str] = None) -> Device:
    """Connects to koebelt dash and returns a device: the one selected in dash,
    or the one called ``device``. dash on this computer is found by itself.

    ``requires``: what the device must be or have, as in a script's
    ``# requires:`` lines: kinds (any one: ``"drone"``, ``"rover"``…) and
    capabilities (all: ``"gps"``, ``"camera"``, ``"lidar"``…)."""
    global _current
    url, token = _find_dash(url, token)
    name = name or os.path.basename(sys.argv[0] or "") or "python"
    try:
        # Entering the context opens it, in every websockets version from 12 on.
        ws = ws_connect(url, open_timeout=5, max_size=None).__enter__()
    except (OSError, TimeoutError) as e:
        raise ScriptError("E0011", {"url": url, "reason": str(e) or type(e).__name__}) from None
    ws.send(json.dumps({"t": "hello", "v": API_VERSION, "token": token, "name": name, "pid": os.getpid()}))
    welcome = json.loads(ws.recv(timeout=5))
    if welcome.get("t") != "welcome":
        ws.close()
        raise ScriptError("E0012", {"reason": welcome.get("why") or "no reason given"})
    dev = Device(ws, welcome, name)
    _check_version(welcome.get("app"))
    dev._use(device, requires)
    _current = dev
    return dev


def _version_key(v: str):
    """1.3.0b2 or 1.3.0-beta.2 → a sortable tuple (a release after its betas)."""
    import re
    m = re.match(r"^(\d+)\.(\d+)\.(\d+)(?:-?(a|alpha|b|beta|rc)\.?(\d+))?", v or "")
    if not m:
        return None
    stage = {"a": 0, "alpha": 0, "b": 1, "beta": 1, "rc": 2}.get(m.group(4) or "", 3)
    return (int(m.group(1)), int(m.group(2)), int(m.group(3)), stage, int(m.group(5) or 0))


def _check_version(app: Optional[str]) -> None:
    """Warns once when this library is older than the dash it talks to."""
    from . import __version__
    have, want = _version_key(__version__), _version_key(app or "")
    if have is None or want is None or have >= want:
        return
    # The package is released with the app, at its version: ask for at least that one.
    major, minor, patch, stage, n = want
    pep = f"{major}.{minor}.{patch}" + ("" if stage == 3 else f"{['a', 'b', 'rc'][stage]}{n}")
    warn_once("W0102", "version", {"have": __version__, "app": app, "spec": f">={pep},<2"})


def every(seconds: float) -> Iterator[int]:
    """A steady loop: ``for i in every(0.05): ...`` runs the body every 50 ms
    (or as fast as it can), and reports the real rate to dash."""
    period = float(seconds)
    if period <= 0:
        raise ScriptError("E0703", {"seconds": seconds})
    nxt = time.monotonic()
    window, count = nxt, 0
    for i in itertools.count():
        yield i
        now = time.monotonic()
        # The rate over each second, not single intervals.
        count += 1
        if now - window >= 1.0 and _current is not None:
            _current.hz = count / (now - window)
            window, count = now, 0
        nxt += period
        delay = nxt - time.monotonic()
        if delay > 0:
            time.sleep(delay)
        else:
            nxt = time.monotonic()


def wait(seconds: float) -> None:
    time.sleep(seconds)
