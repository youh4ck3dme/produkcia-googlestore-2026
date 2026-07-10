#!/usr/bin/env bash
# Spustí BizAgent s Supabase credentials z dart_defines/supabase.json
# Predvolene: Android emulátor (Pixel_10). macOS vyžaduje Xcode signing.
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

export ANDROID_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
export PATH="$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$PATH"

# Zabráň dvojitému flutter run (druhý beh robí force-stop pred reinstaláciou)
if pgrep -f "flutter run.*dart-define-from-file.*supabase.json" >/dev/null 2>&1; then
  echo "⚠️  Už beží flutter run s Supabase. Použi:"
  echo "   bash scripts/attach_android.sh"
  echo "   alebo ukonči existujúci proces (Ctrl+C v tom termináli)."
  exit 1
fi

DEVICE_ARGS=()
if [[ $# -gt 0 ]]; then
  DEVICE_ARGS=("$@")
else
  ANDROID_ID=$(flutter devices --machine 2>/dev/null | python3 -c "
import json, sys
for d in json.load(sys.stdin):
    if d.get('platformType') == 'android' and d.get('emulator'):
        print(d['id']); break
    if d.get('platformType') == 'android':
        print(d['id']); break
" 2>/dev/null || true)

  if [[ -z "${ANDROID_ID:-}" ]]; then
    echo "→ Žiadny Android emulátor — spúšťam Pixel_10…"
    flutter emulators --launch Pixel_10 >/dev/null 2>&1 || true
    echo "→ Čakám na boot emulátora (max 120 s)…"
    for _ in $(seq 1 40); do
      adb start-server >/dev/null 2>&1 || true
      ANDROID_ID=$(adb devices 2>/dev/null | awk '/emulator-.*device$/ {print $1; exit}')
      if [[ -n "${ANDROID_ID:-}" ]]; then
        BOOT=$(adb -s "$ANDROID_ID" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')
        if [[ "$BOOT" == "1" ]]; then
          break
        fi
      fi
      sleep 3
    done
  fi

  if [[ -n "${ANDROID_ID:-}" ]]; then
    echo "→ Cieľové zariadenie: $ANDROID_ID"
    bash "$ROOT/scripts/clean_emulator_apps.sh" "$ANDROID_ID" || true
    DEVICE_ARGS=(-d "$ANDROID_ID")
  else
    echo "⚠️  Android emulátor sa nenašiel. Spusti manuálne:"
    echo "   flutter emulators --launch Pixel_10"
    echo "   bash scripts/run_with_supabase.sh -d emulator-5554"
    exit 1
  fi
fi

exec flutter run \
  --dart-define-from-file="$DEFINES" \
  --device-timeout 120 \
  "${DEVICE_ARGS[@]}"