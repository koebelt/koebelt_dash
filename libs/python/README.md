# koebelt-link (Python)

Connect a Raspberry Pi, a Jetson or any computer-driven robot to koebelt dash.

```bash
pip install koebelt-link                 # Wi-Fi (UDP) only, no dependencies
pip install "koebelt-link[serial,ble]"   # USB serial and radios (pyserial), BLE peripheral (bless)
pip install "koebelt-link[camera]"       # dev.camera(): live video through OpenCV
```

```python
from koebelt_link import Device, Vec3

dev = Device("Mule-2", kind="rover")
dev.connect(wifi=True)                   # or ble=True, serial="/dev/ttyUSB0", radio=("/dev/ttyAMA0", "sik")
dev.failsafe(timeout=1.8, action="hold")
max_spd = dev.param("MAX_SPD", 4, min=0.5, max=8, unit="m/s")

@dev.on_control
def drive(c):
    motors.set(speed=c.ry * max_spd.value, turn=c.lx)

@dev.on_stop
def stop():
    motors.brake()

while True:
    dev.publish("imu", accel=Vec3(*imu.accel()), gyro=Vec3(*imu.gyro()))
    dev.publish("lidar", points=lidar.scan())   # Nx3, metres
    dev.tick(hz=50)
```

- Channels: `imu`, `att`, `pos`, `vel`, `gps`, `bat`, `rssi`, `joints`, `tool`,
  `ft`, `thrust`, `rpm`, `temp`, `throttle`, `rocket`, `lidar`, `tracks`, and
  custom channels via `dev.channel(...)`. Each built-in one also has a
  shortcut named like the Arduino and Rust ones (`dev.position(x, y, z)`,
  `dev.rocket_state(...)`…).
- Links: `wifi`, `ble`, `serial`, `radio` (SiK, LoRa, HC-12, XBee or other:
  rates follow the shared radio profile), and `fallback={"radio": (...)}` for
  a second link that takes over telemetry when the first goes quiet.
- Video: `dev.camera(0, label="Front")` streams a webcam or Pi camera, or
  serve your own frames with `MjpegServer` and declare it with `dev.video(srv.url)`.
- Callbacks: `on_control`, `on_mode`, `on_arm`, `on_stop`, `on_reset`, `on_jog`,
  `on_cart`, `on_command`, `on_params_written`, `on_connect`.
- Pairing: `dev.pair("XXX-XXX")` once. The key and saved parameters live in
  `~/.config/koebelt-link/<id>.json` (override with `KOEBELT_LINK_HOME`).

## Simulator

`koebelt-link-sim --kind rover|drone [--pair CODE]` runs a simulated device on
UDP 47800. It is a reference firmware loop and a way to test the app's real network path.

```bash
python -m venv .venv && .venv/bin/pip install -e ".[dev]" && .venv/bin/python -m pytest
```
