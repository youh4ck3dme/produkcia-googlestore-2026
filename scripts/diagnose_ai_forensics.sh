#!/usr/bin/env bash
# BizAgent — forenzná diagnostika AI (env → edge function → BizBot DB)
# Použitie: bash scripts/diagnose_ai_forensics.sh
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PASS=0
FAIL=0
WARN=0
DEFINES="$ROOT/dart_defines/supabase.json"
ENV_FILE="$ROOT/functions/.env"
PROJECT_REF="${SUPABASE_PROJECT_REF:-kpsnwpuydqqojwmrnkdy}"

ok()   { echo "  ✓ $*"; PASS=$((PASS + 1)); }
bad()  { echo "  ✗ $*"; FAIL=$((FAIL + 1)); }
warn() { echo "  ⚠ $*"; WARN=$((WARN + 1)); }

mask_env() { sed 's/=.*/=***SET***/'; }

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  BizAgent AI FORENZIKA (env → Mistral → Edge → BizBot DB)   ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# ── 1. LOKÁLNE ENV ──────────────────────────────────────────────
echo "▶ 1/6 Lokálne env (functions/.env)"
if [[ -f "$ENV_FILE" ]]; then
  for key in MISTRAL_API_KEY MISTRAL_API_KEY_BACKUP GEMINI_API_KEY MISTRAL_MODEL; do
    if grep -q "^${key}=" "$ENV_FILE" && [[ -n "$(grep "^${key}=" "$ENV_FILE" | cut -d= -f2)" ]]; then
      ok "$key v functions/.env"
    else
      bad "$key chýba alebo je prázdny v functions/.env"
    fi
  done
  echo "    $(grep -E '^(MISTRAL|GEMINI|AI_)' "$ENV_FILE" | mask_env | sed 's/^/    /')"
else
  bad "Chýba $ENV_FILE — spusti: bash scripts/setup_functions_api.sh"
fi
echo ""

# ── 2. SUPABASE SECRETS (remote env) ───────────────────────────
echo "▶ 2/6 Supabase secrets (remote env pre edge functions)"
if command -v supabase >/dev/null 2>&1; then
  SECRETS=$(supabase secrets list --project-ref "$PROJECT_REF" 2>&1)
  for key in MISTRAL_API_KEY MISTRAL_API_KEY_BACKUP GEMINI_API_KEY AI_PRIMARY MISTRAL_MODEL; do
    if echo "$SECRETS" | grep -q "$key"; then
      ok "Supabase secret: $key"
    else
      bad "Supabase secret CHÝBA: $key"
      echo "       Oprava: supabase secrets set $key=... --project-ref $PROJECT_REF"
    fi
  done
else
  bad "supabase CLI nie je nainštalované"
fi
echo ""

# ── 3. MISTRAL API PRIAMO ───────────────────────────────────────
echo "▶ 3/6 Mistral API (priamy test kľúča z functions/.env)"
if [[ -f "$ENV_FILE" ]]; then
  MISTRAL_KEY=$(grep '^MISTRAL_API_KEY=' "$ENV_FILE" | cut -d= -f2-)
  HTTP=$(curl -sS -o /tmp/forensic_mistral.json -w "%{http_code}" -X POST \
    "https://api.mistral.ai/v1/chat/completions" \
    -H "Authorization: Bearer $MISTRAL_KEY" \
    -H "Content-Type: application/json" \
    -d '{"model":"mistral-small-latest","messages":[{"role":"user","content":"ping"}],"max_tokens":5}' 2>/dev/null || echo "000")
  if [[ "$HTTP" == "200" ]]; then
    ok "Mistral API HTTP 200 (kľúč platný)"
  elif [[ "$HTTP" == "401" ]]; then
    bad "Mistral API HTTP 401 — kľúč neplatný/expirovaný"
  else
    bad "Mistral API HTTP $HTTP"
    head -c 200 /tmp/forensic_mistral.json 2>/dev/null | sed 's/^/    /'
  fi
else
  warn "Preskočené — chýba functions/.env"
fi
echo ""

# ── 4. EDGE FUNCTION generate-content ───────────────────────────
echo "▶ 4/6 Supabase Edge Function generate-content"
if [[ ! -f "$DEFINES" ]]; then
  bad "Chýba $DEFINES"
else
  URL=$(python3 -c "import json; print(json.load(open('$DEFINES'))['SUPABASE_URL'])")
  ANON=$(python3 -c "import json; print(json.load(open('$DEFINES'))['SUPABASE_PUBLISHABLE_KEY'])")

  # Bez JWT
  HTTP=$(curl -sS -o /tmp/forensic_ai.json -w "%{http_code}" -X POST \
    "$URL/functions/v1/generate-content" \
    -H "Content-Type: application/json" -H "apikey: $ANON" \
    -d '{"prompt":"Odpovedz jednym slovom: ok"}' 2>/dev/null || echo "000")
  BODY=$(cat /tmp/forensic_ai.json 2>/dev/null)
  if [[ "$HTTP" == "200" ]] && echo "$BODY" | grep -q '"text"'; then
    ok "generate-content HTTP 200 + text field"
    echo "    provider: $(echo "$BODY" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('provider','?'), d.get('model',''))" 2>/dev/null)"
  elif [[ "$HTTP" == "503" ]] && echo "$BODY" | grep -qi "MISTRAL_API_KEY"; then
    bad "generate-content HTTP 503 — MISTRAL_API_KEY nie je v Supabase secrets!"
    echo "    Oprava:"
    echo "      supabase secrets set MISTRAL_API_KEY=\$(grep MISTRAL_API_KEY functions/.env|cut -d= -f2) --project-ref $PROJECT_REF"
    echo "      supabase functions deploy generate-content --project-ref $PROJECT_REF"
  elif [[ "$HTTP" == "401" ]]; then
    bad "generate-content HTTP 401 — JWT/auth problém"
  else
    bad "generate-content HTTP $HTTP — $BODY"
  fi

  # S JWT (ako BizBot v appke)
  PASS_FILE="$ROOT/.play_reviewer_password"
  if [[ -f "$PASS_FILE" ]]; then
    curl -sS -o /tmp/forensic_auth.json -X POST "$URL/auth/v1/token?grant_type=password" \
      -H "apikey: $ANON" -H "Content-Type: application/json" \
      -d "{\"email\":\"bizagent@bizagent.sk\",\"password\":\"$(cat "$PASS_FILE")\"}" >/dev/null 2>&1
    TOKEN=$(python3 -c "import json; print(json.load(open('/tmp/forensic_auth.json')).get('access_token',''))" 2>/dev/null)
    if [[ -n "$TOKEN" ]]; then
      HTTP_JWT=$(curl -sS -o /tmp/forensic_ai_jwt.json -w "%{http_code}" -X POST \
        "$URL/functions/v1/generate-content" \
        -H "Content-Type: application/json" -H "apikey: $ANON" \
        -H "Authorization: Bearer $TOKEN" \
        -d '{"prompt":"test"}' 2>/dev/null || echo "000")
      if [[ "$HTTP_JWT" == "200" ]]; then
        ok "generate-content s JWT (prihlásený user) HTTP 200"
      else
        bad "generate-content s JWT HTTP $HTTP_JWT"
      fi
    else
      warn "Nepodarilo sa získať JWT pre live test"
    fi
  else
    warn "Chýba .play_reviewer_password — preskočený JWT test"
  fi
fi
echo ""

# ── 5. BIZBOT DB (bizbot_messages) ──────────────────────────────
echo "▶ 5/6 BizBot DB (bizbot_messages RLS)"
if [[ -f "$PASS_FILE" && -n "${TOKEN:-}" ]]; then
  USER_ID=$(python3 -c "import json; print(json.load(open('/tmp/forensic_auth.json'))['user']['id'])" 2>/dev/null)
  HTTP_INS=$(curl -sS -o /tmp/forensic_bb.json -w "%{http_code}" -X POST \
    "$URL/rest/v1/bizbot_messages" \
    -H "apikey: $ANON" -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" -H "Prefer: return=minimal" \
    -d "{\"user_id\":\"$USER_ID\",\"thread_id\":\"main\",\"text\":\"forensic ping\",\"is_user\":true}" 2>/dev/null || echo "000")
  if [[ "$HTTP_INS" == "201" ]]; then
    ok "bizbot_messages INSERT HTTP 201 (chat história funguje)"
  else
    bad "bizbot_messages INSERT HTTP $HTTP_INS — RLS alebo tabuľka"
    cat /tmp/forensic_bb.json 2>/dev/null | head -c 200 | sed 's/^/    /'
  fi
else
  warn "Preskočené — chýba auth pre DB test"
fi
echo ""

# ── 6. WEB BUILD + CLIENT ───────────────────────────────────────
echo "▶ 6/6 Flutter web build (embedded Supabase config)"
if [[ -f build/web/main.dart.js ]]; then
  if strings build/web/main.dart.js | grep -q "$PROJECT_REF"; then
    ok "build/web obsahuje Supabase project ref"
  else
    bad "build/web NEOBSAHUJE Supabase URL — rebuild s dart_defines/supabase.json"
  fi
  if strings build/web/main.dart.js | grep -q "generate-content"; then
    ok "build/web volá generate-content edge function"
  else
    warn "generate-content string nenájdený v bundle (môže byť minifikovaný)"
  fi
else
  warn "Chýba build/web — flutter build web --dart-define-from-file=dart_defines/supabase.json"
fi

if [[ -f "$DEFINES" ]]; then
  python3 -c "
import json
d=json.load(open('$DEFINES'))
checks=[('SUPABASE_URL',d.get('SUPABASE_URL')),('SUPABASE_PUBLISHABLE_KEY',d.get('SUPABASE_PUBLISHABLE_KEY'))]
for k,v in checks:
    print(f'  {\"✓\" if v else \"✗\"} dart_defines {k}: {\"SET\" if v else \"MISSING\"}')" 
fi
echo ""

# ── SÚHRN ───────────────────────────────────────────────────────
echo "══════════════════════════════════════════════════════════════"
echo " VÝSLEDOK: ✓ $PASS   ✗ $FAIL   ⚠ $WARN"
echo "══════════════════════════════════════════════════════════════"
echo ""
echo "Ak BizBot stále nefunguje v prehliadači, ale testy vyššie sú ✓:"
echo "  1. Cmd+Shift+R na https://bizagent.sk (vyčisti Service Worker cache)"
echo "  2. DevTools → Application → Service Workers → Unregister"
echo "  3. Skontroluj konzolu — hľadaj POST .../generate-content (nie 503)"
echo ""
echo "Typické chyby:"
echo "  503 + 'chýba MISTRAL_API_KEY' → sekcia 2 (Supabase secrets)"
echo "  401 → nie si prihlásený v appke"
echo "  Paywall sheet → free tier limit (1 AI request/mesiac)"
echo "  'AI dočasne nedostupné' v chate → starý cache alebo 503 z minulosti"
echo ""

[[ "$FAIL" -eq 0 ]] && exit 0 || exit 1