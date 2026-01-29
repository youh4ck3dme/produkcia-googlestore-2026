#!/usr/bin/env bash

set -euo pipefail

# macOS Flutter environment setup (safer, Homebrew-based)
# - Installs Flutter via Homebrew (real installation)
# - Optionally installs Node + Firebase CLI
# - Avoids sudo steps (Xcode license / android licenses) and keeps them as manual next steps

INSTALL_FIREBASE_TOOLS=0
INSTALL_COCOAPODS=1

usage() {
  cat <<'EOF'
Usage: ./flutter_complete_setup.sh [options]

Options:
  --install-firebase-tools   Install firebase-tools globally via npm (requires node)
  --skip-cocoapods           Skip CocoaPods install (for iOS)
  -h, --help                 Show help

Notes:
  - This script is for macOS.
  - Some steps remain manual (Xcode license, Android Studio/SDK).
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --install-firebase-tools)
      INSTALL_FIREBASE_TOOLS=1; shift;;
    --skip-cocoapods)
      INSTALL_COCOAPODS=0; shift;;
    -h|--help)
      usage; exit 0;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 2
      ;;
  esac
done

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

progress() { echo -e "${BLUE}[$(date +'%H:%M:%S')]${NC} $1"; }
success() { echo -e "${GREEN}✓${NC} $1"; }
warning() { echo -e "${YELLOW}⚠${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1"; }

require_cmd() {
  local cmd="$1"
  local hint="${2:-}"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    error "$cmd not found"
    [[ -n "$hint" ]] && echo "$hint" >&2
    exit 1
  fi
}

if [[ "$(uname)" != "Darwin" ]]; then
  error "This script is intended for macOS (Darwin)."
  exit 1
fi

progress "Checking Homebrew..."
if ! command -v brew >/dev/null 2>&1; then
  error "Homebrew not found. Install it first from https://brew.sh (interactive)."
  echo "After installing brew, re-run this script." >&2
  exit 1
fi
success "Homebrew available"

progress "Installing Flutter (Homebrew cask)..."
brew list --cask flutter >/dev/null 2>&1 || brew install --cask flutter
success "Flutter installed/updated"

progress "Verifying Flutter..."
require_cmd flutter "Restart your terminal if flutter is not found, then re-run."
success "$(flutter --version | head -n 1)"

progress "Configuring Flutter (web + macOS desktop)..."
flutter config --enable-web >/dev/null
flutter config --enable-macos-desktop >/dev/null
success "Flutter configured"

if [[ "$INSTALL_COCOAPODS" -eq 1 ]]; then
  progress "Installing CocoaPods (for iOS builds)..."
  brew list cocoapods >/dev/null 2>&1 || brew install cocoapods
  success "CocoaPods installed/updated"
else
  warning "Skipped CocoaPods"
fi

if [[ "$INSTALL_FIREBASE_TOOLS" -eq 1 ]]; then
  progress "Installing Node.js (needed for firebase-tools)..."
  brew list node >/dev/null 2>&1 || brew install node
  success "Node installed/updated"

  progress "Installing Firebase CLI (firebase-tools)..."
  require_cmd npm "npm missing even after installing node; check PATH."
  if command -v firebase >/dev/null 2>&1; then
    success "Firebase CLI already available"
  else
    npm install -g firebase-tools
    success "Firebase CLI installed"
  fi
else
  warning "Skipping Firebase CLI install. You can later run: brew install node && npm install -g firebase-tools"
fi

progress "Installing FlutterFire CLI (dart global)..."
require_cmd dart "Dart should come with Flutter; if missing, restart terminal."
dart pub global activate flutterfire_cli
success "FlutterFire CLI installed"

progress "Running Flutter doctor (this may show manual items)..."
flutter doctor -v || true

cat <<EOF

Setup summary:
- Flutter: installed (Homebrew)
- Web + macOS desktop: enabled
- CocoaPods: ${INSTALL_COCOAPODS}
- Firebase CLI: ${INSTALL_FIREBASE_TOOLS}

Manual next steps (if needed):
- iOS: install Xcode from App Store, then run Xcode once to accept license
- Android: install Android Studio and SDK, then run: flutter doctor --android-licenses

Now you can run the BizAgent project setup:
  ./setup_bizagent.sh --install-firebase-tools
EOF
