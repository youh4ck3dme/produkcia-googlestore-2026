#!/usr/bin/env bash
# Nastaví API kľúče pre Firebase Cloud Functions (functions/.env + voliteľne Firebase Secrets).
#
# DÔLEŽITÉ — aktuálny produkčný backend (functions/index.js):
#   • GEMINI_API_KEY  → Google GenAI (generateContent, generateEmail, …)  ✅ POUŽÍVA SA
#   • ICOATLAS_API_KEY → lookup firiem
#   • MISTRAL_API_KEY  → zatiaľ NIE JE v index.js (len priprava do .env pre budúcu migráciu)
#
# NESPÚŠŤAJ hromadný overwrite index.js / Flutter screenov z externých snippetov.
#
# Usage:
#   GEMINI_API_KEY=xxx ./scripts/setup_functions_api.sh
#   MISTRAL_API_KEY=yyy ./scripts/setup_functions_api.sh   # uloží, ale backend stále Gemini
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
PROJECT="${FIREBASE_PROJECT:-bizagent-live-2026}"
ENV_FILE="functions/.env"
EXAMPLE="functions/.env.example"

if [ ! -f "$EXAMPLE" ]; then
  echo "ERROR: $EXAMPLE chýba"
  exit 1
fi

if [ ! -f "$ENV_FILE" ]; then
  cp "$EXAMPLE" "$ENV_FILE"
  echo "Vytvorený $ENV_FILE z example — doplň hodnoty."
fi

_set_env_var() {
  local key="$1"
  local val="$2"
  if grep -q "^${key}=" "$ENV_FILE" 2>/dev/null; then
    if [[ "$OSTYPE" == darwin* ]]; then
      sed -i '' "s|^${key}=.*|${key}=${val}|" "$ENV_FILE"
    else
      sed -i "s|^${key}=.*|${key}=${val}|" "$ENV_FILE"
    fi
  else
    echo "${key}=${val}" >> "$ENV_FILE"
  fi
}

if [ -n "${GEMINI_API_KEY:-}" ]; then
  _set_env_var "GEMINI_API_KEY" "$GEMINI_API_KEY"
  echo "✓ GEMINI_API_KEY zapísaný do $ENV_FILE"
fi

if [ -n "${ICOATLAS_API_KEY:-}" ]; then
  _set_env_var "ICOATLAS_API_KEY" "$ICOATLAS_API_KEY"
  echo "✓ ICOATLAS_API_KEY zapísaný do $ENV_FILE"
fi

if [ -n "${MISTRAL_API_KEY:-}" ]; then
  _set_env_var "MISTRAL_API_KEY" "$MISTRAL_API_KEY"
  echo "✓ MISTRAL_API_KEY zapísaný do $ENV_FILE (backend zatiaľ používa Gemini — pozri scripts/setup_mistral_api.sh)"
fi

if [ -n "${MISTRAL_MODEL:-}" ]; then
  _set_env_var "MISTRAL_MODEL" "$MISTRAL_MODEL"
  echo "✓ MISTRAL_MODEL=$MISTRAL_MODEL"
fi

echo ""
echo "Premenné v $ENV_FILE (maskované):"
grep -E '^[A-Z_]+=' "$ENV_FILE" | sed 's/=.*/=***/' || true

if command -v firebase >/dev/null && [ -n "${GEMINI_API_KEY:-}" ]; then
  echo ""
  read -r -p "Nahrať GEMINI_API_KEY do Firebase Secret? [y/N] " ans || true
  if [[ "${ans:-}" =~ ^[Yy]$ ]]; then
    firebase use "$PROJECT"
    printf '%s' "$GEMINI_API_KEY" | firebase functions:secrets:set GEMINI_API_KEY --project "$PROJECT"
    echo "✓ Firebase secret GEMINI_API_KEY nastavený"
  fi
fi

if command -v firebase >/dev/null && [ -n "${MISTRAL_API_KEY:-}" ]; then
  echo ""
  read -r -p "Nahrať MISTRAL_API_KEY do Firebase Secret (pre budúcu migráciu)? [y/N] " ans || true
  if [[ "${ans:-}" =~ ^[Yy]$ ]]; then
    firebase use "$PROJECT"
    printf '%s' "$MISTRAL_API_KEY" | firebase functions:secrets:set MISTRAL_API_KEY --project "$PROJECT"
    echo "✓ Firebase secret MISTRAL_API_KEY uložený (index.js ešte nemusí volať Mistral)"
  fi
fi

echo ""
echo "Deploy functions: ./deploy_functions.sh"
