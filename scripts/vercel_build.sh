#!/usr/bin/env bash
# Vercel build — Flutter web (Play MVP). Ak už existuje build/web, preskočí (pre deploy_vercel.sh).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [ -f "build/web/index.html" ] && [ "${VERCEL_FORCE_REBUILD:-0}" != "1" ]; then
  echo "✓ build/web/index.html existuje — preskakujem rebuild (prebuilt deploy)"
  exit 0
fi

FLUTTER_DIR="${FLUTTER_ROOT:-$HOME/flutter}"
FLUTTER_CHANNEL="${FLUTTER_CHANNEL:-stable}"

if [ ! -x "$FLUTTER_DIR/bin/flutter" ]; then
  echo "→ Inštalujem Flutter SDK ($FLUTTER_CHANNEL)..."
  git clone https://github.com/flutter/flutter.git -b "$FLUTTER_CHANNEL" --depth 1 "$FLUTTER_DIR"
fi

export PATH="$FLUTTER_DIR/bin:$PATH"
export CI=true

flutter config --enable-web --no-analytics
flutter precache --web
flutter pub get

echo "→ Building Flutter web (PLAY_MVP=true)..."
flutter build web --release \
  --base-href "/" \
  --dart-define=PLAY_MVP=true \
  --web-resources-cdn \
  --no-wasm-dry-run

bash scripts/trim_web_build.sh

echo "✅ Web build: build/web"
