//! Minimal JSON for the koebelt/link protocol: a streaming writer into a byte
//! buffer and a field extractor for the flat messages the app sends.
//! No allocation, works in `no_std`.

use core::fmt::{self, Write};

/// Writes into a fixed byte buffer; silently marks overflow.
pub struct Buf<'a> {
    buf: &'a mut [u8],
    len: usize,
    overflow: bool,
}

impl<'a> Buf<'a> {
    pub fn new(buf: &'a mut [u8]) -> Self {
        Self { buf, len: 0, overflow: false }
    }
    pub fn as_bytes(&self) -> Option<&[u8]> {
        if self.overflow { None } else { Some(&self.buf[..self.len]) }
    }
    pub fn raw(&mut self, s: &str) {
        let _ = self.write_str(s);
    }
    /// A JSON string literal with escaping.
    pub fn string(&mut self, s: &str) {
        self.raw("\"");
        for c in s.chars() {
            match c {
                '"' => self.raw("\\\""),
                '\\' => self.raw("\\\\"),
                '\n' => self.raw("\\n"),
                c if (c as u32) < 0x20 => {
                    let _ = write!(self, "\\u{:04x}", c as u32);
                }
                c => {
                    let mut b = [0u8; 4];
                    self.raw(c.encode_utf8(&mut b));
                }
            }
        }
        self.raw("\"");
    }
    pub fn num(&mut self, v: f64) {
        if v.is_finite() {
            if v == (v as i64) as f64 && v.abs() < 1e15 {
                let _ = write!(self, "{}", v as i64);
            } else {
                let _ = write!(self, "{}", v);
            }
        } else {
            self.raw("null");
        }
    }
    /// f32 with its shortest round-trip representation (no f64 widening noise).
    pub fn numf(&mut self, v: f32) {
        if v.is_finite() {
            if v == (v as i32) as f32 && v.abs() < 1e7 {
                let _ = write!(self, "{}", v as i32);
            } else {
                let _ = write!(self, "{}", v);
            }
        } else {
            self.raw("null");
        }
    }
    pub fn key(&mut self, first: &mut bool, k: &str) {
        if !*first {
            self.raw(",");
        }
        *first = false;
        self.string(k);
        self.raw(":");
    }
    pub fn arr(&mut self, v: &[f32]) {
        self.raw("[");
        for (i, x) in v.iter().enumerate() {
            if i > 0 {
                self.raw(",");
            }
            self.numf(*x);
        }
        self.raw("]");
    }
}

impl Write for Buf<'_> {
    fn write_str(&mut self, s: &str) -> fmt::Result {
        let b = s.as_bytes();
        if self.overflow || self.len + b.len() > self.buf.len() {
            // Poison the whole buffer so a NUL-terminated reader never sees truncated JSON.
            self.overflow = true;
            self.buf.fill(b' ');
            return Err(fmt::Error);
        }
        self.buf[self.len..self.len + b.len()].copy_from_slice(b);
        self.len += b.len();
        Ok(())
    }
}

// ------------------------------------------------------------------ reading

fn skip_ws(s: &[u8], mut i: usize) -> usize {
    while i < s.len() && matches!(s[i], b' ' | b'\t' | b'\n' | b'\r') {
        i += 1;
    }
    i
}

/// End index (exclusive) of the JSON value starting at `i`.
fn value_end(s: &[u8], i: usize) -> Option<usize> {
    let i = skip_ws(s, i);
    match *s.get(i)? {
        b'"' => {
            let mut j = i + 1;
            while j < s.len() {
                match s[j] {
                    b'\\' => j += 2,
                    b'"' => return Some(j + 1),
                    _ => j += 1,
                }
            }
            None
        }
        b'{' | b'[' => {
            let mut depth = 0i32;
            let mut j = i;
            while j < s.len() {
                match s[j] {
                    b'"' => {
                        j = value_end(s, j)?;
                        continue;
                    }
                    b'{' | b'[' => depth += 1,
                    b'}' | b']' => {
                        depth -= 1;
                        if depth == 0 {
                            return Some(j + 1);
                        }
                    }
                    _ => {}
                }
                j += 1;
            }
            None
        }
        _ => {
            let mut j = i;
            while j < s.len() && !matches!(s[j], b',' | b'}' | b']') {
                j += 1;
            }
            Some(j)
        }
    }
}

/// Iterates top-level `(key, raw value)` pairs of a JSON object.
pub struct Fields<'a> {
    s: &'a [u8],
    i: usize,
}

impl<'a> Fields<'a> {
    pub fn new(s: &'a [u8]) -> Self {
        let i = skip_ws(s, 0);
        Self { s, i: if s.get(i) == Some(&b'{') { i + 1 } else { s.len() } }
    }
}

impl<'a> Iterator for Fields<'a> {
    type Item = (&'a str, &'a [u8]);
    fn next(&mut self) -> Option<Self::Item> {
        let s = self.s;
        let mut i = skip_ws(s, self.i);
        if i < s.len() && s[i] == b',' {
            i = skip_ws(s, i + 1);
        }
        if i >= s.len() || s[i] != b'"' {
            return None;
        }
        let kend = value_end(s, i)?;
        let key = core::str::from_utf8(&s[i + 1..kend - 1]).ok()?;
        let mut j = skip_ws(s, kend);
        if s.get(j) != Some(&b':') {
            return None;
        }
        j = skip_ws(s, j + 1);
        let vend = value_end(s, j)?;
        self.i = vend;
        let mut e = vend;
        while e > j && matches!(s[e - 1], b' ' | b'\t' | b'\n' | b'\r') {
            e -= 1;
        }
        Some((key, &s[j..e]))
    }
}

pub fn get<'a>(obj: &'a [u8], key: &str) -> Option<&'a [u8]> {
    Fields::new(obj).find(|(k, _)| *k == key).map(|(_, v)| v)
}

/// String value without escapes (keys, modes and codes never contain escapes).
pub fn as_str(v: &[u8]) -> Option<&str> {
    if v.len() >= 2 && v[0] == b'"' && v[v.len() - 1] == b'"' {
        core::str::from_utf8(&v[1..v.len() - 1]).ok()
    } else {
        None
    }
}

pub fn as_f64(v: &[u8]) -> Option<f64> {
    core::str::from_utf8(v).ok()?.trim().parse().ok()
}

pub fn as_bool(v: &[u8]) -> Option<bool> {
    match v {
        b"true" => Some(true),
        b"false" => Some(false),
        _ => None,
    }
}

/// Fills `out` from a JSON number array; returns the count read.
pub fn as_f32s(v: &[u8], out: &mut [f32]) -> usize {
    if v.first() != Some(&b'[') {
        return 0;
    }
    let mut n = 0;
    let mut i = 1;
    while n < out.len() {
        i = skip_ws(v, i);
        if i >= v.len() || v[i] == b']' {
            break;
        }
        let Some(e) = value_end(v, i) else { break };
        if let Some(x) = as_f64(&v[i..e]) {
            out[n] = x as f32;
        }
        n += 1;
        i = skip_ws(v, e);
        if v.get(i) == Some(&b',') {
            i += 1;
        }
    }
    n
}

const B64: &[u8; 64] = b"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

pub fn base64(input: &[u8], out: &mut Buf<'_>) {
    for c in input.chunks(3) {
        let v = (c[0] as u32) << 16 | (*c.get(1).unwrap_or(&0) as u32) << 8 | *c.get(2).unwrap_or(&0) as u32;
        let q = [
            B64[(v >> 18) as usize & 63],
            B64[(v >> 12) as usize & 63],
            if c.len() > 1 { B64[(v >> 6) as usize & 63] } else { b'=' },
            if c.len() > 2 { B64[v as usize & 63] } else { b'=' },
        ];
        out.raw(core::str::from_utf8(&q).unwrap_or(""));
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn fields() {
        let m = br#"{ "t":"ctl", "s":812,"lx":0,"ly":0.4 ,"a":{"x":[1,2]},"m":"a\"b"}"#;
        assert_eq!(as_str(get(m, "t").unwrap()), Some("ctl"));
        assert_eq!(as_f64(get(m, "ly").unwrap()), Some(0.4));
        assert_eq!(get(m, "a"), Some(&br#"{"x":[1,2]}"#[..]));
        let mut j = [0f32; 6];
        assert_eq!(as_f32s(b"[0, 0,1,0,0,-1]", &mut j), 6);
        assert_eq!(j[5], -1.0);
        assert!(get(m, "zz").is_none());
    }

    #[test]
    fn writer() {
        let mut b = [0u8; 64];
        let mut w = Buf::new(&mut b);
        let mut f = true;
        w.raw("{");
        w.key(&mut f, "t");
        w.string("a\"b");
        w.key(&mut f, "v");
        w.arr(&[1.0, 0.5, f32::NAN]);
        w.raw("}");
        assert_eq!(w.as_bytes().unwrap(), br#"{"t":"a\"b","v":[1,0.5,null]}"#);
    }
}
