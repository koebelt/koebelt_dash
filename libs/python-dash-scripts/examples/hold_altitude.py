"""Hold altitude.

A drone holds a height set in dash, with a PID on the throttle stick, while
dash puts it in AUTO while the script drives it. Needs the drone armed.
"""
# requires: drone
from koebelt_dash_scripts import connect, every, pid

dev = connect()
target = dev.setting("height (m)", 5.0, min=1, max=30)
climb = pid(0.6, 0.1, 0.25)

for _ in every(0.05):
    error = target.value - dev.tlm.alt
    dev.sticks(throttle=climb.update(error))
    dev.plot("height error", error)
