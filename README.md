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
