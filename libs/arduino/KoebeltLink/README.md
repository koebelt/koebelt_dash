# KoebeltLink (Arduino)

For ESP32 (Wi-Fi, BLE, flash storage), RP2040 W and other Wi-Fi boards (UDP),
and any board with a `Stream` (USB serial or UART radio). It depends on
ArduinoJson 7.

```cpp
#include <KoebeltLink.h>

KLink link("Kite-03", KLink::DRONE);

void setup() {
  link.begin(WIFI_SSID, WIFI_PASS);         // or beginBLE(), beginSerial(Serial)
  link.onControl([](const KControl& c) { throttle = c.ly; yaw = c.lx; pitch = c.ry; roll = c.rx; });
  link.onStop([] { motors.cut(); });
  link.failsafe(1800, KMode::HOLD);
  Serial2.begin(57600);
  link.beginRadio(Serial2, KRadio::SIK);    // a second link takes over when Wi-Fi drops
  link.video(":81/stream", "cam", "mjpeg", "Front");   // a camera the app shows
}

void loop() {
  link.imu(ax, ay, az, gx, gy, gz);
  link.battery(vbat, pct);
  link.update();                            // non-blocking
}
```

| Feature | Boards |
|---------|--------|
| Wi-Fi UDP + discovery | any core with `WiFi.h` + `WiFiUdp.h` |
| BLE (Nordic-UART-style service) | ESP32 with Bluetooth enabled |
| USB serial / UART | all |
| Radio modem on a UART: SiK, XBee, HC-12, LoRa UART (`beginRadio`) | all |
| LoRa on SPI (telemetry only, 2 Hz, `fallback(LORA)`) | with `LoRa.h` installed |
| Camera declaration (`video`) | all; MJPEG serving on ESP32-CAM (`CameraRover` example) |
| Pairing key and params in flash | ESP32 (NVS). Other boards keep them in RAM until reboot. |

Callbacks are plain function pointers (capture-less lambdas), so the library
also builds on cores without `std::function`.

Radio links follow a shared profile (`kRadioProfile(KRadio::SIK)`: baud,
telemetry and control rates). On a telemetry-only radio (LoRa) the library
accepts nothing but STOP, ping, rate and bye.

Examples: `Quickstart` (drone over Wi-Fi), `ThrustBench` (sequences and cutoffs),
`SerialRover` (USB serial), `RadioRover` (SiK radio on a UART), `CameraRover`
(ESP32-CAM with live video).

Host tests: `make -C test`. They cover the protocol core and compile every snippet from
the app's Guides screen.
