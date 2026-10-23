"""Errors that say what went wrong, where in your script, why, and what to do.

    error[E0301]: arming is not allowed for this script
      --> follow_me.py:14
       |
    14 |     dev.arm()
       |     ^^^^^^^^^
       |
       = why: the script's limits in koebelt dash do not allow arming or take-off
       = help: in dash, open the script, then Limits > Allow arming and take-off
       = docs: https://github.com/koebelt/koebelt_dash/blob/main/libs/python-dash-scripts/ERRORS.md#e0301

Every error has a code, explained in ERRORS.md. Uncaught, they print like
this instead of a traceback through the library (set KOEBELT_DASH_TRACEBACK=1
for the full one).
"""
from __future__ import annotations

import difflib
import linecache
import os
import pathlib
import sys
import threading
import traceback
from typing import Any, Dict, Iterable, List, Optional, Tuple

DOCS = "https://github.com/koebelt/koebelt_dash/blob/main/libs/python-dash-scripts/ERRORS.md"
_PACKAGE = str(pathlib.Path(__file__).resolve().parent)

# code: (title, why, help). Titles and texts are formatted with the error's data.
CATALOG: Dict[str, Tuple[str, str, str]] = {
    # Connecting
    "E0001": ("no device is connected in koebelt dash",
              "connect() uses the device selected in dash, and none is connected",
              "connect a device in dash (Devices), or a simulated one (Devices > Pair > Simulated)"),
    "E0002": ("no connected device called “{name}”",
              "connect(\"{name}\") looks for a connected device by name or id",
              "{suggest}connected now: {names_list}"),
    "E0003": ("this script has no device yet",
              "commands need a device, and connect() did not get one",
              "use the Device returned by connect()"),
    "E0004": ("{device} cannot run this script",
              "the script needs {needs}; {device} lacks {missing_list}",
              "choose another device in dash (the script's Device), or change its # requires: line or connect(requires=…)"),
    "E0010": ("koebelt dash is not running on this computer",
              "connect() looks for ~/.koebelt/dash-api.json, which dash writes when it starts",
              "open koebelt dash, or run the script from it (Scripts); on another computer, set KOEBELT_DASH_URL and KOEBELT_DASH_TOKEN"),
    "E0011": ("cannot reach koebelt dash at {url}",
              "{reason}",
              "check that dash is open; a script host needs the phone or computer running dash on the same network"),
    "E0012": ("koebelt dash refused the connection",
              "{reason}",
              "run the script from dash, or restart dash so that ~/.koebelt/dash-api.json is up to date"),
    "E0013": ("the connection to koebelt dash closed",
              "dash was closed, or the script was stopped from it",
              "start the script again once dash is open"),
    "E0014": ("koebelt dash did not answer “{request}” within {timeout} s",
              "dash is busy or stuck, or the network to it dropped",
              "try again; if it keeps happening, restart dash"),
    # Safety: the operator decides
    "E0101": ("STOP is on",
              "the operator pressed STOP, and dash refuses commands until they clear it",
              "clear STOP in dash, then run the script again; a script can react with @dev.on_stop"),
    "E0102": ("this script lost the sticks: {why}",
              "dash took the sticks away for safety, and the script may not take them back by itself",
              "in dash, press Resume on the script (or on Control); handle it in the script with @dev.on_stop"),
    "E0103": ("{other} already drives {device}",
              "one script at a time drives a device's sticks",
              "stop {other} in dash, or connect this script to another device"),
    # Driving
    "E0201": ("“{name}” is not a stick of a {kind}",
              "sticks are named for the kind of device",
              "{suggest}a {kind} has: {names_list}"),
    "E0202": ("sticks() takes named axes",
              "each axis has a name, so a value cannot go to the wrong one",
              "dev.sticks(throttle=0.5, steer=-0.2); a drone has throttle, yaw, pitch, roll"),
    # Limits set in dash
    "E0301": ("arming and take-off are not allowed for this script",
              "the script's limits in koebelt dash do not allow arming or take-off",
              "in dash, open the script, then Limits > Allow arming and take-off; or arm the device yourself first"),
    "E0302": ("parameter writes are not allowed for this script",
              "the script's limits in koebelt dash do not allow writing parameters",
              "in dash, open the script, then Limits > Allow parameter writes"),
    "E0303": ("that point is {distance:.0f} m from home, beyond the {fence:.0f} m geofence",
              "the script's geofence keeps it within {fence:.0f} m of home",
              "aim closer to home, or raise the geofence in dash (the script's Limits)"),
    "E0304": ("{height} m is above the {ceiling:.0f} m ceiling",
              "the script's ceiling keeps drones below {ceiling:.0f} m",
              "fly lower, or raise the ceiling in dash (the script's Limits)"),
    # Steps and programs
    "E0401": ("a {kind} has no “{name}” step",
              "Program steps depend on the kind of device",
              "{suggest}a {kind} has: {names_list}"),
    "E0402": ("no program called “{name}” on {device}",
              "run_program() runs a sequence from dash's Program screen, by name",
              "{suggest}programs on {device}: {names_list}"),
    "E0403": ("“{running}” is already running",
              "a device runs one sequence at a time",
              "wait for it, or dev.stop_program() first"),
    "E0404": ("the device cannot run it now",
              "it is stopped, disconnected, or replaying a recording in dash",
              "check the device in dash"),
    "E0405": ("the step did not finish: {message}",
              "the device, the operator or a safety check ended it",
              "look at what the device is doing in dash; the operator taking the sticks ends a step"),
    "E0406": ("no program is running",
              "pause_program(), resume_program() and stop_program() act on a running one",
              "start one with dev.run_program(\"…\")"),
    # Reading
    "E0501": ("this device sends no “{name}”",
              "telemetry has the fields the device sends",
              "{suggest}it sends: {names_list}"),
    "E0502": ("no telemetry from the device yet",
              "the device has not sent any since the script connected",
              "check that it is connected and its link is up in dash"),
    # Camera
    "E0601": ("{device} has no camera",
              "the device declares no video stream",
              "add one in the firmware: video() in the koebelt/link library (see the Live video guide)"),
    "E0602": ("no picture from camera {camera} within {timeout} s",
              "{reason}",
              "check the camera in dash (Live > CAM); a camera reached by IP needs this computer on the same network"),
    "E0603": ("camera frames need numpy and OpenCV or Pillow",
              "frames are decoded into numpy images",
              "pip install opencv-python   (or: pip install pillow numpy)"),
    # Declarations
    "E0701": ("setting “{name}”: {reason}",
              "settings become sliders (numbers) or switches (True/False) in dash",
              "dev.setting(\"speed\", 0.4, min=0, max=1) or dev.setting(\"patrol\", False)"),
    "E0702": ("trigger “{name}”: unknown kind “{kind}”",
              "a trigger is a button, a switch or a value",
              "kind=\"button\", kind=\"switch\" or kind=\"value\""),
    "E0703": ("every() needs a period above 0 s, not {seconds}",
              "it is the time between two turns of the loop",
              "for _ in every(0.05):   # 20 times a second"),
    # Anything else dash refuses
    "E0900": ("koebelt dash refused: {message}", "", "if it looks like a bug, report it with the script on GitHub"),
    "E0901": ("koebelt dash does not know “{message}”",
              "this library and dash disagree on the messages",
              "update koebelt dash and koebelt-dash-scripts to matching versions"),
}

WARNINGS: Dict[str, Tuple[str, str, str]] = {
    "W0102": ("koebelt-dash-scripts {have} is older than koebelt dash {app}",
              "a newer library may fix bugs or add what this dash offers; this one still works with it",
              "pip install --upgrade \"koebelt-dash-scripts{spec}\"   (in dash: the script's panel > Update)"),
    "W0201": ("{name}={value} is outside −1…1: dash uses {clamped}",
              "sticks go from −1 to 1",
              "clamp it yourself (koebelt_dash_scripts.clamp) to silence this"),
}


def _suggestion(name: Any, names: Iterable[str]) -> str:
    close = difflib.get_close_matches(str(name), [str(n) for n in names], n=1, cutoff=0.6)
    return f"did you mean “{close[0]}”? " if close else ""


def _user_frame() -> Optional[traceback.FrameSummary]:
    """The innermost frame of the script calling the library."""
    for f in reversed(traceback.extract_stack()):
        if not str(pathlib.Path(f.filename).resolve()).startswith(_PACKAGE) and not f.filename.startswith("<frozen"):
            return f
    return None


class ScriptError(RuntimeError):
    """An error from koebelt-dash-scripts or koebelt dash, with its code."""

    def __init__(self, code: str, data: Optional[Dict[str, Any]] = None, message: Optional[str] = None):
        self.code = code
        self.data = dict(data or {})
        if isinstance(self.data.get("missing"), list):
            self.data.setdefault("missing_list", ", ".join(str(m) for m in self.data["missing"]))
        names = self.data.get("names")
        if names is not None:
            self.data.setdefault("names_list", ", ".join(str(n) for n in names) or "none")
            self.data.setdefault("suggest", _suggestion(self.data.get("name", ""), names))
        self.data.setdefault("suggest", "")
        title, why, help_ = (WARNINGS if code.startswith("W") else CATALOG).get(code, ("{message}", "", ""))
        self.data.setdefault("message", message or "")
        self.title = _fmt(title, self.data) or message or code
        self.why = _fmt(why, self.data)
        self.help = _fmt(help_, self.data)
        self.where = _user_frame()
        super().__init__(self.title)

    def render(self, color: Optional[bool] = None) -> str:
        return render(self, color=color)


class Released(ScriptError):
    """dash took the sticks away (watchdog, geofence, STOP…) and the operator has not resumed the script yet."""


class TelemetryFieldError(ScriptError, AttributeError):
    """A telemetry field the device does not send."""


def _fmt(t: str, data: Dict[str, Any]) -> str:
    class Safe(dict):
        def __missing__(self, k):
            return "{" + k + "}"
    try:
        return t.format_map(Safe(data))
    except (ValueError, TypeError):
        return t


def _use_color(stream) -> bool:
    if os.environ.get("NO_COLOR"):
        return False
    if os.environ.get("KOEBELT_DASH_COLOR"):
        return True
    return hasattr(stream, "isatty") and stream.isatty()


def render(e: ScriptError, color: Optional[bool] = None) -> str:
    """The error, Rust style: title, the script's line, why, help, docs."""
    c = _use_color(sys.stderr) if color is None else color

    def paint(s: str, code: str) -> str:
        return f"\x1b[{code}m{s}\x1b[0m" if c else s

    kind = "warning" if e.code.startswith("W") else "error"
    head = paint(f"{kind}[{e.code}]", "1;33" if kind == "warning" else "1;31") + paint(f": {e.title}", "1")
    out = [head]
    f = e.where
    if f is not None and f.lineno:
        src = (linecache.getline(f.filename, f.lineno) or "").rstrip("\n")
        n = str(f.lineno)
        pad = " " * len(n)
        out.append(f"{pad}{paint('-->', '1;34')} {os.path.basename(f.filename)}:{f.lineno}")
        if src.strip():
            indent = len(src) - len(src.lstrip())
            out.append(f"{pad} {paint('|', '1;34')}")
            out.append(f"{paint(n, '1;34')} {paint('|', '1;34')} {src}")
            out.append(f"{pad} {paint('|', '1;34')} {' ' * indent}{paint('^' * max(1, len(src.strip())), '1;31' if kind == 'error' else '1;33')}")
        out.append(f"{pad} {paint('|', '1;34')}")
        lead = f"{pad} {paint('=', '1;34')}"
    else:
        lead = f"  {paint('=', '1;34')}"
    if e.why:
        out.append(f"{lead} {paint('why', '1')}: {e.why}")
    if e.help:
        out.append(f"{lead} {paint('help', '1;32')}: {e.help}")
    out.append(f"{lead} {paint('docs', '1')}: {DOCS}#{e.code.lower()}")
    return "\n".join(out)


_warned = set()


def warn_once(code: str, key: Any, data: Dict[str, Any]) -> None:
    """A warning, once per place in the script and key."""
    w = ScriptError(code, data)
    at = (code, key, w.where.filename if w.where else None, w.where.lineno if w.where else None)
    if at in _warned:
        return
    _warned.add(at)
    print(render(w), file=sys.stderr, flush=True)


def _hook(kind, value, tb):
    if isinstance(value, ScriptError) and not os.environ.get("KOEBELT_DASH_TRACEBACK"):
        # The call chain in the script, without the library's frames.
        chain = [f for f in traceback.extract_tb(tb) if not str(pathlib.Path(f.filename).resolve()).startswith(_PACKAGE)]
        if value.where is None and chain:
            value.where = chain[-1]
        print(render(value), file=sys.stderr, flush=True)
        if len(chain) > 1:
            print("\n  called from: " + " ← ".join(f"{os.path.basename(f.filename)}:{f.lineno} {f.name}()" for f in reversed(chain[:-1])), file=sys.stderr)
        return
    _previous(kind, value, tb)


def _thread_hook(args):
    if isinstance(args.exc_value, ScriptError):
        _hook(args.exc_type, args.exc_value, args.exc_traceback)
    else:
        _previous_thread(args)


_previous = sys.excepthook
_previous_thread = threading.excepthook


def install() -> None:
    """Prints this library's errors Rust style when the script does not catch them."""
    if sys.excepthook is not _hook:
        sys.excepthook = _hook
        threading.excepthook = _thread_hook


def report(exc: BaseException) -> None:
    """For handlers: print an exception the library caught, readably."""
    if isinstance(exc, ScriptError):
        print(render(exc), file=sys.stderr, flush=True)
    else:
        tb = [f for f in traceback.extract_tb(exc.__traceback__) if not str(pathlib.Path(f.filename).resolve()).startswith(_PACKAGE)]
        print("".join(traceback.format_list(tb)) + "".join(traceback.format_exception_only(type(exc), exc)), file=sys.stderr, end="", flush=True)


def codes() -> List[str]:
    return sorted(CATALOG) + sorted(WARNINGS)
