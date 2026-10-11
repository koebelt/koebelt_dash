#!/bin/bash
# entry-px4.sh [quadx|rover]: PX4 with its SIH physics. Its ground-station
# link sends to localhost:14550 inside the container; socat relays that to
# the computer running Docker on UDP 14550 (GCS_PORT to change), and the
# replies back. Logs: /px4/build/px4_sitl_default/log.
set -e
model=${1:-quadx}
case $model in
  quadx) autostart=10040 sim=sihsim_quadx ;;
  rover) autostart=10045 sim=sihsim_rover_ackermann ;;
  *) echo "model must be quadx or rover" >&2; exit 2 ;;
esac
host=$(getent hosts host.docker.internal | cut -d' ' -f1)
host=${host:-$(ip route | awk '/default/ {print $3}')}
echo "PX4 $(cat /px4/VERSION) sih $model -> udp $host:${GCS_PORT:-14550}"
# One relay for PX4's ground-station socket (it always sends from the same port).
socat UDP4-LISTEN:14550,bind=127.0.0.1,reuseaddr UDP4:$host:${GCS_PORT:-14550} &
cd /px4/build/px4_sitl_default
export PX4_SYS_AUTOSTART=$autostart PX4_SIM_MODEL=$sim PX4_HOME_LAT=${HOME_LAT:-47.3769} PX4_HOME_LON=${HOME_LON:-8.5417} PX4_HOME_ALT=${HOME_ALT:-400}
exec ./bin/px4 -d ./etc
