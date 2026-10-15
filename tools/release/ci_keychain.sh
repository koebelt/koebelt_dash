#!/usr/bin/env bash
# CI only: imports a signing certificate (base64 .p12 in $P12_BASE64, password
# in $P12_PASSWORD) into a temporary keychain that codesign can use without a
# prompt, and writes the App Store Connect API key to where xcrun tools look.
set -euo pipefail
keychain="$RUNNER_TEMP/release.keychain-db"
kpass=$(openssl rand -hex 16)
security create-keychain -p "$kpass" "$keychain"
security set-keychain-settings -lut 21600 "$keychain"
security unlock-keychain -p "$kpass" "$keychain"
echo "$P12_BASE64" | base64 --decode > "$RUNNER_TEMP/cert.p12"
security import "$RUNNER_TEMP/cert.p12" -k "$keychain" -P "$P12_PASSWORD" -T /usr/bin/codesign -T /usr/bin/security
rm "$RUNNER_TEMP/cert.p12"
security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$kpass" "$keychain" >/dev/null
security list-keychains -d user -s "$keychain" $(security list-keychains -d user | tr -d '"')
security find-identity -v -p codesigning "$keychain"

if [ -n "${ASC_KEY_P8_BASE64:-}" ]; then
  mkdir -p ~/.appstoreconnect/private_keys
  echo "$ASC_KEY_P8_BASE64" | base64 --decode > ~/.appstoreconnect/private_keys/AuthKey_$ASC_KEY_ID.p8
  echo "ASC_KEY_PATH=$HOME/.appstoreconnect/private_keys/AuthKey_$ASC_KEY_ID.p8" >> "$GITHUB_ENV"
fi
