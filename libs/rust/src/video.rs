//! Serve a camera to the app as MJPEG over HTTP. Video does not go over the
//! KoebeltLink protocol: the device declares the stream in `hello`
//! ([`crate::Device::video`]) and the app opens it directly.

use std::io::{self, BufRead, BufReader, Write};
use std::net::{TcpListener, TcpStream};
use std::sync::atomic::{AtomicBool, AtomicUsize, Ordering};
use std::sync::{Arc, Condvar, Mutex};
use std::time::Duration;

type Frame = (u64, Option<Arc<Vec<u8>>>);

struct Shared {
    frame: Mutex<Frame>,
    cv: Condvar,
    clients: AtomicUsize,
    closed: AtomicBool,
}

/// `/stream` (multipart/x-mixed-replace) and `/snapshot` on `port`.
/// Each client gets the newest frame, never a backlog.
pub struct MjpegServer {
    port: u16,
    shared: Arc<Shared>,
}

impl MjpegServer {
    /// Listens on `0.0.0.0:port` (0 picks a free port).
    pub fn bind(port: u16) -> io::Result<Self> {
        let l = TcpListener::bind(("0.0.0.0", port))?;
        let port = l.local_addr()?.port();
        let shared = Arc::new(Shared { frame: Mutex::new((0, None)), cv: Condvar::new(), clients: AtomicUsize::new(0), closed: AtomicBool::new(false) });
        let s = shared.clone();
        std::thread::Builder::new().name("koebelt-mjpeg".into()).spawn(move || {
            for c in l.incoming() {
                if s.closed.load(Ordering::Relaxed) {
                    break;
                }
                if let Ok(c) = c {
                    let s = s.clone();
                    let _ = std::thread::Builder::new().name("koebelt-mjpeg-client".into()).spawn(move || serve(c, &s));
                }
            }
        })?;
        Ok(Self { port, shared })
    }

    pub fn port(&self) -> u16 {
        self.port
    }

    /// Port and path for [`crate::Device::video`]; the app adds this machine's IP.
    pub fn url(&self) -> String {
        format!(":{}/stream", self.port)
    }

    /// Clients watching right now; skip grabbing frames when 0.
    pub fn clients(&self) -> usize {
        self.shared.clients.load(Ordering::Relaxed)
    }

    /// Publishes a new JPEG frame.
    pub fn push(&self, jpeg: &[u8]) {
        let mut f = self.shared.frame.lock().unwrap();
        *f = (f.0 + 1, Some(Arc::new(jpeg.to_vec())));
        self.shared.cv.notify_all();
    }
}

impl Drop for MjpegServer {
    fn drop(&mut self) {
        self.shared.closed.store(true, Ordering::Relaxed);
        self.shared.cv.notify_all();
        // Wake the accept loop so it sees the flag.
        let _ = TcpStream::connect(("127.0.0.1", self.port));
    }
}

/// Waits for a frame newer than `after`.
fn next(s: &Shared, after: u64) -> Option<(u64, Arc<Vec<u8>>)> {
    let mut f = s.frame.lock().unwrap();
    if f.0 == after || f.1.is_none() {
        f = s.cv.wait_timeout(f, Duration::from_secs(2)).unwrap().0;
    }
    match &f.1 {
        Some(b) if f.0 != after => Some((f.0, b.clone())),
        _ => None,
    }
}

fn serve(c: TcpStream, s: &Shared) {
    let mut r = BufReader::new(match c.try_clone() {
        Ok(x) => x,
        Err(_) => return,
    });
    let mut line = String::new();
    if r.read_line(&mut line).is_err() {
        return;
    }
    let path = line.split_whitespace().nth(1).unwrap_or("/").to_string();
    // Skip the request headers.
    loop {
        let mut h = String::new();
        if r.read_line(&mut h).map(|n| n == 0).unwrap_or(true) || h == "\r\n" || h == "\n" {
            break;
        }
    }
    let mut w = c;
    if path.starts_with("/snapshot") {
        let _ = match next(s, 0) {
            Some((_, f)) => write!(w, "HTTP/1.0 200 OK\r\nContent-Type: image/jpeg\r\nContent-Length: {}\r\n\r\n", f.len()).and_then(|_| w.write_all(&f)),
            None => w.write_all(b"HTTP/1.0 503 Service Unavailable\r\n\r\n"),
        };
        return;
    }
    if !path.starts_with("/stream") {
        let _ = w.write_all(b"HTTP/1.0 404 Not Found\r\n\r\n");
        return;
    }
    if w.write_all(b"HTTP/1.0 200 OK\r\nContent-Type: multipart/x-mixed-replace; boundary=frame\r\nCache-Control: no-cache\r\n\r\n").is_err() {
        return;
    }
    s.clients.fetch_add(1, Ordering::Relaxed);
    let mut seq = 0;
    while !s.closed.load(Ordering::Relaxed) {
        let Some((n, f)) = next(s, seq) else { continue };
        seq = n;
        let ok = write!(w, "--frame\r\nContent-Type: image/jpeg\r\nContent-Length: {}\r\n\r\n", f.len())
            .and_then(|_| w.write_all(&f))
            .and_then(|_| w.write_all(b"\r\n"))
            .and_then(|_| w.flush());
        if ok.is_err() {
            break;
        }
    }
    s.clients.fetch_sub(1, Ordering::Relaxed);
}
