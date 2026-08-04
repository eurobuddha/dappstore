#!/bin/bash
# One-time: make maxlite (Maxima-Lite) a SECOND provider of the PandaDapps IPFS snapshot.
#
# WHY A SECOND PROVIDER. eurobuddha.com and ipfs.eurobuddha.com are the same machine — the Pi, on a
# residential line. The minimaCore App Store's IPFS Mirror tab falls back to a public gateway when
# the store server is unreachable, but a public gateway can only serve blocks it can FETCH from
# somebody. With one provider, that promise expires with the gateway's cache.
#
# WHY maxlite. sally has 563 MB of RAM and 13 GB of disk beside Apache. maxlite has ~780 MB free
# (plus 3.9 GB swap) and 34 GB free, and the snapshot is already 1.1 GB and grows with the catalogs.
#
# THIS BOX RUNS A LIVE MAXIMA RELAY (java, ~2.2 GB RSS). Everything here is bounded so the new
# service can never be the reason the old one dies:
#   - systemd MemoryMax/MemoryHigh, so the kernel caps kubo rather than reaping the relay
#   - DHT CLIENT mode: still publishes provider records and still serves bitswap to anyone who
#     dials us — all a second provider must do — while declining to carry others' DHT queries
#   - a small connection manager, Nice and idle I/O so the relay wins any contention
#
# kubo's memory is driven by peers and cache, NOT by the 1.1 GB of content — that is disk.
set -euo pipefail

KUBO_VER=v0.42.0                      # match the Pi exactly: same defaults => same CIDs
IPFS_HOME=/var/lib/ipfs
export IPFS_PATH=$IPFS_HOME

say(){ echo "[maxlite-ipfs] $*"; }

# ── 1. binary ────────────────────────────────────────────────────────────────
if command -v ipfs >/dev/null 2>&1 && ipfs version 2>/dev/null | grep -q "${KUBO_VER#v}"; then
    say "kubo ${KUBO_VER} already installed"
else
    cd /tmp
    TARBALL=kubo_${KUBO_VER}_linux-amd64.tar.gz
    say "downloading kubo ${KUBO_VER}"
    # --http1.1: dist.ipfs.tech dropped the HTTP/2 stream mid-transfer here
    # ("stream 1 was not closed cleanly: INTERNAL_ERROR"), which curl reports as a hard failure
    # rather than retrying. --retry-all-errors covers the transient rest.
    DL="curl -fsSL --http1.1 --retry 5 --retry-all-errors --continue-at -"
    $DL -o "$TARBALL" "https://dist.ipfs.tech/kubo/${KUBO_VER}/${TARBALL}"
    $DL -o "${TARBALL}.sha512" "https://dist.ipfs.tech/kubo/${KUBO_VER}/${TARBALL}.sha512"
    sed -E 's#\./##' "${TARBALL}.sha512" > /tmp/kubo.sha512      # dist file names it ./<tarball>
    sha512sum -c /tmp/kubo.sha512
    say "checksum OK"
    tar -xzf "$TARBALL"
    install -m 755 kubo/ipfs /usr/local/bin/ipfs
    rm -rf kubo "$TARBALL" "${TARBALL}.sha512" /tmp/kubo.sha512
fi
ipfs --version

# ── 2. unprivileged user + repo ──────────────────────────────────────────────
id -u ipfs >/dev/null 2>&1 || useradd --system --home-dir "$IPFS_HOME" --shell /usr/sbin/nologin ipfs
install -d -o ipfs -g ipfs -m 750 "$IPFS_HOME"

as_ipfs(){ sudo -u ipfs env IPFS_PATH="$IPFS_PATH" "$@"; }

if [ ! -f "$IPFS_HOME/config" ]; then
    say "initialising repo (server profile — no local-network discovery on a VPS)"
    as_ipfs ipfs init --profile server >/dev/null
else
    say "repo already initialised"
fi

# ── 3. bound it ──────────────────────────────────────────────────────────────
# API and gateway stay on loopback. An exposed /api/v0 is remote takeover of the node.
as_ipfs ipfs config Addresses.API /ip4/127.0.0.1/tcp/5001
as_ipfs ipfs config Addresses.Gateway /ip4/127.0.0.1/tcp/8080
as_ipfs ipfs config Routing.Type autoclient
as_ipfs ipfs config --json Swarm.ConnMgr.LowWater 20
as_ipfs ipfs config --json Swarm.ConnMgr.HighWater 50
# Announce only what we deliberately pinned — the snapshot — not every block we ever touched.
# kubo 0.42 RENAMED these (Reprovider.Strategy -> Provide.Strategy, Reprovider.Interval ->
# Provide.DHT.Interval) and refuses to start at all if the legacy keys are present:
#   FATAL Deprecated configuration detected. Manually migrate 'Reprovider' fields to 'Provide'
# `ipfs init` does not create them, so a legacy block only exists if an earlier run of THIS script
# wrote one — strip it, or the daemon crash-loops.
as_ipfs ipfs config Provide.Strategy pinned
as_ipfs ipfs config Provide.DHT.Interval 22h
as_ipfs ipfs config Datastore.StorageMax 4GB
python3 - "$IPFS_HOME/config" <<'PY'
import json, sys
path = sys.argv[1]
with open(path) as fh: cfg = json.load(fh)
if cfg.pop("Reprovider", None) is not None:
    with open(path, "w") as fh: json.dump(cfg, fh, indent=2)
    print("[maxlite-ipfs] removed legacy Reprovider block")
PY
chown ipfs:ipfs "$IPFS_HOME/config"
# Keep a persistent connection to the Pi. It is the only source of new blocks and it sits behind a
# residential NAT, so leaving the link to chance means a snapshot we cannot fetch.
as_ipfs ipfs config --json Peering.Peers '[{
  "ID": "12D3KooW9rxzTGSZviPVTEzYBfGBuqno9ib5HSPHfhYEkirSPGW6",
  "Addrs": ["/ip4/31.125.188.214/udp/4001/quic-v1"]
}]'

# ── 4. service ───────────────────────────────────────────────────────────────
cat > /etc/systemd/system/ipfs.service <<UNIT
[Unit]
Description=IPFS daemon (second provider for the PandaDapps store snapshot)
After=network-online.target
Wants=network-online.target

[Service]
User=ipfs
Group=ipfs
Environment=IPFS_PATH=$IPFS_HOME
ExecStart=/usr/local/bin/ipfs daemon --migrate=true
Restart=on-failure
RestartSec=10
# The Maxima relay is the priority on this box. Cap the NEW service so it can never starve it.
MemoryHigh=280M
MemoryMax=400M
Nice=10
IOSchedulingClass=idle
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=$IPFS_HOME

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable --now ipfs.service

# ── 5. swarm reachable ───────────────────────────────────────────────────────
# Being publicly dialable is the whole point: it is how a public gateway fetches from us when the
# Pi is unreachable.
ufw allow 4001/tcp comment 'ipfs swarm' >/dev/null 2>&1 || true
ufw allow 4001/udp comment 'ipfs swarm quic' >/dev/null 2>&1 || true

# ── 6. mirror sync timer ─────────────────────────────────────────────────────
# Pulls the current CID from the Pi's webroot and pins it. See ipfs-mirror-sync.sh for why this
# pulls rather than being pushed to.
if [ -f /tmp/ipfs-mirror-sync.sh ]; then
    install -m 755 /tmp/ipfs-mirror-sync.sh /usr/local/bin/ipfs-mirror-sync
fi

cat > /etc/systemd/system/ipfs-mirror-sync.service <<'UNIT'
[Unit]
Description=Pin the current PandaDapps store snapshot
After=ipfs.service
Requires=ipfs.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/ipfs-mirror-sync
Nice=10
IOSchedulingClass=idle
UNIT

cat > /etc/systemd/system/ipfs-mirror-sync.timer <<'UNIT'
[Unit]
Description=Check for a new PandaDapps store snapshot

[Timer]
OnBootSec=10min
OnUnitActiveSec=15min
RandomizedDelaySec=2min
Persistent=true

[Install]
WantedBy=timers.target
UNIT

systemctl daemon-reload
systemctl enable --now ipfs-mirror-sync.timer

# `systemctl is-active` exits non-zero while a unit is still "activating", which under `set -e`
# aborted this script before it could report anything. Wait for it instead.
for _ in $(seq 1 20); do
    [ "$(systemctl is-active ipfs.service || true)" = "active" ] && break
    sleep 2
done
STATE=$(systemctl is-active ipfs.service || true)
say "ipfs.service: $STATE"
[ "$STATE" = "active" ] || { journalctl -u ipfs.service -n 15 --no-pager; exit 1; }
say "peer id: $(as_ipfs ipfs id -f '<id>')"
say "ready"
