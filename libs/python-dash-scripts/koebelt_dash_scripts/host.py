"""A script host: runs scripts for koebelt dash on a phone or tablet.

    koebelt-dash-scripts host

Phones cannot run Python with machine learning, so they send their scripts
here. The script runs in this computer's Python and connects back to dash on
the phone, which keeps the device link, the operator's sticks and STOP.

The phone finds the host on the local network (or is given its address),
and pairs once with the code the host prints. Messages are in
protocol/SCRIPTS.md (Script hosts).
"""
from __future__ import annotations

import argparse
import base64
import json
import os
import pathlib
import secrets
import shutil
import socket
import subprocess
import sys
import tempfile
import threading
import time
from typing import Dict, Optional

from websockets.exceptions import ConnectionClosed
from websockets.sync.server import serve

from . import __version__

HOST_PORT = 47921
DISCOVERY_PORT = 47922
CONFIG = pathlib.Path.home() / ".koebelt" / "script-host.json"


def _load() -> dict:
    try:
        return json.loads(CONFIG.read_text())
    except (OSError, ValueError):
        return {}


def _save(cfg: dict) -> None:
    CONFIG.parent.mkdir(parents=True, exist_ok=True)
    CONFIG.write_text(json.dumps(cfg, indent=1))
    try:
        CONFIG.chmod(0o600)
    except OSError:
        pass


def _python_version(python: str) -> str:
    try:
        out = subprocess.run([python, "-c", "import sys; print(sys.version.split()[0])"], capture_output=True, text=True, timeout=10)
        return out.stdout.strip() or "?"
    except Exception:
        return "?"


class Host:
    """Pairs phones and runs their scripts."""

    def __init__(self, name: Optional[str] = None, port: int = HOST_PORT, python: Optional[str] = None,
                 discovery: bool = True, say=print, discovery_port: int = DISCOVERY_PORT):
        self.cfg = _load()
        self.name = name or self.cfg.get("name") or socket.gethostname().split(".")[0]
        self.port = port
        self.python = python or sys.executable
        self.version = _python_version(self.python)
        self.discovery = discovery
        self.discovery_port = discovery_port
        self.say = say
        self.ready = threading.Event()
        self.code = self._new_code()
        self.runs: Dict[str, "_Run"] = {}
        self._server = None

    @staticmethod
    def _new_code() -> str:
        alphabet = "ABCDEFGHJKMNPQRSTUVWXYZ23456789"
        return "".join(secrets.choice(alphabet) for _ in range(3)) + "-" + "".join(secrets.choice(alphabet) for _ in range(3))

    @property
    def tokens(self) -> Dict[str, str]:
        """Paired phones: token → their name."""
        return self.cfg.setdefault("paired", {})

    def info(self) -> dict:
        return {"t": "host", "v": 1, "name": self.name, "port": self.port, "python": self.version, "pkg": __version__}

    # ------------------------------------------------------------- discovery
    def _discovery(self) -> None:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        try:
            s.bind(("", self.discovery_port))
        except OSError as e:
            self.say(f"Discovery is off (port {self.discovery_port}: {e}); phones can still use this computer's address.")
            return
        while True:
            try:
                data, addr = s.recvfrom(2048)
                if json.loads(data).get("t") == "hostdiscover":
                    s.sendto(json.dumps(self.info()).encode(), addr)
            except Exception:
                continue

    # ------------------------------------------------------------- sessions
    def _handle(self, ws) -> None:
        peer = ws.remote_address[0] if ws.remote_address else "?"
        try:
            hello = json.loads(ws.recv(timeout=10))
        except Exception:
            return
        t = hello.get("t")
        if t == "pair":
            if str(hello.get("code", "")).upper().replace(" ", "") != self.code:
                ws.send(json.dumps({"t": "bye", "why": "Wrong pairing code."}))
                return
            token = secrets.token_hex(16)
            self.tokens[token] = str(hello.get("name") or peer)
            _save(self.cfg)
            self.code = self._new_code()
            self.say(f"Paired with {self.tokens[token]}. Next pairing code: {self.code}")
            ws.send(json.dumps({**self.info(), "t": "paired", "token": token}))
            return
        if t != "hello" or hello.get("token") not in self.tokens:
            ws.send(json.dumps({"t": "bye", "why": "Not paired with this host: pair again with its code."}))
            return
        who = self.tokens[hello["token"]]
        ws.send(json.dumps({**self.info(), "t": "welcome"}))
        run: Optional[_Run] = None
        try:
            for raw in ws:
                m = json.loads(raw)
                if m.get("t") == "run" and run is None:
                    run = _Run(self, ws, m, peer)
                    self.say(f"{who}: running {m.get('name', 'a script')}")
                    run.start()
                elif m.get("t") == "stop" and run is not None:
                    run.stop()
        except ConnectionClosed:
            pass
        finally:
            # The phone went away: its script cannot reach dash any more anyway.
            if run is not None:
                run.stop()

    def serve(self) -> None:
        if self.discovery:
            threading.Thread(target=self._discovery, daemon=True).start()
        with serve(self._handle, "0.0.0.0", self.port, max_size=None) as server:
            self._server = server
            self.port = server.socket.getsockname()[1]
            self.ready.set()
            server.serve_forever()

    def shutdown(self) -> None:
        if self._server is not None:
            self._server.shutdown()


class _Run:
    """One script a phone runs here."""

    def __init__(self, host: Host, ws, m: dict, peer: str):
        self.host, self.ws, self.m = host, ws, m
        self.dir = pathlib.Path(tempfile.mkdtemp(prefix="koebelt-script-"))
        self.proc: Optional[subprocess.Popen] = None
        self.lock = threading.Lock()
        # dash on the phone, as this computer reaches it.
        self.dash = f"ws://{m.get('dashHost') or peer}:{int(m['dashPort'])}/scripts"

    def _send(self, msg: dict) -> None:
        with self.lock:
            try:
                self.ws.send(json.dumps(msg))
            except Exception:
                pass

    def start(self) -> None:
        main = None
        for rel, b64 in self.m.get("files", {}).items():
            path = (self.dir / rel).resolve()
            if self.dir.resolve() not in path.parents:
                continue
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(base64.b64decode(b64))
            if rel == self.m.get("main", "main.py"):
                main = path
        if main is None:
            self._send({"t": "out", "level": "err", "text": "The script's file is missing."})
            self._send({"t": "exit", "code": 1})
            return
        env = dict(os.environ, KOEBELT_DASH_URL=self.dash, KOEBELT_DASH_TOKEN=self.m["dashToken"], PYTHONUNBUFFERED="1",
                   PYTHONIOENCODING="utf-8")
        self.proc = subprocess.Popen([self.host.python, "-u", str(main)], cwd=self.dir, env=env, stdout=subprocess.PIPE,
                                     stderr=subprocess.PIPE, text=True, encoding="utf-8", errors="replace")
        self._send({"t": "started", "pid": self.proc.pid, "python": self.host.version})
        for stream, level in ((self.proc.stdout, "out"), (self.proc.stderr, "err")):
            threading.Thread(target=self._pump, args=(stream, level), daemon=True).start()
        threading.Thread(target=self._wait, daemon=True).start()

    def _pump(self, stream, level: str) -> None:
        for line in stream:
            self._send({"t": "out", "level": level, "text": line.rstrip("\n")})

    def _wait(self) -> None:
        code = self.proc.wait()
        time.sleep(0.2)  # let the last lines out first
        self._send({"t": "exit", "code": code})
        shutil.rmtree(self.dir, ignore_errors=True)

    def stop(self) -> None:
        p = self.proc
        if p is None or p.poll() is not None:
            return
        p.terminate()
        try:
            p.wait(2)
        except subprocess.TimeoutExpired:
            p.kill()


def main(argv=None) -> None:
    ap = argparse.ArgumentParser(prog="koebelt-dash-scripts host", description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--name", help="the name phones see (default: this computer's)")
    ap.add_argument("--port", type=int, default=HOST_PORT)
    ap.add_argument("--python", help="the Python scripts run with (default: this one)")
    ap.add_argument("--no-discovery", action="store_true", help="do not answer phones looking for hosts")
    ap.add_argument("--forget", action="store_true", help="unpair every phone, then exit")
    a = ap.parse_args(argv)
    if a.forget:
        cfg = _load()
        cfg["paired"] = {}
        _save(cfg)
        print("Every phone is unpaired.")
        return
    h = Host(name=a.name, port=a.port, python=a.python, discovery=not a.no_discovery)
    if a.name:
        h.cfg["name"] = a.name
        _save(h.cfg)
    print(f"koebelt dash script host “{h.name}”, port {h.port}, Python {h.version}")
    print(f"Pairing code: {h.code}   (in koebelt dash: Scripts > Script host > Pair)")
    print(f"Paired phones: {len(h.tokens)}. Ctrl-C to stop.", flush=True)
    try:
        h.serve()
    except KeyboardInterrupt:
        pass


def cli(argv=None) -> None:
    """`koebelt-dash-scripts <command>`."""
    argv = sys.argv[1:] if argv is None else argv
    if not argv or argv[0] in ("-h", "--help"):
        print("usage: koebelt-dash-scripts host [--name NAME] [--port PORT] [--python PATH] [--forget]")
        print("       koebelt-dash-scripts --version")
        return
    if argv[0] == "--version":
        print(__version__)
        return
    if argv[0] == "host":
        return main(argv[1:])
    sys.exit(f"unknown command: {argv[0]}")
