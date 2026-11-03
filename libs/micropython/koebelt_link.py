"""koebelt/link for MicroPython: connect an ESP32, a Raspberry Pi Pico W or
another MicroPython board to the koebelt/dash app.

    import koebelt_link as kl

    kl.wifi("my-network", "password")
    dev = kl.Device("Mule-3", kind="rover")
    dev.connect(wifi=True)              # or usb=True, serial=UART(1, 115200), radio=(UART(1, 57600), "sik")
    max_spd = dev.param("MAX_SPD", 2, min=0.5, max=4, unit="m/s")

    @dev.on_control
    def drive(c):
        motors(c.ry * max_spd.value, c.lx)

    @dev.on_stop
    def stop():
        motors(0, 0)

    while True:
        dev.imu(*imu.accel(), *imu.gyro())
        dev.tick(hz=50)

One module, no threads: tick() reads what arrived, runs the failsafe and
sends what is due. The wire protocol is protocol/PROTOCOL.md; sequences run
from the app (this library does not store them). Bluetooth, video and point
clouds are left to the other libraries.
"""
import json

try:
    from time import sleep_ms, ticks_diff, ticks_ms
except ImportError:  # CPython, for the tests
    import time as _time

    def ticks_ms():
        return int(_time.monotonic() * 1000)

    def ticks_diff(a, b):
        return a - b

    def sleep_ms(ms):
        _time.sleep(ms / 1000)


__version__ = "1.0.0"
VERSION = 1
UDP_DEVICE_PORT = 47800
UDP_ANNOUNCE_PORT = 47801

KINDS = ("drone", "plane", "rover", "boat", "arm", "rocket", "bench", "generic")
FLYING = ("drone", "plane")

#: Radio link profiles (protocol/PROTOCOL.md, "Radio links"): id -> (baud,
#: telemetry Hz, control Hz). Control Hz 0 means telemetry only. Same table
#: in every library and in protocol/vectors.json.
RADIO_PROFILES = {
    "sik": (57600, 5, 10),
    "lora": (115200, 2, 0),
    "hc12": (9600, 2, 5),
    "xbee": (57600, 5, 10),
    "other": (57600, 2, 5),
}

#: Fields sent on links of 2 Hz or less.
COMPACT_FIELDS = ("pos", "att", "gps", "bat", "rocket")


def module_rate_hz(baud):
    """Telemetry rate for a serial bridge module (HM-10, HC-05…) at `baud`:
    2 Hz up to 19200 baud, 5 Hz to 57600, 10 Hz above. Same in every library."""
    return 2.0 if baud <= 19200 else 5.0 if baud <= 57600 else 10.0


def encode(m):
    return json.dumps(m).encode()


def decode(data):
    """One message, or None for anything that is not a JSON object with a string `t`."""
    try:
        m = json.loads(data)
    except (ValueError, TypeError):
        return None
    if isinstance(m, dict) and isinstance(m.get("t"), str):
        return m
    return None


def wifi(ssid, password, timeout=20):
    """Join a Wi-Fi network (station mode) and return this board's IP address."""
    import network

    w = network.WLAN(network.STA_IF)
    w.active(True)
    if not w.isconnected():
        w.connect(ssid, password)
        t0 = ticks_ms()
        while not w.isconnected():
            if ticks_diff(ticks_ms(), t0) > timeout * 1000:
                raise OSError("could not join " + ssid)
            sleep_ms(100)
    ip = w.ifconfig()[0]
    print("koebelt_link: on", ssid, "as", ip)
    return ip


# ---------------------------------------------------------------- transports
class _Transport:
    accepts_control = True
    low_bandwidth = False
    max_rate_hz = 0.0

    def use_radio(self, radio):
        """Apply a radio profile: sik, lora, hc12, xbee or other."""
        if radio not in RADIO_PROFILES:
            raise ValueError("radio must be one of " + ", ".join(RADIO_PROFILES))
        _, tlm, ctl = RADIO_PROFILES[radio]
        self.low_bandwidth = True
        self.max_rate_hz = float(tlm)
        self.accepts_control = ctl > 0
        return self

    def use_module(self, baud):
        """A Bluetooth serial module (HM-10, HC-05…) on a UART at `baud`."""
        self.low_bandwidth = True
        self.max_rate_hz = module_rate_hz(baud)
        return self

    def announce(self, m):
        pass

    def close(self):
        pass


class UdpTransport(_Transport):
    """Wi-Fi: one JSON message per datagram on port 47800."""

    def __init__(self, port=UDP_DEVICE_PORT):
        import socket

        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        for opt in ("SO_REUSEADDR", "SO_BROADCAST"):
            try:
                s.setsockopt(socket.SOL_SOCKET, getattr(socket, opt), 1)
            except (AttributeError, OSError):
                pass
        s.bind(socket.getaddrinfo("0.0.0.0", port)[0][-1])
        s.setblocking(False)
        self.sock = s
        self.peer = None
        try:
            self.port = s.getsockname()[1]
        except (AttributeError, OSError, TypeError):
            self.port = port
        self._bcast = socket.getaddrinfo("255.255.255.255", UDP_ANNOUNCE_PORT)[0][-1]

    def poll(self):
        out = []
        while True:
            try:
                data, addr = self.sock.recvfrom(1500)
            except OSError:
                break
            m = decode(data)
            if m is None:
                continue
            t = m["t"]
            if t == "discover":
                m["_from"] = addr
            elif t in ("hello", "pair"):
                self.peer = addr
            elif self.peer is None or addr != self.peer:
                continue  # commands only from the session peer
            out.append(m)
        return out

    def send(self, m):
        if self.peer is not None:
            self.reply(m, self.peer)

    def reply(self, m, addr):
        try:
            self.sock.sendto(encode(m), addr)
        except OSError:
            pass

    def announce(self, m):
        self.reply(m, self._bcast)

    def drop_peer(self):
        self.peer = None

    def close(self):
        self.sock.close()


class StreamTransport(_Transport):
    """Newline-delimited JSON over a UART, USB or any object with `read()`
    (returning bytes or None, without blocking) and `write(bytes)`."""

    MAX_LINE = 4096

    def __init__(self, port):
        self.port = port
        self._buf = b""

    def _read(self):
        p = self.port
        n = p.any() if hasattr(p, "any") else None
        if n == 0:
            return None
        return p.read(n) if n else p.read()

    def poll(self):
        try:
            data = self._read()
        except OSError:
            return []
        if not data:
            return []
        self._buf += data
        out = []
        while True:
            i = self._buf.find(b"\n")
            if i < 0:
                break
            line, self._buf = self._buf[:i].strip(), self._buf[i + 1:]
            m = decode(line) if line else None
            if m is not None:
                out.append(m)
        if len(self._buf) > self.MAX_LINE:
            self._buf = b""
        return out

    def send(self, m):
        try:
            self.port.write(encode(m) + b"\n")
        except OSError:
            pass

    def announce(self, m):
        # One peer on a wire or radio: the app finds the device by reading.
        self.send(m)


class _Usb:
    """The board's USB serial (the REPL port): reads stdin without blocking."""

    def __init__(self):
        import select
        import sys

        self._in = getattr(sys.stdin, "buffer", sys.stdin)
        self._out = getattr(sys.stdout, "buffer", sys.stdout)
        self._poll = select.poll()
        self._poll.register(sys.stdin, select.POLLIN)

    def any(self):
        return 1 if self._poll.poll(0) else 0

    def read(self, n=1):
        b = bytearray()
        while self._poll.poll(0) and len(b) < 256:
            c = self._in.read(1)
            if not c:
                break
            b += c if isinstance(c, (bytes, bytearray)) else c.encode()
        return bytes(b)

    def write(self, data):
        self._out.write(data)


# ---------------------------------------------------------------- values
class Control:
    """Four normalised axes, −1…1. Sticks, sliders and tilt all map here."""

    def __init__(self, lx=0.0, ly=0.0, rx=0.0, ry=0.0, seq=0):
        self.lx, self.ly, self.rx, self.ry, self.seq = lx, ly, rx, ry, seq

    @property
    def zero(self):
        return not (self.lx or self.ly or self.rx or self.ry)


class Param:
    """A tunable value shown on the app's Tune screen."""

    def __init__(self, key, default, lo, hi, step, unit, label):
        self.key = key
        self.value = self.default = float(default)
        self.min, self.max = float(lo), float(hi)
        span = self.max - self.min
        self.step = float(step) if step else (10 ** _floor_log10(span / 100) if span > 0 else 0.01)
        self.unit = unit
        self.label = label or key
        self._cbs = []

    def on_change(self, fn):
        self._cbs.append(fn)
        return fn

    def _set(self, v):
        v = max(self.min, min(self.max, float(v)))
        if v != self.value:
            self.value = v
            for cb in self._cbs:
                cb(v)

    def __float__(self):
        return self.value


def _floor_log10(x):
    n = 0
    while x >= 10:
        x /= 10
        n += 1
    while x < 1:
        x *= 10
        n -= 1
    return n


class Channel:
    """A custom telemetry channel with 1–6 axes."""

    def __init__(self, dev, id, axes, unit, hz):
        if not 1 <= len(axes) <= 6:
            raise ValueError("a channel has 1 to 6 axes")
        self.dev, self.id, self.axes, self.unit, self.hz = dev, id, list(axes), unit, hz

    def publish(self, *values):
        if len(values) != len(self.axes):
            raise ValueError(self.id + " expects " + str(len(self.axes)) + " values")
        self.dev._tlm[self.id] = [float(v) for v in values]


class Proximity:
    """A proximity sensor from Device.proximity(): give it what it measures."""

    def __init__(self, dev, index):
        self.dev, self.index = dev, index

    def set(self, metres):
        """The distance in metres; None when nothing is in range."""
        v = self.dev._prox_values
        v[self.index] = -1.0 if metres is None or metres < 0 else float(metres)
        self.dev._tlm["prox"] = list(v)


# ---------------------------------------------------------------- device
class Device:
    """A koebelt/link device."""

    def __init__(self, name, kind="generic", id=None, model="", sensors=None, fw="", state_file="koebelt_link.json"):
        if kind not in KINDS:
            raise ValueError("kind must be one of " + ", ".join(KINDS))
        self.name, self.kind, self.model, self.fw = name, kind, model, fw
        self.id = id or _slug(name)
        self.sensors = list(sensors or [])
        self.transports = []
        self._active = None

        self.control = Control()
        self.mode = "PAD" if kind == "rocket" else "IDLE" if kind == "bench" else "HOLD"
        self.armed = False
        self.estop = False
        self.speed = 0.5
        self.jog = [0.0] * 6
        self.cart = [0.0] * 3
        self.ext = {}
        self.prox = []
        self._prox_values = []

        self.rate_hz = 30.0
        self.params = {}
        self.channels = {}
        self._tlm = {}

        self._fs_timeout = 1.8
        self._fs_action = "HOLD"
        self.failsafe_active = False
        self._last_ctl = 0.0
        self._session = False

        self._pair_code = None
        self._file = state_file
        self.key = None
        self._saved = {}
        self._load()

        self._cb = {}
        self._clock = 0.0  # seconds since start, from ticks that may wrap
        self._ticks = ticks_ms()
        self._t_tlm = self._t_state = self._t_announce = -10.0
        self._last_tick = self._ticks
        self._state_dirty = True

    # ------------------------------------------------------------ connection
    def connect(self, wifi=False, usb=False, serial=None, radio=None, module=None, port=UDP_DEVICE_PORT, fallback=None):
        """Open links. The first is primary; `fallback` takes over telemetry
        when the failsafe trips.

        `serial` is a UART (or anything with read/write); `radio` a radio
        modem on a UART: a UART (SiK) or (uart, profile) with profile sik,
        lora, hc12, xbee or other; `module` a Bluetooth serial module on a
        UART: (uart, baud)."""
        if wifi:
            self.add_transport(UdpTransport(port))
        if usb:
            self.add_transport(StreamTransport(_Usb()))
        if serial is not None:
            self.add_transport(StreamTransport(serial))
        if radio is not None:
            self.add_transport(self._radio(radio))
        if module is not None:
            self.add_transport(StreamTransport(module[0]).use_module(module[1]))
        for k, v in (fallback or {}).items():
            if k == "radio":
                self.add_transport(self._radio(v))
            elif k == "serial":
                self.add_transport(StreamTransport(v))
            elif k == "wifi":
                self.add_transport(UdpTransport(port))
            else:
                raise ValueError("unknown fallback " + k)
        if not self.transports:
            raise ValueError("pick a link: wifi=True, usb=True, serial=UART(…) or radio=(UART(…), 'sik')")
        return self

    @staticmethod
    def _radio(r):
        port, profile = r if isinstance(r, tuple) else (r, "sik")
        return StreamTransport(port).use_radio(profile)

    def add_transport(self, t):
        """Use a custom transport (anything with poll, send and announce)."""
        self.transports.append(t)
        return self

    def close(self):
        for t in self.transports:
            t.close()
        self.transports = []

    @property
    def connected(self):
        return self._session and self._clock - self._last_ctl < 3.0

    # ------------------------------------------------------------ callbacks
    def _on(self, name, fn):
        self._cb.setdefault(name, []).append(fn)
        return fn

    def _emit(self, name, *args):
        for fn in self._cb.get(name, ()):
            fn(*args)

    def on_control(self, fn):
        """`fn(c: Control)` on every control packet (20 Hz while the app is open)."""
        return self._on("control", fn)

    def on_mode(self, fn):
        """`fn(mode)` when the mode changes (from the app or the failsafe)."""
        return self._on("mode", fn)

    def on_stop(self, fn):
        """`fn()` on emergency stop. Cut the motors here."""
        return self._on("stop", fn)

    def on_reset(self, fn):
        return self._on("reset", fn)

    def on_arm(self, fn):
        """`fn(armed)`."""
        return self._on("arm", fn)

    def on_jog(self, fn):
        """`fn(joints)` joint jog velocities, −1…1 (arms)."""
        return self._on("jog", fn)

    def on_cart(self, fn):
        """`fn(v)` Cartesian jog x, y, z, −1…1 (arms)."""
        return self._on("cart", fn)

    def on_command(self, fn):
        """`fn(name, args)` for commands: takeoff, goto, throttle, your own…"""
        return self._on("cmd", fn)

    def on_params_written(self, fn):
        return self._on("params_written", fn)

    def on_connect(self, fn):
        return self._on("connect", fn)

    # ------------------------------------------------------------ safety
    def failsafe(self, timeout=1.8, action="hold"):
        """Switch to `action` (hold, rth or land) after `timeout` s without a control packet."""
        a = action.upper()
        if a not in ("HOLD", "RTH", "LAND"):
            raise ValueError("action must be hold, rth or land")
        self._fs_timeout, self._fs_action = float(timeout), a

    def set_mode(self, mode):
        """Report a mode change made by the device itself."""
        if mode != self.mode:
            self.mode = mode
            self._state_dirty = True

    def set_armed(self, armed):
        if armed != self.armed:
            self.armed = armed
            self._state_dirty = True

    def set_state(self, **ext):
        """Kind-specific state shown in the app, e.g. pyro=["OK", "OK", "-", "-"]."""
        self.ext.update(ext)
        self._state_dirty = True

    def proximity(self, id, dir=0.0, tilt=0.0, fov=0.26, min=0.0, max=4.0, kind=""):
        """Declare a proximity sensor before the app connects; returns it: `.set(metres)`."""
        p = {"id": id, "fov": float(fov), "max": float(max)}
        if dir:
            p["dir"] = float(dir)
        if tilt:
            p["tilt"] = float(tilt)
        if min:
            p["min"] = float(min)
        if kind:
            p["kind"] = kind
        self.prox.append(p)
        self._prox_values.append(-1.0)
        return Proximity(self, len(self.prox) - 1)

    # ------------------------------------------------------------ params and channels
    def param(self, key, default, min=0.0, max=None, step=None, unit="", label=None):
        if max is None:
            max = default * 4 if default else 1.0
        p = Param(key, default, min, max, step, unit, label)
        if key in self._saved:
            p.value = _clamp(float(self._saved[key]), p.min, p.max)
        self.params[key] = p
        return p

    def save_params(self):
        """Keep the parameter values (and the pairing key) in flash."""
        self._saved = {k: p.value for k, p in self.params.items()}
        self._store()

    def channel(self, id, axes=("value",), unit="", hz=10):
        c = Channel(self, id, axes, unit, hz)
        self.channels[id] = c
        if self._session:
            self._send(self._chan_msg())
        return c

    # ------------------------------------------------------------ telemetry
    def _set(self, k, *v):
        self._tlm[k] = [float(x) for x in v]

    def imu(self, ax, ay, az, gx, gy, gz):
        """Acceleration (m/s²) and rotation rate (rad/s)."""
        self._set("imu", ax, ay, az, gx, gy, gz)

    def attitude(self, roll, pitch, yaw):
        self._set("att", roll, pitch, yaw)

    def position(self, x, y, z):
        """Metres east, north and up from home."""
        self._set("pos", x, y, z)

    def velocity(self, vx, vy, vz):
        self._set("vel", vx, vy, vz)

    def gps(self, lat, lon, alt, sats=0):
        self._set("gps", lat, lon, alt, sats)

    def battery(self, volts, percent, amps=0.0):
        self._set("bat", volts, amps, percent)

    def rssi(self, dbm):
        self._set("rssi", dbm)

    def joints(self, rad):
        self._set("joints", *list(rad)[:6])

    def tool(self, x, y, z, gripper=0.0):
        self._set("tool", x, y, z, gripper)

    def force_torque(self, fx, fy, fz):
        self._set("ft", fx, fy, fz)

    def thrust(self, newtons, torque=0.0):
        self._set("thrust", newtons, torque)

    def rpm(self, v):
        self._set("rpm", v)

    def temperature(self, c):
        self._set("temp", c)

    def throttle_out(self, v):
        self._set("throttle", v)

    def rocket_state(self, max_alt, phase_time, countdown=0.0):
        self._set("rocket", max_alt, phase_time, countdown)

    def publish(self, channel, *values):
        """Any channel by name, values in protocol order: publish("pos", x, y, z)."""
        flat = []
        for v in values:
            if isinstance(v, (list, tuple)):
                flat.extend(float(x) for x in v)
            else:
                flat.append(float(v))
        self._tlm[channel] = flat

    def log(self, msg, lvl="info"):
        """A line in the app's log."""
        self._send({"t": "log", "lvl": lvl, "msg": msg})

    # ------------------------------------------------------------ pairing
    def pair(self, code):
        """Enter pairing mode with the code the app shows. The key is kept in flash."""
        self._pair_code = code.strip().upper()

    def unpair(self):
        self.key = None
        self._store()

    # ------------------------------------------------------------ loop
    def tick(self, hz=None):
        """Read what arrived, run the failsafe, send what is due. Call it
        every loop; with `hz`, sleeps so the loop runs at that rate."""
        now_t = ticks_ms()
        self._clock += ticks_diff(now_t, self._ticks) / 1000
        self._ticks = now_t
        now = self._clock
        for t in self.transports:
            for m in t.poll():
                self._handle(t, m, now)
        self._check_failsafe(now)
        self._outgoing(now)
        if hz:
            wait = int(1000 / hz) - ticks_diff(ticks_ms(), self._last_tick)
            if wait > 0:
                sleep_ms(wait)
        self._last_tick = ticks_ms()

    def run(self, hz=50, loop=None):
        """Blocking loop: calls `loop()` then `tick(hz)` forever."""
        try:
            while True:
                if loop:
                    loop()
                self.tick(hz)
        finally:
            self.close()

    # ------------------------------------------------------------ internals
    def _send(self, m):
        t = self._active or (self.transports[0] if self.transports else None)
        if t is not None:
            t.send(m)

    def _lib(self):
        return "micropython/" + __version__

    def _hello(self):
        m = {"t": "hello", "v": VERSION, "id": self.id, "name": self.name, "kind": self.kind, "model": self.model, "fw": self.fw,
             "lib": self._lib(), "sensors": self.sensors, "ok": True}
        if self.prox:
            m["prox"] = self.prox
        return m

    def _announce(self):
        m = {"t": "announce", "v": VERSION, "id": self.id, "name": self.name, "kind": self.kind, "lib": self._lib(), "model": self.model,
             "sensors": self.sensors}
        if self._pair_code:
            m["pair"] = self._pair_code
        return m

    def _params_msg(self):
        return {"t": "params", "p": [[p.key, p.value, p.min, p.max, p.step, p.unit, p.label] for p in self.params.values()]}

    def _chan_msg(self):
        return {"t": "chan", "ch": [{"id": c.id, "axes": c.axes, "unit": c.unit, "hz": c.hz} for c in self.channels.values()]}

    def _state_msg(self):
        return {"t": "state", "mode": self.mode, "armed": self.armed, "estop": self.estop, "fs": self.failsafe_active, "ext": self.ext}

    def _set_mode(self, m):
        if m != self.mode:
            self.mode = m
            self._state_dirty = True
            self._emit("mode", m)

    def _handle(self, t, m, now):
        typ = m["t"]
        if typ == "discover":
            if hasattr(t, "reply") and "_from" in m:
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
                if hasattr(t, "drop_peer"):
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
        # Telemetry-only links: nothing that moves the device; STOP still counts.
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
            self.rate_hz = _clamp(float(m.get("hz", 30)), 1.0, 60.0)
        elif typ == "speed":
            self.speed = _clamp(float(m.get("v", 0.5)), 0.1, 1.0)
        elif typ == "fs":
            self._fs_action = str(m.get("action", self._fs_action)).upper()
            self._fs_timeout = float(m.get("ms", self._fs_timeout * 1000)) / 1000
        elif typ == "bye":
            self._session = False
            self.control = Control()
            if self.kind in FLYING and self.armed:
                self._set_mode("HOLD")
            if hasattr(t, "drop_peer"):
                t.drop_peer()

    def _check_failsafe(self, now):
        if not self._session or self.failsafe_active or self.kind == "rocket":
            return
        if now - self._last_ctl <= self._fs_timeout:
            return
        self.failsafe_active = True
        self.control = Control()
        self._state_dirty = True
        self._emit("control", self.control)
        if self.kind in FLYING:
            self._set_mode(self._fs_action)
        elif self.kind == "bench":
            self._set_mode("IDLE")
        elif self.armed:
            self._set_mode("HOLD")
        self._send({"t": "log", "lvl": "warn", "msg": "Failsafe: no control for %.1f s" % self._fs_timeout})
        # Telemetry carries on over the fallback link, if there is one.
        others = [t for t in self.transports if t is not self._active]
        if others:
            self._active = others[0]

    def _outgoing(self, now):
        if not self._session:
            if now - self._t_announce >= 1.0:
                self._t_announce = now
                for t in self.transports:
                    t.announce(self._announce())
            return
        link = self._active or self.transports[0]
        cap = link.max_rate_hz
        hz = min(self.rate_hz, cap) if cap > 0 else self.rate_hz
        if self._state_dirty or now - self._t_state >= (2.0 if link.low_bandwidth else 0.5):
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

    # ------------------------------------------------------------ flash
    def _load(self):
        try:
            with open(self._file) as f:
                j = json.load(f)
            self.key = j.get("key")
            self._saved = j.get("params") or {}
        except (OSError, ValueError):
            pass

    def _store(self):
        try:
            with open(self._file, "w") as f:
                json.dump({"key": self.key, "params": self._saved}, f)
        except OSError:
            pass


def _clamp(v, lo, hi):
    return lo if v < lo else hi if v > hi else v


def _slug(name):
    out, dash = "", False
    for ch in name.lower():
        if "a" <= ch <= "z" or "0" <= ch <= "9":
            out += ch
            dash = False
        elif not dash and out:
            out += "-"
            dash = True
    return out.rstrip("-")
