#!/usr/bin/env bash
# Spustí MVP integration testy.
#   vm     — bez Xcode (odporúčané lokálne), beží na test VM
#   macos  — natívny macOS build (vyžaduje plný Xcode z App Store)
#   android— Android emulátor
#   auto   — vm ak chýba xcodebuild, inak macos/emulator
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

TARGET="${1:-auto}"
DART_DEFINES=(
  "--dart-define=PLAY_MVP=true"
  "--dart-define=CI=true"
)

xcode_ready() {
  xcodebuild -version >/dev/null 2>&1
}

run_vm_tests() {
  echo "==> MVP integration testy (VM, bez Xcode build)"
  flutter test test/integration_mvp/ "${DART_DEFINES[@]}"
}

pick_device() {
  if [[ "$TARGET" == "vm" ]]; then
    echo "vm"
    return
  fi
  if [[ "$TARGET" == "macos" ]]; then
    echo "macos"
    return
  fi
  if [[ "$TARGET" == "android" ]]; then
    flutter devices 2>/dev/null | rg -o 'emulator-[0-9]+' | head -1 || true
    return
  fi
  # auto: prefer VM when Xcode missing
  if ! xcode_ready; then
    echo "vm"
    return
  fi
  if flutter devices 2>/dev/null | rg -q 'macos'; then
    echo "macos"
  elif flutter devices 2>/dev/null | rg -q 'emulator'; then
    flutter devices 2>/dev/null | rg -o 'emulator-[0-9]+' | head -1
  else
    echo "vm"
  fi
}

DEVICE="$(pick_device)"

if [[ "$DEVICE" == "vm" ]]; then
  if [[ "$TARGET" == "macos" ]] || [[ "$TARGET" == "auto" ]]; then
    echo "WARN: xcodebuild nie je dostupný — preskakujem macOS build."
    echo "      Pre natívny macOS test nainštaluj Xcode z App Store a spusti:"
    echo "      sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
    echo ""
  fi
  run_vm_tests
  exit 0
fi

if [[ "$DEVICE" == "macos" ]]; then
  bash "$ROOT/scripts/prepare_macos_integration.sh"
fi

echo "==> Integration testy na zariadení: $DEVICE"
if [[ "$DEVICE" == "macos" ]]; then
  for test_file in integration_test/e2e_complete_flow_test.dart \
    integration_test/integrity_test.dart \
    integration_test/performance_test.dart; do
    flutter test "$test_file" -d macos "${DART_DEFINES[@]}"
  done
elif [[ "$DEVICE" == "android" ]]; then
  echo "Android: compile smoke (emulator voliteľne lokálne)"
  flutter build apk --debug "${DART_DEFINES[@]}"
else
  flutter test integration_test/ -d "$DEVICE" "${DART_DEFINES[@]}"
fi
