#!/bin/bash
# BizAgent — release AAB pre NOVÝ Google Play listing (sk.bizagent.app)
#
# Toto NIE JE update starej appky (com.bizagent.live). Vytvor nový listing v Play Console.
# SHA1 mismatch so starým listingom ignoruj — iná applicationId + nový upload kľúč.
#
# Predpoklady (spusti skôr):
#   - flutter test          (celý test/) alebo ./run_all_tests.sh
#   - ./verify_demo_account.sh
#
# Tento skript:
#   - vyžaduje android/key.properties + upload keystore (storeFile musí existovať)
#   - flutter clean, pub get, analyze, build appbundle --release --obfuscate
#   - bez keystore ukončí s chybou (nepodpisuje debug AAB ako „release“)
#
# NOVÁ PLAY LISTING (2026): applicationId sk.bizagent.app — nie update starej com.bizagent.live.
#   1) Play Console: Create app (new package), Play App Signing, upload AAB.
#   2) Firebase: Project bizagent-live-2026 → Add Android app sk.bizagent.app + SHA-1/256 upload key.
#      Stiahni google-services.json → android/app/ a spusti: dart run flutterfire_cli:flutterfire configure
#   3) android/key.properties + upload keystore (starý .jks nemazať).
#
# Kedy: len pred uploadom do Play Console — nie pri bežnom commite.
#
# Usage: ./build_release_aab.sh

set -e

echo "🚀 BizAgent — Release AAB (NEW Play listing: sk.bizagent.app)"
echo "=================================================="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check Flutter
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter nie je nainštalovaný!${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Flutter nájdený${NC}"
flutter --version | head -1

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}❌ Spúšťaj z root adresára projektu!${NC}"
    exit 1
fi

# Check Android signing config (prevent accidentally building debug-signed AAB for Play)
KEY_PROPS="android/key.properties"
if [ ! -f "$KEY_PROPS" ]; then
    echo ""
    echo -e "${RED}❌ Chýba $KEY_PROPS${NC}"
    echo "   Pre Google Play musíš mať upload keystore + key.properties."
    echo "   Použi šablónu: android/key.properties.example"
    exit 1
fi

STORE_FILE=$(grep -E '^storeFile=' "$KEY_PROPS" | head -1 | cut -d= -f2- | tr -d '\r')
KEY_ALIAS=$(grep -E '^keyAlias=' "$KEY_PROPS" | head -1 | cut -d= -f2- | tr -d '\r')

if [ -z "$STORE_FILE" ] || [ -z "$KEY_ALIAS" ]; then
    echo ""
    echo -e "${RED}❌ $KEY_PROPS je nekompletný (storeFile/keyAlias).${NC}"
    echo "   Skontroluj formát podľa android/key.properties.example"
    exit 1
fi

if [[ "$STORE_FILE" = /* ]]; then
    KEYSTORE_PATH="$STORE_FILE"
else
    KEYSTORE_PATH="android/app/$STORE_FILE"
fi

if [ ! -f "$KEYSTORE_PATH" ]; then
    echo ""
    echo -e "${RED}❌ Keystore súbor neexistuje: $KEYSTORE_PATH${NC}"
    echo "   Skontroluj storeFile v $KEY_PROPS (podľa android/key.properties.example)."
    exit 1
fi

# Clean previous builds
echo ""
echo -e "${YELLOW}🧹 Čistenie predchádzajúcich buildov...${NC}"
flutter clean

# Get dependencies
echo ""
echo -e "${YELLOW}📦 Sťahovanie závislostí...${NC}"
flutter pub get

# Analyze code
echo ""
echo -e "${YELLOW}🔍 Analýza kódu...${NC}"
if flutter analyze --no-pub; then
    echo -e "${GREEN}✅ Žiadne problémy nájdené${NC}"
else
    echo -e "${YELLOW}⚠️  Nájdené problémy, ale pokračujeme...${NC}"
fi

# Check version
VERSION=$(grep "^version:" pubspec.yaml | sed 's/version: //' | tr -d ' ')
echo ""
echo -e "${GREEN}📱 Verzia aplikácie: ${VERSION}${NC}"

# Build AAB
echo ""
echo -e "${YELLOW}🔨 Budovanie Release AAB...${NC}"
echo "Toto môže trvať niekoľko minút..."
echo ""

if flutter build appbundle --release --obfuscate --split-debug-info=build/symbols; then
    echo ""
    echo -e "${GREEN}✅ Build úspešný!${NC}"
    echo ""
    
    AAB_PATH="build/app/outputs/bundle/release/app-release.aab"
    if [ -f "$AAB_PATH" ]; then
        SIZE=$(du -h "$AAB_PATH" | cut -f1)
        echo -e "${GREEN}📦 AAB súbor: ${AAB_PATH}${NC}"
        echo -e "${GREEN}📊 Veľkosť: ${SIZE}${NC}"
        echo ""
        echo -e "${GREEN}🎉 Aplikácia je pripravená na upload do Google Play!${NC}"
        echo ""
        echo "Ďalšie kroky:"
        echo "1. Otvor Google Play Console → Vytvor NOVÚ aplikáciu (package: sk.bizagent.app)"
        echo "2. Choď na Release > Production (alebo Internal Testing)"
        echo "3. Upload súbor: $AAB_PATH"
        echo "4. Pri prvom upload-e zapni Play App Signing (upload key z android/app/upload-keystore.jks)"
        echo "5. Postupuj podľa GOOGLE_PLAY_UPLOAD_CHECKLIST.md"
    else
        echo -e "${RED}❌ AAB súbor nebol nájdený!${NC}"
        exit 1
    fi
else
    echo ""
    echo -e "${RED}❌ Build zlyhal!${NC}"
    exit 1
fi
