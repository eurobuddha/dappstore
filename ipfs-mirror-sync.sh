#!/bin/bash
# Keep this host pinned to the CURRENT PandaDapps store snapshot. Runs on maxlite from a timer.
#
# PULL, NOT PUSH — and deliberately so. The obvious design has the Pi rsync its staged snapshot to
# the mirror and run `ipfs add` there, but that needs a root SSH key from the Pi to this box, ships
# 1.1 GB of files, and leaves the mirror stale whenever the Pi's build aborts. Instead the mirror
# reads one small file over HTTPS and fetches the snapshot over IPFS itself:
#
#   - no cross-host SSH trust, and no new key to hold or rotate
#   - bitswap moves only the blocks that actually CHANGED between snapshots, not the whole tree
#   - self-healing: if this box is down for a day, the next tick pins whatever is current, with no
#     queue to drain and nothing on the Pi that has to remember we exist
#   - the Pi's build cannot fail because of anything here, which is the standing rule that
#     redundancy is never a gate
#
# The Pi sits behind a residential NAT but advertises a public QUIC address, and both nodes carry
# each other in Peering.Peers, so kubo keeps the link up and reconnects on its own.
set -euo pipefail

CID_URL=https://eurobuddha.com/ipfs-cid.txt
FALLBACK_URL=https://store.eurobuddha.com/ipfs-cid.txt   # sally mirrors the webroot
IPFS_PATH=/var/lib/ipfs
STATE=/var/lib/ipfs-mirror/current.cid
FETCH_TIMEOUT=1800        # a first sync pulls ~1.1 GB over the Pi's home uplink

export IPFS_PATH
as_ipfs(){ sudo -u ipfs env IPFS_PATH="$IPFS_PATH" "$@"; }
log(){ echo "[ipfs-mirror $(date '+%F %T')] $*"; }

install -d -m 755 "$(dirname "$STATE")"

# single-instance: a slow first fetch must not overlap the next tick
exec 9>/var/lock/ipfs-mirror-sync.lock
flock -n 9 || { log "another sync is running - exiting"; exit 0; }

fetch_cid(){
    curl -fsSL --max-time 30 "$CID_URL" 2>/dev/null || curl -fsSL --max-time 30 "$FALLBACK_URL" 2>/dev/null || true
}

CID=$(fetch_cid | tr -d '[:space:]')
# Refuse anything that is not a CIDv1: an error page or a truncated read must never be pinned, and
# must never cause the CID we already hold to be dropped.
case "$CID" in
    bafy*) ;;
    *) log "WARN could not read a valid CID (got '${CID:0:40}') - keeping what we have"; exit 0 ;;
esac

HAVE=$(cat "$STATE" 2>/dev/null || echo none)
if [ "$CID" = "$HAVE" ] && as_ipfs ipfs pin ls --type=recursive -q 2>/dev/null | grep -qx "$CID"; then
    log "already pinned $CID"
    exit 0
fi

log "fetching $CID"
# --progress=false keeps the journal quiet; the timeout stops a dead peer wedging the timer.
if ! timeout "$FETCH_TIMEOUT" sudo -u ipfs env IPFS_PATH="$IPFS_PATH" \
        ipfs pin add --recursive --progress=false "$CID"; then
    log "WARN pin failed or timed out - will retry next tick (previous snapshot still pinned)"
    exit 0
fi
echo "$CID" > "$STATE"
log "pinned $CID"

# Drop superseded snapshots, then reclaim. Only AFTER the new pin succeeded, so a failed fetch can
# never leave this host holding nothing.
as_ipfs ipfs pin ls --type=recursive -q 2>/dev/null | grep -v "^$CID$" | while read -r old; do
    as_ipfs ipfs pin rm "$old" >/dev/null 2>&1 && log "unpinned superseded $old" || true
done
as_ipfs ipfs repo gc >/dev/null 2>&1 || true
log "done - this host now provides $CID"
