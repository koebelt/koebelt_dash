// koebelt/link · connect a device to the koebelt/dash app.
// Protocol: protocol/PROTOCOL.md in https://github.com/koebelt/koebelt_dash
#pragma once

#include <ArduinoJson.h>
#include <stddef.h>
#include <initializer_list>
#include <stdint.h>

#include "KTransport.h"
#include "KUdp.h"

#define KOEBELT_LINK_VERSION "1.5.0"

class Stream;

#ifndef KLINK_MAX_PARAMS
#define KLINK_MAX_PARAMS 48
#endif
#ifndef KLINK_MAX_CHANNELS
#define KLINK_MAX_CHANNELS 8
#endif
#ifndef KLINK_MAX_TRACKS
#define KLINK_MAX_TRACKS 16
#endif
#ifndef KLINK_MSG_SIZE
#define KLINK_MSG_SIZE 2048
#endif

enum class KMode : uint8_t { AUTO, MANUAL, HOLD, TAKEOFF, LAND, RTH, PAD, COUNT, BOOST, COAST, DROGUE, MAIN, LANDED, IDLE, RAMP, STEPS, CUTOFF, UNKNOWN };

const char* kModeName(KMode m);
KMode kModeParse(const char* s);

/// Radio modems on a UART, talking to a matching radio on the app side
/// (protocol/PROTOCOL.md, "Radio links"). Same profiles in every library.
enum class KRadio : uint8_t { SIK, LORA, HC12, XBEE, OTHER };
struct KRadioProfile {
  const char* id;
  uint32_t baud;   // UART speed the module is usually configured for
  uint8_t tlmHz;   // telemetry rate over the air
  uint8_t ctlHz;   // control heartbeat, 0 = telemetry only
};
const KRadioProfile& kRadioProfile(KRadio r);

/// Four normalised axes −1…1. Sticks, sliders and tilt all arrive here.
struct KControl {
  float lx = 0, ly = 0, rx = 0, ry = 0;
  uint32_t seq = 0;
};

class KLink;

/// Handle to a tunable parameter. Cheap to copy.
class KParam {
 public:
  KParam() = default;
  float value() const;
  operator float() const { return value(); }
  void onChange(void (*cb)(float));
  bool valid() const { return _l != nullptr; }

 private:
  friend class KLink;
  KParam(KLink* l, uint8_t i) : _l(l), _i(i) {}
  KLink* _l = nullptr;
  uint8_t _i = 0;
};

/// Handle to a custom telemetry channel (1–6 axes).
class KChannel {
 public:
  KChannel() = default;
  template <typename... T>
  void publish(T... v) {
    const float vals[] = {static_cast<float>(v)...};
    publishArray(vals, sizeof...(T));
  }
  void publishArray(const float* v, uint8_t n);

 private:
  friend class KLink;
  KChannel(KLink* l, uint8_t i) : _l(l), _i(i) {}
  KLink* _l = nullptr;
  uint8_t _i = 0;
};

class KLink {
 public:
  enum Kind : uint8_t { DRONE, ROVER, ARM, ROCKET, BENCH, GENERIC };
  enum TransportType : uint8_t { WIFI, BLE, SERIAL_PORT, LORA };

  KLink(const char* name, Kind kind, const char* id = nullptr);

  // ---- transports (platform specific, see KoebeltLink_platform.cpp)
  /// Join Wi-Fi and listen on UDP 47800. Returns false if Wi-Fi is unavailable on this board.
  bool begin(const char* ssid, const char* pass, uint16_t port = 47800);
  /// Use an already-connected network interface (Ethernet, Wi-Fi joined elsewhere).
  bool beginUdp(uint16_t port = 47800);
  /// Advertise the koebelt/link BLE service: ESP32 (NimBLE-Arduino if
  /// installed, else the core's Bluedroid), nRF52 (Adafruit Bluefruit), and
  /// ArduinoBLE boards (Nano 33 BLE / IoT, UNO R4 WiFi, Nano RP2040 Connect).
  bool beginBLE();
  /// Newline-delimited JSON over any Stream (USB serial).
  bool beginSerial(Stream& s);
  /// A radio modem on a UART (SiK, HC-12, XBee, a LoRa UART module). Start the
  /// UART at kRadioProfile(type).baud first. Rates follow the profile.
  bool beginRadio(Stream& s, KRadio type = KRadio::SIK);
  /// A serial bridge module on a UART: Bluetooth LE modules (HM-10, AT-09,
  /// BT05, JDY, HC-08, RN4870, DFRobot Bluno), Bluetooth Classic modules
  /// (HC-05, HC-06). Start the UART at the module's baud first; telemetry
  /// follows it: 2 Hz up to 19200 baud, 5 Hz to 57600, 10 Hz above.
  bool beginModule(Stream& s, uint32_t baud = 9600);
  /// UDP through a networking library you set up yourself: Ethernet (W5500,
  /// W5100, ENC28J60 with EthernetENC), QNEthernet on Teensy 4.1, WiFiEspAT
  /// (an ESP-01 or ESP32 running ESP-AT as Wi-Fi co-processor), WiFi101…
  /// Pass its UDP object; the library calls begin(port) on it.
  template <typename U>
  bool beginUdp(U& udp, uint16_t port = 47800) {
    if (udp.begin(port) != 1) return false;
    addTransport(new KUdpTransportT<U>(udp));
    return true;
  }
  /// Second transport used when the first goes quiet. LORA takes a frequency in Hz.
  bool fallback(TransportType t, double param = 0);
  /// Any custom transport.
  void addTransport(KTransport* t);

  /// Call every loop. Non-blocking.
  void update();

  // ---- identity
  void setModel(const char* model) { _model = model; }
  void setFirmware(const char* fw) { _fw = fw; }
  void setSensors(const char* csv) { _sensors = csv; }
  /// Declares a camera stream the app shows (MJPEG over HTTP). `url` may be
  /// ":81/stream" (port and path on this device's IP) or a full URL.
  void video(const char* url, const char* id = "cam", const char* fmt = "mjpeg", const char* label = nullptr);

  // ---- telemetry (latest value is sent at the app's telemetry rate)
  void imu(float ax, float ay, float az, float gx, float gy, float gz);
  void attitude(float roll, float pitch, float yaw);
  void position(float x, float y, float z);
  void velocity(float vx, float vy, float vz);
  void gps(double lat, double lon, float alt, uint8_t sats = 0);
  void battery(float volts, float percent, float amps = 0);
  void rssi(float dbm);
  void joints(const float* rad, uint8_t n);
  void tool(float x, float y, float z, float gripper);
  void forceTorque(float fx, float fy, float fz);
  void thrust(float newtons, float torqueNm = 0);
  void rpm(float v);
  void temperature(float c);
  void throttleOut(float v);
  /// Rockets: highest altitude so far (m), time in the current flight phase (s), countdown left (s).
  void rocketState(float maxAltM, float phaseTimeS, float countdownS = 0);
  /// Point cloud in metres, local frame. Sent at most 10 Hz, in chunks.
  void points(const float (*xyz)[3], uint16_t n);
  /// Radar / safety scanner targets; call clearTracks() then track() each scan.
  void clearTracks();
  void track(const char* id, float rangeM, float bearingRad);
  void log(const char* msg, const char* level = "info");

  // ---- state reported by the device
  void setMode(KMode m);
  void setArmed(bool armed);
  void setPyro(const char* ch0, const char* ch1, const char* ch2, const char* ch3);
  void setCutoff(const char* reason);
  /// Any other kind-specific state shown in the app, as text (up to 4 keys).
  void setState(const char* key, const char* value);
  KMode mode() const { return _mode; }
  bool armed() const { return _armed; }
  bool stopped() const { return _estop; }
  bool failsafeActive() const { return _fsActive; }
  bool connected() const;
  const KControl& control() const { return _ctl; }
  float speedLimit() const { return _speed; }

  // ---- callbacks
  void onControl(void (*cb)(const KControl&)) { _cbControl = cb; }
  void onMode(void (*cb)(KMode)) { _cbMode = cb; }
  void onStop(void (*cb)()) { _cbStop = cb; }
  void onReset(void (*cb)()) { _cbReset = cb; }
  void onArm(void (*cb)(bool)) { _cbArm = cb; }
  void onJog(void (*cb)(const float* joints6)) { _cbJog = cb; }
  void onCartesian(void (*cb)(const float* xyz)) { _cbCart = cb; }
  void onCommand(void (*cb)(const char* name, JsonObjectConst args)) { _cbCmd = cb; }
  void onParamsWritten(void (*cb)()) { _cbWritten = cb; }
  /// Called when the app opens a session.
  void onConnect(void (*cb)()) { _cbConnect = cb; }

  // ---- safety
  /// Switch to `mode` after `timeoutMs` without a control packet. Default 1800 ms, HOLD.
  void failsafe(uint32_t timeoutMs, KMode mode);

  // ---- parameters and channels
  KParam param(const char* key, float def, float min, float max, const char* unit = "", float step = 0, const char* label = nullptr);
  bool saveParams();
  KChannel channel(const char* id, std::initializer_list<const char*> axes, const char* unit = "", float hz = 10);

  // ---- pairing
  void pair(const char* code);
  void unpair();
  bool paired() const { return _key[0] != 0; }

  // Used by handles.
  float _paramValue(uint8_t i) const { return _params[i].value; }
  void _paramOnChange(uint8_t i, void (*cb)(float)) { _params[i].cb = cb; }
  void _channelPublish(uint8_t i, const float* v, uint8_t n);

  /// Processes one raw message (exposed for tests and custom transports).
  void handle(KTransport* from, const char* json, size_t len);

 private:
  struct Param {
    const char* key;
    const char* unit;
    const char* label;
    float value, min, max, step;
    void (*cb)(float);
  };
  struct Channel {
    const char* id;
    const char* axes[6];
    uint8_t n;
    const char* unit;
    float hz;
    float v[6];
    bool dirty;
  };
  struct Track {
    char id[8];
    float r, b;
  };
  enum Tlm : uint16_t { T_IMU = 1, T_ATT = 2, T_POS = 4, T_VEL = 8, T_GPS = 16, T_BAT = 32, T_RSSI = 64, T_JOINTS = 128, T_TOOL = 256, T_FT = 512,
                        T_THRUST = 1024, T_RPM = 2048, T_TEMP = 4096, T_THR = 8192, T_ROCKET = 16384 };

  void send(JsonDocument& d, KTransport* to = nullptr);
  void sendHello(KTransport* t);
  void sendParams(KTransport* t);
  void sendChannels(KTransport* t);
  void sendState();
  void sendTelemetry();
  void sendCloud();
  void announce();
  void changeMode(KMode m, bool notify);
  void checkFailsafe(uint32_t now);
  void loadStore();
  bool storeKey();

  const char* _name;
  char _id[32];
  Kind _kind;
  const char* _model = "";
  const char* _fw = "";
  const char* _sensors = "";

  KTransport* _transports[4] = {};
  uint8_t _nTransports = 0;
  KTransport* _active = nullptr;

  KControl _ctl;
  KMode _mode;
  bool _armed = false, _estop = false, _session = false, _stateDirty = true;
  float _speed = 0.5f;
  float _rateHz = 30;
  uint32_t _lastCtl = 0, _tState = 0, _tTlm = 0, _tAnnounce = 0, _tCloud = 0, _lastRx = 0;

  uint32_t _fsTimeout = 1800;
  KMode _fsMode = KMode::HOLD;
  bool _fsActive = false;

  char _pairCode[12] = {};
  char _key[40] = {};

  Param _params[KLINK_MAX_PARAMS];
  uint8_t _nParams = 0;
  Channel _channels[KLINK_MAX_CHANNELS];
  uint8_t _nChannels = 0;
  Track _tracks[KLINK_MAX_TRACKS];
  uint8_t _nTracks = 0;
  bool _tracksDirty = false;

  // telemetry values
  uint16_t _dirty = 0;
  float _imu[6], _att[3], _pos[3], _vel[3], _bat[3], _rssi, _joints[6], _tool[4], _ft[3], _thrust[2], _rpm, _temp, _thr, _rocket[3];
  double _gpsLL[2];
  float _gpsAlt;
  uint8_t _gpsSats, _nJoints = 0;
  const float (*_cloud)[3] = nullptr;
  uint16_t _cloudN = 0;

  const char* _pyro[4] = {"OK", "OK", "OK", "-"};
  const char* _cutoff = nullptr;
  const char* _extKey[4] = {};
  const char* _extVal[4] = {};
  struct Video {
    const char *id, *url, *fmt, *label;
  };
  Video _video[2] = {};
  uint8_t _nVideo = 0;

  void (*_cbControl)(const KControl&) = nullptr;
  void (*_cbMode)(KMode) = nullptr;
  void (*_cbStop)() = nullptr;
  void (*_cbReset)() = nullptr;
  void (*_cbArm)(bool) = nullptr;
  void (*_cbJog)(const float*) = nullptr;
  void (*_cbCart)(const float*) = nullptr;
  void (*_cbCmd)(const char*, JsonObjectConst) = nullptr;
  void (*_cbWritten)() = nullptr;
  void (*_cbConnect)() = nullptr;

  char _buf[KLINK_MSG_SIZE];
};
