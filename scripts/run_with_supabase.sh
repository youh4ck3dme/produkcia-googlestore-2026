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

wait_for_emulator_ready() {
  local device_id=$1
  echo "→ Čakám, kým Flutter uvidí emulátor (max 90 s)…"
  for _ in $(seq 1 30); do
    adb start-server >/dev/null 2>&1 || true
    if ! adb -s "$device_id" get-state >/dev/null 2>&1; then
      sleep 3
      continue
    fi
    local boot sdk
    boot=$(adb -s "$device_id" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')
    sdk=$(adb -s "$device_id" shell getprop ro.build.version.sdk 2>/dev/null | tr -d '\r')
    if [[ "$boot" == "1" && "$sdk" =~ ^[0-9]+$ ]]; then
      if flutter devices --machine 2>/dev/null | python3 -c "
import json, sys
target = '$device_id'
for d in json.load(sys.stdin):
    if d.get('id') == target and d.get('platformType') == 'android':
        raise SystemExit(0 if d.get('sdk') else 1)
raise SystemExit(1)
" 2>/dev/null; then
        echo "→ Emulátor pripravený (API $sdk)"
        return 0
      fi
    fi
    sleep 3
  done
  echo "⚠️  Emulátor ešte nie je stabilný pre flutter run."
  return 1
}

# Zabráň dvojitému flutter run (druhý beh robí force-stop pred reinstaláciou)
if pgrep -f "flutter run.*dart-define-from-file.*supabase.json" >/dev/null 2>&1; then
  echo "⚠️  Už beží flutter run s Supabase. Použi:"
  echo "   bash scripts/attach_android.sh"
  echo "   alebo ukonči existujúci proces (Ctrl+C v tom termináli)."
  exit 1
fi

DEVICE_ARGS=()
ANDROID_ID=""
if [[ $# -gt 0 ]]; then
  DEVICE_ARGS=("$@")
  for ((i=0; i<${#DEVICE_ARGS[@]}; i++)); do
    if [[ "${DEVICE_ARGS[$i]}" == "-d" && $((i+1)) -lt ${#DEVICE_ARGS[@]} ]]; then
      ANDROID_ID="${DEVICE_ARGS[$((i+1))]}"
      break
    fi
  done
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
    wait_for_emulator_ready "$ANDROID_ID" || true
    bash "$ROOT/scripts/clean_emulator_apps.sh" "$ANDROID_ID" || true
    wait_for_emulator_ready "$ANDROID_ID" || true
    DEVICE_ARGS=(-d "$ANDROID_ID")
  else
    echo "⚠️  Android emulátor sa nenašiel. Spusti manuálne:"
    echo "   flutter emulators --launch Pixel_10"
    echo "   bash scripts/run_with_supabase.sh -d emulator-5554"
    exit 1
  fi
fi

APK="$ROOT/build/app/outputs/flutter-apk/app-debug.apk"
for attempt in 1 2 3; do
  if flutter run \
    --dart-define-from-file="$DEFINES" \
    --device-timeout 120 \
    "${DEVICE_ARGS[@]}"; then
    exit 0
  fi
  echo "⚠️  flutter run zlyhal (pokus $attempt/3)."
  if [[ $attempt -lt 3 && -n "${ANDROID_ID:-}" ]]; then
    adb start-server >/dev/null 2>&1 || true
    wait_for_emulator_ready "$ANDROID_ID" || sleep 5
  fi
done

if [[ -f "$APK" && -n "${ANDROID_ID:-}" ]]; then
  echo "→ Fallback: inštalujem debug APK a pripájam sa cez flutter attach…"
  adb -s "$ANDROID_ID" install -r "$APK" >/dev/null 2>&1 || true
  adb -s "$ANDROID_ID" shell am start -n sk.bizagent.app/.MainActivity >/dev/null 2>&1 || true
  exec flutter attach \
    --dart-define-from-file="$DEFINES" \
    -d "$ANDROID_ID" \
    --device-timeout 120
fi

echo "❌ Nepodarilo sa spustiť na emulátore. Skús:"
echo "   adb kill-server && adb start-server"
echo "   flutter emulators --launch Pixel_10"
echo "   bash scripts/run_with_supabase.sh"
exit 1