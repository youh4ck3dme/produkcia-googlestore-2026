#!/bin/bash
# Vytvorí BizAgent_GooglePlay_Release.zip AŽ PO úspešnom otestovaní a builde.
# Použitie:
#   ./create_bizagent_googleplay_release_zip.sh        # spustí testy + build + zip
#   ./create_bizagent_googleplay_release_zip.sh --force # preskočí flutter test, spustí comprehensive + build + zip

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

FORCE=false
for arg in "$@"; do
  [ "$arg" = "--force" ] && FORCE=true
done

echo "📦 BizAgent – vytvorenie Google Play Release ZIP"
echo "================================================="
echo ""

if [ ! -f "pubspec.yaml" ]; then
  echo -e "${RED}❌ Spúšťaj z root adresára projektu (kde je pubspec.yaml).${NC}"
  exit 1
fi

# 1. Flutter testy (okrem --force)
if [ "$FORCE" = false ]; then
  echo -e "${YELLOW}1/4 Spúšťam flutter test...${NC}"
  if ! flutter test --no-pub 2>&1; then
    echo ""
    echo -e "${RED}❌ Flutter testy zlyhali. Oprav zlyhávajúce testy alebo spusti s --force po manuálnom otestovaní.${NC}"
    echo "   Pozri: TEST_STATUS_RELEASE.md"
    exit 1
  fi
  echo -e "${GREEN}✅ Flutter testy prešli.${NC}"
  echo ""
else
  echo -e "${YELLOW}1/4 Preskakujem flutter test (--force).${NC}"
  echo ""
fi

# 2. Comprehensive test
echo -e "${YELLOW}2/4 Spúšťam comprehensive_test.sh...${NC}"
if ! bash comprehensive_test.sh; then
  echo -e "${RED}❌ Comprehensive test zlyhal.${NC}"
  exit 1
fi
echo ""

# 3. Build AAB
echo -e "${YELLOW}3/4 Spúšťam build_release_aab.sh...${NC}"
if ! bash build_release_aab.sh; then
  echo -e "${RED}❌ Build AAB zlyhal.${NC}"
  exit 1
fi
echo ""

# 4. ZIP
echo -e "${YELLOW}4/4 Vytváram BizAgent_GooglePlay_Release.zip...${NC}"

AAB="build/app/outputs/bundle/release/app-release.aab"
CONTENT_DIR="GooglePlay_Release_Content"
ZIP_NAME="BizAgent_GooglePlay_Release.zip"

if [ ! -f "$AAB" ]; then
  echo -e "${RED}❌ AAB neexistuje: $AAB${NC}"
  exit 1
fi

if [ ! -d "$CONTENT_DIR" ]; then
  echo -e "${RED}❌ Priečinok neexistuje: $CONTENT_DIR${NC}"
  exit 1
fi

# Dočasný adresár pre obsah zipu
TMP_DIR=$(mktemp -d)
trap "rm -rf '$TMP_DIR'" EXIT

cp "$AAB" "$TMP_DIR/"
cp -r "$CONTENT_DIR" "$TMP_DIR/"

# Vytvor zip v root projekte (cesty v zip: app-release.aab, GooglePlay_Release_Content/...)
ZIP_PATH="$(pwd)/$ZIP_NAME"
(cd "$TMP_DIR" && zip -r -q "$ZIP_PATH" .)

echo -e "${GREEN}✅ ZIP vytvorený: $ZIP_NAME${NC}"
SIZE=$(du -h "$ZIP_NAME" | cut -f1)
echo -e "${GREEN}   Veľkosť: $SIZE${NC}"
echo ""
echo "Obsah zipu:"
echo "  - app-release.aab"
echo "  - GooglePlay_Release_Content/ (STORE_LISTING_SK.md, prompty, checklist, ...)"
echo ""
echo -e "${GREEN}🎉 Release balík je pripravený. Nahraj AAB do Google Play Console a použij texty z GooglePlay_Release_Content.${NC}"
