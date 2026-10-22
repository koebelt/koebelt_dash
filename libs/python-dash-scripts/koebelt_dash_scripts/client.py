"""The connection to koebelt/dash: a device a script reads and drives.

The messages are in protocol/SCRIPTS.md. A background thread receives
telemetry and events; handlers (triggers, settings, takeover) run on a second
thread, so a slow handler never delays telemetry, and a slow main loop (a
model taking 200 ms per frame) never trips dash's watchdog: keep-alives go
out from their own thread every 100 ms.
"""
from __future__ import annotations

import itertools
import json
import os
import pathlib
import queue
import sys
import threading
import time
import traceback
from typing import Any, Callable, Dict, Iterator, List, Optional

from websockets.exceptions import ConnectionClosed
from websockets.sync.client import connect as ws_connect

API_VERSION = 1
DISCOVERY = pathlib.Path.home() / ".koebelt" / "dash-api.json"


class ScriptError(RuntimeError):
    """dash refused a request; the message says why."""


class Released(ScriptError):
    """dash took the sticks away (watchdog, geofence, STOP…) and the operator has not resumed the script yet."""


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
        try:
            return self.raw[name]
        except KeyError:
            raise AttributeError(f"this device sends no '{name}' (it sends: {', '.join(sorted(self.raw))})") from None

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
        raise ScriptError("koebelt dash is not running on this computer (no ~/.koebelt/dash-api.json). "
                          "Start it, or pass url= and token=.") from None
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
        self.hz: Optional[float] = None
        self.released: Optional[str] = None
        """Why dash took the sticks away, until the operator resumes the script."""
        self.taken_over = False
        """True while the operator holds the sticks."""
        self.app = welcome.get("app")
        self.devices = welcome.get("devices", [])
        self.params = Params(self)
        self.info: Dict[str, Any] = {}
        for target in (self._receive, self._dispatch, self._keepalive):
            threading.Thread(target=target, daemon=True, name=f"koebelt-dash-{target.__name__}").start()

    # ------------------------------------------------------------------ plumbing
    def _send(self, msg: Dict[str, Any]) -> None:
        with self._send_lock:
            self._ws.send(json.dumps(msg))

    def _call(self, t: str, timeout: float = 5, **fields) -> Any:
        if self._closed.is_set():
            raise ScriptError("the connection to koebelt dash is closed")
        i = next(self._ids)
        box: "queue.Queue[Dict[str, Any]]" = queue.Queue(1)
        self._waiting[i] = box
        try:
            self._send({"t": t, "id": i, **fields})
            try:
                res = box.get(timeout=timeout)
            except queue.Empty:
                raise ScriptError(f"koebelt dash did not answer '{t}' within {timeout} s") from None
        finally:
            self._waiting.pop(i, None)
        if res.get("closed"):
            raise ScriptError("the connection to koebelt dash closed")
        if not res.get("ok"):
            err = res.get("err") or "refused"
            raise (Released if self.released and "resume" in err else ScriptError)(err)
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
                except Exception:
                    traceback.print_exc()

    def _keepalive(self) -> None:
        while not self._closed.wait(0.1):
            try:
                self._send({"t": "ka", **({"hz": round(self.hz, 2)} if self.hz else {})})
            except Exception:
                return

    def _use(self, device: Optional[str]) -> None:
        self.info = self._call("use", device=device)
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
            raise ScriptError("no telemetry from the device yet")
        return self._tlm

    def next_tlm(self, timeout: float = 1.0) -> Telemetry:
        """Waits for the next telemetry message and returns it."""
        with self._tlm_ready:
            before = self._tlm
            if not self._tlm_ready.wait_for(lambda: self._tlm is not before, timeout=timeout):
                raise ScriptError(f"no telemetry for {timeout} s")
            return self._tlm  # type: ignore[return-value]

    # ------------------------------------------------------------------ acting
    def sticks(self, **axes: float) -> None:
        """Sets the sticks, −1…1, until changed. Drones: ``throttle``, ``yaw``,
        ``pitch``, ``roll``; rovers: ``throttle``, ``steer``; any device:
        ``lx``, ``ly``, ``rx``, ``ry``. dash scales them to the script's speed
        limit, and the operator's sticks win."""
        self._call("sticks", a=axes)

    def release(self) -> None:
        """Hands the sticks back; the device holds."""
        self._call("release")

    def mode(self, mode: str) -> None:
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

    # ------------------------------------------------------------------ dash
    def setting(self, name: str, default: Any, *, min: Optional[float] = None, max: Optional[float] = None,
                label: Optional[str] = None) -> Setting:
        """A slider (numbers) or switch (True/False) in dash. Read ``.value``;
        the operator's last value is kept between runs."""
        value = self._call("setting", name=name, value=default, min=min, max=max, label=label)
        s = self._settings[name] = Setting(name, value)
        return s

    def trigger(self, name: str, kind: str = "button", *, key: Optional[str] = None, gamepad: Optional[str] = None,
                min: Optional[float] = None, max: Optional[float] = None):
        """Decorator: runs the function when the trigger fires. ``kind``:
        ``button`` (no argument), ``switch`` (True/False) or ``value`` (a
        number). ``key`` and ``gamepad`` suggest bindings; the operator can
        change them."""
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

    def plot(self, name: str, value: float) -> None:
        """Shows a value in dash (channel ``script:<name>``) and records it."""
        self._send({"t": "plot", "name": name, "v": float(value)})

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


def connect(device: Optional[str] = None, *, url: Optional[str] = None, token: Optional[str] = None,
            name: Optional[str] = None) -> Device:
    """Connects to koebelt dash and returns a device: the one selected in dash,
    or the one called ``device``. dash on this computer is found by itself."""
    global _current
    url, token = _find_dash(url, token)
    name = name or os.path.basename(sys.argv[0] or "") or "python"
    try:
        # Entering the context opens it, in every websockets version from 12 on.
        ws = ws_connect(url, open_timeout=5, max_size=None).__enter__()
    except OSError as e:
        raise ScriptError(f"cannot reach koebelt dash at {url}: {e}") from None
    ws.send(json.dumps({"t": "hello", "v": API_VERSION, "token": token, "name": name, "pid": os.getpid()}))
    welcome = json.loads(ws.recv(timeout=5))
    if welcome.get("t") != "welcome":
        ws.close()
        raise ScriptError(welcome.get("why") or "koebelt dash refused the connection")
    dev = Device(ws, welcome, name)
    dev._use(device)
    _current = dev
    return dev


def every(seconds: float) -> Iterator[int]:
    """A steady loop: ``for i in every(0.05): ...`` runs the body every 50 ms
    (or as fast as it can), and reports the real rate to dash."""
    period = float(seconds)
    nxt = time.monotonic()
    last = None
    for i in itertools.count():
        yield i
        now = time.monotonic()
        if last is not None and _current is not None:
            dt = now - last
            hz = 1 / dt if dt > 0 else 0.0
            _current.hz = hz if _current.hz is None else _current.hz * 0.8 + hz * 0.2
        last = now
        nxt += period
        delay = nxt - time.monotonic()
        if delay > 0:
            time.sleep(delay)
        else:
            nxt = time.monotonic()


def wait(seconds: float) -> None:
    time.sleep(seconds)
