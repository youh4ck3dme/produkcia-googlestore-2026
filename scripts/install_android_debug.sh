#!/usr/bin/env bash
# Zostaví a nainštaluje debug APK s Supabase credentials (bez flutter run).
# Užitočné keď chceš appku spúšťať manuálne z launchera emulátora.
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

echo "→ Build debug APK s Supabase defines…"
flutter build apk --debug --dart-define-from-file="$DEFINES"

APK="build/app/outputs/flutter-apk/app-debug.apk"
if [[ ! -f "$APK" ]]; then
  echo "APK nebol nájdený: $APK"
  exit 1
fi

echo "→ Inštalujem na $DEVICE…"
adb -s "$DEVICE" install -r "$APK"

echo ""
echo "Hotovo. Spusti BizAgent z launchera emulátora (sk.bizagent.app)."
echo "Pre hot reload: bash scripts/attach_android.sh $DEVICE"