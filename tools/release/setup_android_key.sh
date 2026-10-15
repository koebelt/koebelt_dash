#!/usr/bin/env bash
# One-time: makes the Android upload key that signs every release APK, keeps
# it in ~/Documents/koebelt-release-keys, its password in the login keychain,
# and both as GitHub Actions secrets. Google Play needs this same key later
# (tools/release/RELEASING.md): back the folder up.
set -euo pipefail
repo=koebelt/koebelt_dash
dir="$HOME/Documents/koebelt-release-keys"
jks="$dir/android-upload.jks"
keytool=$(command -v keytool || true)
for k in "/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/keytool" "${JAVA_HOME:-/nonexistent}/bin/keytool"; do
  [ -x "$k" ] && keytool=$k && break
done
"$keytool" -help >/dev/null 2>&1 || { echo "keytool not found: install Android Studio or a JDK" >&2; exit 1; }
[ -e "$jks" ] && { echo "$jks already exists; not replacing it" >&2; exit 1; }

mkdir -p "$dir" && chmod 700 "$dir"
password=$(openssl rand -base64 32 | tr -dc 'A-Za-z0-9' | cut -c1-28)
"$keytool" -genkeypair -keystore "$jks" -storetype PKCS12 -alias upload -keyalg RSA -keysize 4096 \
  -validity 10000 -storepass "$password" -keypass "$password" -dname "CN=Thomas Koebel, O=koebelt" >/dev/null
chmod 600 "$jks"
security add-generic-password -U -a koebelt -s "koebelt android upload key" -w "$password"
base64 -i "$jks" | gh secret set ANDROID_KEYSTORE_BASE64 -R "$repo"
printf %s "$password" | gh secret set ANDROID_KEYSTORE_PASSWORD -R "$repo"
"$keytool" -list -v -keystore "$jks" -storepass "$password" | grep -E "SHA256:" | head -1
echo "Done: $jks (password in Keychain: \"koebelt android upload key\"). Back the folder up."
