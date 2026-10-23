"""A device's camera, as numpy images for OpenCV, PyTorch, YOLO…

The stream is read straight from the device (MJPEG, or a still JPEG polled),
on a background thread that keeps only the newest picture: a slow model
always gets the latest frame, never a backlog.
"""
from __future__ import annotations

import io
import threading
import time
import urllib.request
from typing import Any, Dict, Iterator, Optional


class CameraError(RuntimeError):
    pass


def decode_jpeg(data: bytes):
    """Image bytes (JPEG, PNG) → H×W×3 numpy array, BGR (OpenCV's order), with OpenCV or Pillow."""
    try:
        import cv2
        import numpy as np
    except ImportError:
        cv2 = None
    if cv2 is not None:
        img = cv2.imdecode(np.frombuffer(data, np.uint8), cv2.IMREAD_COLOR)
        if img is None:
            raise CameraError("could not decode a camera frame")
        return img
    try:
        import numpy as np
        from PIL import Image
    except ImportError:
        raise CameraError("camera frames need numpy and OpenCV (pip install opencv-python) or Pillow (pip install pillow)") from None
    return np.asarray(Image.open(io.BytesIO(data)).convert("RGB"))[:, :, ::-1].copy()


class Camera:
    """One of the device's cameras. ``frame()`` is the newest picture;
    ``for img in camera.frames():`` yields each new one."""

    def __init__(self, info: Dict[str, Any]):
        self.id: str = info.get("id", "cam")
        self.label: str = info.get("label") or self.id
        self.url: Optional[str] = info.get("url")
        self.fmt: str = info.get("fmt", "mjpeg")
        self._jpeg: Optional[bytes] = None
        self._count = 0
        self._cond = threading.Condition()
        self._thread: Optional[threading.Thread] = None
        self._stop = threading.Event()
        self.error: Optional[str] = None
        self.fps = 0.0

    def __repr__(self):
        return f"Camera({self.label!r}, {self.url!r})"

    def _start(self) -> None:
        if self._thread is not None:
            return
        if not self.url:
            raise CameraError(f"camera {self.label} is not reachable from this computer")
        self._thread = threading.Thread(target=self._read, daemon=True, name=f"koebelt-dash-camera-{self.id}")
        self._thread.start()

    def _publish(self, jpeg: bytes) -> None:
        with self._cond:
            self._jpeg = jpeg
            self._count += 1
            self._cond.notify_all()

    def _read(self) -> None:
        while not self._stop.is_set():
            try:
                with urllib.request.urlopen(self.url, timeout=5) as r:
                    ctype = r.headers.get("Content-Type", "")
                    if self.fmt == "jpeg" or not ctype.startswith("multipart/"):
                        self._publish(r.read())
                        self._stop.wait(0.1)
                        continue
                    boundary = ctype.split("boundary=", 1)[-1].strip().strip('"').encode()
                    self._parts(r, b"--" + boundary.lstrip(b"-") if boundary else b"")
                self.error = None
            except Exception as e:
                self.error = str(e)
                self._stop.wait(1.0)

    def _parts(self, r, boundary: bytes) -> None:
        """Reads multipart/x-mixed-replace parts: headers, then Content-Length
        bytes (or, without a length, up to the next boundary)."""
        rd = _Buffered(r)
        last = time.monotonic()
        while not self._stop.is_set():
            line = rd.readline()
            if line is None:
                return
            if not line.strip().startswith(b"--"):
                continue
            length = None
            while True:
                h = rd.readline()
                if h is None:
                    return
                if not h.strip():
                    break
                k, _, v = h.decode("latin-1").partition(":")
                if k.strip().lower() == "content-length":
                    length = int(v.strip())
            data = rd.read(length) if length is not None else rd.until(b"\r\n" + boundary)
            if data is None:
                return
            self._publish(data)
            now = time.monotonic()
            self.fps = self.fps * 0.9 + (1 / max(now - last, 1e-3)) * 0.1
            last = now

    def jpeg(self, timeout: float = 5.0) -> bytes:
        """The newest frame as the camera sends it (JPEG, or PNG for simulated cameras)."""
        self._start()
        with self._cond:
            if not self._cond.wait_for(lambda: self._jpeg is not None, timeout=timeout):
                raise CameraError(f"no picture from camera {self.label} within {timeout} s" + (f": {self.error}" if self.error else ""))
            return self._jpeg  # type: ignore[return-value]

    def frame(self, timeout: float = 5.0):
        """The newest frame, H×W×3 BGR numpy array."""
        return decode_jpeg(self.jpeg(timeout))

    def frames(self, timeout: float = 5.0) -> Iterator[Any]:
        """Each new frame, newest first: frames the loop was too slow for are skipped."""
        self._start()
        seen = -1
        while True:
            with self._cond:
                if not self._cond.wait_for(lambda: self._count != seen and self._jpeg is not None, timeout=timeout):
                    raise CameraError(f"no picture from camera {self.label} within {timeout} s" + (f": {self.error}" if self.error else ""))
                seen, data = self._count, self._jpeg
            yield decode_jpeg(data)  # type: ignore[arg-type]

    def close(self) -> None:
        self._stop.set()


class _Buffered:
    """Line, length and marker reads over a live HTTP body, returning what has
    arrived without waiting for more than it needs."""

    def __init__(self, r):
        self.r = r
        self.buf = b""

    def _more(self) -> bool:
        chunk = self.r.read1(65536) if hasattr(self.r, "read1") else self.r.read(4096)
        if not chunk:
            return False
        self.buf += chunk
        if len(self.buf) > 32_000_000:
            raise CameraError("camera stream without frame boundaries")
        return True

    def readline(self) -> Optional[bytes]:
        while b"\n" not in self.buf:
            if not self._more():
                return None
        line, _, self.buf = self.buf.partition(b"\n")
        return line + b"\n"

    def read(self, n: int) -> Optional[bytes]:
        while len(self.buf) < n:
            if not self._more():
                return None
        data, self.buf = self.buf[:n], self.buf[n:]
        return data

    def until(self, marker: bytes) -> Optional[bytes]:
        """The bytes before marker; the marker stays for the next part."""
        while marker not in self.buf:
            if not self._more():
                return None
        i = self.buf.index(marker)
        data, self.buf = self.buf[:i], self.buf[i + 2:]
        return data


def boxes_of(items: Any, width: Optional[float] = None, height: Optional[float] = None) -> list:
    """Boxes for dev.overlay(): from (x, y, w, h[, label]) tuples, normalised
    or in pixels (with width and height), or straight from an ultralytics
    result (``model(frame)[0]``) or its ``.boxes``."""
    names = getattr(items, "names", None)
    if hasattr(items, "boxes") and not hasattr(items, "xyxyn"):
        items = items.boxes
    if hasattr(items, "xyxyn"):
        xyxy = items.xyxyn.tolist()
        cls = items.cls.tolist() if hasattr(items, "cls") else [None] * len(xyxy)
        conf = items.conf.tolist() if hasattr(items, "conf") else [None] * len(xyxy)
        out = []
        for (x1, y1, x2, y2), c, p in zip(xyxy, cls, conf):
            label = "" if c is None else (names.get(int(c), str(int(c))) if isinstance(names, dict) else str(int(c)))
            if p is not None:
                label = f"{label} {p:.2f}".strip()
            out.append([x1, y1, x2 - x1, y2 - y1, label])
        return out
    out = []
    for b in items:
        if hasattr(b, "xyxyn"):
            out.extend(boxes_of(b))
            continue
        x, y, w, h = (float(v) for v in b[:4])
        if width and height:
            x, y, w, h = x / width, y / height, w / width, h / height
        out.append([x, y, w, h, str(b[4]) if len(b) > 4 else ""])
    return out
