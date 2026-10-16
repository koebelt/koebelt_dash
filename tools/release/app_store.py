#!/usr/bin/env python3
"""Prepares an App Store version of koebelt dash from a release, through the
App Store Connect API (the key that setup_apple.py keeps in
~/Documents/koebelt-release-keys).

    python3 tools/release/app_store.py 1.2.0                     # show what it would do
    python3 tools/release/app_store.py 1.2.0 --apply             # create the version, fill it
    python3 tools/release/app_store.py 1.2.0 --apply --shots DIR # and replace the screenshots
    python3 tools/release/app_store.py 1.2.0 --submit            # then send it for review

It creates the version (released by hand after approval), sets "What's New"
from tools/release/app-notes/X.Y.Z.store.md and X.Y.Z.store.fr.md (the App
Store notes: iPhone and iPad have no in-app updater, so the GitHub notes in
X.Y.Z.md may not fit; they are the fallback), attaches the TestFlight build of that version and, with --shots,
replaces the screenshots with the ones test/store_screenshots_test.dart
renders. The listing text, categories, age rating, price and review contact
carry over from the previous version. Submitting is a separate, explicit step.

Apple allows one version in preparation at a time: while one is in review,
wait for it before preparing the next.
"""
import argparse
import hashlib
import importlib.util
import pathlib
import re
import sys
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[2]
BUNDLE_ID = "com.koebelt.dash"
SHOT_TYPES = {"iphone": "APP_IPHONE_67", "ipad": "APP_IPAD_PRO_3GEN_129"}

# The API client from setup_apple.py (it sets up the cryptography package).
spec = importlib.util.spec_from_file_location("setup_apple", ROOT / "tools/release/setup_apple.py")
argv, sys.argv = sys.argv, [sys.argv[0]]
setup_apple = importlib.util.module_from_spec(spec)
spec.loader.exec_module(setup_apple)
sys.argv = argv


def api():
    keys = setup_apple.KEYS_DIR
    key = next(keys.glob("AuthKey_*.p8"), None)
    if key is None or not (keys / "issuer-id.txt").exists():
        raise SystemExit(f"No App Store Connect key in {keys}: run tools/release/setup_apple.py first.")
    return setup_apple.Api(key, key.stem.removeprefix("AuthKey_"), (keys / "issuer-id.txt").read_text().strip())


def whats_new(md: str) -> str:
    """Release notes (Markdown) as App Store text: headings and bullets kept, tables and links' targets dropped."""
    out = []
    for line in md.splitlines():
        s = line.rstrip()
        if s.lstrip().startswith("|"):
            continue
        s = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", s).replace("**", "").replace("`", "")
        if s.startswith("#"):
            s = re.sub(r"^#+\s*", "", s).upper()
        elif re.match(r"^\s*[-*]\s", s):
            s = "• " + re.sub(r"^\s*[-*]\s+", "", s)
        out.append(s)
    text = re.sub(r"\n{3,}", "\n\n", "\n".join(out)).strip()
    return text[:4000]


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("version")
    ap.add_argument("--apply", action="store_true", help="create and fill the version (default: only show what would change)")
    ap.add_argument("--shots", help="folder of iphone_*.png and ipad_*.png to replace the screenshots with")
    ap.add_argument("--submit", action="store_true", help="send the prepared version for review")
    a = ap.parse_args()
    a.apply = a.apply or a.submit
    c = api()

    def get(path, **q):
        return c.call("GET", path, query=q or None)

    def do(method, path, data, what):
        if not a.apply:
            print(f"would {what}")
            return None
        r = c.call(method, path, data)
        print(f"done: {what}")
        return r

    app = get("apps", **{"filter[bundleId]": BUNDLE_ID})["data"][0]
    aid = app["id"]
    versions = get(f"apps/{aid}/appStoreVersions", **{"filter[platform]": "IOS"})["data"]
    v = next((x for x in versions if x["attributes"]["versionString"] == a.version), None)
    busy = [x for x in versions if x is not v and x["attributes"]["appStoreState"] in ("WAITING_FOR_REVIEW", "IN_REVIEW", "PREPARE_FOR_SUBMISSION")]
    if v is None and busy:
        b = busy[0]["attributes"]
        raise SystemExit(f"{b['versionString']} is {b['appStoreState'].lower().replace('_', ' ')}; Apple allows one version in preparation at a time. Try again once it is through.")

    # 1. The version
    if v is None:
        r = do("POST", "appStoreVersions", {"type": "appStoreVersions", "attributes": {"platform": "IOS", "versionString": a.version, "releaseType": "MANUAL"},
               "relationships": {"app": {"data": {"type": "apps", "id": aid}}}}, f"create App Store version {a.version}")
        if r is None:
            print("(the remaining steps run on the new version with --apply)")
            return
        v = r["data"]
    vid = v["id"]
    print(f"version {a.version}: {v['attributes'].get('appStoreState', 'new')}")

    # 2. What's New, per language
    d = ROOT / "tools/release/app-notes"
    notes = next((f for f in (d / f"{a.version}.store.md", d / f"{a.version}.md") if f.exists()), None)
    if notes is None:
        raise SystemExit(f"No release notes for {a.version} in {d.relative_to(ROOT)}.")
    texts = {"en-US": whats_new(notes.read_text())}
    fr = d / f"{a.version}.store.fr.md"
    texts["fr-FR"] = whats_new(fr.read_text()) if fr.exists() else texts["en-US"]
    for loc in get(f"appStoreVersions/{vid}/appStoreVersionLocalizations")["data"]:
        locale = loc["attributes"]["locale"]
        if locale in texts:
            do("PATCH", f"appStoreVersionLocalizations/{loc['id']}", {"type": "appStoreVersionLocalizations", "id": loc["id"], "attributes": {"whatsNew": texts[locale]}},
               f"set What's New ({locale}, {len(texts[locale])} characters, from {(fr if locale == 'fr-FR' and fr.exists() else notes).name})")

    # 3. The build
    builds = get("builds", **{"filter[app]": aid, "filter[preReleaseVersion.version]": a.version, "filter[processingState]": "VALID", "sort": "-uploadedDate", "limit": "1"})["data"]
    if not builds:
        raise SystemExit(f"No processed TestFlight build of {a.version} yet: wait for Apple's processing after the release workflow uploads it.")
    build = builds[0]
    do("PATCH", f"appStoreVersions/{vid}/relationships/build", {"type": "builds", "id": build["id"]}, f"attach build {build['attributes']['version']}")

    # 4. Screenshots (the primary language; others fall back to it)
    if a.shots:
        folder = pathlib.Path(a.shots)
        loc = next(l for l in get(f"appStoreVersions/{vid}/appStoreVersionLocalizations")["data"] if l["attributes"]["locale"] == app["attributes"]["primaryLocale"])
        sets = {s["attributes"]["screenshotDisplayType"]: s["id"] for s in get(f"appStoreVersionLocalizations/{loc['id']}/appScreenshotSets")["data"]}
        for prefix, kind in SHOT_TYPES.items():
            files = sorted(folder.glob(f"{prefix}_*.png"))
            if not files:
                continue
            if not a.apply:
                print(f"would replace the {prefix} screenshots with {len(files)} from {folder}")
                continue
            if kind in sets:
                for old in get(f"appScreenshotSets/{sets[kind]}/appScreenshots")["data"]:
                    c.call("DELETE", f"appScreenshots/{old['id']}")
            else:
                sets[kind] = c.call("POST", "appScreenshotSets", {"type": "appScreenshotSets", "attributes": {"screenshotDisplayType": kind},
                                    "relationships": {"appStoreVersionLocalization": {"data": {"type": "appStoreVersionLocalizations", "id": loc["id"]}}}})["data"]["id"]
            for f in files:
                data = f.read_bytes()
                r = c.call("POST", "appScreenshots", {"type": "appScreenshots", "attributes": {"fileName": f.name, "fileSize": len(data)},
                           "relationships": {"appScreenshotSet": {"data": {"type": "appScreenshotSets", "id": sets[kind]}}}})["data"]
                for op in r["attributes"]["uploadOperations"]:
                    req = urllib.request.Request(op["url"], method=op["method"], data=data[op["offset"]:op["offset"] + op["length"]],
                                                 headers={h["name"]: h["value"] for h in op["requestHeaders"]})
                    urllib.request.urlopen(req).read()
                c.call("PATCH", f"appScreenshots/{r['id']}", {"type": "appScreenshots", "id": r["id"], "attributes": {"uploaded": True, "sourceFileChecksum": hashlib.md5(data).hexdigest()}})
            print(f"done: {len(files)} {prefix} screenshots")

    # 5. Review, only when asked
    if a.submit:
        sub = c.call("POST", "reviewSubmissions", {"type": "reviewSubmissions", "attributes": {"platform": "IOS"}, "relationships": {"app": {"data": {"type": "apps", "id": aid}}}})["data"]
        c.call("POST", "reviewSubmissionItems", {"type": "reviewSubmissionItems", "relationships": {
            "reviewSubmission": {"data": {"type": "reviewSubmissions", "id": sub["id"]}}, "appStoreVersion": {"data": {"type": "appStoreVersions", "id": vid}}}})
        c.call("PATCH", f"reviewSubmissions/{sub['id']}", {"type": "reviewSubmissions", "id": sub["id"], "attributes": {"submitted": True}})
        print(f"submitted {a.version} for review")
    elif a.apply:
        print("Ready. Check it in App Store Connect, then run again with --submit.")


if __name__ == "__main__":
    try:
        main()
    except setup_apple.Refused as e:
        raise SystemExit(str(e))
