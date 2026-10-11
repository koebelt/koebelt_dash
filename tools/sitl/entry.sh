#!/bin/bash
# entry.sh VEHICLE [extra SITL args]: copter, plane or rover. Sends MAVLink to
# the computer running Docker on UDP 14550 (GCS_PORT to change), like a
# vehicle on a telemetry link. Logs land in /sitl/logs.
set -e
vehicle=${1:-copter}; shift || true
case $vehicle in
  copter) bin=arducopter model=+ ;;
  plane) bin=arduplane model=plane ;;
  rover) bin=ardurover model=rover ;;
  *) echo "vehicle must be copter, plane or rover" >&2; exit 2 ;;
esac
host=$(getent hosts host.docker.internal | cut -d' ' -f1)
host=${host:-$(ip route | awk '/default/ {print $3}')}
echo "ArduPilot $vehicle $(cat $bin.version) -> udp $host:${GCS_PORT:-14550}"
exec ./$bin --model "$model" --speedup "${SPEEDUP:-1}" --home "${HOME_LOC:-47.3769,8.5417,400,0}" \
  --defaults "$vehicle.parm" -I0 --serial0 "udpclient:$host:${GCS_PORT:-14550}" "$@"
