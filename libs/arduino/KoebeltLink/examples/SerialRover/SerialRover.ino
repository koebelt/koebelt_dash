// Rover over USB serial: plug the board into a laptop running koebelt/dash
// (desktop), or into a Raspberry Pi running the Python bridge.
#include <KoebeltLink.h>

KLink link("Mule-3", KLink::ROVER);
float speed = 0, turn = 0;

void setup() {
  Serial.begin(115200);
  link.beginSerial(Serial);
  link.onControl([](const KControl& c) { speed = c.ry; turn = c.lx; });
  link.onStop([] { speed = turn = 0; });
  link.failsafe(1000, KMode::HOLD);
}

void loop() {
  static float x = 0, y = 0, h = 0;
  float s = link.stopped() || !link.armed() ? 0 : speed * link.speedLimit() * 2;
  h -= turn * 0.02f;
  x += cosf(h) * s * 0.02f;
  y += sinf(h) * s * 0.02f;
  link.position(x, y, 0);
  link.attitude(0, 0, h);
  link.velocity(cosf(h) * s, sinf(h) * s, 0);
  link.battery(12.4f, 71);
  link.update();
  delay(20);
}
