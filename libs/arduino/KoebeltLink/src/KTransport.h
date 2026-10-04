#pragma once

#include <stddef.h>
#include <stdint.h>
#include <string.h>

/// One link to the app. Implementations must be non-blocking.
class KTransport {
 public:
  virtual ~KTransport() = default;
  /// Copies one complete message into buf (no terminator needed) and returns its length, or 0.
  virtual size_t read(char* buf, size_t cap) = 0;
  /// Sends one message to the current peer.
  virtual void write(const char* msg, size_t len) = 0;
  /// Replies to whoever sent the last message (used for `discover`).
  virtual void reply(const char* msg, size_t len) { write(msg, len); }
  /// Broadcasts discovery info while no app is connected.
  virtual void announce(const char* msg, size_t len) {}
  /// The last message came from a new peer that should become the session peer.
  virtual void adoptPeer() {}
  virtual void dropPeer() {}
  /// False on telemetry-only links (LoRa): the device then ignores everything
  /// that could move it and accepts only stop, ping, rate and bye.
  virtual bool acceptsControl() const { return true; }
  /// Radio links: no point clouds or tracks, state every 2 s.
  virtual bool lowBandwidth() const { return false; }
  /// Telemetry rate cap for slow links, 0 = none. At 2 Hz or less only the
  /// compact field set is sent (pos, att, gps, bat, rocket).
  virtual float maxRateHz() const { return 0; }
  virtual size_t maxMessage() const { return 65000; }
};

/// Reassembles newline-delimited messages from a byte stream.
class KLineReader {
 public:
  /// Feed one byte; returns the message length when a line completes.
  size_t feed(char c, char* out, size_t cap) {
    if (c == '\n') {
      size_t n = _n;
      _n = 0;
      if (_overflow) {
        _overflow = false;
        return 0;
      }
      if (n == 0) return 0;
      memcpy(out, _line, n < cap ? n : cap);
      return n < cap ? n : 0;
    }
    if (c == '\r') return 0;
    if (_n < sizeof(_line)) {
      _line[_n++] = c;
    } else {
      _overflow = true;
    }
    return 0;
  }

 private:
  char _line[1024];
  size_t _n = 0;
  bool _overflow = false;
};
