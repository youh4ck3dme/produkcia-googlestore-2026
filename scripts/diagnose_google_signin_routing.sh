#!/usr/bin/env bash
# BizAgent — diagnostika Google Sign-In + routing po prihlásení
# Použitie: bash scripts/diagnose_google_signin_routing.sh [web|android|all]
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

MODE="${1:-all}"
PASS=0
FAIL=0
WARN=0

ok()   { echo "  ✓ $*"; PASS=$((PASS + 1)); }
bad()  { echo "  ✗ $*"; FAIL=$((FAIL + 1)); }
warn() { echo "  ⚠ $*"; WARN=$((WARN + 1)); }

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  Google Sign-In + ROUTING diagnostika (BizAgent)             ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# --- A. Konfigurácia (SHA-1, Supabase, Firebase) ---
echo "▶ A/5 Auth konfigurácia"
if bash scripts/verify_google_signin.sh 2>&1 | tee /tmp/diag_google_signin.log | grep -q "✗"; then
  bad "verify_google_signin.sh našiel problémy"
else
  ok "SHA-1, google-services.json, GOOGLE_WEB_CLIENT_ID"
fi

if bash scripts/verify_auth_stack.sh 2>&1 | tee /tmp/diag_auth_stack.log | grep -q "✗"; then
  bad "verify_auth_stack.sh — live stack má chyby"
else
  ok "Supabase + hosting stack konzistentný"
fi
echo ""

# --- B. Router logika (unit testy) ---
echo "▶ B/5 Router po prihlásení"
if flutter test test/core/router/app_router_test.dart \
  --dart-define=PLAY_MVP=false >/tmp/diag_router.log 2>&1; then
  ok "Všetky router redirect testy prešli"
else
  bad "Router testy zlyhali — pozri /tmp/diag_router.log"
  tail -15 /tmp/diag_router.log | sed 's/^/    /'
fi
echo ""

# --- C. OAuth callback handler v kóde ---
echo "▶ C/5 OAuth callback (web PKCE)"
for f in lib/core/supabase/oauth_callback_handler_web.dart lib/main.dart; do
  if [[ -f "$f" ]] && grep -q 'recoverOAuthSessionFromBrowserUrl\|getSessionFromUrl' "$f"; then
    ok "$f obsahuje OAuth session recovery"
  else
    bad "$f — chýba OAuth session recovery (commit d81cf72?)"
  fi
done

if grep -qE "queryParameters.containsKey\('code'\)|shouldHoldLoginForOAuthCode" lib/core/router/app_router.dart lib/core/router/oauth_login_hold.dart 2>/dev/null; then
  ok "Router má OAuth ?code= guard"
else
  warn "Router nemá OAuth ?code= guard — môže presmerovať pred exchange"
fi
echo ""

# --- D. Platform-specific ---
echo "▶ D/5 Platforma: $MODE"

if [[ "$MODE" == "web" || "$MODE" == "all" ]]; then
  echo "  Web (bizagent.sk):"
  PROD_JS=$(curl -sS "https://bizagent.sk/flutter_bootstrap.js" 2>/dev/null | grep -oE 'main\.dart\.js[^"]*' | head -1)
  if [[ -n "$PROD_JS" ]]; then
    MATCHES=$(curl -sS "https://bizagent.sk/$PROD_JS" 2>/dev/null | grep -c 'getSessionFromUrl' || echo 0)
    if [[ "$MATCHES" -gt 0 ]]; then
      ok "Produkčný bundle obsahuje getSessionFromUrl (OAuth fix deploynutý)"
    else
      bad "Produkčný web NEMÁ OAuth session recovery — treba: flutter build web && deploy"
    fi
  else
    warn "Nepodarilo sa načítať flutter_bootstrap.js z bizagent.sk"
  fi

  DEFINES="$ROOT/dart_defines/supabase.json"
  if [[ -f "$DEFINES" ]]; then
    REDIRECT=$(python3 -c "import json; print(json.load(open('$DEFINES')).get('SUPABASE_URL','').replace('https://','https://').split('.')[0])" 2>/dev/null || true)
    AUTH_LOC=$(curl -sS -D - -o /dev/null -X GET \
      "$(python3 -c "import json; d=json.load(open('$DEFINES')); print(d['SUPABASE_URL']+'/auth/v1/authorize?provider=google&redirect_to=https://bizagent.sk/')")" \
      -H "apikey: $(python3 -c "import json; print(json.load(open('$DEFINES'))['SUPABASE_PUBLISHABLE_KEY'])")" 2>/dev/null \
      | awk 'tolower($1)=="location:" {print $2}' | tr -d '\r')
    if [[ "$AUTH_LOC" == *"accounts.google.com"* ]]; then
      ok "Supabase OAuth redirect → Google ($AUTH_LOC | head -c 80)..."
    else
      bad "Supabase OAuth authorize nevracia Google redirect"
    fi
  fi

  echo ""
  echo "  Manuálny web test (Google):"
  echo "    1. Otvor https://bizagent.sk/#/login (Cmd+Shift+R / hard refresh)"
  echo "    2. Klikni „Prihlásiť sa cez Google“"
  echo "    3. Po návrate z Google:"
  echo "       ✓ OK:  URL = https://bizagent.sk/#/dashboard (bez ?code=)"
  echo "       ✗ ZLY: URL obsahuje ?code= → session sa nevymenila"
  echo "       ✗ ZLY: URL = #/login → routing alebo auth stream nefunguje"
  echo ""
fi

if [[ "$MODE" == "android" || "$MODE" == "all" ]]; then
  echo "  Android (native ID token):"
  if [[ -f android/key.properties ]]; then
    STORE=$(grep storeFile android/key.properties | cut -d= -f2)
    ALIAS=$(grep keyAlias android/key.properties | cut -d= -f2)
    PASS=$(grep storePassword android/key.properties | cut -d= -f2)
    UPLOAD_SHA=$(keytool -list -v -keystore "android/app/$STORE" -alias "$ALIAS" \
      -storepass "$PASS" -keypass "$PASS" 2>/dev/null \
      | awk -F': ' '/SHA1:/{gsub(/ /,":",$2); print toupper($2)}' | tr -d ':')
    UPLOAD_SHA_LC=$(echo "$UPLOAD_SHA" | tr '[:upper:]' '[:lower:]')
    ok "Upload keystore SHA-1: $UPLOAD_SHA_LC"
    echo ""
    echo "    DÔLEŽITÉ — Play App Signing vs Upload key:"
    echo "    • Lokálny release APK/AAB: SHA-1 upload kľúča ($UPLOAD_SHA_LC)"
    echo "    • APK z Play Store (internal/closed): SHA-1 App signing key z Play Console"
    echo "      → Setup → App integrity → App signing → SHA-1 certifikát"
    echo "      → Tento SHA-1 MUSÍ byť v Firebase (nie len upload key)!"
    echo ""
    echo "    Chyba „Google nevrátil ID token“ = zlý SHA-1 v Firebase (nie routing)."
    echo "    Po výbere účtu ostaneš na /login = routing/init — pozri sekciu E."
  else
    warn "Chýba android/key.properties"
  fi
fi
echo ""

# --- E. Routing checklist (kód) ---
echo "▶ E/5 Routing checklist (známe príčiny „ostanem na /login“)"
echo ""
INIT_BLOCK=$(grep -A6 '!init.isCompleted' lib/core/router/app_router.dart | head -7)
if echo "$INIT_BLOCK" | grep -q 'isLoggedIn'; then
  ok "Router: prihlásený používateľ nie je blokovaný počas init"
else
  warn "Router: init.isCompleted môže blokovať redirect ~2.6s po Google login"
  echo "       (authState je OK, ale init ešte beží → zostaneš na /login)"
fi

if grep -q 'seen_onboarding\|seenOnboarding' lib/core/router/app_router.dart; then
  warn "Ak si nový používateľ / vymazané prefs → redirect ide na /onboarding, NIE /dashboard"
  echo "       To vyzerá ako „login nefunguje“, ale auth prešiel."
fi

if grep -q "catch (_)" lib/main.dart; then
  warn "main.dart ticho prehltá OAuth chyby — pri zlyhaní ?code= exchange uvidíš len /login"
fi
echo ""

# --- Súhrn ---
echo "══════════════════════════════════════════════════════════════"
echo " VÝSLEDOK: ✓ $PASS   ✗ $FAIL   ⚠ $WARN"
echo "══════════════════════════════════════════════════════════════"
echo ""
echo "Rýchly rozhodovací strom:"
echo "  • Chyba PRED výberom Google účtu     → Supabase/Google Cloud konfigurácia"
echo "  • „Google nevrátil ID token“ (Android) → Firebase SHA-1 (upload + Play signing)"
echo "  • Návrat z Google, URL má ?code=       → OAuth PKCE exchange (deploy web fix)"
echo "  • Účet vybraný, URL #/login            → routing / init / onboarding"
echo "  • Email login funguje, Google nie      → platform-specific (nie router)"
echo ""

if [[ "$FAIL" -eq 0 ]]; then
  exit 0
else
  exit 1
fi