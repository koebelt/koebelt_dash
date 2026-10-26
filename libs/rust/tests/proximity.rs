//! Proximity sensors: declared in `hello`, reported in the `prox` channel.
use std::cell::RefCell;
use std::rc::Rc;

use koebelt_link::json;
use koebelt_link::{Kind, Link, MAX_PROX, Transport};

/// Messages to the device, and what it sent.
type Wire = (Vec<Vec<u8>>, Vec<String>);

#[derive(Clone, Default)]
struct Mem(Rc<RefCell<Wire>>);

impl Transport for Mem {
    fn recv(&mut self, buf: &mut [u8]) -> Option<usize> {
        let m = self.0.borrow_mut().0.pop()?;
        buf[..m.len()].copy_from_slice(&m);
        Some(m.len())
    }
    fn send(&mut self, msg: &[u8]) {
        let end = msg.iter().position(|&b| b == 0).unwrap_or(msg.len());
        self.0
            .borrow_mut()
            .1
            .push(String::from_utf8_lossy(&msg[..end]).into_owned());
    }
}

impl Mem {
    fn of(&self, t: &str) -> Vec<String> {
        let tag = format!(r#""t":"{t}""#);
        self.0
            .borrow()
            .1
            .iter()
            .filter(|m| m.contains(&tag))
            .cloned()
            .collect()
    }
}

fn prox_of(tlm: &str) -> Vec<f32> {
    let d = json::get(tlm.as_bytes(), "d").unwrap();
    let mut out = [0f32; 8];
    let n = json::as_f32s(json::get(d, "prox").unwrap(), &mut out);
    out[..n].to_vec()
}

#[test]
fn declared_in_hello_and_reported_in_telemetry() {
    let wire = Mem::default();
    let mut l = Link::new("Mule", Kind::Rover, wire.clone());
    let front = l
        .proximity("front", 4.0, 0.0, "ultrasonic", 0.26, 0.0, 0.02)
        .unwrap();
    let down = l
        .proximity("down", 8.0, 0.0, "tof", 0.05, -1.571, 0.0)
        .unwrap();
    wire.0
        .borrow_mut()
        .0
        .push(br#"{"t":"hello","v":1}"#.to_vec());
    let mut now = 0;
    let mut run = |l: &mut Link<Mem>, ms: u32| {
        for _ in 0..ms / 10 {
            now += 10;
            l.update(now);
        }
    };
    run(&mut l, 50);
    let h = &wire.of("hello")[0];
    assert!(h.contains(r#""prox":[{"id":"front","fov":0.26,"min":0.02,"max":4,"kind":"ultrasonic"},{"id":"down","tilt":-1.571,"fov":0.05,"max":8,"kind":"tof"}]"#), "{h}");

    l.set_proximity(front, Some(0.42));
    run(&mut l, 100);
    assert_eq!(prox_of(wire.of("tlm").last().unwrap()), vec![0.42, -1.0]);
    l.set_proximity(front, None);
    l.set_proximity(down, Some(1.2));
    run(&mut l, 100);
    assert_eq!(prox_of(wire.of("tlm").last().unwrap()), vec![-1.0, 1.2]);

    for _ in 2..MAX_PROX {
        assert!(l.proximity("x", 1.0, 0.0, "", 0.26, 0.0, 0.0).is_some());
    }
    assert!(
        l.proximity("one too many", 1.0, 0.0, "", 0.26, 0.0, 0.0)
            .is_none()
    );
}
