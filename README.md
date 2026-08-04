# dappstore

Manifests and store front-ends for the **PandaDapps** unofficial Minima MiniDapp store,
served from:

- https://eurobuddha.com/pandadapps.json
- https://store.eurobuddha.com/pandadapps.json (mirror)

## Contents

- `pandadapps.json` — the PandaDapps store manifest (`name`, `description`, `version`,
  `file`, `icon` per dapp).
- `minimadapps.json` — Minima official store manifest mirror.
- `pandadapps-site/`, `minimaofficial-site/`, `anydappstore/` — store front-end sources.
- `panda_dapps/` — dapp icons. The installable `*.mds.zip` builds live on the web
  server and are **not** committed here (some exceed GitHub's 100 MB limit).

## Publishing a dapp version

Upload the build to the server's `panda_dapps/` dir, point the dapp's entry in
`pandadapps.json` at the new `file`/`version`, then mirror to the store host
(`sync_store_to_sally.sh`). Keep this manifest in sync with the live one.
Finally run `/usr/local/bin/build_ipfs_store.sh` on the Pi (also runs hourly
from cron) to publish the updated IPFS snapshot.

## IPFS mirror

The full store — both MiniDapp catalogs, the native minimaCore APK catalog and
a browsable front-end — is snapshotted to IPFS by `build_ipfs_store.sh`
(deployed at `/usr/local/bin/` on the Pi; kubo node runs there as the `ipfs`
user, remote-pinned to Pinata for redundancy).

- `build_ipfs_store.sh` — stages `/var/ipfs-store`, rewrites catalogs to
  root-relative paths (plus `*.abs.json` variants with absolute
  `ipfs.eurobuddha.com` URLs for MDS store clients), downloads externally
  hosted zips/APKs so the snapshot is self-contained, then
  `ipfs add` → IPNS publish (`pandastore` key) → record the CID → remote pin
  rotation. The remote pin is **redundancy and never a gate**: it runs last and
  every failure is a warning, so a pinning outage cannot leave the store live on
  a CID that `ipfs-cid.txt` never recorded.

  **The remote pin service is `filebase` (`PIN_SERVICE`), not Pinata, and it is
  currently failing** — Filebase now returns `403 FORBIDDEN … requires a paid
  account` for the Pinning Service API. Redundancy is provided instead by a
  second self-hosted node (below); `PIN_SERVICE` stays wired so a paid service
  resumes automatically if one is ever configured.

## Second provider — maxlite

`eurobuddha.com` and `ipfs.eurobuddha.com` are **the same machine**, on a residential
line. The App Store's IPFS Mirror tab falls back to a public gateway when the store
server is unreachable, but a public gateway can only serve blocks it can fetch from
somebody — so with one provider that fallback expires with the gateway's cache.

`maxlite` runs a second kubo node holding the same snapshot:

- `maxlite_ipfs_setup.sh` — one-time provisioning. kubo pinned to the **same version as
  the Pi** (identical defaults ⇒ identical CIDs), DHT **client** mode, small connection
  manager, API/gateway on loopback, swarm 4001 open. The box runs a live Maxima relay,
  so the unit is capped (`MemoryMax=400M`, `Nice=10`, idle I/O) and cannot starve it.
  Settles around 155 MB.
- `ipfs-mirror-sync.sh` + timer (15 min) — **pulls**: reads `ipfs-cid.txt` over HTTPS and
  `ipfs pin add`s it. No SSH key from the Pi, no 1.1 GB rsync, and bitswap moves only the
  blocks that changed. If maxlite is down for a day the next tick pins whatever is current.
- Both nodes carry each other in `Peering.Peers`, so kubo keeps the link up and reconnects
  by itself — the Pi is NAT'd, so leaving that to chance means a snapshot maxlite cannot fetch.

Note the snapshot is **~1.1 GB**, not the 615 MB the script's older comments assume; it grows
as the catalogs gain apps.
- `ipfs-site/index.html` — the gateway-agnostic three-tab store UI at the
  snapshot root (deployed at `/usr/local/share/ipfs-store/index.html`).

Access:

- https://ipfs.eurobuddha.com/ (own gateway on the Pi)
- `/ipns/ipfs.eurobuddha.com/` on any public gateway (e.g.
  https://ipfs.io/ipns/ipfs.eurobuddha.com/)
- `/ipns/k51qzi5uqu5dk9g8mlhkab3t2h3195r4mwf6gdgpzte3cwhjn708w89y8b6axi`
  (raw IPNS key, DNS-free)
- current CID: https://eurobuddha.com/ipfs-cid.txt
