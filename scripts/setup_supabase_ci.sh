#!/usr/bin/env bash
# Supabase + GitHub CI setup: migrácie, edge function, test user, GitHub Secrets.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PROJECT_REF="${SUPABASE_PROJECT_REF:-xitittqtaeyazcpaylsz}"
DEFINES="$ROOT/dart_defines/supabase.json"
TEST_EMAIL="${SUPABASE_TEST_USER_EMAIL:-test+bizagent@example.com}"
PASSWORD_FILE="$ROOT/.supabase_test_password"

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Inštalujem $1..."
    case "$1" in
      supabase)
        brew install supabase/tap/supabase
        ;;
      gh)
        brew install gh
        ;;
      *)
        echo "Chýba $1 — nainštaluj manuálne."
        exit 1
        ;;
    esac
  fi
}

need_cmd supabase
need_cmd gh
need_cmd flutter
need_cmd python3
need_cmd curl
need_cmd openssl

if [[ ! -f "$DEFINES" ]]; then
  if [[ -f "$ROOT/dart_defines/supabase.example.json" ]]; then
    cp "$ROOT/dart_defines/supabase.example.json" "$DEFINES"
    echo "Vytvorené $DEFINES — doplň SUPABASE_URL a SUPABASE_PUBLISHABLE_KEY z dashboardu."
    echo "Potom spusti tento skript znova."
    exit 1
  fi
  echo "Chýba $DEFINES"
  exit 1
fi

SUPABASE_URL=$(python3 -c "import json; print(json.load(open('$DEFINES'))['SUPABASE_URL'])")
PUBLISHABLE_KEY=$(python3 -c "import json; print(json.load(open('$DEFINES'))['SUPABASE_PUBLISHABLE_KEY'])")

echo "==> Link projekt $PROJECT_REF"
supabase link --project-ref "$PROJECT_REF" 2>/dev/null || true

echo "==> db push"
supabase db push

echo "==> deploy generate-content"
if ! supabase functions deploy generate-content --project-ref "$PROJECT_REF"; then
  echo "WARN: deploy generate-content zlyhal (Docker/CLI) — preskakujem ak funkcia už beží na remote."
  supabase functions list --project-ref "$PROJECT_REF" | rg -q generate-content || {
    echo "ERROR: generate-content nie je nasadená."
    exit 1
  }
fi

SERVICE_ROLE=$(supabase projects api-keys --project-ref "$PROJECT_REF" -o json | python3 -c "
import json,sys
for item in json.load(sys.stdin):
    if item.get('name')=='service_role':
        print(item['api_key']); break
")

if [[ -z "$SERVICE_ROLE" ]]; then
  echo "Nepodarilo sa načítať service_role key."
  exit 1
fi

if [[ -f "$PASSWORD_FILE" ]]; then
  TEST_PASSWORD=$(cat "$PASSWORD_FILE")
else
  TEST_PASSWORD=$(openssl rand -base64 24 | tr -d '/+=' | head -c 24)
  echo "$TEST_PASSWORD" > "$PASSWORD_FILE"
  chmod 600 "$PASSWORD_FILE"
fi

echo "==> CI test user: $TEST_EMAIL"
HTTP=$(curl -sS -o /tmp/supabase_user.json -w "%{http_code}" -X POST "$SUPABASE_URL/auth/v1/admin/users" \
  -H "apikey: $SERVICE_ROLE" \
  -H "Authorization: Bearer $SERVICE_ROLE" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASSWORD\",\"email_confirm\":true}")

if [[ "$HTTP" != "200" && "$HTTP" != "201" ]]; then
  USER_ID=$(curl -sS "$SUPABASE_URL/auth/v1/admin/users?email=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$TEST_EMAIL'))")" \
    -H "apikey: $SERVICE_ROLE" \
    -H "Authorization: Bearer $SERVICE_ROLE" | python3 -c "
import json,sys
data=json.load(sys.stdin)
users=data.get('users') or []
print(users[0]['id'] if users else '')
")
  if [[ -n "$USER_ID" ]]; then
    curl -sS -X PUT "$SUPABASE_URL/auth/v1/admin/users/$USER_ID" \
      -H "apikey: $SERVICE_ROLE" \
      -H "Authorization: Bearer $SERVICE_ROLE" \
      -H "Content-Type: application/json" \
      -d "{\"password\":\"$TEST_PASSWORD\",\"email_confirm\":true}" >/dev/null
    echo "Heslo existujúceho test usera synchronizované."
  fi
else
  echo "Test user vytvorený."
fi

SIGNIN_HTTP=$(curl -sS -o /dev/null -w "%{http_code}" -X POST "$SUPABASE_URL/auth/v1/token?grant_type=password" \
  -H "apikey: $PUBLISHABLE_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASSWORD\"}")
echo "Sign-in check: HTTP $SIGNIN_HTTP"

echo "==> GitHub Secrets (repo: $(gh repo view --json nameWithOwner -q .nameWithOwner))"
printf '%s' "$SUPABASE_URL" | gh secret set SUPABASE_TEST_URL
printf '%s' "$PUBLISHABLE_KEY" | gh secret set SUPABASE_TEST_PUBLISHABLE_KEY
printf '%s' "$SERVICE_ROLE" | gh secret set SUPABASE_TEST_SERVICE_KEY
printf '%s' "$TEST_EMAIL" | gh secret set SUPABASE_TEST_USER_EMAIL
printf '%s' "$TEST_PASSWORD" | gh secret set SUPABASE_TEST_USER_PASSWORD
echo "GitHub secrets nastavené."

echo "==> Live smoke (HTTP)"
export SUPABASE_DEFINES="$DEFINES"
export SUPABASE_TEST_USER_EMAIL="$TEST_EMAIL"
export SUPABASE_TEST_USER_PASSWORD="$TEST_PASSWORD"
bash "$ROOT/scripts/verify_supabase_live.sh"

echo "==> Dart integration stubs (SKIP_SUPABASE_LIVE)"
flutter test test/integration/supabase/ \
  --dart-define-from-file="$DEFINES" \
  --dart-define=SKIP_SUPABASE_LIVE=true \
  --dart-define=PLAY_MVP=true

echo ""
echo "Hotovo."
echo "- Lokálne heslo: $PASSWORD_FILE"
echo "- Spustenie app: bash scripts/run_with_supabase.sh"
echo "- CI workflow: .github/workflows/supabase_integration_test.yml"
