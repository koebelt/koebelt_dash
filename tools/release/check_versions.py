#!/usr/bin/env python3
"""Checks that every koebelt/link library carries the same version.

    python3 tools/release/check_versions.py          # prints the version
    python3 tools/release/check_versions.py 1.0.0    # also checks it is 1.0.0
"""
import json
import pathlib
import re
import sys

root = pathlib.Path(__file__).resolve().parents[2]


def find(path, pattern):
    m = re.search(pattern, (root / path).read_text(), re.M)
    return m.group(1) if m else None


versions = {
    "libs/python/pyproject.toml": find("libs/python/pyproject.toml", r'^version = "([^"]+)"'),
    "libs/python/koebelt_link/__init__.py": find("libs/python/koebelt_link/__init__.py", r'^__version__ = "([^"]+)"'),
    "libs/rust/Cargo.toml": find("libs/rust/Cargo.toml", r'^version = "([^"]+)"'),
    "libs/arduino/KoebeltLink/library.properties": find("libs/arduino/KoebeltLink/library.properties", r"^version=(\S+)"),
    "libs/arduino/KoebeltLink/library.json": json.loads((root / "libs/arduino/KoebeltLink/library.json").read_text())["version"],
    "libs/arduino/KoebeltLink/src/KoebeltLink.h": find("libs/arduino/KoebeltLink/src/KoebeltLink.h", r'KOEBELT_LINK_VERSION "([^"]+)"'),
    "libs/ros2/koebelt_link_ros/package.xml": find("libs/ros2/koebelt_link_ros/package.xml", r"<version>([^<]+)</version>"),
    "libs/ros2/koebelt_link_ros/setup.py": find("libs/ros2/koebelt_link_ros/setup.py", r'version="([^"]+)"'),
}
want = sys.argv[1] if len(sys.argv) > 1 else versions["libs/python/pyproject.toml"]
bad = {f: v for f, v in versions.items() if v != want}
if bad:
    for f, v in bad.items():
        print(f"{f}: {v}, expected {want}", file=sys.stderr)
    sys.exit(1)
print(want)
