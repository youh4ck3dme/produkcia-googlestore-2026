#!/usr/bin/env bash
# BizAgent — Google OAuth redirect URI + test user (Google Cloud Console helper)
# Spusti: bash scripts/setup_google_oauth_redirect.sh [email]
set -euo pipefail

REDIRECT_URI="https://xitittqtaeyazcpaylsz.supabase.co/auth/v1/callback"
PROJECT="gifted-mountain-476207-u4"
CLIENT_ID="90348815049-s8ecj4dq2dd5pmo172h4g9khhbt3m7lg.apps.googleusercontent.com"
TEST_EMAIL="${1:-u0352652320@gmail.com}"

echo "→ Redirect URI (kopíruje sa do schránky):"
echo "  $REDIRECT_URI"
if command -v pbcopy >/dev/null 2>&1; then
  printf '%s' "$REDIRECT_URI" | pbcopy
  echo "  ✓ Skopírované (Cmd+V v Google Console)"
fi

echo ""
echo "→ Otváram Google Auth Platform…"
echo "  1) Clients — pridaj Redirect URI (Cmd+V) a Save"
echo "  2) Audience — + Add users → $TEST_EMAIL"

CLIENTS_URL="https://console.cloud.google.com/auth/clients/${CLIENT_ID}?project=${PROJECT}"
AUDIENCE_URL="https://console.cloud.google.com/auth/audience?project=${PROJECT}"

if command -v open >/dev/null 2>&1; then
  open "$CLIENTS_URL"
  sleep 1
  open "$AUDIENCE_URL"
else
  echo "Clients:  $CLIENTS_URL"
  echo "Audience: $AUDIENCE_URL"
fi

echo ""
echo "Po Save v Console otestuj:"
echo "  bash scripts/run_with_supabase.sh"
