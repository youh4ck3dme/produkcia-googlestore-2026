#!/usr/bin/env bash
# Zmenší build/web pred Vercel uploadom (CDN CanvasKit, bez junk súborov).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WEB="$ROOT/build/web"

[ -d "$WEB" ] || { echo "build/web neexistuje"; exit 1; }

BEFORE=$(du -sm "$WEB" | cut -f1)

# CanvasKit sa načíta z gstatic CDN (flutter_bootstrap.js → useLocalCanvasKit=false)
if [ -d "$WEB/canvaskit" ]; then
  rm -rf "$WEB/canvaskit"
  echo "✓ odstránený lokálny canvaskit/ (CDN)"
fi

find "$WEB" -name '.DS_Store' -delete 2>/dev/null || true
find "$WEB" -name '*.map' -delete 2>/dev/null || true
rm -rf "$WEB/.vercel" "$WEB/vercel.json" "$WEB/.env.local" 2>/dev/null || true

if [ -f "$WEB/favicon.png" ] && [ ! -f "$WEB/favicon.ico" ]; then
  cp "$WEB/favicon.png" "$WEB/favicon.ico"
fi

# SPA routing pre statický deploy build/web
cat > "$WEB/vercel.json" <<'EOF'
{
  "rewrites": [{ "source": "/(.*)", "destination": "/index.html" }],
  "redirects": [{ "source": "/favicon.ico", "destination": "/favicon.png", "permanent": false }],
  "headers": [
    {
      "source": "/(.*)",
      "headers": [{ "key": "Cross-Origin-Opener-Policy", "value": "same-origin-allow-popups" }]
    },
    {
      "source": "/index.html",
      "headers": [{ "key": "Cache-Control", "value": "no-cache, no-store, must-revalidate" }]
    },
    {
      "source": "/flutter_service_worker.js",
      "headers": [{ "key": "Cache-Control", "value": "no-cache, no-store, must-revalidate" }]
    },
    {
      "source": "/assets/(.*)",
      "headers": [{ "key": "Cache-Control", "value": "public, max-age=31536000, immutable" }]
    }
  ]
}
EOF

AFTER=$(du -sm "$WEB" | cut -f1)
echo "✓ build/web: ${BEFORE}MB → ${AFTER}MB"
