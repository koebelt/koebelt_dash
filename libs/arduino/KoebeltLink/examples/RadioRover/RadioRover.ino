// Rover over a SiK telemetry radio (or HC-12 / XBee): the radio sits on a
// UART, its twin is plugged into the computer or phone running koebelt dash.
// Wiring (ESP32): radio TX -> GPIO16 (RX2), radio RX -> GPIO17 (TX2), GND, 5 V.
// In the app: Pair device > Radio > SiK telemetry radio.
#include <KoebeltLink.h>

KLink link("Mule-R", KLink::ROVER);
float speed = 0, turn = 0;

void setup() {
  Serial2.begin(kRadioProfile(KRadio::SIK).baud, SERIAL_8N1, 16, 17);
  link.beginRadio(Serial2, KRadio::SIK);  // 5 Hz telemetry, 10 Hz control
  link.onControl([](const KControl& c) { speed = c.ry; turn = c.lx; });
  link.onStop([] { speed = turn = 0; });
  link.failsafe(1500, KMode::HOLD);       // radios drop packets: a little more slack
}

void loop() {
  static float x = 0, y = 0, h = 0;
  float s = link.stopped() || !link.armed() ? 0 : speed * link.speedLimit() * 2;
  h -= turn * 0.02f;
  x += cosf(h) * s * 0.02f;
  y += sinf(h) * s * 0.02f;
  link.position(x, y, 0);
  link.attitude(0, 0, h);
  link.battery(12.1f, 64);
  link.update();
  delay(20);
}
