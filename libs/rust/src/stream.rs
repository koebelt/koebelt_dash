//! Byte-stream links: USB serial, radio modems, TCP serial bridges.
//! Newline-delimited JSON, read on a background thread so `recv` never blocks.

use std::collections::VecDeque;
use std::io::{self, Read, Write};
use std::sync::mpsc::{self, Receiver};

use crate::{LineReader, Radio, RadioProfile, Transport, module_rate_hz};

/// Newline-delimited JSON over any reader/writer pair. With a radio profile
/// ([`StreamTransport::radio`]) it follows that radio's rates.
pub struct StreamTransport {
    rx: Receiver<Vec<u8>>,
    pending: VecDeque<u8>,
    lines: LineReader,
    out: Box<dyn Write + Send>,
    profile: Option<RadioProfile>,
}

impl StreamTransport {
    pub fn new(mut reader: impl Read + Send + 'static, writer: impl Write + Send + 'static) -> Self {
        let (tx, rx) = mpsc::channel();
        std::thread::Builder::new()
            .name("koebelt-stream".into())
            .spawn(move || {
                let mut b = [0u8; 1024];
                loop {
                    match reader.read(&mut b) {
                        Ok(0) => break,
                        Ok(n) => {
                            if tx.send(b[..n].to_vec()).is_err() {
                                break;
                            }
                        }
                        Err(e) if e.kind() == io::ErrorKind::Interrupted => {}
                        Err(_) => break,
                    }
                }
            })
            .expect("spawn reader thread");
        Self { rx, pending: VecDeque::new(), lines: LineReader::default(), out: Box::new(writer), profile: None }
    }

    /// Applies a radio profile: telemetry rate cap, no bulk data, and
    /// control only if the radio carries it.
    pub fn radio(mut self, r: Radio) -> Self {
        self.profile = Some(r.profile());
        self
    }

    pub fn profile(&self) -> Option<RadioProfile> {
        self.profile
    }

    /// A serial bridge module (HM-10, HC-05, RN4870, Bluno…) on a UART at
    /// `baud`: telemetry follows the baud rate, control is accepted.
    pub fn module(mut self, baud: u32) -> Self {
        self.profile = Some(RadioProfile { id: "module", baud, tlm_hz: module_rate_hz(baud), ctl_hz: 10 });
        self
    }
}

impl Transport for StreamTransport {
    fn recv(&mut self, buf: &mut [u8]) -> Option<usize> {
        loop {
            while let Some(b) = self.pending.pop_front() {
                if let Some(n) = self.lines.feed(b, buf) {
                    return Some(n);
                }
            }
            self.pending.extend(self.rx.try_recv().ok()?);
        }
    }
    fn send(&mut self, msg: &[u8]) {
        let _ = self.out.write_all(msg).and_then(|_| self.out.write_all(b"\n")).and_then(|_| self.out.flush());
    }
    /// One peer on a wire or radio: announcing is writing, so the app can
    /// find the device behind a radio before pairing.
    fn announce(&mut self, msg: &[u8]) {
        self.send(msg)
    }
    fn accepts_control(&self) -> bool {
        self.profile.map(|p| p.ctl_hz > 0).unwrap_or(true)
    }
    fn low_bandwidth(&self) -> bool {
        self.profile.is_some()
    }
    fn max_rate_hz(&self) -> f32 {
        self.profile.map(|p| p.tlm_hz as f32).unwrap_or(0.0)
    }
}

/// Serial ports, configured with the system's `stty` (Linux, macOS) or
/// `mode` (Windows), so the crate stays dependency-free.
pub struct SerialTransport;

impl SerialTransport {
    /// Opens `path` (`/dev/ttyUSB0`, `/dev/cu.usbserial-…`, `COM3`) at `baud`.
    pub fn open(path: &str, baud: u32) -> io::Result<StreamTransport> {
        configure(path, baud)?;
        let mut o = std::fs::OpenOptions::new();
        o.read(true).write(true);
        #[cfg(unix)]
        {
            use std::os::unix::fs::OpenOptionsExt;
            // O_NOCTTY: the port must not become our controlling terminal.
            o.custom_flags(if cfg!(target_os = "linux") { 0o400 } else { 0x20000 });
        }
        let f = o.open(path)?;
        let r = f.try_clone()?;
        Ok(StreamTransport::new(r, f))
    }

    /// A radio modem on `path`, at the radio's usual baud rate.
    pub fn radio(path: &str, radio: Radio) -> io::Result<StreamTransport> {
        Ok(Self::open(path, radio.profile().baud)?.radio(radio))
    }

    /// A Bluetooth serial module on `path` (a UART such as /dev/serial0).
    pub fn module(path: &str, baud: u32) -> io::Result<StreamTransport> {
        Ok(Self::open(path, baud)?.module(baud))
    }
}

fn configure(path: &str, baud: u32) -> io::Result<()> {
    use std::process::Command;
    let status = if cfg!(windows) {
        let com = path.trim_start_matches(r"\\.\");
        Command::new("mode").args([format!("{com}:"), format!("BAUD={baud}"), "PARITY=n".into(), "DATA=8".into(), "STOP=1".into()]).status()?
    } else {
        let flag = if cfg!(target_os = "linux") { "-F" } else { "-f" };
        Command::new("stty")
            .args([flag, path, &baud.to_string(), "raw", "-echo", "cs8", "-cstopb", "-parenb", "clocal", "min", "1", "time", "0"])
            .status()?
    };
    if status.success() { Ok(()) } else { Err(io::Error::other(format!("could not configure {path} at {baud} baud"))) }
}
