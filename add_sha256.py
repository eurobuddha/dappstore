#!/usr/bin/env python3
"""
add_sha256.py — stamp every catalog row with the SHA-256 of the file it points at.

    python3 add_sha256.py [pandadapps.json minimadapps.json ...]   (default: both)

For each row with a `file` URL: download it (following redirects, https only), compute SHA-256, and
set `sha256` on the row. Rows whose download fails keep whatever `sha256` they already had (a stale
hash would make every client refuse the file — better to leave it and print a warning). A row whose
hash CHANGES for an unchanged `file`/`version` is also flagged: that means the published zip was
replaced in place, which downstream verifiers (minimaDesk boot-time updates, the store's SHA-256 row)
will now catch.

Idempotent: re-running touches nothing when the files are unchanged. Run it after every publish,
before mirroring to sally / IPFS.
"""
import hashlib
import json
import sys
import urllib.request

MAX_BYTES = 128 * 1024 * 1024
TIMEOUT = 60
UA = "pandadapps-add-sha256/1.0"


def sha256_url(url):
    if not url.startswith("https://"):
        raise ValueError("not https")
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    h = hashlib.sha256()
    total = 0
    first = b""
    with urllib.request.urlopen(req, timeout=TIMEOUT) as r:
        while True:
            chunk = r.read(1024 * 1024)
            if not chunk:
                break
            if not first:
                first = chunk[:16]
                # a MiniDapp is a zip (PK\x03\x04); a server that answers 200 with an error page must not be hashed
                if first.lstrip().lower().startswith((b"<html", b"<!doctype")):
                    raise ValueError("body is an HTML page, not a zip (broken upload?)")
                if not first.startswith(b"PK"):
                    raise ValueError("body is not a zip archive")
            total += len(chunk)
            if total > MAX_BYTES:
                raise ValueError("larger than %d bytes" % MAX_BYTES)
            h.update(chunk)
    return h.hexdigest(), total


def process(path):
    with open(path) as f:
        cat = json.load(f)
    rows = cat.get("dapps") if isinstance(cat, dict) else cat
    if not isinstance(rows, list):
        print("%s: no dapps array" % path)
        return 0, 0
    changed = 0
    failed = 0
    for row in rows:
        url = row.get("file") or ""
        name = row.get("name", "?")
        if not url:
            continue
        try:
            digest, size = sha256_url(url)
        except Exception as e:  # noqa: BLE001
            failed += 1
            if "not a zip" in str(e) and row.get("sha256"):
                # never publish a hash for a broken file — the store would show it as if it were verified
                print("DROP %-28s removed stale sha256 — %s" % (name, e))
                del row["sha256"]
                changed += 1
            else:
                print("WARN %-28s keep %s — download failed: %s" % (name, row.get("sha256", "(none)"), e))
            continue
        old = row.get("sha256")
        if old == digest:
            print("ok   %-28s %s (%d bytes)" % (name, digest, size))
            continue
        if old:
            print("CHANGED %-25s %s -> %s (%d bytes) — the published file was replaced" % (name, old, digest, size))
        else:
            print("add  %-28s %s (%d bytes)" % (name, digest, size))
        row["sha256"] = digest
        changed += 1
    if changed:
        with open(path, "w") as f:
            json.dump(cat, f, indent=2, ensure_ascii=False)
            f.write("\n")
    return changed, failed


def main(argv):
    paths = argv[1:] or ["pandadapps.json", "minimadapps.json"]
    total_changed = total_failed = 0
    for p in paths:
        c, fl = process(p)
        total_changed += c
        total_failed += fl
        print("%s: %d row(s) updated, %d download failure(s)" % (p, c, fl))
    return 1 if total_failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
