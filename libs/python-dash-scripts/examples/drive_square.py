"""A rover drives a square, side by side, and stops on a button.

Try it on the simulated rover: Devices > Pair > Simulated > Mule, then arm
it. dash puts it in AUTO while the script drives it.
"""
# requires: rover
from koebelt_dash_scripts import angle_diff, bearing, clamp, connect, distance, every

dev = connect()
side = dev.setting("side (m)", 8.0, min=2, max=20)
corners = [(0, 0), (1, 0), (1, 1), (0, 1)]
done = False


@dev.trigger("Stop", key="S")
def stop():
    global done
    done = True


target = 1
for _ in every(0.05):
    if done:
        break
    x, y = dev.tlm.pos[0], dev.tlm.pos[1]
    goal = (corners[target][0] * side.value, corners[target][1] * side.value)
    if distance((x, y), goal) < 0.5:
        target = (target + 1) % len(corners)
        dev.mark(f"corner {target}")
        continue
    turn = angle_diff(bearing((x, y), goal), dev.tlm.heading)
    dev.sticks(throttle=0.6 if abs(turn) < 45 else 0.15, steer=clamp(turn / 45))

dev.sticks(throttle=0, steer=0)
dev.mode("HOLD")
