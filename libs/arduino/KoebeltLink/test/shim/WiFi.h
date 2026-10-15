// Wi-Fi shim. As on real cores, WiFi needs its own include in the sketch.
#pragma once
#include <Arduino.h>

struct WiFiClass {
  int RSSI() { return -55; }
  const char* localIP() { return "192.168.1.42"; }
};
inline WiFiClass WiFi;
