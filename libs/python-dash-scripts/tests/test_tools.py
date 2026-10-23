import math

from koebelt_dash_scripts import angle_diff, bearing, clamp, distance, geo_bearing, geo_distance, lowpass, pid, rate_limit


def test_pid_proportional_and_clamped():
    c = pid(2.0)
    assert c.update(0.25, dt=0.1) == 0.5
    assert c.update(5, dt=0.1) == 1.0


def test_pid_integral_does_not_wind_up_while_clamped():
    c = pid(1.0, ki=1.0)
    for _ in range(100):
        c.update(10, dt=0.1)
    assert c.integral < 1.0
    assert c.update(-0.5, dt=0.1) < 0.5


def test_pid_derivative():
    c = pid(0, kd=1.0, limit=100)
    c.update(0, dt=0.1)
    assert math.isclose(c.update(1, dt=0.1), 10)


def test_lowpass_converges():
    f = lowpass(5)
    f.update(0, dt=0.01)
    for _ in range(200):
        y = f.update(1, dt=0.01)
    assert 0.99 < y <= 1


def test_rate_limit():
    r = rate_limit(1.0)
    assert math.isclose(r.update(1, dt=0.25), 0.25)
    assert math.isclose(r.update(-1, dt=0.1), 0.15)


def test_geometry():
    assert clamp(3) == 1 and clamp(-3) == -1
    assert distance((3, 4)) == 5
    assert bearing((0, 0), (0, 10)) == 0
    assert bearing((0, 0), (10, 0)) == 90
    assert bearing((0, 0), (-10, 0)) == 270
    assert angle_diff(10, 350) == 20
    assert angle_diff(350, 10) == -20
    # One degree of latitude is about 111 km; due east is 90°.
    assert 111_000 < geo_distance(45, 6, 46, 6) < 111_400
    assert round(geo_bearing(0, 0, 0, 1)) == 90


def test_the_examples_compile():
    import pathlib
    import py_compile

    for f in sorted(pathlib.Path(__file__).parent.parent.joinpath("examples").glob("*.py")):
        py_compile.compile(str(f), doraise=True)
