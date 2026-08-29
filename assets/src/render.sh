#!/usr/bin/env bash
# Renders the README images from the HTML sources in this directory to ../*.png.
# Sized at 800px wide with large type so they stay legible on mobile screens.
# Requires a Chromium/Chrome binary ($CHROME if not on PATH) and Python Pillow
# (the crop removes the ~85px viewport offset headless Chrome adds).
set -euo pipefail
cd "$(dirname "$0")/.."
CHROME="${CHROME:-$(command -v chromium || command -v chromium-browser || command -v google-chrome)}"
render() {
  "$CHROME" --headless=new --no-sandbox --disable-gpu --hide-scrollbars \
    --window-size="800,$(($2 + 85))" --screenshot="$1.raw.png" "src/$1.html"
  python3 -c "from PIL import Image; Image.open('$1.raw.png').crop((0,0,800,$2)).save('$1.png')"
  rm "$1.raw.png"
}
render banner 300
render lifecycle 940
render forget-flow 960
