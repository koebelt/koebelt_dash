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
