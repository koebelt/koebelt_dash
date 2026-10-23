import http.server
import threading

import pytest

from koebelt_dash_scripts import Camera
from koebelt_dash_scripts.camera import boxes_of

FRAMES = [b"\xff\xd8frame-one\xff\xd9", b"\x89PNGframe-two-with\r\n--fake boundary inside", b"\xff\xd8three\xff\xd9"]


class _Handler(http.server.BaseHTTPRequestHandler):
    with_length = True

    def log_message(self, *a):
        pass

    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-Type", "multipart/x-mixed-replace; boundary=kdashframe")
        self.end_headers()
        for f in FRAMES:
            head = "--kdashframe\r\nContent-Type: image/jpeg\r\n"
            if self.with_length:
                head += f"Content-Length: {len(f)}\r\n"
            self.wfile.write(head.encode() + b"\r\n" + f + b"\r\n")
        self.wfile.write(b"--kdashframe--\r\n")
        self.wfile.flush()


@pytest.fixture(params=[True, False], ids=["with length", "boundary only"])
def stream(request):
    handler = type("H", (_Handler,), {"with_length": request.param})
    srv = http.server.ThreadingHTTPServer(("127.0.0.1", 0), handler)
    threading.Thread(target=srv.serve_forever, daemon=True).start()
    yield f"http://127.0.0.1:{srv.server_address[1]}/stream", request.param
    srv.shutdown()


def test_reads_multipart_frames_whatever_their_type(stream):
    url, with_length = stream
    cam = Camera({"id": "cam", "url": url, "fmt": "mjpeg", "label": "FPV"})
    seen = []
    publish = cam._publish
    cam._publish = lambda data: (seen.append(data), publish(data))
    cam.jpeg(timeout=2)
    for _ in range(100):
        if len(seen) >= 3:
            break
        threading.Event().wait(0.02)
    cam.close()
    assert cam.jpeg() in FRAMES, "keeps the newest"
    if with_length:
        # Content-Length keeps a frame whole even with a boundary-like text inside.
        assert FRAMES[1] in seen
    assert FRAMES[0] in seen and FRAMES[2] in seen


def test_a_camera_without_a_url():
    with pytest.raises(RuntimeError) as e:
        Camera({"id": "cam", "url": None}).jpeg(timeout=0.1)
    assert e.value.code == "E0602" and "address" in e.value.why


class _T:
    def __init__(self, v):
        self.v = v

    def tolist(self):
        return self.v


class _Boxes:
    xyxyn = _T([[0.1, 0.2, 0.3, 0.6]])
    cls = _T([0.0])
    conf = _T([0.912])


class _Result:
    boxes = _Boxes()
    names = {0: "person"}


def test_boxes_from_tuples_pixels_and_ultralytics():
    assert boxes_of([(0.1, 0.2, 0.3, 0.4)]) == [[0.1, 0.2, 0.3, 0.4, ""]]
    assert boxes_of([(64, 48, 32, 24, "ball")], width=640, height=480) == [[0.1, 0.1, 0.05, 0.05, "ball"]]
    b = boxes_of(_Result())
    assert b[0][4] == "person 0.91" and [round(v, 6) for v in b[0][:4]] == [0.1, 0.2, 0.2, 0.4]
    assert boxes_of([_Boxes()])[0][4] == "0 0.91"
