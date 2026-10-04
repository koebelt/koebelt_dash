"""A simulated device on the network, built on this library.

    koebelt-link-sim --kind rover --name Mule-2
    koebelt-link-sim --kind drone --pair 4F7-K2Q

Useful to try the app without hardware, and as a reference firmware loop."""
from __future__ import annotations

import argparse
import math
import random

from . import Device, Vec3


def main(argv=None) -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--kind", default="rover", choices=["rover", "drone"])
    ap.add_argument("--name", default=None)
    ap.add_argument("--port", type=int, default=47800)
    ap.add_argument("--pair", default=None, help="pairing code shown in the app")
    ap.add_argument("--hz", type=float, default=60)
    a = ap.parse_args(argv)

    name = a.name or ("Mule-2" if a.kind == "rover" else "Kite-09")
    dev = Device(name, kind=a.kind, model="Simulated · koebelt-link-sim", sensors=["IMU", "GPS", "LIDAR"], fw="sim")
    dev.connect(wifi=True, port=a.port)
    if a.pair:
        dev.pair(a.pair)

    kp = dev.param("SPD_P", 0.8, 0, 3.2, unit="")
    max_spd = dev.param("MAX_SPD", 4, 0.5, 8, unit="m/s")
    temp = dev.channel("motor_temp", axes=["L", "R"], unit="C", hz=10)
    dev.failsafe(timeout=1.8, action="hold")

    s = {"x": 0.0, "y": 0.0, "z": 8.0 if a.kind == "drone" else 0.0, "yaw": 0.0, "v": 0.0, "vz": 0.0, "t": 0.0, "bat": 100.0}
    dev.set_armed(True)
    dev.set_mode("AUTO")
    world = [(random.uniform(-40, 40), random.uniform(-40, 40), random.uniform(0, 3)) for _ in range(2500)]

    @dev.on_stop
    def _stop():
        s["v"] = 0.0
        print("STOP")

    @dev.on_mode
    def _mode(m):
        print("mode ->", m)

    @dev.on_connect
    def _conn():
        print("app connected")

    dt = 1 / a.hz

    def step():
        s["t"] += dt
        c = dev.control
        live = dev.armed and not dev.estop
        if live and dev.mode == "AUTO":
            tx, ty = 20 * math.cos(s["t"] * 0.08), 12 * math.sin(s["t"] * 0.16)
            err = math.atan2(ty - s["y"], tx - s["x"]) - s["yaw"]
            err = math.atan2(math.sin(err), math.cos(err))
            target, turn = min(max_spd.value, 3.0), err * 1.2
        elif live and dev.mode == "MANUAL":
            target, turn = c.ry * max_spd.value * dev.speed * 2, -c.lx * 1.2
        else:
            target, turn = 0.0, 0.0
        s["v"] += (target - s["v"]) * min(1.0, dt * kp.value * 3)
        s["yaw"] += turn * dt
        s["x"] += math.cos(s["yaw"]) * s["v"] * dt
        s["y"] += math.sin(s["yaw"]) * s["v"] * dt
        if a.kind == "drone":
            want = s["z"] + (c.ly * 3 if dev.mode == "MANUAL" else (8 - s["z"]) * 0.5)
            s["z"] = max(0.0, s["z"] + (want - s["z"]) * dt)
        s["bat"] = max(0.0, s["bat"] - dt * 0.01 * (1 + abs(s["v"])))
        n = lambda k=0.03: random.uniform(-k, k)  # noqa: E731
        dev.publish("imu", accel=Vec3(n(.2), n(.2), 9.81 + n(.2)), gyro=Vec3(n(), n(), turn))
        dev.publish("att", roll=n(.01), pitch=n(.01), yaw=s["yaw"])
        dev.publish("pos", x=s["x"], y=s["y"], z=s["z"])
        dev.publish("vel", vx=math.cos(s["yaw"]) * s["v"], vy=math.sin(s["yaw"]) * s["v"], vz=0)
        dev.gps(47.3769 + s["y"] / 111111, 8.5417 + s["x"] / 75000, s["z"], 12)
        dev.publish("bat", volts=22 + s["bat"] / 100 * 3, amps=2 + abs(s["v"]) * 2, percent=s["bat"])
        temp.publish(35 + abs(s["v"]) * 3 + n(1), 36 + abs(s["v"]) * 3 + n(1))
        if int(s["t"] * 10) % 10 == 0:
            dev.publish("lidar", points=[p for p in world if math.hypot(p[0] - s["x"], p[1] - s["y"]) < 26])

    print(f"{name} ({a.kind}) listening on UDP {a.port}. Ctrl-C to stop.")
    dev.run(hz=a.hz, loop=step)


if __name__ == "__main__":
    main()
