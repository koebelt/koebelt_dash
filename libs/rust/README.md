# koebelt-link (Rust)

No dependencies. The protocol core (`Link<T: Transport>`) is `no_std` and
allocation-free; the default `std` feature adds a `Device` with callbacks,
Wi-Fi (UDP), serial and radio links, and an MJPEG server for live video.

```rust
use koebelt_link::{Device, Kind, Mode};
use std::time::Duration;

let mut dev = Device::new("Kite-04", Kind::Drone).wifi(SSID, PASS).start()?;
dev.on_stop(|| motors.cut());
dev.failsafe(Duration::from_millis(1800), Mode::Hold);
loop {
    let (a, g) = imu.read()?;
    dev.imu(a, g)?;
    if let Some(c) = dev.poll_control() {
        mixer.apply(c.lx, c.ly, c.rx, c.ry);
    }
    dev.tick().await;           // or dev.tick_blocking(50.0)
}
```

On `std`, `.wifi(ssid, pass)` uses the host's existing network connection.

## Links

```rust
let mut dev = Device::new("Mule", Kind::Rover)
    .wifi("", "")                                // primary
    .radio("/dev/ttyAMA0", Radio::Sik)           // takes over telemetry on failsafe
    .start()?;
// or .serial("/dev/ttyUSB0", 115200), .module("/dev/serial0", 9600) for a
// Bluetooth serial module, or .transport(any_transport)
```

### Bluetooth LE

```toml
koebelt-link = { version = "1.6", features = ["ble"] }
```

```rust
let mut dev = Device::new("Cell arm", Kind::Arm).ble().start()?;
```

Advertises the koebelt/link service under the device's name; the app finds
it under Pair device > Nearby. Linux (BlueZ, e.g. Raspberry Pi, Jetson),
macOS and Windows, through `ble-peripheral-rust`. On Linux, building needs
`sudo apt install libdbus-1-dev pkg-config`. The feature is opt-in: without it
the crate has no dependencies.

Serial ports are configured with `stty` (Linux, macOS) or `mode` (Windows).
Radio profiles (`Radio::Sik.profile()`) set the baud rate and the telemetry
and control rates; on a telemetry-only radio (LoRa) only STOP gets through.
`Fallback::new(a, b)` combines any two transports, also in `no_std`.

## Video

```rust
let cam = MjpegServer::bind(8081)?;
dev.video(&cam.url(), "cam", "Front");
cam.push(&jpeg_bytes);                           // whenever you have a frame
```

## Embedded (embassy, embedded-hal)

```toml
koebelt-link = { version = "1.6", default-features = false, features = ["embassy"] }
```

Implement `Transport` (`recv`, `send`, and optionally `reply`, `announce`,
`adopt_peer`, and `accepts_control` / `max_rate_hz` for radios) over your UDP
socket, UART or BLE stack. `LineReader` splits a UART byte stream into
messages. Then:

```rust
let mut link = Link::new("Kite-05", Kind::Drone, my_transport);
loop {
    link.imu(accel, gyro);
    link.update(now_ms());
    while let Some(ev) = link.poll_event() {
        match ev {
            Event::Stop => motors.cut(),
            Event::Control(c) => mixer.apply(c.lx, c.ly, c.rx, c.ry),
            Event::Paired => flash.store_key(link.key()),
            _ => {}
        }
    }
}
```

`Link` holds two 2 KB message buffers and room for a 32-step stored
sequence (about 1 KB). Give its task about 12 KB of stack.

```bash
cargo test
cargo run --example rover
cargo build --no-default-features --features embassy --target thumbv7em-none-eabihf
```
