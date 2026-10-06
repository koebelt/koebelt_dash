//! Allocation-free protocol engine. Feed it a [`Transport`] and a clock;
//! it answers the app, streams telemetry and reports [`Event`]s.

use crate::json::{self, Buf};
use crate::{Control, Kind, Mode};

/// One link to the app. Must not block.
pub trait Transport {
    /// Copies one received message into `buf` and returns its length.
    fn recv(&mut self, buf: &mut [u8]) -> Option<usize>;
    /// Sends one message to the session peer.
    fn send(&mut self, msg: &[u8]);
    /// Replies to the sender of the last received message (for `discover`).
    fn reply(&mut self, msg: &[u8]) {
        self.send(msg)
    }
    /// Discovery info while no app is connected: a broadcast on UDP, a plain
    /// write on serial and radio links.
    fn announce(&mut self, _msg: &[u8]) {}
    /// The last message's sender becomes the session peer.
    fn adopt_peer(&mut self) {}
    fn drop_peer(&mut self) {}

    /// False on telemetry-only links (LoRa): only `stop`, `ping`, `rate` and
    /// `bye` are accepted from the link the last message came from.
    fn accepts_control(&self) -> bool {
        true
    }
    /// Radio links: no point clouds or tracks, state every 2 s.
    fn low_bandwidth(&self) -> bool {
        false
    }
    /// Telemetry rate cap of the link messages are sent on, 0 = none. At
    /// 2 Hz or less only the compact field set goes out.
    fn max_rate_hz(&self) -> f32 {
        0.0
    }
    /// A control packet arrived on the link of the last message.
    fn control_seen(&mut self) {}
    /// The failsafe tripped: move outgoing traffic to a fallback link.
    fn failover(&mut self) {}
}

/// Two links, the first primary: telemetry goes where control last came
/// from, and to the other one when the failsafe trips. Chain them for more:
/// `Fallback::new(wifi, Fallback::new(radio, serial))`.
pub struct Fallback<A: Transport, B: Transport> {
    pub a: A,
    pub b: B,
    from_b: bool,
    to_b: bool,
}

impl<A: Transport, B: Transport> Fallback<A, B> {
    pub fn new(a: A, b: B) -> Self {
        Self { a, b, from_b: false, to_b: false }
    }
    /// True while traffic goes to the second link.
    pub fn on_fallback(&self) -> bool {
        self.to_b
    }
}

impl<A: Transport, B: Transport> Transport for Fallback<A, B> {
    fn recv(&mut self, buf: &mut [u8]) -> Option<usize> {
        if let Some(n) = self.a.recv(buf) {
            self.from_b = false;
            return Some(n);
        }
        let n = self.b.recv(buf)?;
        self.from_b = true;
        Some(n)
    }
    fn send(&mut self, msg: &[u8]) {
        if self.to_b { self.b.send(msg) } else { self.a.send(msg) }
    }
    fn reply(&mut self, msg: &[u8]) {
        if self.from_b { self.b.reply(msg) } else { self.a.reply(msg) }
    }
    fn announce(&mut self, msg: &[u8]) {
        self.a.announce(msg);
        self.b.announce(msg);
    }
    fn adopt_peer(&mut self) {
        self.to_b = self.from_b;
        if self.from_b { self.b.adopt_peer() } else { self.a.adopt_peer() }
    }
    fn drop_peer(&mut self) {
        if self.from_b { self.b.drop_peer() } else { self.a.drop_peer() }
    }
    fn accepts_control(&self) -> bool {
        if self.from_b { self.b.accepts_control() } else { self.a.accepts_control() }
    }
    fn low_bandwidth(&self) -> bool {
        if self.to_b { self.b.low_bandwidth() } else { self.a.low_bandwidth() }
    }
    fn max_rate_hz(&self) -> f32 {
        if self.to_b { self.b.max_rate_hz() } else { self.a.max_rate_hz() }
    }
    fn control_seen(&mut self) {
        self.to_b = self.from_b;
        if self.from_b { self.b.control_seen() } else { self.a.control_seen() }
    }
    fn failover(&mut self) {
        if self.to_b {
            self.b.failover()
        } else {
            self.to_b = true;
        }
    }
}

/// Reassembles newline-delimited messages from a byte stream (UART, radio).
pub struct LineReader {
    line: [u8; 2048],
    n: usize,
    overflow: bool,
}

impl Default for LineReader {
    fn default() -> Self {
        Self { line: [0; 2048], n: 0, overflow: false }
    }
}

impl LineReader {
    /// Feeds one byte; returns the message length in `out` when a line completes.
    pub fn feed(&mut self, c: u8, out: &mut [u8]) -> Option<usize> {
        match c {
            b'\n' => {
                let n = core::mem::take(&mut self.n);
                if core::mem::take(&mut self.overflow) || n == 0 || n > out.len() {
                    return None;
                }
                out[..n].copy_from_slice(&self.line[..n]);
                Some(n)
            }
            b'\r' => None,
            _ => {
                if self.n < self.line.len() {
                    self.line[self.n] = c;
                    self.n += 1;
                } else {
                    self.overflow = true;
                }
                None
            }
        }
    }
}

/// What happened since the last poll.
#[derive(Clone, Copy, Debug, PartialEq)]
pub enum Event {
    Connected,
    Control(Control),
    Mode(Mode),
    Arm(bool),
    Stop,
    Reset,
    Jog([f32; 6]),
    Cartesian([f32; 3]),
    /// A parameter changed: index returned by [`Link::param`], new value.
    Param(usize, f32),
    ParamsWritten,
    /// Kind-specific command: name (up to 16 bytes) and its arguments (`a` object).
    Command(CommandName, CommandArgs),
    Failsafe,
    /// A pairing key was received; persist it with [`Link::key`].
    Paired,
    /// The app asked to persist parameters (`psave`); store [`Link::param_value`]s.
    SaveParams,
}

#[derive(Clone, Copy, PartialEq)]
pub struct CommandName {
    buf: [u8; 16],
    len: u8,
}

impl CommandName {
    pub fn as_str(&self) -> &str {
        core::str::from_utf8(&self.buf[..self.len as usize]).unwrap_or("")
    }
}

/// The `a` object of a command, e.g. `{"x":15,"y":0,"z":10}` (up to 160 bytes).
#[derive(Clone, Copy, PartialEq)]
pub struct CommandArgs {
    buf: [u8; 160],
    len: u8,
}

impl CommandArgs {
    /// Numeric argument by name: `args.get("alt")`.
    pub fn get(&self, key: &str) -> Option<f32> {
        json::get(&self.buf[..self.len as usize], key).and_then(json::as_f64).map(|v| v as f32)
    }
    /// String argument by name.
    pub fn get_str(&self, key: &str) -> Option<&str> {
        json::get(&self.buf[..self.len as usize], key).and_then(json::as_str)
    }
    /// The conventional single value (`v`, else `s`).
    pub fn value(&self) -> Option<f32> {
        self.get("v").or_else(|| self.get("s"))
    }
}

impl core::fmt::Debug for CommandArgs {
    fn fmt(&self, f: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        f.write_str(core::str::from_utf8(&self.buf[..self.len as usize]).unwrap_or("{}"))
    }
}

impl core::fmt::Debug for CommandName {
    fn fmt(&self, f: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        f.write_str(self.as_str())
    }
}

#[path = "seq.rs"]
mod seq;
pub use seq::MAX_STEPS;

#[derive(Clone, Copy)]
struct Param {
    key: &'static str,
    unit: &'static str,
    label: &'static str,
    value: f32,
    min: f32,
    max: f32,
    step: f32,
}

const MAX_PARAMS: usize = 32;
const MAX_CHANNELS: usize = 8;

/// A custom telemetry channel (1–6 axes), declared with [`Link::channel`].
#[derive(Clone, Copy)]
struct Chan {
    id: &'static str,
    axes: [&'static str; 6],
    n: u8,
    unit: &'static str,
    hz: f32,
    v: [f32; 6],
    dirty: bool,
}
const MAX_EVENTS: usize = 16;

#[derive(Default, Clone, Copy)]
struct Tlm {
    imu: Option<[f32; 6]>,
    att: Option<[f32; 3]>,
    pos: Option<[f32; 3]>,
    vel: Option<[f32; 3]>,
    gps: Option<(f64, f64, f32, u8)>,
    bat: Option<[f32; 3]>,
    rssi: Option<f32>,
    joints: Option<([f32; 6], u8)>,
    ft: Option<[f32; 3]>,
    thrust: Option<[f32; 2]>,
    rpm: Option<f32>,
    temp: Option<f32>,
    tool: Option<[f32; 4]>,
    throttle: Option<f32>,
    rocket: Option<[f32; 3]>,
}

/// A camera stream declared in `hello` (MJPEG over HTTP).
#[derive(Clone, Copy)]
struct Video {
    id: &'static str,
    url: &'static str,
    fmt: &'static str,
    label: &'static str,
}

pub struct Link<T: Transport> {
    pub transport: T,
    name: &'static str,
    id: [u8; 32],
    id_len: usize,
    kind: Kind,
    model: &'static str,
    fw: &'static str,
    sensors: &'static [&'static str],
    video: [Option<Video>; 2],
    pyro: Option<[&'static str; 4]>,
    cutoff: Option<&'static str>,
    ext: [Option<(&'static str, &'static str)>; 4],
    lib: &'static str,

    session: bool,
    control: Control,
    mode: Mode,
    armed: bool,
    estop: bool,
    speed: f32,
    rate_hz: f32,
    state_dirty: bool,

    fs_timeout_ms: u32,
    fs_mode: Mode,
    fs_active: bool,

    last_ctl: u32,
    t_state: u32,
    t_tlm: u32,
    t_announce: u32,

    pair_code: [u8; 12],
    key: [u8; 40],

    params: [Option<Param>; MAX_PARAMS],
    channels: [Option<Chan>; MAX_CHANNELS],
    tlm: Tlm,

    events: [Option<Event>; MAX_EVENTS],
    ev_head: usize,
    ev_len: usize,

    // stored sequences, and the latest position and joints they check
    stored: Option<seq::Stored>,
    run: Option<seq::Run>,
    t_seq: u32,
    last_pos: [f32; 3],
    last_joints: [f32; 6],
    last_nj: u8,

    rx: [u8; 2048],
    tx: [u8; 2048],
}

impl<T: Transport> Link<T> {
    pub fn new(name: &'static str, kind: Kind, transport: T) -> Self {
        let mut id = [0u8; 32];
        let mut n = 0;
        for c in name.chars() {
            if n >= id.len() {
                break;
            }
            if c.is_ascii_alphanumeric() {
                id[n] = c.to_ascii_lowercase() as u8;
                n += 1;
            } else if n > 0 && id[n - 1] != b'-' {
                id[n] = b'-';
                n += 1;
            }
        }
        while n > 0 && id[n - 1] == b'-' {
            n -= 1;
        }
        Self {
            transport,
            name,
            id,
            id_len: n,
            kind,
            model: "",
            fw: "",
            sensors: &[],
            video: [None; 2],
            pyro: None,
            cutoff: None,
            ext: [None; 4],
            lib: concat!("rust/", env!("CARGO_PKG_VERSION")),
            session: false,
            control: Control::default(),
            mode: match kind {
                Kind::Rocket => Mode::Pad,
                Kind::Bench => Mode::Idle,
                _ => Mode::Hold,
            },
            armed: false,
            estop: false,
            speed: 0.5,
            rate_hz: 30.0,
            state_dirty: true,
            fs_timeout_ms: 1800,
            fs_mode: Mode::Hold,
            fs_active: false,
            last_ctl: 0,
            t_state: 0,
            t_tlm: 0,
            t_announce: 0,
            pair_code: [0; 12],
            key: [0; 40],
            params: [None; MAX_PARAMS],
            channels: [None; MAX_CHANNELS],
            tlm: Tlm::default(),
            events: [None; MAX_EVENTS],
            ev_head: 0,
            ev_len: 0,
            stored: None,
            run: None,
            t_seq: 0,
            last_pos: [0.0; 3],
            last_joints: [0.0; 6],
            last_nj: 0,
            rx: [0; 2048],
            tx: [0; 2048],
        }
    }

    pub fn id(&self) -> &str {
        core::str::from_utf8(&self.id[..self.id_len]).unwrap_or("")
    }
    pub fn set_model(&mut self, model: &'static str) {
        self.model = model;
    }
    pub fn set_firmware(&mut self, fw: &'static str) {
        self.fw = fw;
    }
    /// Sensor names shown in the app: `&["GPS", "IMU"]`.
    pub fn set_sensors(&mut self, s: &'static [&'static str]) {
        self.sensors = s;
    }
    /// Declares a camera stream (MJPEG over HTTP). `url` may be ":8081/stream"
    /// (port and path on this device's IP) or a full URL. Up to two.
    pub fn video(&mut self, url: &'static str, id: &'static str, fmt: &'static str, label: &'static str) {
        let v = Video { id, url, fmt, label };
        if let Some(slot) = self.video.iter_mut().find(|x| x.map(|x| x.id == id).unwrap_or(true)) {
            *slot = Some(v);
        }
    }
    /// Rocket pyro channel states (`"OK"`, `"FIRED"`, `"-"`…).
    pub fn set_pyro(&mut self, p: [&'static str; 4]) {
        self.pyro = Some(p);
        self.state_dirty = true;
    }
    /// Test bench cutoff reason, or None.
    pub fn set_cutoff(&mut self, reason: Option<&'static str>) {
        self.cutoff = reason;
        self.state_dirty = true;
    }
    /// Any other kind-specific state shown in the app, as text (up to 4 keys).
    pub fn set_state(&mut self, key: &'static str, value: &'static str) {
        if let Some(slot) = self.ext.iter_mut().find(|x| x.map(|x| x.0 == key).unwrap_or(true)) {
            *slot = Some((key, value));
            self.state_dirty = true;
        }
    }
    pub fn mode(&self) -> Mode {
        self.mode
    }
    pub fn armed(&self) -> bool {
        self.armed
    }
    pub fn stopped(&self) -> bool {
        self.estop
    }
    pub fn failsafe_active(&self) -> bool {
        self.fs_active
    }
    pub fn connected(&self) -> bool {
        self.session
    }
    pub fn control(&self) -> Control {
        self.control
    }
    pub fn speed_limit(&self) -> f32 {
        self.speed
    }

    pub fn failsafe(&mut self, timeout_ms: u32, mode: Mode) {
        self.fs_timeout_ms = timeout_ms;
        self.fs_mode = mode;
    }

    /// Enter pairing mode with the code shown in the app.
    pub fn pair(&mut self, code: &str) {
        self.pair_code = [0; 12];
        for (i, b) in code.bytes().take(11).enumerate() {
            self.pair_code[i] = b.to_ascii_uppercase();
        }
    }
    /// Current pairing key (empty when unpaired). Persist it and restore it with [`Link::set_key`].
    pub fn key(&self) -> &str {
        let n = self.key.iter().position(|&b| b == 0).unwrap_or(self.key.len());
        core::str::from_utf8(&self.key[..n]).unwrap_or("")
    }
    pub fn set_key(&mut self, key: &str) {
        self.key = [0; 40];
        for (i, b) in key.bytes().take(39).enumerate() {
            self.key[i] = b;
        }
    }
    fn pair_code(&self) -> &str {
        let n = self.pair_code.iter().position(|&b| b == 0).unwrap_or(0);
        core::str::from_utf8(&self.pair_code[..n]).unwrap_or("")
    }

    /// Registers a tunable parameter and returns its index.
    pub fn param(&mut self, key: &'static str, default: f32, min: f32, max: f32, unit: &'static str) -> usize {
        self.param_full(key, default, min, max, unit, 0.0, "")
    }
    /// [`Link::param`] with a step (0 = automatic) and a human label ("" = the key).
    #[allow(clippy::too_many_arguments)]
    pub fn param_full(&mut self, key: &'static str, default: f32, min: f32, max: f32, unit: &'static str, step: f32, label: &'static str) -> usize {
        let span = max - min;
        let step = if step > 0.0 {
            step
        } else if span > 0.0 {
            pow10(floor(log10(span / 100.0)))
        } else {
            0.01
        };
        let slot = self
            .params
            .iter()
            .position(|p| p.map(|p| p.key == key).unwrap_or(false))
            .or_else(|| self.params.iter().position(|p| p.is_none()))
            .unwrap_or(MAX_PARAMS - 1);
        self.params[slot] = Some(Param { key, unit, label, value: default, min, max, step });
        slot
    }
    /// Sets a parameter (clamped), e.g. a value restored from storage.
    pub fn set_param(&mut self, i: usize, v: f32) {
        if let Some(Some(p)) = self.params.get_mut(i) {
            p.value = v.clamp(p.min, p.max);
        }
    }
    /// Parameters as (index, key, value), for persisting them.
    pub fn params(&self) -> impl Iterator<Item = (usize, &'static str, f32)> + '_ {
        self.params.iter().enumerate().filter_map(|(i, p)| p.map(|p| (i, p.key, p.value)))
    }
    /// Declares a custom channel (1–6 axes) and returns its index for
    /// [`Link::publish`]. It appears as a tile, a HUD widget and CSV columns.
    pub fn channel(&mut self, id: &'static str, axes: &[&'static str], unit: &'static str, hz: f32) -> usize {
        let mut a = [""; 6];
        let n = axes.len().min(6);
        a[..n].copy_from_slice(&axes[..n]);
        let slot = self.channels.iter().position(|c| c.is_none()).unwrap_or(MAX_CHANNELS - 1);
        self.channels[slot] = Some(Chan { id, axes: a, n: n as u8, unit, hz, v: [0.0; 6], dirty: false });
        if self.session {
            self.write_channels();
            self.flush();
        }
        slot
    }

    /// Latest values of a custom channel, sent with the next telemetry frame.
    pub fn publish(&mut self, channel: usize, values: &[f32]) {
        if let Some(Some(c)) = self.channels.get_mut(channel) {
            let n = values.len().min(c.n as usize);
            c.v[..n].copy_from_slice(&values[..n]);
            c.dirty = true;
        }
    }

    pub fn param_value(&self, i: usize) -> f32 {
        self.params.get(i).and_then(|p| *p).map(|p| p.value).unwrap_or(0.0)
    }

    // ---- telemetry
    pub fn imu(&mut self, a: [f32; 3], g: [f32; 3]) {
        self.tlm.imu = Some([a[0], a[1], a[2], g[0], g[1], g[2]]);
    }
    pub fn attitude(&mut self, roll: f32, pitch: f32, yaw: f32) {
        self.tlm.att = Some([roll, pitch, yaw]);
    }
    pub fn position(&mut self, p: [f32; 3]) {
        self.tlm.pos = Some(p);
        self.last_pos = p;
    }
    pub fn velocity(&mut self, v: [f32; 3]) {
        self.tlm.vel = Some(v);
    }
    pub fn gps(&mut self, lat: f64, lon: f64, alt: f32, sats: u8) {
        self.tlm.gps = Some((lat, lon, alt, sats));
    }
    pub fn battery(&mut self, volts: f32, percent: f32) {
        let amps = self.tlm.bat.map(|b| b[1]).unwrap_or(0.0);
        self.tlm.bat = Some([volts, amps, percent]);
    }
    pub fn power(&mut self, volts: f32, amps: f32, percent: f32) {
        self.tlm.bat = Some([volts, amps, percent]);
    }
    pub fn rssi(&mut self, dbm: f32) {
        self.tlm.rssi = Some(dbm);
    }
    pub fn joints(&mut self, j: &[f32]) {
        let mut a = [0f32; 6];
        let n = j.len().min(6);
        a[..n].copy_from_slice(&j[..n]);
        self.tlm.joints = Some((a, n as u8));
        self.last_joints = a;
        self.last_nj = n as u8;
    }
    pub fn force_torque(&mut self, f: [f32; 3]) {
        self.tlm.ft = Some(f);
    }
    pub fn thrust(&mut self, newtons: f32, torque: f32) {
        self.tlm.thrust = Some([newtons, torque]);
    }
    pub fn rpm(&mut self, v: f32) {
        self.tlm.rpm = Some(v);
    }
    pub fn temperature(&mut self, c: f32) {
        self.tlm.temp = Some(c);
    }
    /// Arm tool position (m) and gripper opening 0–1.
    pub fn tool(&mut self, x: f32, y: f32, z: f32, gripper: f32) {
        self.tlm.tool = Some([x, y, z, gripper]);
    }
    /// Commanded throttle output 0–1 (test benches).
    pub fn throttle_out(&mut self, v: f32) {
        self.tlm.throttle = Some(v);
    }
    /// Rockets: highest altitude so far (m), time in the current phase (s), countdown left (s).
    pub fn rocket_state(&mut self, max_alt: f32, phase_time: f32, countdown: f32) {
        self.tlm.rocket = Some([max_alt, phase_time, countdown]);
    }
    /// Radar / safety scanner targets: (id, range m, bearing rad). Sent now.
    pub fn tracks(&mut self, t: &[(&str, f32, f32)]) {
        if !self.session || self.transport.low_bandwidth() {
            return;
        }
        self.tx.fill(0);
        let mut w = Buf::new(&mut self.tx);
        w.raw(r#"{"t":"tracks","d":["#);
        for (i, (id, r, b)) in t.iter().enumerate() {
            if i > 0 {
                w.raw(",");
            }
            w.raw("[");
            w.string(id);
            w.raw(",");
            w.numf(*r);
            w.raw(",");
            w.numf(*b);
            w.raw("]");
        }
        w.raw("]}");
        self.flush();
    }
    /// A line in the app's log: level "info", "warn" or "error".
    pub fn log(&mut self, level: &str, msg: &str) {
        if !self.session {
            return;
        }
        self.tx.fill(0);
        let mut w = Buf::new(&mut self.tx);
        w.raw(r#"{"t":"log","lvl":"#);
        w.string(level);
        w.raw(r#","msg":"#);
        w.string(msg);
        w.raw("}");
        self.flush();
    }

    /// Device-initiated mode change (reported to the app).
    pub fn set_mode(&mut self, m: Mode) {
        if m != self.mode {
            self.mode = m;
            self.state_dirty = true;
        }
    }
    pub fn set_armed(&mut self, a: bool) {
        if a != self.armed {
            self.armed = a;
            self.state_dirty = true;
        }
    }

    /// Next pending event.
    pub fn poll_event(&mut self) -> Option<Event> {
        if self.ev_len == 0 {
            return None;
        }
        let e = self.events[self.ev_head].take();
        self.ev_head = (self.ev_head + 1) % MAX_EVENTS;
        self.ev_len -= 1;
        e
    }

    fn push(&mut self, e: Event) {
        if self.ev_len == MAX_EVENTS {
            // Drop the oldest, except never drop a Stop.
            let _ = self.poll_event();
        }
        let i = (self.ev_head + self.ev_len) % MAX_EVENTS;
        self.events[i] = Some(e);
        self.ev_len += 1;
    }

    /// Run the protocol. Call every loop with a monotonic millisecond clock.
    pub fn update(&mut self, now_ms: u32) {
        for _ in 0..16 {
            let mut rx = [0u8; 2048];
            let Some(n) = self.transport.recv(&mut rx) else { break };
            self.rx[..n].copy_from_slice(&rx[..n]);
            self.handle(n, now_ms);
        }
        self.seq_tick(now_ms);
        self.check_failsafe(now_ms);
        if !self.session {
            if now_ms.wrapping_sub(self.t_announce) >= 1000 {
                self.t_announce = now_ms;
                self.write_announce();
                self.emit(How::Announce);
            }
            return;
        }
        let period = if self.transport.low_bandwidth() { 2000 } else { 500 };
        if self.state_dirty || now_ms.wrapping_sub(self.t_state) >= period {
            self.t_state = now_ms;
            self.state_dirty = false;
            self.write_state();
            self.flush();
        }
        let cap = self.transport.max_rate_hz();
        let hz = if cap > 0.0 && cap < self.rate_hz { cap } else { self.rate_hz };
        if now_ms.wrapping_sub(self.t_tlm) as f32 >= 1000.0 / hz {
            self.t_tlm = now_ms;
            if self.write_tlm(now_ms) {
                self.flush();
            }
        }
    }

    fn check_failsafe(&mut self, now: u32) {
        // A stored sequence is meant to survive a lost link.
        if !self.session || self.fs_active || self.kind == Kind::Rocket || self.sequence_running() {
            return;
        }
        if now.wrapping_sub(self.last_ctl) <= self.fs_timeout_ms {
            return;
        }
        self.fs_active = true;
        self.control = Control::default();
        self.state_dirty = true;
        // Keep telemetry flowing on a fallback link if there is one.
        self.transport.failover();
        self.push(Event::Control(self.control));
        self.push(Event::Failsafe);
        let m = match self.kind {
            Kind::Drone => Some(self.fs_mode),
            Kind::Bench => Some(Mode::Idle),
            _ if self.armed => Some(Mode::Hold),
            _ => None,
        };
        if let Some(m) = m
            && m != self.mode {
                self.mode = m;
                self.push(Event::Mode(m));
            }
    }

    // ------------------------------------------------------------ incoming
    fn handle(&mut self, n: usize, now: u32) {
        let mut copy = [0u8; 2048];
        copy[..n].copy_from_slice(&self.rx[..n]);
        let m = &copy[..n];
        let Some(t) = json::get(m, "t").and_then(json::as_str) else { return };
        let num = |k: &str| json::get(m, k).and_then(json::as_f64);
        match t {
            "discover" => {
                self.write_announce();
                self.emit(How::Reply);
                return;
            }
            "pair" => {
                let code = json::get(m, "code").and_then(json::as_str).unwrap_or("");
                let key = json::get(m, "key").and_then(json::as_str).unwrap_or("");
                if !self.pair_code().is_empty() && code.eq_ignore_ascii_case(self.pair_code()) && !key.is_empty() {
                    self.transport.adopt_peer();
                    let mut k = [0u8; 40];
                    for (i, b) in key.bytes().take(39).enumerate() {
                        k[i] = b;
                    }
                    self.key = k;
                    self.pair_code = [0; 12];
                    self.begin_obj("paired");
                    self.push(Event::Paired);
                    self.flush();
                }
                return;
            }
            "hello" => {
                self.transport.adopt_peer();
                let key = json::get(m, "key").and_then(json::as_str).unwrap_or("");
                if !self.key().is_empty() && key != self.key() {
                    let id = self.id_owned();
                    let mut w = Buf::new(&mut self.tx);
                    w.raw(r#"{"t":"hello","v":1,"id":"#);
                    w.string(id.as_str());
                    w.raw(r#","ok":false,"err":"key"}"#);
                    self.flush();
                    self.transport.drop_peer();
                    return;
                }
                self.session = true;
                self.last_ctl = now;
                self.fs_active = false;
                self.state_dirty = true;
                self.write_hello();
                self.flush();
                self.write_params();
                self.flush();
                if self.channels.iter().any(|c| c.is_some()) {
                    self.write_channels();
                    self.flush();
                }
                self.push(Event::Connected);
                return;
            }
            _ => {}
        }
        if !self.session {
            return;
        }
        // Telemetry-only links: nothing that moves the device. A STOP is
        // still worth having, however slowly it arrives.
        if !self.transport.accepts_control() && !matches!(t, "stop" | "ping" | "rate" | "bye") {
            return;
        }
        match t {
            "ctl" => {
                self.transport.control_seen();
                self.last_ctl = now;
                if self.fs_active {
                    self.fs_active = false;
                    self.state_dirty = true;
                }
                self.control = Control {
                    lx: num("lx").unwrap_or(0.0) as f32,
                    ly: num("ly").unwrap_or(0.0) as f32,
                    rx: num("rx").unwrap_or(0.0) as f32,
                    ry: num("ry").unwrap_or(0.0) as f32,
                    seq: num("s").unwrap_or(0.0) as u32,
                };
                if !self.estop {
                    self.push(Event::Control(self.control));
                }
            }
            "ping" => {
                let ts = json::get(m, "ts").unwrap_or(b"0");
                let mut w = Buf::new(&mut self.tx);
                w.raw(r#"{"t":"pong","ts":"#);
                w.raw(core::str::from_utf8(ts).unwrap_or("0"));
                w.raw("}");
                self.flush();
            }
            "seq" => self.seq_store(m),
            "seqrun" => self.seq_run(m),
            "seqctl" => self.seq_ctl(m),
            "stop" => {
                self.seq_stop("Stopped: emergency stop");
                if !self.estop {
                    self.estop = true;
                    self.armed = false;
                    self.control = Control::default();
                    self.state_dirty = true;
                    self.push(Event::Stop);
                    self.push(Event::Arm(false));
                }
            }
            "reset" => {
                if self.estop {
                    self.estop = false;
                    self.state_dirty = true;
                    self.push(Event::Reset);
                }
            }
            "arm" => {
                let v = json::get(m, "v").and_then(json::as_bool).unwrap_or(false);
                if !self.estop && v != self.armed {
                    self.armed = v;
                    self.state_dirty = true;
                    self.push(Event::Arm(v));
                }
            }
            "mode" => {
                if let Some(md) = json::get(m, "m").and_then(json::as_str).and_then(Mode::parse)
                    && !self.estop && md != self.mode {
                        self.mode = md;
                        self.state_dirty = true;
                        self.push(Event::Mode(md));
                    }
            }
            "jog" => {
                let mut j = [0f32; 6];
                json::as_f32s(json::get(m, "j").unwrap_or(b"[]"), &mut j);
                if !self.estop {
                    self.push(Event::Jog(j));
                }
            }
            "cart" => {
                let mut v = [0f32; 3];
                json::as_f32s(json::get(m, "v").unwrap_or(b"[]"), &mut v);
                if !self.estop {
                    self.push(Event::Cartesian(v));
                }
            }
            "cmd" => {
                let c = json::get(m, "c").and_then(json::as_str).unwrap_or("");
                let a = json::get(m, "a").unwrap_or(b"{}");
                let mut args = CommandArgs { buf: [0; 160], len: 0 };
                if a.len() <= 160 {
                    args.buf[..a.len()].copy_from_slice(a);
                    args.len = a.len() as u8;
                }
                if !self.estop || matches!(c, "abort" | "clear" | "reset") {
                    let mut name = CommandName { buf: [0; 16], len: 0 };
                    let b = c.as_bytes();
                    let n = b.len().min(16);
                    name.buf[..n].copy_from_slice(&b[..n]);
                    name.len = n as u8;
                    self.push(Event::Command(name, args));
                }
            }
            "pset" => {
                let p = json::get(m, "p").unwrap_or(b"{}");
                let mut changed = [false; MAX_PARAMS];
                for (k, v) in json::Fields::new(p) {
                    let Some(x) = json::as_f64(v) else { continue };
                    for (i, slot) in self.params.iter_mut().enumerate() {
                        if let Some(prm) = slot
                            && prm.key == k {
                                let x = (x as f32).clamp(prm.min, prm.max);
                                prm.value = x;
                                changed[i] = true;
                            }
                    }
                }
                let mut w = Buf::new(&mut self.tx);
                w.raw(r#"{"t":"pack","ok":true,"keys":["#);
                let mut first = true;
                for (i, c) in changed.iter().enumerate() {
                    if *c {
                        if !first {
                            w.raw(",");
                        }
                        first = false;
                        w.string(self.params[i].map(|p| p.key).unwrap_or(""));
                    }
                }
                w.raw("]}");
                self.flush();
                let mut any = false;
                for (i, c) in changed.iter().enumerate() {
                    if *c {
                        any = true;
                        let v = self.param_value(i);
                        self.push(Event::Param(i, v));
                    }
                }
                if any {
                    self.push(Event::ParamsWritten);
                }
            }
            "psave" => self.push(Event::SaveParams),
            "rate" => self.rate_hz = (num("hz").unwrap_or(30.0) as f32).clamp(1.0, 60.0),
            "speed" => self.speed = (num("v").unwrap_or(0.5) as f32).clamp(0.1, 1.0),
            "fs" => {
                if let Some(md) = json::get(m, "action").and_then(json::as_str).and_then(Mode::parse) {
                    self.fs_mode = md;
                }
                if let Some(ms) = num("ms") {
                    self.fs_timeout_ms = ms as u32;
                }
            }
            "bye" => {
                self.session = false;
                self.control = Control::default();
                // A stored sequence carries on; otherwise a flying drone holds.
                if self.kind == Kind::Drone && self.armed && self.mode != Mode::Hold && !self.sequence_running() {
                    self.mode = Mode::Hold;
                    self.push(Event::Mode(Mode::Hold));
                }
                self.transport.drop_peer();
            }
            _ => {}
        }
    }

    // ------------------------------------------------------------ outgoing
    fn id_owned(&self) -> IdStr {
        IdStr { b: self.id, n: self.id_len }
    }

    /// Sends the message in `tx` (NUL-terminated) to the peer and clears it.
    fn flush(&mut self) {
        self.emit(How::Send);
    }

    fn emit(&mut self, how: How) {
        let n = self.tx.iter().position(|&b| b == 0).unwrap_or(self.tx.len());
        // n == len means the writer overflowed: drop rather than send truncated JSON.
        if n > 0 && n < self.tx.len() {
            let msg = &self.tx[..n];
            match how {
                How::Send => self.transport.send(msg),
                How::Reply => self.transport.reply(msg),
                How::Announce => self.transport.announce(msg),
            }
        }
        self.tx.fill(0);
    }

    fn begin_obj(&mut self, t: &str) {
        self.tx.fill(0);
        let id = self.id_owned();
        let mut w = Buf::new(&mut self.tx);
        w.raw(r#"{"t":"#);
        w.string(t);
        w.raw(r#","id":"#);
        w.string(id.as_str());
        w.raw("}");
    }

    fn write_announce(&mut self) {
        self.tx.fill(0);
        let (id, pc) = (self.id_owned(), PairStr { b: self.pair_code });
        let mut w = Buf::new(&mut self.tx);
        w.raw(r#"{"t":"announce","v":1,"id":"#);
        w.string(id.as_str());
        w.raw(r#","name":"#);
        w.string(self.name);
        w.raw(r#","kind":"#);
        w.string(self.kind.as_str());
        w.raw(r#","lib":"#);
        w.string(self.lib);
        if !pc.as_str().is_empty() {
            w.raw(r#","pair":"#);
            w.string(pc.as_str());
        }
        w.raw("}");
    }

    fn write_hello(&mut self) {
        self.tx.fill(0);
        let id = self.id_owned();
        let mut w = Buf::new(&mut self.tx);
        w.raw(r#"{"t":"hello","v":1,"id":"#);
        w.string(id.as_str());
        w.raw(r#","name":"#);
        w.string(self.name);
        w.raw(r#","kind":"#);
        w.string(self.kind.as_str());
        w.raw(r#","model":"#);
        w.string(self.model);
        w.raw(r#","fw":"#);
        w.string(self.fw);
        w.raw(r#","lib":"#);
        w.string(self.lib);
        w.raw(r#","sensors":["#);
        for (i, x) in self.sensors.iter().enumerate() {
            if i > 0 {
                w.raw(",");
            }
            w.string(x);
        }
        w.raw("]");
        if self.video.iter().any(|v| v.is_some()) {
            w.raw(r#","video":["#);
            for (i, v) in self.video.iter().flatten().enumerate() {
                if i > 0 {
                    w.raw(",");
                }
                w.raw(r#"{"id":"#);
                w.string(v.id);
                w.raw(r#","url":"#);
                w.string(v.url);
                w.raw(r#","fmt":"#);
                w.string(v.fmt);
                if !v.label.is_empty() {
                    w.raw(r#","label":"#);
                    w.string(v.label);
                }
                w.raw("}");
            }
            w.raw("]");
        }
        w.raw(r#","seq":"#);
        w.num(MAX_STEPS as f64);
        w.raw(r#","ok":true}"#);
    }

    fn write_params(&mut self) {
        self.tx.fill(0);
        let params = self.params;
        let mut w = Buf::new(&mut self.tx);
        w.raw(r#"{"t":"params","p":["#);
        let mut first = true;
        for p in params.iter().flatten() {
            if !first {
                w.raw(",");
            }
            first = false;
            w.raw("[");
            w.string(p.key);
            for x in [p.value, p.min, p.max, p.step] {
                w.raw(",");
                w.numf(x);
            }
            w.raw(",");
            w.string(p.unit);
            if !p.label.is_empty() {
                w.raw(",");
                w.string(p.label);
            }
            w.raw("]");
        }
        w.raw("]}");
    }

    fn write_channels(&mut self) {
        self.tx.fill(0);
        let chans = self.channels;
        let mut w = Buf::new(&mut self.tx);
        w.raw(r#"{"t":"chan","ch":["#);
        let mut first = true;
        for c in chans.iter().flatten() {
            if !first {
                w.raw(",");
            }
            first = false;
            w.raw(r#"{"id":"#);
            w.string(c.id);
            w.raw(r#","axes":["#);
            for (i, a) in c.axes[..c.n as usize].iter().enumerate() {
                if i > 0 {
                    w.raw(",");
                }
                w.string(a);
            }
            w.raw(r#"],"unit":"#);
            w.string(c.unit);
            w.raw(r#","hz":"#);
            w.numf(c.hz);
            w.raw("}");
        }
        w.raw("]}");
    }

    fn write_state(&mut self) {
        let mut tx = [0u8; 2048];
        let (mode, armed, estop, fs) = (self.mode, self.armed, self.estop, self.fs_active);
        let (pyro, cutoff, ext) = (self.pyro, self.cutoff, self.ext);
        let mut w = Buf::new(&mut tx);
        w.raw(r#"{"t":"state","mode":"#);
        w.string(mode.as_str());
        w.raw(if armed { r#","armed":true"# } else { r#","armed":false"# });
        w.raw(if estop { r#","estop":true"# } else { r#","estop":false"# });
        w.raw(if fs { r#","fs":true,"ext":{"# } else { r#","fs":false,"ext":{"# });
        let mut f = true;
        if let Some(p) = pyro {
            w.key(&mut f, "pyro");
            w.raw("[");
            for (i, x) in p.iter().enumerate() {
                if i > 0 {
                    w.raw(",");
                }
                w.string(x);
            }
            w.raw("]");
        }
        if let Some(c) = cutoff {
            w.key(&mut f, "cutoff");
            w.string(c);
        }
        for (k, v) in ext.iter().flatten() {
            w.key(&mut f, k);
            w.string(v);
        }
        self.write_run(&mut w, &mut f);
        w.raw("}}");
        self.tx = tx;
    }

    fn write_tlm(&mut self, now: u32) -> bool {
        let mut t = core::mem::take(&mut self.tlm);
        let cap = self.transport.max_rate_hz();
        let compact = cap > 0.0 && cap <= 2.0;
        if compact {
            // Slow radio: position, attitude, GPS, battery and rocket state only.
            t = Tlm { pos: t.pos, att: t.att, gps: t.gps, bat: t.bat, rocket: t.rocket, ..Tlm::default() };
        }
        let empty = t.imu.is_none()
            && t.att.is_none()
            && t.pos.is_none()
            && t.vel.is_none()
            && t.gps.is_none()
            && t.bat.is_none()
            && t.rssi.is_none()
            && t.joints.is_none()
            && t.ft.is_none()
            && t.thrust.is_none()
            && t.rpm.is_none()
            && t.temp.is_none()
            && t.tool.is_none()
            && t.throttle.is_none()
            && t.rocket.is_none();
        if empty && (compact || !self.channels.iter().flatten().any(|c| c.dirty)) {
            return false;
        }
        self.tx.fill(0);
        let mut w = Buf::new(&mut self.tx);
        w.raw(r#"{"t":"tlm","ts":"#);
        w.num(now as f64);
        w.raw(r#","d":{"#);
        let mut f = true;
        if let Some(v) = t.imu {
            w.key(&mut f, "imu");
            w.arr(&v);
        }
        if let Some(v) = t.att {
            w.key(&mut f, "att");
            w.arr(&v);
        }
        if let Some(v) = t.pos {
            w.key(&mut f, "pos");
            w.arr(&v);
        }
        if let Some(v) = t.vel {
            w.key(&mut f, "vel");
            w.arr(&v);
        }
        if let Some((la, lo, alt, s)) = t.gps {
            w.key(&mut f, "gps");
            w.raw("[");
            w.num(la);
            w.raw(",");
            w.num(lo);
            w.raw(",");
            w.numf(alt);
            w.raw(",");
            w.num(s as f64);
            w.raw("]");
        }
        if let Some(v) = t.bat {
            w.key(&mut f, "bat");
            w.arr(&v);
        }
        if let Some(v) = t.rssi {
            w.key(&mut f, "rssi");
            w.arr(&[v]);
        }
        if let Some((v, n)) = t.joints {
            w.key(&mut f, "joints");
            w.arr(&v[..n as usize]);
        }
        if let Some(v) = t.ft {
            w.key(&mut f, "ft");
            w.arr(&v);
        }
        if let Some(v) = t.thrust {
            w.key(&mut f, "thrust");
            w.arr(&v);
        }
        if let Some(v) = t.rpm {
            w.key(&mut f, "rpm");
            w.arr(&[v]);
        }
        if let Some(v) = t.temp {
            w.key(&mut f, "temp");
            w.arr(&[v]);
        }
        if let Some(v) = t.tool {
            w.key(&mut f, "tool");
            w.arr(&v);
        }
        if let Some(v) = t.throttle {
            w.key(&mut f, "throttle");
            w.arr(&[v]);
        }
        if let Some(v) = t.rocket {
            w.key(&mut f, "rocket");
            w.arr(&v);
        }
        for c in self.channels.iter_mut().flatten() {
            if c.dirty && !compact {
                c.dirty = false;
                w.key(&mut f, c.id);
                w.arr(&c.v[..c.n as usize]);
            }
        }
        w.raw("}}");
        w.as_bytes().is_some()
    }

    /// Sends a point cloud (metres), in `i16cm` chunks of 150 points.
    pub fn points(&mut self, pts: &[[f32; 3]]) {
        if !self.session || self.transport.low_bandwidth() {
            return;
        }
        for chunk in pts.chunks(150) {
            let mut raw = [0u8; 900];
            for (i, p) in chunk.iter().enumerate() {
                for k in 0..3 {
                    let cm = (p[k] * 100.0).clamp(-32768.0, 32767.0);
                    let v = (if cm >= 0.0 { cm + 0.5 } else { cm - 0.5 }) as i16;
                    raw[i * 6 + k * 2..i * 6 + k * 2 + 2].copy_from_slice(&v.to_le_bytes());
                }
            }
            self.tx.fill(0);
            let mut w = Buf::new(&mut self.tx);
            w.raw(r#"{"t":"pc","f":"i16cm","n":"#);
            w.num(chunk.len() as f64);
            w.raw(r#","d":""#);
            json::base64(&raw[..chunk.len() * 6], &mut w);
            w.raw(r#""}"#);
            self.flush();
        }
    }
}

enum How {
    Send,
    Reply,
    Announce,
}

struct IdStr {
    b: [u8; 32],
    n: usize,
}
impl IdStr {
    fn as_str(&self) -> &str {
        core::str::from_utf8(&self.b[..self.n]).unwrap_or("")
    }
}
struct PairStr {
    b: [u8; 12],
}
impl PairStr {
    fn as_str(&self) -> &str {
        let n = self.b.iter().position(|&x| x == 0).unwrap_or(0);
        core::str::from_utf8(&self.b[..n]).unwrap_or("")
    }
}

// no_std float helpers (core has no log10/pow on f32 without libm)
fn log10(x: f32) -> f32 {
    let mut n = 0.0;
    let mut v = x;
    if v <= 0.0 {
        return 0.0;
    }
    while v >= 10.0 {
        v /= 10.0;
        n += 1.0;
    }
    while v < 1.0 {
        v *= 10.0;
        n -= 1.0;
    }
    n
}
fn floor(x: f32) -> f32 {
    let i = x as i32 as f32;
    if i > x { i - 1.0 } else { i }
}
fn pow10(e: f32) -> f32 {
    let mut v = 1.0;
    let n = e as i32;
    for _ in 0..n.unsigned_abs() {
        v = if n >= 0 { v * 10.0 } else { v / 10.0 };
    }
    v
}
