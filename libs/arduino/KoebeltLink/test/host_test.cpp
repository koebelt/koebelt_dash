// Host tests for the koebelt/link core. Build and run:
//   make -C test
#include <Arduino.h>
#include <ArduinoJson.h>
#include <math.h>
#include <stdio.h>

#include <deque>
#include <string>
#include <vector>

#include "KoebeltLink.h"

uint32_t g_millis = 1000;

struct FakeTransport : KTransport {
  std::deque<std::string> in;
  std::vector<std::string> out, announced;
  bool control = true, low = false;
  float rate = 0;
  size_t read(char* buf, size_t cap) override {
    if (in.empty()) return 0;
    std::string m = in.front();
    in.pop_front();
    if (m.size() >= cap) return 0;
    memcpy(buf, m.data(), m.size());
    return m.size();
  }
  void write(const char* msg, size_t len) override { out.emplace_back(msg, len); }
  void announce(const char* msg, size_t len) override { announced.emplace_back(msg, len); }
  bool acceptsControl() const override { return control; }
  bool lowBandwidth() const override { return low; }
  float maxRateHz() const override { return rate; }

  std::vector<JsonDocument> of(const char* t) const {
    std::vector<JsonDocument> r;
    for (auto& s : out) {
      JsonDocument d;
      deserializeJson(d, s);
      if (strcmp(d["t"] | "", t) == 0) r.push_back(d);
    }
    return r;
  }
};

static int failures = 0, checks = 0;
#define CHECK(c)                                                  \
  do {                                                            \
    checks++;                                                     \
    if (!(c)) {                                                   \
      failures++;                                                 \
      printf("FAIL %s:%d  %s\n", __FILE__, __LINE__, #c);         \
    }                                                             \
  } while (0)

static void run(KLink& l, FakeTransport& t, uint32_t ms, bool ctl = true) {
  for (uint32_t i = 0; i < ms; i += 10) {
    if (ctl) t.in.push_back("{\"t\":\"ctl\",\"s\":1,\"lx\":0,\"ly\":0,\"rx\":0,\"ry\":0}");
    g_millis += 10;
    l.update();
  }
}

// callbacks (function pointers, like on the boards)
static int stops = 0, writes = 0;
static KMode lastMode = KMode::UNKNOWN;
static KControl lastCtl;
static float lastParam = 0;
static float lastJog[6];

void test_handshake() {
  KLink l("Kite-03", KLink::DRONE);
  FakeTransport t;
  l.addTransport(&t);
  l.setSensors("GPS, IMU,BARO");
  l.param("RATE_RLL_P", 0.135f, 0, 0.5f);
  auto temp = l.channel("motor_temp", {"M1", "M2"}, "C", 10);
  run(l, t, 1100, false);
  CHECK(!t.announced.empty());
  t.in.push_back("{\"t\":\"hello\",\"v\":1}");
  l.imu(0, 0, 9.81f, 0, 0, 0.1f);
  l.gps(47.1, 8.2, 400, 12);
  temp.publish(40.5, 41);
  run(l, t, 100);
  auto h = t.of("hello");
  CHECK(h.size() == 1 && h[0]["ok"] == true && strcmp(h[0]["id"], "kite-03") == 0 && strcmp(h[0]["kind"], "drone") == 0);
  CHECK(h[0]["sensors"].size() == 3 && strcmp(h[0]["sensors"][1], "IMU") == 0);
  auto p = t.of("params");
  CHECK(p.size() == 1 && strcmp(p[0]["p"][0][0], "RATE_RLL_P") == 0);
  CHECK(t.of("chan").size() == 1);
  auto tl = t.of("tlm");
  CHECK(!tl.empty());
  bool gps = false, custom = false;
  for (auto& d : tl) {
    if (d["d"]["gps"].is<JsonArray>()) gps = fabs(d["d"]["gps"][0].as<double>() - 47.1) < 1e-4;
    if (d["d"]["motor_temp"].is<JsonArray>()) custom = fabs(d["d"]["motor_temp"][0].as<float>() - 40.5f) < 1e-4;
  }
  CHECK(gps && custom);
  CHECK(l.connected());
}

void test_control_stop_failsafe() {
  KLink l("Mule", KLink::ROVER);
  FakeTransport t;
  l.addTransport(&t);
  l.onControl([](const KControl& c) { lastCtl = c; });
  l.onStop([] { stops++; });
  l.onMode([](KMode m) { lastMode = m; });
  l.failsafe(300, KMode::HOLD);
  t.in.push_back("{\"t\":\"hello\"}");
  t.in.push_back("{\"t\":\"arm\",\"v\":true}");
  t.in.push_back("{\"t\":\"mode\",\"m\":\"MANUAL\"}");
  t.in.push_back("{\"t\":\"ctl\",\"s\":7,\"lx\":0.5,\"ly\":0,\"rx\":0,\"ry\":-1}");
  g_millis += 10;
  l.update();
  CHECK(l.armed() && l.mode() == KMode::MANUAL && lastMode == KMode::MANUAL);
  CHECK(lastCtl.lx == 0.5f && lastCtl.ry == -1 && lastCtl.seq == 7);

  run(l, t, 500, false);
  CHECK(l.failsafeActive() && l.mode() == KMode::HOLD);
  run(l, t, 30);
  CHECK(!l.failsafeActive());

  for (int i = 0; i < 3; i++) t.in.push_back("{\"t\":\"stop\"}");
  run(l, t, 20);
  CHECK(l.stopped() && !l.armed() && stops == 1);
  t.in.push_back("{\"t\":\"mode\",\"m\":\"AUTO\"}");
  run(l, t, 20);
  CHECK(l.mode() == KMode::HOLD);
  auto st = t.of("state");
  CHECK(!st.empty() && st.back()["estop"] == true);
  t.in.push_back("{\"t\":\"reset\"}");
  run(l, t, 20);
  CHECK(!l.stopped() && !l.armed());
}

void test_control_only_on_fast_links() {
  KLink l("Rocketeer", KLink::ROCKET);
  FakeTransport lora;
  lora.control = false;
  lora.low = true;
  lora.rate = kRadioProfile(KRadio::LORA).tlmHz;
  l.addTransport(&lora);
  lastCtl = KControl();
  l.onControl([](const KControl& c) { lastCtl = c; });
  lora.in.push_back("{\"t\":\"hello\"}");
  lora.in.push_back("{\"t\":\"ctl\",\"lx\":1}");
  l.position(0, 0, 120);
  l.imu(1, 2, 3, 4, 5, 6);
  run(l, lora, 1000, false);
  CHECK(lastCtl.lx == 0);
  auto tl = lora.of("tlm");
  CHECK(!tl.empty() && tl[0]["d"]["pos"].is<JsonArray>() && !tl[0]["d"]["imu"].is<JsonArray>());
  CHECK(tl.size() <= 3);  // 2 Hz on low-bandwidth links
  CHECK(!l.failsafeActive());  // rockets ignore the failsafe
  // Nothing that moves the device over a telemetry-only link, but STOP works.
  lora.in.push_back("{\"t\":\"arm\",\"v\":true}");
  lora.in.push_back("{\"t\":\"cmd\",\"c\":\"countdown\",\"a\":{\"s\":10}}");
  run(l, lora, 50, false);
  CHECK(!l.armed());
  lora.in.push_back("{\"t\":\"stop\"}");
  run(l, lora, 50, false);
  CHECK(l.stopped());
}

void test_radio_profiles() {
  // Same table as protocol/vectors.json.
  CHECK(!strcmp(kRadioProfile(KRadio::SIK).id, "sik") && kRadioProfile(KRadio::SIK).baud == 57600 && kRadioProfile(KRadio::SIK).ctlHz == 10);
  CHECK(!strcmp(kRadioProfile(KRadio::LORA).id, "lora") && kRadioProfile(KRadio::LORA).ctlHz == 0);
  CHECK(kRadioProfile(KRadio::HC12).baud == 9600 && kRadioProfile(KRadio::HC12).tlmHz == 2 && kRadioProfile(KRadio::HC12).ctlHz == 5);
  CHECK(kRadioProfile(KRadio::XBEE).tlmHz == 5 && kRadioProfile(KRadio::OTHER).ctlHz == 5);

  // SiK: control accepted, telemetry capped at 5 Hz with the full field set, no point clouds.
  KLink l("Mule", KLink::ROVER);
  FakeTransport sik;
  sik.low = true;
  sik.rate = kRadioProfile(KRadio::SIK).tlmHz;
  l.addTransport(&sik);
  static const float cloud[2][3] = {{1, 2, 0}, {3, 4, 0}};
  l.points(cloud, 2);
  lastCtl = KControl();
  l.onControl([](const KControl& c) { lastCtl = c; });
  sik.in.push_back("{\"t\":\"hello\"}");
  sik.in.push_back("{\"t\":\"ctl\",\"lx\":0.5}");
  for (int i = 0; i < 100; i++) {
    l.imu(0, 0, 9.81f, 0, 0, 0);
    l.position(i, 0, 0);
    run(l, sik, 10);
  }
  CHECK(lastCtl.lx == 0 || lastCtl.lx == 0.5f);
  auto tl = sik.of("tlm");
  CHECK(tl.size() >= 4 && tl.size() <= 6);
  CHECK(tl[0]["d"]["imu"].is<JsonArray>());
  CHECK(sik.of("pc").empty());
}

void test_video_state_label_connect() {
  static int connects = 0;
  KLink l("Cam", KLink::ROVER);
  FakeTransport t;
  l.addTransport(&t);
  l.video(":81/stream", "fpv", "mjpeg", "Front");
  l.param("MAX_SPD", 2, 0, 5, "m/s", 0.1f, "Top speed");
  l.setState("gear", "LOW");
  l.onConnect([] { connects++; });
  t.in.push_back("{\"t\":\"hello\"}");
  run(l, t, 600);
  auto h = t.of("hello");
  CHECK(!h.empty() && h[0]["video"][0]["url"] == ":81/stream" && h[0]["video"][0]["label"] == "Front");
  auto p = t.of("params");
  CHECK(!p.empty() && p[0]["p"][0][6] == "Top speed");
  auto st = t.of("state");
  CHECK(!st.empty() && st.back()["ext"]["gear"] == "LOW");
  CHECK(connects == 1);
}

void test_proximity() {
  KLink l("Mule", KLink::ROVER);
  FakeTransport t;
  l.addTransport(&t);
  KProx front = l.proximity("front", 4, 0, "ultrasonic");
  KProx down = l.proximity("down", 8, 0, "tof", 0.05f, -1.571f);
  t.in.push_back("{\"t\":\"hello\"}");
  run(l, t, 100);
  auto h = t.of("hello");
  CHECK(!h.empty() && h[0]["prox"].size() == 2);
  CHECK(h[0]["prox"][0]["id"] == "front" && h[0]["prox"][0]["max"] == 4 && h[0]["prox"][0]["kind"] == "ultrasonic");
  CHECK(h[0]["prox"][1]["tilt"].as<float>() < -1.5f && h[0]["prox"][0]["tilt"].isNull());
  front.set(0.42f);
  run(l, t, 100);
  auto tl = t.of("tlm");
  CHECK(!tl.empty() && tl.back()["d"]["prox"][0].as<float>() > 0.41f && tl.back()["d"]["prox"][1] == -1);
  front.clear();
  down.set(1.2f);
  run(l, t, 100);
  tl = t.of("tlm");
  CHECK(tl.back()["d"]["prox"][0] == -1 && tl.back()["d"]["prox"][1].as<float>() > 1.19f);
  for (int i = 0; i < KLINK_MAX_PROX; i++) l.proximity("x");
  CHECK(!l.proximity("one too many").valid());
}

void test_params_jog_cmd() {
  KLink l("Cell", KLink::ARM);
  FakeTransport t;
  l.addTransport(&t);
  KParam kp = l.param("J1_KP", 120, 0, 400);
  kp.onChange([](float v) { lastParam = v; });
  l.onParamsWritten([] { writes++; });
  l.onJog([](const float* j) { memcpy(lastJog, j, sizeof(lastJog)); });
  static char lastCmd[16];
  static float lastArg;
  l.onCommand([](const char* c, JsonObjectConst a) {
    strncpy(lastCmd, c, sizeof(lastCmd) - 1);
    lastArg = a["v"] | -1.0f;
  });
  t.in.push_back("{\"t\":\"hello\"}");
  t.in.push_back("{\"t\":\"pset\",\"p\":{\"J1_KP\":999,\"NOPE\":1}}");
  t.in.push_back("{\"t\":\"jog\",\"j\":[0,0,1,0,0,-1]}");
  t.in.push_back("{\"t\":\"cmd\",\"c\":\"gripper\",\"a\":{\"v\":0.9}}");
  run(l, t, 30);
  CHECK(kp.value() == 400 && lastParam == 400 && writes == 1);  // clamped to max
  auto ack = t.of("pack");
  CHECK(ack.size() == 1 && ack[0]["keys"].size() == 1);
  CHECK(lastJog[2] == 1 && lastJog[5] == -1);
  CHECK(strcmp(lastCmd, "gripper") == 0 && fabs(lastArg - 0.9f) < 1e-5);
}

void test_pairing() {
  KLink l("Kite-9", KLink::DRONE);
  FakeTransport t;
  l.addTransport(&t);
  l.pair("4f7-k2q");
  run(l, t, 1100, false);
  CHECK(!t.announced.empty() && t.announced.back().find("\"pair\":\"4F7-K2Q\"") != std::string::npos);
  t.in.push_back("{\"t\":\"pair\",\"code\":\"XXX-XXX\",\"key\":\"deadbeef\"}");
  run(l, t, 10, false);
  CHECK(!l.paired());
  t.in.push_back("{\"t\":\"pair\",\"code\":\"4F7-K2Q\",\"key\":\"00112233445566778899aabbccddeeff\"}");
  run(l, t, 10, false);
  CHECK(l.paired() && t.of("paired").size() == 1);
  t.in.push_back("{\"t\":\"hello\",\"key\":\"wrong\"}");
  run(l, t, 10, false);
  CHECK(t.of("hello").back()["ok"] == false);
  t.in.push_back("{\"t\":\"hello\",\"key\":\"00112233445566778899aabbccddeeff\"}");
  run(l, t, 10);
  CHECK(t.of("hello").back()["ok"] == true);
}

void test_point_cloud() {
  KLink l("Scan", KLink::ROVER);
  FakeTransport t;
  l.addTransport(&t);
  static const float pts[2][3] = {{1, 0, 0}, {-0.02f, 0.01f, 5}};
  t.in.push_back("{\"t\":\"hello\"}");
  l.points(pts, 2);
  run(l, t, 150);
  auto pc = t.of("pc");
  // Must match protocol/vectors.json "point cloud i16cm".
  CHECK(pc.size() == 1 && pc[0]["n"] == 2 && strcmp(pc[0]["d"], "ZAAAAAAA/v8BAPQB") == 0);
}

void test_discover() {
  KLink l("Kite-2", KLink::DRONE);
  FakeTransport t;
  l.addTransport(&t);
  t.in.push_back("{\"t\":\"discover\"}");
  run(l, t, 10, false);
  CHECK(t.of("announce").size() == 1);
}

// ---- third-party networking: any library's UDP class
struct FakeIP {
  uint8_t a = 0, b = 0, c = 0, d = 0;
  FakeIP() = default;
  FakeIP(uint8_t a, uint8_t b, uint8_t c, uint8_t d) : a(a), b(b), c(c), d(d) {}
  bool operator==(const FakeIP& o) const { return a == o.a && b == o.b && c == o.c && d == o.d; }
};

struct Datagram {
  FakeIP ip;
  uint16_t port;
  std::string data;
};

// Shaped like EthernetUDP / WiFiEspAT's UDP: only the usual methods.
struct FakeEthernetUdp {
  std::deque<Datagram> in;
  std::vector<Datagram> out;
  Datagram cur, building;
  uint16_t bound = 0;
  uint8_t begin(uint16_t p) {
    bound = p;
    return 1;
  }
  int parsePacket() {
    if (in.empty()) return 0;
    cur = in.front();
    in.pop_front();
    return static_cast<int>(cur.data.size());
  }
  FakeIP remoteIP() { return cur.ip; }
  uint16_t remotePort() { return cur.port; }
  int read(char* buf, size_t cap) {
    size_t n = cur.data.size() < cap ? cur.data.size() : cap;
    memcpy(buf, cur.data.data(), n);
    return static_cast<int>(n);
  }
  int beginPacket(FakeIP ip, uint16_t port) {
    building = {ip, port, ""};
    return 1;
  }
  size_t write(const uint8_t* b, size_t n) {
    building.data.append(reinterpret_cast<const char*>(b), n);
    return n;
  }
  int endPacket() {
    out.push_back(building);
    return 1;
  }
  std::vector<std::string> to(FakeIP ip, uint16_t port, const char* t) {
    std::vector<std::string> r;
    for (auto& d : out) {
      JsonDocument j;
      deserializeJson(j, d.data);
      if (d.ip == ip && d.port == port && strcmp(j["t"] | "", t) == 0) r.push_back(d.data);
    }
    return r;
  }
};

void test_third_party_udp() {
  KLink l("Teensy-Bot", KLink::ROVER);
  FakeEthernetUdp udp;
  CHECK(l.beginUdp(udp, 47800));
  CHECK(udp.bound == 47800);
  const FakeIP app(10, 0, 0, 7), other(10, 0, 0, 9);
  for (int i = 0; i < 110; i++) {
    g_millis += 10;
    l.update();
  }
  CHECK(!udp.to(FakeIP(255, 255, 255, 255), 47801, "announce").empty());
  udp.in.push_back({app, 50000, "{\"t\":\"hello\"}"});
  udp.in.push_back({other, 50001, "{\"t\":\"arm\",\"v\":true}"});  // not the session peer
  for (int i = 0; i < 30; i++) {
    udp.in.push_back({app, 50000, "{\"t\":\"ctl\",\"s\":1,\"lx\":0,\"ly\":0,\"rx\":0,\"ry\":0}"});
    g_millis += 10;
    l.update();
  }
  CHECK(!udp.to(app, 50000, "hello").empty());
  CHECK(!l.armed());
  udp.in.push_back({app, 50000, "{\"t\":\"arm\",\"v\":true}"});
  g_millis += 10;
  l.update();
  CHECK(l.armed());
}

struct Wire : Stream {
  std::string in, out;
  int available() override { return static_cast<int>(in.size()); }
  int read() override {
    if (in.empty()) return -1;
    int c = static_cast<unsigned char>(in[0]);
    in.erase(0, 1);
    return c;
  }
  size_t write(uint8_t c) override {
    out.push_back(static_cast<char>(c));
    return 1;
  }
  int count(const char* t) const {
    int n = 0;
    std::string needle = std::string("\"t\":\"") + t + "\"";
    for (size_t p = out.find(needle); p != std::string::npos; p = out.find(needle, p + 1)) n++;
    return n;
  }
};

void test_bluetooth_module_rates() {
  // An HM-10 at its default 9600 baud: 2 Hz, compact, announced on the UART.
  KLink l("Uno-Bot", KLink::ROVER);
  Wire hm10;
  CHECK(l.beginModule(hm10, 9600));
  for (int i = 0; i < 110; i++) {
    g_millis += 10;
    l.update();
  }
  CHECK(hm10.count("announce") >= 1);
  hm10.in = "{\"t\":\"hello\"}\n";
  hm10.out.clear();
  for (int i = 0; i < 100; i++) {
    hm10.in += "{\"t\":\"ctl\",\"s\":1,\"lx\":0,\"ly\":0,\"rx\":0,\"ry\":0}\n";
    l.imu(0, 0, 9.81f, 0, 0, 0);
    l.position(1, 2, 0);
    g_millis += 10;
    l.update();
  }
  CHECK(hm10.count("tlm") >= 1 && hm10.count("tlm") <= 3);
  CHECK(hm10.out.find("\"imu\"") == std::string::npos);  // compact at 2 Hz
  CHECK(!l.failsafeActive());                               // control is accepted

  // The same module set to 115200 baud: 10 Hz.
  KLink f("Fast-Bot", KLink::ROVER);
  Wire fast;
  f.beginModule(fast, 115200);
  fast.in = "{\"t\":\"hello\"}\n";
  for (int i = 0; i < 100; i++) {
    f.imu(0, 0, 9.81f, 0, 0, 0);
    g_millis += 10;
    f.update();
  }
  CHECK(fast.count("tlm") >= 8 && fast.count("tlm") <= 12);
}

// ---- stored sequences: the shared scenario in protocol/vectors.json
static JsonDocument g_vec;
static std::vector<std::string> g_calls;
static float g_pos[3];
static KLink* g_seq = nullptr;

static void seqOnArm(bool v) { g_calls.push_back(std::string("arm||{\"v\":") + (v ? "true" : "false") + "}"); }
static void seqOnMode(KMode m) {
  g_calls.push_back(std::string("mode|") + kModeName(m) + "|{}");
  if (m == KMode::LAND) {
    g_pos[2] = 0;
    g_seq->setArmed(false);
  }
}
static void seqOnCmd(const char* c, JsonObjectConst a) {
  std::string args;
  serializeJson(a, args);
  g_calls.push_back(std::string("cmd|") + c + "|" + args);
  if (!strcmp(c, "takeoff")) {
    g_pos[2] = a["alt"];
    g_seq->setMode(KMode::HOLD);
  } else if (!strcmp(c, "goto")) {
    g_pos[0] = a["x"];
    g_pos[1] = a["y"];
    g_pos[2] = a["z"] | g_pos[2];
  }
}

static void runSeq(KLink& l, FakeTransport& t, uint32_t ms, bool ctl) {
  for (uint32_t i = 0; i < ms; i += 10) {
    l.position(g_pos[0], g_pos[1], g_pos[2]);
    run(l, t, 10, ctl);
  }
}

static JsonDocument lastRun(FakeTransport& t) {
  JsonDocument r;
  for (auto& s : t.of("state"))
    if (!s["ext"]["run"].isNull()) r = s["ext"]["run"];
  return r;
}

void test_stored_sequences() {
  FILE* f = fopen("../../../../protocol/vectors.json", "rb");
  CHECK(f != nullptr);
  if (!f) return;
  std::string txt;
  char b[4096];
  for (size_t n; (n = fread(b, 1, sizeof(b), f)) > 0;) txt.append(b, n);
  fclose(f);
  CHECK(!deserializeJson(g_vec, txt));
  JsonObjectConst sq = g_vec["sequence"];

  KLink l("Seq-1", KLink::DRONE);
  g_seq = &l;
  FakeTransport t;
  l.addTransport(&t);
  l.onArm(seqOnArm);
  l.onMode(seqOnMode);
  l.onCommand(seqOnCmd);
  t.in.push_back("{\"t\":\"hello\",\"v\":1}");
  runSeq(l, t, 50, true);
  CHECK(t.of("hello")[0]["seq"] == KLINK_MAX_STEPS);

  t.in.push_back(sq["upload"].as<const char*>());
  runSeq(l, t, 20, true);
  CHECK(t.of("seqack").back()["ok"] == true);
  t.in.push_back(sq["run"].as<const char*>());
  // No control heartbeat: the failsafe would switch to HOLD after 1.8 s.
  // The stored sequence must not be interrupted.
  runSeq(l, t, 3000, false);
  JsonDocument r = lastRun(t);
  CHECK(strcmp(r["st"] | "", "done") == 0);
  CHECK(r["i"] == sq["steps"]);
  CHECK(fabsf(l.speedLimit() - 0.5f) < 1e-6f);
  size_t k = 0;
  for (JsonArrayConst c : sq["calls"].as<JsonArrayConst>()) {
    if (!strcmp(c[0], "speed")) continue;
    CHECK(k < g_calls.size());
    if (k >= g_calls.size()) break;
    const std::string& got = g_calls[k++];
    std::string kind = got.substr(0, got.find('|'));
    std::string rest = got.substr(got.find('|') + 1);
    std::string name = rest.substr(0, rest.find('|'));
    JsonDocument args;
    deserializeJson(args, rest.substr(rest.find('|') + 1));
    CHECK(kind == c[0].as<const char*>());
    CHECK(name == c[1].as<const char*>());
    for (JsonPairConst kv : c[2].as<JsonObjectConst>()) CHECK(args[kv.key()] == kv.value());
  }

  // Refused steps
  t.in.push_back(sq["reject"].as<const char*>());
  runSeq(l, t, 20, true);
  CHECK(t.of("seqack").back()["ok"] == false);
  CHECK(strstr(t.of("seqack").back()["err"] | "", "fly_upside_down") != nullptr);

  // Pause, resume, STOP
  t.in.push_back("{\"t\":\"seq\",\"id\":\"w\",\"steps\":[[\"wait\",{\"s\":30}]]}");
  t.in.push_back("{\"t\":\"seqrun\",\"id\":\"w\"}");
  runSeq(l, t, 700, true);
  r = lastRun(t);
  CHECK(strcmp(r["st"] | "", "run") == 0);
  CHECK((r["p"] | 0.0f) > 0 && (r["p"] | 0.0f) < 1);
  t.in.push_back("{\"t\":\"seqctl\",\"c\":\"pause\"}");
  runSeq(l, t, 50, true);
  CHECK(strcmp(lastRun(t)["st"] | "", "pause") == 0);
  t.in.push_back("{\"t\":\"seqctl\",\"c\":\"resume\"}");
  runSeq(l, t, 50, true);
  CHECK(strcmp(lastRun(t)["st"] | "", "run") == 0);
  t.in.push_back("{\"t\":\"stop\"}");
  runSeq(l, t, 50, true);
  r = lastRun(t);
  CHECK(strcmp(r["st"] | "", "fail") == 0);
  CHECK(strstr(r["msg"] | "", "emergency") != nullptr);
}

int main() {
  test_handshake();
  test_control_stop_failsafe();
  test_control_only_on_fast_links();
  test_radio_profiles();
  test_video_state_label_connect();
  test_proximity();
  test_params_jog_cmd();
  test_pairing();
  test_point_cloud();
  test_discover();
  test_third_party_udp();
  test_bluetooth_module_rates();
  test_stored_sequences();
  printf("%d checks, %d failures\n", checks, failures);
  return failures ? 1 : 0;
}
