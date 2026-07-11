#!/usr/bin/env bash
# BizAgent — nastaví Google OAuth na Supabase (CLI) + otvorí Google Console pre redirect URI
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SECRETS_JSON="${GOOGLE_OAUTH_JSON:-$HOME/Documents/secrets/bizagent-auth/client_secret_90348815049-e5faruj0mfvnn34m80k9b9b5upp9nn6v.apps.googleusercontent.com.json}"
PROJECT_REF="${SUPABASE_PROJECT_REF:-kpsnwpuydqqojwmrnkdy}"
REDIRECT_URI="https://${PROJECT_REF}.supabase.co/auth/v1/callback"
GCP_PROJECT="gifted-mountain-476207-u4"

if [[ ! -f "$SECRETS_JSON" ]]; then
  echo "Chýba OAuth JSON: $SECRETS_JSON"
  exit 1
fi

export GOOGLE_CLIENT_ID
export GOOGLE_CLIENT_SECRET
read -r GOOGLE_CLIENT_ID GOOGLE_CLIENT_SECRET < <(python3 -c "
import json, sys
data = json.load(open('$SECRETS_JSON'))
block = data.get('web') or data.get('installed')
if not block:
    sys.exit('OAuth JSON musí obsahovať web alebo installed sekciu')
print(block['client_id'])
print(block['client_secret'])
")
export GOOGLE_CLIENT_ID GOOGLE_CLIENT_SECRET

echo "→ Supabase config push (Google provider)…"
cd "$ROOT"
supabase config push --yes

echo ""
echo "→ Google Console — pridaj redirect URI (Cmd+V):"
echo "  $REDIRECT_URI"
if command -v pbcopy >/dev/null 2>&1; then
  printf '%s' "$REDIRECT_URI" | pbcopy
  echo "  ✓ Skopírované do schránky"
fi

CLIENTS=(
  "90348815049-e5faruj0mfvnn34m80k9b9b5upp9nn6v.apps.googleusercontent.com"
)

if command -v open >/dev/null 2>&1; then
  for CID in "${CLIENTS[@]}"; do
    open "https://console.cloud.google.com/auth/clients/${CID}?project=${GCP_PROJECT}"
    sleep 1
  done
  open "https://supabase.com/dashboard/project/${PROJECT_REF}/auth/providers"
fi

echo ""
echo "Hotovo na Supabase strane. Po Save v Google Console otestuj:"
echo "  bash scripts/verify_supabase_live.sh"
echo "  bash scripts/run_with_supabase.sh"