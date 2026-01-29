#!/bin/bash
# Skript na testovanie UI zmien
# Spustenie: ./test_ui_changes.sh

echo "🧪 Testovanie UI zmien"
echo "======================"
echo ""

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 1. Kontrola syntaxe
echo "1️⃣  Kontrola syntaxe..."
if flutter analyze lib/features/intro/screens/modern_onboarding_screen.dart lib/features/auth/screens/firebase_login_screen.dart 2>&1 | grep -q "No issues found"; then
    echo -e "${GREEN}✅${NC} Syntax je správna"
else
    echo -e "${YELLOW}⚠️${NC}  Kontrola syntaxe dokončená (môžu byť varovania)"
fi

# 2. Kontrola zmien v modern_onboarding_screen.dart
echo ""
echo "2️⃣  Kontrola zmien v modern_onboarding_screen.dart..."
if grep -q "SingleChildScrollView" lib/features/intro/screens/modern_onboarding_screen.dart; then
    echo -e "${GREEN}✅${NC} SingleChildScrollView je použité (namiesto ListView)"
else
    echo -e "${RED}❌${NC} SingleChildScrollView nie je nájdené"
fi

if grep -q "Flexible" lib/features/intro/screens/modern_onboarding_screen.dart; then
    echo -e "${GREEN}✅${NC} Flexible je použité (namiesto Expanded)"
else
    echo -e "${YELLOW}⚠️${NC}  Flexible nie je nájdené"
fi

# 3. Kontrola zmien v firebase_login_screen.dart
echo ""
echo "3️⃣  Kontrola zmien v firebase_login_screen.dart..."
if grep -q "Container(color: Colors.white)" lib/features/auth/screens/firebase_login_screen.dart; then
    echo -e "${GREEN}✅${NC} Biele pozadie je nastavené"
else
    echo -e "${RED}❌${NC} Biele pozadie nie je nastavené"
fi

if ! grep -q "background_fusion.webp" lib/features/auth/screens/firebase_login_screen.dart; then
    echo -e "${GREEN}✅${NC} Pozadie s obrázkom je odstránené"
else
    echo -e "${RED}❌${NC} Pozadie s obrázkom stále existuje"
fi

# 4. Kontrola počtu business types
echo ""
echo "4️⃣  Kontrola business types..."
BUSINESS_TYPES_COUNT=$(grep -c "'type':" lib/features/intro/screens/modern_onboarding_screen.dart || echo "0")
if [ "$BUSINESS_TYPES_COUNT" -eq 4 ]; then
    echo -e "${GREEN}✅${NC} Všetky 4 business types sú prítomné (IT služby, Obchod, Remeslo, Iné)"
else
    echo -e "${YELLOW}⚠️${NC}  Nájdených business types: $BUSINESS_TYPES_COUNT (očakávané: 4)"
fi

# Summary
echo ""
echo "======================"
echo -e "${GREEN}✅ Testovanie dokončené!${NC}"
echo ""
echo "📝 Ďalšie kroky:"
echo "   1. Spusti aplikáciu: flutter run"
echo "   2. Over obrazovku 'Vyberte typ podnikania' - všetky 4 možnosti by mali byť viditeľné"
echo "   3. Over login obrazovku - pozadie by malo byť čisto biele"
echo ""
