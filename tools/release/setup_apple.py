#!/usr/bin/env python3
"""One-time Apple setup for the app release workflow (tools/release/RELEASING.md).

With an App Store Connect API key (Admin), it:
  1. registers the app id com.koebelt.dash;
  2. creates an Apple Distribution certificate (App Store, TestFlight) and a
     Developer ID Application certificate (the notarized macOS download);
  3. creates the iOS App Store provisioning profile;
  4. keeps a copy of everything in ~/Documents/koebelt-release-keys;
  5. stores it as GitHub Actions secrets of koebelt/koebelt_dash (with gh).

    python3 tools/release/setup_apple.py --key ~/Downloads/AuthKey_XXXXXXXXXX.p8 --issuer <issuer id>

The private keys are made here and only leave this computer as GitHub secrets.
Needs gh (logged in) and creates a small virtualenv for the `cryptography` package.
"""
import argparse
import base64
import json
import os
import pathlib
import secrets
import subprocess
import sys
import time
import urllib.error
import urllib.request

BUNDLE_ID = "com.koebelt.dash"
APP_NAME = "koebelt dash"
PROFILE_NAME = "koebelt dash App Store"
REPO = "koebelt/koebelt_dash"
KEYS_DIR = pathlib.Path.home() / "Documents" / "koebelt-release-keys"
VENV = pathlib.Path.home() / ".cache" / "koebelt-release-venv"


def ensure_cryptography():
    try:
        import cryptography  # noqa: F401
        return
    except ImportError:
        pass
    py = VENV / "bin" / "python"
    if not py.exists():
        subprocess.check_call([sys.executable, "-m", "venv", str(VENV)])
        subprocess.check_call([str(py), "-m", "pip", "install", "-q", "cryptography"])
    os.execv(str(py), [str(py), *sys.argv])


ensure_cryptography()

from cryptography import x509  # noqa: E402
from cryptography.hazmat.primitives import hashes, serialization  # noqa: E402
from cryptography.hazmat.primitives.asymmetric import ec, rsa  # noqa: E402
from cryptography.hazmat.primitives.asymmetric.utils import decode_dss_signature  # noqa: E402
from cryptography.hazmat.primitives.serialization import pkcs12  # noqa: E402
from cryptography.x509.oid import NameOID  # noqa: E402


def b64url(b: bytes) -> str:
    return base64.urlsafe_b64encode(b).rstrip(b"=").decode()


class Api:
    def __init__(self, key_path, key_id, issuer):
        self.key = serialization.load_pem_private_key(pathlib.Path(key_path).read_bytes(), None)
        self.key_id, self.issuer = key_id, issuer

    def token(self):
        head = b64url(json.dumps({"alg": "ES256", "kid": self.key_id, "typ": "JWT"}).encode())
        now = int(time.time())
        body = b64url(json.dumps({"iss": self.issuer, "iat": now, "exp": now + 900, "aud": "appstoreconnect-v1"}).encode())
        r, s = decode_dss_signature(self.key.sign(f"{head}.{body}".encode(), ec.ECDSA(hashes.SHA256())))
        return f"{head}.{body}.{b64url(r.to_bytes(32, 'big') + s.to_bytes(32, 'big'))}"

    def call(self, method, path, data=None):
        req = urllib.request.Request(
            "https://api.appstoreconnect.apple.com/v1/" + path,
            method=method,
            data=json.dumps({"data": data}).encode() if data else None,
            headers={"Authorization": "Bearer " + self.token(), "Content-Type": "application/json"},
        )
        try:
            with urllib.request.urlopen(req) as r:
                return json.load(r)
        except urllib.error.HTTPError as e:
            errors = json.load(e).get("errors", [])
            raise SystemExit(f"App Store Connect refused {method} {path}:\n" + "\n".join(f"  {x.get('title')}: {x.get('detail')}" for x in errors))


def bundle_id(api):
    found = api.call("GET", f"bundleIds?filter[identifier]={BUNDLE_ID}")["data"]
    exact = [b for b in found if b["attributes"]["identifier"] == BUNDLE_ID]
    if exact:
        print(f"app id {BUNDLE_ID}: already registered")
        return exact[0]["id"]
    made = api.call("POST", "bundleIds", {"type": "bundleIds", "attributes": {"identifier": BUNDLE_ID, "name": APP_NAME, "platform": "UNIVERSAL"}})
    print(f"app id {BUNDLE_ID}: registered")
    return made["data"]["id"]


def certificate(api, kind, label):
    """A new certificate of `kind` with a fresh private key. Returns (id, cert, key)."""
    key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    csr = (
        x509.CertificateSigningRequestBuilder()
        .subject_name(x509.Name([x509.NameAttribute(NameOID.COMMON_NAME, f"koebelt dash {label}")]))
        .sign(key, hashes.SHA256())
    )
    made = api.call("POST", "certificates", {"type": "certificates", "attributes": {"certificateType": kind, "csrContent": csr.public_bytes(serialization.Encoding.PEM).decode()}})
    cert = x509.load_der_x509_certificate(base64.b64decode(made["data"]["attributes"]["certificateContent"]))
    print(f"certificate: {cert.subject.get_attributes_for_oid(NameOID.COMMON_NAME)[0].value}")
    return made["data"]["id"], cert, key


def profile(api, bundle, cert_id):
    for p in api.call("GET", f"profiles?filter[name]={PROFILE_NAME}")["data"]:
        api.call("DELETE", f"profiles/{p['id']}")  # it names the old certificate
    made = api.call(
        "POST",
        "profiles",
        {
            "type": "profiles",
            "attributes": {"name": PROFILE_NAME, "profileType": "IOS_APP_STORE"},
            "relationships": {
                "bundleId": {"data": {"type": "bundleIds", "id": bundle}},
                "certificates": {"data": [{"type": "certificates", "id": cert_id}]},
            },
        },
    )
    print(f"profile: {PROFILE_NAME}")
    return base64.b64decode(made["data"]["attributes"]["profileContent"])


def p12(cert, key, password):
    # 3DES/SHA1: the encryption `security import` on macOS reads everywhere.
    enc = (
        serialization.PrivateFormat.PKCS12.encryption_builder()
        .kdf_rounds(50000)
        .key_cert_algorithm(pkcs12.PBES.PBESv1SHA1And3KeyTripleDESCBC)
        .hmac_hash(hashes.SHA1())
        .build(password.encode())
    )
    return pkcs12.serialize_key_and_certificates(b"koebelt dash", key, cert, None, enc)


def secret(name, value):
    subprocess.run(["gh", "secret", "set", name, "-R", REPO], input=value.encode(), check=True, stdout=subprocess.DEVNULL)
    print(f"secret {name}: set")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--key", required=True, help="AuthKey_<KEYID>.p8 downloaded from App Store Connect")
    ap.add_argument("--issuer", required=True, help="Issuer ID shown above the keys in App Store Connect")
    ap.add_argument("--key-id", help="defaults to the id in the file name AuthKey_<KEYID>.p8")
    a = ap.parse_args()
    key_path = pathlib.Path(a.key).expanduser()
    key_id = a.key_id or key_path.stem.removeprefix("AuthKey_")
    api = Api(key_path, key_id, a.issuer)

    bundle = bundle_id(api)
    dist_id, dist, dist_key = certificate(api, "DISTRIBUTION", "App Store")
    try:
        _, devid, devid_key = certificate(api, "DEVELOPER_ID_APPLICATION_G2", "Developer ID")
    except SystemExit as e:
        print(f"{e}\nSkipping Developer ID: Apple may only let the Account Holder create it (see the end).")
        devid = devid_key = None
    prof = profile(api, bundle, dist_id)
    team = dist.subject.get_attributes_for_oid(NameOID.ORGANIZATIONAL_UNIT_NAME)[0].value

    password = secrets.token_urlsafe(24)
    files = {
        "apple-distribution.p12": p12(dist, dist_key, password),
        "ios-app-store.mobileprovision": prof,
        "p12-password.txt": password.encode(),
        key_path.name: key_path.read_bytes(),
    }
    if devid:
        files["developer-id-application.p12"] = p12(devid, devid_key, password)
    KEYS_DIR.mkdir(parents=True, exist_ok=True)
    KEYS_DIR.chmod(0o700)
    for name, data in files.items():
        f = KEYS_DIR / name
        f.write_bytes(data)
        f.chmod(0o600)
    print(f"copies in {KEYS_DIR}")

    b64 = lambda b: base64.b64encode(b).decode()  # noqa: E731
    secret("APPLE_TEAM_ID", team)
    secret("ASC_KEY_ID", key_id)
    secret("ASC_ISSUER_ID", a.issuer)
    secret("ASC_KEY_P8_BASE64", b64(key_path.read_bytes()))
    secret("APPLE_P12_PASSWORD", password)
    secret("APPLE_DISTRIBUTION_P12_BASE64", b64(files["apple-distribution.p12"]))
    secret("IOS_PROFILE_BASE64", b64(prof))
    if devid:
        secret("APPLE_DEVELOPER_ID_P12_BASE64", b64(files["developer-id-application.p12"]))
        secret("APPLE_DEVELOPER_ID_NAME", devid.subject.get_attributes_for_oid(NameOID.COMMON_NAME)[0].value)
    else:
        print(
            "\nThe macOS download still needs a Developer ID certificate. In Xcode: Settings > Accounts >"
            " your team > Manage Certificates > + > Developer ID Application. Then in Keychain Access, export"
            f" it (with its key) as {KEYS_DIR}/developer-id-application.p12 using the password in p12-password.txt, and run:\n"
            f"  base64 -i {KEYS_DIR}/developer-id-application.p12 | gh secret set APPLE_DEVELOPER_ID_P12_BASE64 -R {REPO}\n"
            f'  gh secret set APPLE_DEVELOPER_ID_NAME -R {REPO} --body "Developer ID Application: <your name> ({team})"'
        )
    print(f"\nDone. Team {team}. Keep {KEYS_DIR} backed up (a password manager or an encrypted drive).")


if __name__ == "__main__":
    main()
