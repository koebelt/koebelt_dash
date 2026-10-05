// ESP32 Bluetooth LE with NimBLE-Arduino instead of the core's Bluedroid:
// including its header is enough, koebelt/link then uses it (and saves
// about 100 KB of RAM).
#include <NimBLEDevice.h>
#include <KoebeltLink.h>

KLink link("Cell arm", KLink::ARM);

void setup() {
  link.beginBLE();
  link.onJog([](const float* j) { /* move the joints */ });
}

void loop() {
  const float joints[6] = {0, -0.5f, 1.1f, 0, 0.6f, 0};
  link.joints(joints, 6);
  link.update();
}
