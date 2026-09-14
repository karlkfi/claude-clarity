#!/usr/bin/env bash
# Render assets/social-preview.html to the 1280x640 PNG GitHub wants for a
# repository social preview. Draws at 2x and downsamples, because text rendered
# straight to 1280x640 is visibly soft in a link card.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

chrome=${CHROME:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}
if [[ ! -x $chrome ]]; then
  echo "no Chrome at '$chrome'; set CHROME to a Chromium binary" >&2
  exit 1
fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

"$chrome" --headless=new --disable-gpu --hide-scrollbars \
  --window-size=1280,640 --force-device-scale-factor=2 \
  --screenshot="$tmp/2x.png" "file://$PWD/social-preview.html" >"$tmp/log" 2>&1

sips -z 640 1280 "$tmp/2x.png" --out social-preview.png >/dev/null

bytes=$(wc -c < social-preview.png)
(( bytes < 1000000 )) || { echo "social-preview.png is ${bytes}B; GitHub caps it at 1MB" >&2; exit 1; }
echo "social-preview.png: 1280x640, ${bytes}B"
