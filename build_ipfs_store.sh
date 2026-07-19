#!/bin/bash
# Build and publish the IPFS snapshot of the PandaDapps store, the official
# Minima store mirror, and the native minimaCore APK catalog.
#
# Runs on the Pi as root (cron + manually after store updates). The snapshot
# is staged in /var/ipfs-store, added to the local kubo node, published under
# the 'pandastore' IPNS key, and remote-pinned to Pinata (if configured).
#
# Deployed copy: /usr/local/bin/build_ipfs_store.sh
set -euo pipefail

# single-instance guard: a slow run (big downloads) must not overlap the next cron fire
exec 9>/var/lock/build_ipfs_store.lock
flock -n 9 || { echo "[ipfs-store] another build is running - exiting"; exit 0; }

STAGE=/var/ipfs-store
WEB=/var/www/html
GATEWAY_BASE=https://ipfs.eurobuddha.com
IPNS_KEY=pandastore
APKS_JSON_URL=https://raw.githubusercontent.com/eurobuddha/minima-core-apks/main/apks.json
SITE_SRC=/usr/local/share/ipfs-store/index.html
STATE_DIR=/var/lib/ipfs-store
CACHE=$STATE_DIR/cache

as_ipfs(){ sudo -u ipfs env IPFS_PATH=/home/ipfs/.ipfs "$@"; }
log(){ echo "[ipfs-store $(date '+%F %T')] $*"; }

mkdir -p "$STAGE" "$STATE_DIR" "$CACHE"

# ── 1. Mirror the two MiniDapp catalogs from the live webroot ────────────────
rsync -a --delete "$WEB/panda_dapps/" "$STAGE/panda_dapps/"
rsync -a --delete "$WEB/store/" "$STAGE/store/"
cp "$WEB/pandadapps.json" "$STAGE/pandadapps.src.json"

# ── 2-4. Download external assets, rewrite catalogs (relative + absolute) ────
STAGE=$STAGE CACHE=$CACHE GATEWAY_BASE=$GATEWAY_BASE APKS_JSON_URL=$APKS_JSON_URL \
python3 - <<'PY'
import hashlib, json, os, re, shutil, sys, urllib.request

STAGE = os.environ["STAGE"]
CACHE = os.environ["CACHE"]
GATEWAY = os.environ["GATEWAY_BASE"].rstrip("/")
APKS_URL = os.environ["APKS_JSON_URL"]

def fetch(url, dest, force=False, tries=2):
    """Download url to dest (skip if present unless force). True on success."""
    if os.path.exists(dest) and not force:
        return True
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    for attempt in range(tries):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "pandastore-ipfs-mirror"})
            with urllib.request.urlopen(req, timeout=120) as r, open(dest + ".tmp", "wb") as f:
                shutil.copyfileobj(r, f)
            os.replace(dest + ".tmp", dest)
            return True
        except Exception as e:
            print(f"WARN download failed ({attempt+1}/{tries}) {url}: {e}", file=sys.stderr)
    return False

def slug(name):
    return re.sub(r"[^a-z0-9]+", "-", name.lower()).strip("-")

def sha256_file(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()

def relativize(url, owner_slug):
    """Map a catalog URL to a snapshot-root-relative path.

    eurobuddha.com URLs are already mirrored by rsync; external URLs are
    downloaded into a cache (staging dirs get rsync --delete'd) and copied
    under panda_dapps/external/<owner>/.
    """
    if not isinstance(url, str) or not url.startswith(("http://", "https://")):
        return url
    for pref in ("https://eurobuddha.com/", "http://eurobuddha.com/",
                 "https://store.eurobuddha.com/", "http://store.eurobuddha.com/"):
        if url.startswith(pref):
            return url[len(pref):]
    base = url.rsplit("/", 1)[-1]
    rel = f"panda_dapps/external/{owner_slug}/{base}"
    cached = os.path.join(CACHE, rel)
    # 'releases/latest' URLs change content without changing name: always refetch
    if fetch(url, cached, force=("releases/latest" in url)):
        dest = os.path.join(STAGE, rel)
        os.makedirs(os.path.dirname(dest), exist_ok=True)
        shutil.copy2(cached, dest)
        return rel
    print(f"WARN keeping original URL (download failed): {url}", file=sys.stderr)
    return url

def write_pair(rel_path, data, url_fields):
    """Write <name>.json (root-relative paths) + <name>.abs.json (gateway URLs)."""
    def deep(obj, absolute):
        if isinstance(obj, dict):
            return {k: (f"{GATEWAY}/{v}" if absolute and k in url_fields
                        and isinstance(v, str) and not v.startswith("http")
                        else deep(v, absolute) if not (k in url_fields) else v)
                    for k, v in obj.items()}
        if isinstance(obj, list):
            return [deep(x, absolute) for x in obj]
        return obj
    with open(os.path.join(STAGE, rel_path), "w") as f:
        json.dump(data, f, indent=1, ensure_ascii=False)
    absname = rel_path[:-5] + ".abs.json"
    with open(os.path.join(STAGE, absname), "w") as f:
        json.dump(deep(data, True), f, indent=1, ensure_ascii=False)

URL_FIELDS = {"file", "icon"}

# --- pandadapps.json --------------------------------------------------------
with open(os.path.join(STAGE, "pandadapps.src.json")) as f:
    panda = json.load(f)
panda["icon"] = relativize(panda.get("icon", ""), "store")
for dapp in panda.get("dapps", []):
    s = slug(dapp.get("name", "dapp"))
    dapp["file"] = relativize(dapp.get("file", ""), s)
    dapp["icon"] = relativize(dapp.get("icon", ""), s)
write_pair("pandadapps.json", panda, URL_FIELDS)
os.remove(os.path.join(STAGE, "pandadapps.src.json"))
print(f"pandadapps: {len(panda.get('dapps', []))} dapps")

# --- store/minimadapps.json -------------------------------------------------
mpath = os.path.join(STAGE, "store", "minimadapps.json")
if os.path.exists(mpath):
    with open(mpath) as f:
        official = json.load(f)
    if isinstance(official.get("icon"), str):
        official["icon"] = relativize(official["icon"], "official-store")
    for dapp in official.get("dapps", []):
        s = slug(dapp.get("name", "dapp"))
        for k in ("file", "icon"):
            if isinstance(dapp.get(k), str):
                dapp[k] = relativize(dapp[k], s)
    write_pair("store/minimadapps.json", official, URL_FIELDS)
    print(f"official store: {len(official.get('dapps', []))} dapps")
else:
    print("WARN store/minimadapps.json missing", file=sys.stderr)

# --- apks/apks.json (native minimaCore catalog) -----------------------------
apks_dir = os.path.join(STAGE, "apks")
os.makedirs(os.path.join(apks_dir, "icons"), exist_ok=True)
apks_tmp = os.path.join(apks_dir, "apks.src.json")
apks = None
if fetch(APKS_URL, apks_tmp, force=True):
    with open(apks_tmp) as f:
        apks = json.load(f)
    os.remove(apks_tmp)
elif os.path.exists(os.path.join(apks_dir, "apks.json")):
    print("WARN apks.json fetch failed - keeping previous snapshot copy", file=sys.stderr)

if apks is not None:
    referenced = set()
    for app in apks.get("apps", []):
        fbase = app["file"].rsplit("/", 1)[-1]
        frel = f"apks/{fbase}"
        if fetch(app["file"], os.path.join(STAGE, frel)):
            want = app.get("sha256")
            if want:
                got = sha256_file(os.path.join(STAGE, frel))
                if got != want.lower():
                    print(f"WARN sha256 mismatch for {fbase} - refetching", file=sys.stderr)
                    if fetch(app["file"], os.path.join(STAGE, frel), force=True):
                        got = sha256_file(os.path.join(STAGE, frel))
                    if got != want.lower():
                        print(f"WARN sha256 STILL wrong for {fbase} (catalog carries "
                              f"the expected hash; client will verify)", file=sys.stderr)
            app["file"] = frel
            referenced.add(fbase)
        else:
            print(f"WARN apk unavailable, keeping original URL: {app['file']}", file=sys.stderr)
        icon = app.get("icon")
        if isinstance(icon, str) and icon.startswith("http"):
            ibase = icon.rsplit("/", 1)[-1]
            irel = f"apks/icons/{ibase}"
            if fetch(icon, os.path.join(STAGE, irel)):
                app["icon"] = irel
    # prune APKs no longer referenced (keeps snapshot at current-versions-only)
    for fn in os.listdir(apks_dir):
        p = os.path.join(apks_dir, fn)
        if os.path.isfile(p) and fn not in referenced and not fn.endswith(".json"):
            os.remove(p)
            print(f"pruned stale {fn}")
    write_pair("apks/apks.json", apks, URL_FIELDS)
    print(f"apks: {len(apks.get('apps', []))} apps")

# --- desktop placeholder ----------------------------------------------------
os.makedirs(os.path.join(STAGE, "desktop"), exist_ok=True)
readme = os.path.join(STAGE, "desktop", "README.txt")
if not os.path.exists(readme):
    with open(readme, "w") as f:
        f.write("minimaDesktop builds will be published here once released.\n")
PY

# ── 5. Store front-end ───────────────────────────────────────────────────────
cp "$SITE_SRC" "$STAGE/index.html"

# ── 6. Change detection ──────────────────────────────────────────────────────
chmod -R a+rX "$STAGE"
HASH=$(cd "$STAGE" && find . -type f -print0 | sort -z | xargs -0 sha256sum | sha256sum | cut -d' ' -f1)
LAST=$(cat "$STATE_DIR/last.hash" 2>/dev/null || echo none)
if [ "$HASH" = "$LAST" ]; then
    log "no changes since last publish - nothing to do"
    exit 0
fi

# ── 7. Add + IPNS publish ────────────────────────────────────────────────────
CID=$(as_ipfs ipfs add -r --cid-version 1 -Q "$STAGE")
log "snapshot CID: $CID"
as_ipfs ipfs name publish --key="$IPNS_KEY" --lifetime 48h "/ipfs/$CID"
log "IPNS published"

# ── 8. Pinata: pin new CID, drop superseded pins ─────────────────────────────
if as_ipfs ipfs pin remote service ls 2>/dev/null | awk '{print $1}' | grep -qx pinata; then
    if as_ipfs ipfs pin remote add --service=pinata --name "pandastore-$(date +%Y%m%d-%H%M)" "/ipfs/$CID"; then
        log "pinned to pinata"
        as_ipfs ipfs pin remote ls --service=pinata | awk -v cid="$CID" '$1 ~ /^(baf|Qm)/ && $1 != cid {print $1}' | \
        while read -r old; do
            as_ipfs ipfs pin remote rm --service=pinata --cid="$old" --force && log "unpinned old $old" || true
        done
    else
        log "WARN pinata pin failed (will retry next run)"
    fi
else
    log "pinata not configured - skipping remote pin"
fi

# ── 9. Record + local GC of superseded snapshots ─────────────────────────────
echo "$CID"  > "$WEB/ipfs-cid.txt" && chmod 644 "$WEB/ipfs-cid.txt"
echo "$HASH" > "$STATE_DIR/last.hash"
as_ipfs ipfs pin ls --type=recursive -q | grep -v "^$(as_ipfs ipfs cid base32 "$CID" 2>/dev/null || echo "$CID")$" | \
while read -r old; do as_ipfs ipfs pin rm "$old" >/dev/null 2>&1 || true; done
log "done - https://ipfs.eurobuddha.com/  |  /ipns/ipfs.eurobuddha.com  |  /ipfs/$CID"
