//! Sequences stored on and run by the device (protocol/PROTOCOL.md,
//! "Sequences"). The app uploads the steps with `seq`; the device runs them
//! through the same events the app's messages produce and checks completion
//! against its own telemetry, so a sequence keeps going when the link drops.

use super::*;

/// The most steps a device stores (advertised in `hello` as `seq`).
pub const MAX_STEPS: usize = 32;

#[derive(Clone, Copy)]
pub(super) enum Step {
    Takeoff(f32),
    Goto([f32; 3]),
    Land,
    Rth,
    Pose([f32; 6]),
    Home,
    Gripper(f32),
    Throttle(f32, f32),
    Ramp(f32, f32, f32),
    Wait(f32),
    Mode(Mode),
    Arm(bool),
    Speed(f32),
    /// Custom command and its `v`, the value the app's command step carries.
    Cmd(CommandName, Option<f32>),
}

#[derive(Clone, Copy, PartialEq, Debug)]
pub(super) enum RunSt {
    Run,
    Pause,
    Done,
    Fail,
}

impl RunSt {
    fn as_str(self) -> &'static str {
        match self {
            RunSt::Run => "run",
            RunSt::Pause => "pause",
            RunSt::Done => "done",
            RunSt::Fail => "fail",
        }
    }
}

pub(super) struct Stored {
    pub(super) id: [u8; 24],
    pub(super) id_len: u8,
    pub(super) steps: [Option<Step>; MAX_STEPS],
    pub(super) n: u8,
}

/// The run of the stored sequence (uploads are refused while it is active,
/// so it reads the steps in place).
pub(super) struct Run {
    pub(super) st: RunSt,
    pub(super) i: u8,
    step_t: f32,
    total_t: f32,
    entered: bool,
    last_thr: f32,
    send_acc: f32,
    still: f32,
    last_j: [f32; 6],
    msg: [u8; 40],
    msg_len: u8,
    pub(super) reported: Option<(RunSt, u8)>,
}

fn name(s: &str) -> CommandName {
    let mut n = CommandName { buf: [0; 16], len: 0 };
    let b = s.as_bytes();
    let l = b.len().min(16);
    n.buf[..l].copy_from_slice(&b[..l]);
    n.len = l as u8;
    n
}

/// Arguments written as JSON, e.g. `{"alt":3}`.
fn args(f: impl FnOnce(&mut json::Buf<'_>)) -> CommandArgs {
    let mut a = CommandArgs { buf: [0; 160], len: 0 };
    let mut w = json::Buf::new(&mut a.buf);
    f(&mut w);
    let n = w.as_bytes().map(|b| b.len()).unwrap_or(0);
    a.len = n as u8;
    a
}

/// Parses one `[type, args]` step; `Err` names the type it refuses.
pub(super) fn parse(kind: Kind, w: &[u8]) -> Result<Step, &[u8]> {
    let mut it = json::Items::new(w);
    let t = it.next().unwrap_or(b"");
    let a = it.next().unwrap_or(b"{}");
    let ty = json::as_str(t).unwrap_or("");
    let num = |k: &str| json::get(a, k).and_then(json::as_f64).map(|v| v as f32);
    let (drone, rover, arm, bench) = (kind == Kind::Drone, kind == Kind::Rover, kind == Kind::Arm, kind == Kind::Bench);
    let moving = !bench && kind != Kind::Rocket;
    Ok(match ty {
        "takeoff" if drone => Step::Takeoff(num("alt").unwrap_or(6.0)),
        "goto" if drone || rover => Step::Goto([num("x").unwrap_or(0.0), num("y").unwrap_or(0.0), num("z").unwrap_or(8.0)]),
        "land" if drone => Step::Land,
        "rth" if drone => Step::Rth,
        "pose" if arm => {
            let mut j = [0f32; 6];
            json::as_f32s(json::get(a, "j").unwrap_or(b"[]"), &mut j);
            Step::Pose(j)
        }
        "home" if arm => Step::Home,
        "gripper" if arm => Step::Gripper(num("v").unwrap_or(0.9)),
        "throttle" if bench => Step::Throttle(num("v").unwrap_or(0.0), num("s").unwrap_or(0.0)),
        "ramp" if bench => Step::Ramp(num("from").unwrap_or(0.0), num("to").unwrap_or(0.0), num("s").unwrap_or(0.0)),
        "wait" => Step::Wait(num("s").unwrap_or(0.0)),
        "mode" if moving => match json::get(a, "m").and_then(json::as_str).and_then(Mode::parse) {
            Some(m) => Step::Mode(m),
            None => return Err(t),
        },
        "arm" => Step::Arm(json::get(a, "v").and_then(json::as_bool).unwrap_or(false)),
        "speed" if moving => Step::Speed(num("v").unwrap_or(0.5)),
        "cmd" => {
            let v = json::get(a, "a").and_then(|x| json::get(x, "v")).and_then(json::as_f64).map(|v| v as f32);
            Step::Cmd(name(json::get(a, "c").and_then(json::as_str).unwrap_or("")), v)
        }
        _ => return Err(t),
    })
}

impl Run {
    pub(super) fn new() -> Self {
        Run {
            st: RunSt::Run,
            i: 0,
            step_t: 0.0,
            total_t: 0.0,
            entered: false,
            last_thr: -1.0,
            send_acc: 0.0,
            still: 0.0,
            last_j: [0.0; 6],
            msg: [0; 40],
            msg_len: 0,
            reported: None,
        }
    }
    pub(super) fn active(&self) -> bool {
        matches!(self.st, RunSt::Run | RunSt::Pause)
    }
    fn set_msg(&mut self, f: impl FnOnce(&mut json::Buf<'_>)) {
        let mut m = [0u8; 40];
        let mut w = json::Buf::new(&mut m);
        f(&mut w);
        self.msg_len = w.as_bytes().map(|b| b.len()).unwrap_or(0) as u8;
        self.msg = m;
    }
    fn msg(&self) -> &str {
        core::str::from_utf8(&self.msg[..self.msg_len as usize]).unwrap_or("")
    }
    fn progress(&self, steps: &[Option<Step>]) -> Option<f32> {
        let d = match steps.get(self.i as usize).copied().flatten()? {
            Step::Wait(s) | Step::Throttle(_, s) | Step::Ramp(_, _, s) => s,
            Step::Gripper(_) => 0.8,
            _ => return None,
        };
        (d > 0.0).then(|| (self.step_t / d).clamp(0.0, 1.0))
    }
}

impl<T: Transport> Link<T> {
    /// True while a stored sequence runs (or is paused).
    pub fn sequence_running(&self) -> bool {
        self.run.as_ref().is_some_and(|r| r.active())
    }

    pub(super) fn seq_store(&mut self, m: &[u8]) {
        let id = json::get(m, "id").and_then(json::as_str).unwrap_or("");
        let mut st = Stored { id: [0; 24], id_len: 0, steps: [None; MAX_STEPS], n: 0 };
        let l = id.len().min(24);
        st.id[..l].copy_from_slice(&id.as_bytes()[..l]);
        st.id_len = l as u8;
        let mut err: Option<&str> = if self.sequence_running() { Some("running") } else { None };
        let mut bad = [0u8; 24];
        let mut bad_len = 0;
        for w in json::Items::new(json::get(m, "steps").unwrap_or(b"[]")) {
            if err.is_some() {
                break;
            }
            if st.n as usize >= MAX_STEPS {
                err = Some("too many");
                break;
            }
            match parse(self.kind, w) {
                Ok(s) => {
                    st.steps[st.n as usize] = Some(s);
                    st.n += 1;
                }
                Err(t) => {
                    let t = json::as_str(t).unwrap_or("?");
                    bad_len = t.len().min(24);
                    bad[..bad_len].copy_from_slice(&t.as_bytes()[..bad_len]);
                    err = Some("step");
                    break;
                }
            }
        }
        if err.is_none() && st.n == 0 {
            err = Some("empty");
        }
        let mut w = json::Buf::new(&mut self.tx);
        w.raw(r#"{"t":"seqack","id":"#);
        w.string(id);
        match err {
            None => w.raw(r#","ok":true}"#),
            Some(e) => {
                w.raw(r#","ok":false,"err":"#);
                let mut eb = [0u8; 80];
                let mut ew = json::Buf::new(&mut eb);
                match e {
                    "too many" => {
                        let _ = core::fmt::Write::write_fmt(&mut ew, format_args!("Too many steps: this device stores {MAX_STEPS}"));
                    }
                    "empty" => ew.raw("No steps"),
                    "running" => ew.raw("A sequence is running"),
                    _ => {
                        let t = core::str::from_utf8(&bad[..bad_len]).unwrap_or("?");
                        let _ = core::fmt::Write::write_fmt(&mut ew, format_args!("Step \"{t}\" is not supported on this device"));
                    }
                }
                let n = ew.as_bytes().map(|b| b.len()).unwrap_or(0);
                w.string(core::str::from_utf8(&eb[..n]).unwrap_or(""));
                w.raw("}");
            }
        }
        if err.is_none() {
            self.stored = Some(st);
        }
        self.flush();
    }

    pub(super) fn seq_run(&mut self, m: &[u8]) {
        let id = json::get(m, "id").and_then(json::as_str).unwrap_or("");
        if self.estop {
            return;
        }
        if let Some(s) = &self.stored
            && core::str::from_utf8(&s.id[..s.id_len as usize]).unwrap_or("") == id
        {
            self.run = Some(Run::new());
            self.state_dirty = true;
        }
    }

    pub(super) fn seq_ctl(&mut self, m: &[u8]) {
        match json::get(m, "c").and_then(json::as_str) {
            Some("pause") => self.seq_pause(),
            Some("resume") => {
                if let Some(r) = &mut self.run
                    && r.st == RunSt::Pause
                {
                    r.st = RunSt::Run;
                    r.msg_len = 0;
                    r.entered = false; // re-issue the current step
                    r.step_t = 0.0;
                }
            }
            Some("stop") => self.seq_stop("Stopped from the app"),
            _ => {}
        }
        self.state_dirty = true;
    }

    fn seq_pause(&mut self) {
        let Some(r) = &mut self.run else { return };
        if r.st != RunSt::Run {
            return;
        }
        r.st = RunSt::Pause;
        r.set_msg(|w| w.raw("Paused"));
        let cur = self.stored.as_ref().and_then(|s| s.steps.get(r.i as usize).copied().flatten());
        match cur {
            Some(Step::Throttle(..) | Step::Ramp(..)) => self.seq_cmd("throttle", args(|w| w.raw(r#"{"v":0}"#))),
            _ if matches!(self.kind, Kind::Drone | Kind::Rover) && self.armed => self.seq_mode(Mode::Hold),
            _ => {}
        }
    }

    pub(super) fn seq_stop(&mut self, why: &str) {
        let Some(r) = &mut self.run else { return };
        if !r.active() {
            return;
        }
        r.st = RunSt::Fail;
        r.set_msg(|w| w.raw(why));
        self.state_dirty = true;
        if self.kind == Kind::Bench {
            self.seq_cmd("throttle", args(|w| w.raw(r#"{"v":0}"#)));
        }
        if matches!(self.kind, Kind::Drone | Kind::Rover) && self.armed && !self.estop {
            self.seq_mode(Mode::Hold);
        }
    }

    // The same events the app's messages produce.
    fn seq_cmd(&mut self, c: &str, a: CommandArgs) {
        if !self.estop {
            self.push(Event::Command(name(c), a));
        }
    }
    fn seq_mode(&mut self, m: Mode) {
        if !self.estop && m != self.mode {
            self.mode = m;
            self.state_dirty = true;
            self.push(Event::Mode(m));
        }
    }
    fn seq_arm(&mut self, v: bool) {
        if !self.estop && v != self.armed {
            self.armed = v;
            self.state_dirty = true;
            self.push(Event::Arm(v));
        }
    }

    /// Advances the stored sequence; called from `update`.
    pub(super) fn seq_tick(&mut self, now: u32) {
        let dt = now.wrapping_sub(self.t_seq) as f32 / 1000.0;
        self.t_seq = now;
        let Some(mut r) = self.run.take() else { return };
        if r.st == RunSt::Run {
            if self.estop {
                self.run = Some(r);
                self.seq_stop("Stopped: emergency stop");
                return;
            }
            self.seq_step(&mut r, dt.min(1.0));
        }
        let rep = (r.st, r.i);
        if r.reported != Some(rep) {
            r.reported = Some(rep);
            self.state_dirty = true;
        }
        self.run = Some(r);
    }

    fn seq_step(&mut self, r: &mut Run, dt: f32) {
        let Some(step) = self.stored.as_ref().and_then(|s| s.steps.get(r.i as usize).copied().flatten()) else {
            r.st = RunSt::Done;
            let t = r.total_t;
            r.set_msg(|w| {
                let _ = core::fmt::Write::write_fmt(w, format_args!("Completed in {t:.1} s"));
            });
            return;
        };
        r.total_t += dt;
        if !r.entered {
            r.entered = true;
            r.step_t = 0.0;
            r.last_thr = -1.0;
            self.seq_enter(step);
        }
        r.step_t += dt;
        let t = r.step_t;
        let within = |limit: f32, ok: bool| if ok { Some(true) } else if t > limit { None } else { Some(false) };
        let p = self.last_pos;
        let res = match step {
            Step::Wait(s) | Step::Throttle(_, s) => Some(t >= s),
            Step::Takeoff(alt) => within(60.0, t > 0.3 && self.mode != Mode::Takeoff && p[2] > alt - 0.6),
            Step::Goto(g) => {
                let drone = self.kind == Kind::Drone;
                let (dx, dy, dz) = (p[0] - g[0], p[1] - g[1], if drone { p[2] - g[2] } else { 0.0 });
                let d = sqrt(dx * dx + dy * dy + dz * dz);
                r.set_msg(|w| {
                    let _ = core::fmt::Write::write_fmt(w, format_args!("{d:.1} m to go"));
                });
                within(300.0, d < if drone { 1.0 } else { 0.6 })
            }
            Step::Land | Step::Rth => within(300.0, t > 0.5 && (!self.armed || (p[2] < 0.1 && !matches!(self.mode, Mode::Land | Mode::Rth)))),
            Step::Pose(target) => {
                let n = (self.last_nj as usize).min(6);
                let err = (0..n).map(|i| (self.last_joints[i] - target[i]).abs()).fold(0.0, f32::max);
                within(60.0, t > 0.2 && err < 0.03)
            }
            Step::Home => {
                let n = (self.last_nj as usize).min(6);
                let moved = (0..n).map(|i| (self.last_joints[i] - r.last_j[i]).abs()).fold(0.0, f32::max);
                r.last_j = self.last_joints;
                r.still = if moved < 2e-4 { r.still + dt } else { 0.0 };
                within(60.0, t > 0.6 && r.still > 0.4)
            }
            Step::Gripper(_) => Some(t >= 0.8),
            Step::Ramp(from, to, s) => {
                let d = s.max(0.001);
                let k = (t / d).clamp(0.0, 1.0);
                let thr = from + (to - from) * k;
                r.send_acc += dt;
                if r.send_acc >= 0.1 && (thr - r.last_thr).abs() >= 0.005 {
                    r.send_acc = 0.0;
                    r.last_thr = thr;
                    self.seq_cmd("throttle", args(|w| {
                        w.raw(r#"{"v":"#);
                        w.numf(thr);
                        w.raw("}");
                    }));
                }
                Some(t >= d)
            }
            Step::Mode(m) => within(3.0, self.mode == m),
            Step::Arm(v) => within(3.0, self.armed == v),
            Step::Speed(_) | Step::Cmd(..) => Some(true),
        };
        match res {
            Some(true) => {
                r.i += 1;
                r.entered = false;
                r.msg_len = 0;
            }
            Some(false) => {}
            None => {
                let i = r.i + 1;
                r.st = RunSt::Fail;
                r.set_msg(|w| {
                    let _ = core::fmt::Write::write_fmt(w, format_args!("Step {i} timed out"));
                });
                if matches!(self.kind, Kind::Drone | Kind::Rover) && self.armed {
                    self.seq_mode(Mode::Hold);
                }
            }
        }
    }

    fn seq_enter(&mut self, s: Step) {
        match s {
            Step::Takeoff(alt) => self.seq_cmd("takeoff", args(|w| {
                w.raw(r#"{"alt":"#);
                w.numf(alt);
                w.raw("}");
            })),
            Step::Goto(g) => {
                let drone = self.kind == Kind::Drone;
                self.seq_cmd("goto", args(|w| {
                    w.raw(r#"{"x":"#);
                    w.numf(g[0]);
                    w.raw(r#","y":"#);
                    w.numf(g[1]);
                    if drone {
                        w.raw(r#","z":"#);
                        w.numf(g[2]);
                    }
                    w.raw("}");
                }));
            }
            Step::Land => self.seq_mode(Mode::Land),
            Step::Rth => self.seq_mode(Mode::Rth),
            Step::Pose(j) => self.seq_cmd("pose", args(|w| {
                w.raw(r#"{"j":"#);
                w.arr(&j);
                w.raw("}");
            })),
            Step::Home => self.seq_cmd("home", args(|w| w.raw("{}"))),
            Step::Gripper(v) | Step::Throttle(v, _) => {
                let c = if matches!(s, Step::Gripper(_)) { "gripper" } else { "throttle" };
                self.seq_cmd(c, args(|w| {
                    w.raw(r#"{"v":"#);
                    w.numf(v);
                    w.raw("}");
                }));
            }
            Step::Ramp(..) | Step::Wait(_) => {}
            Step::Mode(m) => self.seq_mode(m),
            Step::Arm(v) => self.seq_arm(v),
            Step::Speed(v) => self.speed = v.clamp(0.1, 1.0),
            Step::Cmd(n, v) => {
                if n.len > 0 {
                    self.seq_cmd(n.as_str(), args(|w| match v {
                        Some(v) => {
                            w.raw(r#"{"v":"#);
                            w.numf(v);
                            w.raw("}");
                        }
                        None => w.raw("{}"),
                    }))
                }
            }
        }
    }

    /// The `run` object of `state.ext`.
    pub(super) fn write_run(&self, w: &mut json::Buf<'_>, first: &mut bool) {
        let (Some(r), Some(s)) = (&self.run, &self.stored) else { return };
        w.key(first, "run");
        w.raw(r#"{"id":"#);
        w.string(core::str::from_utf8(&s.id[..s.id_len as usize]).unwrap_or(""));
        w.raw(r#","i":"#);
        w.num(r.i as f64);
        w.raw(r#","n":"#);
        w.num(s.n as f64);
        w.raw(r#","st":"#);
        w.string(r.st.as_str());
        if r.msg_len > 0 {
            w.raw(r#","msg":"#);
            w.string(r.msg());
        }
        if r.active()
            && let Some(p) = r.progress(&s.steps)
        {
            w.raw(r#","p":"#);
            w.numf(((p * 100.0 + 0.5) as i32) as f32 / 100.0);
        }
        w.raw("}");
    }
}

fn sqrt(x: f32) -> f32 {
    // no_std: Newton's method is plenty for distances.
    if x <= 0.0 {
        return 0.0;
    }
    let mut g = if x > 1.0 { x / 2.0 } else { 1.0 };
    for _ in 0..20 {
        g = 0.5 * (g + x / g);
    }
    g
}
