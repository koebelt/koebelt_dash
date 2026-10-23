#!/usr/bin/env python3
"""Copies the docs and examples koebelt dash bundles into apps/dash/assets.

    python3 tools/assets/sync_app_assets.py

They are gzip-compressed: App Store Connect refuses an iOS app holding text
that looks like Python (an example, a README with code) as unsigned code.
The app decompresses them; apps/dash/test/script_library_test.dart checks
they match their sources.
"""
import gzip
import pathlib

ROOT = pathlib.Path(__file__).resolve().parents[2]
ASSETS = ROOT / "apps/dash/assets"

PAIRS = {
    "protocol/PROTOCOL.md": "docs/PROTOCOL.md.gz",
    "protocol/SCRIPTS.md": "docs/SCRIPTS.md.gz",
    "libs/python-dash-scripts/README.md": "docs/SCRIPTS_API.md.gz",
    **{f"libs/python-dash-scripts/examples/{p.name}": f"script_examples/{p.name}.gz"
       for p in sorted((ROOT / "libs/python-dash-scripts/examples").glob("*.py"))},
}

for d in ("docs", "script_examples"):
    for old in (ASSETS / d).glob("*"):
        old.unlink()
for src, dst in PAIRS.items():
    out = ASSETS / dst
    out.parent.mkdir(parents=True, exist_ok=True)
    # mtime 0: the same source gives the same bytes, so git sees no change.
    out.write_bytes(gzip.compress((ROOT / src).read_bytes(), mtime=0))
    print(f"{src} -> assets/{dst}")
