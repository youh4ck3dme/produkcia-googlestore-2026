#!/usr/bin/env bash
# Vytvorí BizAgent projekt v Linear s P0/P1 backlogom (priorita Urgent pre P0).
#
# Použitie:
#   export LINEAR_API_KEY="lin_api_..."
#   bash scripts/setup_linear_bizagent.sh
#
# API kľúč: https://linear.app/settings/api

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
exec python3 "$ROOT/scripts/setup_linear_bizagent.py"