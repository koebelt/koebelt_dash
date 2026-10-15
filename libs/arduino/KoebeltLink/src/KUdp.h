#pragma once

#include <stddef.h>
#include <stdint.h>
#include <string.h>

#include "KTransport.h"

/// One JSON message per datagram over any Arduino networking library's UDP
/// class: WiFiUDP (ESP32, ESP8266, Pico W, WiFiNINA, WiFiS3, WiFi101,
/// WiFiEspAT), EthernetUDP (W5100/W5500, ENC28J60 with EthernetENC, STM32
/// Ethernet), QNEthernet on Teensy 4.1… Anything with the usual methods.
// std::declval, which AVR cores do not ship.
template <typename T>
T& kDeclval();

template <typename U>
class KUdpTransportT : public KTransport {
  typedef decltype(kDeclval<U>().remoteIP()) Addr;

 public:
  explicit KUdpTransportT(U& udp) : _udp(udp) {}

  size_t read(char* buf, size_t cap) override {
    int n = _udp.parsePacket();
    if (n <= 0) return 0;
    _from = _udp.remoteIP();
    _fromPort = _udp.remotePort();
    int r = _udp.read(buf, cap);
    if (r <= 0 || static_cast<size_t>(n) > cap) return 0;
    // Only the session peer (or anyone before a session) may talk to us.
    if (_hasPeer && (!(_from == _peer) || _fromPort != _peerPort) && !isOpen(buf, r)) return 0;
    return static_cast<size_t>(r);
  }
  void write(const char* msg, size_t len) override {
    if (_hasPeer) send(_peer, _peerPort, msg, len);
  }
  void reply(const char* msg, size_t len) override { send(_from, _fromPort, msg, len); }
  void announce(const char* msg, size_t len) override { send(Addr(255, 255, 255, 255), 47801, msg, len); }
  void adoptPeer() override {
    _peer = _from;
    _peerPort = _fromPort;
    _hasPeer = true;
  }
  void dropPeer() override { _hasPeer = false; }
  size_t maxMessage() const override { return 1460; }

 private:
  void send(Addr to, uint16_t port, const char* msg, size_t len) {
    _udp.beginPacket(to, port);
    _udp.write(reinterpret_cast<const uint8_t*>(msg), len);
    _udp.endPacket();
  }
  // hello / pair / discover are accepted from anyone.
  static bool isOpen(const char* b, int n) {
    for (const char* t : {"\"hello\"", "\"pair\"", "\"discover\""}) {
      int k = static_cast<int>(strlen(t));
      for (int i = 0; i + k <= n; i++)
        if (!memcmp(b + i, t, k)) return true;  // memmem is not in every libc
    }
    return false;
  }
  U& _udp;
  Addr _from, _peer;
  uint16_t _fromPort = 0, _peerPort = 0;
  bool _hasPeer = false;
};
