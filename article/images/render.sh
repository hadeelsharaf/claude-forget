#!/usr/bin/env bash
# Renders the article figures from the HTML sources in src/ to PNG.
# Requires any Chromium/Chrome binary; pass its path as $CHROME if not on PATH.
set -euo pipefail
cd "$(dirname "$0")"
CHROME="${CHROME:-$(command -v chromium || command -v chromium-browser || command -v google-chrome)}"
render() { "$CHROME" --headless=new --no-sandbox --disable-gpu --hide-scrollbars \
  --window-size="1400,$2" --screenshot="$1.png" "src/$1.html"; }
render 01-stacking-timeline 800
render 02-model-tiers 720
render 03-investigation-stats 580
render 04-reinstall-filter 900
