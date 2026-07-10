#!/usr/bin/env bash
# Pripraví release AAB a vypíše metadáta pre Google Play upload.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

if [[ ! -f "dart_defines/supabase.json" ]]; then
  echo -e "${RED}❌ Chýba dart_defines/supabase.json${NC}"
  exit 1
fi

VERSION=$(grep "^version:" pubspec.yaml | sed 's/version: //' | tr -d ' ')
VERSION_NAME="${VERSION%%+*}"
VERSION_CODE="${VERSION##*+}"

echo -e "${GREEN}📱 BizAgent Play Upload Helper${NC}"
echo "=================================================="
echo "Package:     sk.bizagent.app"
echo "Version:     $VERSION_NAME ($VERSION_CODE)"
echo ""

read -r -p "Spustiť release build? [y/N] " BUILD
BUILD_LOWER=$(printf '%s' "$BUILD" | tr '[:upper:]' '[:lower:]')
if [[ "$BUILD_LOWER" == "y" ]]; then
  ./build_release_aab.sh
fi

AAB="build/app/outputs/bundle/release/app-release.aab"
if [[ ! -f "$AAB" ]]; then
  echo -e "${RED}❌ AAB neexistuje: $AAB${NC}"
  echo "   Spusti: ./build_release_aab.sh"
  exit 1
fi

SIZE=$(du -h "$AAB" | cut -f1)
SHA256=$(shasum -a 256 "$AAB" | awk '{print $1}')
MD5=$(md5 -q "$AAB" 2>/dev/null || md5sum "$AAB" | awk '{print $1}')

REPORT="build/play_upload_report.txt"
mkdir -p build

cat >"$REPORT" <<EOF
BizAgent Play Upload Report
Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
Git: $(git rev-parse --short HEAD 2>/dev/null || echo unknown)

Package:      sk.bizagent.app
Version name: $VERSION_NAME
Version code: $VERSION_CODE
AAB path:     $AAB
AAB size:     $SIZE
SHA-256:      $SHA256
MD5:          $MD5

Privacy URL:  https://web-one-beta-76.vercel.app/privacy.html
Deletion URL: https://web-one-beta-76.vercel.app/delete-account.html
Supabase:     kpsnwpuydqqojwmrnkdy

Play Console checklist:
  [ ] Create app sk.bizagent.app (new listing)
  [ ] Internal testing track
  [ ] Upload AAB above
  [ ] Privacy policy URL
  [ ] Account deletion URL
  [ ] Demo credentials for review
  [ ] Data safety form
EOF

echo ""
echo -e "${GREEN}📦 AAB${NC}"
echo "   Path:   $AAB"
echo "   Size:   $SIZE"
echo -e "${GREEN}🔐 SHA-256${NC}"
echo "   $SHA256"
echo -e "${GREEN}🔐 MD5${NC}"
echo "   $MD5"
echo ""
echo -e "${YELLOW}📄 Report uložený:${NC} $REPORT"
echo ""
echo "Ďalší krok: Play Console → Release → Internal testing → Upload"