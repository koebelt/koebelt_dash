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
