"""koebelt-dash-scripts: control devices connected in koebelt/dash from Python.

    from koebelt_dash_scripts import connect, every
    dev = connect()
    for _ in every(0.05):
        dev.sticks(throttle=0.3)
"""

__version__ = "1.3.0"

from .client import Device, Released, ScriptError, Setting, Telemetry, connect, every, wait  # noqa: E402
from .tools import angle_diff, bearing, clamp, distance, geo_bearing, geo_distance, lowpass, pid, rate_limit  # noqa: E402

__all__ = ["connect", "every", "wait", "Device", "Telemetry", "Setting", "ScriptError", "Released",
           "pid", "lowpass", "rate_limit", "clamp", "distance", "bearing", "angle_diff", "geo_distance", "geo_bearing",
           "__version__"]
