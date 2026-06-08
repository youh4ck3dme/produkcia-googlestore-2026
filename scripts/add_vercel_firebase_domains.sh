#!/usr/bin/env bash
# Pridá Vercel domény do Firebase Auth authorized domains (bizagent-live-2026).
# Spusti raz po novom Vercel preview/prod URL.
set -euo pipefail

PROJECT="bizagent-live-2026"
DOMAINS=(
  "biz-agent-web.vercel.app"
  "web-32q457c0j-h4ck3d.vercel.app"
  "localhost"
)

echo "Firebase Auth — authorized domains pre $PROJECT"
echo "Manuálne (najrýchlejšie):"
echo "  https://console.firebase.google.com/project/$PROJECT/authentication/settings"
echo ""
echo "Pridaj domény:"
for d in "${DOMAINS[@]}"; do echo "  • $d"; done
echo ""
echo "Pre preview deploye (*.vercel.app) pridávaj konkrétnu URL z Vercel logu po deployi."
