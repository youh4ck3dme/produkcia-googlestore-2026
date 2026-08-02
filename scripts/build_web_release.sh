#!/usr/bin/env bash
# Release web build s embednutým Supabase (povinné pre login na bizagent.sk).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

DEFINES="${SUPABASE_DEFINES:-$ROOT/dart_defines/supabase.json}"
[[ -f "$DEFINES" ]] || { echo "ERROR: chýba $DEFINES" >&2; exit 1; }

echo "==> Flutter web release (Supabase embed)"
flutter pub get
flutter build web --release \
  --base-href "/" \
  --dart-define-from-file="$DEFINES" \
  --dart-define=PLAY_MVP=true \
  --no-wasm-dry-run

JS="build/web/main.dart.js"
[[ -f "$JS" ]] || { echo "ERROR: chýba $JS" >&2; exit 1; }

if ! grep -q 'kpsnwpuydqqojwmrnkdy' "$JS"; then
  echo "ERROR: Supabase URL nie je v main.dart.js — login na webe nebude fungovať!" >&2
  exit 1
fi

echo "OK: Supabase embed overený v build/web/main.dart.js"