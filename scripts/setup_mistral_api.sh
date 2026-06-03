#!/usr/bin/env bash
# Mistral API — príprava kľúča a dokumentácia stavu backendu.
#
# STAV PROJEKTU (2026-06):
#   functions/index.js volá Google Gemini cez @google/genai + GEMINI_API_KEY.
#   Mistral NIE JE zapojený v produkčnom index.js.
#
# Tento skript:
#   1) uloží MISTRAL_API_KEY / MISTRAL_MODEL do functions/.env
#   2) voliteľne Firebase Secret
#   3) vypíše čo treba pre skutočnú migráciu (samostatná úloha, nie overwrite)
#
# Usage:
#   MISTRAL_API_KEY=sk-... ./scripts/setup_mistral_api.sh
#   MISTRAL_MODEL=mistral-small-latest ./scripts/setup_mistral_api.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [ -z "${MISTRAL_API_KEY:-}" ]; then
  echo "ERROR: nastav MISTRAL_API_KEY v prostredí."
  echo "  MISTRAL_API_KEY=sk-xxx ./scripts/setup_mistral_api.sh"
  echo ""
  echo "Kľúč: https://console.mistral.ai/"
  exit 1
fi

export MISTRAL_MODEL="${MISTRAL_MODEL:-mistral-small-latest}"
bash scripts/setup_functions_api.sh

echo ""
echo "════════════════════════════════════════════════════════"
echo " Mistral kľúč uložený — backend stále beží na GEMINI"
echo "════════════════════════════════════════════════════════"
echo ""
echo "Pre prepnutie Cloud Functions na Mistral treba:"
echo "  1) Upraviť functions/index.js (axios → api.mistral.ai/v1/chat/completions)"
echo "  2) Pridať defineString('MISTRAL_API_KEY') alebo secret binding"
echo "  3) Otestovať: node test_gemini_direct.js → nový test_mistral_direct.js"
echo "  4) firebase deploy --only functions"
echo ""
echo "NEDOPORÚČAME prepisovať celý repo jedným cat-skriptom —"
echo "zničí to Play MVP (create_expense OCR, onboarding, privacy GDPR)."
echo ""
echo "Rýchly test Gemini backendu (aktuálny): node test_gemini_direct.js"
