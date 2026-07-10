#!/usr/bin/env bash
# Live E2E checklist — spustí appku, sleduje logcat a overí Supabase init + auth flow.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

export ANDROID_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
export PATH="$ANDROID_HOME/platform-tools:$PATH"

DEVICE="${1:-}"
if [[ -z "$DEVICE" ]]; then
  DEVICE=$(adb devices 2>/dev/null | awk '/emulator-.*device$/ {print $1; exit}')
fi

if [[ -z "${DEVICE:-}" ]]; then
  echo "❌ Žiadny emulátor. Spusti: flutter emulators --launch Pixel_10"
  exit 1
fi

LOG_FILE="/tmp/bizagent_e2e_${DEVICE}.log"
rm -f "$LOG_FILE"

echo "→ E2E checklist na $DEVICE"
echo "→ Log: $LOG_FILE"
echo ""

adb -s "$DEVICE" logcat -c >/dev/null 2>&1 || true
adb -s "$DEVICE" logcat -v time >"$LOG_FILE" 2>&1 &
LOGCAT_PID=$!
cleanup() {
  kill "$LOGCAT_PID" 2>/dev/null || true
}
trap cleanup EXIT

if pgrep -f "flutter run.*supabase.json" >/dev/null 2>&1; then
  echo "→ flutter run už beží — pripájam sa"
  bash "$ROOT/scripts/attach_android.sh" "$DEVICE" &
  RUN_PID=$!
else
  echo "→ Spúšťam flutter run…"
  bash "$ROOT/scripts/run_with_supabase.sh" -d "$DEVICE" &
  RUN_PID=$!
fi

echo "→ Čakám 90 s na boot + Supabase init…"
sleep 90

PASS=0
FAIL=0
check() {
  local label="$1"
  local pattern="$2"
  if grep -qE "$pattern" "$LOG_FILE" 2>/dev/null; then
    echo "  ✅ $label"
    PASS=$((PASS + 1))
  else
    echo "  ❌ $label"
    FAIL=$((FAIL + 1))
  fi
}

check_absent() {
  local label="$1"
  local pattern="$2"
  if grep -qE "$pattern" "$LOG_FILE" 2>/dev/null; then
    echo "  ❌ $label"
    FAIL=$((FAIL + 1))
  else
    echo "  ✅ $label"
    PASS=$((PASS + 1))
  fi
}

echo ""
echo "=== Výsledky logcat ==="
check "BizAgent proces beží" "sk\.bizagent\.app"
check "Supabase init" "Supabase init completed|Supabase.*initialize"
check_absent "Žiadny FATAL pre BizAgent" "FATAL EXCEPTION.*sk\.bizagent\.app"
check "Flutter engine OK" "Flutter engine|Dart VM"

if grep -qE "FATAL EXCEPTION.*sk\.bizagent\.app" "$LOG_FILE"; then
  echo ""
  echo "⚠️  Nájdený crash — posledných 30 riadkov:"
  grep -A 20 "FATAL EXCEPTION.*sk\.bizagent\.app" "$LOG_FILE" | tail -30
fi

echo ""
echo "=== Manuálny checklist (v emulátore) ==="
echo "  [ ] Google / email login"
echo "  [ ] Dashboard sa zobrazí"
echo "  [ ] Vytvor faktúru (číslo 2026/001 formát)"
echo "  [ ] Soft delete → kôš → obnoviť"
echo "  [ ] Nastavenia → Zmazať účet"
echo ""
echo "Pass: $PASS | Fail: $FAIL | Log: $LOG_FILE"
echo ""
echo "Ukonči flutter run: kill $RUN_PID (alebo Ctrl+C v termináli)"

if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi