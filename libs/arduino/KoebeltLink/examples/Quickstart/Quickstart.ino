// Quickstart: an ESP32 streams IMU + battery to koebelt/dash over Wi-Fi and
// maps stick input to four motor outputs. Replace the fake sensor reads.
#include <KoebeltLink.h>
#include <WiFi.h>  // WiFi.RSSI()

const char* WIFI_SSID = "your-ssid";
const char* WIFI_PASS = "your-password";

KLink klink("Kite-03", KLink::DRONE);
KParam rollP;
float throttle, yaw, pitch, roll;
bool armed = false;

void cutMotors() { throttle = yaw = pitch = roll = 0; }

void setup() {
  Serial.begin(115200);
  klink.setModel("Quadcopter · 1.4 kg");
  klink.setSensors("IMU,BARO,GPS");
  if (!klink.begin(WIFI_SSID, WIFI_PASS)) Serial.println("Wi-Fi failed");
  // klink.pair("XXX-XXX");   // paste the code from Guides > Pair with this app, once

  klink.onControl([](const KControl& c) {
    throttle = c.ly; yaw = c.lx; pitch = c.ry; roll = c.rx;
  });
  klink.onMode([](KMode m) { Serial.printf("mode -> %s\n", kModeName(m)); });
  klink.onArm([](bool a) { armed = a; if (!a) cutMotors(); });
  klink.onStop([] { armed = false; cutMotors(); });
  klink.failsafe(1800, KMode::HOLD);

  rollP = klink.param("RATE_RLL_P", 0.135, 0.0, 0.5);
  klink.param("MAX_TILT", 35, 10, 60, "deg");
  klink.onParamsWritten([] { klink.saveParams(); });
}

void loop() {
  float t = millis() / 1000.0f;
  klink.imu(0.02f * sinf(t), 0.02f * cosf(t), 9.81f, 0, 0, yaw);
  klink.attitude(roll * 0.3f, pitch * 0.3f, 0);
  klink.battery(15.8f, 82);
  klink.rssi(WiFi.RSSI());
  klink.update();
  // mixer.apply(throttle, yaw, pitch, roll, armed);
}
