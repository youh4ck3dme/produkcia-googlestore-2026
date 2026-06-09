#!/usr/bin/env bash
# Live Supabase smoke test (skutočné HTTP — flutter test blokuje sieť).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEFINES="${SUPABASE_DEFINES:-$ROOT/dart_defines/supabase.json}"
PROJECT_REF="${SUPABASE_PROJECT_REF:-xitittqtaeyazcpaylsz}"

EMAIL="${SUPABASE_TEST_USER_EMAIL:-test+bizagent@example.com}"
PASSWORD="${SUPABASE_TEST_USER_PASSWORD:-}"
EMAIL_B="${SUPABASE_TEST_USER_B_EMAIL:-test2+bizagent@example.com}"
PASSWORD_B="${SUPABASE_TEST_USER_B_PASSWORD:-ci-test-user-b-pass}"
SERVICE_KEY="${SUPABASE_TEST_SERVICE_KEY:-}"

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

if [[ "$ANON" != eyJ* ]]; then
  LEGACY=$(supabase projects api-keys --project-ref "$PROJECT_REF" -o json 2>/dev/null | python3 -c "
import json,sys
for item in json.load(sys.stdin):
    if item.get('name')=='anon':
        print(item['api_key']); break
" || true)
  [[ -n "${LEGACY:-}" ]] && ANON="$LEGACY"
fi

if [[ -z "$SERVICE_KEY" ]]; then
  SERVICE_KEY=$(supabase projects api-keys --project-ref "$PROJECT_REF" -o json 2>/dev/null | python3 -c "
import json,sys
for item in json.load(sys.stdin):
    if item.get('name')=='service_role':
        print(item['api_key']); break
" || true)
fi

auth_sign_in() {
  local user_email=$1 user_password=$2
  local resp http body
  resp=$(curl -sS -w "\n%{http_code}" -X POST "$URL/auth/v1/token?grant_type=password" \
    -H "apikey: $ANON" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$user_email\",\"password\":\"$user_password\"}")
  http=$(echo "$resp" | tail -n1)
  body=$(echo "$resp" | sed '$d')
  if [[ "$http" != "200" ]]; then
    echo "Auth failed for $user_email HTTP $http"
    echo "$body"
    return 1
  fi
  echo "$body"
}

ensure_user_b() {
  if [[ -z "$SERVICE_KEY" ]]; then
    echo "WARN: SERVICE_KEY missing — RLS smoke skipped."
    return 1
  fi
  local http
  http=$(curl -sS -o /tmp/user_b.json -w "%{http_code}" -X POST "$URL/auth/v1/admin/users" \
    -H "apikey: $SERVICE_KEY" \
    -H "Authorization: Bearer $SERVICE_KEY" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$EMAIL_B\",\"password\":\"$PASSWORD_B\",\"email_confirm\":true}")
  if [[ "$http" != "200" && "$http" != "201" ]]; then
    local user_id
    user_id=$(curl -sS "$URL/auth/v1/admin/users?email=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$EMAIL_B'))")" \
      -H "apikey: $SERVICE_KEY" \
      -H "Authorization: Bearer $SERVICE_KEY" | python3 -c "
import json,sys
data=json.load(sys.stdin)
users=data.get('users') or []
print(users[0]['id'] if users else '')
")
    if [[ -n "$user_id" ]]; then
      curl -sS -X PUT "$URL/auth/v1/admin/users/$user_id" \
        -H "apikey: $SERVICE_KEY" \
        -H "Authorization: Bearer $SERVICE_KEY" \
        -H "Content-Type: application/json" \
        -d "{\"password\":\"$PASSWORD_B\",\"email_confirm\":true}" >/dev/null
    fi
  fi
  return 0
}

echo "==> Auth sign-in ($EMAIL)"
BODY_A=$(auth_sign_in "$EMAIL" "$PASSWORD")
ACCESS_TOKEN=$(echo "$BODY_A" | python3 -c "import json,sys; print(json.load(sys.stdin)['access_token'])")
USER_ID=$(echo "$BODY_A" | python3 -c "import json,sys; print(json.load(sys.stdin)['user']['id'])")
echo "Signed in as $USER_ID"

INVOICE_ID="ci-smoke-$(date +%s)"
ROW=$(python3 - <<PY
import json, datetime
print(json.dumps({
  "id": "$INVOICE_ID",
  "user_id": "$USER_ID",
  "data": {"id": "$INVOICE_ID", "number": "CI-SMOKE", "clientName": "Smoke", "totalAmount": 0, "status": "draft"},
  "updated_at": datetime.datetime.now(datetime.timezone.utc).isoformat().replace("+00:00", "Z"),
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

echo "==> Invoice select (owner)"
SELECT_HTTP=$(curl -sS -o /tmp/invoice_select.json -w "%{http_code}" \
  "$URL/rest/v1/invoices?id=eq.$INVOICE_ID&select=id" \
  -H "apikey: $ANON" \
  -H "Authorization: Bearer $ACCESS_TOKEN")
if [[ "$SELECT_HTTP" != "200" ]]; then
  echo "Select failed HTTP $SELECT_HTTP"
  exit 1
fi
python3 -c "import json; rows=json.load(open('/tmp/invoice_select.json')); assert len(rows)==1, rows"

if ensure_user_b; then
  echo "==> RLS: second user must not read foreign invoice"
  BODY_B=$(auth_sign_in "$EMAIL_B" "$PASSWORD_B")
  TOKEN_B=$(echo "$BODY_B" | python3 -c "import json,sys; print(json.load(sys.stdin)['access_token'])")
  curl -sS -o /tmp/invoice_rls.json \
    "$URL/rest/v1/invoices?id=eq.$INVOICE_ID&select=id" \
    -H "apikey: $ANON" \
    -H "Authorization: Bearer $TOKEN_B"
  python3 -c "import json; rows=json.load(open('/tmp/invoice_rls.json')); assert rows==[], rows"
  echo "RLS OK — foreign row hidden."
fi

RECEIPT_PATH="${USER_ID}/ci-smoke-$(date +%s).txt"
echo "==> Receipt upload ($RECEIPT_PATH)"
UPLOAD_HTTP=$(curl -sS -o /tmp/receipt_upload.json -w "%{http_code}" -X POST \
  "$URL/storage/v1/object/receipts/$RECEIPT_PATH" \
  -H "apikey: $ANON" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: text/plain" \
  --data-binary "ci-smoke-receipt")
if [[ "$UPLOAD_HTTP" != "200" && "$UPLOAD_HTTP" != "201" ]]; then
  echo "Receipt upload failed HTTP $UPLOAD_HTTP"
  cat /tmp/receipt_upload.json
  exit 1
fi

echo "==> Receipt delete"
RECEIPT_DEL_HTTP=$(curl -sS -o /tmp/receipt_del.json -w "%{http_code}" -X DELETE \
  "$URL/storage/v1/object/receipts/$RECEIPT_PATH" \
  -H "apikey: $ANON" \
  -H "Authorization: Bearer $ACCESS_TOKEN")
if [[ "$RECEIPT_DEL_HTTP" != "200" && "$RECEIPT_DEL_HTTP" != "204" ]]; then
  echo "Receipt delete failed HTTP $RECEIPT_DEL_HTTP"
  cat /tmp/receipt_del.json
  exit 1
fi

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
