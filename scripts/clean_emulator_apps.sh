#!/usr/bin/env bash
# Odstráni cudzie / testovacie APK z Android emulátora, ktoré môžu rušiť vývoj.
# BizAgent (sk.bizagent.app) sa NEMAŽE.
set -euo pipefail

export ANDROID_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
export PATH="$ANDROID_HOME/platform-tools:$PATH"

adb start-server >/dev/null 2>&1 || true

DEVICE="${1:-}"
if [[ -z "$DEVICE" ]]; then
  DEVICE=$(adb devices 2>/dev/null | awk '/emulator-.*device$/ {print $1; exit}')
fi

if [[ -z "${DEVICE:-}" ]]; then
  echo "Žiadny bežiaci emulátor. Spusti: flutter emulators --launch Pixel_10"
  exit 1
fi

echo "→ Emulátor: $DEVICE"

# Balíčky, ktoré spôsobovali crash / zmätok (nexify RECEIVER_EXPORTED na API 37)
REMOVE_PKGS=(
  com.nexify.myapplication
  com.george.pwa
)

for pkg in "${REMOVE_PKGS[@]}"; do
  if adb -s "$DEVICE" shell pm list packages 2>/dev/null | grep -q "package:$pkg"; then
    echo "→ Odstraňujem $pkg"
    adb -s "$DEVICE" uninstall "$pkg" >/dev/null 2>&1 || true
  else
    echo "→ $pkg nie je nainštalovaný — preskakujem"
  fi
done

echo ""
echo "Zostávajúce balíčky (okrem systémových):"
adb -s "$DEVICE" shell pm list packages -3 2>/dev/null | sed 's/package://' | sort