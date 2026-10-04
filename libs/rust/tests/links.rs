//! Radio and serial links, fallback, video and the fields every library sends.
#![cfg(unix)]
use std::io::{BufRead, BufReader, Read, Write};
use std::net::{TcpStream, UdpSocket};
use std::os::unix::net::UnixStream;
use std::sync::{Arc, Mutex};
use std::time::{Duration, Instant};

use koebelt_link::{Device, Kind, MjpegServer, Radio, StreamTransport, json};

fn dir(name: &str) -> std::path::PathBuf {
    let d = std::env::temp_dir().join(format!("kl-links-{}-{}", name, std::process::id()));
    let _ = std::fs::remove_dir_all(&d);
    d
}

/// The app's end of a serial or radio link.
struct LineApp {
    s: UnixStream,
    buf: Vec<u8>,
    got: Vec<String>,
}

impl LineApp {
    fn send(&mut self, m: &str) {
        self.s.write_all(m.as_bytes()).unwrap();
        self.s.write_all(b"\n").unwrap();
    }
    fn pump(&mut self, dev: &mut Device, ms: u64, ctl: bool) {
        let end = Instant::now() + Duration::from_millis(ms);
        while Instant::now() < end {
            if ctl {
                self.send(r#"{"t":"ctl","s":1,"lx":0.5,"ly":0,"rx":0,"ry":0}"#);
            }
            dev.tick_blocking(100.0);
            let mut b = [0u8; 4096];
            while let Ok(n) = self.s.read(&mut b) {
                if n == 0 {
                    break;
                }
                self.buf.extend_from_slice(&b[..n]);
            }
            while let Some(i) = self.buf.iter().position(|&c| c == b'\n') {
                let line: Vec<u8> = self.buf.drain(..=i).collect();
                self.got.push(String::from_utf8_lossy(&line[..i]).into_owned());
            }
        }
    }
    fn of(&self, t: &str) -> Vec<&String> {
        self.got.iter().filter(|m| json::get(m.as_bytes(), "t").and_then(json::as_str) == Some(t)).collect()
    }
}

fn radio_device(name: &'static str, kind: Kind, r: Radio) -> (Device, LineApp) {
    let (a, b) = UnixStream::pair().unwrap();
    b.set_nonblocking(true).unwrap();
    let t = StreamTransport::new(a.try_clone().unwrap(), a).radio(r);
    let dev = Device::new(name, kind).state_dir(dir(name)).transport(t).start().unwrap();
    (dev, LineApp { s: b, buf: vec![], got: vec![] })
}

#[test]
fn radio_profiles_match_shared_vectors() {
    let v = std::fs::read_to_string(concat!(env!("CARGO_MANIFEST_DIR"), "/../../protocol/vectors.json")).unwrap();
    let section: String = v[v.find("\"radio\"").unwrap()..].chars().filter(|c| !c.is_whitespace()).collect();
    let objs: Vec<&str> = section.split('{').skip(1).map(|o| o.split('}').next().unwrap()).collect();
    assert_eq!(objs.len(), Radio::ALL.len());
    for (o, r) in objs.iter().zip(Radio::ALL) {
        let o = format!("{{{o}}}");
        let p = r.profile();
        let n = |k: &str| json::get(o.as_bytes(), k).and_then(json::as_f64).unwrap() as u32;
        assert_eq!(json::get(o.as_bytes(), "id").and_then(json::as_str), Some(p.id));
        assert_eq!((n("baud"), n("tlm_hz"), n("ctl_hz")), (p.baud, p.tlm_hz as u32, p.ctl_hz as u32), "{}", p.id);
    }
}

#[test]
fn sik_radio_announces_caps_rate_and_carries_control() {
    let (mut dev, mut app) = radio_device("Radio-Rover", Kind::Rover, Radio::Sik);
    app.pump(&mut dev, 1100, false);
    assert!(!app.of("announce").is_empty(), "stream links announce");
    let seen = Arc::new(Mutex::new(0f32));
    let s2 = seen.clone();
    dev.on_control(move |c| *s2.lock().unwrap() = c.lx);
    app.send(r#"{"t":"hello","v":1}"#);
    let start = app.got.len();
    for _ in 0..50 {
        dev.link.imu([0.0, 0.0, 9.81], [0.0; 3]);
        dev.link.position([1.0, 2.0, 0.0]);
        dev.link.points(&[[1.0, 0.0, 0.0]]);
        app.pump(&mut dev, 20, true);
    }
    let tlm: Vec<_> = app.got[start..].iter().filter(|m| m.contains(r#""t":"tlm""#)).collect();
    assert!((4..=6).contains(&tlm.len()), "5 Hz on SiK, got {}", tlm.len());
    assert!(tlm.last().unwrap().contains(r#""imu""#), "full field set above 2 Hz");
    assert!(app.of("pc").is_empty(), "no point clouds over radio");
    assert_eq!(*seen.lock().unwrap(), 0.5);
}

#[test]
fn telemetry_only_link_takes_stop_but_nothing_else() {
    let (mut dev, mut app) = radio_device("Radio-Rocket", Kind::Rocket, Radio::Lora);
    let cmds = Arc::new(Mutex::new(0));
    let c2 = cmds.clone();
    dev.on_command(move |_, _| *c2.lock().unwrap() += 1);
    app.send(r#"{"t":"hello","v":1}"#);
    app.send(r#"{"t":"arm","v":true}"#);
    app.send(r#"{"t":"cmd","c":"countdown","a":{"s":10}}"#);
    for _ in 0..30 {
        dev.link.imu([0.0, 0.0, 9.81], [0.0; 3]);
        dev.link.position([0.0, 0.0, 120.0]);
        app.pump(&mut dev, 50, true);
    }
    assert!(!dev.link.armed());
    assert_eq!(*cmds.lock().unwrap(), 0);
    let tlm = app.of("tlm");
    assert!(!tlm.is_empty() && tlm.iter().all(|m| !m.contains("imu")) && tlm.last().unwrap().contains(r#""pos""#));
    app.send(r#"{"t":"stop"}"#);
    app.pump(&mut dev, 50, false);
    assert!(dev.link.stopped());
}

#[test]
fn telemetry_moves_to_the_fallback_link_on_failsafe() {
    let (a, b) = UnixStream::pair().unwrap();
    b.set_nonblocking(true).unwrap();
    let radio = StreamTransport::new(a.try_clone().unwrap(), a).radio(Radio::Sik);
    let mut dev = Device::new("Fb", Kind::Rover).port(0).state_dir(dir("fb")).wifi("", "").transport(radio).start().unwrap();
    dev.failsafe(Duration::from_millis(200), koebelt_link::Mode::Hold);
    let udp = UdpSocket::bind("127.0.0.1:0").unwrap();
    udp.set_nonblocking(true).unwrap();
    let to = ("127.0.0.1", dev.local_port());
    udp.send_to(br#"{"t":"hello","v":1}"#, to).unwrap();
    let mut app = LineApp { s: b, buf: vec![], got: vec![] };
    for _ in 0..10 {
        udp.send_to(br#"{"t":"ctl","s":1,"lx":0,"ly":0,"rx":0,"ry":0}"#, to).unwrap();
        dev.link.position([1.0, 0.0, 0.0]);
        app.pump(&mut dev, 20, false);
    }
    let before = app.of("tlm").len();
    assert_eq!(before, 0, "telemetry follows the primary link while it is alive");
    for _ in 0..40 {
        dev.link.position([1.0, 0.0, 0.0]);
        app.pump(&mut dev, 20, false); // Wi-Fi went quiet
    }
    assert!(dev.link.failsafe_active());
    assert!(!app.of("tlm").is_empty(), "telemetry continues over the radio");
}

#[test]
fn video_fields_state_and_saved_params() {
    let d = dir("vid");
    let (a, b) = UnixStream::pair().unwrap();
    b.set_nonblocking(true).unwrap();
    let mut dev = Device::new("Cam", Kind::Rover).state_dir(&d).transport(StreamTransport::new(a.try_clone().unwrap(), a)).start().unwrap();
    let mut app = LineApp { s: b, buf: vec![], got: vec![] };
    let srv = MjpegServer::bind(0).unwrap();
    dev.video(&srv.url(), "cam", "Front");
    dev.link.set_sensors(&["CAMERA", "IMU"]);
    let i = dev.link.param_full("MAX_SPD", 2.0, 0.0, 5.0, "m/s", 0.1, "Top speed");
    dev.link.set_state("gear", "LOW");
    let connects = Arc::new(Mutex::new(0));
    let c2 = connects.clone();
    dev.on_connect(move || *c2.lock().unwrap() += 1);
    app.send(r#"{"t":"hello","v":1}"#);
    dev.link.tool(0.1, 0.2, 0.3, 0.5);
    dev.link.throttle_out(0.4);
    dev.link.rocket_state(120.0, 3.5, 0.0);
    app.pump(&mut dev, 100, true);
    dev.link.tracks(&[("T1", 18.0, 0.5)]);
    dev.link.log("warn", "GPS lost");
    app.pump(&mut dev, 50, true);
    let hello = app.of("hello")[0].clone();
    assert!(hello.contains(&format!(r#""video":[{{"id":"cam","url":":{}/stream","fmt":"mjpeg","label":"Front"}}]"#, srv.port())), "{hello}");
    assert!(hello.contains(r#""sensors":["CAMERA","IMU"]"#));
    assert!(app.of("params")[0].contains(r#"["MAX_SPD",2,0,5,0.1,"m/s","Top speed"]"#), "{:?}", app.of("params"));
    assert!(app.of("state").last().unwrap().contains(r#""ext":{"gear":"LOW"}"#));
    let tlm: String = app.of("tlm").iter().map(|s| s.as_str()).collect();
    for k in ["tool", "throttle", "rocket"] {
        assert!(tlm.contains(&format!("\"{k}\"")), "{k}");
    }
    assert!(app.of("tracks")[0].contains(r#"["T1",18,0.5]"#));
    assert!(app.of("log")[0].contains("GPS lost"));
    assert_eq!(*connects.lock().unwrap(), 1);

    // Tune > Save persists; the next start restores it.
    app.send(r#"{"t":"pset","p":{"MAX_SPD":3.5}}"#);
    app.send(r#"{"t":"psave"}"#);
    app.pump(&mut dev, 50, true);
    assert_eq!(dev.link.param_value(i), 3.5);
    drop(dev);
    let (a, _b) = UnixStream::pair().unwrap();
    let mut again = Device::new("Cam", Kind::Rover).state_dir(&d).transport(StreamTransport::new(a.try_clone().unwrap(), a)).start().unwrap();
    let j = again.param("MAX_SPD", 2.0, 0.0, 5.0, "m/s");
    assert_eq!(again.link.param_value(j), 3.5);
}

#[test]
fn mjpeg_server_streams_newest_frame() {
    let srv = MjpegServer::bind(0).unwrap();
    let jpeg = [&[0xFF, 0xD8][..], &[b'x'; 100][..], &[0xFF, 0xD9][..]].concat();
    let mut c = TcpStream::connect(("127.0.0.1", srv.port())).unwrap();
    c.write_all(b"GET /stream HTTP/1.1\r\nHost: x\r\n\r\n").unwrap();
    c.set_read_timeout(Some(Duration::from_secs(3))).unwrap();
    let mut r = BufReader::new(c);
    let mut head = String::new();
    while head.lines().last() != Some("") || !head.ends_with("\r\n\r\n") {
        r.read_line(&mut head).unwrap();
    }
    assert!(head.contains("multipart/x-mixed-replace; boundary=frame"), "{head}");
    for _ in 0..50 {
        if srv.clients() == 1 {
            break;
        }
        std::thread::sleep(Duration::from_millis(10));
    }
    srv.push(&jpeg);
    let mut part = vec![0u8; 60 + jpeg.len()];
    r.read_exact(&mut part).unwrap();
    let want = [&b"--frame\r\nContent-Type: image/jpeg\r\nContent-Length: 104\r\n\r\n"[..], &jpeg[..]].concat();
    assert_eq!(&part[..want.len()], &want[..]);
}
