// A board without Wi-Fi (Arduino Zero, Teensy, STM32 Nucleo…) plus an
// ESP-01 or ESP32 running Espressif's AT firmware, through the WiFiEspAT
// library. Its WiFiUDP works with beginUdp() like any other.
#include <WiFiEspAT.h>
#include <KoebeltLink.h>

WiFiUDP udp;
KLink klink("Zero-Rover", KLink::ROVER);

void setup() {
  Serial.begin(115200);
  Serial1.begin(115200);  // the AT module's baud rate
  WiFi.init(Serial1);
  WiFi.begin("your-ssid", "your-password");
  klink.beginUdp(udp);
  klink.onControl([](const KControl& c) { /* drive c.ry, steer c.lx */ });
}

void loop() {
  klink.battery(7.4f, 80);
  klink.update();
}
