"""End-to-end tests: a fake app talks to a Device over real UDP on localhost."""
from __future__ import annotations

import json
import socket
import time
from pathlib import Path

import pytest

from koebelt_link import Device, Vec3, decode, decode_points, encode

VECTORS = json.loads((Path(__file__).resolve().parents[3] / "protocol" / "vectors.json").read_text())["vectors"]


class App:
    """Minimal app side of the protocol."""

    def __init__(self, dev: Device, port: int):
        self.dev, self.addr = dev, ("127.0.0.1", port)
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.sock.bind(("127.0.0.1", 0))
        self.sock.setblocking(False)
        self.got = []

    def send(self, m):
        self.sock.sendto(encode(m), self.addr)

    def pump(self, secs=0.1, ctl=True):
        end = time.monotonic() + secs
        while time.monotonic() < end:
            if ctl:
                self.send({"t": "ctl", "s": 0, "lx": 0, "ly": 0, "rx": 0, "ry": 0})
            self.dev.tick()
            while True:
                try:
                    data, _ = self.sock.recvfrom(65535)
                except BlockingIOError:
                    break
                self.got.append(decode(data))
            time.sleep(0.01)

    def of(self, t):
        return [m for m in self.got if m["t"] == t]


@pytest.fixture
def pair(tmp_path):
    dev = Device("Test-1", kind="rover", state_dir=str(tmp_path))
    dev.connect(wifi=True, port=0)
    port = dev.transports[0].port
    app = App(dev, port)
    yield dev, app
    dev.close()


@pytest.mark.parametrize("v", VECTORS, ids=[v["name"] for v in VECTORS])
def test_vectors(v):
    m = decode(v["wire"])
    want = v["decoded"]
    if m["t"] == "pc":
        assert decode_points(m["d"]) == want["points_m"]
        return
    for k, val in want.items():
        assert m[k] == val


def test_handshake_and_telemetry(pair):
    dev, app = pair
    dev.param("MAX_SPD", 4, 0.5, 8, unit="m/s")
    dev.channel("motor_temp", ["L", "R"], "C", 10)
    app.send({"t": "hello", "v": 1})
    app.pump(0.05)
    hello = app.of("hello")[0]
    assert hello["ok"] and hello["kind"] == "rover" and hello["id"] == "test-1"
    assert app.of("params")[0]["p"][0][:2] == ["MAX_SPD", 4.0]
    assert app.of("chan")[0]["ch"][0]["axes"] == ["L", "R"]
    dev.publish("imu", accel=Vec3(0, 0, 9.81), gyro=Vec3(0, 0, 0.1))
    dev.gps(47.1, 8.2, 400)
    app.pump(0.1)
    tlm = app.of("tlm")[-1]["d"]
    assert tlm["imu"] == [0, 0, 9.81, 0, 0, 0.1] or tlm.get("gps")
    assert any("gps" in m["d"] for m in app.of("tlm"))


def test_control_mode_and_stop(pair):
    dev, app = pair
    seen = {"ctl": [], "mode": [], "stop": 0}
    dev.on_control(lambda c: seen["ctl"].append(c))
    dev.on_mode(lambda m: seen["mode"].append(m))
    dev.on_stop(lambda: seen.__setitem__("stop", seen["stop"] + 1))
    app.send({"t": "hello", "v": 1})
    app.send({"t": "arm", "v": True})
    app.send({"t": "mode", "m": "MANUAL"})
    app.send({"t": "ctl", "s": 1, "lx": 0.5, "ly": 0, "rx": 0, "ry": -1})
    dev.tick()
    time.sleep(0.02)
    dev.tick()
    assert dev.armed and dev.mode == "MANUAL"
    assert any(c.lx == 0.5 and c.ry == -1 for c in seen["ctl"])
    for _ in range(3):
        app.send({"t": "stop"})
    app.pump(0.05)
    assert dev.estop and not dev.armed and seen["stop"] == 1
    app.send({"t": "mode", "m": "AUTO"})
    app.pump(0.05)
    assert dev.mode == "MANUAL", "mode changes are blocked while stopped"
    assert app.of("state")[-1]["estop"] is True
    app.send({"t": "reset"})
    app.pump(0.05)
    assert not dev.estop and not dev.armed


def test_failsafe(pair):
    dev, app = pair
    dev.failsafe(timeout=0.2, action="hold")
    modes = []
    dev.on_mode(modes.append)
    app.send({"t": "hello", "v": 1})
    app.send({"t": "arm", "v": True})
    app.send({"t": "mode", "m": "MANUAL"})
    app.pump(0.1)
    assert not dev.failsafe_active
    app.pump(0.4, ctl=False)
    assert dev.failsafe_active and dev.mode == "HOLD" and modes[-1] == "HOLD"
    app.pump(0.05)
    assert not dev.failsafe_active


def test_params_write(pair):
    dev, app = pair
    p = dev.param("SPD_P", 0.8, 0, 3.2)
    changed, written = [], []
    p.on_change(changed.append)
    dev.on_params_written(lambda: written.append(1))
    app.send({"t": "hello", "v": 1})
    app.send({"t": "pset", "p": {"SPD_P": 1.25, "NOPE": 3}})
    app.pump(0.05)
    assert p.value == 1.25 and changed == [1.25] and written
    assert app.of("pack")[0]["keys"] == ["SPD_P"]


def test_pairing_and_key(tmp_path):
    dev = Device("Kite-9", kind="drone", state_dir=str(tmp_path))
    dev.connect(wifi=True, port=0)
    app = App(dev, dev.transports[0].port)
    dev.pair("4f7-k2q")
    app.send({"t": "pair", "code": "WRONG-1", "key": "x" * 32})
    app.pump(0.03)
    assert dev.key is None
    app.send({"t": "pair", "code": "4F7-K2Q", "key": "ab" * 16})
    app.pump(0.03)
    assert dev.key == "ab" * 16 and app.of("paired")
    app.send({"t": "hello", "v": 1, "key": "nope"})
    app.pump(0.03)
    assert app.of("hello")[-1]["ok"] is False
    app.send({"t": "hello", "v": 1, "key": "ab" * 16})
    app.pump(0.03)
    assert app.of("hello")[-1]["ok"] is True
    # key survives a restart
    dev.close()
    again = Device("Kite-9", kind="drone", state_dir=str(tmp_path))
    assert again.key == "ab" * 16


def test_discover_reply(pair):
    dev, app = pair
    app.send({"t": "discover"})
    app.pump(0.03, ctl=False)
    ann = app.of("announce")[0]
    assert ann["id"] == "test-1" and ann["kind"] == "rover"


def test_point_cloud(pair):
    dev, app = pair
    app.send({"t": "hello", "v": 1})
    dev.publish("lidar", points=[(1, 2, 3), (-0.5, 0, 0.25)])
    app.pump(0.05)
    pc = app.of("pc")[0]
    assert pc["n"] == 2 and decode_points(pc["d"]) == [[1, 2, 3], [-0.5, 0, 0.25]]


# ---------------------------------------------------------------- radio links
RADIO = json.loads((Path(__file__).resolve().parents[3] / "protocol" / "vectors.json").read_text())["radio"]


def test_radio_profiles_match_vectors():
    from koebelt_link import RADIO_PROFILES

    assert list(RADIO_PROFILES) == [r["id"] for r in RADIO]
    for r in RADIO:
        assert RADIO_PROFILES[r["id"]] == (r["baud"], r["tlm_hz"], r["ctl_hz"])


class LineApp:
    """App side over a socket pair standing in for a radio modem."""

    def __init__(self, dev, sock):
        self.dev, self.sock, self.got, self.buf = dev, sock, [], b""
        sock.setblocking(False)

    def send(self, m):
        self.sock.sendall(encode(m) + b"\n")

    def pump(self, secs, ctl=False):
        end = time.monotonic() + secs
        while time.monotonic() < end:
            if ctl:
                self.send({"t": "ctl", "s": 0, "lx": 0.5, "ly": 0, "rx": 0, "ry": 0})
            self.dev.tick()
            try:
                self.buf += self.sock.recv(65536)
            except BlockingIOError:
                pass
            *lines, self.buf = self.buf.split(b"\n")
            self.got += [decode(x) for x in lines if x]
            time.sleep(0.01)

    def of(self, t):
        return [m for m in self.got if m and m["t"] == t]


def radio_pair(tmp_path, profile, kind="rover"):
    from koebelt_link import SocketTransport

    a, b = socket.socketpair()
    dev = Device("Radio-1", kind=kind, state_dir=str(tmp_path))
    dev.add_transport(SocketTransport(a).use_radio(profile))
    return dev, LineApp(dev, b)


def test_radio_announces_and_caps_rate(tmp_path):
    dev, app = radio_pair(tmp_path, "sik")
    app.pump(1.1)
    assert app.of("announce"), "stream links announce so the app can find the device behind a radio"
    seen = []
    dev.on_control(seen.append)
    app.send({"t": "hello", "v": 1})
    dev.points([(1, 2, 0)])
    t0 = time.monotonic()
    while time.monotonic() - t0 < 1.0:
        dev.imu(0, 0, 9.81, 0, 0, 0)
        dev.position(1, 2, 0)
        app.pump(0.02, ctl=True)
    tl = app.of("tlm")
    assert 4 <= len(tl) <= 6, len(tl)  # SiK: 5 Hz
    assert "imu" in tl[-1]["d"]  # full field set above 2 Hz
    assert not app.of("pc")  # no point clouds over radio
    assert seen and seen[-1].lx == 0.5  # SiK carries control
    dev.close()


def test_telemetry_only_link_takes_stop_but_nothing_else(tmp_path):
    dev, app = radio_pair(tmp_path, "lora", kind="rocket")
    cmds = []
    dev.on_command(lambda c, a: cmds.append(c))
    app.send({"t": "hello", "v": 1})
    app.send({"t": "arm", "v": True})
    app.send({"t": "cmd", "c": "countdown", "a": {"s": 10}})
    for _ in range(30):
        dev.imu(0, 0, 9.81, 0, 0, 0)
        dev.position(0, 0, 120)
        app.pump(0.05, ctl=True)
    assert not dev.armed and not cmds
    tl = app.of("tlm")
    assert tl and all("imu" not in m["d"] for m in tl) and "pos" in tl[-1]["d"]  # compact set at 2 Hz
    app.send({"t": "stop"})
    app.pump(0.1)
    assert dev.estop
    dev.close()


# ---------------------------------------------------------------- video
def test_hello_declares_video_and_mjpeg_server_streams(pair):
    import urllib.request

    from koebelt_link import MjpegServer

    dev, app = pair
    srv = MjpegServer(port=0)
    dev.video(srv.url, label="Front")
    app.send({"t": "hello", "v": 1})
    app.pump(0.05)
    v = app.of("hello")[0]["video"][0]
    assert v == {"id": "cam", "url": f":{srv.port}/stream", "fmt": "mjpeg", "label": "Front"}
    jpeg = b"\xff\xd8" + b"x" * 100 + b"\xff\xd9"
    stop = False

    def feed():
        while not stop:
            srv.push(jpeg)
            time.sleep(0.02)

    import threading

    threading.Thread(target=feed, daemon=True).start()
    r = urllib.request.urlopen(f"http://127.0.0.1:{srv.port}/stream", timeout=3)
    assert "boundary=frame" in r.headers["Content-Type"]
    body = r.read(600)
    assert body.startswith(b"--frame\r\nContent-Type: image/jpeg\r\nContent-Length: 104\r\n\r\n" + jpeg)
    r.close()
    snap = urllib.request.urlopen(f"http://127.0.0.1:{srv.port}/snapshot", timeout=3).read()
    assert snap == jpeg
    stop = True
    srv.close()


def test_shortcuts_cover_every_builtin_channel(pair):
    dev, app = pair
    app.send({"t": "hello", "v": 1})
    dev.attitude(0.1, 0.2, 0.3)
    dev.velocity(1, 0, 0)
    dev.rssi(-60)
    dev.joints([0, 1, 2])
    dev.tool(0.1, 0.2, 0.3, 0.5)
    dev.force_torque(1, 2, 3)
    dev.thrust(10, 0.2)
    dev.rpm(5000)
    dev.temperature(40)
    dev.throttle_out(0.4)
    dev.rocket_state(120, 3.5)
    app.pump(0.1)
    d = {}
    for m in app.of("tlm"):
        d.update(m["d"])
    for k in ("att", "vel", "rssi", "joints", "tool", "ft", "thrust", "rpm", "temp", "throttle", "rocket"):
        assert k in d, k
    assert d["rocket"] == [120.0, 3.5, 0.0]


def test_bluetooth_module_rates_follow_baud(tmp_path):
    from koebelt_link import SocketTransport
    from koebelt_link.protocol import module_rate_hz

    assert [module_rate_hz(b) for b in (9600, 19200, 38400, 57600, 115200)] == [2, 2, 5, 5, 10]
    a, b = socket.socketpair()
    dev = Device("Module-1", kind="rover", state_dir=str(tmp_path))
    dev.add_transport(SocketTransport(a).use_module(9600))
    app = LineApp(dev, b)
    seen = []
    dev.on_control(seen.append)
    app.send({"t": "hello", "v": 1})
    t0 = time.monotonic()
    while time.monotonic() - t0 < 1.0:
        dev.imu(0, 0, 9.81, 0, 0, 0)
        dev.position(1, 2, 0)
        app.pump(0.02, ctl=True)
    tl = app.of("tlm")
    assert 1 <= len(tl) <= 3 and "imu" not in tl[-1]["d"]  # 2 Hz, compact
    assert seen, "modules carry control"
    dev.close()
