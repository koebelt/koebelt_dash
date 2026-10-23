"""Patrol waypoints.

A rover (or a flying drone) drives between waypoints, round and round, until
you switch Patrol off in dash or on Control.
"""
# requires: drone, rover
from koebelt_dash_scripts import connect, wait

dev = connect()
points = [(0, 0), (8, 0), (8, 6), (0, 6)]
on = dev.store.get("patrol", True)


@dev.trigger("Patrol", kind="switch", key="P")
def patrol(value):
    global on
    on = value
    dev.store["patrol"] = value
    if not value:
        dev.mode("HOLD")


i = 0
while True:
    if not on:
        wait(0.5)
        continue
    x, y = points[i % len(points)]
    dev.goto(x, y)
    i += 1
