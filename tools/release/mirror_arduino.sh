#!/usr/bin/env bash
# Copies libs/arduino/KoebeltLink into a checkout of github.com/koebelt/KoebeltLink
# (the Arduino Library Manager reads library.properties at a repository's root)
# and commits it there. With a version, also tags that commit, which is what
# the Library Manager picks up.
#
#   tools/release/mirror_arduino.sh <KoebeltLink checkout> [version]
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
src="$here/../../libs/arduino/KoebeltLink"
dst=$1
version=${2:-}
rev=$(git -C "$here" rev-parse --short HEAD)

# The host tests build against the monorepo's protocol/ folder; they stay there.
rsync -a --delete --exclude .git --exclude test "$src/" "$dst/"
cd "$dst"
git add -A
if ! git diff --cached --quiet; then
  git commit -q -m "KoebeltLink ${version:-$(sed -n 's/^version=//p' library.properties)}" -m "From koebelt/koebelt_dash@$rev, libs/arduino/KoebeltLink."
fi
if [ -n "$version" ]; then git tag "$version"; fi
git log --oneline -1
