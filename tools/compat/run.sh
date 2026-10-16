#!/usr/bin/env bash
# The app against every published koebelt/link release (PyPI and crates.io),
# not this repository's copies: a device people already run must keep working
# with each new app. Runs test/compat_published_test.dart once per version.
#
#   tools/compat/run.sh               every published version
#   tools/compat/run.sh 1.0.0         just this one
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
app="$here/../../apps/dash"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

versions() {  # $1: python | rust
  if [ $# -gt 1 ]; then echo "$2"; return; fi
  case $1 in
    python) curl -fsS https://pypi.org/pypi/koebelt-link/json | python3 -c 'import json,sys; print("\n".join(sorted(json.load(sys.stdin)["releases"])))' ;;
    rust) curl -fsS -A "koebelt-dash compat check (contact@koebelt.com)" https://crates.io/api/v1/crates/koebelt-link/versions \
      | python3 -c 'import json,sys; print("\n".join(v["num"] for v in json.load(sys.stdin)["versions"] if not v["yanked"]))' ;;
  esac
}

# Versions below the app's declared minimum (apps/dash/compat.json) are no
# longer supported on purpose, and skipped.
min() { python3 -c "import json,sys; print(json.load(open('$app/compat.json'))['minLib'].get(sys.argv[1], '0'))" "$1"; }
supported() {  # $1 family, $2 version
  python3 -c "import sys; p=lambda v:[int(x) for x in v.split('.')]; sys.exit(0 if p(sys.argv[1])>=p(sys.argv[2]) else 1)" "$2" "$(min "$1")"
}

failed=()
check() {  # $1 label, $2 command with {port}, $3 expected lib
  echo "== app vs $3"
  if (cd "$app" && KDASH_COMPAT_CMD="$2" KDASH_COMPAT_LIB="$3" flutter test test/compat_published_test.dart); then :; else failed+=("$3"); fi
}

for v in $(versions python "$@"); do
  supported python "$v" || { echo "== skip python/$v (below the app's minimum, $(min python))"; continue; }
  python3 -m venv "$work/py-$v"
  "$work/py-$v/bin/pip" install -q "koebelt-link==$v"
  check python "$work/py-$v/bin/python -m koebelt_link.sim --kind rover --port {port}" "python/$v"
done

for v in $(versions rust "$@"); do
  supported rust "$v" || { echo "== skip rust/$v (below the app's minimum, $(min rust))"; continue; }
  cp -R "$here/rust-device" "$work/rs-$v"
  sed -i.bak "s/^koebelt-link = .*/koebelt-link = \"=$v\"/" "$work/rs-$v/Cargo.toml"
  (cd "$work/rs-$v" && cargo build -q --release)
  check rust "$work/rs-$v/target/release/koebelt-compat-device {port}" "rust/$v"
done

if [ ${#failed[@]} -gt 0 ]; then
  echo "The app no longer works with: ${failed[*]}" >&2
  exit 1
fi
echo "The app works with every published koebelt/link release checked."
