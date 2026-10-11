# Autopilot simulators (SITL)

The real ArduPilot and PX4 flight code, flying simulated vehicles, for
testing koebelt/dash without hardware. Each container sends MAVLink to UDP
14550 on the computer running Docker, like a vehicle on a telemetry radio:
open the app and the vehicle appears under **Pair device > Nearby**.

| Image | Vehicles | Source |
|-------|----------|--------|
| `koebelt/sitl-ardupilot` | `copter`, `plane`, `rover` | ArduPilot's prebuilt SITL binaries (stable, x86-64; emulated on Apple silicon) |
| `koebelt/sitl-px4` | `quadx` (SIH physics, no Gazebo) | PX4 built from source (native on ARM and x86-64; the first build takes a while) |

```bash
cd tools/sitl
docker build -t koebelt/sitl-ardupilot -f Dockerfile.ardupilot .
docker build -t koebelt/sitl-px4 -f Dockerfile.px4 .

docker run --rm --add-host=host.docker.internal:host-gateway koebelt/sitl-ardupilot copter
docker run --rm --add-host=host.docker.internal:host-gateway koebelt/sitl-px4 quadx
```

Options (`-e NAME=value`): `GCS_PORT` (default 14550), `HOME_LOC` for
ArduPilot (`lat,lon,alt,heading`), `HOME_LAT` / `HOME_LON` / `HOME_ALT` for
PX4, `SPEEDUP` for ArduPilot. ArduPilot writes its DataFlash logs to
`/sitl/logs` in the container (`docker cp <name>:/sitl/logs .`), handy for
the app's log import.

The vehicles need about 25 s after start to get a GPS fix and an EKF
position before they arm. Stop the app's own ground station first if
another one (Mission Planner, QGroundControl) is using UDP 14550.

## Tests

```bash
cd apps/dash
SITL=1 flutter test test/sitl_test.dart
```

Builds the images if needed, then for each vehicle: finds it on UDP 14550,
pairs and connects, checks telemetry and parameters, flies a sequence as a
mission (take off, waypoint, wait, land) and imports the autopilot's own
log of the flight. A few minutes per vehicle. CI runs it weekly and on
demand (`sitl` workflow).
