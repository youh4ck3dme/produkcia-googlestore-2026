#!/usr/bin/env bash
# Spustí BizAgent s Supabase credentials z dart_defines/supabase.json
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

DEFINES="$ROOT/dart_defines/supabase.json"
if [[ ! -f "$DEFINES" ]]; then
  echo "Chýba $DEFINES"
  echo "Skopíruj: cp dart_defines/supabase.example.json dart_defines/supabase.json"
  echo "A doplň URL + publishable key z Supabase dashboardu."
  exit 1
fi

flutter run --dart-define-from-file="$DEFINES" "$@"
