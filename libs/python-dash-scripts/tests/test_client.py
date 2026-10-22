"""The client against a stand-in for koebelt dash's script API (protocol/SCRIPTS.md)."""
import json
import threading
import time

import pytest
from websockets.sync.server import serve

import koebelt_dash_scripts as k
from koebelt_dash_scripts import client


class FakeDash:
    """Answers like dash: token check, use, sticks, commands; telemetry at 20 Hz."""

    def __init__(self, token="t0ken"):
        self.token = token
        self.got = []
        self.conn = None
        self.refuse_sticks = None
        self.server = serve(self._handle, "127.0.0.1", 0)
        self.url = f"ws://127.0.0.1:{self.server.socket.getsockname()[1]}/scripts"
        threading.Thread(target=self.server.serve_forever, daemon=True).start()

    def send(self, m):
        self.conn.send(json.dumps(m))

    def _handle(self, ws):
        hello = json.loads(ws.recv())
        if hello.get("token") != self.token:
            ws.send(json.dumps({"t": "bye", "why": "Wrong or missing token."}))
            return
        self.conn = ws
        self.hello = hello
        ws.send(json.dumps({"t": "welcome", "v": 1, "app": "1.3.0", "devices": []}))
        stop = threading.Event()

        def tlm():
            while not stop.wait(0.05):
                try:
                    ws.send(json.dumps({"t": "tlm", "d": {"pos": [1, 2, 3], "mode": "AUTO", "armed": True, "battery": 80}}))
                except Exception:
                    return
        threading.Thread(target=tlm, daemon=True).start()
        try:
            for raw in ws:
                m = json.loads(raw)
                self.got.append(m)
                if "id" not in m:
                    continue
                res = {"t": "res", "id": m["id"], "ok": True}
                if m["t"] == "use":
                    res["value"] = {"id": "sim-mule", "name": "Mule", "kind": "rover", "sim": True}
                elif m["t"] == "setting":
                    res["value"] = 0.7 if m["name"] == "kept" else m["value"]
                elif m["t"] == "sticks" and self.refuse_sticks:
                    res = {"t": "res", "id": m["id"], "ok": False, "err": self.refuse_sticks}
                elif m["t"] == "cmd" and m["c"] == "arm":
                    res = {"t": "res", "id": m["id"], "ok": False, "err": "Arming is not allowed for this script (Limits in dash)."}
                elif m["t"] == "cmd" and m["c"] == "params":
                    res["value"] = {"MAX_SPD": 2.0}
                ws.send(json.dumps(res))
        finally:
            stop.set()

    def close(self):
        self.server.shutdown()


@pytest.fixture
def dash(tmp_path, monkeypatch):
    d = FakeDash()
    monkeypatch.setattr(client, "DISCOVERY", tmp_path / "dash-api.json")
    (tmp_path / "dash-api.json").write_text(json.dumps({"url": d.url, "token": d.token}))
    monkeypatch.delenv("KOEBELT_DASH_URL", raising=False)
    monkeypatch.delenv("KOEBELT_DASH_TOKEN", raising=False)
    yield d
    d.close()


def wait_for(cond, timeout=2.0):
    end = time.monotonic() + timeout
    while time.monotonic() < end:
        if cond():
            return True
        time.sleep(0.01)
    return False


def test_finds_dash_and_uses_the_selected_device(dash):
    dev = k.connect(name="test.py")
    assert dash.hello["name"] == "test.py" and dash.hello["v"] == 1
    assert (dev.name, dev.kind, dev.simulated) == ("Mule", "rover", True)
    assert dev.tlm.alt == 3 and dev.tlm.mode == "AUTO" and dev.tlm.battery == 80
    with pytest.raises(AttributeError, match="sends no 'lidar'"):
        dev.tlm.lidar
    dev.close()


def test_environment_wins_over_the_discovery_file(dash, monkeypatch):
    monkeypatch.setenv("KOEBELT_DASH_URL", dash.url)
    monkeypatch.setenv("KOEBELT_DASH_TOKEN", "wrong")
    with pytest.raises(k.ScriptError, match="token"):
        k.connect()


def test_no_dash_running(tmp_path, monkeypatch):
    monkeypatch.setattr(client, "DISCOVERY", tmp_path / "none.json")
    monkeypatch.delenv("KOEBELT_DASH_URL", raising=False)
    with pytest.raises(k.ScriptError, match="not running"):
        k.connect()


def test_commands_and_refusals(dash):
    dev = k.connect()
    dev.sticks(throttle=0.5, steer=-0.2)
    assert dash.got[-1]["t"] == "sticks" and dash.got[-1]["a"] == {"throttle": 0.5, "steer": -0.2}
    dev.mode("hold")
    assert dash.got[-1] == {"t": "cmd", "id": dash.got[-1]["id"], "c": "mode", "a": {"m": "hold"}}
    with pytest.raises(k.ScriptError, match="not allowed"):
        dev.arm()
    assert dev.params["MAX_SPD"] == 2.0
    with pytest.raises(KeyError, match="MAX_SPD"):
        dev.params["NOPE"]
    dev.close()


def test_settings_keep_the_operators_value_and_follow_changes(dash):
    dev = k.connect()
    assert dev.setting("speed", 0.4, min=0, max=1).value == 0.4
    kept = dev.setting("kept", 0.4)
    assert kept.value == 0.7
    dash.send({"t": "setting", "name": "kept", "value": 0.9})
    assert wait_for(lambda: kept.value == 0.9)
    dev.close()


def test_triggers_run_their_handlers(dash):
    dev = k.connect()
    fired = []

    @dev.trigger("Drop payload", key="D")
    def drop():
        fired.append("drop")

    @dev.trigger("Patrol", kind="switch")
    def patrol(on):
        fired.append(("patrol", on))

    @dev.on_trigger
    def other(name, value):
        fired.append((name, value))

    assert {m["name"] for m in dash.got if m["t"] == "trigger"} == {"Drop payload", "Patrol"}
    dash.send({"t": "fire", "name": "Drop payload"})
    dash.send({"t": "fire", "name": "Patrol", "value": True})
    dash.send({"t": "fire", "name": "Low battery", "value": True})
    assert wait_for(lambda: len(fired) == 3)
    assert fired == ["drop", ("patrol", True), ("Low battery", True)]
    dev.close()


def test_a_handler_that_raises_does_not_stop_the_others(dash, capsys):
    dev = k.connect()

    @dev.trigger("Bad")
    def bad():
        raise ValueError("oops")

    seen = []

    @dev.trigger("Good")
    def good():
        seen.append(1)

    dash.send({"t": "fire", "name": "Bad"})
    dash.send({"t": "fire", "name": "Good"})
    assert wait_for(lambda: seen)
    assert "ValueError: oops" in capsys.readouterr().err
    dev.close()


def test_released_and_takeover(dash):
    dev = k.connect()
    stopped, takeovers = [], []
    dev.on_stop(lambda: stopped.append(1))
    dev.on_takeover(takeovers.append)
    dash.send({"t": "takeover", "on": True})
    assert wait_for(lambda: dev.taken_over and takeovers == [True])
    dash.send({"t": "released", "why": "Mule left the 50 m geofence: it holds."})
    assert wait_for(lambda: stopped and dev.released)
    dash.refuse_sticks = "Mule left the 50 m geofence: it holds. The operator must resume the script in dash."
    with pytest.raises(k.Released, match="resume"):
        dev.sticks(throttle=1)
    dash.send({"t": "resumed"})
    assert wait_for(lambda: dev.released is None)
    dev.close()


def test_keepalives_carry_the_loop_rate(dash):
    dev = k.connect()
    for i in k.every(0.02):
        if i == 15:
            break
    assert wait_for(lambda: any(m["t"] == "ka" and "hz" in m for m in dash.got))
    hz = [m["hz"] for m in dash.got if m["t"] == "ka" and "hz" in m][-1]
    assert 30 < hz < 70
    dev.close()


def test_store_survives_a_restart(dash):
    dev = k.connect(name="store test.py")
    dev.store["runs"] = dev.store.get("runs", 0) + 1
    dev.close()
    dev = k.connect(name="store test.py")
    assert dev.store["runs"] == 1
    dev.close()
