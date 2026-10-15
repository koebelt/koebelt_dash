#!/usr/bin/env python3
"""One-time Apple setup for the app release workflow (tools/release/RELEASING.md).

With an App Store Connect API key (Admin), it:
  1. registers the app id com.koebelt.dash;
  2. creates an Apple Distribution certificate (App Store, TestFlight);
  3. prepares the Developer ID Application certificate (the notarized macOS
     download): Apple lets only the Account Holder create that one, so the
     script writes a signing request to upload in the developer portal, and
     takes the certificate back with --devid-cer;
  4. creates the iOS App Store provisioning profile;
  5. stores it all as GitHub Actions secrets of koebelt/koebelt_dash (with gh).

    python3 tools/release/setup_apple.py        # finds ~/Downloads/AuthKey_*.p8, asks for the Issuer ID
    python3 tools/release/setup_apple.py --devid-cer ~/Downloads/developerID_application.cer

Every private key is written to ~/Documents/koebelt-release-keys before Apple
is asked for its certificate, and reused when the script runs again, so a
rerun never leaves a certificate without its key. The keys only leave this
computer as GitHub secrets. Needs gh (logged in); creates a small virtualenv
for the `cryptography` package.
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
import urllib.parse
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


class Refused(Exception):
    pass


def b64url(b: bytes) -> str:
    return base64.urlsafe_b64encode(b).rstrip(b"=").decode()


def save(name, data: bytes):
    KEYS_DIR.mkdir(parents=True, exist_ok=True)
    KEYS_DIR.chmod(0o700)
    f = KEYS_DIR / name
    f.write_bytes(data)
    f.chmod(0o600)
    return f


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

    def call(self, method, path, data=None, query=None):
        url = "https://api.appstoreconnect.apple.com/v1/" + path
        if query:
            url += "?" + urllib.parse.urlencode(query)
        req = urllib.request.Request(
            url,
            method=method,
            data=json.dumps({"data": data}).encode() if data else None,
            headers={"Authorization": "Bearer " + self.token(), "Content-Type": "application/json"},
        )
        try:
            with urllib.request.urlopen(req) as r:
                body = r.read()
                return json.loads(body) if body else {}
        except urllib.error.HTTPError as e:
            errors = json.load(e).get("errors", [])
            raise Refused(f"App Store Connect refused {method} {path}:\n" + "\n".join(f"  {x.get('title')}: {x.get('detail')}" for x in errors))


def bundle_id(api):
    found = api.call("GET", "bundleIds", query={"filter[identifier]": BUNDLE_ID})["data"]
    exact = [b for b in found if b["attributes"]["identifier"] == BUNDLE_ID]
    if exact:
        print(f"app id {BUNDLE_ID}: registered")
        return exact[0]["id"]
    made = api.call("POST", "bundleIds", {"type": "bundleIds", "attributes": {"identifier": BUNDLE_ID, "name": APP_NAME, "platform": "UNIVERSAL"}})
    print(f"app id {BUNDLE_ID}: registered now")
    return made["data"]["id"]


def private_key(name):
    """The saved private key `name`, made and saved first if there is none."""
    f = KEYS_DIR / f"{name}.key.pem"
    if f.exists():
        return serialization.load_pem_private_key(f.read_bytes(), None)
    key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    save(f.name, key.private_bytes(serialization.Encoding.PEM, serialization.PrivateFormat.PKCS8, serialization.NoEncryption()))
    return key


def csr(key, label):
    return (
        x509.CertificateSigningRequestBuilder()
        .subject_name(x509.Name([x509.NameAttribute(NameOID.COMMON_NAME, f"koebelt dash {label}"), x509.NameAttribute(NameOID.EMAIL_ADDRESS, "contact@koebelt.com")]))
        .sign(key, hashes.SHA256())
        .public_bytes(serialization.Encoding.PEM)
    )


def matches(cert, key):
    pem = lambda k: k.public_bytes(serialization.Encoding.PEM, serialization.PublicFormat.SubjectPublicKeyInfo)  # noqa: E731
    return pem(cert.public_key()) == pem(key.public_key())


def cn(cert):
    return cert.subject.get_attributes_for_oid(NameOID.COMMON_NAME)[0].value


def distribution(api):
    """Apple Distribution certificate for the saved key: found on the account, or created."""
    key = private_key("apple-distribution")
    for c in api.call("GET", "certificates", query={"filter[certificateType]": "DISTRIBUTION", "limit": "200"})["data"]:
        cert = x509.load_der_x509_certificate(base64.b64decode(c["attributes"]["certificateContent"]))
        if matches(cert, key):
            print(f"certificate: {cn(cert)} (existing, expires {cert.not_valid_after_utc:%Y-%m-%d})")
            return c["id"], cert, key
    made = api.call("POST", "certificates", {"type": "certificates", "attributes": {"certificateType": "DISTRIBUTION", "csrContent": csr(key, "App Store").decode()}})
    cert = x509.load_der_x509_certificate(base64.b64decode(made["data"]["attributes"]["certificateContent"]))
    print(f"certificate: {cn(cert)} (new)")
    return made["data"]["id"], cert, key


def developer_id(api, cer_path):
    """Developer ID Application certificate for the saved key, or None after writing the request to upload."""
    key = private_key("developer-id")
    if cer_path:
        data = pathlib.Path(cer_path).expanduser().read_bytes()
        cert = x509.load_pem_x509_certificate(data) if data.startswith(b"-----") else x509.load_der_x509_certificate(data)
        if not matches(cert, key):
            raise SystemExit(f"{cer_path} was not made from {KEYS_DIR}/developer-id.csr (different key).")
        save("developer-id.cer", cert.public_bytes(serialization.Encoding.DER))
    saved = KEYS_DIR / "developer-id.cer"
    if saved.exists():
        cert = x509.load_der_x509_certificate(saved.read_bytes())
        print(f"certificate: {cn(cert)} (expires {cert.not_valid_after_utc:%Y-%m-%d})")
        return cert, key
    try:
        made = api.call("POST", "certificates", {"type": "certificates", "attributes": {"certificateType": "DEVELOPER_ID_APPLICATION_G2", "csrContent": csr(key, "Developer ID").decode()}})
    except Refused:
        save("developer-id.csr", csr(key, "Developer ID"))
        return None, key
    cert = x509.load_der_x509_certificate(base64.b64decode(made["data"]["attributes"]["certificateContent"]))
    save("developer-id.cer", cert.public_bytes(serialization.Encoding.DER))
    print(f"certificate: {cn(cert)} (new)")
    return cert, key


def profile(api, bundle, cert_id):
    for p in api.call("GET", "profiles", query={"filter[name]": PROFILE_NAME})["data"]:
        api.call("DELETE", f"profiles/{p['id']}")  # replaced, in case it names an old certificate
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
    ap.add_argument("--key", help="AuthKey_<KEYID>.p8 downloaded from App Store Connect (default: the newest in ~/Downloads)")
    ap.add_argument("--issuer", help="Issuer ID shown above the keys in App Store Connect (asked if missing)")
    ap.add_argument("--key-id", help="defaults to the id in the file name AuthKey_<KEYID>.p8")
    ap.add_argument("--devid-cer", help="the Developer ID Application certificate downloaded from the developer portal")
    a = ap.parse_args()
    if not a.key:
        found = sorted((pathlib.Path.home() / "Downloads").glob("AuthKey_*.p8"), key=lambda f: f.stat().st_mtime)
        if not found:
            raise SystemExit(
                "No AuthKey_*.p8 in ~/Downloads. Create one in App Store Connect > Users and Access > "
                "Integrations > App Store Connect API > Team Keys (access: Admin), download it, or pass --key."
            )
        a.key = str(found[-1])
        print(f"API key: {a.key}")
    if not a.issuer:
        saved = KEYS_DIR / "issuer-id.txt"
        a.issuer = saved.read_text().strip() if saved.exists() else input("Issuer ID (App Store Connect > Users and Access > Integrations, above the keys): ").strip()
    key_path = pathlib.Path(a.key).expanduser()
    key_id = a.key_id or key_path.stem.removeprefix("AuthKey_")
    save(key_path.name, key_path.read_bytes())
    save("issuer-id.txt", a.issuer.encode())
    api = Api(key_path, key_id, a.issuer)

    try:
        bundle = bundle_id(api)
        dist_id, dist, dist_key = distribution(api)
        devid, devid_key = developer_id(api, a.devid_cer)
        prof = profile(api, bundle, dist_id)
    except Refused as e:
        raise SystemExit(str(e))
    team = dist.subject.get_attributes_for_oid(NameOID.ORGANIZATIONAL_UNIT_NAME)[0].value
    save("ios-app-store.mobileprovision", prof)

    pw_file = KEYS_DIR / "p12-password.txt"
    password = pw_file.read_text().strip() if pw_file.exists() else secrets.token_urlsafe(24)
    save(pw_file.name, password.encode())
    dist_p12 = save("apple-distribution.p12", p12(dist, dist_key, password)).read_bytes()

    b64 = lambda b: base64.b64encode(b).decode()  # noqa: E731
    secret("APPLE_TEAM_ID", team)
    secret("ASC_KEY_ID", key_id)
    secret("ASC_ISSUER_ID", a.issuer)
    secret("ASC_KEY_P8_BASE64", b64(key_path.read_bytes()))
    secret("APPLE_P12_PASSWORD", password)
    secret("APPLE_DISTRIBUTION_P12_BASE64", b64(dist_p12))
    secret("IOS_PROFILE_BASE64", b64(prof))
    if devid:
        devid_p12 = save("developer-id-application.p12", p12(devid, devid_key, password)).read_bytes()
        secret("APPLE_DEVELOPER_ID_P12_BASE64", b64(devid_p12))
        secret("APPLE_DEVELOPER_ID_NAME", cn(devid))
        print(f"\nDone. Team {team}. Keep {KEYS_DIR} backed up (a password manager or an encrypted drive).")
    else:
        print(
            f"""
iOS is set up. One step left for the macOS download: Apple lets only the
Account Holder create a Developer ID certificate, so do it in the portal:

  1. https://developer.apple.com/account/resources/certificates/add
  2. Choose "Developer ID Application", Continue, keep "G2 Sub-CA".
  3. Upload {KEYS_DIR}/developer-id.csr and download the certificate.
  4. Run: python3 tools/release/setup_apple.py --devid-cer ~/Downloads/developerID_application.cer"""
        )


if __name__ == "__main__":
    main()
