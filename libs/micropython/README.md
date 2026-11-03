# koebelt_link (MicroPython)

Connect an ESP32, a Raspberry Pi Pico W or another MicroPython board to
koebelt/dash. One module, `koebelt_link.py`, with no dependencies.

```bash
mpremote mip install github:koebelt/koebelt_dash/libs/micropython
# or copy it: mpremote cp koebelt_link.py :
```

```python
import koebelt_link as kl

kl.wifi("my-network", "password")
dev = kl.Device("Mule-3", kind="rover")
dev.connect(wifi=True)              # or usb=True, serial=UART(1, 115200), radio=(UART(1, 57600), "sik")
dev.failsafe(timeout=1.8, action="hold")
max_spd = dev.param("MAX_SPD", 1, min=0.2, max=2, unit="m/s")

@dev.on_control
def drive(c):
    motors(c.ry * max_spd.value, c.lx)

@dev.on_stop
def stop():
    motors(0, 0)

while True:
    dev.imu(*imu.accel(), *imu.gyro())
    dev.battery(7.6, 80)
    dev.tick(hz=50)
```

- Kinds: drone, plane, rover, boat, arm, rocket, bench, generic.
- Links: Wi-Fi (`wifi=True`, after `kl.wifi(ssid, password)`), the board's
  USB serial (`usb=True`: the REPL port, so print nothing else on it), a
  UART (`serial=UART(…)`), a radio modem on a UART (`radio=(UART(…), "sik")`:
  sik, lora, hc12, xbee or other) or a Bluetooth serial module
  (`module=(UART(…), 9600)`); `fallback={"radio": …}` takes over telemetry
  when the first link goes quiet.
- Telemetry: `imu`, `attitude`, `position`, `velocity`, `gps`, `battery`,
  `rssi`, `joints`, `tool`, `force_torque`, `thrust`, `rpm`, `temperature`,
  `throttle_out`, `rocket_state`, `publish(channel, …)`, custom channels with
  `dev.channel(…)` and proximity sensors with `dev.proximity(…)`.
- Callbacks: `on_control`, `on_mode`, `on_arm`, `on_stop`, `on_reset`,
  `on_jog`, `on_cart`, `on_command` (goto, takeoff, sethome, your own…),
  `on_params_written`, `on_connect`.
- Pairing: `dev.pair("XXX-XXX")` once. The key and saved parameters live in
  `koebelt_link.json` on the board's flash.

Compared with the other libraries: sequences run from the app (the board
does not store them, so they pause if the link drops), and there is no
Bluetooth LE, video or point clouds. Everything else in
[`protocol/PROTOCOL.md`](../../protocol/PROTOCOL.md) is here.

## Tests

The module also runs on CPython, which the tests use, and `mpy-cross` checks
that it compiles for MicroPython:

```bash
../python/.venv/bin/pip install mpy-cross pytest
../python/.venv/bin/python -m pytest tests
```
