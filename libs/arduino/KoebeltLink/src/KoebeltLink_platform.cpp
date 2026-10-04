// Board-specific transports and storage.
//   Wi-Fi UDP : ESP32, ESP8266, Raspberry Pi Pico W, Arduino UNO R4 WiFi
//               (WiFiS3), Nano 33 IoT / MKR WiFi 1010 / Nano RP2040 Connect
//               (WiFiNINA), Nano ESP32, GIGA, Portenta (WiFi.h)
//               (WiFi101: MKR1000); any other library through beginUdp(udp)
//   BLE       : ESP32 (NimBLE-Arduino if installed, else Bluedroid); nRF52
//               (Adafruit Bluefruit); Nano 33 BLE, Nano 33 IoT, UNO R4
//               WiFi, Nano RP2040 Connect (ArduinoBLE)
//   Modules   : Bluetooth / serial bridge modules on a UART (beginModule)
//   Serial    : any Arduino Stream
//   Radio     : any Stream with a radio modem on it (SiK, HC-12, XBee, LoRa UART)
//   LoRa      : sandeepmistry/arduino-LoRa (<LoRa.h>), telemetry only
//   Storage   : ESP32 Preferences (NVS); other boards keep keys in RAM only
//
// How the Arduino IDE finds libraries: it adds one only when an #include of
// it fails to resolve; __has_include never fails. So stacks that ship with a
// board's core are included directly, keyed on the board, and separate
// libraries (WiFiNINA, WiFi101, ArduinoBLE, NimBLE-Arduino, LoRa) are used
// once the sketch includes their header.
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
#if defined(ESP8266)
#include <ESP8266WiFi.h>
#include <WiFiUdp.h>
#define KLINK_HAS_WIFI 1
#elif defined(ARDUINO_UNOWIFIR4)
#include <WiFiS3.h>
#define KLINK_HAS_WIFI 1
#elif !defined(ESP32) && __has_include(<WiFiNINA.h>)  // the sketch includes <WiFiNINA.h>
#include <WiFiNINA.h>
#include <WiFiUdp.h>
#define KLINK_HAS_WIFI 1
#elif !defined(ESP32) && __has_include(<WiFi101.h>)  // the sketch includes <WiFi101.h> (MKR1000, WINC1500)
#include <WiFi101.h>
#include <WiFiUdp.h>
#define KLINK_HAS_WIFI 1
#elif defined(ESP32) || defined(ARDUINO_RASPBERRY_PI_PICO_W) || defined(ARDUINO_RASPBERRY_PI_PICO_2W) || defined(ARDUINO_PORTENTA_H7_M7) || \
    defined(ARDUINO_GIGA) || defined(ARDUINO_NICLA_VISION)
#include <WiFi.h>
#include <WiFiUdp.h>
#define KLINK_HAS_WIFI 1
#endif

#ifdef KLINK_HAS_WIFI

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
  auto* udp = new WiFiUDP();
  if (!beginUdp(*udp, port)) {
    delete udp;
    return false;
  }
  return true;
}
#else
bool KLink::begin(const char*, const char*, uint16_t) { return false; }
bool KLink::beginUdp(uint16_t) { return false; }
#endif

// ------------------------------------------------------------------ BLE
#if defined(ESP32) && __has_include(<NimBLEDevice.h>)
// NimBLE-Arduino (the sketch includes <NimBLEDevice.h>): much less RAM than
// the core's Bluedroid stack.
#include <NimBLEDevice.h>

class KNimBleTransport : public KTransport, NimBLECharacteristicCallbacks {
 public:
  bool begin(const char* name) {
    NimBLEDevice::init(name);
    NimBLEDevice::setMTU(247);
    _server = NimBLEDevice::createServer();
    NimBLEService* svc = _server->createService("6e400001-b5a3-f393-e0a9-e50e24dcca9e");
    _tx = svc->createCharacteristic("6e400003-b5a3-f393-e0a9-e50e24dcca9e", NIMBLE_PROPERTY::NOTIFY);
    NimBLECharacteristic* rx =
        svc->createCharacteristic("6e400002-b5a3-f393-e0a9-e50e24dcca9e", NIMBLE_PROPERTY::WRITE | NIMBLE_PROPERTY::WRITE_NR);
    rx->setCallbacks(this);
    svc->start();
    NimBLEAdvertising* adv = NimBLEDevice::getAdvertising();
    adv->addServiceUUID("6e400001-b5a3-f393-e0a9-e50e24dcca9e");
    return adv->start();
  }
  // NimBLE-Arduino 1.x and 2.x differ in this callback's signature: provide both.
  void onWrite(NimBLECharacteristic* c) { take(c); }
  void onWrite(NimBLECharacteristic* c, NimBLEConnInfo&) { take(c); }
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
    if (_server->getConnectedCount() == 0) return;
    size_t chunk = NimBLEDevice::getMTU() > 23 ? NimBLEDevice::getMTU() - 3 : 20;
    uint8_t tmp[256];
    if (chunk > sizeof(tmp)) chunk = sizeof(tmp);
    for (size_t o = 0; o <= len; o += chunk) {
      size_t n = (len + 1 - o) < chunk ? (len + 1 - o) : chunk;
      for (size_t i = 0; i < n; i++) tmp[i] = (o + i < len) ? msg[o + i] : '\n';
      _tx->setValue(tmp, n);
      _tx->notify();
    }
  }
  size_t maxMessage() const override { return 2000; }

 private:
  void take(NimBLECharacteristic* c) {
    std::string v = c->getValue();
    portENTER_CRITICAL(&_mux);
    for (size_t i = 0; i < v.length(); i++) {
      size_t next = (_head + 1) % sizeof(_ring);
      if (next == _tail) break;
      _ring[_head] = v[i];
      _head = next;
    }
    portEXIT_CRITICAL(&_mux);
  }
  NimBLEServer* _server = nullptr;
  NimBLECharacteristic* _tx = nullptr;
  KLineReader _lines;
  char _ring[2048];
  volatile size_t _head = 0, _tail = 0;
  portMUX_TYPE _mux = portMUX_INITIALIZER_UNLOCKED;
};

bool KLink::beginBLE() {
  auto* t = new KNimBleTransport();
  if (!t->begin(_name)) {
    delete t;
    return false;
  }
  addTransport(t);
  return true;
}

#elif defined(ESP32) && defined(CONFIG_BT_ENABLED)
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
#elif defined(ARDUINO_NRF52_ADAFRUIT)
// Adafruit nRF52 boards (Feather nRF52840, ItsyBitsy, CLUE, XIAO nRF52840
// with the Adafruit core): BLEUart is the same Nordic UART service.
#include <bluefruit.h>

class KBluefruitTransport : public KTransport {
 public:
  bool begin(const char* name) {
    if (!Bluefruit.begin()) return false;
    Bluefruit.setName(name);
    _uart.begin();
    Bluefruit.Advertising.addFlags(BLE_GAP_ADV_FLAGS_LE_ONLY_GENERAL_DISC_MODE);
    Bluefruit.Advertising.addTxPower();
    Bluefruit.Advertising.addService(_uart);
    Bluefruit.ScanResponse.addName();
    Bluefruit.Advertising.restartOnDisconnect(true);
    return Bluefruit.Advertising.start(0);
  }
  size_t read(char* buf, size_t cap) override {
    while (_uart.available() > 0) {
      size_t n = _lines.feed(static_cast<char>(_uart.read()), buf, cap);
      if (n) return n;
    }
    return 0;
  }
  void write(const char* msg, size_t len) override {
    if (!Bluefruit.connected()) return;
    _uart.write(reinterpret_cast<const uint8_t*>(msg), len);
    _uart.write('\n');
  }
  size_t maxMessage() const override { return 1000; }

 private:
  BLEUart _uart;
  KLineReader _lines;
};

bool KLink::beginBLE() {
  auto* t = new KBluefruitTransport();
  if (!t->begin(_name)) {
    delete t;
    return false;
  }
  addTransport(t);
  return true;
}

#elif __has_include(<ArduinoBLE.h>) && (defined(ARDUINO_ARCH_MBED) || defined(ARDUINO_ARCH_SAMD) || defined(ARDUINO_ARCH_RENESAS))  // the sketch includes <ArduinoBLE.h>
#include <ArduinoBLE.h>

// ArduinoBLE delivers writes from BLE.poll() through a plain callback, so the
// one transport instance is reached through a static pointer.
class KArduinoBleTransport : public KTransport {
 public:
  KArduinoBleTransport()
      : _svc("6e400001-b5a3-f393-e0a9-e50e24dcca9e"),
        _rx("6e400002-b5a3-f393-e0a9-e50e24dcca9e", BLEWrite | BLEWriteWithoutResponse, 244),
        _tx("6e400003-b5a3-f393-e0a9-e50e24dcca9e", BLENotify, 244) {}
  bool begin(const char* name) {
    if (!BLE.begin()) return false;
    _self = this;
    BLE.setLocalName(name);
    BLE.setDeviceName(name);
    BLE.setAdvertisedService(_svc);
    _svc.addCharacteristic(_rx);
    _svc.addCharacteristic(_tx);
    BLE.addService(_svc);
    _rx.setEventHandler(BLEWritten, onWrite);
    BLE.advertise();
    return true;
  }
  size_t read(char* buf, size_t cap) override {
    BLE.poll();
    while (_tail != _head) {
      char c = _ring[_tail];
      _tail = (_tail + 1) % sizeof(_ring);
      size_t n = _lines.feed(c, buf, cap);
      if (n) return n;
    }
    return 0;
  }
  void write(const char* msg, size_t len) override {
    if (!BLE.connected()) return;
    // 20-byte notifications fit the default MTU every central accepts.
    uint8_t tmp[20];
    for (size_t o = 0; o <= len; o += sizeof(tmp)) {
      size_t n = (len + 1 - o) < sizeof(tmp) ? (len + 1 - o) : sizeof(tmp);
      for (size_t i = 0; i < n; i++) tmp[i] = (o + i < len) ? msg[o + i] : '\n';
      _tx.writeValue(tmp, n);
    }
  }
  size_t maxMessage() const override { return 1000; }

 private:
  static void onWrite(BLEDevice, BLECharacteristic c) {
    KArduinoBleTransport* t = _self;
    if (!t) return;
    const uint8_t* v = c.value();
    for (int i = 0; i < c.valueLength(); i++) {
      size_t next = (t->_head + 1) % sizeof(t->_ring);
      if (next == t->_tail) break;
      t->_ring[t->_head] = static_cast<char>(v[i]);
      t->_head = next;
    }
  }
  static KArduinoBleTransport* _self;
  BLEService _svc;
  BLECharacteristic _rx, _tx;
  KLineReader _lines;
  char _ring[1024];
  size_t _head = 0, _tail = 0;
};
KArduinoBleTransport* KArduinoBleTransport::_self = nullptr;

bool KLink::beginBLE() {
  auto* t = new KArduinoBleTransport();
  if (!t->begin(_name)) {
    delete t;
    return false;
  }
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
#if defined(ESP32)
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
