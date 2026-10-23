"""Errors read like Rust's: what, where in the script, why, help, docs."""
import json
import os
import subprocess
import sys
import textwrap

import pytest

import koebelt_dash_scripts as k
from koebelt_dash_scripts.errors import CATALOG, WARNINGS, ScriptError, render
from test_client import FakeDash, dash  # noqa: F401  (fixture)


def test_points_at_the_scripts_line_with_why_help_and_docs(dash):  # noqa: F811
    dev = k.connect()
    with pytest.raises(k.ScriptError) as e:
        dev.arm()
    text = render(e.value, color=False)
    lines = text.splitlines()
    assert lines[0] == "error[E0301]: arming and take-off are not allowed for this script"
    assert lines[1].strip().startswith("--> test_errors.py:")
    assert "dev.arm()" in text and "^^^^^^^^^" in text
    assert "= why: the script's limits in koebelt dash do not allow arming or take-off" in text
    assert "= help: in dash, open the script, then Limits > Allow arming and take-off" in text
    assert text.endswith("ERRORS.md#e0301")
    dev.close()


def test_suggests_the_name_you_meant(dash):  # noqa: F811
    dev = k.connect()
    with pytest.raises(k.ScriptError) as e:
        dev.sticks(throttle=0.2, pitch=1)
    assert e.value.code == "E0201"
    assert e.value.title == "“pitch” is not a stick of a rover"
    assert e.value.help.startswith("a rover has: throttle, steer")
    with pytest.raises(k.ScriptError) as e:
        dev.sticks(0.5, 0.2)
    assert e.value.code == "E0202"
    dev.close()


def test_warns_once_when_a_stick_is_out_of_range(dash, capsys):  # noqa: F811
    dev = k.connect()
    for _ in range(3):
        dev.sticks(throttle=1.7)
    err = capsys.readouterr().err
    assert err.count("warning[W0201]: throttle=1.7 is outside −1…1: dash uses 1.0") == 1
    assert dash.got[-1]["a"] == {"throttle": 1.0}
    dev.close()


def test_mistakes_caught_before_dash(dash):  # noqa: F811
    dev = k.connect()
    with pytest.raises(k.ScriptError) as e:
        dev.setting("speed", 0.4, min=1, max=0)
    assert e.value.code == "E0701" and "min (1) must be below max (0)" in e.value.title
    with pytest.raises(k.ScriptError) as e:
        dev.trigger("Go", kind="lever")
    assert e.value.code == "E0702"
    with pytest.raises(k.ScriptError) as e:
        next(k.every(0))
    assert e.value.code == "E0703"
    dev.close()


def test_every_code_is_documented():
    with open(os.path.join(os.path.dirname(__file__), "..", "ERRORS.md"), encoding="utf-8") as f:
        doc = f.read()
    for code in [*CATALOG, *WARNINGS]:
        assert f"## {code}" in doc, f"ERRORS.md has no section for {code}"


def test_an_uncaught_error_prints_rust_style_without_the_librarys_traceback(tmp_path):
    script = tmp_path / "my_script.py"
    script.write_text(textwrap.dedent('''\
        import koebelt_dash_scripts as k

        def go():
            k.connect()

        go()
    '''))
    env = dict(os.environ, HOME=str(tmp_path), NO_COLOR="1")
    env.pop("KOEBELT_DASH_URL", None)
    r = subprocess.run([sys.executable, str(script)], capture_output=True, text=True, env=env)
    assert r.returncode == 1
    assert r.stderr.startswith("error[E0010]: koebelt dash is not running on this computer")
    assert "--> my_script.py:4" in r.stderr and "k.connect()" in r.stderr
    assert "called from: my_script.py:6 <module>()" in r.stderr
    assert "Traceback" not in r.stderr and "client.py" not in r.stderr


def test_warns_when_older_than_dash(dash, capsys):  # noqa: F811
    from koebelt_dash_scripts import client
    client._check_version("9.0.0")
    assert "warning[W0102]: koebelt-dash-scripts" in capsys.readouterr().err
    client._check_version("0.1.0")
    client._check_version(k.__version__)
    assert capsys.readouterr().err == "", "not older: no warning"
    assert client._version_key("1.3.0b2") < client._version_key("1.3.0-beta.3") < client._version_key("1.3.0rc1") < client._version_key("1.3.0")
