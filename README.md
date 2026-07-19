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
  `ipfs add` → IPNS publish (`pandastore` key) → Pinata pin rotation.
- `ipfs-site/index.html` — the gateway-agnostic three-tab store UI at the
  snapshot root (deployed at `/usr/local/share/ipfs-store/index.html`).

Access:

- https://ipfs.eurobuddha.com/ (own gateway on the Pi)
- `/ipns/ipfs.eurobuddha.com/` on any public gateway (e.g.
  https://ipfs.io/ipns/ipfs.eurobuddha.com/)
- `/ipns/k51qzi5uqu5dk9g8mlhkab3t2h3195r4mwf6gdgpzte3cwhjn708w89y8b6axi`
  (raw IPNS key, DNS-free)
- current CID: https://eurobuddha.com/ipfs-cid.txt
