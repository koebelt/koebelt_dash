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
  `release.yml`, environment `pypi`. No token is stored.
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
  Developer ID, notarized), the Windows installer, the Linux tarball and the
  Android APK;
- uploads the iOS build to App Store Connect, where it appears in TestFlight
  after Apple's processing (about 15 minutes).

Running the workflow by hand (Actions > app-release > Run workflow) builds
everything without publishing, unsigned where secrets are missing, and keeps
the files as workflow artifacts.

## Each release

```bash
# 1. Bump `version:` in apps/dash/pubspec.yaml (keep +1 after it), and write
#    tools/release/app-notes/X.Y.Z.md
# 2. Commit, tag, push
git tag app-v1.0.1 && git push origin main app-v1.0.1
# 3. In App Store Connect > TestFlight, the build appears; add it to a group
#    of testers, or submit it for App Store review.
```

## One-time setup

- **Apple**: in App Store Connect, create an API key (Users and Access >
  Integrations > App Store Connect API > Team Keys > +, access Admin) and
  download it, then run
  `python3 tools/release/setup_apple.py --key ~/Downloads/AuthKey_XXXX.p8 --issuer <Issuer ID>`.
  It registers the bundle id `com.koebelt.dash`, makes the certificates and
  profile and stores them as secrets. Then create the app (Apps > + > New App:
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
