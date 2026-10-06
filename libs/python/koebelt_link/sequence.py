"""Sequences stored on and run by the device (PROTOCOL.md, "Sequences").

The app uploads the steps with `seq`; the device runs them with the same
handlers the app's messages reach and checks completion against its own
telemetry, so a sequence keeps going when the link drops.
"""
import math
from typing import Any, Dict, List, Optional

#: The most steps a device stores (advertised in `hello` as "seq").
MAX_STEPS = 64

#: Step types each kind of device runs; the rest are refused at upload.
_COMMON = {"wait", "mode", "arm", "speed", "cmd"}
STEP_TYPES = {
    "drone": _COMMON | {"takeoff", "goto", "land", "rth"},
    "rover": _COMMON | {"goto"},
    "arm": _COMMON | {"pose", "home", "gripper"},
    "bench": {"wait", "arm", "cmd", "throttle", "ramp"},
    "rocket": {"wait", "arm", "cmd"},
    "generic": _COMMON,
}


def validate(kind: str, steps: Any) -> Optional[str]:
    """The reason a `seq` upload is refused, or None."""
    if not isinstance(steps, list) or not steps:
        return "No steps"
    if len(steps) > MAX_STEPS:
        return f"Too many steps: this device stores {MAX_STEPS}"
    for w in steps:
        typ = w[0] if isinstance(w, list) and w else None
        if typ not in STEP_TYPES.get(kind, _COMMON):
            return f'Step "{typ}" is not supported on this device'
    return None


class Runner:
    """Runs uploaded steps. `host` is the Device: it provides `mode`,
    `armed`, `estop`, `latest` telemetry and the handlers."""

    def __init__(self, host: Any, seq_id: str, steps: List[list]):
        self.host, self.id = host, seq_id
        self.steps = [(str(w[0]), dict(w[1]) if len(w) > 1 and isinstance(w[1], dict) else {}) for w in steps]
        self.state = "run"  # run | pause | done | fail
        self.index = 0
        self.msg = ""
        self.step_t = self.total_t = 0.0
        self._entered = False
        self._last_thr = -1.0
        self._send_acc = self._still = 0.0
        self._last_joints: List[float] = []

    @property
    def active(self) -> bool:
        return self.state in ("run", "pause")

    def progress(self) -> Optional[float]:
        if self.index >= len(self.steps):
            return None
        typ, a = self.steps[self.index]
        d = {"wait": a.get("s"), "throttle": a.get("s"), "ramp": a.get("s"), "gripper": 0.8}.get(typ)
        if not d or d <= 0:
            return None
        return max(0.0, min(1.0, self.step_t / float(d)))

    def report(self) -> Dict[str, Any]:
        r: Dict[str, Any] = {"id": self.id, "i": self.index, "n": len(self.steps), "st": self.state}
        if self.msg:
            r["msg"] = self.msg
        p = self.progress() if self.state in ("run", "pause") else None
        if p is not None:
            r["p"] = round(p, 2)
        return r

    # ---------------------------------------------------------------- control
    def pause(self) -> None:
        if self.state != "run":
            return
        self.state, self.msg = "pause", "Paused"
        typ = self.steps[self.index][0] if self.index < len(self.steps) else ""
        if typ in ("throttle", "ramp"):
            self.host._run_cmd("throttle", {"v": 0})
        elif self.host.kind in ("drone", "rover") and self.host.armed:
            self.host._run_mode("HOLD")

    def resume(self) -> None:
        if self.state != "pause":
            return
        self.state, self.msg = "run", ""
        self._entered = False  # re-issue the current step
        self.step_t = 0.0

    def stop(self, why: str) -> None:
        if not self.active:
            return
        self.state, self.msg = "fail", why
        if self.host.kind == "bench":
            self.host._run_cmd("throttle", {"v": 0})
        if self.host.kind in ("drone", "rover") and self.host.armed and not self.host.estop:
            self.host._run_mode("HOLD")

    # ---------------------------------------------------------------- loop
    def tick(self, dt: float) -> None:
        if self.state != "run":
            return
        if self.host.estop:
            return self.stop("Stopped: emergency stop")
        if self.index >= len(self.steps):
            self.state, self.msg = "done", f"Completed in {self.total_t:.1f} s"
            return
        typ, a = self.steps[self.index]
        self.total_t += dt
        if not self._entered:
            self._entered = True
            self.step_t = 0.0
            self._last_thr = -1.0
            self._enter(typ, a)
        self.step_t += dt
        r = self._check(typ, a, dt)
        if r is True:
            self.index += 1
            self._entered = False
            self.msg = ""
        elif r is None:
            self.stop(f"Step {self.index + 1} timed out: {typ}")

    def _enter(self, typ: str, a: Dict[str, Any]) -> None:
        h = self.host
        if typ in ("takeoff", "goto", "pose", "home", "gripper"):
            h._run_cmd(typ, a)
        elif typ == "throttle":
            h._run_cmd("throttle", {"v": a.get("v", 0)})
        elif typ == "land":
            h._run_mode("LAND")
        elif typ == "rth":
            h._run_mode("RTH")
        elif typ == "mode":
            h._run_mode(str(a.get("m", "")))
        elif typ == "arm":
            h._run_arm(bool(a.get("v")))
        elif typ == "speed":
            h.speed = max(0.1, min(1.0, float(a.get("v", 0.5))))
        elif typ == "cmd" and a.get("c"):
            h._run_cmd(str(a["c"]), a.get("a") or {})

    def _check(self, typ: str, a: Dict[str, Any], dt: float) -> Optional[bool]:
        h, t = self.host, self.step_t

        def within(limit: float, ok: bool) -> Optional[bool]:
            return True if ok else (None if t > limit else False)

        def n(k: str, d: float = 0.0) -> float:
            return float(a.get(k, d))

        p = (h.latest.get("pos") or [0.0, 0.0, 0.0]) + [0.0, 0.0, 0.0]
        if typ == "wait":
            return t >= n("s")
        if typ == "takeoff":
            return within(60, t > 0.3 and h.mode != "TAKEOFF" and p[2] > n("alt", 6) - 0.6)
        if typ == "goto":
            dx, dy = p[0] - n("x"), p[1] - n("y")
            drone = h.kind == "drone"
            dist = math.sqrt(dx * dx + dy * dy + ((p[2] - n("z", 8)) ** 2 if drone else 0.0))
            self.msg = f"{dist:.1f} m to go"
            return within(300, dist < (1.0 if drone else 0.6))
        if typ in ("land", "rth"):
            return within(300, t > 0.5 and (not h.armed or (p[2] < 0.1 and h.mode not in ("LAND", "RTH"))))
        if typ == "pose":
            target = list(a.get("j") or [])
            j = h.latest.get("joints") or []
            err = max((abs(float(j[i]) - float(target[i])) for i in range(min(6, len(j), len(target)))), default=0.0)
            return within(60, t > 0.2 and err < 0.03)
        if typ == "home":
            j = list(h.latest.get("joints") or [])
            moved = max((abs(j[i] - self._last_joints[i]) for i in range(min(6, len(j), len(self._last_joints)))), default=0.0)
            self._last_joints = j
            self._still = self._still + dt if moved < 2e-4 else 0.0
            return within(60, t > 0.6 and self._still > 0.4)
        if typ == "gripper":
            return t >= 0.8
        if typ == "throttle":
            return t >= n("s")
        if typ == "ramp":
            d = max(0.001, n("s"))
            k = max(0.0, min(1.0, t / d))
            thr = n("from") + (n("to") - n("from")) * k
            self._send_acc += dt
            if self._send_acc >= 0.1 and abs(thr - self._last_thr) >= 0.005:
                self._send_acc = 0.0
                self._last_thr = thr
                h._run_cmd("throttle", {"v": thr})
            return t >= d
        if typ == "mode":
            return within(3, h.mode == a.get("m"))
        if typ == "arm":
            return within(3, h.armed == bool(a.get("v")))
        return True

