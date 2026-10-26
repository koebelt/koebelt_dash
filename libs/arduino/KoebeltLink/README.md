# koebelt/link (Arduino)

For ESP32 (Wi-Fi, BLE, flash storage), RP2040 W and other Wi-Fi boards (UDP),
and any board with a `Stream` (USB serial or UART radio). It depends on
ArduinoJson 7.

Install it from the Arduino IDE (Sketch > Include Library > Manage
Libraries, search **KoebeltLink**), with `arduino-cli lib install KoebeltLink`,
or in PlatformIO with `lib_deps = koebelt/KoebeltLink@^1.0.0`.

```cpp
#include <KoebeltLink.h>

KLink klink("Kite-03", KLink::DRONE);

void setup() {
  klink.begin(WIFI_SSID, WIFI_PASS);         // or beginBLE(), beginSerial(Serial)
  klink.onControl([](const KControl& c) { throttle = c.ly; yaw = c.lx; pitch = c.ry; roll = c.rx; });
  klink.onStop([] { motors.cut(); });
  klink.failsafe(1800, KMode::HOLD);
  Serial2.begin(57600);
  klink.beginRadio(Serial2, KRadio::SIK);    // a second link takes over when Wi-Fi drops
  klink.video(":81/stream", "cam", "mjpeg", "Front");   // a camera the app shows
  front = klink.proximity("front", 4.0, 0, "ultrasonic");  // KProx front; a sensor the app shows from above
}

void loop() {
  klink.imu(ax, ay, az, gx, gy, gz);
  front.set(sonarMetres());                  // negative, or front.clear(): nothing in range
  klink.battery(vbat, pct);
  klink.update();                            // non-blocking
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
| Any networking library's UDP (`beginUdp(udp)`): W5500/W5100/ENC28J60 Ethernet, QNEthernet, WiFiEspAT, WiFi101 | all |
| Bluetooth serial modules (`beginModule`): HM-10 family, HC-05/06, RN4870, Bluno | all |
| BLE through NimBLE-Arduino (ESP32), Adafruit Bluefruit (nRF52), ArduinoBLE | those boards |
| Pairing key and params in flash | ESP32 (NVS). Other boards keep them in RAM until reboot. |

**ESP32 with Wi-Fi and Bluetooth in one sketch** does not fit the default
1.2 MB app partition: pick Tools > Partition Scheme > Huge APP, or use
NimBLE-Arduino (include `<NimBLEDevice.h>`), which is much smaller.

**Libraries that are not part of your board's core** (WiFiNINA, WiFi101,
ArduinoBLE, NimBLE-Arduino, LoRa) are used once your sketch includes their
header: the Arduino IDE only links libraries a sketch includes. Stacks that
ship with the core (ESP32 Wi-Fi and Bluetooth, ESP8266, Pico W, UNO R4 WiFi,
Adafruit nRF52 Bluefruit) need nothing.

**Any other network or Bluetooth chip:**

```cpp
EthernetUDP udp;             // or WiFiUDP from WiFiEspAT, WiFi101, QNEthernet…
klink.beginUdp(udp);          // any library's UDP object

Serial1.begin(9600);         // HM-10, HC-05, JDY, RN4870, Bluno… on a UART
klink.beginModule(Serial1, 9600);
```

Callbacks are plain function pointers (capture-less lambdas), so the library
also builds on cores without `std::function`.

Radio links follow a shared profile (`kRadioProfile(KRadio::SIK)`: baud,
telemetry and control rates). On a telemetry-only radio (LoRa) the library
accepts nothing but STOP, ping, rate and bye.

Examples: `Quickstart` (drone over Wi-Fi), `ThrustBench` (sequences and cutoffs),
`SerialRover` (USB serial), `RadioRover` (SiK radio on a UART), `CameraRover`
(ESP32-CAM with live video), `AnyBoard` (Wi-Fi, BLE or serial, whatever the
board has), `BluetoothModule` (HM-10 / HC-05 on a UART), `EthernetW5500`,
`EspAtCoprocessor` (ESP-01 as Wi-Fi for boards without it), `NimBLE`.

Host tests: `make -C test` in [koebelt/dash](https://github.com/koebelt/koebelt_dash/tree/main/libs/arduino/KoebeltLink).
They cover the protocol core and compile every snippet from the app's Guides screen.

The library is developed in [koebelt/dash](https://github.com/koebelt/koebelt_dash),
next to the app, the [protocol](https://github.com/koebelt/koebelt_dash/blob/main/protocol/PROTOCOL.md)
and the Python, Rust and ROS 2 versions. The KoebeltLink repository is a copy
made on each release: open issues and pull requests in koebelt/dash.

MIT licence.
