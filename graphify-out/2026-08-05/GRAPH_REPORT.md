# Graph Report - .  (2026-07-28)

## Corpus Check
- Corpus is ~19,740 words - fits in a single context window. You may not need a graph.

## Summary
- 95 nodes · 102 edges · 16 communities (7 shown, 9 thin omitted)
- Extraction: 77% EXTRACTED · 23% INFERRED · 0% AMBIGUOUS · INFERRED: 23 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- PandaDapps PocketWeb Front-End
- IPFS Store Front-End
- Store Manifests & Publish Pipeline
- AnyDappStore Universal Installer
- Future Cash & WOTS Safety
- MinimaOfficial Front-End
- IPFS Build Script
- History MiniDapp
- Limit DEX
- Linternet Plaza
- maximizeSaver
- miniMerch Shop
- miniMerch Inbox
- PocketFS
- PocketWeb
- Cross-Site Navigation

## God Nodes (most connected - your core abstractions)
1. `pandadapps.json manifest` - 6 edges
2. `render() — builds dapp card grid` - 5 edges
3. `AnyDappStore front-end (PocketWeb mini-site)` - 5 edges
4. `build_ipfs_store.sh script` - 4 edges
5. `sync_remote_pin()` - 4 edges
6. `PandaDapps store` - 4 edges
7. `Publish flow` - 4 edges
8. `build_ipfs_store.sh IPFS publish` - 4 edges
9. `installDapp(idx) — install flow handler` - 4 edges
10. `MinimaOfficialDapps front-end` - 4 edges

## Surprising Connections (you probably didn't know these)
- `AnyDappStore front-end (PocketWeb mini-site)` --semantically_similar_to--> `PocketWeb pandadapps-site front-end`  [INFERRED] [semantically similar]
  anydappstore/index.html → ipfs-site/index.html
- `pandadapps.json catalog` --semantically_similar_to--> `Official MiniDapp catalog (minimadapps.json)`  [INFERRED] [semantically similar]
  store/index.html → minimaofficial-site/index.html
- `Classic Future Cash 2.7.1` --conceptually_related_to--> `pandadapps.json catalog`  [INFERRED]
  minimaofficial-site/futurecash/guide.html → store/index.html
- `CLAUDE.md Rule 0 project rules` --rationale_for--> `PandaDapps store`  [INFERRED]
  CLAUDE.md → README.md
- `PandaDapps sibling jump-link` --conceptually_related_to--> `PandaDapps store landing page`  [INFERRED]
  minimaofficial-site/index.html → store/index.html

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **** — readme_panda_dapps_assets, readme_pandadapps_json, readme_sync_store_to_sally, readme_build_ipfs_store, readme_ipfs_mirror [EXTRACTED 1.00]
- **PocketWeb-proxied catalog load + install flow** — minimaofficial_site_index_front, minimaofficial_site_index_miniweb_proxy, minimaofficial_site_index_catalog, minimaofficial_site_index_install_flow [EXTRACTED 1.00]
- **Lock → mature → Guardian collect lifecycle** — minimaofficial_site_futurecash_guide_timelock, minimaofficial_site_futurecash_guide_maturity, minimaofficial_site_futurecash_guide_guardian, minimaofficial_site_futurecash_guide_collect_flow [EXTRACTED 1.00]
- **Key audit → reuse detection → rescue/harden** — minimaofficial_site_futurecash_guide_audit, minimaofficial_site_futurecash_guide_keyreuse, minimaofficial_site_futurecash_guide_rescue [EXTRACTED 1.00]

## Communities (16 total, 9 thin omitted)

### Community 0 - "PandaDapps PocketWeb Front-End"
Cohesion: 0.18
Nodes (14): PandaDapps Site index.html, compareSemver() — version compare for update state, Dapp card (install / update / installed button states), findInstalled() — match catalog dapp to installed, installDapp(idx) — install flow handler, loadData() — dual fetch catalog + installed, mds command (node minidapps state), miniweb_InstallDapp() — install a dapp (+6 more)

### Community 1 - "IPFS Store Front-End"
Cohesion: 0.15
Nodes (14): apks/apks.json catalog, store/minimadapps.json catalog, pandadapps.json catalog, Download-only buttons, escHtml/escAttr escaping, PandaDapps IPFS Store Front-End, normDesc() string-or-array normalizer, render() card builder (+6 more)

### Community 2 - "Store Manifests & Publish Pipeline"
Cohesion: 0.22
Nodes (13): CLAUDE.md Rule 0 project rules, build_ipfs_store.sh IPFS publish, IPFS mirror snapshot, ipfs-site/index.html three-tab UI, IPNS / DNSLink gateways, minimaCore APK catalog, minimadapps.json official mirror, panda_dapps/ icons dir (+5 more)

### Community 3 - "AnyDappStore Universal Installer"
Cohesion: 0.20
Nodes (11): User-supplied store catalog JSON (name/description/dapps[]), AnyDappStore front-end (PocketWeb mini-site), installDapp() install handler, miniweb_Init() bootstrap, miniweb_InstallDapp() install call, miniweb_JumpToURL("miniweb://pocketweb"), miniweb.js PocketWeb proxy library, miniweb_MdsCmd("mds") installed-list query (+3 more)

### Community 4 - "Future Cash & WOTS Safety"
Cohesion: 0.24
Nodes (10): Future Cash user guide, Key audit service, Classic Future Cash 2.7.1, Collect flow, Guardian background daemon, WOTS key-reuse protection, Stake maturity (Pending/Matured), Rescue / Harden (at-risk sweep) (+2 more)

### Community 5 - "MinimaOfficial Front-End"
Cohesion: 0.28
Nodes (9): Official MiniDapp catalog (minimadapps.json), MinimaOfficialDapps front-end, Install/update dapp flow, miniweb_* PocketWeb proxy, No MDS in sandboxed iframe, PandaDapps sibling jump-link, Android APK downloads (Minima Core, PandaApps, FreezePeach), PandaDapps store landing page (+1 more)

### Community 6 - "IPFS Build Script"
Cohesion: 0.90
Nodes (4): as_ipfs(), log(), build_ipfs_store.sh script, sync_remote_pin()

## Knowledge Gaps
- **30 isolated node(s):** `Store front-end sources`, `minimaCore APK catalog`, `CLAUDE.md Rule 0 project rules`, `History dapp icon`, `History MiniDapp` (+25 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **9 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `AnyDappStore front-end (PocketWeb mini-site)` connect `AnyDappStore Universal Installer` to `IPFS Store Front-End`?**
  _High betweenness centrality (0.037) - this node is a cross-community bridge._
- **Are the 2 inferred relationships involving `pandadapps.json manifest` (e.g. with `IPFS mirror snapshot` and `minimadapps.json official mirror`) actually correct?**
  _`pandadapps.json manifest` has 2 INFERRED edges - model-reasoned connections that need verification._
- **What connects `Store front-end sources`, `minimaCore APK catalog`, `CLAUDE.md Rule 0 project rules` to the rest of the system?**
  _30 weakly-connected nodes found - possible documentation gaps or missing edges._