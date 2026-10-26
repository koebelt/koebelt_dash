import math

import pytest

from koebelt_link_ros.convert import control_to_twist, downsample, parse_fallback, parse_transport, quat_to_rpy, range_metres, topic_values


def test_quat_to_rpy():
    s = math.sin(math.pi / 4)
    r, p, y = quat_to_rpy(0, 0, s, s)  # 90° yaw
    assert abs(r) < 1e-9 and abs(p) < 1e-9 and abs(y - math.pi / 2) < 1e-9


def test_downsample():
    pts = [(i, 0, 0) for i in range(10000)] + [(float("nan"), 0, 0)]
    out = downsample(pts, 2000)
    assert len(out) == 2000 and all(math.isfinite(p[0]) for p in out)


def test_transport():
    assert parse_transport("serial:/dev/ttyUSB0") == {"serial": "/dev/ttyUSB0"}
    assert parse_transport("wifi") == {"wifi": True}
    assert parse_transport("radio:/dev/ttyUSB1") == {"radio": ("/dev/ttyUSB1", "sik")}
    assert parse_transport("radio:/dev/ttyUSB1:hc12") == {"radio": ("/dev/ttyUSB1", "hc12")}
    assert parse_fallback("radio:/dev/ttyUSB1:lora") == {"radio": ("/dev/ttyUSB1", "lora")}
    with pytest.raises(ValueError):
        parse_transport("carrier-pigeon")
    with pytest.raises(ValueError):
        parse_fallback("ble")


def test_twist():
    lin, ang = control_to_twist(1, -1, 0.5, 2.0, 1.5)
    assert lin == 2.0 and ang == 1.5


def test_topic_values():
    class Arr:
        data = [1, 2.5]

    class Temp:
        temperature = 41.5

    assert topic_values(Arr(), 3) == [1.0, 2.5, 0.0]
    assert topic_values(Temp(), 1) == [41.5]


def test_range_as_proximity():
    assert range_metres(0.42, 0.02, 4.0) == 0.42
    assert range_metres(math.inf, 0.02, 4.0) is None      # nothing detected
    assert range_metres(-math.inf, 0.02, 4.0) == 0.02     # triggered, closer than it can tell
    assert range_metres(float("nan"), 0.02, 4.0) is None  # invalid
    assert range_metres(5.0, 0.02, 4.0) is None           # out of range

