//! `koebelt-compat-device <port>`: a rover on UDP <port> that drives in Manual
//! from the right stick, holds on link loss after 1.8 s and runs stored
//! sequences, like the Python simulator. Written against the 1.0.0 API.
use std::time::Duration;

use koebelt_link::{Device, Kind, Mode};

fn main() -> std::io::Result<()> {
    let port: u16 = std::env::args().nth(1).and_then(|p| p.parse().ok()).unwrap_or(47800);
    let mut dev = Device::new("Compat", Kind::Rover).model("koebelt-link compatibility check").port(port).wifi("", "").start()?;
    dev.failsafe(Duration::from_millis(1800), Mode::Hold);
    let max_speed = dev.link.param("MAX_SPD", 2.0, 0.5, 6.0, "m/s");
    dev.link.set_armed(true);
    println!("listening on UDP {}", dev.local_port());

    let (mut x, mut y, mut h, mut v) = (0f32, 0f32, 0f32, 0f32);
    loop {
        let c = dev.link.control();
        let manual = dev.link.mode() == Mode::Manual && dev.link.armed() && !dev.link.stopped();
        let target = if manual { c.ry * dev.link.param_value(max_speed) * 2.0 } else { 0.0 };
        v += (target - v) * 0.1;
        h -= if manual { c.lx * 0.02 } else { 0.0 };
        x += h.cos() * v * 0.02;
        y += h.sin() * v * 0.02;
        dev.position([x, y, 0.0])?;
        dev.attitude(0.0, 0.0, h)?;
        dev.imu([0.0, 0.0, 9.81], [0.0, 0.0, 0.0])?;
        dev.battery(12.3, 80.0)?;
        dev.tick_blocking(50.0);
    }
}
