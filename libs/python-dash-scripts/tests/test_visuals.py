import base64
import struct
import zlib

import pytest

import koebelt_dash_scripts as k
from koebelt_dash_scripts import client
from koebelt_dash_scripts.visuals import chart_message, encode_image


def _png(w, h):
    """A tiny valid PNG, without imaging packages."""
    def chunk(t, d):
        return struct.pack(">I", len(d)) + t + d + struct.pack(">I", zlib.crc32(t + d) & 0xFFFFFFFF)
    raw = b"".join(b"\x00" + b"\x80\x80\x80" * w for _ in range(h))
    return (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress(raw)) + chunk(b"IEND", b""))


class _Dev(client.Device):
    """A Device that keeps what it would send."""
    def __init__(self):
        self.sent = []
        self._shown = {}

    def _send(self, msg):
        self.sent.append(msg)


def test_png_bytes_as_they_are_with_their_size():
    data, w, h = encode_image(_png(7, 5))
    assert (w, h) == (7, 5) and data[:4] == b"\x89PNG"


def test_what_cannot_be_shown_says_so():
    with pytest.raises(k.ScriptError) as e:
        encode_image(b"hello")
    assert e.value.code == "E0711"
    with pytest.raises(k.ScriptError) as e:
        encode_image("frame.png")
    assert e.value.code == "E0711"


def test_show_sends_a_picture_and_skips_calls_too_close_together():
    d = _Dev()
    assert d.show("tracking", _png(4, 3)) is True
    assert d.show("tracking", _png(4, 3)) is False   # within 1/15 s
    assert d.show("other", _png(2, 2)) is True       # per name
    m = d.sent[0]
    assert m["t"] == "view" and m["kind"] == "picture" and m["name"] == "tracking"
    assert (m["w"], m["h"]) == (4, 3) and base64.b64decode(m["data"])[:4] == b"\x89PNG"


def test_numpy_pictures():
    np = pytest.importorskip("numpy")
    if not any(_has(m) for m in ("cv2", "PIL")):
        pytest.skip("needs OpenCV or Pillow")
    img = np.zeros((480, 1280, 3), dtype=np.uint8)
    data, w, h = encode_image(img, max_size=640)
    assert data[:2] == b"\xff\xd8" and (w, h) == (640, 240)
    data, w, h = encode_image(np.ones((10, 20)))       # grey floats 0–1
    assert (w, h) == (20, 10)
    with pytest.raises(k.ScriptError):
        encode_image(np.zeros((4, 4, 2)))


def test_matplotlib_figures():
    plt = pytest.importorskip("matplotlib.pyplot")
    fig = plt.figure(figsize=(4, 3))
    plt.plot([1, 2, 3])
    data, w, h = encode_image(fig)
    assert data[:4] == b"\x89PNG" and w > 0 and h > 0


def _has(m):
    try:
        __import__(m)
        return True
    except ImportError:
        return False


def test_charts():
    m = chart_message("scan", [1, 2, None, float("nan"), 3], x=[0, 1, 2, 3, 4], kind="scatter", xlabel="deg")
    assert m == {"t": "view", "name": "scan", "kind": "chart", "chart": "scatter",
                 "series": {"scan": [1.0, 2.0, None, None, 3.0]}, "x": [0.0, 1.0, 2.0, 3.0, 4.0], "xlabel": "deg"}
    m = chart_message("cells", {"volts": [3.9, 4.0], "min": [3.5, 3.5]}, kind="bar")
    assert list(m["series"]) == ["volts", "min"]
    assert len(chart_message("long", list(range(20000)))["series"]["long"]) == 5000
    for bad in ({"y": [1], "kind": "pie"}, {"y": ["a", "b"]}, {"y": {}}, {"y": {str(i): [1] for i in range(9)}}):
        with pytest.raises(k.ScriptError) as e:
            chart_message("c", bad["y"], kind=bad.get("kind", "line"))
        assert e.value.code == "E0712"


def test_plot_one_value_or_several_series():
    d = _Dev()
    d.plot("alt", 3)
    d.plot("speed", target=2, actual=1.5)
    d.plot("err", 0.1, limit=0.5)
    assert d.sent[0] == {"t": "plot", "name": "alt", "v": 3.0}
    assert d.sent[1] == {"t": "plot", "name": "speed", "v": [2.0, 1.5], "labels": ["target", "actual"]}
    assert d.sent[2] == {"t": "plot", "name": "err", "v": [0.1, 0.5], "labels": ["err", "limit"]}
    with pytest.raises(k.ScriptError) as e:
        d.plot("nothing")
    assert e.value.code == "E0713"
