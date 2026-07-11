#!/bin/bash
# Export Google Play Store assets from existing brand/marketing sources.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

OUT_DIR="google_play_assets"
ICON_SRC="assets/icon/app_icon_1024.png"
DASHBOARD_SRC="assets/images/dashboard_empty_state.png"
LOGO_SRC="assets/images/biz_logo_brand.png"

mkdir -p "$OUT_DIR/icon" "$OUT_DIR/screenshots/phone"

echo "1/4 Exporting 512x512 app icon..."
sips -z 512 512 -s format png "$ICON_SRC" --out "$OUT_DIR/icon/hi-res-icon-512.png" >/dev/null
rm -f "$OUT_DIR/icon/hi-res-icon.png"

echo "2/4 Compositing feature graphic (1024x500)..."
PHONE_LAYER=$(mktemp).png
LOGO_LAYER=$(mktemp).png
trap 'rm -f "$PHONE_LAYER" "$LOGO_LAYER"' EXIT

magick "$DASHBOARD_SRC" \
  -gravity center -crop 900x1536+0+0 +repage \
  -resize 420x716 \
  "$PHONE_LAYER"

magick "$LOGO_SRC" \
  -resize 200x200 \
  -background none -alpha remove -alpha off \
  "$LOGO_LAYER"

magick -size 1024x500 \
  gradient:'#0B4EA2-#EE1C25' \
  "$PHONE_LAYER" -geometry +40+0 -composite \
  "$LOGO_LAYER" -geometry +760+80 -composite \
  -font '/System/Library/Fonts/Supplemental/Arial Bold.ttf' -pointsize 58 -fill white \
  -annotate +520+220 'BizAgent' \
  -font '/System/Library/Fonts/Supplemental/Arial.ttf' -pointsize 26 -fill white \
  -annotate +520+290 'Faktúry, Dane & AI Poradca' \
  -strip -define png:compression-level=9 \
  "$OUT_DIR/feature-graphic-1024x500.png"

echo "3/4 Exporting phone screenshots (1080x1920)..."
declare -a PAIRS=(
  "assets/images/dashboard_empty_state.png:$OUT_DIR/screenshots/phone/01-dashboard.png"
  "assets/images/invoices_empty_state.png:$OUT_DIR/screenshots/phone/02-invoices.png"
  "assets/images/ocr_scanning_feature.png:$OUT_DIR/screenshots/phone/03-expenses-ocr.png"
  "assets/images/ai_tools_feature.png:$OUT_DIR/screenshots/phone/04-ai-tools.png"
)

for pair in "${PAIRS[@]}"; do
  src="${pair%%:*}"
  dst="${pair##*:}"
  magick "$src" \
    -gravity center -crop 864x1536+0+0 +repage \
    -resize 1080x1920 \
    -strip -define png:compression-level=9 \
    "$dst"
done

echo "4/4 Validating assets..."
TOTAL_KB=$(du -sk "$OUT_DIR" | cut -f1)
if [ "$TOTAL_KB" -gt 15360 ]; then
  if command -v pngquant >/dev/null 2>&1; then
    echo "Total size > 15 MB, running pngquant on screenshots..."
    pngquant --quality=85-95 --force --ext .png "$OUT_DIR"/screenshots/phone/*.png
  else
    echo "Warning: total size > 15 MB and pngquant not installed."
  fi
fi

for f in \
  "$OUT_DIR/icon/hi-res-icon-512.png" \
  "$OUT_DIR/feature-graphic-1024x500.png" \
  "$OUT_DIR"/screenshots/phone/*.png; do
  w=$(sips -g pixelWidth "$f" 2>/dev/null | awk '/pixelWidth/ {print $2}')
  h=$(sips -g pixelHeight "$f" 2>/dev/null | awk '/pixelHeight/ {print $2}')
  echo "  $f -> ${w}x${h}"
done

echo "Total size: $(du -sh "$OUT_DIR" | cut -f1)"
echo "Done."
