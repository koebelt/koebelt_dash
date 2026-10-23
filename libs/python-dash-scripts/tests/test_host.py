"""The script host, with a stand-in for a phone."""
import base64
import json
import socket
import threading

import pytest
from websockets.sync.client import connect

from koebelt_dash_scripts import host as hostmod


@pytest.fixture
def host(tmp_path, monkeypatch):
    monkeypatch.setattr(hostmod, "CONFIG", tmp_path / "script-host.json")
    h = hostmod.Host(name="Bench PC", port=0, discovery=True, discovery_port=0, say=lambda *_: None)
    threading.Thread(target=h.serve, daemon=True).start()
    assert h.ready.wait(5)
    yield h
    h.shutdown()


def ws(h):
    return connect(f"ws://127.0.0.1:{h.port}/host").__enter__()


def pair(h) -> str:
    with ws(h) as c:
        c.send(json.dumps({"t": "pair", "code": h.code.lower(), "name": "Thomas’s iPhone"}))
        m = json.loads(c.recv(timeout=5))
    assert m["t"] == "paired" and m["name"] == "Bench PC"
    return m["token"]


def test_pairing_needs_the_code_and_changes_it(host):
    with ws(host) as c:
        c.send(json.dumps({"t": "pair", "code": "AAA-AAA"}))
        assert json.loads(c.recv(timeout=5))["why"] == "Wrong pairing code."
    first = host.code
    token = pair(host)
    assert host.code != first, "a code pairs once"
    assert host.tokens[token] == "Thomas’s iPhone"
    assert json.loads(hostmod.CONFIG.read_text())["paired"][token] == "Thomas’s iPhone", "kept across restarts"


def test_an_unpaired_phone_is_turned_away(host):
    with ws(host) as c:
        c.send(json.dumps({"t": "hello", "token": "nope"}))
        assert "pair again" in json.loads(c.recv(timeout=5))["why"]


def run(host, files, main="main.py", stop_after=None):
    token = pair(host)
    got = []
    with ws(host) as c:
        c.send(json.dumps({"t": "hello", "token": token}))
        assert json.loads(c.recv(timeout=5))["t"] == "welcome"
        c.send(json.dumps({"t": "run", "name": "test", "main": main, "dashPort": 47920, "dashToken": "run-token",
                           "files": {k: base64.b64encode(v.encode()).decode() for k, v in files.items()}}))
        while True:
            m = json.loads(c.recv(timeout=10))
            got.append(m)
            if stop_after and any(x.get("text") == stop_after for x in got) and not any(x["t"] == "stop-sent" for x in got):
                c.send(json.dumps({"t": "stop"}))
                got.append({"t": "stop-sent"})
            if m["t"] == "exit":
                return got


def test_runs_a_script_with_its_files_pointing_it_at_dash_on_the_phone(host):
    got = run(host, {
        "main.py": "import os, json\nprint(open('data/config.json').read())\nprint(os.environ['KOEBELT_DASH_URL'], os.environ['KOEBELT_DASH_TOKEN'])\n",
        "data/config.json": '{"speed": 2}',
        "../escape.py": "print('no')",
    })
    out = [m["text"] for m in got if m["t"] == "out"]
    assert out == ['{"speed": 2}', "ws://127.0.0.1:47920/scripts run-token"], "dash's address as the host sees the phone"
    assert got[0]["t"] == "started" and got[-1] == {"t": "exit", "code": 0}


def test_errors_and_stop(host):
    got = run(host, {"main.py": "raise ValueError('oops')"})
    assert any("ValueError: oops" in m.get("text", "") for m in got)
    assert got[-1]["code"] == 1
    got = run(host, {"main.py": "import time\nprint('up', flush=True)\ntime.sleep(60)"}, stop_after="up")
    assert got[-1]["t"] == "exit" and got[-1]["code"] != 0


def test_answers_phones_looking_for_hosts(tmp_path, monkeypatch):
    monkeypatch.setattr(hostmod, "CONFIG", tmp_path / "script-host.json")
    probe = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    probe.bind(("127.0.0.1", 0))
    free = probe.getsockname()[1]
    probe.close()
    h = hostmod.Host(name="Bench PC", port=0, discovery_port=free, say=lambda *_: None)
    threading.Thread(target=h.serve, daemon=True).start()
    assert h.ready.wait(5)
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.settimeout(2)
    for _ in range(20):
        s.sendto(json.dumps({"t": "hostdiscover"}).encode(), ("127.0.0.1", free))
        try:
            m = json.loads(s.recv(2048))
            break
        except socket.timeout:
            continue
    assert m["t"] == "host" and m["name"] == "Bench PC" and m["port"] == h.port
    h.shutdown()
