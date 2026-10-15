#!/usr/bin/env bash
# Packages the macOS app as a .dmg. With a Developer ID identity in the
# keychain and an App Store Connect API key, it signs with the hardened
# runtime, notarizes and staples; without them it makes an unsigned .dmg
# (for checking the packaging).
#
#   tools/release/macos_dmg.sh "<koebelt dash.app>" <out.dmg>
#
# Environment for a signed build:
#   MAC_SIGN_IDENTITY   e.g. "Developer ID Application: Thomas Koebel (TEAMID)"
#   ASC_KEY_PATH, ASC_KEY_ID, ASC_ISSUER_ID   App Store Connect API key (notarization)
set -euo pipefail
app=$1
out=$2
here=$(cd "$(dirname "$0")" && pwd)
entitlements="$here/../../apps/dash/macos/Runner/Release.entitlements"
identity=${MAC_SIGN_IDENTITY:-}

if [ -n "$identity" ]; then
  # Inside out: nested frameworks and libraries first, then the app with its
  # sandbox entitlements. --options runtime is the hardened runtime that
  # notarization requires.
  find "$app/Contents/Frameworks" -depth \( -name "*.framework" -o -name "*.dylib" \) -print0 |
    while IFS= read -r -d '' f; do
      codesign --force --timestamp --options runtime --sign "$identity" "$f"
    done
  codesign --force --timestamp --options runtime --entitlements "$entitlements" --sign "$identity" "$app"
  codesign --verify --deep --strict --verbose=2 "$app"
fi

stage=$(mktemp -d)
trap 'rm -rf "$stage"' EXIT
ditto "$app" "$stage/$(basename "$app")"
ln -s /Applications "$stage/Applications"
rm -f "$out"
hdiutil create -quiet -volname "koebelt dash" -srcfolder "$stage" -fs HFS+ -format UDZO "$out"

if [ -n "$identity" ]; then
  codesign --force --timestamp --sign "$identity" "$out"
  xcrun notarytool submit "$out" --key "$ASC_KEY_PATH" --key-id "$ASC_KEY_ID" --issuer "$ASC_ISSUER_ID" --wait --timeout 30m
  xcrun stapler staple "$out"
  spctl --assess --type open --context context:primary-signature --verbose=2 "$out"
fi
echo "$out"
