use std::net::UdpSocket;
use std::sync::{Arc, Mutex};
use std::time::Duration;

use koebelt_link::{Device, Kind, Mode, json};

struct App {
    sock: UdpSocket,
    port: u16,
    got: Vec<String>,
}

impl App {
    fn new(port: u16) -> Self {
        let sock = UdpSocket::bind("127.0.0.1:0").unwrap();
        sock.set_nonblocking(true).unwrap();
        Self { sock, port, got: vec![] }
    }
    fn send(&self, m: &str) {
        self.sock.send_to(m.as_bytes(), ("127.0.0.1", self.port)).unwrap();
    }
    fn pump(&mut self, dev: &mut Device, ms: u64, ctl: bool) {
        for _ in 0..ms / 5 {
            if ctl {
                self.send(r#"{"t":"ctl","s":1,"lx":0,"ly":0,"rx":0,"ry":0}"#);
            }
            dev.tick_blocking(200.0);
            let mut b = [0u8; 4096];
            while let Ok((n, _)) = self.sock.recv_from(&mut b) {
                self.got.push(String::from_utf8_lossy(&b[..n]).into_owned());
            }
        }
    }
    fn of(&self, t: &str) -> Vec<&String> {
        self.got.iter().filter(|m| json::get(m.as_bytes(), "t").and_then(json::as_str) == Some(t)).collect()
    }
}

fn device(name: &'static str, kind: Kind) -> (Device, App) {
    let dir = std::env::temp_dir().join(format!("kl-test-{}-{}", name, std::process::id()));
    let _ = std::fs::remove_dir_all(&dir);
    let dev = Device::new(name, kind).port(0).state_dir(dir).start().unwrap();
    let app = App::new(dev.local_port());
    (dev, app)
}

#[test]
fn handshake_control_stop_failsafe() {
    let (mut dev, mut app) = device("Kite-04", Kind::Drone);
    let stops = Arc::new(Mutex::new(0));
    let s2 = stops.clone();
    dev.on_stop(move || *s2.lock().unwrap() += 1);
    dev.failsafe(Duration::from_millis(200), Mode::Rth);
    dev.link.param("RATE_RLL_P", 0.135, 0.0, 0.5, "");

    app.send(r#"{"t":"hello","v":1}"#);
    dev.imu([0.0, 0.0, 9.81], [0.0, 0.0, 0.1]).unwrap();
    app.pump(&mut dev, 60, true);
    let hello = app.of("hello");
    assert!(hello[0].contains(r#""id":"kite-04""#) && hello[0].contains(r#""ok":true"#), "{hello:?}");
    assert!(app.of("params")[0].contains(r#"["RATE_RLL_P",0.135"#));
    assert!(app.of("tlm").iter().any(|m| m.contains(r#""imu":[0,0,9.81,0,0,0.1]"#)), "{:?}", app.of("tlm"));

    app.send(r#"{"t":"arm","v":true}"#);
    app.send(r#"{"t":"mode","m":"MANUAL"}"#);
    app.send(r#"{"t":"ctl","s":9,"lx":0.5,"ly":0,"rx":0,"ry":-1}"#);
    // Datagrams can land a moment later; tick until the stick input shows up.
    let mut c = Default::default();
    for _ in 0..50 {
        dev.tick_blocking(1000.0);
        if let Some(x) = dev.poll_control() {
            c = x;
            if x.lx != 0.0 {
                break;
            }
        }
    }
    let c: koebelt_link::Control = c;
    assert_eq!((c.lx, c.ry), (0.5, -1.0));
    assert!(dev.link.armed() && dev.link.mode() == Mode::Manual);

    app.pump(&mut dev, 400, false);
    assert!(dev.link.failsafe_active() && dev.link.mode() == Mode::Rth);
    app.pump(&mut dev, 30, true);
    assert!(!dev.link.failsafe_active());

    for _ in 0..3 {
        app.send(r#"{"t":"stop"}"#);
    }
    app.pump(&mut dev, 30, true);
    assert!(dev.link.stopped() && !dev.link.armed());
    assert_eq!(*stops.lock().unwrap(), 1);
    assert!(app.of("state").last().unwrap().contains(r#""estop":true"#));

    app.send(r#"{"t":"ping","ts":12345}"#);
    app.pump(&mut dev, 20, true);
    assert!(app.of("pong")[0].contains("12345"));
}

#[test]
fn pairing_and_key_persistence() {
    let dir = std::env::temp_dir().join(format!("kl-pair-{}", std::process::id()));
    let _ = std::fs::remove_dir_all(&dir);
    let mut dev = Device::new("Kite-05", Kind::Drone).port(0).state_dir(&dir).start().unwrap();
    let mut app = App::new(dev.local_port());
    dev.pair("4f7-k2q").unwrap();
    app.send(r#"{"t":"discover"}"#);
    app.pump(&mut dev, 20, false);
    assert!(app.of("announce")[0].contains(r#""pair":"4F7-K2Q""#));
    app.send(r#"{"t":"pair","code":"4F7-K2Q","key":"00112233445566778899aabbccddeeff"}"#);
    app.pump(&mut dev, 20, false);
    assert_eq!(app.of("paired").len(), 1);
    app.send(r#"{"t":"hello","key":"nope"}"#);
    app.pump(&mut dev, 20, false);
    assert!(app.of("hello").last().unwrap().contains(r#""ok":false"#));
    drop(dev);
    let again = Device::new("Kite-05", Kind::Drone).port(0).state_dir(&dir).start().unwrap();
    assert_eq!(again.link.key(), "00112233445566778899aabbccddeeff");
}

#[test]
fn point_cloud_matches_shared_vector() {
    let (mut dev, mut app) = device("Scan", Kind::Rover);
    app.send(r#"{"t":"hello"}"#);
    app.pump(&mut dev, 20, true);
    dev.link.points(&[[1.0, 0.0, 0.0], [-0.02, 0.01, 5.0]]);
    app.pump(&mut dev, 10, true);
    // protocol/vectors.json "point cloud i16cm"
    assert!(app.of("pc")[0].contains(r#""d":"ZAAAAAAA/v8BAPQB""#), "{:?}", app.of("pc"));
}

#[test]
fn params_write() {
    let (mut dev, mut app) = device("Bench", Kind::Bench);
    let i = dev.link.param("MAX_CURRENT", 45.0, 5.0, 120.0, "A");
    app.send(r#"{"t":"hello"}"#);
    app.send(r#"{"t":"pset","p":{"MAX_CURRENT":500,"NOPE":1}}"#);
    app.pump(&mut dev, 20, true);
    assert_eq!(dev.link.param_value(i), 120.0);
    assert!(app.of("pack")[0].contains(r#""keys":["MAX_CURRENT"]"#));
}

#[test]
fn custom_channels_and_commands() {
    let (mut dev, mut app) = device("Rig", Kind::Generic);
    let temp = dev.channel("motor_temp", &["M1", "M2"], "C", 10.0);
    let got = Arc::new(Mutex::new(Vec::new()));
    let g2 = got.clone();
    dev.on_command(move |name, a| g2.lock().unwrap().push((name.to_string(), a.value(), a.get("y"))));
    app.send(r#"{"t":"hello"}"#);
    app.pump(&mut dev, 30, true);
    assert!(app.of("chan")[0].contains(r#"{"id":"motor_temp","axes":["M1","M2"],"unit":"C","hz":10}"#), "{:?}", app.of("chan"));
    dev.publish(temp, &[40.5, 41.0]).unwrap();
    app.pump(&mut dev, 60, true);
    assert!(app.of("tlm").iter().any(|m| m.contains(r#""motor_temp":[40.5,41]"#)), "{:?}", app.of("tlm"));
    app.send(r#"{"t":"cmd","c":"goto","a":{"x":15,"y":-2.5,"z":10}}"#);
    app.pump(&mut dev, 30, true);
    assert_eq!(got.lock().unwrap().as_slice(), &[("goto".to_string(), None, Some(-2.5))]);
}
