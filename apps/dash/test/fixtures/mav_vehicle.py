"""A stand-in ArduCopter for the app's MAVLink tests, built on pymavlink so
the app's encoder and decoder are checked against an independent one.

    python mav_vehicle.py VEHICLE_PORT GCS_PORT SECONDS

Streams heartbeat, attitude, position, battery and GPS to 127.0.0.1:GCS_PORT,
answers parameters, commands and time sync, then prints a JSON summary of
what the ground station did.
"""
import json
import math
import socket
import sys
import time

from pymavlink.dialects.v20 import common as m

vport, gport, secs = int(sys.argv[1]), int(sys.argv[2]), float(sys.argv[3])
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.bind(("127.0.0.1", vport))
sock.setblocking(False)
gcs = ("127.0.0.1", gport)


class Out:
    def write(self, b):
        sock.sendto(b, gcs)


mav = m.MAVLink(Out(), srcSystem=1, srcComponent=1)
LAT0, LON0, ALT0 = 47.3769, 8.5417, 400.0
state = {"armed": False, "mode": 0, "alt": 0.0, "north": 0.0, "east": 0.0}
params = {"ATC_RAT_RLL_P": (0.135, m.MAV_PARAM_TYPE_REAL32), "WPNAV_SPEED": (500.0, m.MAV_PARAM_TYPE_REAL32), "FS_GCS_ENABLE": (1.0, m.MAV_PARAM_TYPE_INT8)}
log = {"arm": [], "modes": [], "manual": 0, "last_manual": None, "param_sets": {}, "reposition": None, "takeoff": None, "force_disarm": False,
       "gcs_heartbeats": 0, "timesync": 0, "intervals": 0}


def send_params():
    names = sorted(params)
    for i, k in enumerate(names):
        v, t = params[k]
        mav.param_value_send(k.encode(), v, t, len(names), i)


def handle(msg):
    t = msg.get_type()
    if t == "HEARTBEAT":
        log["gcs_heartbeats"] += 1
    elif t == "PARAM_REQUEST_LIST":
        send_params()
    elif t == "PARAM_SET":
        k = msg.param_id.rstrip("\x00") if isinstance(msg.param_id, str) else msg.param_id.decode().rstrip("\x00")
        params[k] = (msg.param_value, msg.param_type)
        log["param_sets"][k] = msg.param_value
        names = sorted(params)
        mav.param_value_send(k.encode(), msg.param_value, msg.param_type, len(names), names.index(k))
    elif t == "COMMAND_LONG":
        c = msg.command
        if c == m.MAV_CMD_COMPONENT_ARM_DISARM:
            state["armed"] = msg.param1 == 1
            log["arm"].append(bool(state["armed"]))
            if msg.param2 == 21196:
                log["force_disarm"] = True
        elif c == m.MAV_CMD_DO_SET_MODE:
            state["mode"] = int(msg.param2)
            log["modes"].append(int(msg.param2))
        elif c == m.MAV_CMD_GET_HOME_POSITION:
            mav.home_position_send(int(LAT0 * 1e7), int(LON0 * 1e7), int(ALT0 * 1000), 0, 0, 0, [1, 0, 0, 0], 0, 0, 0)
        elif c == m.MAV_CMD_NAV_TAKEOFF:
            log["takeoff"] = msg.param7
            state["alt"] = msg.param7
        elif c == m.MAV_CMD_SET_MESSAGE_INTERVAL:
            log["intervals"] += 1
        mav.command_ack_send(c, 0)
    elif t == "COMMAND_INT" and msg.command == m.MAV_CMD_DO_REPOSITION:
        lat, lon = msg.x / 1e7, msg.y / 1e7
        log["reposition"] = [lat, lon, msg.z, msg.frame]
        state["north"] = (lat - LAT0) * 111111
        state["east"] = (lon - LON0) * 111111 * math.cos(math.radians(LAT0))
        state["alt"] = msg.z
        mav.command_ack_send(msg.command, 0)
    elif t == "MANUAL_CONTROL":
        log["manual"] += 1
        log["last_manual"] = [msg.x, msg.y, msg.z, msg.r]
    elif t == "TIMESYNC" and msg.tc1 == 0:
        log["timesync"] += 1
        mav.timesync_send(time.monotonic_ns(), msg.ts1)


t0 = time.monotonic()
last_hb = 0.0
said = False
while time.monotonic() - t0 < secs:
    now = time.monotonic()
    ms = int((now - t0) * 1000)
    if now - last_hb >= 0.5:
        last_hb = now
        base = m.MAV_MODE_FLAG_CUSTOM_MODE_ENABLED | (m.MAV_MODE_FLAG_SAFETY_ARMED if state["armed"] else 0)
        mav.heartbeat_send(m.MAV_TYPE_QUADROTOR, m.MAV_AUTOPILOT_ARDUPILOTMEGA, base, state["mode"], m.MAV_STATE_ACTIVE)
        mav.sys_status_send(0, 0, 0, 0, 15800, 1210, 76, 0, 0, 0, 0, 0, 0)
        mav.gps_raw_int_send(ms * 1000, 3, int(LAT0 * 1e7), int(LON0 * 1e7), int(ALT0 * 1000), 80, 120, 0, 0, 14)  # XML order
        if not said:
            said = True
            mav.statustext_send(m.MAV_SEVERITY_WARNING, b"PreArm: test vehicle ready")
    mav.attitude_send(ms, 0.05, -0.1, 0.0, 0.01, 0.02, 0.0)
    lat = LAT0 + state["north"] / 111111
    lon = LON0 + state["east"] / (111111 * math.cos(math.radians(LAT0)))
    mav.global_position_int_send(ms, int(lat * 1e7), int(lon * 1e7), int((ALT0 + state["alt"]) * 1000), int(state["alt"] * 1000), 120, -30, 0, 9000)
    try:
        while True:
            data = sock.recv(4096)
            for msg in mav.parse_buffer(data) or []:
                handle(msg)
    except BlockingIOError:
        pass
    time.sleep(0.05)

print(json.dumps(log), flush=True)
