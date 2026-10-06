//! Bluetooth LE on a computer: the koebelt/link service (Nordic-UART style)
//! that the Arduino and Python libraries advertise, so the app finds the
//! device under Pair device > Nearby. Linux (BlueZ: Raspberry Pi, Jetson),
//! macOS and Windows, through `ble-peripheral-rust`. Feature `ble`.
//!
//! The app writes newline-delimited JSON to RX; the device notifies TX in
//! chunks that fit any negotiated MTU.

use std::io;
use std::sync::Arc;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::mpsc;
use std::thread;
use std::time::{Duration, Instant};

use ble_peripheral_rust::gatt::characteristic::Characteristic;
use ble_peripheral_rust::gatt::peripheral_event::{PeripheralEvent, ReadRequestResponse, RequestResponse, WriteRequestResponse};
use ble_peripheral_rust::gatt::properties::{AttributePermission, CharacteristicProperty};
use ble_peripheral_rust::gatt::service::Service;
use ble_peripheral_rust::{Peripheral, PeripheralImpl};
use uuid::Uuid;

use crate::{LineReader, Transport};

/// The koebelt/link GATT service and its characteristics (protocol/PROTOCOL.md).
pub const BLE_SERVICE: Uuid = Uuid::from_u128(0x6e400001_b5a3_f393_e0a9_e50e24dcca9e);
/// The app writes here.
pub const BLE_RX: Uuid = Uuid::from_u128(0x6e400002_b5a3_f393_e0a9_e50e24dcca9e);
/// The device notifies here.
pub const BLE_TX: Uuid = Uuid::from_u128(0x6e400003_b5a3_f393_e0a9_e50e24dcca9e);

/// Notification payload: fits the 185-byte MTU iOS and Android negotiate.
const CHUNK: usize = 180;

/// Advertises the koebelt/link service and carries one app session.
pub struct BleTransport {
    lines: mpsc::Receiver<Vec<u8>>,
    out: tokio::sync::mpsc::UnboundedSender<Vec<u8>>,
    subscribed: Arc<AtomicBool>,
}

impl BleTransport {
    /// Starts advertising `name` with the koebelt/link service. Fails when
    /// the computer has no Bluetooth adapter, or it is off.
    pub fn advertise(name: &str) -> io::Result<Self> {
        let (line_tx, lines) = mpsc::channel::<Vec<u8>>();
        let (out, mut out_rx) = tokio::sync::mpsc::unbounded_channel::<Vec<u8>>();
        let (ready_tx, ready) = mpsc::channel::<Result<(), String>>();
        let subscribed = Arc::new(AtomicBool::new(false));
        let sub = subscribed.clone();
        let name = name.to_string();
        thread::Builder::new().name("koebelt-ble".into()).spawn(move || {
            let rt = match tokio::runtime::Builder::new_multi_thread().worker_threads(1).enable_all().build() {
                Ok(rt) => rt,
                Err(e) => {
                    let _ = ready_tx.send(Err(e.to_string()));
                    return;
                }
            };
            rt.block_on(async move {
                let (ev_tx, mut events) = tokio::sync::mpsc::channel::<PeripheralEvent>(256);
                let mut p = match Peripheral::new(ev_tx).await {
                    Ok(p) => p,
                    Err(e) => {
                        let _ = ready_tx.send(Err(format!("no Bluetooth adapter: {e}")));
                        return;
                    }
                };
                let t0 = Instant::now();
                while !p.is_powered().await.unwrap_or(false) {
                    if t0.elapsed() > Duration::from_secs(5) {
                        let _ = ready_tx.send(Err("Bluetooth is off".into()));
                        return;
                    }
                    tokio::time::sleep(Duration::from_millis(100)).await;
                }
                if let Err(e) = p.add_service(&service()).await {
                    let _ = ready_tx.send(Err(format!("could not add the service: {e}")));
                    return;
                }
                if let Err(e) = p.start_advertising(&name, &[BLE_SERVICE]).await {
                    let _ = ready_tx.send(Err(format!("could not advertise: {e}")));
                    return;
                }
                let _ = ready_tx.send(Ok(()));
                let mut reader = LineReader::default();
                let mut buf = [0u8; 2048];
                loop {
                    tokio::select! {
                        ev = events.recv() => match ev {
                            None => break,
                            Some(PeripheralEvent::WriteRequest { request, value, responder, .. }) => {
                                if request.characteristic == BLE_RX {
                                    for b in value {
                                        if let Some(n) = reader.feed(b, &mut buf) {
                                            let _ = line_tx.send(buf[..n].to_vec());
                                        }
                                    }
                                }
                                let _ = responder.send(WriteRequestResponse { response: RequestResponse::Success });
                            }
                            Some(PeripheralEvent::ReadRequest { responder, .. }) => {
                                let _ = responder.send(ReadRequestResponse { value: vec![], response: RequestResponse::Success });
                            }
                            Some(PeripheralEvent::CharacteristicSubscriptionUpdate { request, subscribed }) => {
                                if request.characteristic == BLE_TX {
                                    sub.store(subscribed, Ordering::Relaxed);
                                }
                            }
                            Some(_) => {}
                        },
                        msg = out_rx.recv() => match msg {
                            None => break, // transport dropped
                            Some(m) => {
                                for c in frames(&m) {
                                    let _ = p.update_characteristic(BLE_TX, c).await;
                                }
                            }
                        },
                    }
                }
                let _ = p.stop_advertising().await;
            });
        })?;
        match ready.recv_timeout(Duration::from_secs(15)) {
            Ok(Ok(())) => Ok(Self { lines, out, subscribed }),
            Ok(Err(e)) => Err(io::Error::other(format!("Bluetooth LE: {e}"))),
            Err(_) => Err(io::Error::other("Bluetooth LE did not start")),
        }
    }

    /// True while the app is subscribed to notifications (a session is open).
    pub fn connected(&self) -> bool {
        self.subscribed.load(Ordering::Relaxed)
    }
}

/// The GATT service, as the other libraries define it.
fn service() -> Service {
    Service {
        uuid: BLE_SERVICE,
        primary: true,
        characteristics: vec![
            Characteristic {
                uuid: BLE_RX,
                properties: vec![CharacteristicProperty::Write, CharacteristicProperty::WriteWithoutResponse],
                permissions: vec![AttributePermission::Writeable],
                ..Default::default()
            },
            Characteristic {
                uuid: BLE_TX,
                properties: vec![CharacteristicProperty::Notify],
                permissions: vec![AttributePermission::Readable],
                ..Default::default()
            },
        ],
    }
}

/// Splits `msg` plus its newline into notification payloads.
pub(crate) fn frames(msg: &[u8]) -> Vec<Vec<u8>> {
    let mut v = msg.to_vec();
    v.push(b'\n');
    v.chunks(CHUNK).map(|c| c.to_vec()).collect()
}

impl Transport for BleTransport {
    fn recv(&mut self, buf: &mut [u8]) -> Option<usize> {
        let m = self.lines.try_recv().ok()?;
        if m.len() > buf.len() {
            return None;
        }
        buf[..m.len()].copy_from_slice(&m);
        Some(m.len())
    }
    fn send(&mut self, msg: &[u8]) {
        if self.connected() {
            let _ = self.out.send(msg.to_vec());
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn service_matches_the_other_libraries() {
        assert_eq!(BLE_SERVICE.to_string(), "6e400001-b5a3-f393-e0a9-e50e24dcca9e");
        assert_eq!(BLE_RX.to_string(), "6e400002-b5a3-f393-e0a9-e50e24dcca9e");
        assert_eq!(BLE_TX.to_string(), "6e400003-b5a3-f393-e0a9-e50e24dcca9e");
        let s = service();
        assert_eq!(s.characteristics.len(), 2);
    }

    #[test]
    fn long_messages_split_into_mtu_sized_frames_ending_in_a_newline() {
        let msg = vec![b'x'; 400];
        let f = frames(&msg);
        assert_eq!(f.len(), 3);
        assert!(f.iter().all(|c| c.len() <= CHUNK));
        assert_eq!(f.concat().len(), 401);
        assert_eq!(*f.last().unwrap().last().unwrap(), b'\n');
        // and the app side reassembles them
        let mut r = LineReader::default();
        let mut out = [0u8; 2048];
        let got: Vec<usize> = f.concat().into_iter().filter_map(|b| r.feed(b, &mut out)).collect();
        assert_eq!(got, vec![400]);
    }
}
