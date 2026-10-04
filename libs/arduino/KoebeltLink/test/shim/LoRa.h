// Host stand-in for sandeepmistry/arduino-LoRa, so sketches that include it compile.
#pragma once
#include <stddef.h>
#include <stdint.h>

struct LoRaClass {
  int begin(long) { return 1; }
  int parsePacket() { return 0; }
  int available() { return 0; }
  int read() { return -1; }
  int beginPacket() { return 1; }
  size_t write(const uint8_t*, size_t n) { return n; }
  size_t write(uint8_t) { return 1; }
  size_t print(const char*) { return 0; }
  int endPacket(bool = false) { return 1; }
};
inline LoRaClass LoRa;
