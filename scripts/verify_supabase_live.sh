#!/usr/bin/env bash
# Live Supabase smoke test (skutočné HTTP — flutter test blokuje sieť).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEFINES="${SUPABASE_DEFINES:-$ROOT/dart_defines/supabase.json}"
PROJECT_REF="${SUPABASE_PROJECT_REF:-xitittqtaeyazcpaylsz}"

EMAIL="${SUPABASE_TEST_USER_EMAIL:-test+bizagent@example.com}"
PASSWORD="${SUPABASE_TEST_USER_PASSWORD:-}"

if [[ -f "$ROOT/.supabase_test_password" && -z "$PASSWORD" ]]; then
  PASSWORD=$(cat "$ROOT/.supabase_test_password")
fi

if [[ ! -f "$DEFINES" ]]; then
  echo "Chýba $DEFINES"
  exit 1
fi

if [[ -z "$PASSWORD" ]]; then
  echo "Chýba SUPABASE_TEST_USER_PASSWORD alebo $ROOT/.supabase_test_password"
  exit 1
fi

URL=$(python3 -c "import json; print(json.load(open('$DEFINES'))['SUPABASE_URL'])")
ANON=$(python3 -c "import json; print(json.load(open('$DEFINES'))['SUPABASE_PUBLISHABLE_KEY'])")

# Fallback na legacy anon JWT ak publishable zlyhá
if [[ "$ANON" != eyJ* ]]; then
  LEGACY=$(supabase projects api-keys --project-ref "$PROJECT_REF" -o json 2>/dev/null | python3 -c "
import json,sys
for item in json.load(sys.stdin):
    if item.get('name')=='anon':
        print(item['api_key']); break
" || true)
  [[ -n "${LEGACY:-}" ]] && ANON="$LEGACY"
fi

echo "==> Auth sign-in ($EMAIL)"
TOKEN_RESP=$(curl -sS -w "\n%{http_code}" -X POST "$URL/auth/v1/token?grant_type=password" \
  -H "apikey: $ANON" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}")
HTTP=$(echo "$TOKEN_RESP" | tail -n1)
BODY=$(echo "$TOKEN_RESP" | sed '$d')
if [[ "$HTTP" != "200" ]]; then
  echo "Auth failed HTTP $HTTP"
  echo "$BODY"
  exit 1
fi

ACCESS_TOKEN=$(echo "$BODY" | python3 -c "import json,sys; print(json.load(sys.stdin)['access_token'])")
USER_ID=$(echo "$BODY" | python3 -c "import json,sys; print(json.load(sys.stdin)['user']['id'])")
echo "Signed in as $USER_ID"

INVOICE_ID="ci-smoke-$(date +%s)"
ROW=$(python3 - <<PY
import json, datetime
print(json.dumps({
  "id": "$INVOICE_ID",
  "user_id": "$USER_ID",
  "data": {"id": "$INVOICE_ID", "number": "CI-SMOKE", "clientName": "Smoke", "totalAmount": 0, "status": "draft"},
  "updated_at": datetime.datetime.utcnow().isoformat() + "Z",
}))
PY
)

echo "==> Invoice upsert"
UPSERT_HTTP=$(curl -sS -o /tmp/invoice_upsert.json -w "%{http_code}" -X POST "$URL/rest/v1/invoices" \
  -H "apikey: $ANON" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -H "Prefer: resolution=merge-duplicates" \
  -d "$ROW")
if [[ "$UPSERT_HTTP" != "201" && "$UPSERT_HTTP" != "200" ]]; then
  echo "Upsert failed HTTP $UPSERT_HTTP"
  cat /tmp/invoice_upsert.json
  exit 1
fi

echo "==> Invoice select"
SELECT_HTTP=$(curl -sS -o /tmp/invoice_select.json -w "%{http_code}" \
  "$URL/rest/v1/invoices?id=eq.$INVOICE_ID&select=id" \
  -H "apikey: $ANON" \
  -H "Authorization: Bearer $ACCESS_TOKEN")
if [[ "$SELECT_HTTP" != "200" ]]; then
  echo "Select failed HTTP $SELECT_HTTP"
  exit 1
fi
python3 -c "import json; rows=json.load(open('/tmp/invoice_select.json')); assert len(rows)==1, rows"

echo "==> Invoice delete"
DELETE_HTTP=$(curl -sS -o /dev/null -w "%{http_code}" -X DELETE \
  "$URL/rest/v1/invoices?id=eq.$INVOICE_ID" \
  -H "apikey: $ANON" \
  -H "Authorization: Bearer $ACCESS_TOKEN")
if [[ "$DELETE_HTTP" != "204" && "$DELETE_HTTP" != "200" ]]; then
  echo "Delete failed HTTP $DELETE_HTTP"
  exit 1
fi

echo "Supabase live smoke: OK"
