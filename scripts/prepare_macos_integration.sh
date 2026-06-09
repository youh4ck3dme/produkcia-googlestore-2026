#!/usr/bin/env bash
# Pripraví macOS prostredie pre integration testy.
# Rieši: Xcode SPM konflikt s pluginmi bez SPM podpory (printing, flutter_local_notifications…).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "==> Vypínam Flutter Swift Package Manager (CocoaPods only)"
flutter config --no-enable-swift-package-manager

# Starý ios Package.resolved spôsobuje SPM prefetch chyby pri macOS build-e.
RESOLVED="$ROOT/ios/Runner.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
if [[ -f "$RESOLVED" ]]; then
  rm -f "$RESOLVED"
  echo "==> Odstránený ios SwiftPM Package.resolved (CocoaPods režim)"
fi

echo "==> flutter pub get"
flutter pub get

echo "==> macOS CocoaPods (pod install)"
cd macos
if command -v pod >/dev/null 2>&1; then
  pod install --repo-update
else
  echo "WARN: CocoaPods (pod) nie je nainštalovaný — spusti: sudo gem install cocoapods"
  exit 1
fi
cd "$ROOT"

if ! xcode-select -p >/dev/null 2>&1 || ! command -v xcodebuild >/dev/null 2>&1; then
  echo ""
  echo "WARN: Xcode Command Line Tools nie sú nastavené."
  echo "      Nainštaluj Xcode z App Store, potom spusti:"
  echo "      sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
  echo "      sudo xcodebuild -runFirstLaunch"
  echo ""
fi

echo "==> Hotovo."
echo ""
echo "Odporúčané (funguje BEZ plného Xcode):"
echo "  bash scripts/run_integration_tests.sh vm"
echo ""
echo "Natívny macOS compile smoke (vyžaduje Xcode z App Store):"
echo "  bash scripts/run_integration_tests.sh macos"
echo ""
echo "Widget/integration logika (odporúčané):"
echo "  bash scripts/run_integration_tests.sh vm"
