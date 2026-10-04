// Wired network through a W5500 / W5100 module and the Ethernet library:
// any networking library's UDP object works with beginUdp(). The same goes
// for EthernetENC (ENC28J60), QNEthernet (Teensy 4.1) and STM32Ethernet.
#include <Ethernet.h>
#include <KoebeltLink.h>

byte mac[] = {0x02, 0x4B, 0x4C, 0x00, 0x00, 0x01};
EthernetUDP udp;
KLink link("Wired-Bench", KLink::BENCH);

void setup() {
  Serial.begin(115200);
  Ethernet.init(10);               // chip select pin of the module
  if (Ethernet.begin(mac) == 0) {  // DHCP
    Serial.println("Ethernet: no DHCP answer");
  }
  link.beginUdp(udp);              // listens on 47800, announces on 47801
  link.onStop([] { /* cut the motor */ });
}

void loop() {
  link.thrust(analogRead(A0) * 0.01f, 0);
  link.update();
  Ethernet.maintain();
}
