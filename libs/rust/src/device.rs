//! `std` convenience layer: UDP transport, closures, key persistence.

use std::io;
use std::net::{SocketAddr, UdpSocket};
use std::path::PathBuf;
use std::time::{Duration, Instant};

use std::collections::HashMap;

use crate::{CommandArgs, Control, Event, Fallback, Kind, Link, Mode, Radio, SerialTransport, Transport, UDP_ANNOUNCE_PORT, UDP_DEVICE_PORT};

/// Wi-Fi / Ethernet transport: one JSON message per datagram.
pub struct UdpTransport {
    sock: UdpSocket,
    peer: Option<SocketAddr>,
    last: Option<SocketAddr>,
}

impl UdpTransport {
    pub fn bind(port: u16) -> io::Result<Self> {
        let sock = UdpSocket::bind(("0.0.0.0", port))?;
        sock.set_nonblocking(true)?;
        sock.set_broadcast(true)?;
        Ok(Self { sock, peer: None, last: None })
    }
    pub fn local_port(&self) -> u16 {
        self.sock.local_addr().map(|a| a.port()).unwrap_or(0)
    }
}

impl Transport for UdpTransport {
    fn recv(&mut self, buf: &mut [u8]) -> Option<usize> {
        loop {
            let (n, from) = self.sock.recv_from(buf).ok()?;
            self.last = Some(from);
            // Only the session peer may send commands; hello/pair/discover are open.
            let open = [&b"\"hello\""[..], b"\"pair\"", b"\"discover\""].iter().any(|t| buf[..n].windows(t.len()).any(|w| w == *t));
            if self.peer.is_none() || self.peer == Some(from) || open {
                return Some(n);
            }
        }
    }
    fn send(&mut self, msg: &[u8]) {
        if let Some(p) = self.peer {
            let _ = self.sock.send_to(msg, p);
        }
    }
    fn reply(&mut self, msg: &[u8]) {
        if let Some(p) = self.last {
            let _ = self.sock.send_to(msg, p);
        }
    }
    fn announce(&mut self, msg: &[u8]) {
        let _ = self.sock.send_to(msg, ("255.255.255.255", UDP_ANNOUNCE_PORT));
    }
    fn adopt_peer(&mut self) {
        self.peer = self.last;
    }
    fn drop_peer(&mut self) {
        self.peer = None;
    }
}

/// Lets a boxed transport (the [`Device`]'s chain of links) be a transport.
impl Transport for Box<dyn Transport + Send> {
    fn recv(&mut self, buf: &mut [u8]) -> Option<usize> {
        (**self).recv(buf)
    }
    fn send(&mut self, msg: &[u8]) {
        (**self).send(msg)
    }
    fn reply(&mut self, msg: &[u8]) {
        (**self).reply(msg)
    }
    fn announce(&mut self, msg: &[u8]) {
        (**self).announce(msg)
    }
    fn adopt_peer(&mut self) {
        (**self).adopt_peer()
    }
    fn drop_peer(&mut self) {
        (**self).drop_peer()
    }
    fn accepts_control(&self) -> bool {
        (**self).accepts_control()
    }
    fn low_bandwidth(&self) -> bool {
        (**self).low_bandwidth()
    }
    fn max_rate_hz(&self) -> f32 {
        (**self).max_rate_hz()
    }
    fn control_seen(&mut self) {
        (**self).control_seen()
    }
    fn failover(&mut self) {
        (**self).failover()
    }
}

enum Spec {
    Udp,
    Serial(String, u32),
    Radio(String, Radio),
    Module(String, u32),
    #[cfg(feature = "ble")]
    Ble,
    Custom(Box<dyn Transport + Send>),
}

pub struct DeviceBuilder {
    name: &'static str,
    kind: Kind,
    port: u16,
    model: &'static str,
    state_dir: Option<PathBuf>,
    links: Vec<Spec>,
}

impl DeviceBuilder {
    /// Wi-Fi / Ethernet (UDP). On a computer the OS is already on the
    /// network, so the credentials are not needed; they are accepted so the
    /// same code reads like the embedded version.
    pub fn wifi(mut self, _ssid: &str, _pass: &str) -> Self {
        self.links.push(Spec::Udp);
        self
    }
    /// USB serial: `.serial("/dev/ttyACM0", 115200)`.
    pub fn serial(mut self, path: &str, baud: u32) -> Self {
        self.links.push(Spec::Serial(path.into(), baud));
        self
    }
    /// A radio modem on a serial port: `.radio("/dev/ttyUSB1", Radio::Sik)`.
    pub fn radio(mut self, path: &str, radio: Radio) -> Self {
        self.links.push(Spec::Radio(path.into(), radio));
        self
    }
    /// A Bluetooth serial module (HM-10, HC-05…) on a UART: `.module("/dev/serial0", 9600)`.
    pub fn module(mut self, path: &str, baud: u32) -> Self {
        self.links.push(Spec::Module(path.into(), baud));
        self
    }
    /// Bluetooth LE: advertises the koebelt/link service under the device's
    /// name, so the app finds it under Pair device > Nearby. Feature `ble`.
    #[cfg(feature = "ble")]
    pub fn ble(mut self) -> Self {
        self.links.push(Spec::Ble);
        self
    }
    /// Any other transport (a TCP serial bridge, a custom radio…).
    pub fn transport(mut self, t: impl Transport + Send + 'static) -> Self {
        self.links.push(Spec::Custom(Box::new(t)));
        self
    }
    /// UDP port for `.wifi()` (default 47800, 0 picks a free one).
    pub fn port(mut self, port: u16) -> Self {
        self.port = port;
        self
    }
    pub fn model(mut self, model: &'static str) -> Self {
        self.model = model;
        self
    }
    /// Where the pairing key and saved parameters live (default `~/.config/koebelt-link`).
    pub fn state_dir(mut self, dir: impl Into<PathBuf>) -> Self {
        self.state_dir = Some(dir.into());
        self
    }
    /// Opens the links. The first is primary, the others take over telemetry
    /// when the failsafe trips. Without any, Wi-Fi (UDP) is used.
    pub fn start(mut self) -> io::Result<Device> {
        if self.links.is_empty() {
            self.links.push(Spec::Udp);
        }
        let mut udp_port = 0;
        let mut opened: Vec<Box<dyn Transport + Send>> = vec![];
        for l in self.links {
            opened.push(match l {
                Spec::Udp => {
                    let t = UdpTransport::bind(self.port)?;
                    udp_port = t.local_port();
                    Box::new(t)
                }
                Spec::Serial(p, b) => Box::new(SerialTransport::open(&p, b)?),
                Spec::Radio(p, r) => Box::new(SerialTransport::radio(&p, r)?),
                Spec::Module(p, b) => Box::new(SerialTransport::module(&p, b)?),
                #[cfg(feature = "ble")]
                Spec::Ble => Box::new(crate::BleTransport::advertise(self.name)?),
                Spec::Custom(t) => t,
            });
        }
        // a, b, c -> Fallback(a, Fallback(b, c))
        let mut chain = opened.pop().expect("one link");
        while let Some(prev) = opened.pop() {
            chain = Box::new(Fallback::new(prev, chain));
        }
        let mut link = Link::new(self.name, self.kind, chain);
        link.set_model(self.model);
        let dir = self.state_dir.unwrap_or_else(|| {
            std::env::var_os("KOEBELT_LINK_HOME")
                .map(PathBuf::from)
                .unwrap_or_else(|| PathBuf::from(std::env::var_os("HOME").unwrap_or_default()).join(".config/koebelt-link"))
        });
        let key_file = dir.join(format!("{}.key", link.id()));
        if let Ok(k) = std::fs::read_to_string(&key_file) {
            link.set_key(k.trim());
        }
        let params_file = dir.join(format!("{}.params", link.id()));
        let saved = std::fs::read_to_string(&params_file)
            .unwrap_or_default()
            .lines()
            .filter_map(|l| l.split_once('=').and_then(|(k, v)| Some((k.trim().to_string(), v.trim().parse().ok()?))))
            .collect();
        Ok(Device {
            link,
            start: Instant::now(),
            key_file,
            params_file,
            saved,
            udp_port,
            on_stop: None,
            on_mode: None,
            on_arm: None,
            on_control: None,
            on_command: None,
            on_jog: None,
            on_cartesian: None,
            on_param: None,
            on_connect: None,
            pending: None,
            last_tick: Instant::now(),
        })
    }
}

type Cb<A> = Option<Box<dyn FnMut(A) + Send>>;
type CmdCb = Option<Box<dyn FnMut(&str, &CommandArgs) + Send>>;

/// A koebelt/link device on a computer (Raspberry Pi, Jetson, laptop).
pub struct Device {
    pub link: Link<Box<dyn Transport + Send>>,
    start: Instant,
    key_file: PathBuf,
    params_file: PathBuf,
    saved: HashMap<String, f32>,
    udp_port: u16,
    on_stop: Option<Box<dyn FnMut() + Send>>,
    on_mode: Cb<Mode>,
    on_arm: Cb<bool>,
    on_control: Cb<Control>,
    on_command: CmdCb,
    on_jog: Cb<[f32; 6]>,
    on_cartesian: Cb<[f32; 3]>,
    on_param: Option<Box<dyn FnMut(usize, f32) + Send>>,
    on_connect: Option<Box<dyn FnMut() + Send>>,
    pending: Option<Control>,
    last_tick: Instant,
}

impl Device {
    #[allow(clippy::new_ret_no_self)]
    pub fn new(name: &'static str, kind: Kind) -> DeviceBuilder {
        DeviceBuilder { name, kind, port: UDP_DEVICE_PORT, model: "", state_dir: None, links: vec![] }
    }

    /// The UDP port `.wifi()` listens on, 0 without Wi-Fi.
    pub fn local_port(&self) -> u16 {
        self.udp_port
    }

    /// Registers a parameter, restoring the value saved by the app's "Save"
    /// (`psave`). Returns its index.
    pub fn param(&mut self, key: &'static str, default: f32, min: f32, max: f32, unit: &'static str) -> usize {
        let i = self.link.param(key, default, min, max, unit);
        if let Some(v) = self.saved.get(key) {
            self.link.set_param(i, *v);
        }
        i
    }

    /// Declares a camera stream: `dev.video(&server.url(), "cam", "Front")`.
    pub fn video(&mut self, url: &str, id: &str, label: &str) {
        // Declared once per run; leaking keeps the no_std core allocation-free.
        let s = |x: &str| -> &'static str { Box::leak(x.to_string().into_boxed_str()) };
        self.link.video(s(url), s(id), "mjpeg", s(label));
    }


    // ---- telemetry (Result for parity with embedded transports that can fail)
    pub fn imu(&mut self, accel: impl Into<[f32; 3]>, gyro: impl Into<[f32; 3]>) -> io::Result<()> {
        self.link.imu(accel.into(), gyro.into());
        Ok(())
    }
    pub fn battery(&mut self, volts: f32, percent: f32) -> io::Result<()> {
        self.link.battery(volts, percent);
        Ok(())
    }
    pub fn gps(&mut self, lat: f64, lon: f64, alt: f32) -> io::Result<()> {
        self.link.gps(lat, lon, alt, 0);
        Ok(())
    }
    pub fn position(&mut self, p: impl Into<[f32; 3]>) -> io::Result<()> {
        self.link.position(p.into());
        Ok(())
    }
    pub fn attitude(&mut self, roll: f32, pitch: f32, yaw: f32) -> io::Result<()> {
        self.link.attitude(roll, pitch, yaw);
        Ok(())
    }

    // ---- callbacks
    pub fn on_stop(&mut self, f: impl FnMut() + Send + 'static) {
        self.on_stop = Some(Box::new(f));
    }
    pub fn on_mode(&mut self, f: impl FnMut(Mode) + Send + 'static) {
        self.on_mode = Some(Box::new(f));
    }
    pub fn on_arm(&mut self, f: impl FnMut(bool) + Send + 'static) {
        self.on_arm = Some(Box::new(f));
    }
    pub fn on_control(&mut self, f: impl FnMut(Control) + Send + 'static) {
        self.on_control = Some(Box::new(f));
    }
    /// The app opened a session.
    pub fn on_connect(&mut self, f: impl FnMut() + Send + 'static) {
        self.on_connect = Some(Box::new(f));
    }

    /// Kind-specific commands from the app (`goto`, `takeoff`, `throttle`, custom…):
    /// `dev.on_command(|name, args| if name == "goto" { nav.go_to(args.get("x"), …) })`.
    pub fn on_command(&mut self, f: impl FnMut(&str, &CommandArgs) + Send + 'static) {
        self.on_command = Some(Box::new(f));
    }
    /// Arm joint jog velocities, −1…1 per joint.
    pub fn on_jog(&mut self, f: impl FnMut([f32; 6]) + Send + 'static) {
        self.on_jog = Some(Box::new(f));
    }
    pub fn on_cartesian(&mut self, f: impl FnMut([f32; 3]) + Send + 'static) {
        self.on_cartesian = Some(Box::new(f));
    }
    /// A parameter written from the Tune screen: index from `link.param`, new value.
    pub fn on_param(&mut self, f: impl FnMut(usize, f32) + Send + 'static) {
        self.on_param = Some(Box::new(f));
    }

    /// Declares a proximity sensor (ultrasonic, infrared, time of flight, a
    /// switch): `dir` rad clockwise from forward, `kind` "ultrasonic", "ir",
    /// "tof" or "switch". For one looking down or with another cone, use
    /// `link` directly. Returns its index for [`Device::set_proximity`].
    pub fn proximity(&mut self, id: &'static str, max: f32, dir: f32, kind: &'static str) -> Option<usize> {
        self.link.proximity(id, max, dir, kind, 0.26, 0.0, 0.0)
    }
    /// What a proximity sensor measures, in metres; `None`: nothing in range.
    pub fn set_proximity(&mut self, sensor: usize, metres: Option<f32>) -> io::Result<()> {
        self.link.set_proximity(sensor, metres);
        Ok(())
    }

    /// Declares a custom channel; returns its index for [`Device::publish`].
    pub fn channel(&mut self, id: &'static str, axes: &[&'static str], unit: &'static str, hz: f32) -> usize {
        self.link.channel(id, axes, unit, hz)
    }
    pub fn publish(&mut self, channel: usize, values: &[f32]) -> io::Result<()> {
        self.link.publish(channel, values);
        Ok(())
    }

    pub fn failsafe(&mut self, timeout: Duration, mode: Mode) {
        self.link.failsafe(timeout.as_millis() as u32, mode);
    }

    pub fn pair(&mut self, code: &str) -> io::Result<()> {
        self.link.pair(code);
        Ok(())
    }

    /// Latest control input received since the last call.
    pub fn poll_control(&mut self) -> Option<Control> {
        self.pending.take()
    }

    /// Non-blocking: handles messages, fires callbacks, sends due telemetry.
    /// Works under any executor (tokio, smol, embassy-std, pollster).
    pub async fn tick(&mut self) {
        self.tick_now();
    }

    /// Blocking variant that also paces the loop to `hz`.
    pub fn tick_blocking(&mut self, hz: f32) {
        self.tick_now();
        let period = Duration::from_secs_f32(1.0 / hz);
        let spent = self.last_tick.elapsed();
        if spent < period {
            std::thread::sleep(period - spent);
        }
        self.last_tick = Instant::now();
    }

    fn tick_now(&mut self) {
        let now = self.start.elapsed().as_millis() as u32;
        self.link.update(now);
        while let Some(e) = self.link.poll_event() {
            match e {
                Event::Control(c) => {
                    self.pending = Some(c);
                    if let Some(f) = self.on_control.as_mut() {
                        f(c)
                    }
                }
                Event::Stop => {
                    if let Some(f) = self.on_stop.as_mut() {
                        f()
                    }
                }
                Event::Mode(m) => {
                    if let Some(f) = self.on_mode.as_mut() {
                        f(m)
                    }
                }
                Event::Arm(a) => {
                    if let Some(f) = self.on_arm.as_mut() {
                        f(a)
                    }
                }
                Event::Command(name, args) => {
                    if let Some(f) = self.on_command.as_mut() {
                        f(name.as_str(), &args)
                    }
                }
                Event::Jog(j) => {
                    if let Some(f) = self.on_jog.as_mut() {
                        f(j)
                    }
                }
                Event::Cartesian(v) => {
                    if let Some(f) = self.on_cartesian.as_mut() {
                        f(v)
                    }
                }
                Event::Param(i, v) => {
                    if let Some(f) = self.on_param.as_mut() {
                        f(i, v)
                    }
                }
                Event::Connected => {
                    if let Some(f) = self.on_connect.as_mut() {
                        f()
                    }
                }
                Event::SaveParams => {
                    let text: String = self.link.params().map(|(_, k, v)| format!("{k}={v}\n")).collect();
                    for (_, k, v) in self.link.params() {
                        self.saved.insert(k.to_string(), v);
                    }
                    if let Some(d) = self.params_file.parent() {
                        let _ = std::fs::create_dir_all(d);
                    }
                    let _ = std::fs::write(&self.params_file, text);
                }
                Event::Paired => {
                    if let Some(d) = self.key_file.parent() {
                        let _ = std::fs::create_dir_all(d);
                    }
                    let _ = std::fs::write(&self.key_file, self.link.key());
                }
                _ => {}
            }
        }
    }
}
