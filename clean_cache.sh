#!/bin/bash
# Skript na kompletné čistenie cache a build súborov
# Spustenie: ./clean_cache.sh

echo "🧹 Čistenie Cache a Build Súborov"
echo "=================================="
echo ""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 1. Flutter clean
echo "1️⃣  Flutter clean..."
flutter clean > /dev/null 2>&1
echo -e "${GREEN}✅${NC} Flutter clean dokončený"

# 2. Odstránenie .dart_tool
echo ""
echo "2️⃣  Odstránenie .dart_tool..."
if [ -d ".dart_tool" ]; then
    rm -rf .dart_tool
    echo -e "${GREEN}✅${NC} .dart_tool vymazaný"
else
    echo -e "${YELLOW}⚠️${NC}  .dart_tool neexistuje"
fi

# 3. Odstránenie build directory
echo ""
echo "3️⃣  Odstránenie build cache..."
if [ -d "build" ]; then
    rm -rf build
    echo -e "${GREEN}✅${NC} build cache vymazaný"
else
    echo -e "${YELLOW}⚠️${NC}  build cache neexistuje"
fi

# 4. Odstránenie iOS build
echo ""
echo "4️⃣  Odstránenie iOS build..."
if [ -d "ios/Pods" ]; then
    rm -rf ios/Pods ios/Podfile.lock
    echo -e "${GREEN}✅${NC} iOS Pods vymazané"
else
    echo -e "${YELLOW}⚠️${NC}  iOS Pods neexistujú"
fi

# 5. Odstránenie macOS build
echo ""
echo "5️⃣  Odstránenie macOS build..."
if [ -d "macos/Pods" ]; then
    rm -rf macos/Pods macos/Podfile.lock
    echo -e "${GREEN}✅${NC} macOS Pods vymazané"
else
    echo -e "${YELLOW}⚠️${NC}  macOS Pods neexistujú"
fi

# 6. Odstránenie .flutter-plugins
echo ""
echo "6️⃣  Odstránenie Flutter plugins cache..."
rm -f .flutter-plugins .flutter-plugins-dependencies
echo -e "${GREEN}✅${NC} Flutter plugins cache vymazaný"

# 7. Odstránenie coverage
echo ""
echo "7️⃣  Odstránenie coverage súborov..."
rm -rf coverage .coverage
echo -e "${GREEN}✅${NC} Coverage súbory vymazané"

# Summary
echo ""
echo "=================================="
echo -e "${GREEN}✅ Cache vyčistený!${NC}"
echo ""
echo "📝 Ďalšie kroky:"
echo "   1. flutter pub get"
echo "   2. flutter pub upgrade (voliteľné)"
echo "   3. flutter run (pre testovanie)"
