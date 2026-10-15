// Motor test stand: load cell + tachometer + ESC. The app's test-bench
// screen sends throttle and ramp/step sequence commands.
#include <KoebeltLink.h>
#include <ESP32Servo.h>   // any ESC driver works

KLink klink("Thrust bench", KLink::BENCH);
Servo esc;
KParam maxCurrent, maxTemp, rampTime;
float throttle = 0, seqT = 0;
const char* seq = nullptr;

float readThrustN() { return 0; }     // HX711 here
float readRpm() { return 0; }         // optical tach here
float readCurrentA() { return 0; }    // INA228 here
float readTempC() { return 25; }      // NTC here

void setThrottle(float v) { throttle = constrain(v, 0, 1); esc.writeMicroseconds(1000 + throttle * 1000); }

void setup() {
  esc.attach(18);
  setThrottle(0);
  klink.begin("your-ssid", "your-password");
  maxCurrent = klink.param("MAX_CURRENT", 45, 5, 120, "A");
  maxTemp = klink.param("MAX_TEMP", 90, 40, 150, "C");
  rampTime = klink.param("RAMP_TIME", 10, 2, 60, "s");
  klink.onStop([] { seq = nullptr; setThrottle(0); });
  klink.onCommand([](const char* c, JsonObjectConst a) {
    if (!klink.armed()) return;
    if (!strcmp(c, "throttle")) setThrottle(a["v"] | 0.0f);
    if (!strcmp(c, "seq")) {
      const char* k = a["kind"];
      seq = k && !strcmp(k, "RAMP") ? "RAMP" : nullptr;
      seqT = 0;
      klink.setMode(seq ? KMode::RAMP : KMode::IDLE);
      if (!seq) setThrottle(0);
    }
    if (!strcmp(c, "clear")) { klink.setCutoff(nullptr); klink.setMode(KMode::IDLE); }
  });
}

void loop() {
  static uint32_t last = millis();
  float dt = (millis() - last) / 1000.0f;
  last = millis();
  if (seq) {
    seqT += dt;
    float rt = rampTime;
    setThrottle(seqT < rt ? seqT / rt : seqT < rt + 2 ? 1 : 0);
    if (seqT > rt + 2) { seq = nullptr; klink.setMode(KMode::IDLE); }
  }
  float amps = readCurrentA(), temp = readTempC();
  if (amps > maxCurrent || temp > maxTemp) {
    seq = nullptr;
    setThrottle(0);
    klink.setCutoff(amps > maxCurrent ? "Current limit" : "Temperature limit");
    klink.setMode(KMode::CUTOFF);
  }
  float n = readThrustN();
  klink.thrust(n, n * 0.012f);
  klink.rpm(readRpm());
  klink.battery(22.2f, 100, amps);
  klink.temperature(temp);
  klink.throttleOut(throttle);
  klink.update();
}
