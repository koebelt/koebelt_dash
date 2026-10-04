// Board-specific transports and storage.
//   Wi-Fi UDP : boards with <WiFi.h> + <WiFiUdp.h> (ESP32, Pico W, Nano 33 IoT…)
//   BLE       : ESP32 (Bluedroid <BLEDevice.h>)
//   Serial    : any Arduino Stream
//   Radio     : any Stream with a radio modem on it (SiK, HC-12, XBee, LoRa UART)
//   LoRa      : sandeepmistry/arduino-LoRa (<LoRa.h>), telemetry only
//   Storage   : ESP32 Preferences (NVS); other boards keep keys in RAM only
#include <Arduino.h>

#include "KoebeltLink.h"

#if defined(ARDUINO)

// ------------------------------------------------------------------ Stream (USB serial / UART)
class KStreamTransport : public KTransport {
 public:
  explicit KStreamTransport(Stream& s, bool control = true) : _s(s), _control(control) {}
  size_t read(char* buf, size_t cap) override {
    while (_s.available() > 0) {
      size_t n = _lines.feed(static_cast<char>(_s.read()), buf, cap);
      if (n) return n;
    }
    return 0;
  }
  void write(const char* msg, size_t len) override {
    if (_s.availableForWrite() > 0 && static_cast<size_t>(_s.availableForWrite()) < len + 1) return;  // never block the loop
    _s.write(reinterpret_cast<const uint8_t*>(msg), len);
    _s.write('\n');
  }
  // One peer on a wire or radio: announcing is just writing, so the app can
  // find the device behind a radio before pairing.
  void announce(const char* msg, size_t len) override { write(msg, len); }
  bool acceptsControl() const override { return _control; }

 protected:
  Stream& _s;
  KLineReader _lines;
  bool _control;
};

/// A radio modem on a UART: same framing, rates from the radio profile.
class KRadioTransport : public KStreamTransport {
 public:
  KRadioTransport(Stream& s, const KRadioProfile& p) : KStreamTransport(s, p.ctlHz > 0), _p(p) {}
  bool lowBandwidth() const override { return true; }
  float maxRateHz() const override { return _p.tlmHz; }
  size_t maxMessage() const override { return _p.tlmHz <= 2 ? 250 : 1000; }

 private:
  const KRadioProfile& _p;
};

bool KLink::beginSerial(Stream& s) {
  addTransport(new KStreamTransport(s));
  return true;
}

bool KLink::beginRadio(Stream& s, KRadio type) {
  addTransport(new KRadioTransport(s, kRadioProfile(type)));
  return true;
}

// ------------------------------------------------------------------ Wi-Fi UDP
#if __has_include(<WiFi.h>) && __has_include(<WiFiUdp.h>)
#include <WiFi.h>
#include <WiFiUdp.h>
#define KLINK_HAS_WIFI 1

class KUdpTransport : public KTransport {
 public:
  explicit KUdpTransport(uint16_t port) : _port(port) {}
  bool begin() { return _udp.begin(_port) == 1; }
  size_t read(char* buf, size_t cap) override {
    int n = _udp.parsePacket();
    if (n <= 0) return 0;
    _from = _udp.remoteIP();
    _fromPort = _udp.remotePort();
    int r = _udp.read(buf, cap);
    if (r <= 0 || static_cast<size_t>(n) > cap) return 0;
    // Only the session peer (or anyone before a session) may talk to us.
    if (_hasPeer && (_from != _peer || _fromPort != _peerPort) && !isOpen(buf, r)) return 0;
    return static_cast<size_t>(r);
  }
  void write(const char* msg, size_t len) override {
    if (!_hasPeer) return;
    _udp.beginPacket(_peer, _peerPort);
    _udp.write(reinterpret_cast<const uint8_t*>(msg), len);
    _udp.endPacket();
  }
  void reply(const char* msg, size_t len) override {
    _udp.beginPacket(_from, _fromPort);
    _udp.write(reinterpret_cast<const uint8_t*>(msg), len);
    _udp.endPacket();
  }
  void announce(const char* msg, size_t len) override {
    _udp.beginPacket(IPAddress(255, 255, 255, 255), 47801);
    _udp.write(reinterpret_cast<const uint8_t*>(msg), len);
    _udp.endPacket();
  }
  void adoptPeer() override {
    _peer = _from;
    _peerPort = _fromPort;
    _hasPeer = true;
  }
  void dropPeer() override { _hasPeer = false; }
  size_t maxMessage() const override { return 1460; }

 private:
  // hello / pair / discover are accepted from anyone.
  static bool isOpen(const char* b, int n) {
    for (const char* t : {"\"hello\"", "\"pair\"", "\"discover\""})
      if (memmem(b, n, t, strlen(t))) return true;
    return false;
  }
  WiFiUDP _udp;
  uint16_t _port;
  IPAddress _from, _peer;
  uint16_t _fromPort = 0, _peerPort = 0;
  bool _hasPeer = false;
};

bool KLink::begin(const char* ssid, const char* pass, uint16_t port) {
  if (WiFi.status() != WL_CONNECTED) {
    WiFi.begin(ssid, pass);
    uint32_t t0 = millis();
    while (WiFi.status() != WL_CONNECTED && millis() - t0 < 15000) delay(100);
    if (WiFi.status() != WL_CONNECTED) return false;
  }
  return beginUdp(port);
}

bool KLink::beginUdp(uint16_t port) {
  auto* t = new KUdpTransport(port);
  if (!t->begin()) {
    delete t;
    return false;
  }
  addTransport(t);
  return true;
}
#else
bool KLink::begin(const char*, const char*, uint16_t) { return false; }
bool KLink::beginUdp(uint16_t) { return false; }
#endif

// ------------------------------------------------------------------ BLE (ESP32)
#if defined(ESP32) && __has_include(<BLEDevice.h>) && defined(CONFIG_BT_ENABLED)
#include <BLE2902.h>
#include <BLEDevice.h>
#include <BLEServer.h>

class KBleTransport : public KTransport, BLEServerCallbacks, BLECharacteristicCallbacks {
 public:
  bool begin(const char* name) {
    BLEDevice::init(name);
    BLEDevice::setMTU(247);
    _server = BLEDevice::createServer();
    _server->setCallbacks(this);
    BLEService* svc = _server->createService("6e400001-b5a3-f393-e0a9-e50e24dcca9e");
    _tx = svc->createCharacteristic("6e400003-b5a3-f393-e0a9-e50e24dcca9e", BLECharacteristic::PROPERTY_NOTIFY);
    _tx->addDescriptor(new BLE2902());
    BLECharacteristic* rx = svc->createCharacteristic("6e400002-b5a3-f393-e0a9-e50e24dcca9e",
                                                      BLECharacteristic::PROPERTY_WRITE | BLECharacteristic::PROPERTY_WRITE_NR);
    rx->setCallbacks(this);
    svc->start();
    BLEAdvertising* adv = BLEDevice::getAdvertising();
    adv->addServiceUUID("6e400001-b5a3-f393-e0a9-e50e24dcca9e");
    adv->setScanResponse(true);
    BLEDevice::startAdvertising();
    _mux = portMUX_INITIALIZER_UNLOCKED;
    return true;
  }
  // BLE callbacks run on another task: bytes go through a small ring buffer.
  void onWrite(BLECharacteristic* c) override {
    String v = c->getValue();
    portENTER_CRITICAL(&_mux);
    for (size_t i = 0; i < v.length(); i++) {
      size_t next = (_head + 1) % sizeof(_ring);
      if (next == _tail) break;
      _ring[_head] = v[i];
      _head = next;
    }
    portEXIT_CRITICAL(&_mux);
  }
  void onConnect(BLEServer*) override { _connected = true; }
  void onDisconnect(BLEServer*) override {
    _connected = false;
    BLEDevice::startAdvertising();
  }
  size_t read(char* buf, size_t cap) override {
    while (true) {
      char c;
      portENTER_CRITICAL(&_mux);
      bool has = _tail != _head;
      if (has) {
        c = _ring[_tail];
        _tail = (_tail + 1) % sizeof(_ring);
      }
      portEXIT_CRITICAL(&_mux);
      if (!has) return 0;
      size_t n = _lines.feed(c, buf, cap);
      if (n) return n;
    }
  }
  void write(const char* msg, size_t len) override {
    if (!_connected) return;
    size_t chunk = BLEDevice::getMTU() > 23 ? BLEDevice::getMTU() - 3 : 20;
    for (size_t o = 0; o <= len; o += chunk) {
      size_t n = (len + 1 - o) < chunk ? (len + 1 - o) : chunk;
      uint8_t tmp[256];
      for (size_t i = 0; i < n; i++) tmp[i] = (o + i < len) ? msg[o + i] : '\n';
      _tx->setValue(tmp, n);
      _tx->notify();
    }
  }
  size_t maxMessage() const override { return 2000; }

 private:
  BLEServer* _server = nullptr;
  BLECharacteristic* _tx = nullptr;
  KLineReader _lines;
  char _ring[2048];
  volatile size_t _head = 0, _tail = 0;
  portMUX_TYPE _mux;
  volatile bool _connected = false;
};

bool KLink::beginBLE() {
  auto* t = new KBleTransport();
  if (!t->begin(_name)) return false;
  addTransport(t);
  return true;
}
#else
bool KLink::beginBLE() { return false; }
#endif

// ------------------------------------------------------------------ LoRa (telemetry-only fallback)
#if __has_include(<LoRa.h>)
#include <LoRa.h>

class KLoraTransport : public KTransport {
 public:
  size_t read(char* buf, size_t cap) override {
    int n = LoRa.parsePacket();
    if (n <= 0) return 0;
    size_t i = 0;
    while (LoRa.available() && i < cap) buf[i++] = static_cast<char>(LoRa.read());
    return i;
  }
  void write(const char* msg, size_t len) override {
    if (len > 250) return;
    LoRa.beginPacket();
    LoRa.write(reinterpret_cast<const uint8_t*>(msg), len);
    LoRa.endPacket(true);  // async
  }
  bool acceptsControl() const override { return false; }
  bool lowBandwidth() const override { return true; }
  float maxRateHz() const override { return 2; }
  size_t maxMessage() const override { return 250; }
};
#endif

bool KLink::fallback(TransportType t, double param) {
  switch (t) {
#if __has_include(<LoRa.h>)
    case LORA:
      if (!LoRa.begin(static_cast<long>(param))) return false;
      addTransport(new KLoraTransport());
      return true;
#endif
    case BLE:
      return beginBLE();
    case WIFI:
      return beginUdp(param > 0 ? static_cast<uint16_t>(param) : 47800);
    case SERIAL_PORT:
      return beginSerial(Serial);
    default:
      return false;
  }
}

// ------------------------------------------------------------------ storage
#if defined(ESP32) && __has_include(<Preferences.h>)
#include <Preferences.h>

// NVS keys are limited to 15 chars, so parameters are stored under a hash of their key.
static uint32_t hash(const char* s) {
  uint32_t h = 2166136261u;
  while (*s) h = (h ^ static_cast<uint8_t>(*s++)) * 16777619u;
  return h;
}

void KLink::loadStore() {
  Preferences p;
  if (!p.begin("klink", true)) return;
  p.getString("key", _key, sizeof(_key));
  for (uint8_t i = 0; i < _nParams; i++) {
    char k[16];
    snprintf(k, sizeof(k), "p%08lx", static_cast<unsigned long>(hash(_params[i].key)));
    if (p.isKey(k)) _params[i].value = p.getFloat(k, _params[i].value);
  }
  p.end();
}
bool KLink::storeKey() {
  Preferences p;
  if (!p.begin("klink", false)) return false;
  bool ok = p.putString("key", _key) > 0 || !_key[0];
  p.end();
  return ok;
}
bool KLink::saveParams() {
  Preferences p;
  if (!p.begin("klink", false)) return false;
  for (uint8_t i = 0; i < _nParams; i++) {
    char k[16];
    snprintf(k, sizeof(k), "p%08lx", static_cast<unsigned long>(hash(_params[i].key)));
    p.putFloat(k, _params[i].value);
  }
  p.end();
  return true;
}
#else
void KLink::loadStore() {}
bool KLink::storeKey() { return false; }
bool KLink::saveParams() { return false; }
#endif

#else  // host build (tests): no board transports, RAM-only storage

bool KLink::begin(const char*, const char*, uint16_t) { return false; }
bool KLink::beginUdp(uint16_t) { return false; }
bool KLink::beginBLE() { return false; }
bool KLink::beginSerial(Stream&) { return false; }
bool KLink::beginRadio(Stream&, KRadio) { return false; }
bool KLink::fallback(TransportType, double) { return false; }
void KLink::loadStore() {}
bool KLink::storeKey() { return true; }
bool KLink::saveParams() { return true; }

#endif
