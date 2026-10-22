"""Small helpers for control loops: PID, filters, limits and geometry.

Local positions are metres from home, x east and y north (as dash's
telemetry ``pos``); headings and bearings are compass degrees.
"""
from __future__ import annotations

import math
import time
from typing import Optional, Sequence


def clamp(x: float, lo: float = -1.0, hi: float = 1.0) -> float:
    return lo if x < lo else hi if x > hi else x


class pid:
    """A PID controller. ``out = pid(1.2, 0.1, 0.3).update(error)``; the time
    step is measured unless given. The output is clamped to ±limit, and the
    integral stops growing while the output is clamped (anti-windup)."""

    def __init__(self, kp: float, ki: float = 0.0, kd: float = 0.0, limit: float = 1.0):
        self.kp, self.ki, self.kd, self.limit = kp, ki, kd, limit
        self.reset()

    def reset(self) -> None:
        self.integral = 0.0
        self._last_error: Optional[float] = None
        self._last_t: Optional[float] = None

    def update(self, error: float, dt: Optional[float] = None) -> float:
        now = time.monotonic()
        if dt is None:
            dt = 0.0 if self._last_t is None else now - self._last_t
        self._last_t = now
        deriv = 0.0 if self._last_error is None or dt <= 0 else (error - self._last_error) / dt
        self._last_error = error
        integral = self.integral + error * dt
        out = self.kp * error + self.ki * integral + self.kd * deriv
        if -self.limit < out < self.limit:
            self.integral = integral
        return clamp(out, -self.limit, self.limit)


class lowpass:
    """A first-order low-pass filter with a cut-off in Hz: ``f = lowpass(2); y = f.update(x)``."""

    def __init__(self, hz: float):
        self.hz = hz
        self.value: Optional[float] = None
        self._last_t: Optional[float] = None

    def update(self, x: float, dt: Optional[float] = None) -> float:
        now = time.monotonic()
        if dt is None:
            dt = 0.0 if self._last_t is None else now - self._last_t
        self._last_t = now
        if self.value is None:
            self.value = x
        else:
            a = 1 - math.exp(-2 * math.pi * self.hz * dt)
            self.value += a * (x - self.value)
        return self.value


class rate_limit:
    """Moves towards a target at most ``per_second`` units a second: smooth stick changes."""

    def __init__(self, per_second: float, start: float = 0.0):
        self.per_second = per_second
        self.value = start
        self._last_t: Optional[float] = None

    def update(self, target: float, dt: Optional[float] = None) -> float:
        now = time.monotonic()
        if dt is None:
            dt = 0.0 if self._last_t is None else now - self._last_t
        self._last_t = now
        step = self.per_second * dt
        self.value += clamp(target - self.value, -step, step)
        return self.value


def distance(a: Sequence[float], b: Sequence[float] = (0, 0, 0)) -> float:
    """Straight-line distance between two local positions (2 or 3 coordinates); from home by default."""
    return math.sqrt(sum((x - y) ** 2 for x, y in zip(a, b)))


def bearing(a: Sequence[float], b: Sequence[float]) -> float:
    """Compass bearing from local position a to b, degrees (0 = north, 90 = east)."""
    return math.degrees(math.atan2(b[0] - a[0], b[1] - a[1])) % 360


def angle_diff(target: float, current: float) -> float:
    """Shortest signed turn from one heading to another, degrees in −180…180."""
    return (target - current + 180) % 360 - 180


def geo_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """Metres between two GPS positions."""
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dp, dl = p2 - p1, math.radians(lon2 - lon1)
    h = math.sin(dp / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2
    return 2 * 6371000 * math.asin(math.sqrt(h))


def geo_bearing(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """Compass bearing between two GPS positions, degrees."""
    p1, p2, dl = math.radians(lat1), math.radians(lat2), math.radians(lon2 - lon1)
    y = math.sin(dl) * math.cos(p2)
    x = math.cos(p1) * math.sin(p2) - math.sin(p1) * math.cos(p2) * math.cos(dl)
    return math.degrees(math.atan2(y, x)) % 360
