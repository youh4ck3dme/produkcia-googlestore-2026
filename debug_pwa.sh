#!/bin/bash

# Define Canary Path
CANARY_PATH="/Applications/Google Chrome Canary.app/Contents/MacOS/Google Chrome Canary"

# Check if Canary is installed
if [ ! -f "$CANARY_PATH" ]; then
    echo "❌ Google Chrome Canary not found at $CANARY_PATH"
    echo "⚠️  Falling back to Standard Chrome..."
    CANARY_PATH="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
fi

echo "🚀 Starting Chrome PWA Debug Mode..."

# Launch with flags
"$CANARY_PATH" \
  --user-data-dir="/tmp/chrome_pwa_debug_profile" \
  --no-first-run \
  --no-default-browser-check \
  --auto-open-devtools-for-tabs \
  --unsafely-treat-insecure-origin-as-secure="http://localhost:port" \
  --window-size=412,915 \
  "https://bizagent-live-2026.web.app"

echo "✅ Chrome launched in PWA Debug Mode."
