//! koebelt/link: connect drones, robots and test rigs to the koebelt/dash app.
//!
//! With `std` (default):
//! ```no_run
//! use koebelt_link::{Device, Kind, Mode};
//! use std::time::Duration;
//!
//! # async fn run() -> std::io::Result<()> {
//! let mut dev = Device::new("Kite-04", Kind::Drone).wifi("ssid", "pass").start()?;
//! dev.on_stop(|| println!("cut motors"));
//! dev.failsafe(Duration::from_millis(1800), Mode::Hold);
//! loop {
//!     dev.imu([0.0, 0.0, 9.81], [0.0, 0.0, 0.0])?;
//!     if let Some(c) = dev.poll_control() {
//!         println!("{} {} {} {}", c.lx, c.ly, c.rx, c.ry);
//!     }
//!     dev.tick().await;
//! }
//! # }
//! ```
//!
//! Without `std` (`--no-default-features --features embassy`), use [`Link`]
//! with your own [`Transport`] and read [`Event`]s from `poll_event()`.
#![cfg_attr(not(feature = "std"), no_std)]

pub mod json;
mod link;

pub use link::{CommandArgs, CommandName, Event, Fallback, LineReader, Link, MAX_STEPS, Transport};

#[cfg(feature = "std")]
mod device;
#[cfg(feature = "std")]
pub use device::{Device, DeviceBuilder, UdpTransport};
#[cfg(feature = "std")]
mod stream;
#[cfg(feature = "std")]
pub use stream::{SerialTransport, StreamTransport};
#[cfg(feature = "ble")]
mod ble;
#[cfg(feature = "ble")]
pub use ble::{BLE_RX, BLE_SERVICE, BLE_TX, BleTransport};
#[cfg(feature = "std")]
mod video;
#[cfg(feature = "std")]
pub use video::MjpegServer;

pub const UDP_DEVICE_PORT: u16 = 47800;

/// Radio modems on a serial port (protocol/PROTOCOL.md, "Radio links").
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Radio {
    /// SiK telemetry radios: 3DR, Holybro, RFD900.
    Sik,
    /// A LoRa UART module or ground station. Telemetry only.
    Lora,
    Hc12,
    Xbee,
    Other,
}

/// Telemetry rate for a serial bridge module (HM-10, HC-05, RN4870…) at
/// `baud`: 2 Hz up to 19200 baud, 5 Hz to 57600, 10 Hz above. Same in every
/// library.
pub const fn module_rate_hz(baud: u32) -> u8 {
    if baud <= 19200 {
        2
    } else if baud <= 57600 {
        5
    } else {
        10
    }
}

/// Link rates for a [`Radio`]. Same table in every library and in
/// protocol/vectors.json.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct RadioProfile {
    pub id: &'static str,
    /// Serial speed the module is usually configured for.
    pub baud: u32,
    pub tlm_hz: u8,
    /// Control heartbeat; 0 = telemetry only.
    pub ctl_hz: u8,
}

impl Radio {
    pub const ALL: [Radio; 5] = [Radio::Sik, Radio::Lora, Radio::Hc12, Radio::Xbee, Radio::Other];
    pub const fn profile(self) -> RadioProfile {
        match self {
            Radio::Sik => RadioProfile { id: "sik", baud: 57600, tlm_hz: 5, ctl_hz: 10 },
            Radio::Lora => RadioProfile { id: "lora", baud: 115200, tlm_hz: 2, ctl_hz: 0 },
            Radio::Hc12 => RadioProfile { id: "hc12", baud: 9600, tlm_hz: 2, ctl_hz: 5 },
            Radio::Xbee => RadioProfile { id: "xbee", baud: 57600, tlm_hz: 5, ctl_hz: 10 },
            Radio::Other => RadioProfile { id: "other", baud: 57600, tlm_hz: 2, ctl_hz: 5 },
        }
    }
}
pub const UDP_ANNOUNCE_PORT: u16 = 47801;

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Kind {
    Drone,
    Rover,
    Arm,
    Rocket,
    Bench,
    Generic,
}

impl Kind {
    pub fn as_str(self) -> &'static str {
        match self {
            Kind::Drone => "drone",
            Kind::Rover => "rover",
            Kind::Arm => "arm",
            Kind::Rocket => "rocket",
            Kind::Bench => "bench",
            Kind::Generic => "generic",
        }
    }
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Mode {
    Auto,
    Manual,
    Hold,
    Takeoff,
    Land,
    Rth,
    Pad,
    Count,
    Boost,
    Coast,
    Drogue,
    Main,
    Landed,
    Idle,
    Ramp,
    Steps,
    Cutoff,
}

const MODES: [(Mode, &str); 17] = [
    (Mode::Auto, "AUTO"),
    (Mode::Manual, "MANUAL"),
    (Mode::Hold, "HOLD"),
    (Mode::Takeoff, "TAKEOFF"),
    (Mode::Land, "LAND"),
    (Mode::Rth, "RTH"),
    (Mode::Pad, "PAD"),
    (Mode::Count, "COUNT"),
    (Mode::Boost, "BOOST"),
    (Mode::Coast, "COAST"),
    (Mode::Drogue, "DROGUE"),
    (Mode::Main, "MAIN"),
    (Mode::Landed, "LANDED"),
    (Mode::Idle, "IDLE"),
    (Mode::Ramp, "RAMP"),
    (Mode::Steps, "STEPS"),
    (Mode::Cutoff, "CUTOFF"),
];

impl Mode {
    pub fn as_str(self) -> &'static str {
        MODES.iter().find(|(m, _)| *m == self).map(|(_, s)| *s).unwrap_or("HOLD")
    }
    pub fn parse(s: &str) -> Option<Mode> {
        MODES.iter().find(|(_, n)| n.eq_ignore_ascii_case(s)).map(|(m, _)| *m)
    }
}

/// Four normalised axes, −1…1. Sticks, sliders and tilt all arrive here.
#[derive(Clone, Copy, Debug, Default, PartialEq)]
pub struct Control {
    pub lx: f32,
    pub ly: f32,
    pub rx: f32,
    pub ry: f32,
    pub seq: u32,
}
