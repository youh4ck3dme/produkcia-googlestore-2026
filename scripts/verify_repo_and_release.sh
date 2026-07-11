#!/usr/bin/env bash
# Overí sync GitHub ↔ lokál, Android identitu, Firebase JSON a core test gate.
# Usage: ./scripts/verify_repo_and_release.sh [--require-aab]
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

REQUIRE_AAB=false
for arg in "$@"; do
  case "$arg" in
    --require-aab) REQUIRE_AAB=true ;;
    -h|--help)
      echo "Usage: ./scripts/verify_repo_and_release.sh [--require-aab]"
      exit 0
      ;;
    *)
      echo "Neznámy argument: $arg" >&2
      exit 1
      ;;
  esac
done

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ok() { echo -e "${GREEN}✓${NC} $*"; }
warn() { echo -e "${YELLOW}!${NC} $*"; }
fail() { echo -e "${RED}✗${NC} $*"; exit 1; }

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

echo "── Supabase defines ──"
if [ -f dart_defines/supabase.json ]; then
  if python3 - <<'PY'
import json, sys
d = json.load(open("dart_defines/supabase.json"))
url = (d.get("SUPABASE_URL") or "").strip()
key = (d.get("SUPABASE_PUBLISHABLE_KEY") or d.get("SUPABASE_ANON_KEY") or "").strip()
bad = not url or "YOUR_PROJECT" in url or "REPLACE" in url
bad = bad or not key or "YOUR_KEY" in key or "REPLACE" in key
sys.exit(1 if bad else 0)
PY
  then
    ok "dart_defines/supabase.json — URL + key nastavené"
  else
    fail "dart_defines/supabase.json obsahuje placeholder — doplň pred release buildom"
  fi
else
  warn "Chýba dart_defines/supabase.json — ./build_release_aab.sh zlyhá"
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
AAB_PATH="build/app/outputs/bundle/release/app-release.aab"
if [ -f "$AAB_PATH" ]; then
  ls -lh "$AAB_PATH"
  if unzip -p "$AAB_PATH" base/lib/arm64-v8a/libapp.so 2>/dev/null | strings | rg -q 'supabase\.co'; then
    ok "AAB obsahuje Supabase URL (dart defines OK)"
  else
    if [ "$REQUIRE_AAB" = true ]; then
      fail "AAB existuje, ale Supabase URL chýba v libapp.so — rebuild s ./build_release_aab.sh"
    else
      warn "AAB existuje, ale Supabase URL nenájdená — rebuild s ./build_release_aab.sh"
    fi
  fi
else
  if [ "$REQUIRE_AAB" = true ]; then
    fail "AAB neexistuje — spusti: ./build_release_aab.sh"
  else
    warn "AAB ešte neexistuje — spusti: ./build_release_aab.sh"
  fi
fi
echo ""

echo "── Play reviewer account ──"
if [ -f scripts/seed_play_reviewer_account.sh ]; then
  ok "seed_play_reviewer_account.sh existuje"
else
  warn "Chýba scripts/seed_play_reviewer_account.sh"
fi
if [ -f .play_reviewer_password ]; then
  ok "Play reviewer heslo (.play_reviewer_password)"
else
  warn "Chýba .play_reviewer_password — spusti: bash scripts/seed_play_reviewer_account.sh"
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
