// Runs on any supported board: Wi-Fi where the board has it, otherwise
// Bluetooth LE, otherwise USB serial. Tested in CI on ESP32, ESP8266,
// Raspberry Pi Pico W, Arduino UNO R4 WiFi, Nano 33 IoT and Nano 33 BLE.
#include <KoebeltLink.h>

// Libraries that are not part of the board's core must be included by the
// sketch for the IDE to link them; koebelt/link then uses them.
#if defined(ARDUINO_SAMD_NANO_33_IOT) || defined(ARDUINO_SAMD_MKRWIFI1010) || defined(ARDUINO_NANO_RP2040_CONNECT)
#include <WiFiNINA.h>
#endif
#if defined(ARDUINO_ARDUINO_NANO33BLE) || defined(ARDUINO_SAMD_NANO_33_IOT) || defined(ARDUINO_UNOWIFIR4) || defined(ARDUINO_NANO_RP2040_CONNECT)
#include <ArduinoBLE.h>
#endif

const char* WIFI_SSID = "your-ssid";
const char* WIFI_PASS = "your-password";

KLink klink("Mule", KLink::ROVER);
float speed = 0, turn = 0;

void setup() {
  Serial.begin(115200);
  if (klink.begin(WIFI_SSID, WIFI_PASS)) {
    Serial.println("KoebeltLink on Wi-Fi");
  } else if (klink.beginBLE()) {
    Serial.println("KoebeltLink on Bluetooth LE");
  } else {
    klink.beginSerial(Serial);  // from here on, Serial belongs to koebelt/link
  }
  klink.onControl([](const KControl& c) { speed = c.ry; turn = c.lx; });
  klink.onStop([] { speed = turn = 0; });
  klink.failsafe(1000, KMode::HOLD);
}

void loop() {
  static float x = 0, y = 0, h = 0;
  float s = klink.stopped() || !klink.armed() ? 0 : speed * klink.speedLimit() * 2;
  h -= turn * 0.02f;
  x += cosf(h) * s * 0.02f;
  y += sinf(h) * s * 0.02f;
  klink.position(x, y, 0);
  klink.attitude(0, 0, h);
  klink.battery(7.4f, 80);
  klink.update();
  delay(20);
}
