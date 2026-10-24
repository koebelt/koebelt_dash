"""Pictures and charts for dash's Live view: what Device.show() and
Device.chart() send."""
from __future__ import annotations

import io
from typing import Any, Dict, List, Optional, Tuple

from .errors import ScriptError

#: Chart kinds dash draws.
CHART_KINDS = ("line", "bar", "scatter")

#: Points per series dash keeps; longer ones are thinned evenly.
MAX_POINTS = 5000


def _size_of(data: bytes) -> Tuple[int, int]:
    """Width and height of JPEG or PNG bytes (0, 0 if unsure)."""
    if data[:8] == b"\x89PNG\r\n\x1a\n" and len(data) >= 24:
        return int.from_bytes(data[16:20], "big"), int.from_bytes(data[20:24], "big")
    if data[:2] == b"\xff\xd8":
        i = 2
        while i + 9 < len(data):
            if data[i] != 0xFF:
                break
            marker, length = data[i + 1], int.from_bytes(data[i + 2:i + 4], "big")
            if marker in (0xC0, 0xC1, 0xC2):
                return int.from_bytes(data[i + 7:i + 9], "big"), int.from_bytes(data[i + 5:i + 7], "big")
            i += 2 + length
    return 0, 0


def _uint8(a: Any) -> Any:
    """A numpy image as uint8: floats in 0–1 are scaled to 0–255."""
    import numpy as np
    if a.dtype == np.uint8:
        return a
    a = a.astype("float64")
    if a.size and float(np.nanmax(a)) <= 1.0:
        a = a * 255.0
    return np.clip(np.nan_to_num(a), 0, 255).astype(np.uint8)


def encode_image(image: Any, quality: int = 80, max_size: int = 960) -> Tuple[bytes, int, int]:
    """JPEG (or PNG) bytes of ``image``, its largest side at most
    ``max_size``, and its width and height.

    ``image``: a numpy array (BGR or grey, as OpenCV makes them), a PIL image,
    a matplotlib figure, or JPEG or PNG bytes as they are."""
    if isinstance(image, (bytes, bytearray, memoryview)):
        data = bytes(image)
        if data[:2] != b"\xff\xd8" and data[:8] != b"\x89PNG\r\n\x1a\n":
            raise ScriptError("E0711", {"what": "these bytes", "reason": "they are not a JPEG or a PNG"})
        w, h = _size_of(data)
        return data, w, h
    if hasattr(image, "savefig"):  # a matplotlib figure
        buf = io.BytesIO()
        w_in, h_in = image.get_size_inches()
        dpi = min(100.0, max_size / max(w_in, h_in, 0.1))
        image.savefig(buf, format="png", dpi=dpi, facecolor=image.get_facecolor())
        data = buf.getvalue()
        w, h = _size_of(data)
        return data, w, h
    if hasattr(image, "shape") and hasattr(image, "dtype"):  # numpy
        a = _uint8(image)
        if a.ndim == 3 and a.shape[2] == 4:
            a = a[:, :, :3]
        if a.ndim not in (2, 3) or (a.ndim == 3 and a.shape[2] != 3):
            raise ScriptError("E0711", {"what": f"an array of shape {tuple(image.shape)}", "reason": "an image is H×W (grey) or H×W×3 (BGR)"})
        h, w = a.shape[:2]
        scale = min(1.0, max_size / max(w, h, 1))
        try:
            import cv2
            if scale < 1:
                a = cv2.resize(a, (max(1, int(w * scale)), max(1, int(h * scale))), interpolation=cv2.INTER_AREA)
            ok, buf = cv2.imencode(".jpg", a, [cv2.IMWRITE_JPEG_QUALITY, int(quality)])
            if ok:
                return buf.tobytes(), a.shape[1], a.shape[0]
        except ImportError:
            pass
        try:
            from PIL import Image
        except ImportError:
            raise ScriptError("E0711", {"what": "a numpy image", "reason": "encoding it needs OpenCV or Pillow"}) from None
        image = Image.fromarray(a[:, :, ::-1] if a.ndim == 3 else a)
    if hasattr(image, "mode") and hasattr(image, "save"):  # PIL
        im = image.convert("RGB") if image.mode not in ("RGB", "L") else image
        if max(im.size) > max_size:
            im = im.copy()
            im.thumbnail((max_size, max_size))
        buf = io.BytesIO()
        im.save(buf, format="JPEG", quality=int(quality))
        return buf.getvalue(), im.size[0], im.size[1]
    raise ScriptError("E0711", {"what": type(image).__name__, "reason": "show() takes a numpy image, a PIL image, a matplotlib figure, or JPEG/PNG bytes"})


def _numbers(name: str, values: Any) -> List[Optional[float]]:
    """A series as a list of floats (None for gaps), thinned to MAX_POINTS."""
    if hasattr(values, "tolist"):
        values = values.tolist()
    try:
        out = [None if v is None else float(v) for v in values]
    except (TypeError, ValueError):
        raise ScriptError("E0712", {"what": name, "reason": "a series is a list of numbers"}) from None
    out = [None if v is not None and v != v else v for v in out]  # NaN: a gap
    if len(out) > MAX_POINTS:
        step = len(out) / MAX_POINTS
        out = [out[int(i * step)] for i in range(MAX_POINTS)]
    return out


def chart_message(name: str, y: Any, x: Any = None, kind: str = "line", xlabel: str = "", ylabel: str = "") -> Dict[str, Any]:
    """The `view` message of a chart: ``y`` a list of numbers or a dict of
    named lists, ``x`` their x values (else 0, 1, 2…)."""
    if kind not in CHART_KINDS:
        raise ScriptError("E0712", {"what": name, "reason": f"kind is “{kind}”; it is line, bar or scatter"})
    if isinstance(y, dict):
        if not y:
            raise ScriptError("E0712", {"what": name, "reason": "no series"})
        if len(y) > 8:
            raise ScriptError("E0712", {"what": name, "reason": f"{len(y)} series; dash draws up to 8"})
        series = {str(k): _numbers(str(k), v) for k, v in y.items()}
    else:
        series = {name: _numbers(name, y)}
    msg: Dict[str, Any] = {"t": "view", "name": name, "kind": "chart", "chart": kind, "series": series}
    if x is not None:
        msg["x"] = _numbers("x", x)
    if xlabel:
        msg["xlabel"] = str(xlabel)
    if ylabel:
        msg["ylabel"] = str(ylabel)
    return msg
