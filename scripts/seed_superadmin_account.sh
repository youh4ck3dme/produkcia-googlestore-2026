#!/usr/bin/env bash
# Vytvorí/aktualizuje Supabase superadmin + voliteľne Firebase Auth (legacy).
#
# Usage:
#   bash scripts/seed_superadmin_account.sh
#   SUPERADMIN_EMAIL=x@y.com bash scripts/seed_superadmin_account.sh --send-recover-email
#
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PROJECT_REF="${SUPABASE_PROJECT_REF:-kpsnwpuydqqojwmrnkdy}"
SUPERADMIN_EMAIL="${SUPERADMIN_EMAIL:-larsenevans@gmail.com}"
PASSWORD_FILE="${PASSWORD_FILE:-$ROOT/.superadmin_larsenevans_password}"
SUPABASE_DEFINES="${SUPABASE_DEFINES:-$ROOT/dart_defines/supabase.json}"
FIREBASE_PROJECT="${FIREBASE_PROJECT:-gifted-mountain-476207-u4}"
SEND_RECOVER=false
FORCE_PASSWORD=false
VERBOSE=false

for arg in "$@"; do
  case "$arg" in
    --send-recover-email) SEND_RECOVER=true ;;
    --force-password) FORCE_PASSWORD=true ;;
    --verbose) VERBOSE=true ;;
    -h|--help)
      echo "Usage: bash scripts/seed_superadmin_account.sh [--force-password] [--send-recover-email] [--verbose]"
      exit 0
      ;;
    *)
      echo "Neznámy argument: $arg" >&2
      exit 1
      ;;
  esac
done

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || { echo "ERROR: chýba '$1'" >&2; exit 1; }
}

need_cmd supabase
need_cmd curl
need_cmd python3
need_cmd openssl

[[ -f "$SUPABASE_DEFINES" ]] || { echo "ERROR: chýba $SUPABASE_DEFINES" >&2; exit 1; }

SUPABASE_URL=$(python3 -c "
import json
d = json.load(open('$SUPABASE_DEFINES'))
print((d.get('SUPABASE_URL') or '').strip())
")
PUBLISHABLE_KEY=$(python3 -c "
import json
d = json.load(open('$SUPABASE_DEFINES'))
print((d.get('SUPABASE_PUBLISHABLE_KEY') or d.get('SUPABASE_ANON_KEY') or '').strip())
")

SERVICE_ROLE=$(supabase projects api-keys --project-ref "$PROJECT_REF" -o json | python3 -c "
import json, sys
for item in json.load(sys.stdin):
    if item.get('name') == 'service_role':
        print(item['api_key'])
        break
")

[[ -n "$SERVICE_ROLE" ]] || { echo "ERROR: service_role (supabase login?)" >&2; exit 1; }

if [[ "$FORCE_PASSWORD" == true ]] || [[ ! -f "$PASSWORD_FILE" ]]; then
  SUPERADMIN_PASSWORD=$(openssl rand -base64 24 | tr -d '/+=' | head -c 24)
  printf '%s' "$SUPERADMIN_PASSWORD" > "$PASSWORD_FILE"
  chmod 600 "$PASSWORD_FILE"
  echo "Nové heslo: $PASSWORD_FILE"
else
  SUPERADMIN_PASSWORD=$(cat "$PASSWORD_FILE")
  echo "Používam heslo z $PASSWORD_FILE"
fi

ensure_supabase_user() {
  local http user_id payload
  payload=$(python3 -c "
import json
print(json.dumps({
  'email': '$SUPERADMIN_EMAIL',
  'password': '$SUPERADMIN_PASSWORD',
  'email_confirm': True,
  'app_metadata': {'role': 'superadmin', 'provider': 'email'},
  'user_metadata': {'full_name': 'Lars Evans', 'is_superadmin': True},
}))
")

  http=$(curl -sS -o /tmp/superadmin_create.json -w "%{http_code}" \
    -X POST "$SUPABASE_URL/auth/v1/admin/users" \
    -H "apikey: $SERVICE_ROLE" \
    -H "Authorization: Bearer $SERVICE_ROLE" \
    -H "Content-Type: application/json" \
    -d "$payload")

  if [[ "$http" == "200" || "$http" == "201" ]]; then
    USER_ID=$(python3 -c "import json; print(json.load(open('/tmp/superadmin_create.json'))['id'])")
    echo "Supabase user vytvorený: $USER_ID"
    return 0
  fi

  user_id=$(curl -sS \
    "$SUPABASE_URL/auth/v1/admin/users?page=1&per_page=200" \
    -H "apikey: $SERVICE_ROLE" \
    -H "Authorization: Bearer $SERVICE_ROLE" | python3 -c "
import json, os, sys
target = os.environ.get('SUPERADMIN_EMAIL', '').lower()
for u in json.load(sys.stdin).get('users') or []:
    if (u.get('email') or '').lower() == target:
        print(u['id'])
        break
" SUPERADMIN_EMAIL="$SUPERADMIN_EMAIL")

  [[ -n "$user_id" ]] || { echo "ERROR: create HTTP $http" >&2; cat /tmp/superadmin_create.json >&2; exit 1; }

  http=$(curl -sS -o /tmp/superadmin_update.json -w "%{http_code}" \
    -X PUT "$SUPABASE_URL/auth/v1/admin/users/$user_id" \
    -H "apikey: $SERVICE_ROLE" \
    -H "Authorization: Bearer $SERVICE_ROLE" \
    -H "Content-Type: application/json" \
    -d "$payload")

  [[ "$http" == "200" ]] || { echo "ERROR: update HTTP $http" >&2; cat /tmp/superadmin_update.json >&2; exit 1; }
  USER_ID="$user_id"
  echo "Supabase user existuje, aktualizovaný: $USER_ID"
}

seed_user_settings() {
  local now payload http
  now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  payload=$(python3 -c "
import json
print(json.dumps({
  'user_id': '$USER_ID',
  'data': {
    'companyName': 'BizAgent Superadmin',
    'role': 'superadmin',
    'isSuperAdmin': True,
    'language': 'sk',
    'currency': 'EUR',
  },
  'updated_at': '$now',
}))
")
  http=$(curl -sS -o /tmp/superadmin_settings.json -w "%{http_code}" \
    -X POST "$SUPABASE_URL/rest/v1/user_settings" \
    -H "apikey: $SERVICE_ROLE" \
    -H "Authorization: Bearer $SERVICE_ROLE" \
    -H "Content-Type: application/json" \
    -H "Prefer: resolution=merge-duplicates" \
    -d "$payload")
  [[ "$http" == "200" || "$http" == "201" ]] || { echo "ERROR: user_settings HTTP $http" >&2; cat /tmp/superadmin_settings.json >&2; exit 1; }
  echo "user_settings: superadmin OK"
}

verify_sign_in() {
  local http
  http=$(curl -sS -o /tmp/superadmin_signin.json -w "%{http_code}" \
    -X POST "$SUPABASE_URL/auth/v1/token?grant_type=password" \
    -H "apikey: $PUBLISHABLE_KEY" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$SUPERADMIN_EMAIL\",\"password\":\"$SUPERADMIN_PASSWORD\"}")
  [[ "$http" == "200" ]] || { echo "ERROR: sign-in HTTP $http" >&2; cat /tmp/superadmin_signin.json >&2; exit 1; }
  python3 -c "
import json
d = json.load(open('/tmp/superadmin_signin.json'))
role = (d.get('user', {}).get('app_metadata') or {}).get('role')
assert role == 'superadmin', role
print('Sign-in OK, role=superadmin')
"
}

send_recover_email() {
  local http
  http=$(curl -sS -o /tmp/superadmin_recover.json -w "%{http_code}" \
    -X POST "$SUPABASE_URL/auth/v1/recover" \
    -H "apikey: $PUBLISHABLE_KEY" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$SUPERADMIN_EMAIL\"}")
  if [[ "$http" == "200" ]]; then
    echo "Supabase recover email odoslaný na $SUPERADMIN_EMAIL"
  else
    echo "WARN: recover email HTTP $http (skontroluj Supabase SMTP)" >&2
    cat /tmp/superadmin_recover.json >&2
  fi
}

ensure_firebase_user() {
  if ! command -v node >/dev/null 2>&1; then
    echo "WARN: node chýba — preskakujem Firebase Auth"
    return 0
  fi
  if [[ ! -d "$ROOT/functions/node_modules/firebase-admin" ]]; then
    echo "==> npm install vo functions/ (firebase-admin)..."
    (cd "$ROOT/functions" && npm install --silent) || true
  fi
  SUPERADMIN_EMAIL="$SUPERADMIN_EMAIL" \
  SUPERADMIN_PASSWORD="$SUPERADMIN_PASSWORD" \
  FIREBASE_PROJECT="$FIREBASE_PROJECT" \
  node <<'NODE' || echo "WARN: Firebase Auth sync zlyhal (app používa primárne Supabase)"
const admin = require('./functions/node_modules/firebase-admin');
const email = process.env.SUPERADMIN_EMAIL;
const password = process.env.SUPERADMIN_PASSWORD;
const projectId = process.env.FIREBASE_PROJECT;
if (!admin.apps.length) {
  admin.initializeApp({ projectId });
}
(async () => {
  try {
    const existing = await admin.auth().getUserByEmail(email);
    await admin.auth().updateUser(existing.uid, {
      password,
      emailVerified: true,
      disabled: false,
    });
    await admin.auth().setCustomUserClaims(existing.uid, { role: 'superadmin' });
    console.log('Firebase user aktualizovaný:', existing.uid);
  } catch (e) {
    if (e.code !== 'auth/user-not-found') throw e;
    const u = await admin.auth().createUser({
      email,
      password,
      emailVerified: true,
      disabled: false,
    });
    await admin.auth().setCustomUserClaims(u.uid, { role: 'superadmin' });
    console.log('Firebase user vytvorený:', u.uid);
  }
})();
NODE
}

echo "==> Superadmin seed ($PROJECT_REF)"
echo "    Email: $SUPERADMIN_EMAIL"

ensure_supabase_user
seed_user_settings
verify_sign_in
ensure_firebase_user
[[ "$SEND_RECOVER" == true ]] && send_recover_email

echo ""
echo "Hotovo."
echo "  Email:    $SUPERADMIN_EMAIL"
echo "  Password: $PASSWORD_FILE"
echo "  User ID:  $USER_ID"
echo "  Role:     superadmin (app_metadata + user_settings)"
if [[ "$VERBOSE" == true ]]; then
  echo "  Password value: $SUPERADMIN_PASSWORD"
fi