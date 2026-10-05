"""Writes every platform's app icon from the masters made by
test/gen_icons_test.dart.  Usage: python3 tool/icons.py <ICON_DIR>"""
import json
import os
import sys

from PIL import Image

src = sys.argv[1]
root = os.path.join(os.path.dirname(__file__), '..')
square, rounded, mac = (Image.open(os.path.join(src, n)).convert('RGBA') for n in ('square.png', 'rounded.png', 'macos.png'))


def save(img, px, path, opaque=False):
    out = img.resize((px, px), Image.LANCZOS)
    if opaque:
        out = out.convert('RGB')  # App Store rejects alpha
    out.save(os.path.join(root, path))


# iOS: sizes from the asset catalogue itself.
ios = 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
for i in json.load(open(os.path.join(root, ios, 'Contents.json')))['images']:
    pt, scale = float(i['size'].split('x')[0]), int(i['scale'][0])
    save(square, round(pt * scale), f"{ios}/{i['filename']}", opaque=True)

# macOS
macd = 'macos/Runner/Assets.xcassets/AppIcon.appiconset'
for px in (16, 32, 64, 128, 256, 512, 1024):
    save(mac, px, f'{macd}/app_icon_{px}.png')

# Android legacy launcher icons.
for d, px in {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192}.items():
    save(rounded, px, f'android/app/src/main/res/mipmap-{d}/ic_launcher.png')

# Windows
rounded.save(os.path.join(root, 'windows/runner/resources/app_icon.ico'), sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)])
print('icons written')
