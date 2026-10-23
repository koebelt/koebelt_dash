"""Thrust curve.

A test bench steps the throttle from 10 to 100 %, holds each step, and
prints the average thrust and current at each one, as a table to paste into
a spreadsheet. Allow arming in the script's Limits first.
"""
from koebelt_dash_scripts import connect, wait

dev = connect()
hold = dev.setting("seconds per step", 3.0, min=1, max=10)

dev.arm()
print("throttle %\tthrust\tcurrent A")
for pct in range(10, 101, 10):
    dev.throttle(pct, hold.value, wait=False)
    wait(hold.value / 2)                          # let it settle
    thrust, current = [], []
    for _ in range(10):
        t = dev.next_tlm()
        thrust.append(t.raw.get("thrust", 0.0))
        current.append(t.raw.get("current", 0.0))
    print(f"{pct}\t{sum(thrust) / len(thrust):.3f}\t{sum(current) / len(current):.2f}")
    wait(hold.value / 2)
dev.throttle(0, 1)
dev.disarm()
