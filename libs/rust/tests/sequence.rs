//! Sequences stored on and run by the device: the shared scenario in
//! protocol/vectors.json, link loss, refusal, pause / resume / stop.
use std::cell::RefCell;
use std::collections::VecDeque;
use std::rc::Rc;

use koebelt_link::json;
use koebelt_link::{Event, Kind, Link, Mode, Transport};

#[derive(Default)]
struct Wire {
    to_dev: VecDeque<Vec<u8>>,
    to_app: Vec<String>,
}

#[derive(Clone, Default)]
struct Mem(Rc<RefCell<Wire>>);

impl Transport for Mem {
    fn recv(&mut self, buf: &mut [u8]) -> Option<usize> {
        let m = self.0.borrow_mut().to_dev.pop_front()?;
        buf[..m.len()].copy_from_slice(&m);
        Some(m.len())
    }
    fn send(&mut self, msg: &[u8]) {
        let end = msg.iter().position(|&b| b == 0).unwrap_or(msg.len());
        self.0.borrow_mut().to_app.push(String::from_utf8_lossy(&msg[..end]).into_owned());
    }
}

impl Mem {
    fn app(&self, m: &str) {
        self.0.borrow_mut().to_dev.push_back(m.as_bytes().to_vec());
    }
    fn of(&self, t: &str) -> Vec<String> {
        let tag = format!(r#""t":"{t}""#);
        self.0.borrow().to_app.iter().filter(|m| m.contains(&tag)).cloned().collect()
    }
    fn last_run(&self) -> Option<String> {
        self.of("state").iter().rev().find_map(|s| {
            let ext = json::get(s.as_bytes(), "ext")?;
            json::get(ext, "run").map(|r| String::from_utf8_lossy(r).into_owned())
        })
    }
}

/// A drone whose events move it like a very fast vehicle; records the calls.
struct Drone {
    link: Link<Mem>,
    wire: Mem,
    pos: [f32; 3],
    now: u32,
    calls: Vec<(String, String, String)>,
}

impl Drone {
    fn new() -> Self {
        let wire = Mem::default();
        let link = Link::new("Seq-1", Kind::Drone, wire.clone());
        Drone { link, wire, pos: [0.0; 3], now: 0, calls: vec![] }
    }
    fn step(&mut self, ms: u32, ctl: bool) {
        for _ in 0..ms / 10 {
            if ctl {
                self.wire.app(r#"{"t":"ctl","s":0,"lx":0,"ly":0,"rx":0,"ry":0}"#);
            }
            self.link.position(self.pos);
            self.now += 10;
            self.link.update(self.now);
            while let Some(e) = self.link.poll_event() {
                match e {
                    Event::Arm(v) => self.calls.push(("arm".into(), String::new(), format!(r#"{{"v":{v}}}"#))),
                    Event::Mode(m) => {
                        self.calls.push(("mode".into(), m.as_str().into(), "{}".into()));
                        if m == Mode::Land {
                            self.pos[2] = 0.0;
                            self.link.set_armed(false);
                        }
                    }
                    Event::Command(n, a) => {
                        self.calls.push(("cmd".into(), n.as_str().into(), format!("{a:?}")));
                        match n.as_str() {
                            "takeoff" => {
                                self.pos[2] = a.get("alt").unwrap();
                                self.link.set_mode(Mode::Hold);
                            }
                            "goto" => self.pos = [a.get("x").unwrap(), a.get("y").unwrap(), a.get("z").unwrap_or(self.pos[2])],
                            _ => {}
                        }
                    }
                    _ => {}
                }
            }
        }
    }
}

fn vectors() -> String {
    std::fs::read_to_string(concat!(env!("CARGO_MANIFEST_DIR"), "/../../protocol/vectors.json")).unwrap()
}

/// A JSON string value, unescaped (the vectors only escape quotes).
fn unquote(v: &[u8]) -> String {
    let s = std::str::from_utf8(v).unwrap();
    s[1..s.len() - 1].replace(r#"\""#, "\"")
}

#[test]
fn hello_advertises_stored_sequences() {
    let mut d = Drone::new();
    d.wire.app(r#"{"t":"hello","v":1}"#);
    d.step(20, true);
    let h = &d.wire.of("hello")[0];
    assert_eq!(json::get(h.as_bytes(), "seq").and_then(json::as_f64), Some(koebelt_link::MAX_STEPS as f64));
}

#[test]
fn shared_scenario_runs_through_a_lost_link() {
    let v = vectors();
    let sq = json::get(v.as_bytes(), "sequence").unwrap();
    let mut d = Drone::new();
    d.wire.app(r#"{"t":"hello","v":1}"#);
    d.step(50, true);
    d.wire.app(&unquote(json::get(sq, "upload").unwrap()));
    d.step(20, true);
    assert_eq!(d.wire.of("seqack").last().unwrap(), r#"{"t":"seqack","id":"q1","ok":true}"#);
    d.wire.app(&unquote(json::get(sq, "run").unwrap()));
    // No control heartbeat from here on: the failsafe would switch to HOLD
    // after 1.8 s. The stored sequence must not be interrupted.
    d.step(3000, false);
    let run = d.wire.last_run().unwrap();
    assert_eq!(json::get(run.as_bytes(), "st").and_then(json::as_str), Some("done"), "{run}");
    let steps = json::get(sq, "steps").and_then(json::as_f64).unwrap();
    assert_eq!(json::get(run.as_bytes(), "i").and_then(json::as_f64), Some(steps));
    assert_eq!(d.link.speed_limit(), 0.5);
    let want: Vec<_> = json::Items::new(json::get(sq, "calls").unwrap())
        .filter_map(|c| {
            let mut it = json::Items::new(c);
            let kind = json::as_str(it.next()?)?.to_string();
            let name = json::as_str(it.next()?)?.to_string();
            let args = it.next().unwrap_or(b"{}");
            (kind != "speed").then_some((kind, name, args.to_vec()))
        })
        .collect();
    // Only once the sequence is over does the lost link trip the failsafe.
    assert!(d.calls.len() >= want.len(), "{:?}", d.calls);
    for ((k, n, a), (wk, wn, wa)) in d.calls.iter().zip(&want) {
        assert_eq!((k, n), (wk, wn), "{:?}", d.calls);
        for (key, val) in json::Fields::new(wa) {
            assert_eq!(json::get(a.as_bytes(), key), Some(val), "{k} {n} {a}");
        }
    }
}

#[test]
fn refuses_steps_it_cannot_run() {
    let v = vectors();
    let sq = json::get(v.as_bytes(), "sequence").unwrap();
    let mut d = Drone::new();
    d.wire.app(r#"{"t":"hello","v":1}"#);
    d.wire.app(&unquote(json::get(sq, "reject").unwrap()));
    d.step(30, true);
    let ack = d.wire.of("seqack").pop().unwrap();
    assert_eq!(json::get(ack.as_bytes(), "ok").and_then(json::as_bool), Some(false));
    assert!(ack.contains("fly_upside_down"), "{ack}");
}

#[test]
fn pause_resume_stop_and_estop() {
    let mut d = Drone::new();
    d.wire.app(r#"{"t":"hello","v":1}"#);
    d.wire.app(r#"{"t":"seq","id":"w","steps":[["wait",{"s":30}]]}"#);
    d.wire.app(r#"{"t":"seqrun","id":"w"}"#);
    d.step(700, true);
    let st = |d: &Drone, k: &str| d.wire.last_run().and_then(|r| json::get(r.as_bytes(), k).map(|v| String::from_utf8_lossy(v).into_owned()));
    assert_eq!(st(&d, "st").as_deref(), Some(r#""run""#));
    let p: f64 = st(&d, "p").unwrap().parse().unwrap();
    assert!(p > 0.0 && p < 1.0);
    d.wire.app(r#"{"t":"seqctl","c":"pause"}"#);
    d.step(50, true);
    assert_eq!(st(&d, "st").as_deref(), Some(r#""pause""#));
    d.wire.app(r#"{"t":"seqctl","c":"resume"}"#);
    d.step(50, true);
    assert_eq!(st(&d, "st").as_deref(), Some(r#""run""#));
    d.wire.app(r#"{"t":"stop"}"#);
    d.step(50, true);
    assert_eq!(st(&d, "st").as_deref(), Some(r#""fail""#));
    assert!(st(&d, "msg").unwrap().contains("emergency"));
}

#[test]
fn planes_fly_their_steps_and_boats_do_not_take_off() {
    assert!(Kind::Plane.flies() && Kind::Boat.drives() && !Kind::Boat.flies());
    assert_eq!((Kind::Plane.as_str(), Kind::Boat.as_str()), ("plane", "boat"));
    // A plane passes its waypoints; a boat drifts.
    assert!(Kind::Plane.arrival() > Kind::Boat.arrival() && Kind::Boat.arrival() > Kind::Rover.arrival());
    for (kind, ok) in [(Kind::Plane, true), (Kind::Boat, false)] {
        let wire = Mem::default();
        let mut link = Link::new("K-1", kind, wire.clone());
        wire.app(r#"{"t":"hello","v":1}"#);
        wire.app(r#"{"t":"seq","id":"t","steps":[["takeoff",{"alt":30}],["land",{}]]}"#);
        for i in 1..30 {
            link.update(i * 10);
            while link.poll_event().is_some() {}
        }
        let ack = wire.of("seqack").pop().unwrap();
        assert_eq!(json::get(ack.as_bytes(), "ok").and_then(json::as_bool), Some(ok), "{}: {ack}", kind.as_str());
    }
}

#[test]
fn legged_robots_walk_their_steps_and_hello_carries_the_body() {
    assert!(Kind::Legged.on_ground() && !Kind::Legged.flies() && Kind::Legged.as_str() == "legged");
    assert_eq!(Kind::Legged.bodies()[0], "quadruped");
    let wire = Mem::default();
    let mut link = Link::new("Scout", Kind::Legged, wire.clone());
    link.set_body("hexapod");
    wire.app(r#"{"t":"hello","v":1}"#);
    wire.app(r#"{"t":"seq","id":"t","steps":[["goto",{"x":3,"y":1}],["takeoff",{"alt":2}]]}"#);
    for i in 1..30 {
        link.update(i * 10);
        while link.poll_event().is_some() {}
    }
    let hello = wire.of("hello").pop().unwrap();
    assert!(hello.contains(r#""kind":"legged""#) && hello.contains(r#""body":"hexapod""#), "{hello}");
    let ack = wire.of("seqack").pop().unwrap();
    assert!(ack.contains("takeoff"), "a legged robot does not take off: {ack}");
}
