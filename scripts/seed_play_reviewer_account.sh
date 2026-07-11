#!/usr/bin/env bash
# Vytvorí/aktualizuje Supabase Play reviewer účet + seed dáta pre Google Play review.
#
# Usage:
#   bash scripts/seed_play_reviewer_account.sh
#   bash scripts/seed_play_reviewer_account.sh --force-password
#   bash scripts/seed_play_reviewer_account.sh --verbose
#
# Vyžaduje: supabase CLI (logged in), dart_defines/supabase.json s URL + publishable key.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PROJECT_REF="${SUPABASE_PROJECT_REF:-kpsnwpuydqqojwmrnkdy}"
PLAY_REVIEWER_EMAIL="${PLAY_REVIEWER_EMAIL:-bizagent@bizagent.sk}"
PASSWORD_FILE="${PASSWORD_FILE:-$ROOT/.play_reviewer_password}"
SUPABASE_DEFINES="${SUPABASE_DEFINES:-$ROOT/dart_defines/supabase.json}"
FORCE_PASSWORD=false
VERBOSE=false

for arg in "$@"; do
  case "$arg" in
    --force-password) FORCE_PASSWORD=true ;;
    --verbose) VERBOSE=true ;;
    -h|--help)
      echo "Usage: bash scripts/seed_play_reviewer_account.sh [--force-password] [--verbose]"
      exit 0
      ;;
    *)
      echo "Neznámy argument: $arg" >&2
      exit 1
      ;;
  esac
done

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "ERROR: chýba príkaz '$1'" >&2
    exit 1
  fi
}

need_cmd supabase
need_cmd curl
need_cmd python3
need_cmd openssl

if [[ ! -f "$SUPABASE_DEFINES" ]]; then
  echo "ERROR: chýba $SUPABASE_DEFINES" >&2
  echo "  cp dart_defines/supabase.example.json dart_defines/supabase.json" >&2
  exit 1
fi

read -r SUPABASE_URL PUBLISHABLE_KEY <<EOF
$(python3 -c "
import json, sys
d = json.load(open('$SUPABASE_DEFINES'))
url = (d.get('SUPABASE_URL') or '').strip()
key = (d.get('SUPABASE_PUBLISHABLE_KEY') or d.get('SUPABASE_ANON_KEY') or '').strip()
if not url or 'YOUR_PROJECT' in url or 'REPLACE' in url:
    sys.exit('invalid url')
if not key or 'YOUR_KEY' in key or 'REPLACE' in key:
    sys.exit('invalid key')
print(url)
print(key)
")
EOF

SERVICE_ROLE=$(supabase projects api-keys --project-ref "$PROJECT_REF" -o json | python3 -c "
import json, sys
for item in json.load(sys.stdin):
    if item.get('name') == 'service_role':
        print(item['api_key'])
        break
")

if [[ -z "$SERVICE_ROLE" ]]; then
  echo "ERROR: nepodarilo sa načítať service_role (supabase login?)" >&2
  exit 1
fi

if [[ "$FORCE_PASSWORD" == true ]] || [[ ! -f "$PASSWORD_FILE" ]]; then
  REVIEWER_PASSWORD=$(openssl rand -base64 24 | tr -d '/+=' | head -c 24)
  printf '%s' "$REVIEWER_PASSWORD" > "$PASSWORD_FILE"
  chmod 600 "$PASSWORD_FILE"
  echo "Nové heslo uložené do $PASSWORD_FILE"
else
  REVIEWER_PASSWORD=$(cat "$PASSWORD_FILE")
  echo "Používam existujúce heslo z $PASSWORD_FILE"
fi

url_encode_email() {
  python3 -c "import urllib.parse; print(urllib.parse.quote('$PLAY_REVIEWER_EMAIL'))"
}

ensure_auth_user() {
  local http user_id
  http=$(curl -sS -o /tmp/play_reviewer_user_create.json -w "%{http_code}" \
    -X POST "$SUPABASE_URL/auth/v1/admin/users" \
    -H "apikey: $SERVICE_ROLE" \
    -H "Authorization: Bearer $SERVICE_ROLE" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$PLAY_REVIEWER_EMAIL\",\"password\":\"$REVIEWER_PASSWORD\",\"email_confirm\":true}")

  if [[ "$http" == "200" || "$http" == "201" ]]; then
    USER_ID=$(python3 -c "import json; print(json.load(open('/tmp/play_reviewer_user_create.json'))['id'])")
    echo "Play reviewer user vytvorený: $USER_ID"
    return 0
  fi

  user_id=$(curl -sS \
    "$SUPABASE_URL/auth/v1/admin/users?email=$(url_encode_email)" \
    -H "apikey: $SERVICE_ROLE" \
    -H "Authorization: Bearer $SERVICE_ROLE" | python3 -c "
import json, sys
data = json.load(sys.stdin)
users = data.get('users') or []
print(users[0]['id'] if users else '')
")

  if [[ -z "$user_id" ]]; then
    echo "ERROR: admin create HTTP $http, user not found" >&2
    cat /tmp/play_reviewer_user_create.json >&2
    exit 1
  fi

  http=$(curl -sS -o /tmp/play_reviewer_user_update.json -w "%{http_code}" \
    -X PUT "$SUPABASE_URL/auth/v1/admin/users/$user_id" \
    -H "apikey: $SERVICE_ROLE" \
    -H "Authorization: Bearer $SERVICE_ROLE" \
    -H "Content-Type: application/json" \
    -d "{\"password\":\"$REVIEWER_PASSWORD\",\"email_confirm\":true}")

  if [[ "$http" != "200" ]]; then
    echo "ERROR: password sync HTTP $http" >&2
    cat /tmp/play_reviewer_user_update.json >&2
    exit 1
  fi

  USER_ID="$user_id"
  echo "Play reviewer user existuje, heslo synchronizované: $USER_ID"
}

rest_upsert() {
  local table=$1
  local payload=$2
  local http
  http=$(curl -sS -o "/tmp/play_reviewer_${table}.json" -w "%{http_code}" \
    -X POST "$SUPABASE_URL/rest/v1/$table" \
    -H "apikey: $SERVICE_ROLE" \
    -H "Authorization: Bearer $SERVICE_ROLE" \
    -H "Content-Type: application/json" \
    -H "Prefer: resolution=merge-duplicates" \
    -d "$payload")
  if [[ "$http" != "200" && "$http" != "201" ]]; then
    echo "ERROR: upsert $table HTTP $http" >&2
    cat "/tmp/play_reviewer_${table}.json" >&2
    exit 1
  fi
}

seed_data() {
  python3 - "$USER_ID" <<'PY' | while IFS= read -r line; do
import json, datetime, sys
uid = sys.argv[1]
now = datetime.datetime.now(datetime.timezone.utc)
iso = lambda d: d.isoformat().replace("+00:00", "Z")
issued1 = now - datetime.timedelta(days=14)
due1 = now + datetime.timedelta(days=16)
issued2 = now - datetime.timedelta(days=30)
due2 = now - datetime.timedelta(days=2)
exp_date = now - datetime.timedelta(days=3)

settings = {
    "user_id": uid,
    "data": {
        "companyName": "BizAgent Review s.r.o.",
        "companyAddress": "Hlavná 1, 811 01 Bratislava",
        "companyIco": "12345678",
        "companyDic": "1234567890",
        "companyIcDph": "",
        "bankAccount": "SK12 1100 0000 0012 3456 7890",
        "swift": "TATRSKBX",
        "registerInfo": "Obchodný register SR",
        "showQrCode": True,
        "isVatPayer": False,
        "iban": "SK1211000000001234567890",
        "companyIban": "SK1211000000001234567890",
        "companySwift": "TATRSKBX",
        "showQrOnInvoice": True,
        "biometricEnabled": False,
        "language": "sk",
        "currency": "EUR",
    },
    "updated_at": iso(now),
}
print(json.dumps({"table": "user_settings", "payload": settings}))

inv1_data = {
    "id": "play-review-inv-1",
    "number": "2026/001",
    "clientName": "Klient Alpha s.r.o.",
    "clientAddress": "Dlhá 10, Bratislava",
    "clientIco": "87654321",
    "clientDic": "8765432109",
    "clientIcDph": "",
    "dateIssued": iso(issued1),
    "dateDue": iso(due1),
    "items": [{"name": "Konzultácia", "quantity": 1, "unitPrice": 150.0, "vatRate": 0}],
    "totalAmount": 150.0,
    "status": "sent",
    "variableSymbol": "2026001",
    "constantSymbol": "0308",
    "paymentMethod": "bank_transfer",
    "isNumberProvisional": False,
}
inv1 = {
    "id": "play-review-inv-1",
    "user_id": uid,
    "data": inv1_data,
    "date_issued": iso(issued1),
    "status": "sent",
    "is_deleted": False,
    "updated_at": iso(now),
}
print(json.dumps({"table": "invoices", "payload": inv1}))

inv2_data = {
    "id": "play-review-inv-2",
    "number": "2026/002",
    "clientName": "Beta Freelancer",
    "clientAddress": "Krátka 5, Košice",
    "clientIco": "",
    "clientDic": "",
    "clientIcDph": "",
    "dateIssued": iso(issued2),
    "dateDue": iso(due2),
    "items": [{"name": "Web development", "quantity": 8, "unitPrice": 45.0, "vatRate": 0}],
    "totalAmount": 360.0,
    "status": "paid",
    "variableSymbol": "2026002",
    "constantSymbol": "0308",
    "paymentMethod": "bank_transfer",
    "paymentDate": iso(due2),
    "isNumberProvisional": False,
}
inv2 = {
    "id": "play-review-inv-2",
    "user_id": uid,
    "data": inv2_data,
    "date_issued": iso(issued2),
    "status": "paid",
    "is_deleted": False,
    "updated_at": iso(now),
}
print(json.dumps({"table": "invoices", "payload": inv2}))

exp_data = {
    "userId": uid,
    "vendorName": "Tesco Extra",
    "description": "Office supplies",
    "amount": 42.5,
    "date": iso(exp_date),
    "category": "office",
    "categorizationConfidence": 90,
    "receiptUrls": [],
    "isOcrVerified": True,
}
expense = {
    "id": "play-review-exp-1",
    "user_id": uid,
    "data": exp_data,
    "date": iso(exp_date),
    "is_deleted": False,
    "updated_at": iso(now),
}
print(json.dumps({"table": "expenses", "payload": expense}))

notif = {
    "id": "play-review-notif-1",
    "user_id": uid,
    "data": {
        "title": "Vitajte v BizAgent",
        "body": "Ukážkové upozornenie pre Google Play review.",
        "type": "welcome",
    },
    "read": False,
    "created_at": iso(now),
}
print(json.dumps({"table": "notifications", "payload": notif}))
PY
    table=$(python3 -c "import json,sys; print(json.loads(sys.argv[1])['table'])" "$line")
    payload=$(python3 -c "import json,sys; print(json.dumps(json.loads(sys.argv[1])['payload']))" "$line")
    rest_upsert "$table" "$payload"
  done
}

verify_sign_in() {
  local http body
  body=$(curl -sS -w "\n%{http_code}" \
    -X POST "$SUPABASE_URL/auth/v1/token?grant_type=password" \
    -H "apikey: $PUBLISHABLE_KEY" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$PLAY_REVIEWER_EMAIL\",\"password\":\"$REVIEWER_PASSWORD\"}")
  http=$(echo "$body" | tail -n1)
  if [[ "$http" != "200" ]]; then
    echo "ERROR: sign-in HTTP $http" >&2
    echo "$body" | sed '$d' >&2
    exit 1
  fi
  echo "Sign-in REST OK (HTTP 200)"
}

count_rows() {
  local table=$1
  local min=$2
  local count http
  http=$(curl -sS -o "/tmp/play_reviewer_count_${table}.json" -w "%{http_code}" \
    "$SUPABASE_URL/rest/v1/${table}?user_id=eq.${USER_ID}&select=id" \
    -H "apikey: $SERVICE_ROLE" \
    -H "Authorization: Bearer $SERVICE_ROLE")
  if [[ "$http" != "200" ]]; then
    echo "ERROR: count $table HTTP $http" >&2
    exit 1
  fi
  count=$(python3 -c "import json; print(len(json.load(open('/tmp/play_reviewer_count_${table}.json'))))")
  if [[ "$count" -lt "$min" ]]; then
    echo "ERROR: $table má $count riadkov, očakávané >= $min" >&2
    exit 1
  fi
  echo "  $table: $count riadkov"
}

verify_settings() {
  local http
  http=$(curl -sS -o /tmp/play_reviewer_settings.json -w "%{http_code}" \
    "$SUPABASE_URL/rest/v1/user_settings?user_id=eq.${USER_ID}&select=user_id,data" \
    -H "apikey: $SERVICE_ROLE" \
    -H "Authorization: Bearer $SERVICE_ROLE")
  if [[ "$http" != "200" ]]; then
    echo "ERROR: user_settings HTTP $http" >&2
    exit 1
  fi
  python3 -c "
import json, sys
rows = json.load(open('/tmp/play_reviewer_settings.json'))
assert len(rows) == 1, rows
data = rows[0].get('data') or {}
assert data.get('companyIco') == '12345678', data
assert data.get('companyDic') == '1234567890', data
print('  user_settings: IČO/DIČ OK')
"
}

echo "==> Play reviewer seed (project $PROJECT_REF)"
echo "    Email: $PLAY_REVIEWER_EMAIL"

ensure_auth_user
seed_data

echo "==> Verifikácia"
verify_sign_in
count_rows invoices 2
count_rows expenses 1
count_rows notifications 1
verify_settings

echo ""
echo "Hotovo."
echo "  Email:    $PLAY_REVIEWER_EMAIL"
echo "  Password: $PASSWORD_FILE"
echo "  User ID:  $USER_ID"
if [[ "$VERBOSE" == true ]]; then
  echo "  Password value: $REVIEWER_PASSWORD"
fi
echo ""
echo "Play Console text: docs/PLAY_APP_ACCESS_NOTES.md"
