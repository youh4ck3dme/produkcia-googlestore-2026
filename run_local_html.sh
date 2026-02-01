#!/bin/bash

# 1. Definícia cesty ku Canary (upravil som aby to bolo robustné)
export CHROME_EXECUTABLE="/Applications/Google Chrome Canary.app/Contents/MacOS/Google Chrome Canary"

if [ ! -f "$CHROME_EXECUTABLE" ]; then
    echo "⚠️ Canary nenašiel, skúšam klasický Chrome..."
    export CHROME_EXECUTABLE="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
fi

# 2. Spustenie Flutteru s HTML rendererom (rýchlejší štart, menej náročný, ale horší blur)
# Používame port 5050 aby sme nemuseli hladať
echo "🚀 Spúšťam BizAgent lokálne (HTML Renderer)..."
flutter run -d chrome --web-port=5050
