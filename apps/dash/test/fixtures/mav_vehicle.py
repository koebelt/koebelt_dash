"""A stand-in ArduCopter for the app's MAVLink tests, built on pymavlink so
the app's encoder and decoder are checked against an independent one.

    python mav_vehicle.py VEHICLE_PORT GCS_PORT SECONDS [refuse-auto]

Streams heartbeat, attitude, position, battery and GPS to 127.0.0.1:GCS_PORT,
answers parameters, commands and time sync, takes mission uploads and flies
them in AUTO like ArduCopter (item 0 is home), then prints a JSON summary of
what the ground station did.
"""
import json
import math
import socket
import sys
import time

from pymavlink.dialects.v20 import common as m

vport, gport, secs = int(sys.argv[1]), int(sys.argv[2]), float(sys.argv[3])
# Like ArduCopter before its EKF uses GPS: no AUTO, no mission start.
refuse_auto = "refuse-auto" in sys.argv[4:]
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
       "gcs_heartbeats": 0, "timesync": 0, "intervals": 0, "mission": [], "mission_start": 0, "reached": []}
mission = {"items": [], "expect": 0, "gcs": (255, 0), "cur": -1, "since": 0.0}


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
            if refuse_auto and int(msg.param2) == 3:
                mav.statustext_send(m.MAV_SEVERITY_WARNING, b"Mode change to Auto failed: requires position")
                mav.command_ack_send(c, m.MAV_RESULT_FAILED)
                return
            state["mode"] = int(msg.param2)
            log["modes"].append(int(msg.param2))
            if state["mode"] == 3 and mission["cur"] < 1:
                start_mission()
        elif c == m.MAV_CMD_GET_HOME_POSITION:
            mav.home_position_send(int(LAT0 * 1e7), int(LON0 * 1e7), int(ALT0 * 1000), 0, 0, 0, [1, 0, 0, 0], 0, 0, 0)
        elif c == m.MAV_CMD_NAV_TAKEOFF:
            log["takeoff"] = msg.param7
            state["alt"] = msg.param7
        elif c == m.MAV_CMD_SET_MESSAGE_INTERVAL:
            log["intervals"] += 1
        elif c == m.MAV_CMD_MISSION_START:
            log["mission_start"] += 1
            if refuse_auto:
                mav.command_ack_send(c, m.MAV_RESULT_FAILED)
                return
            start_mission()
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
    elif t == "MISSION_COUNT":
        mission["items"] = [None] * msg.count
        mission["gcs"] = (msg.get_srcSystem(), msg.get_srcComponent())
        mission["cur"] = -1
        mav.mission_request_int_send(*mission["gcs"], 0, 0)
    elif t == "MISSION_ITEM_INT":
        items = mission["items"]
        if msg.seq < len(items):
            items[msg.seq] = msg
            nxt = next((i for i, x in enumerate(items) if x is None), None)
            if nxt is None:
                log["mission"] = [[x.command, x.x / 1e7, x.y / 1e7, x.z, x.param1, x.frame] for x in items]
                mav.mission_ack_send(*mission["gcs"], 0, 0)
            else:
                mav.mission_request_int_send(*mission["gcs"], nxt, 0)
    elif t == "TIMESYNC" and msg.tc1 == 0:
        log["timesync"] += 1
        mav.timesync_send(time.monotonic_ns(), msg.ts1)


def start_mission():
    if state["armed"] and len(mission["items"]) > 1 and all(mission["items"]):
        state["mode"] = 3  # AUTO
        mission["cur"] = 1
        mission["since"] = 0.0


def fly_mission(dt):
    """Very fast ArduCopter: 20 m/s, items done as soon as they are reached."""
    items, i = mission["items"], mission["cur"]
    if state["mode"] != 3 or not state["armed"] or i < 1 or i >= len(items):
        return
    it = items[i]
    mav.mission_current_send(i, len(items), 0, 0)
    done = False
    if it.command == m.MAV_CMD_NAV_TAKEOFF:
        state["alt"] = min(it.z, state["alt"] + 20 * dt)
        done = state["alt"] >= it.z - 0.05
    elif it.command == m.MAV_CMD_NAV_WAYPOINT:
        tn = (it.x / 1e7 - LAT0) * 111111
        te = (it.y / 1e7 - LON0) * 111111 * math.cos(math.radians(LAT0))
        dn, de, dz = tn - state["north"], te - state["east"], it.z - state["alt"]
        d = math.sqrt(dn * dn + de * de + dz * dz)
        k = min(1.0, 20 * dt / d) if d > 0 else 1.0
        state["north"] += dn * k
        state["east"] += de * k
        state["alt"] += dz * k
        done = d < 0.5
    elif it.command == m.MAV_CMD_NAV_LOITER_TIME:
        mission["since"] += dt
        done = mission["since"] >= it.param1
    elif it.command == m.MAV_CMD_NAV_LAND:
        state["alt"] = max(0.0, state["alt"] - 20 * dt)
        if state["alt"] <= 0:
            state["armed"] = False
            done = True
    if done:
        log["reached"].append(i)
        mav.mission_item_reached_send(i)
        mission["cur"] += 1
        mission["since"] = 0.0
        if not state["armed"]:
            # ArduCopter rewinds to the first item after landing and disarming.
            mission["cur"] = 1
            mav.mission_current_send(1, len(items), 0, 0)


t0 = time.monotonic()
last_hb = 0.0
said = False
while time.monotonic() - t0 < secs:
    now = time.monotonic()
    ms = int((now - t0) * 1000)
    fly_mission(0.05)
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
