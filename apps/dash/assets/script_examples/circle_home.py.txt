"""Circle home.

A drone takes off, flies a circle around home through eight points, and
lands. Allow arming and take-off in the script's Limits first.
"""
import math

from koebelt_dash_scripts import connect

dev = connect()
radius = dev.setting("radius (m)", 10.0, min=3, max=40)
height = dev.setting("height (m)", 8.0, min=3, max=30)

dev.takeoff(height.value)
for i in range(9):
    a = i / 8 * 2 * math.pi
    dev.goto(radius.value * math.cos(a), radius.value * math.sin(a), height.value)
    dev.mark(f"point {i + 1}")
dev.rth()
