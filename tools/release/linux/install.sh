#!/bin/sh
# Adds koebelt dash to your applications menu (for this user), from where
# this folder is. Run it again after moving the folder.
set -e
here=$(cd "$(dirname "$0")" && pwd)
apps="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
icons="${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor/512x512/apps"
mkdir -p "$apps" "$icons"
cp "$here/com.koebelt.dash.png" "$icons/"
sed "s|^Exec=.*|Exec=\"$here/koebelt_dash\"|" "$here/koebelt-dash.desktop" > "$apps/com.koebelt.dash.desktop"
echo "koebelt dash is in your applications menu."
# Chinese and Japanese text needs a CJK font from the system.
if command -v fc-list >/dev/null && [ -z "$(fc-list :lang=zh 2>/dev/null | head -n 1)" ]; then
  echo "For Chinese or Japanese, install a CJK font too: sudo apt install fonts-noto-cjk"
fi
