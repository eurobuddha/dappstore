#!/bin/bash
# Package the minimaCore App Store MiniDapp into an installable .mds.zip.
# CRITICAL: dapp.conf MUST be the first entry in the zip, or MiniHub silently fails to install.
set -e
cd "$(dirname "$0")"

VER=$(grep -o '"version"[^,]*' dapp.conf | grep -o '[0-9][0-9.]*' | head -1)
OUT="minimaCore-App-Store-${VER}.mds.zip"

rm -f "$OUT"
# dapp.conf first, then everything else.
zip "$OUT" dapp.conf >/dev/null
zip "$OUT" index.html mds.js favicon.png >/dev/null

echo "Built $OUT"
unzip -l "$OUT"
