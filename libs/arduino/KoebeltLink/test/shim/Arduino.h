// Minimal Arduino shim for host tests and for compiling the guide examples.
#pragma once
#include <math.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <strings.h>
// The ESP32 core pulls in POSIX names (link, unlink, close…) through Arduino.h;
// sketches must not clash with them.
#include <unistd.h>

extern uint32_t g_millis;
inline uint32_t millis() { return g_millis; }
inline void delay(uint32_t ms) { g_millis += ms; }

#define HIGH 1
#define LOW 0
#define INPUT 0
#define OUTPUT 1
#define INPUT_PULLUP 2
inline void pinMode(int, int) {}
inline void digitalWrite(int, int) {}
inline int digitalRead(int) { return HIGH; }
inline int analogRead(int) { return 2048; }
inline void analogWrite(int, int) {}

template <typename T, typename L, typename H>
inline T constrain(T v, L lo, H hi) { return v < lo ? (T)lo : v > hi ? (T)hi : v; }

class Stream {
 public:
  virtual ~Stream() = default;
  virtual int available() = 0;
  virtual int read() = 0;
  virtual size_t write(uint8_t) = 0;
  virtual size_t write(const uint8_t* b, size_t n) {
    for (size_t i = 0; i < n; i++) write(b[i]);
    return n;
  }
};

#define SERIAL_8N1 0x800001c

class HardwareSerial : public Stream {
 public:
  void begin(unsigned long) {}
  void begin(unsigned long, uint32_t, int8_t = -1, int8_t = -1) {}
  int available() override { return 0; }
  int read() override { return -1; }
  size_t write(uint8_t) override { return 1; }
  size_t write(const uint8_t*, size_t n) override { return n; }
  int availableForWrite() { return 256; }
  template <typename T> size_t print(const T&) { return 0; }
  template <typename T> size_t println(const T&) { return 0; }
  size_t println() { return 0; }
  template <typename... A> size_t printf(const char*, A...) { return 0; }
};
inline HardwareSerial Serial, Serial1, Serial2;

struct WiFiClass {
  int RSSI() { return -55; }
  const char* localIP() { return "192.168.1.42"; }
};
inline WiFiClass WiFi;
