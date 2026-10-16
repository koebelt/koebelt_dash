# dmgbuild settings for the koebelt dash disk image (tools/release/macos_dmg.sh).
# dmgbuild writes the Finder window layout itself, without scripting Finder,
# so it works on CI Macs. Pass -D app=<path to koebelt dash.app> and
# -D dir=<this folder> (dmgbuild runs this file without __file__).
import os.path

here = defines["dir"]  # noqa: F821 (provided by dmgbuild)
app = defines["app"]  # noqa: F821
name = os.path.basename(app)

format = "UDZO"
filesystem = "HFS+"
files = [app]
symlinks = {"Applications": "/Applications"}
# The disk's own icon: the app's.
icon = os.path.join(app, "Contents", "Resources", "AppIcon.icns")

# 660 × 400 of content, the size background.html is drawn at.
background = os.path.join(here, "background.tiff")
window_rect = ((240, 160), (660, 428))
default_view = "icon-view"
show_status_bar = False
show_tab_view = False
show_toolbar = False
show_pathbar = False
show_sidebar = False
show_icon_preview = False
include_icon_view_settings = True

icon_size = 112
text_size = 12
label_pos = "bottom"
# The centres of the two slots in background.html.
icon_locations = {
    name: (170, 190),
    "Applications": (490, 190),
    # Hidden files, far outside the window for anyone who shows hidden files.
    ".background.tiff": (900, 900),
    ".VolumeIcon.icns": (1000, 900),
    ".DS_Store": (1100, 900),
}
