// Platform-independent core: message handling, telemetry, failsafe, params.
// Transports and storage live in KoebeltLink_platform.cpp.
#include "KoebeltLink.h"

#include <Arduino.h>
#include <ctype.h>
#include <math.h>
#include <stdio.h>
#include <string.h>

static const char* const MODE_NAMES[] = {"AUTO", "MANUAL", "HOLD", "TAKEOFF", "LAND", "RTH", "PAD", "COUNT", "BOOST",
                                         "COAST", "DROGUE", "MAIN", "LANDED", "IDLE", "RAMP", "STEPS", "CUTOFF", "UNKNOWN"};
static const char* const KIND_NAMES[] = {"drone", "rover", "arm", "rocket", "bench", "generic"};

const char* kModeName(KMode m) { return MODE_NAMES[static_cast<uint8_t>(m)]; }

// Keep in step with protocol/vectors.json ("radio").
static const KRadioProfile RADIO_PROFILES[] = {
    {"sik", 57600, 5, 10}, {"lora", 115200, 2, 0}, {"hc12", 9600, 2, 5}, {"xbee", 57600, 5, 10}, {"other", 57600, 2, 5},
};
const KRadioProfile& kRadioProfile(KRadio r) { return RADIO_PROFILES[static_cast<uint8_t>(r)]; }

/// A UART bridge module: a Bluetooth module (HM-10, HC-05/HC-06, JDY,
/// RN4870, Bluno) or any transparent serial link whose speed is set by its
/// UART. Telemetry follows the baud rate so the module's buffer never
/// overflows: 2 Hz compact up to 19200 baud, 5 Hz to 57600, 10 Hz above.
class KModuleTransport : public KTransport {
 public:
  KModuleTransport(Stream& s, uint32_t baud) : _s(s), _baud(baud) {}
  size_t read(char* buf, size_t cap) override {
    while (_s.available() > 0) {
      size_t n = _lines.feed(static_cast<char>(_s.read()), buf, cap);
      if (n) return n;
    }
    return 0;
  }
  void write(const char* msg, size_t len) override {
    _s.write(reinterpret_cast<const uint8_t*>(msg), len);
    _s.write('\n');
  }
  void announce(const char* msg, size_t len) override { write(msg, len); }
  bool lowBandwidth() const override { return true; }
  float maxRateHz() const override { return _baud <= 19200 ? 2 : _baud <= 57600 ? 5 : 10; }
  size_t maxMessage() const override { return _baud <= 19200 ? 250 : 1000; }

 private:
  Stream& _s;
  uint32_t _baud;
  KLineReader _lines;
};

bool KLink::beginModule(Stream& s, uint32_t baud) {
  addTransport(new KModuleTransport(s, baud));
  return true;
}

KMode kModeParse(const char* s) {
  if (!s) return KMode::UNKNOWN;
  for (uint8_t i = 0; i < static_cast<uint8_t>(KMode::UNKNOWN); i++)
    if (strcmp(s, MODE_NAMES[i]) == 0) return static_cast<KMode>(i);
  return KMode::UNKNOWN;
}

float KParam::value() const { return _l ? _l->_paramValue(_i) : 0; }
void KParam::onChange(void (*cb)(float)) {
  if (_l) _l->_paramOnChange(_i, cb);
}
void KChannel::publishArray(const float* v, uint8_t n) {
  if (_l) _l->_channelPublish(_i, v, n);
}

void KProx::set(float metres) {
  if (_l) _l->_proxSet(_i, metres);
}

KLink::KLink(const char* name, Kind kind, const char* id) : _name(name), _kind(kind) {
  if (id) {
    strncpy(_id, id, sizeof(_id) - 1);
    _id[sizeof(_id) - 1] = 0;
  } else {
    // slug of the name: "Kite-03" -> "kite-03"
    size_t j = 0;
    for (size_t i = 0; name[i] && j < sizeof(_id) - 1; i++) {
      char c = name[i];
      if (isalnum(static_cast<unsigned char>(c))) {
        _id[j++] = static_cast<char>(tolower(c));
      } else if (j && _id[j - 1] != '-') {
        _id[j++] = '-';
      }
    }
    while (j && _id[j - 1] == '-') j--;
    _id[j] = 0;
  }
  _mode = kind == ROCKET ? KMode::PAD : kind == BENCH ? KMode::IDLE : KMode::HOLD;
  loadStore();
}

void KLink::addTransport(KTransport* t) {
  if (_nTransports < 4) _transports[_nTransports++] = t;
}

bool KLink::connected() const { return _session && millis() - _lastRx < 3000; }

// ------------------------------------------------------------------ telemetry setters
void KLink::imu(float ax, float ay, float az, float gx, float gy, float gz) {
  const float v[] = {ax, ay, az, gx, gy, gz};
  memcpy(_imu, v, sizeof(v));
  _dirty |= T_IMU;
}
void KLink::attitude(float r, float p, float y) {
  _att[0] = r, _att[1] = p, _att[2] = y;
  _dirty |= T_ATT;
}
void KLink::position(float x, float y, float z) {
  _pos[0] = x, _pos[1] = y, _pos[2] = z;
  _dirty |= T_POS;
}
void KLink::velocity(float x, float y, float z) {
  _vel[0] = x, _vel[1] = y, _vel[2] = z;
  _dirty |= T_VEL;
}
void KLink::gps(double lat, double lon, float alt, uint8_t sats) {
  _gpsLL[0] = lat, _gpsLL[1] = lon, _gpsAlt = alt, _gpsSats = sats;
  _dirty |= T_GPS;
}
void KLink::battery(float volts, float pct, float amps) {
  _bat[0] = volts, _bat[1] = amps, _bat[2] = pct;
  _dirty |= T_BAT;
}
void KLink::rssi(float dbm) {
  _rssi = dbm;
  _dirty |= T_RSSI;
}
void KLink::joints(const float* rad, uint8_t n) {
  _nJoints = n > 6 ? 6 : n;
  memcpy(_joints, rad, _nJoints * sizeof(float));
  _dirty |= T_JOINTS;
}
void KLink::tool(float x, float y, float z, float g) {
  _tool[0] = x, _tool[1] = y, _tool[2] = z, _tool[3] = g;
  _dirty |= T_TOOL;
}
void KLink::forceTorque(float fx, float fy, float fz) {
  _ft[0] = fx, _ft[1] = fy, _ft[2] = fz;
  _dirty |= T_FT;
}
void KLink::thrust(float n, float tq) {
  _thrust[0] = n, _thrust[1] = tq;
  _dirty |= T_THRUST;
}
void KLink::rpm(float v) {
  _rpm = v;
  _dirty |= T_RPM;
}
void KLink::temperature(float c) {
  _temp = c;
  _dirty |= T_TEMP;
}
void KLink::throttleOut(float v) {
  _thr = v;
  _dirty |= T_THR;
}
void KLink::rocketState(float maxAlt, float phaseT, float countdown) {
  _rocket[0] = maxAlt, _rocket[1] = phaseT, _rocket[2] = countdown;
  _dirty |= T_ROCKET;
}
void KLink::points(const float (*xyz)[3], uint16_t n) {
  _cloud = xyz;
  _cloudN = n;
}
void KLink::clearTracks() {
  _nTracks = 0;
  _tracksDirty = true;
}
void KLink::track(const char* id, float r, float b) {
  if (_nTracks >= KLINK_MAX_TRACKS) return;
  Track& t = _tracks[_nTracks++];
  strncpy(t.id, id, sizeof(t.id) - 1);
  t.id[sizeof(t.id) - 1] = 0;
  t.r = r, t.b = b;
  _tracksDirty = true;
}
void KLink::log(const char* msg, const char* level) {
  JsonDocument d;
  d["t"] = "log";
  d["lvl"] = level;
  d["msg"] = msg;
  send(d);
}

// ------------------------------------------------------------------ state
void KLink::setMode(KMode m) { changeMode(m, false); }
void KLink::setArmed(bool a) {
  if (a != _armed) {
    _armed = a;
    _stateDirty = true;
  }
}
void KLink::setPyro(const char* a, const char* b, const char* c, const char* d) {
  _pyro[0] = a, _pyro[1] = b, _pyro[2] = c, _pyro[3] = d;
  _stateDirty = true;
}
void KLink::setCutoff(const char* r) {
  _cutoff = r;
  _stateDirty = true;
}
void KLink::setState(const char* key, const char* value) {
  for (uint8_t i = 0; i < 4; i++) {
    if (!_extKey[i] || !strcmp(_extKey[i], key)) {
      _extKey[i] = key;
      _extVal[i] = value;
      _stateDirty = true;
      return;
    }
  }
}
KProx KLink::proximity(const char* id, float maxM, float dirRad, const char* kind, float fovRad, float tiltRad, float minM) {
  if (_nProx >= KLINK_MAX_PROX) return KProx();
  _prox[_nProx] = {id, kind, dirRad, tiltRad, fovRad, minM, maxM, -1};
  return KProx(this, _nProx++);
}
void KLink::_proxSet(uint8_t i, float m) {
  if (i >= _nProx) return;
  _prox[i].value = m < 0 ? -1 : m;
  _dirty |= T_PROX;
}
void KLink::video(const char* url, const char* id, const char* fmt, const char* label) {
  for (uint8_t i = 0; i < _nVideo; i++)
    if (!strcmp(_video[i].id, id)) {
      _video[i] = {id, url, fmt, label};
      return;
    }
  if (_nVideo < 2) _video[_nVideo++] = {id, url, fmt, label};
}
void KLink::changeMode(KMode m, bool notify) {
  if (m == _mode) return;
  _mode = m;
  _stateDirty = true;
  if (notify && _cbMode) _cbMode(m);
}
void KLink::failsafe(uint32_t ms, KMode m) {
  _fsTimeout = ms;
  _fsMode = m;
}

// ------------------------------------------------------------------ params & channels
KParam KLink::param(const char* key, float def, float mn, float mx, const char* unit, float step, const char* label) {
  for (uint8_t i = 0; i < _nParams; i++)
    if (strcmp(_params[i].key, key) == 0) return KParam(this, i);
  if (_nParams >= KLINK_MAX_PARAMS) return KParam();
  if (step <= 0) {
    float span = mx - mn;
    step = span > 0 ? powf(10, floorf(log10f(span / 100))) : 0.01f;
  }
  _params[_nParams] = {key, unit ? unit : "", label, def, mn, mx, step, nullptr};
  loadStore();  // pick up a saved value for this key
  return KParam(this, _nParams++);
}

KChannel KLink::channel(const char* id, std::initializer_list<const char*> axes, const char* unit, float hz) {
  if (_nChannels >= KLINK_MAX_CHANNELS) return KChannel();
  Channel& c = _channels[_nChannels];
  c.id = id;
  c.n = 0;
  for (const char* a : axes)
    if (c.n < 6) c.axes[c.n++] = a;
  c.unit = unit;
  c.hz = hz;
  c.dirty = false;
  if (_session) sendChannels(_active);
  return KChannel(this, _nChannels++);
}

void KLink::_channelPublish(uint8_t i, const float* v, uint8_t n) {
  Channel& c = _channels[i];
  for (uint8_t k = 0; k < c.n; k++) c.v[k] = k < n ? v[k] : 0;
  c.dirty = true;
}

void KLink::pair(const char* code) {
  size_t j = 0;
  for (size_t i = 0; code[i] && j < sizeof(_pairCode) - 1; i++) _pairCode[j++] = static_cast<char>(toupper(code[i]));
  _pairCode[j] = 0;
}

void KLink::unpair() {
  _key[0] = 0;
  storeKey();
}

// ------------------------------------------------------------------ loop
void KLink::update() {
  uint32_t now = millis();
  for (uint8_t i = 0; i < _nTransports; i++) {
    KTransport* t = _transports[i];
    for (uint8_t guard = 0; guard < 16; guard++) {
      size_t n = t->read(_buf, sizeof(_buf) - 1);
      if (!n) break;
      _buf[n] = 0;
      handle(t, _buf, n);
    }
  }
  seqTick(now);
  checkFailsafe(now);
  if (!_session) {
    if (now - _tAnnounce >= 1000) {
      _tAnnounce = now;
      announce();
    }
    return;
  }
  bool low = _active && _active->lowBandwidth();
  if (_stateDirty || now - _tState >= (low ? 2000u : 500u)) {
    _tState = now;
    _stateDirty = false;
    sendState();
  }
  float cap = _active ? _active->maxRateHz() : 0;
  float hz = cap > 0 && cap < _rateHz ? cap : _rateHz;
  if (now - _tTlm >= (uint32_t)(1000 / hz)) {
    _tTlm = now;
    sendTelemetry();
  }
  if (_tracksDirty && !low) {
    _tracksDirty = false;
    JsonDocument d;
    d["t"] = "tracks";
    JsonArray a = d["d"].to<JsonArray>();
    for (uint8_t i = 0; i < _nTracks; i++) {
      JsonArray e = a.add<JsonArray>();
      e.add(_tracks[i].id);
      e.add(_tracks[i].r);
      e.add(_tracks[i].b);
    }
    send(d);
  }
  if (_cloud && !low && now - _tCloud >= 100) {
    _tCloud = now;
    sendCloud();
  }
}

void KLink::checkFailsafe(uint32_t now) {
  // A stored sequence is meant to survive a lost link.
  if (!_session || _fsActive || _kind == ROCKET || sequenceRunning()) return;
  if (now - _lastCtl <= _fsTimeout) return;
  _fsActive = true;
  _ctl = KControl();
  _stateDirty = true;
  if (_cbControl) _cbControl(_ctl);
  if (_kind == DRONE) {
    changeMode(_fsMode, true);
  } else if (_kind == BENCH) {
    changeMode(KMode::IDLE, true);
  } else if (_armed) {
    changeMode(KMode::HOLD, true);
  }
  char msg[64];
  snprintf(msg, sizeof(msg), "Failsafe: no control for %.1f s", _fsTimeout / 1000.0);
  log(msg, "warn");
  // Keep telemetry flowing on a fallback link if there is one.
  for (uint8_t i = 0; i < _nTransports; i++)
    if (_transports[i] != _active) {
      _active = _transports[i];
      break;
    }
}

// ------------------------------------------------------------------ incoming
void KLink::handle(KTransport* t, const char* json, size_t len) {
  JsonDocument m;
  if (deserializeJson(m, json, len)) return;
  const char* typ = m["t"];
  if (!typ) return;
  uint32_t now = millis();

  if (!strcmp(typ, "discover")) {
    JsonDocument a;
    a["t"] = "announce";
    a["v"] = 1;
    a["id"] = _id;
    a["name"] = _name;
    a["kind"] = KIND_NAMES[_kind];
    a["lib"] = "arduino/" KOEBELT_LINK_VERSION;
    if (_pairCode[0]) a["pair"] = _pairCode;
    size_t n = serializeJson(a, _buf, sizeof(_buf));
    t->reply(_buf, n);
    return;
  }
  if (!strcmp(typ, "pair")) {
    const char* code = m["code"];
    const char* key = m["key"];
    if (_pairCode[0] && code && key && !strcasecmp(code, _pairCode)) {
      t->adoptPeer();
      strncpy(_key, key, sizeof(_key) - 1);
      _key[sizeof(_key) - 1] = 0;
      _pairCode[0] = 0;
      storeKey();
      JsonDocument r;
      r["t"] = "paired";
      r["id"] = _id;
      send(r, t);
    }
    return;
  }
  if (!strcmp(typ, "hello")) {
    const char* key = m["key"] | "";
    t->adoptPeer();
    if (_key[0] && strcmp(key, _key) != 0) {
      JsonDocument r;
      r["t"] = "hello";
      r["v"] = 1;
      r["id"] = _id;
      r["ok"] = false;
      r["err"] = "key";
      send(r, t);
      t->dropPeer();
      return;
    }
    _active = t;
    _session = true;
    _lastCtl = _lastRx = now;
    _fsActive = false;
    sendHello(t);
    sendParams(t);
    if (_nChannels) sendChannels(t);
    _stateDirty = true;
    if (_cbConnect) _cbConnect();
    return;
  }
  if (!_session) return;
  _lastRx = now;
  // Telemetry-only links: nothing that moves the device. A STOP is still
  // worth having, however slowly it arrives.
  if (!t->acceptsControl() && strcmp(typ, "stop") && strcmp(typ, "ping") && strcmp(typ, "rate") && strcmp(typ, "bye")) return;

  if (!strcmp(typ, "ctl")) {
    _lastCtl = now;
    _active = t;
    if (_fsActive) {
      _fsActive = false;
      _stateDirty = true;
    }
    _ctl.lx = m["lx"] | 0.0f;
    _ctl.ly = m["ly"] | 0.0f;
    _ctl.rx = m["rx"] | 0.0f;
    _ctl.ry = m["ry"] | 0.0f;
    _ctl.seq = m["s"] | 0u;
    if (!_estop && _cbControl) _cbControl(_ctl);
  } else if (!strcmp(typ, "ping")) {
    JsonDocument r;
    r["t"] = "pong";
    r["ts"] = m["ts"];
    send(r, t);
  } else if (!strcmp(typ, "seq")) {
    seqStore(t, m);
  } else if (!strcmp(typ, "seqrun")) {
    const char* id = m["id"] | "";
    if (_nSteps && !_estop && !strcmp(id, _seqId)) {
      _run = R_RUN;
      _runI = 0;
      _entered = false;
      _stepT = _totalT = 0;
      _runMsg[0] = 0;
      _tSeq = now;
      _repSt = 255;
    }
  } else if (!strcmp(typ, "seqctl")) {
    seqCtl(m["c"] | "");
  } else if (!strcmp(typ, "stop")) {
    seqStop("Stopped: emergency stop");
    if (!_estop) {
      _estop = true;
      _armed = false;
      _ctl = KControl();
      _stateDirty = true;
      if (_cbStop) _cbStop();
      if (_cbArm) _cbArm(false);
    }
  } else if (!strcmp(typ, "reset")) {
    if (_estop) {
      _estop = false;
      _stateDirty = true;
      if (_cbReset) _cbReset();
    }
  } else if (!strcmp(typ, "arm")) {
    bool v = m["v"] | false;
    if (!_estop && v != _armed) {
      _armed = v;
      _stateDirty = true;
      if (_cbArm) _cbArm(v);
    }
  } else if (!strcmp(typ, "mode")) {
    KMode md = kModeParse(m["m"]);
    if (!_estop && md != KMode::UNKNOWN) changeMode(md, true);
  } else if (!strcmp(typ, "jog")) {
    float j[6] = {};
    JsonArrayConst a = m["j"];
    for (uint8_t i = 0; i < 6 && i < a.size(); i++) j[i] = a[i];
    if (!_estop && _cbJog) _cbJog(j);
  } else if (!strcmp(typ, "cart")) {
    float v[3] = {};
    JsonArrayConst a = m["v"];
    for (uint8_t i = 0; i < 3 && i < a.size(); i++) v[i] = a[i];
    if (!_estop && _cbCart) _cbCart(v);
  } else if (!strcmp(typ, "cmd")) {
    const char* c = m["c"] | "";
    bool always = !strcmp(c, "abort") || !strcmp(c, "clear") || !strcmp(c, "reset");
    if ((!_estop || always) && _cbCmd) _cbCmd(c, m["a"].as<JsonObjectConst>());
  } else if (!strcmp(typ, "pset")) {
    JsonDocument r;
    r["t"] = "pack";
    r["ok"] = true;
    JsonArray keys = r["keys"].to<JsonArray>();
    for (JsonPairConst kv : m["p"].as<JsonObjectConst>()) {
      for (uint8_t i = 0; i < _nParams; i++) {
        if (strcmp(_params[i].key, kv.key().c_str()) || !kv.value().is<float>()) continue;
        float v = kv.value().as<float>();
        v = v < _params[i].min ? _params[i].min : v > _params[i].max ? _params[i].max : v;
        if (v != _params[i].value) {
          _params[i].value = v;
          if (_params[i].cb) _params[i].cb(v);
        }
        keys.add(_params[i].key);
      }
    }
    send(r, t);
    if (keys.size() && _cbWritten) _cbWritten();
  } else if (!strcmp(typ, "psave")) {
    saveParams();
  } else if (!strcmp(typ, "rate")) {
    float hz = m["hz"] | 30.0f;
    _rateHz = hz < 1 ? 1 : hz > 60 ? 60 : hz;
  } else if (!strcmp(typ, "speed")) {
    float v = m["v"] | 0.5f;
    _speed = v < 0.1f ? 0.1f : v > 1 ? 1 : v;
  } else if (!strcmp(typ, "fs")) {
    KMode md = kModeParse(m["action"]);
    if (md != KMode::UNKNOWN) _fsMode = md;
    _fsTimeout = m["ms"] | _fsTimeout;
  } else if (!strcmp(typ, "bye")) {
    _session = false;
    _ctl = KControl();
    // A stored sequence carries on; otherwise a flying drone holds.
    if (_kind == DRONE && _armed && !sequenceRunning()) changeMode(KMode::HOLD, true);
    t->dropPeer();
  }
}

// ------------------------------------------------------------------ outgoing
void KLink::send(JsonDocument& d, KTransport* to) {
  KTransport* t = to ? to : _active;
  if (!t) return;
  size_t n = serializeJson(d, _buf, sizeof(_buf));
  if (n == 0 || n >= sizeof(_buf) - 1 || n > t->maxMessage()) return;
  t->write(_buf, n);
}

void KLink::sendHello(KTransport* t) {
  JsonDocument d;
  d["t"] = "hello";
  d["v"] = 1;
  d["id"] = _id;
  d["name"] = _name;
  d["kind"] = KIND_NAMES[_kind];
  d["model"] = _model;
  d["fw"] = _fw;
  d["lib"] = "arduino/" KOEBELT_LINK_VERSION;
  d["seq"] = KLINK_MAX_STEPS;
  if (_nProx) {
    JsonArray p = d["prox"].to<JsonArray>();
    for (uint8_t i = 0; i < _nProx; i++) {
      JsonObject o = p.add<JsonObject>();
      o["id"] = _prox[i].id;
      if (_prox[i].dir != 0) o["dir"] = _prox[i].dir;
      if (_prox[i].tilt != 0) o["tilt"] = _prox[i].tilt;
      o["fov"] = _prox[i].fov;
      if (_prox[i].min != 0) o["min"] = _prox[i].min;
      o["max"] = _prox[i].max;
      if (_prox[i].kind) o["kind"] = _prox[i].kind;
    }
  }
  if (_nVideo) {
    JsonArray v = d["video"].to<JsonArray>();
    for (uint8_t i = 0; i < _nVideo; i++) {
      JsonObject o = v.add<JsonObject>();
      o["id"] = _video[i].id;
      o["url"] = _video[i].url;
      o["fmt"] = _video[i].fmt;
      if (_video[i].label) o["label"] = _video[i].label;
    }
  }
  JsonArray s = d["sensors"].to<JsonArray>();
  // comma-separated list -> array
  char tmp[128];
  strncpy(tmp, _sensors, sizeof(tmp) - 1);
  tmp[sizeof(tmp) - 1] = 0;
  for (char* tok = strtok(tmp, ","); tok; tok = strtok(nullptr, ",")) {
    while (*tok == ' ') tok++;
    if (*tok) s.add(static_cast<const char*>(tok));
  }
  d["ok"] = true;
  send(d, t);
}

void KLink::sendParams(KTransport* t) {
  // Split large tables so each message fits the transport.
  uint8_t i = 0;
  do {
    JsonDocument d;
    d["t"] = "params";
    JsonArray p = d["p"].to<JsonArray>();
    for (uint8_t k = 0; k < 16 && i < _nParams; k++, i++) {
      JsonArray e = p.add<JsonArray>();
      e.add(_params[i].key);
      e.add(_params[i].value);
      e.add(_params[i].min);
      e.add(_params[i].max);
      e.add(_params[i].step);
      e.add(_params[i].unit);
      if (_params[i].label) e.add(_params[i].label);
    }
    if (i < _nParams) d["more"] = true;
    send(d, t);
  } while (i < _nParams);
}

void KLink::sendChannels(KTransport* t) {
  JsonDocument d;
  d["t"] = "chan";
  JsonArray ch = d["ch"].to<JsonArray>();
  for (uint8_t i = 0; i < _nChannels; i++) {
    JsonObject o = ch.add<JsonObject>();
    o["id"] = _channels[i].id;
    JsonArray ax = o["axes"].to<JsonArray>();
    for (uint8_t k = 0; k < _channels[i].n; k++) ax.add(_channels[i].axes[k]);
    o["unit"] = _channels[i].unit;
    o["hz"] = _channels[i].hz;
  }
  send(d, t);
}

void KLink::sendState() {
  JsonDocument d;
  d["t"] = "state";
  d["mode"] = kModeName(_mode);
  d["armed"] = _armed;
  d["estop"] = _estop;
  d["fs"] = _fsActive;
  JsonObject ext = d["ext"].to<JsonObject>();
  if (_kind == ROCKET) {
    JsonArray p = ext["pyro"].to<JsonArray>();
    for (auto s : _pyro) p.add(s);
  }
  if (_cutoff) ext["cutoff"] = _cutoff;
  for (uint8_t i = 0; i < 4 && _extKey[i]; i++) ext[_extKey[i]] = _extVal[i];
  if (_run != R_NONE) {
    static const char* const ST[] = {"", "run", "pause", "done", "fail"};
    JsonObject r = ext["run"].to<JsonObject>();
    r["id"] = _seqId;
    r["i"] = _runI;
    r["n"] = _nSteps;
    r["st"] = ST[_run];
    if (_runMsg[0]) r["msg"] = _runMsg;
    float p = seqProgress();
    if (sequenceRunning() && p >= 0) r["p"] = (int)(p * 100 + 0.5f) / 100.0f;
  }
  send(d);
}

// ------------------------------------------------------------------ stored sequences
// PROTOCOL.md "Sequences": the app uploads the steps, the device runs them
// through the same callbacks as the app's messages and checks completion
// against its own telemetry, so a sequence keeps going when the link drops.

void KLink::seqStore(KTransport* t, JsonDocument& m) {
  const char* id = m["id"] | "";
  JsonArrayConst steps = m["steps"];
  const char* err = nullptr;
  char why[64];
  uint8_t n = 0;
  bool drone = _kind == DRONE, rover = _kind == ROVER, arm = _kind == ARM, bench = _kind == BENCH;
  bool moving = !bench && _kind != ROCKET;
  if (sequenceRunning()) {
    err = "A sequence is running";
  } else if (steps.size() == 0) {
    err = "No steps";
  } else if (steps.size() > KLINK_MAX_STEPS) {
    snprintf(why, sizeof(why), "Too many steps: this device stores %d", KLINK_MAX_STEPS);
    err = why;
  }
  Step parsed[KLINK_MAX_STEPS];
  for (JsonArrayConst w : steps) {
    if (err) break;
    const char* ty = w[0] | "";
    JsonObjectConst a = w[1];
    Step s = {};
    if (!strcmp(ty, "takeoff") && drone) {
      s.type = S_TAKEOFF;
      s.v[0] = a["alt"] | 6.0f;
    } else if (!strcmp(ty, "goto") && (drone || rover)) {
      s.type = S_GOTO;
      s.v[0] = a["x"] | 0.0f;
      s.v[1] = a["y"] | 0.0f;
      s.v[2] = a["z"] | 8.0f;
    } else if (!strcmp(ty, "land") && drone) {
      s.type = S_LAND;
    } else if (!strcmp(ty, "rth") && drone) {
      s.type = S_RTH;
    } else if (!strcmp(ty, "pose") && arm) {
      s.type = S_POSE;
      JsonArrayConst j = a["j"];
      for (uint8_t i = 0; i < 6; i++) s.v[i] = j[i] | 0.0f;
    } else if (!strcmp(ty, "home") && arm) {
      s.type = S_HOME;
    } else if (!strcmp(ty, "gripper") && arm) {
      s.type = S_GRIPPER;
      s.v[0] = a["v"] | 0.9f;
    } else if (!strcmp(ty, "throttle") && bench) {
      s.type = S_THROTTLE;
      s.v[0] = a["v"] | 0.0f;
      s.v[1] = a["s"] | 0.0f;
    } else if (!strcmp(ty, "ramp") && bench) {
      s.type = S_RAMP;
      s.v[0] = a["from"] | 0.0f;
      s.v[1] = a["to"] | 0.0f;
      s.v[2] = a["s"] | 0.0f;
    } else if (!strcmp(ty, "wait")) {
      s.type = S_WAIT;
      s.v[0] = a["s"] | 0.0f;
    } else if (!strcmp(ty, "mode") && moving && kModeParse(a["m"] | "") != KMode::UNKNOWN) {
      s.type = S_MODE;
      s.v[0] = (float)(uint8_t)kModeParse(a["m"] | "");
    } else if (!strcmp(ty, "arm")) {
      s.type = S_ARM;
      s.v[0] = (a["v"] | false) ? 1 : 0;
    } else if (!strcmp(ty, "speed") && moving) {
      s.type = S_SPEED;
      s.v[0] = a["v"] | 0.5f;
    } else if (!strcmp(ty, "cmd")) {
      // Custom commands in stored sequences carry their "v" only.
      s.type = S_CMD;
      strncpy(s.name, a["c"] | "", sizeof(s.name) - 1);
      JsonVariantConst v = a["a"]["v"];
      s.v[1] = v.isNull() ? 0 : 1;
      s.v[0] = v | 0.0f;
    } else {
      snprintf(why, sizeof(why), "Step \"%s\" is not supported on this device", ty);
      err = why;
      break;
    }
    parsed[n++] = s;
  }
  if (!err) {
    memcpy(_steps, parsed, sizeof(Step) * n);
    _nSteps = n;
    strncpy(_seqId, id, sizeof(_seqId) - 1);
    _seqId[sizeof(_seqId) - 1] = 0;
    _run = R_NONE;
    _stateDirty = true;
  }
  JsonDocument r;
  r["t"] = "seqack";
  r["id"] = id;
  r["ok"] = err == nullptr;
  if (err) r["err"] = err;
  send(r, t);
}

void KLink::seqCtl(const char* c) {
  if (!strcmp(c, "pause")) {
    seqPause();
  } else if (!strcmp(c, "resume") && _run == R_PAUSE) {
    _run = R_RUN;
    _runMsg[0] = 0;
    _entered = false;  // re-issue the current step
    _stepT = 0;
  } else if (!strcmp(c, "stop")) {
    seqStop("Stopped from the app");
  }
  _stateDirty = true;
}

void KLink::seqPause() {
  if (_run != R_RUN) return;
  _run = R_PAUSE;
  strcpy(_runMsg, "Paused");
  uint8_t ty = _runI < _nSteps ? _steps[_runI].type : 255;
  if (ty == S_THROTTLE || ty == S_RAMP) {
    JsonDocument a;
    a["v"] = 0;
    seqCmd("throttle", a);
  } else if ((_kind == DRONE || _kind == ROVER) && _armed) {
    seqMode(KMode::HOLD);
  }
}

void KLink::seqStop(const char* why) {
  if (!sequenceRunning()) return;
  _run = R_FAIL;
  strncpy(_runMsg, why, sizeof(_runMsg) - 1);
  _stateDirty = true;
  if (_kind == BENCH) {
    JsonDocument a;
    a["v"] = 0;
    seqCmd("throttle", a);
  }
  if ((_kind == DRONE || _kind == ROVER) && _armed && !_estop) seqMode(KMode::HOLD);
}

// The same callbacks the app's messages reach.
void KLink::seqCmd(const char* name, JsonDocument& args) {
  if (!_estop && _cbCmd) _cbCmd(name, args.as<JsonObjectConst>());
}
void KLink::seqMode(KMode m) {
  if (!_estop) changeMode(m, true);
}
void KLink::seqArm(bool v) {
  if (_estop || v == _armed) return;
  _armed = v;
  _stateDirty = true;
  if (_cbArm) _cbArm(v);
}

float KLink::seqProgress() const {
  if (_runI >= _nSteps) return -1;
  const Step& s = _steps[_runI];
  float d = s.type == S_WAIT ? s.v[0] : s.type == S_THROTTLE ? s.v[1] : s.type == S_RAMP ? s.v[2] : s.type == S_GRIPPER ? 0.8f : 0;
  if (d <= 0) return -1;
  float p = _stepT / d;
  return p < 0 ? 0 : p > 1 ? 1 : p;
}

void KLink::seqTick(uint32_t now) {
  float dt = (now - _tSeq) / 1000.0f;
  _tSeq = now;
  if (_run == R_RUN) {
    if (_estop) {
      seqStop("Stopped: emergency stop");
    } else {
      seqStep(dt > 1 ? 1 : dt);
    }
  }
  if (_run != R_NONE && (_repSt != _run || _repI != _runI)) {
    _repSt = _run;
    _repI = _runI;
    _stateDirty = true;
  }
}

void KLink::seqEnter(const Step& s) {
  JsonDocument a;
  switch (s.type) {
    case S_TAKEOFF:
      a["alt"] = s.v[0];
      seqCmd("takeoff", a);
      break;
    case S_GOTO:
      a["x"] = s.v[0];
      a["y"] = s.v[1];
      if (_kind == DRONE) a["z"] = s.v[2];
      seqCmd("goto", a);
      break;
    case S_LAND:
      seqMode(KMode::LAND);
      break;
    case S_RTH:
      seqMode(KMode::RTH);
      break;
    case S_POSE: {
      JsonArray j = a["j"].to<JsonArray>();
      for (uint8_t i = 0; i < 6; i++) j.add(s.v[i]);
      seqCmd("pose", a);
      break;
    }
    case S_HOME:
      a.to<JsonObject>();
      seqCmd("home", a);
      break;
    case S_GRIPPER:
    case S_THROTTLE:
      a["v"] = s.v[0];
      seqCmd(s.type == S_GRIPPER ? "gripper" : "throttle", a);
      break;
    case S_MODE:
      seqMode((KMode)(uint8_t)s.v[0]);
      break;
    case S_ARM:
      seqArm(s.v[0] != 0);
      break;
    case S_SPEED:
      _speed = s.v[0] < 0.1f ? 0.1f : s.v[0] > 1 ? 1 : s.v[0];
      break;
    case S_CMD:
      a.to<JsonObject>();
      if (s.v[1] != 0) a["v"] = s.v[0];
      if (s.name[0]) seqCmd(s.name, a);
      break;
    default:
      break;
  }
}

void KLink::seqStep(float dt) {
  if (_runI >= _nSteps) {
    _run = R_DONE;
    snprintf(_runMsg, sizeof(_runMsg), "Completed in %.1f s", _totalT);
    return;
  }
  const Step& s = _steps[_runI];
  _totalT += dt;
  if (!_entered) {
    _entered = true;
    _stepT = 0;
    _lastThr = -1;
    seqEnter(s);
  }
  _stepT += dt;
  float t = _stepT;
  // 1 done, 0 keep going, -1 timed out
  auto within = [t](float limit, bool ok) { return ok ? 1 : t > limit ? -1 : 0; };
  const float* p = _pos;
  int r = 1;
  switch (s.type) {
    case S_WAIT:
    case S_THROTTLE:
      r = t >= (s.type == S_WAIT ? s.v[0] : s.v[1]);
      break;
    case S_TAKEOFF:
      r = within(60, t > 0.3f && _mode != KMode::TAKEOFF && p[2] > s.v[0] - 0.6f);
      break;
    case S_GOTO: {
      bool drone = _kind == DRONE;
      float dx = p[0] - s.v[0], dy = p[1] - s.v[1], dz = drone ? p[2] - s.v[2] : 0;
      float d = sqrtf(dx * dx + dy * dy + dz * dz);
      snprintf(_runMsg, sizeof(_runMsg), "%.1f m to go", d);
      r = within(300, d < (drone ? 1.0f : 0.6f));
      break;
    }
    case S_LAND:
    case S_RTH:
      r = within(300, t > 0.5f && (!_armed || (p[2] < 0.1f && _mode != KMode::LAND && _mode != KMode::RTH)));
      break;
    case S_POSE: {
      float err = 0;
      for (uint8_t i = 0; i < 6 && i < _nJoints; i++) err = fmaxf(err, fabsf(_joints[i] - s.v[i]));
      r = within(60, t > 0.2f && err < 0.03f);
      break;
    }
    case S_HOME: {
      float moved = 0;
      for (uint8_t i = 0; i < 6 && i < _nJoints; i++) moved = fmaxf(moved, fabsf(_joints[i] - _lastJ[i]));
      memcpy(_lastJ, _joints, sizeof(_lastJ));
      _still = moved < 2e-4f ? _still + dt : 0;
      r = within(60, t > 0.6f && _still > 0.4f);
      break;
    }
    case S_GRIPPER:
      r = t >= 0.8f;
      break;
    case S_RAMP: {
      float d = s.v[2] > 0.001f ? s.v[2] : 0.001f, k = t / d > 1 ? 1 : t / d;
      float thr = s.v[0] + (s.v[1] - s.v[0]) * k;
      _sendAcc += dt;
      if (_sendAcc >= 0.1f && fabsf(thr - _lastThr) >= 0.005f) {
        _sendAcc = 0;
        _lastThr = thr;
        JsonDocument a;
        a["v"] = thr;
        seqCmd("throttle", a);
      }
      r = t >= d;
      break;
    }
    case S_MODE:
      r = within(3, _mode == (KMode)(uint8_t)s.v[0]);
      break;
    case S_ARM:
      r = within(3, _armed == (s.v[0] != 0));
      break;
    default:
      break;
  }
  if (r == 1) {
    _runI++;
    _entered = false;
    _runMsg[0] = 0;
  } else if (r == -1) {
    _run = R_FAIL;
    snprintf(_runMsg, sizeof(_runMsg), "Step %d timed out", _runI + 1);
    if ((_kind == DRONE || _kind == ROVER) && _armed) seqMode(KMode::HOLD);
  }
}

void KLink::sendTelemetry() {
  bool anyCh = false;
  for (uint8_t i = 0; i < _nChannels; i++) anyCh |= _channels[i].dirty;
  if (!_dirty && !anyCh) return;
  float cap = _active ? _active->maxRateHz() : 0;
  bool compact = cap > 0 && cap <= 2;
  JsonDocument doc;
  doc["t"] = "tlm";
  doc["ts"] = millis();
  JsonObject d = doc["d"].to<JsonObject>();
  auto arr = [&](const char* k, const float* v, uint8_t n) {
    JsonArray a = d[k].to<JsonArray>();
    for (uint8_t i = 0; i < n; i++) a.add(v[i]);
  };
  if (_dirty & T_POS) arr("pos", _pos, 3);
  if (_dirty & T_BAT) arr("bat", _bat, 3);
  if (_dirty & T_ATT) arr("att", _att, 3);
  if (_dirty & T_ROCKET) arr("rocket", _rocket, 3);
  if (_dirty & T_PROX) {
    // Even on slow links: it is about not hitting things.
    JsonArray a = d["prox"].to<JsonArray>();
    for (uint8_t i = 0; i < _nProx; i++) a.add(_prox[i].value);
  }
  if (_dirty & T_GPS) {
    JsonArray a = d["gps"].to<JsonArray>();
    a.add(_gpsLL[0]);
    a.add(_gpsLL[1]);
    a.add(_gpsAlt);
    a.add(_gpsSats);
  }
  if (!compact) {
    if (_dirty & T_IMU) arr("imu", _imu, 6);
    if (_dirty & T_VEL) arr("vel", _vel, 3);
    if (_dirty & T_RSSI) arr("rssi", &_rssi, 1);
    if (_dirty & T_JOINTS) arr("joints", _joints, _nJoints);
    if (_dirty & T_TOOL) arr("tool", _tool, 4);
    if (_dirty & T_FT) arr("ft", _ft, 3);
    if (_dirty & T_THRUST) arr("thrust", _thrust, 2);
    if (_dirty & T_RPM) arr("rpm", &_rpm, 1);
    if (_dirty & T_TEMP) arr("temp", &_temp, 1);
    if (_dirty & T_THR) arr("throttle", &_thr, 1);
    for (uint8_t i = 0; i < _nChannels; i++) {
      if (!_channels[i].dirty) continue;
      arr(_channels[i].id, _channels[i].v, _channels[i].n);
      _channels[i].dirty = false;
    }
  }
  _dirty = 0;
  send(doc);
}

static const char B64[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

static size_t b64(const uint8_t* in, size_t n, char* out) {
  size_t o = 0;
  for (size_t i = 0; i < n; i += 3) {
    uint32_t v = in[i] << 16 | (i + 1 < n ? in[i + 1] << 8 : 0) | (i + 2 < n ? in[i + 2] : 0);
    out[o++] = B64[(v >> 18) & 63];
    out[o++] = B64[(v >> 12) & 63];
    out[o++] = i + 1 < n ? B64[(v >> 6) & 63] : '=';
    out[o++] = i + 2 < n ? B64[v & 63] : '=';
  }
  out[o] = 0;
  return o;
}

void KLink::sendCloud() {
  // 120 points per message: 720 bytes -> 960 base64 chars.
  static const uint16_t CHUNK = 120;
  uint8_t raw[CHUNK * 6];
  char enc[CHUNK * 8 + 4];
  for (uint16_t o = 0; o < _cloudN; o += CHUNK) {
    uint16_t n = _cloudN - o < CHUNK ? _cloudN - o : CHUNK;
    for (uint16_t i = 0; i < n; i++)
      for (uint8_t k = 0; k < 3; k++) {
        float cm = _cloud[o + i][k] * 100;
        int16_t v = cm > 32767 ? 32767 : cm < -32768 ? -32768 : static_cast<int16_t>(lroundf(cm));
        raw[i * 6 + k * 2] = static_cast<uint8_t>(v & 0xFF);
        raw[i * 6 + k * 2 + 1] = static_cast<uint8_t>((v >> 8) & 0xFF);
      }
    b64(raw, n * 6, enc);
    JsonDocument d;
    d["t"] = "pc";
    d["f"] = "i16cm";
    d["n"] = n;
    d["d"] = static_cast<const char*>(enc);
    send(d);
  }
  _cloud = nullptr;
}

void KLink::announce() {
  JsonDocument a;
  a["t"] = "announce";
  a["v"] = 1;
  a["id"] = _id;
  a["name"] = _name;
  a["kind"] = KIND_NAMES[_kind];
  a["lib"] = "arduino/" KOEBELT_LINK_VERSION;
  if (_pairCode[0]) a["pair"] = _pairCode;
  size_t n = serializeJson(a, _buf, sizeof(_buf));
  for (uint8_t i = 0; i < _nTransports; i++) _transports[i]->announce(_buf, n);
}
