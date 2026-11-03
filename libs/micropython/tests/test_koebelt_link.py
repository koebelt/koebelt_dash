"""The MicroPython library, run by CPython: a fake app talks to a Device over
real UDP on localhost and over an in-memory serial line, as the other
libraries' tests do. `mpy-cross` checks it also compiles for MicroPython."""
import json
import os
import socket
import sys
import time
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import koebelt_link as kl  # noqa: E402

VECTORS = json.loads((Path(__file__).resolve().parents[3] / "protocol" / "vectors.json").read_text())


class App:
    """Minimal app side of the protocol, over UDP."""

    def __init__(self, dev, port):
        self.dev, self.addr = dev, ("127.0.0.1", port)
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.sock.bind(("127.0.0.1", 0))
        self.sock.setblocking(False)
        self.got = []

    def send(self, m):
        self.sock.sendto(kl.encode(m), self.addr)

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
                self.got.append(kl.decode(data))
            time.sleep(0.01)

    def of(self, t):
        return [m for m in self.got if m["t"] == t]


class Line:
    """A UART: what the app wrote, and what the device wrote back."""

    def __init__(self):
        self.inbox, self.out = b"", b""

    def any(self):
        return len(self.inbox)

    def read(self, n=None):
        data, self.inbox = self.inbox, b""
        return data

    def write(self, b):
        self.out += b

    def app(self, m):
        self.inbox += kl.encode(m) + b"\n"

    def of(self, t):
        return [m for m in (kl.decode(x) for x in self.out.split(b"\n") if x) if m and m["t"] == t]


@pytest.fixture
def pair(tmp_path):
    dev = kl.Device("Test-1", kind="rover", state_file=str(tmp_path / "state.json"))
    dev.connect(wifi=True, port=0)
    yield dev, App(dev, dev.transports[0].port)
    dev.close()


def test_handshake_telemetry_and_channels(pair):
    dev, app = pair
    dev.body = "tracked"
    dev.param("MAX_SPD", 4, 0.5, 8, unit="m/s")
    temp = dev.channel("motor_temp", ["L", "R"], "C", 10)
    app.send({"t": "hello", "v": 1})
    app.pump(0.05)
    h = app.of("hello")[0]
    assert h["ok"] and h["kind"] == "rover" and h["id"] == "test-1" and h["lib"] == "micropython/" + kl.__version__
    assert "seq" not in h, "sequences run from the app"
    assert h["body"] == "tracked"
    assert app.of("params")[0]["p"][0][:2] == ["MAX_SPD", 4.0]
    assert app.of("chan")[0]["ch"][0]["axes"] == ["L", "R"]
    dev.imu(0, 0, 9.81, 0, 0, 0.1)
    dev.gps(47.1, 8.2, 400, 12)
    temp.publish(40.5, 41)
    app.pump(0.1)
    d = {}
    for m in app.of("tlm"):
        d.update(m["d"])
    assert d["imu"][2] == 9.81 and d["gps"][:2] == [47.1, 8.2] and d["motor_temp"] == [40.5, 41.0]


def test_control_mode_stop_and_reset(pair):
    dev, app = pair
    seen = {"ctl": [], "stop": 0}
    dev.on_control(seen["ctl"].append)
    dev.on_stop(lambda: seen.__setitem__("stop", seen["stop"] + 1))
    app.send({"t": "hello", "v": 1})
    app.send({"t": "arm", "v": True})
    app.send({"t": "mode", "m": "MANUAL"})
    app.send({"t": "ctl", "s": 1, "lx": 0.5, "ly": 0, "rx": 0, "ry": -1})
    app.pump(0.05, ctl=False)
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
    dev.failsafe(timeout=0.2)
    app.send({"t": "hello", "v": 1})
    app.send({"t": "arm", "v": True})
    app.send({"t": "mode", "m": "MANUAL"})
    app.pump(0.1)
    assert not dev.failsafe_active
    app.pump(0.4, ctl=False)
    assert dev.failsafe_active and dev.mode == "HOLD"
    app.pump(0.05)
    assert not dev.failsafe_active


def test_params_written_and_kept(tmp_path):
    f = str(tmp_path / "state.json")
    dev = kl.Device("Kite-9", kind="drone", state_file=f)
    dev.connect(wifi=True, port=0)
    app = App(dev, dev.transports[0].port)
    p = dev.param("RATE_P", 0.8, 0, 3.2)
    app.send({"t": "hello", "v": 1})
    app.send({"t": "pset", "p": {"RATE_P": 1.25, "NOPE": 3}})
    app.pump(0.05)
    assert p.value == 1.25 and app.of("pack")[0]["keys"] == ["RATE_P"]
    app.send({"t": "psave"})
    app.pump(0.03)
    dev.close()
    again = kl.Device("Kite-9", kind="drone", state_file=f)
    assert again.param("RATE_P", 0.8, 0, 3.2).value == 1.25


def test_pairing_discovery_and_key(tmp_path):
    f = str(tmp_path / "state.json")
    dev = kl.Device("Kite-9", kind="plane", state_file=f)
    dev.connect(wifi=True, port=0)
    app = App(dev, dev.transports[0].port)
    dev.pair("4f7-k2q")
    app.send({"t": "discover"})
    app.pump(0.2, ctl=False)
    ann = app.of("announce")[0]
    assert ann["kind"] == "plane" and ann["pair"] == "4F7-K2Q"
    app.send({"t": "pair", "code": "4F7-K2Q", "key": "ab" * 16})
    app.pump(0.03)
    assert dev.key == "ab" * 16 and app.of("paired")
    app.send({"t": "hello", "v": 1, "key": "nope"})
    app.pump(0.03)
    assert app.of("hello")[-1]["ok"] is False
    app.send({"t": "hello", "v": 1, "key": "ab" * 16})
    app.pump(0.03)
    assert app.of("hello")[-1]["ok"] is True
    dev.close()
    assert kl.Device("Kite-9", kind="plane", state_file=f).key == "ab" * 16


def test_radio_profiles_match_vectors():
    want = {r["id"]: (r["baud"], r["tlm_hz"], r["ctl_hz"]) for r in VECTORS["radio"]}
    assert kl.RADIO_PROFILES == want


def test_serial_radio_announces_and_telemetry_only_takes_stop(tmp_path):
    line = Line()
    dev = kl.Device("Nova", kind="rocket", state_file=str(tmp_path / "s.json"))
    dev.connect(radio=(line, "lora"))
    dev.tick()
    assert line.of("announce"), "found behind a radio before pairing"
    line.app({"t": "hello", "v": 1})
    line.app({"t": "arm", "v": True})
    for _ in range(5):
        dev.tick()
        time.sleep(0.02)
    assert line.of("hello") and not dev.armed, "telemetry-only: no arming"
    line.app({"t": "stop"})
    dev.tick()
    assert dev.estop
    dev.position(1, 2, 300)
    dev.imu(0, 0, 9.81, 0, 0, 0)
    dev.rocket_state(310, 12)
    line.out = b""
    for _ in range(40):
        dev.tick()
        time.sleep(0.03)
    tl = line.of("tlm")
    assert 1 <= len(tl) <= 4, "2 Hz on LoRa"
    assert "imu" not in tl[0]["d"] and "pos" in tl[0]["d"], "only the compact fields"


def test_kinds_and_bad_input():
    assert "plane" in kl.KINDS and "boat" in kl.KINDS and "legged" in kl.KINDS
    with pytest.raises(ValueError):
        kl.Device("X", kind="submarine")
    with pytest.raises(ValueError):
        kl.Device("X", kind="rover", body="hexa")
    assert kl.decode(b"not json") is None and kl.decode(b'{"no":"t"}') is None
    assert kl._slug("Mule 3 / Front!") == "mule-3-front"


def test_compiles_for_micropython(tmp_path):
    mpy = pytest.importorskip("mpy_cross")
    src = Path(kl.__file__)
    out = tmp_path / "koebelt_link.mpy"
    r = mpy.run(str(src), "-o", str(out))
    r.wait()
    assert r.returncode == 0 and out.exists() and os.path.getsize(out) > 1000
