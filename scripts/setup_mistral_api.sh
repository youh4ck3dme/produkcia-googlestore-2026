#!/usr/bin/env bash
# Mistral API — primárny + záložný kľúč (fallback v functions/mistral_client.js).
#
# Usage:
#   MISTRAL_API_KEY=primary MISTRAL_API_KEY_BACKUP=backup ./scripts/setup_mistral_api.sh
#   ./scripts/setup_mistral_api.sh --firebase-secrets   # nahrať aj do Firebase Secrets
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
PROJECT="${FIREBASE_PROJECT:-bizagent-pro-2026}"
UPLOAD_SECRETS=false

for arg in "$@"; do
  case "$arg" in
    --firebase-secrets) UPLOAD_SECRETS=true ;;
  esac
done

if [ -z "${MISTRAL_API_KEY:-}" ]; then
  echo "ERROR: nastav MISTRAL_API_KEY (primárny)."
  echo "  MISTRAL_API_KEY=xxx MISTRAL_API_KEY_BACKUP=yyy ./scripts/setup_mistral_api.sh"
  exit 1
fi

export MISTRAL_MODEL="${MISTRAL_MODEL:-mistral-small-latest}"
export MISTRAL_API_KEY_BACKUP="${MISTRAL_API_KEY_BACKUP:-}"

bash scripts/setup_functions_api.sh

if [ "$UPLOAD_SECRETS" = true ] && command -v firebase >/dev/null; then
  firebase use "$PROJECT"
  printf '%s' "$MISTRAL_API_KEY" | firebase functions:secrets:set MISTRAL_API_KEY --project "$PROJECT"
  echo "✓ Firebase secret MISTRAL_API_KEY"
  if [ -n "$MISTRAL_API_KEY_BACKUP" ]; then
    printf '%s' "$MISTRAL_API_KEY_BACKUP" | firebase functions:secrets:set MISTRAL_API_KEY_BACKUP --project "$PROJECT"
    echo "✓ Firebase secret MISTRAL_API_KEY_BACKUP"
  fi
fi

echo ""
echo "Mistral: primárny → záložný fallback v generateContent (po zlyhaní Gemini)."
echo "Deploy: ./deploy_functions.sh"
