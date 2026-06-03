#!/usr/bin/env bash
# Smoke test AI Cloud Function (aktuálne Gemini generateContent).
# Vyžaduje nasadené functions + platný GEMINI_API_KEY.
# Usage: ./scripts/test_cloud_ai.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [ ! -f test_gemini_direct.js ]; then
  echo "ERROR: test_gemini_direct.js chýba"
  exit 1
fi

echo "Testujem Cloud Function generateContent (Gemini backend)..."
node test_gemini_direct.js
