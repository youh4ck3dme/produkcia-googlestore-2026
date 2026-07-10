#!/usr/bin/env bash
# Pripojí sa k už bežiacej BizAgent na emulátore bez force-stop / reinstalácie.
# Použi keď flutter run ukončí s „Lost connection to device“, ale appka na emulátore beží.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

DEFINES="$ROOT/dart_defines/supabase.json"
if [[ ! -f "$DEFINES" ]]; then
  echo "Chýba $DEFINES"
  exit 1
fi

export ANDROID_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
export PATH="$ANDROID_HOME/platform-tools:$PATH"

DEVICE="${1:-}"
if [[ -z "$DEVICE" ]]; then
  DEVICE=$(adb devices 2>/dev/null | awk '/emulator-.*device$/ {print $1; exit}')
fi

if [[ -z "${DEVICE:-}" ]]; then
  echo "Žiadny bežiaci emulátor."
  exit 1
fi

echo "→ Pripájam sa k $DEVICE (bez reinstalácie)…"
exec flutter attach \
  --dart-define-from-file="$DEFINES" \
  -d "$DEVICE" \
  --device-timeout 120