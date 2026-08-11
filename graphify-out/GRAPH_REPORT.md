# Graph Report - tools/dappstore  (2026-08-05)

## Corpus Check
- 8 files · ~22,922 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 114 nodes · 123 edges · 19 communities (9 shown, 10 thin omitted)
- Extraction: 81% EXTRACTED · 19% INFERRED · 0% AMBIGUOUS · INFERRED: 23 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- render() — builds dapp card grid
- render() card builder
- pandadapps.json manifest
- AnyDappStore front-end (PocketWeb mini-site)
- Guardian background daemon
- MinimaOfficialDapps front-end
- build_ipfs_store.sh
- History MiniDapp
- Limit on-chain limit-order DEX
- Linternet Plaza MiniDapp
- maximizeSaver
- miniMerch merchant dapp
- miniMerch Inbox
- PocketFS decentralised file system
- PocketWeb decentralised browser
- Cross-link to MinimaOfficialDapps site
- ipfs-mirror-sync.sh
- maxlite_ipfs_setup.sh
- User instructions — AUTHORITATIVE. These override default behavior and must be followed exactly.

## God Nodes (most connected - your core abstractions)
1. `pandadapps.json manifest` - 6 edges
2. `dappstore` - 5 edges
3. `render() — builds dapp card grid` - 5 edges
4. `AnyDappStore front-end (PocketWeb mini-site)` - 5 edges
5. `build_ipfs_store.sh script` - 4 edges
6. `as_ipfs()` - 4 edges
7. `sync_remote_pin()` - 4 edges
8. `IPFS mirror` - 4 edges
9. `PandaDapps store` - 4 edges
10. `Publish flow` - 4 edges

## Surprising Connections (you probably didn't know these)
- `AnyDappStore front-end (PocketWeb mini-site)` --semantically_similar_to--> `PocketWeb pandadapps-site front-end`  [INFERRED] [semantically similar]
  anydappstore/index.html → ipfs-site/index.html
- `pandadapps.json catalog` --semantically_similar_to--> `Official MiniDapp catalog (minimadapps.json)`  [INFERRED] [semantically similar]
  store/index.html → minimaofficial-site/index.html
- `Classic Future Cash 2.7.1` --conceptually_related_to--> `pandadapps.json catalog`  [INFERRED]
  minimaofficial-site/futurecash/guide.html → store/index.html
- `IPFS mirror` --shares_data_with--> `pandadapps.json manifest`  [INFERRED]
  tools/dappstore/README.md → README.md
- `CLAUDE.md Rule 0 project rules` --rationale_for--> `PandaDapps store`  [INFERRED]
  CLAUDE.md → README.md

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **** — readme_panda_dapps_assets, readme_pandadapps_json, readme_sync_store_to_sally, readme_build_ipfs_store, readme_ipfs_mirror [EXTRACTED 1.00]
- **PocketWeb-proxied catalog load + install flow** — minimaofficial_site_index_front, minimaofficial_site_index_miniweb_proxy, minimaofficial_site_index_catalog, minimaofficial_site_index_install_flow [EXTRACTED 1.00]
- **Lock → mature → Guardian collect lifecycle** — minimaofficial_site_futurecash_guide_timelock, minimaofficial_site_futurecash_guide_maturity, minimaofficial_site_futurecash_guide_guardian, minimaofficial_site_futurecash_guide_collect_flow [EXTRACTED 1.00]
- **Key audit → reuse detection → rescue/harden** — minimaofficial_site_futurecash_guide_audit, minimaofficial_site_futurecash_guide_keyreuse, minimaofficial_site_futurecash_guide_rescue [EXTRACTED 1.00]

## Communities (19 total, 10 thin omitted)

### Community 0 - "render() — builds dapp card grid"
Cohesion: 0.18
Nodes (14): PandaDapps Site index.html, compareSemver() — version compare for update state, Dapp card (install / update / installed button states), findInstalled() — match catalog dapp to installed, installDapp(idx) — install flow handler, loadData() — dual fetch catalog + installed, mds command (node minidapps state), miniweb_InstallDapp() — install a dapp (+6 more)

### Community 1 - "render() card builder"
Cohesion: 0.15
Nodes (14): apks/apks.json catalog, store/minimadapps.json catalog, pandadapps.json catalog, Download-only buttons, escHtml/escAttr escaping, PandaDapps IPFS Store Front-End, normDesc() string-or-array normalizer, render() card builder (+6 more)

### Community 2 - "pandadapps.json manifest"
Cohesion: 0.14
Nodes (17): CLAUDE.md Rule 0 project rules, build_ipfs_store.sh IPFS publish, Contents, dappstore, IPFS mirror, ipfs-site/index.html three-tab UI, IPNS / DNSLink gateways, minimaCore APK catalog (+9 more)

### Community 3 - "AnyDappStore front-end (PocketWeb mini-site)"
Cohesion: 0.20
Nodes (11): User-supplied store catalog JSON (name/description/dapps[]), AnyDappStore front-end (PocketWeb mini-site), installDapp() install handler, miniweb_Init() bootstrap, miniweb_InstallDapp() install call, miniweb_JumpToURL("miniweb://pocketweb"), miniweb.js PocketWeb proxy library, miniweb_MdsCmd("mds") installed-list query (+3 more)

### Community 4 - "Guardian background daemon"
Cohesion: 0.24
Nodes (10): Future Cash user guide, Key audit service, Classic Future Cash 2.7.1, Collect flow, Guardian background daemon, WOTS key-reuse protection, Stake maturity (Pending/Matured), Rescue / Harden (at-risk sweep) (+2 more)

### Community 5 - "MinimaOfficialDapps front-end"
Cohesion: 0.28
Nodes (9): Official MiniDapp catalog (minimadapps.json), MinimaOfficialDapps front-end, Install/update dapp flow, miniweb_* PocketWeb proxy, No MDS in sandboxed iframe, PandaDapps sibling jump-link, Android APK downloads (Minima Core, PandaApps, FreezePeach), PandaDapps store landing page (+1 more)

### Community 6 - "build_ipfs_store.sh"
Cohesion: 0.73
Nodes (5): as_ipfs(), log(), remote_ls(), build_ipfs_store.sh script, sync_remote_pin()

### Community 16 - "ipfs-mirror-sync.sh"
Cohesion: 0.60
Nodes (3): as_ipfs(), log(), ipfs-mirror-sync.sh script

### Community 17 - "maxlite_ipfs_setup.sh"
Cohesion: 0.60
Nodes (4): as_ipfs(), IPFS_PATH, say(), maxlite_ipfs_setup.sh script

## Knowledge Gaps
- **35 isolated node(s):** `IPFS_PATH`, `RULE 0 (highest priority) — Follow the user's explicit instructions. They are BLOCKING, not suggestions.`, `Contents`, `Publishing a dapp version`, `Second provider — maxlite` (+30 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **10 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `AnyDappStore front-end (PocketWeb mini-site)` connect `AnyDappStore front-end (PocketWeb mini-site)` to `render() card builder`?**
  _High betweenness centrality (0.026) - this node is a cross-community bridge._
- **Are the 2 inferred relationships involving `pandadapps.json manifest` (e.g. with `IPFS mirror` and `minimadapps.json official mirror`) actually correct?**
  _`pandadapps.json manifest` has 2 INFERRED edges - model-reasoned connections that need verification._
- **What connects `IPFS_PATH`, `RULE 0 (highest priority) — Follow the user's explicit instructions. They are BLOCKING, not suggestions.`, `Contents` to the rest of the system?**
  _35 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `pandadapps.json manifest` be split into smaller, more focused modules?**
  _Cohesion score 0.1437908496732026 - nodes in this community are weakly interconnected._