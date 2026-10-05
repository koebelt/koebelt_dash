"""Serve a camera to the app as MJPEG over HTTP (what ESP32-CAM, mjpg-streamer
and ustreamer serve too). Video does not go over the koebelt/link protocol: the
device only declares the stream in its `hello`, the app opens it directly.

    srv = MjpegServer(port=8081)
    dev.video(srv.url, label="Front")
    srv.push(jpeg_bytes)          # whenever you have a new frame
"""
from __future__ import annotations

import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from typing import Any, Optional


class MjpegServer:
    """HTTP server with `/stream` (multipart/x-mixed-replace) and `/snapshot`.

    Frames are JPEG bytes passed to `push()`. Each client gets the newest
    frame, never a backlog, so a slow link drops frames instead of lagging."""

    def __init__(self, port: int = 8081, host: str = "0.0.0.0", boundary: str = "frame") -> None:
        self.boundary = boundary
        self._frame: Optional[bytes] = None
        self._seq = 0
        self._cond = threading.Condition()
        self._closed = False
        self.clients = 0
        srv = self

        class Handler(BaseHTTPRequestHandler):
            def log_message(self, *_: Any) -> None:  # quiet
                pass

            def do_GET(self) -> None:  # noqa: N802
                if self.path.startswith("/snapshot"):
                    f = srv._wait(-1, 2.0)
                    if f is None:
                        self.send_error(503, "no frame yet")
                        return
                    self.send_response(200)
                    self.send_header("Content-Type", "image/jpeg")
                    self.send_header("Content-Length", str(len(f[1])))
                    self.end_headers()
                    self.wfile.write(f[1])
                    return
                if not self.path.startswith("/stream"):
                    self.send_error(404)
                    return
                self.send_response(200)
                self.send_header("Content-Type", f"multipart/x-mixed-replace; boundary={srv.boundary}")
                self.send_header("Cache-Control", "no-cache")
                self.end_headers()
                with srv._cond:
                    srv.clients += 1
                seq = -1
                try:
                    while not srv._closed:
                        f = srv._wait(seq, 2.0)
                        if f is None:
                            continue
                        seq, jpeg = f
                        self.wfile.write(
                            f"--{srv.boundary}\r\nContent-Type: image/jpeg\r\nContent-Length: {len(jpeg)}\r\n\r\n".encode() + jpeg + b"\r\n"
                        )
                        self.wfile.flush()
                except (BrokenPipeError, ConnectionResetError, OSError):
                    pass
                finally:
                    with srv._cond:
                        srv.clients -= 1

        self._http = ThreadingHTTPServer((host, port), Handler)
        self._http.daemon_threads = True
        self.port = self._http.server_address[1]
        threading.Thread(target=self._http.serve_forever, daemon=True, name="koebelt-mjpeg").start()

    @property
    def url(self) -> str:
        """Port and path, for `Device.video()`; the app adds this machine's IP."""
        return f":{self.port}/stream"

    def push(self, jpeg: bytes) -> None:
        with self._cond:
            self._frame = bytes(jpeg)
            self._seq += 1
            self._cond.notify_all()

    def _wait(self, after: int, timeout: float):
        with self._cond:
            if self._seq == after or self._frame is None:
                self._cond.wait(timeout)
            if self._frame is None or self._seq == after:
                return None
            return self._seq, self._frame

    def close(self) -> None:
        self._closed = True
        with self._cond:
            self._cond.notify_all()
        self._http.shutdown()
        self._http.server_close()


def camera(dev: Any, source: Any = 0, *, port: int = 8081, fps: float = 15, width: int = 640, quality: int = 80,
           label: Optional[str] = None) -> MjpegServer:
    """Stream a camera with OpenCV (`pip install "koebelt-link[camera]"`):
    a USB webcam index, a device path, or any URL OpenCV opens. Frames are
    only grabbed and encoded while the app is watching."""
    try:
        import cv2  # type: ignore
    except ImportError as e:  # pragma: no cover
        raise ImportError('camera() needs OpenCV: pip install "koebelt-link[camera]"') from e
    srv = MjpegServer(port)
    dev.video(srv.url, label=label)

    def run() -> None:
        cap = cv2.VideoCapture(source)
        cap.set(cv2.CAP_PROP_FRAME_WIDTH, width)
        while not srv._closed:
            t0 = time.monotonic()
            if srv.clients == 0:
                time.sleep(0.2)
                continue
            ok, frame = cap.read()
            if ok:
                ok, buf = cv2.imencode(".jpg", frame, [cv2.IMWRITE_JPEG_QUALITY, quality])
                if ok:
                    srv.push(buf.tobytes())
            time.sleep(max(0.0, 1.0 / fps - (time.monotonic() - t0)))
        cap.release()

    threading.Thread(target=run, daemon=True, name="koebelt-camera").start()
    return srv


__all__ = ["MjpegServer", "camera"]
