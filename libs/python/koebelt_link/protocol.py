"""KoebeltLink v1 wire format. See protocol/PROTOCOL.md."""
from __future__ import annotations

import base64
import json
import struct
from typing import Any, Dict, Iterable, Iterator, List, Optional, Sequence

VERSION = 1
UDP_DEVICE_PORT = 47800
UDP_ANNOUNCE_PORT = 47801
BLE_SERVICE = "6e400001-b5a3-f393-e0a9-e50e24dcca9e"
BLE_RX = "6e400002-b5a3-f393-e0a9-e50e24dcca9e"
BLE_TX = "6e400003-b5a3-f393-e0a9-e50e24dcca9e"

KINDS = ("drone", "rover", "arm", "rocket", "bench", "generic")

#: Radio link profiles (protocol/PROTOCOL.md, "Radio links"): id -> (baud,
#: telemetry Hz, control Hz). Control Hz 0 means telemetry only. Same table
#: in every library and in protocol/vectors.json.
RADIO_PROFILES = {
    "sik": (57600, 5, 10),
    "lora": (115200, 2, 0),
    "hc12": (9600, 2, 5),
    "xbee": (57600, 5, 10),
    "other": (57600, 2, 5),
}

#: Fields sent on links of 2 Hz or less.
COMPACT_FIELDS = ("pos", "att", "gps", "bat", "rocket")

Msg = Dict[str, Any]


def encode(m: Msg) -> bytes:
    return json.dumps(m, separators=(",", ":"), allow_nan=False).encode()


def decode(data: bytes | str) -> Optional[Msg]:
    """Parse one message. Returns None for anything that is not a JSON object with a string `t`."""
    try:
        m = json.loads(data)
    except (ValueError, UnicodeDecodeError):
        return None
    if isinstance(m, dict) and isinstance(m.get("t"), str):
        return m
    return None


class LineDecoder:
    """Splits a byte stream (serial, BLE) into newline-delimited messages."""

    MAX_LINE = 64 * 1024

    def __init__(self) -> None:
        self._buf = bytearray()

    def feed(self, data: bytes) -> Iterator[Msg]:
        self._buf.extend(data)
        while True:
            i = self._buf.find(b"\n")
            if i < 0:
                break
            line = bytes(self._buf[:i]).strip()
            del self._buf[: i + 1]
            if line:
                m = decode(line)
                if m is not None:
                    yield m
        if len(self._buf) > self.MAX_LINE:
            self._buf.clear()


def encode_points(points: Iterable[Sequence[float]]) -> tuple[int, str]:
    """`i16cm` point cloud: little-endian int16 x,y,z in centimetres, base64."""
    out = bytearray()
    n = 0
    for p in points:
        out += struct.pack("<3h", *(max(-32768, min(32767, int(round(float(v) * 100)))) for v in p[:3]))
        n += 1
    return n, base64.b64encode(bytes(out)).decode()


def decode_points(d: str) -> List[List[float]]:
    raw = base64.b64decode(d)
    return [[v / 100 for v in struct.unpack_from("<3h", raw, i)] for i in range(0, len(raw) - len(raw) % 6, 6)]
