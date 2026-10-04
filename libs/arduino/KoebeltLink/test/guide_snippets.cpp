// Compile-only check: every Arduino snippet from the app's Guides screen
// (apps/dash/lib/screens/guides_data.dart) must build against this library.
#include <Arduino.h>

#include "KoebeltLink.h"

#define WIFI_SSID "ssid"
#define WIFI_PASS "pass"

KLink link("Kite-03", KLink::DRONE);
struct { float ax, ay, az, gx, gy, gz; void read() {} } imu;
struct { double lat, lon; float alt; } gps;
struct {
  void returnHome() {}
  void goTo(float, float, float) {}
  void takeOff(float) {}
  bool arrived() { return true; }
  float x() { return 0; }
  float y() { return 0; }
  float z() { return 0; }
} nav;
float angles[6];
struct { void cut() {} void enable(bool) {} } motors;
struct { float kp; } rollPid;
float vbat, pct, throttle, yaw, pitch, roll, t1, t2, t3, t4;

void guide_setup() {
  link.begin(WIFI_SSID, WIFI_PASS);  // or link.beginBLE()
  link.pair("4F7-K2Q");
  link.onControl([](const KControl& c) {
    throttle = c.ly;  yaw = c.lx;
    pitch    = c.ry;  roll = c.rx;
  });
  link.onMode([](KMode m) {
    if (m == KMode::RTH) nav.returnHome();
  });
  link.onStop([] { motors.cut(); });
  link.onArm([](bool armed) { motors.enable(armed); });
  link.failsafe(1800, KMode::HOLD);

  KParam rollP = link.param("RATE_RLL_P", 0.135, 0.0, 0.5);
  KParam maxTilt = link.param("MAX_TILT", 35, 10, 60, "deg");
  (void)maxTilt;
  rollP.onChange([](float v) { rollPid.kp = v; });
  link.onParamsWritten([] { link.saveParams(); });

  KChannel temp = link.channel("motor_temp", {"M1","M2","M3","M4"}, "C", 10);
  temp.publish(t1, t2, t3, t4);

  link.fallback(KLink::LORA, 915E6);
}

void guide_sequences() {
  link.onCommand([](const char* c, JsonObjectConst a) {
    if (!strcmp(c, "goto")) {
      nav.goTo(a["x"] | 0.0f, a["y"] | 0.0f, a["z"] | 0.0f);
      link.setMode(KMode::AUTO);
    }
    if (!strcmp(c, "takeoff")) nav.takeOff(a["alt"] | 5.0f);
  });

  // in loop(): report arrival
  if (link.mode() == KMode::AUTO && nav.arrived()) link.setMode(KMode::HOLD);
  link.position(nav.x(), nav.y(), nav.z());
  link.joints(angles, 6);
}

void guide_loop() {
  imu.read();
  link.imu(imu.ax, imu.ay, imu.az, imu.gx, imu.gy, imu.gz);
  link.gps(gps.lat, gps.lon, gps.alt);
  link.battery(vbat, pct);
  link.update();
}
