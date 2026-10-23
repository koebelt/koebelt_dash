# Releasing koebelt/link

The Python, Rust and Arduino libraries are released together, with one
version. Pushing a tag `link-vX.Y.Z` runs [`release.yml`](../../.github/workflows/release.yml),
which:

1. checks every library carries version X.Y.Z (`check_versions.py`);
2. tests and publishes the Python package to PyPI;
3. tests and publishes the Rust crate to crates.io;
4. tests the Arduino library, copies it to
   [koebelt/KoebeltLink](https://github.com/koebelt/KoebeltLink), lints it and
   tags it `X.Y.Z` there. The Arduino Library Manager picks the tag up within
   a day.

The ROS 2 bridge carries the same version but is not released to rosdistro yet.

## Each release

```bash
# 1. Set the version in every library, then check
python3 tools/release/check_versions.py        # prints it, fails if one differs
#    pyproject.toml, koebelt_link/__init__.py, Cargo.toml, library.properties,
#    library.json, KoebeltLink.h (KOEBELT_LINK_VERSION), package.xml, setup.py,
#    and the versions quoted in the guides and READMEs

# 2. Commit, then tag and push
git tag link-v1.0.1 && git push origin main link-v1.0.1

# 3. PlatformIO (manual, from the mirror at the new tag)
git clone --branch 1.0.1 https://github.com/koebelt/KoebeltLink && pio pkg publish KoebeltLink
```

A failed job can be re-run from the Actions tab. PyPI and crates.io refuse to
publish the same version twice, so a fix after a partial release takes a new
patch version.

## One-time setup

- **PyPI**: on pypi.org, add a *pending trusted publisher* for the project
  `koebelt-link`: owner `koebelt`, repository `koebelt_dash`, workflow
  `release.yml`, environment `pypi`. No token is stored. A second one for
  `koebelt-dash-scripts`, released with the app: workflow `app-release.yml`,
  environment `pypi`.
- **crates.io**: sign in with GitHub, create an API token with the
  `publish-new` and `publish-update` scopes, and store it as the repository
  secret `CARGO_REGISTRY_TOKEN`.
- **Arduino**: the repository `koebelt/KoebeltLink` has a deploy key with write
  access; its private half is the secret `KOEBELTLINK_DEPLOY_KEY`. After the
  first tagged release, add `https://github.com/koebelt/KoebeltLink` to
  [arduino/library-registry](https://github.com/arduino/library-registry)
  (a pull request on `repositories.txt`; a bot checks and merges it).
- **PlatformIO**: an account named `koebelt` (`pio account register`), so the
  package is `koebelt/KoebeltLink`.

# Releasing the app

Pushing a tag `app-vX.Y.Z` runs [`app-release.yml`](../../.github/workflows/app-release.yml).
X.Y.Z must be the version in `apps/dash/pubspec.yaml`; the build number is
the workflow's run number, so it always goes up. It builds every platform
and then:

- creates the GitHub Release `app-vX.Y.Z` with the notes in
  [`app-notes/X.Y.Z.md`](app-notes/) and the macOS .dmg (signed with
  Developer ID, notarized), the Windows installer, the Linux tarball, the
  Android APK and `SHA256SUMS`;
- uploads the iOS build to App Store Connect, where it appears in TestFlight
  after Apple's processing (about 15 minutes);
- publishes `koebelt-dash-scripts` (libs/python-dash-scripts) to PyPI. Its
  version, and the MCP bridge's (tools/mcp_bridge), must be the app's: the
  version job checks.

### Betas and release candidates

Set `appVersion` (apps/dash/lib/link/protocol.dart) to `X.Y.Z-beta.N` or
`X.Y.Z-rc.N`, keep `X.Y.Z` in pubspec.yaml (iOS and macOS take numbers only),
give koebelt-dash-scripts `X.Y.ZbN` / `X.Y.ZrcN` and the MCP bridge the app's
version, write `app-notes/X.Y.Z-beta.N.md`, and tag `app-vX.Y.Z-beta.N`. The
GitHub Release is marked as a pre-release: the in-app updater offers it only
to apps with Settings > Updates > Betas on (on by itself in a beta). iOS gets
build X.Y.Z on TestFlight; do not prepare an App Store version for a beta.
PyPI keeps it out of `pip install` without `--pre`; dash's Python setup asks
for the exact version, so a beta app gets the beta package.

`apps/dash/compat.json` says which koebelt/link versions the app works with:
the protocol version it speaks and the oldest library version it supports, per
library. It is bundled in the app and published with each release, so an
installed app checks a release against the library versions your devices
reported before installing it, and warns about the ones it would leave behind.
Raise a minimum only when the app drops support for older devices, and say so
in the release notes; `tools/compat/run.sh` (in CI) tests the app against every
published library version from those minimums up.

Installed copies from GitHub find the new release by themselves (at launch
and once a day) and update in one click: the app downloads its file, checks
it against `SHA256SUMS` (and on macOS the Developer ID team and Gatekeeper),
swaps itself and restarts; Android hands the APK to the system installer.
Those builds get `--dart-define=KDASH_UPDATES=github`; the iOS build and
local builds do not, and never check. So the file names, the `app-v` tag and
`SHA256SUMS` must stay as they are, and `appVersion` in
`lib/link/protocol.dart` must match `pubspec.yaml` (a test and the workflow
check it). Version 1.0.0 had no updater: its users install 1.1.0 by hand once.

The macOS disk image opens on a designed window: the background is
[`dmg/background.html`](dmg/), rendered to `dmg/background.tiff` (1x and 2x)
by `node tools/release/dmg/render-background.mjs` (needs Playwright), and
`dmg/dmgbuild-settings.py` places the icons on it. Finder writes the file
names itself, black in light mode and white in dark, so they sit on grey
plates that read either way; moving an icon means moving its slot and plate
in the HTML too. `background-preview.png` shows the result.

Running the workflow by hand (Actions > app-release > Run workflow) builds
everything without publishing, unsigned where secrets are missing, and keeps
the files as workflow artifacts.

## Each release

```bash
# 1. Bump `version:` in apps/dash/pubspec.yaml (keep +1 after it) and
#    `appVersion` in apps/dash/lib/link/protocol.dart, and write
#    tools/release/app-notes/X.Y.Z.md (shown in the app's update dialog)
# 2. Commit, tag, push
git tag app-v1.0.1 && git push origin main app-v1.0.1
# 3. In App Store Connect > TestFlight, the build appears; add it to a group
#    of testers, or prepare it for the App Store (below).
```

## App Store

The release workflow only uploads iOS builds to TestFlight; each App Store
version is prepared and submitted separately, once Apple has processed the
build (about 15 minutes) and the previous version is through review (Apple
allows one in preparation at a time).

```bash
# Fresh screenshots (iPhone 6.9" and iPad 13", at the sizes Apple requires)
cd apps/dash && STORE_SHOTS=/tmp/store flutter test test/store_screenshots_test.dart && cd -

python3 tools/release/app_store.py 1.2.0                               # shows what it would do
python3 tools/release/app_store.py 1.2.0 --apply --shots /tmp/store   # creates and fills the version
python3 tools/release/app_store.py 1.2.0 --submit                      # sends it for review
```

"What's New" comes from `app-notes/X.Y.Z.store.md` and `X.Y.Z.store.fr.md`:
iPhone and iPad have no in-app updater, so the GitHub notes (`X.Y.Z.md`, the
fallback) often do not fit. French falls back to English. The description, keywords,
categories, age rating, price and review contact carry over from the previous
version. A version is released by hand after approval (App Store Connect >
the version > Release).

## One-time setup

- **Apple**: in App Store Connect, create an API key (Users and Access >
  Integrations > App Store Connect API > Team Keys > +, access Admin) and
  download it, then run
  `python3 tools/release/setup_apple.py --key ~/Downloads/AuthKey_XXXX.p8 --issuer <Issuer ID>`.
  It registers the bundle id `com.koebelt.dash`, makes the App Store
  certificate and profile and stores them as secrets. Apple lets only the
  Account Holder create the Developer ID certificate (macOS download): the
  script writes `developer-id.csr`, you upload it in the developer portal
  (Certificates > + > Developer ID Application) and rerun the script with
  `--devid-cer <downloaded .cer>`. Reruns reuse the saved keys. Then create the app (Apps > + > New App:
  iOS, name "koebelt dash", bundle id `com.koebelt.dash`, SKU `koebelt-dash`);
  the bundle id is in the list once registered.
  Certificates last a year: rerun the script when Apple's renewal email arrives.
- **Android**: run `tools/release/setup_android_key.sh` once. The key in
  `~/Documents/koebelt-release-keys` signs every APK; installed copies only
  update from APKs signed with it, so back it up.
- **Google Play (later)**: when creating the app, choose to use your own app
  signing key and give Play this same key (Play Console guides you through
  exporting it with its PEPK tool), so people who installed the APK can
  update from Play. The workflow already builds the .aab Play wants.
- **iOS LAN discovery**: finding devices by UDP broadcast on iPhone and
  iPad needs Apple's multicast networking entitlement. Request it at
  https://developer.apple.com/contact/request/networking-multicast for
  `com.koebelt.dash`; once granted, give the Runner target an entitlements
  file with `com.apple.developer.networking.multicast` and rerun
  `setup_apple.py` so the profile includes it. Until then, iOS connects over Bluetooth and Add by IP.
- **Windows code signing (later)**: the installer is unsigned, so SmartScreen
  warns at first. Azure Trusted Signing is the cheapest way to sign it.
