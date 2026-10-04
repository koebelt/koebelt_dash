"""Pure helpers (no ROS imports) so they can be unit-tested anywhere."""
from __future__ import annotations

import math
from typing import Any, Dict, Iterable, List, Sequence, Tuple


def quat_to_rpy(x: float, y: float, z: float, w: float) -> Tuple[float, float, float]:
    """Quaternion to roll, pitch, yaw (rad), ZYX convention as in REP 103."""
    sinr = 2 * (w * x + y * z)
    cosr = 1 - 2 * (x * x + y * y)
    roll = math.atan2(sinr, cosr)
    sinp = 2 * (w * y - z * x)
    pitch = math.copysign(math.pi / 2, sinp) if abs(sinp) >= 1 else math.asin(sinp)
    siny = 2 * (w * z + x * y)
    cosy = 1 - 2 * (y * y + z * z)
    return roll, pitch, math.atan2(siny, cosy)


def downsample(points: Iterable[Sequence[float]], limit: int = 2000) -> List[Tuple[float, float, float]]:
    """Keep at most `limit` finite points, evenly strided."""
    pts = [(float(p[0]), float(p[1]), float(p[2])) for p in points if all(math.isfinite(float(v)) for v in p[:3])]
    if len(pts) <= limit:
        return pts
    step = len(pts) / limit
    return [pts[int(i * step)] for i in range(limit)]


RADIOS = ("sik", "lora", "hc12", "xbee", "other")


def parse_transport(t: str) -> Dict[str, Any]:
    """'wifi' | 'ble' | 'serial:/dev/ttyUSB0' | 'radio:/dev/ttyUSB1[:sik]' -> kwargs for Device.connect()."""
    t = (t or "wifi").strip()
    if t == "wifi":
        return {"wifi": True}
    if t == "ble":
        return {"ble": True}
    if t.startswith("serial:"):
        return {"serial": t.split(":", 1)[1]}
    if t.startswith("radio:"):
        rest = t.split(":", 1)[1]
        path, _, profile = rest.rpartition(":")
        if profile in RADIOS and path:
            return {"radio": (path, profile)}
        return {"radio": (rest, "sik")}
    raise ValueError(f"unknown transport {t!r}: use wifi, ble, serial:/dev/tty… or radio:/dev/tty…[:sik|lora|hc12|xbee|other]")


def parse_fallback(t: str) -> Dict[str, Any]:
    """A second link that takes over telemetry when the first goes quiet."""
    kw = parse_transport(t)
    if "ble" in kw:
        raise ValueError("BLE cannot be a fallback; use wifi, serial or radio")
    k, v = next(iter(kw.items()))
    return {k: v}


def topic_values(msg: Any, n: int) -> List[float]:
    """Numbers from a std_msgs scalar/array or a sensor_msgs Temperature/FluidPressure, padded to n."""
    for field in ("data", "temperature", "fluid_pressure"):
        if hasattr(msg, field):
            v = getattr(msg, field)
            vals = [float(x) for x in v] if isinstance(v, (list, tuple)) or hasattr(v, "__len__") and not isinstance(v, str) else [float(v)]
            return (vals + [0.0] * n)[:n]
    raise TypeError(f"unsupported message for a channel: {type(msg).__name__}")


def control_to_twist(ry: float, lx: float, speed: float, max_linear: float, max_angular: float) -> Tuple[float, float]:
    """Right stick forward = drive, left stick sideways = turn (left is positive yaw in ROS)."""
    scale = speed * 2
    return ry * max_linear * scale, -lx * max_angular * scale
