"""Sequences stored on and run by the device: the shared scenario in
protocol/vectors.json, link loss, pause / resume / stop."""
import json
from pathlib import Path

import pytest

from koebelt_link import Device
from koebelt_link.protocol import decode

from test_device import App

SEQ = json.loads((Path(__file__).resolve().parents[3] / "protocol" / "vectors.json").read_text())["sequence"]


@pytest.fixture
def drone(tmp_path):
    """A drone whose handlers move it like a very fast vehicle."""
    dev = Device("Seq-1", kind="drone", state_dir=str(tmp_path))
    dev.connect(wifi=True, port=0)
    app = App(dev, dev.transports[0].port)
    calls = []
    pos = [0.0, 0.0, 0.0]

    @dev.on_arm
    def _(v):
        calls.append(["arm", "", {"v": v}])

    @dev.on_mode
    def _(m):
        calls.append(["mode", m, {}])
        if m == "LAND":
            pos[2] = 0.0
            dev.set_armed(False)

    @dev.on_command
    def _(c, a):
        calls.append(["cmd", c, a])
        if c == "takeoff":
            pos[2] = a["alt"]
            dev.set_mode("HOLD")
        elif c == "goto":
            pos[:] = [a["x"], a["y"], a.get("z", pos[2])]

    def loop():
        dev.position(*pos)

    yield dev, app, calls, loop
    dev.close()


def run(dev, app, loop, secs, ctl=True):
    import time

    end = time.monotonic() + secs
    while time.monotonic() < end:
        loop()
        app.pump(0.02, ctl=ctl)


def last_run(app):
    runs = [m["ext"]["run"] for m in app.of("state") if "run" in m.get("ext", {})]
    return runs[-1] if runs else None


def test_hello_advertises_stored_sequences(drone):
    dev, app, _, loop = drone
    app.send({"t": "hello", "v": 1})
    run(dev, app, loop, 0.1)
    assert app.of("hello")[0]["seq"] == 64


def test_shared_scenario_runs_through_a_lost_link(drone):
    dev, app, calls, loop = drone
    app.send({"t": "hello", "v": 1})
    run(dev, app, loop, 0.1)
    app.send(decode(SEQ["upload"]))
    run(dev, app, loop, 0.1)
    assert app.of("seqack")[-1] == {"t": "seqack", "id": "q1", "ok": True}
    app.send(decode(SEQ["run"]))
    # No control heartbeat from here on: the failsafe would switch to HOLD
    # after 1.8 s. The stored sequence must not be interrupted.
    run(dev, app, loop, 3.0, ctl=False)
    r = last_run(app)
    assert r["st"] == "done", r
    assert r["i"] == SEQ["steps"]
    assert dev.speed == 0.5
    # Only once the sequence is over does the lost link trip the failsafe.
    want = [c for c in SEQ["calls"] if c[0] != "speed"]
    assert calls[: len(want)] == want


def test_refuses_steps_it_cannot_run(drone):
    dev, app, _, loop = drone
    app.send({"t": "hello", "v": 1})
    run(dev, app, loop, 0.1)
    app.send(decode(SEQ["reject"]))
    run(dev, app, loop, 0.1)
    ack = app.of("seqack")[-1]
    assert ack["ok"] is False and "fly_upside_down" in ack["err"]


def test_pause_resume_stop_and_estop(drone):
    dev, app, _, loop = drone
    app.send({"t": "hello", "v": 1})
    app.send({"t": "seq", "id": "w", "steps": [["wait", {"s": 30}]]})
    app.send({"t": "seqrun", "id": "w"})
    run(dev, app, loop, 0.7)  # state goes out at 2 Hz
    assert last_run(app)["st"] == "run"
    assert 0 < last_run(app).get("p", 0) < 1
    app.send({"t": "seqctl", "c": "pause"})
    run(dev, app, loop, 0.2)
    assert last_run(app)["st"] == "pause"
    app.send({"t": "seqctl", "c": "resume"})
    run(dev, app, loop, 0.2)
    assert last_run(app)["st"] == "run"
    app.send({"t": "stop"})
    run(dev, app, loop, 0.2)
    assert last_run(app)["st"] == "fail"
    assert "emergency" in last_run(app)["msg"]
