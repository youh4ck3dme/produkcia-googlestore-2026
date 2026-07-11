#!/usr/bin/env bash
# Smoke: prihlásenie → home (dashboard)
# 1) Supabase REST auth (live HTTP)
# 2) Router redirect unit test (auth → /dashboard)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'
ok() { echo -e "${GREEN}✓${NC} $*"; }
fail() { echo -e "${RED}✗${NC} $*"; exit 1; }

EMAIL="${SMOKE_EMAIL:-bizagent@bizagent.sk}"
DEFINES="${SUPABASE_DEFINES:-$ROOT/dart_defines/supabase.json}"
PASSWORD_FILE="${PASSWORD_FILE:-$ROOT/.play_reviewer_password}"

if [[ -z "${SMOKE_PASSWORD:-}" ]]; then
  [[ -f "$PASSWORD_FILE" ]] || fail "Chýba $PASSWORD_FILE alebo SMOKE_PASSWORD"
  SMOKE_PASSWORD=$(cat "$PASSWORD_FILE")
fi

[[ -f "$DEFINES" ]] || fail "Chýba $DEFINES"

URL=$(python3 -c "import json; print(json.load(open('$DEFINES'))['SUPABASE_URL'])")
ANON=$(python3 -c "import json; print(json.load(open('$DEFINES'))['SUPABASE_PUBLISHABLE_KEY'])")

echo "BizAgent smoke — login → dashboard"
echo "================================="
echo ""

echo "1/2 Supabase REST prihlásenie ($EMAIL)"
HTTP=$(curl -sS -o /tmp/smoke_auth.json -w "%{http_code}" \
  -X POST "$URL/auth/v1/token?grant_type=password" \
  -H "apikey: $ANON" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$SMOKE_PASSWORD\"}")
if [[ "$HTTP" != "200" ]]; then
  cat /tmp/smoke_auth.json >&2
  fail "Auth API HTTP $HTTP"
fi
AUTH_EMAIL=$(python3 -c "import json; print(json.load(open('/tmp/smoke_auth.json'))['user']['email'])")
ok "Auth API OK — $AUTH_EMAIL"

echo ""
echo "2/2 Router redirect (unit test)"
if ! flutter test test/core/router/app_router_test.dart \
  --name "Redirects to /dashboard when authenticated" \
  --dart-define=PLAY_MVP=false >/tmp/smoke_router.log 2>&1; then
  tail -20 /tmp/smoke_router.log >&2
  fail "Router redirect test"
fi
ok "Router presmeruje prihláseného na /dashboard"

echo ""
echo "3/3 Produkcia bizagent.sk dostupná"
HTTP_SITE=$(curl -sS -o /dev/null -w "%{http_code}" "https://bizagent.sk/")
[[ "$HTTP_SITE" == "200" ]] || fail "bizagent.sk HTTP $HTTP_SITE"
ok "https://bizagent.sk HTTP 200"

echo ""
ok "Smoke PASS — auth API + router redirect + site live"
echo ""
echo "Manuálny UI test (Flutter web canvas — automatizácia nefunguje na release):"
echo "  1. Otvor https://bizagent.sk/#/login (Cmd+Shift+R)"
echo "  2. Email: $EMAIL"
echo "  3. Heslo: (v .play_reviewer_password)"
echo "  4. Po Prihlásiť sa → URL #/dashboard, nie ?code= ani #/login"