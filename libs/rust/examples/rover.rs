//! A rover on a Raspberry Pi: `cargo run --example rover`, then connect from
//! koebelt/dash (Devices > Pair device, or add by IP address).
use std::time::Duration;

use koebelt_link::{Device, Kind, Mode};

fn main() -> std::io::Result<()> {
    let mut dev = Device::new("Mule-R", Kind::Rover).model("Rust example rover").wifi("", "").start()?;
    dev.on_stop(|| println!("STOP: motors cut"));
    dev.on_mode(|m| println!("mode -> {}", m.as_str()));
    dev.failsafe(Duration::from_millis(1800), Mode::Hold);
    let max_speed = dev.link.param("MAX_SPD", 2.0, 0.5, 6.0, "m/s");
    dev.link.set_armed(true);

    let (mut x, mut y, mut h, mut v) = (0f32, 0f32, 0f32, 0f32);
    println!("Mule-R listening on UDP {}", dev.local_port());
    loop {
        let c = dev.link.control();
        let manual = dev.link.mode() == Mode::Manual && dev.link.armed() && !dev.link.stopped();
        let target = if manual { c.ry * dev.link.param_value(max_speed) * dev.link.speed_limit() * 2.0 } else { 0.0 };
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
