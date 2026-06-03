#!/usr/bin/env bash
# Overí sync GitHub ↔ lokál, Android identitu, Firebase JSON a core test gate.
# Usage: ./scripts/verify_repo_and_release.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ok() { echo -e "${GREEN}✓${NC} $*"; }
warn() { echo -e "${YELLOW}!${NC} $*"; }
fail() { echo -e "${RED}✗${NC} $*"; }

echo "BizAgent — verify repo & Play release readiness"
echo "==============================================="
echo ""

echo "── Git ──"
git fetch origin 2>/dev/null || warn "git fetch zlyhal (offline?)"
BEHIND=$(git rev-list --count HEAD..origin/main 2>/dev/null || echo "?")
AHEAD=$(git rev-list --count origin/main..HEAD 2>/dev/null || echo "?")
echo "Branch: $(git branch --show-current) | ahead: $AHEAD | behind: $BEHIND"
if [ "$BEHIND" != "0" ] && [ "$BEHIND" != "?" ]; then
  warn "Lokálny branch je behind origin — spusti: git pull origin main"
else
  ok "GitHub vetva stiahnutá (behind=0)"
fi
UNCOMMITTED=$(git status --porcelain | wc -l | tr -d ' ')
if [ "$UNCOMMITTED" -gt 0 ]; then
  warn "Necommitnutých zmien: $UNCOMMITTED súborov (normálne pre WIP)"
else
  ok "Working tree čistý"
fi
echo ""

echo "── Android identita ──"
APP_ID=$(grep -E 'applicationId\s*=' android/app/build.gradle.kts | head -1 | sed 's/.*"\(.*\)".*/\1/')
echo "applicationId: $APP_ID"
if [ "$APP_ID" = "sk.bizagent.app" ]; then
  ok "Play NEW listing package"
else
  fail "Očakávané sk.bizagent.app, je: $APP_ID"
fi
if [ -f android/key.properties ] && [ -f android/app/upload-keystore.jks ]; then
  ok "Upload keystore + key.properties"
else
  warn "Chýba signing — spusti: ./setup_android_play_signing.sh"
fi
if [ -f build/app/outputs/bundle/release/app-release.aab ]; then
  ls -lh build/app/outputs/bundle/release/app-release.aab
else
  warn "AAB ešte neexistuje — flutter build appbundle --release"
fi
echo ""

echo "── Firebase google-services.json ──"
if python3 - <<'PY'
import json, sys
p = "android/app/google-services.json"
d = json.load(open(p))
pkgs = [c["client_info"]["android_client_info"]["package_name"] for c in d.get("client", [])]
sys.exit(0 if "sk.bizagent.app" in pkgs else 1)
PY
then
  ok "google-services.json obsahuje sk.bizagent.app"
else
  fail "Chýba klient sk.bizagent.app — ./scripts/setup_firebase_android_sk_bizagent.sh"
fi
echo ""

echo "── Play MVP scope ──"
if grep -q 'playMvp' lib/core/config/play_release_scope.dart 2>/dev/null; then
  ok "PlayReleaseScope existuje (PLAY_MVP=true default)"
else
  warn "Chýba lib/core/config/play_release_scope.dart"
fi
echo ""

echo "── Firebase CLI ──"
if command -v firebase >/dev/null; then
  firebase login:list 2>/dev/null | head -3 || true
  firebase use 2>/dev/null | head -1 || warn "firebase use bizagent-live-2026"
else
  warn "firebase CLI nenájdený"
fi
echo ""

echo "── Core test gate ──"
if [ -x ./run_core_tests.sh ]; then
  ./run_core_tests.sh
else
  warn "run_core_tests.sh chýba"
fi
