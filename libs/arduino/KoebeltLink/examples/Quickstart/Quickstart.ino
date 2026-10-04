// Quickstart: an ESP32 streams IMU + battery to koebelt dash over Wi-Fi and
// maps stick input to four motor outputs. Replace the fake sensor reads.
#include <KoebeltLink.h>

const char* WIFI_SSID = "your-ssid";
const char* WIFI_PASS = "your-password";

KLink link("Kite-03", KLink::DRONE);
KParam rollP;
float throttle, yaw, pitch, roll;
bool armed = false;

void cutMotors() { throttle = yaw = pitch = roll = 0; }

void setup() {
  Serial.begin(115200);
  link.setModel("Quadcopter · 1.4 kg");
  link.setSensors("IMU,BARO,GPS");
  if (!link.begin(WIFI_SSID, WIFI_PASS)) Serial.println("Wi-Fi failed");
  // link.pair("XXX-XXX");   // paste the code from Guides > Pair with this app, once

  link.onControl([](const KControl& c) {
    throttle = c.ly; yaw = c.lx; pitch = c.ry; roll = c.rx;
  });
  link.onMode([](KMode m) { Serial.printf("mode -> %s\n", kModeName(m)); });
  link.onArm([](bool a) { armed = a; if (!a) cutMotors(); });
  link.onStop([] { armed = false; cutMotors(); });
  link.failsafe(1800, KMode::HOLD);

  rollP = link.param("RATE_RLL_P", 0.135, 0.0, 0.5);
  link.param("MAX_TILT", 35, 10, 60, "deg");
  link.onParamsWritten([] { link.saveParams(); });
}

void loop() {
  float t = millis() / 1000.0f;
  link.imu(0.02f * sinf(t), 0.02f * cosf(t), 9.81f, 0, 0, yaw);
  link.attitude(roll * 0.3f, pitch * 0.3f, 0);
  link.battery(15.8f, 82);
  link.rssi(WiFi.RSSI());
  link.update();
  // mixer.apply(throttle, yaw, pitch, roll, armed);
}
