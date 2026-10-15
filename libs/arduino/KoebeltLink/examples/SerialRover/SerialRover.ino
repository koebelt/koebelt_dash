// Rover over USB serial: plug the board into a laptop running koebelt/dash
// (desktop), or into a Raspberry Pi running the Python bridge.
#include <KoebeltLink.h>

KLink klink("Mule-3", KLink::ROVER);
float speed = 0, turn = 0;

void setup() {
  Serial.begin(115200);
  klink.beginSerial(Serial);
  klink.onControl([](const KControl& c) { speed = c.ry; turn = c.lx; });
  klink.onStop([] { speed = turn = 0; });
  klink.failsafe(1000, KMode::HOLD);
}

void loop() {
  static float x = 0, y = 0, h = 0;
  float s = klink.stopped() || !klink.armed() ? 0 : speed * klink.speedLimit() * 2;
  h -= turn * 0.02f;
  x += cosf(h) * s * 0.02f;
  y += sinf(h) * s * 0.02f;
  klink.position(x, y, 0);
  klink.attitude(0, 0, h);
  klink.velocity(cosf(h) * s, sinf(h) * s, 0);
  klink.battery(12.4f, 71);
  klink.update();
  delay(20);
}
