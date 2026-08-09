#!/usr/bin/env bash
# BizAgent — jeden beh: potvrdí alebo vyvráti celý auth stack (lokál + live).
# Použitie: bash scripts/verify_auth_stack.sh
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PASS=0
FAIL=0
WARN=0

ok()   { echo "  ✓ $*"; PASS=$((PASS + 1)); }
bad()  { echo "  ✗ $*"; FAIL=$((FAIL + 1)); }
warn() { echo "  ⚠ $*"; WARN=$((WARN + 1)); }

EXPECTED_WEB_CLIENT="90348815049-e5faruj0mfvnn34m80k9b9b5upp9nn6v.apps.googleusercontent.com"
EXPECTED_GCP_PROJECT="gifted-mountain-476207-u4"
EXPECTED_SUPABASE_REF="kpsnwpuydqqojwmrnkdy"
PROD_URL="https://bizagent.sk"
FIREBASE_URL="https://gifted-mountain-476207-u4.web.app"
SUPABASE_CALLBACK="https://${EXPECTED_SUPABASE_REF}.supabase.co/auth/v1/callback"
SECRETS_JSON="${GOOGLE_OAUTH_JSON:-$HOME/Documents/secrets/bizagent-auth/client_secret_${EXPECTED_WEB_CLIENT}.json}"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  BizAgent AUTH STACK — verify (lokál + Supabase + Hosting)   ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# --- 1. Nástroje ---
echo "▶ 1/7 Nástroje"
for cmd in flutter firebase gcloud supabase python3 curl keytool; do
  if command -v "$cmd" >/dev/null 2>&1; then
    ok "$cmd → $(command -v "$cmd")"
  else
    bad "chýba príkaz: $cmd"
  fi
done
echo ""

# --- 2. gcloud / Firebase projekt ---
echo "▶ 2/7 gcloud + Firebase projekt"
if command -v gcloud >/dev/null 2>&1; then
  GCLOUD_PROJECT=$(gcloud config get-value project 2>/dev/null || true)
  GCLOUD_ACCOUNT=$(gcloud config get-value account 2>/dev/null || true)
  if [[ "$GCLOUD_PROJECT" == "$EXPECTED_GCP_PROJECT" ]]; then
    ok "gcloud project = $GCLOUD_PROJECT"
  else
    bad "gcloud project = ${GCLOUD_PROJECT:-?} (očakávané $EXPECTED_GCP_PROJECT)"
  fi
  if [[ -n "$GCLOUD_ACCOUNT" ]]; then
    ok "gcloud account = $GCLOUD_ACCOUNT"
  else
    bad "gcloud nie je prihlásený — spusti: gcloud auth login"
  fi
else
  bad "gcloud nie je nainštalovaný"
fi

if command -v firebase >/dev/null 2>&1; then
  if firebase use "$EXPECTED_GCP_PROJECT" >/dev/null 2>&1; then
    ok "firebase use $EXPECTED_GCP_PROJECT"
  else
    warn "firebase use $EXPECTED_GCP_PROJECT zlyhal (skontroluj firebase login)"
  fi
  if [[ -f .firebaserc ]] && grep -q "$EXPECTED_GCP_PROJECT" .firebaserc; then
    ok ".firebaserc obsahuje $EXPECTED_GCP_PROJECT"
  else
    bad ".firebaserc nemá default $EXPECTED_GCP_PROJECT"
  fi
fi
echo ""

# --- 3. Lokálna Google Sign-In konfigurácia ---
echo "▶ 3/7 Lokálna konfigurácia (SHA-1, google-services.json, dart defines)"
if [[ -f scripts/verify_google_signin.sh ]]; then
  OUT=$(bash scripts/verify_google_signin.sh 2>&1) || true
  echo "$OUT" | sed 's/^/    /'
  if echo "$OUT" | grep -q "✗"; then
    bad "verify_google_signin.sh našiel problémy (pozri ✗ vyššie)"
  else
    ok "verify_google_signin.sh — lokálne súbory OK"
  fi
else
  bad "chýba scripts/verify_google_signin.sh"
fi

if [[ -f "$SECRETS_JSON" ]]; then
  SECRET_CID=$(python3 -c "
import json, sys
d = json.load(open('$SECRETS_JSON'))
b = d.get('web') or d.get('installed') or {}
print(b.get('client_id',''))
" 2>/dev/null || true)
  if [[ "$SECRET_CID" == "$EXPECTED_WEB_CLIENT" ]]; then
    ok "OAuth secret JSON → správny Web client"
  else
    bad "OAuth secret JSON client_id = ${SECRET_CID:-?}"
  fi
else
  warn "chýba OAuth secret JSON: $SECRETS_JSON"
fi
echo ""

# --- 4. Supabase live ---
echo "▶ 4/7 Supabase live ($EXPECTED_SUPABASE_REF)"
DEFINES="$ROOT/dart_defines/supabase.json"
if [[ ! -f "$DEFINES" ]]; then
  bad "chýba $DEFINES"
else
  SUPABASE_URL=$(python3 -c "import json; print(json.load(open('$DEFINES'))['SUPABASE_URL'])")
  ANON_KEY=$(python3 -c "import json; print(json.load(open('$DEFINES'))['SUPABASE_PUBLISHABLE_KEY'])")
  LOCAL_CLIENT=$(python3 -c "import json; print(json.load(open('$DEFINES')).get('GOOGLE_WEB_CLIENT_ID',''))")
  if [[ "$LOCAL_CLIENT" == "$EXPECTED_WEB_CLIENT" ]]; then
    ok "dart_defines GOOGLE_WEB_CLIENT_ID = e5faruj0"
  else
    bad "dart_defines GOOGLE_WEB_CLIENT_ID = ${LOCAL_CLIENT:-?}"
  fi

  HTTP=$(curl -sS -o /tmp/sb_health.json -w "%{http_code}" "$SUPABASE_URL/auth/v1/health" -H "apikey: $ANON_KEY" 2>/dev/null || echo "000")
  if [[ "$HTTP" == "200" ]]; then
    ok "Supabase auth health HTTP 200"
  else
    bad "Supabase auth health HTTP $HTTP"
  fi

  SETTINGS=$(curl -sS "$SUPABASE_URL/auth/v1/settings" -H "apikey: $ANON_KEY" 2>/dev/null || echo "{}")
  if echo "$SETTINGS" | python3 -c "import json,sys; d=json.load(sys.stdin); sys.exit(0 if d.get('external',{}).get('google') else 1)" 2>/dev/null; then
    ok "Supabase Google provider enabled (live API)"
  else
    bad "Supabase Google provider nie je enabled"
  fi

  AUTH_LOC=$(curl -sS -D - -o /dev/null -X GET \
    "$SUPABASE_URL/auth/v1/authorize?provider=google&redirect_to=$PROD_URL" \
    -H "apikey: $ANON_KEY" 2>/dev/null | awk 'tolower($1)=="location:" {print $2}' | tr -d '\r')
  if [[ "$AUTH_LOC" == *"$EXPECTED_WEB_CLIENT"* ]]; then
    ok "Live OAuth redirect používa client e5faruj0 (nie ireo2g7l)"
  elif [[ "$AUTH_LOC" == *"ireo2g7l"* ]]; then
    bad "Live Supabase stále používa ZLÝ client ireo2g7l — spusti supabase config push"
  elif [[ -z "$AUTH_LOC" ]]; then
    bad "Supabase authorize nevrátil redirect na Google"
  else
    warn "OAuth redirect: $AUTH_LOC"
  fi

  if [[ "$AUTH_LOC" == *"redirect_uri=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$SUPABASE_CALLBACK', safe=''))")"* ]] \
     || [[ "$AUTH_LOC" == *"${SUPABASE_CALLBACK//\//%2F}"* ]] \
     || [[ "$AUTH_LOC" == *"kpsnwpuydqqojwmrnkdy.supabase.co"* ]]; then
    ok "Supabase callback URI v OAuth flow"
  else
    warn "skontroluj callback URI v Google Cloud Web klientovi"
  fi

  # Follow Google authorize URL — catch redirect_uri_mismatch (false green otherwise)
  if [[ -n "$AUTH_LOC" ]]; then
    FINAL_URL=$(curl -sS -L -o /dev/null -w "%{url_effective}" --max-time 20 "$AUTH_LOC" 2>/dev/null || echo "")
    if [[ "$FINAL_URL" == *"redirect_uri_mismatch"* ]] || [[ "$FINAL_URL" == *"authError="* ]]; then
      bad "Google OAuth redirect_uri_mismatch — v GCP Web klientovi pridaj: $SUPABASE_CALLBACK"
      echo "    Spusti: bash scripts/setup_google_oauth_redirect.sh"
    elif [[ "$FINAL_URL" == *"accounts.google.com"* ]] && [[ "$FINAL_URL" != *"oauth/error"* ]]; then
      ok "Google OAuth authorize page dosiahnuteľná (redirect URI OK)"
    else
      warn "Google OAuth final URL: ${FINAL_URL:0:120}"
    fi
  fi
fi
echo ""

# --- 5. Hosting / produkčná doména ---
echo "▶ 5/7 Hosting (bizagent.sk + Firebase)"
for url in "$PROD_URL" "$FIREBASE_URL"; do
  CODE=$(curl -sS -o /dev/null -w "%{http_code}" -L --max-time 15 "$url" 2>/dev/null || echo "000")
  if [[ "$CODE" == "200" ]]; then
    ok "$url → HTTP $CODE"
  else
    bad "$url → HTTP $CODE"
  fi
done

if command -v firebase >/dev/null 2>&1; then
  if firebase hosting:channel:list --project "$EXPECTED_GCP_PROJECT" 2>/dev/null | grep -q "live"; then
    ok "Firebase Hosting má live release"
  else
    warn "Firebase Hosting live release sa nenašiel"
  fi
fi
echo ""

# --- 6. APK / build (voliteľné) ---
echo "▶ 6/7 Build artefakty"
if [[ -f build/web/index.html ]]; then
  ok "build/web existuje (web deploy pripravený)"
else
  warn "chýba build/web — spusti: flutter build web --release --dart-define-from-file=dart_defines/supabase.json"
fi
if [[ -f build/app/outputs/flutter-apk/app-debug.apk ]]; then
  ok "debug APK existuje"
else
  warn "chýba debug APK — pre Android test: flutter build apk --debug --dart-define-from-file=dart_defines/supabase.json"
fi
echo ""

# --- 7. Manuálne kroky v konzolách ---
echo "▶ 7/7 Čo CLI neoverí (skontroluj ručne v konzole)"
echo "    Google Cloud Web client ($EXPECTED_WEB_CLIENT):"
echo "      • Authorized JavaScript origins: https://bizagent.sk, $FIREBASE_URL"
echo "      • Authorized redirect URI: $SUPABASE_CALLBACK"
echo "    Firebase Auth → Authorized domains: bizagent.sk"
echo "    Supabase → URL Configuration → Redirect URLs: https://bizagent.sk/**"
echo ""

# --- Súhrn ---
echo "══════════════════════════════════════════════════════════════"
echo " VÝSLEDOK: ✓ $PASS   ✗ $FAIL   ⚠ $WARN"
echo "══════════════════════════════════════════════════════════════"

if [[ "$FAIL" -eq 0 ]]; then
  echo ""
  echo "PASS — stack vyzerá konzistentne. Otestuj v prehliadači:"
  echo "  $PROD_URL  →  Pokračovať s Google"
  echo ""
  echo "Ak Android stále hlási „Google neposkytol ID token“, problém je v GCP"
  echo "Android OAuth klientovi (SHA-1), nie v Supabase webe."
  exit 0
else
  echo ""
  echo "FAIL — oprav položky označené ✗, potom spusti znova:"
  echo "  bash scripts/verify_auth_stack.sh"
  exit 1
fi