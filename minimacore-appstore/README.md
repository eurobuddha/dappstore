# minimaCore App Store (MiniDapp)

A MiniDapp for **Minima Classic** (the official MDS node with MiniHub) that is essentially a
web clone of the native **PandaApps** APK store. It gives users on a Minima node a path from
inside MiniHub to the native Android app ecosystem.

It fetches the **same** catalog the native PandaApps app reads —
`https://raw.githubusercontent.com/eurobuddha/minima-core-apks/main/apks.json` — and renders
every app (the minimaCore node APK, the PandaApps store, PandaPools, wallets, and the rest),
grouped exactly like the native app:

- **YOUR APPS** — `source: "PandaApps"`
- **OFFICIAL MINIMA** — `source: "Official"`
- **MORE** — everything else (desktop `.dmg` / `.exe` builds)

Each app shows its icon, name, version, category, and description, plus a **Download** button
that links to the entry's `file` URL.

## Download-only, by design

A MiniDapp runs in the MDS webview and **cannot** invoke Android's package installer (that is a
native-only capability). So this is a bootstrap: tap **Download** → the APK downloads to the
phone → the user installs it. Once they have **PandaApps**, that native app handles in-app
install and auto-update for everything else. Because it reads the live `apks.json`, this MiniDapp
is always current and needs no per-release maintenance.

## Files

| File | Purpose |
|------|---------|
| `dapp.conf` | MiniDapp manifest (name, version, icon, description, category) |
| `index.html` | The store UI — `MDS.net.GET` the catalog, render grouped cards + disclaimer |
| `mds.js` | The MDS library (fetch the external catalog without CORS issues) |
| `favicon.png` | Store icon (the PandaApps panda) |
| `build.sh` | Packages `*.mds.zip` with `dapp.conf` first (required by MiniHub) |

## Build

```bash
./build.sh          # → minimaCore-App-Store-<version>.mds.zip
```

## Publish

Hosted at `https://eurobuddha.com/panda_dapps/` and listed in the PandaDapps catalog
(`https://eurobuddha.com/pandadapps.json`). Deploy is over SSH/scp to the Apache server
(the GitHub repo is source-only and does not auto-publish):

```bash
scp minimaCore-App-Store-<ver>.mds.zip eurobuddha.com:/var/www/html/panda_dapps/
scp favicon.png                        eurobuddha.com:/var/www/html/panda_dapps/minimacore-appstore.png
# then add an entry to pandadapps.json and scp it to /var/www/html/pandadapps.json
```

## Licence

MIT © 2026 eurobuddha. Experimental software, provided **as is** — use at your own risk.
