// Any board plus a Bluetooth serial module on a UART:
//   BLE:     HM-10, HM-19, AT-09, BT05, JDY-08/23, HC-08, RN4870, DFRobot Bluno
//   Classic: HC-05, HC-06 (pair it in the computer's or phone's Bluetooth settings)
// Wiring: module TX -> board RX1, module RX -> board TX1 (through a divider on
// 5 V boards), VCC, GND. The app finds BLE modules under Pair device > Nearby.
#include <KoebeltLink.h>

KLink klink("Module-Bot", KLink::ROVER);
float speed = 0, turn = 0;

void setup() {
  Serial1.begin(9600);             // the module's factory baud rate
  klink.beginModule(Serial1, 9600); // 2 Hz telemetry at 9600 baud; 10 Hz at 115200
  klink.onControl([](const KControl& c) { speed = c.ry; turn = c.lx; });
  klink.onStop([] { speed = turn = 0; });
  klink.failsafe(1500, KMode::HOLD);
}

void loop() {
  klink.battery(7.4f, 80);
  klink.update();
  delay(20);
}
