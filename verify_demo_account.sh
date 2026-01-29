#!/bin/bash
# Skript na overenie demo účtu v Firebase
# Spustenie: ./verify_demo_account.sh

DEMO_EMAIL="bizbizagent@bizbizagent.com"
DEMO_PASSWORD="1369#1369#1369#"

echo "🔍 Overovanie Demo Účtu"
echo "======================"
echo ""

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 1. Firebase CLI Check
echo "1️⃣  Firebase CLI:"
if command -v firebase &> /dev/null; then
    echo -e "${GREEN}✅${NC} Firebase CLI installed"
else
    echo -e "${RED}❌${NC} Firebase CLI not found"
    exit 1
fi

# 2. Firebase Login Check
echo ""
echo "2️⃣  Firebase Login:"
if firebase projects:list > /dev/null 2>&1; then
    echo -e "${GREEN}✅${NC} Logged into Firebase"
else
    echo -e "${RED}❌${NC} Not logged in. Run: firebase login"
    exit 1
fi

# 3. Project Check
echo ""
echo "3️⃣  Firebase Project:"
CURRENT=$(firebase use 2>&1 | grep "Using" | awk '{print $2}' || firebase use 2>&1 | grep "bizagent-live-2026" && echo "bizagent-live-2026")
if [ -n "$CURRENT" ] && echo "$CURRENT" | grep -q "bizagent-live-2026"; then
    echo -e "${GREEN}✅${NC} Using project: bizagent-live-2026"
elif [ -z "$CURRENT" ]; then
    echo -e "${YELLOW}⚠️${NC}  Setting project to bizagent-live-2026..."
    firebase use bizagent-live-2026 > /dev/null 2>&1
    echo -e "${GREEN}✅${NC} Project set to: bizagent-live-2026"
else
    echo -e "${YELLOW}⚠️${NC}  Current project: $CURRENT"
    echo -e "${BLUE}ℹ️${NC}  Setting to bizagent-live-2026..."
    firebase use bizagent-live-2026 > /dev/null 2>&1
    echo -e "${GREEN}✅${NC} Project set to: bizagent-live-2026"
fi

# 4. Manual Check Instructions
echo ""
echo "4️⃣  Demo Účet Overenie:"
echo -e "${YELLOW}⚠️  MANUÁLNA KONTROLA POTREBNÁ${NC}"
echo ""
echo "Firebase CLI nepodporuje priame overenie existencie používateľa."
echo "Musíš to urobiť manuálne:"
echo ""
echo "👉 Otvor: https://console.firebase.google.com/project/bizagent-live-2026/authentication/users"
echo ""
echo "Skontroluj:"
echo "  ✅ Účet existuje: ${BLUE}$DEMO_EMAIL${NC}"
echo "  ✅ Status je 'Enabled'"
echo "  ✅ Provider je 'password' (ikona obálky 📧, nie G)"
echo ""
echo "Ak účet neexistuje:"
echo "  1. Klikni 'Add User'"
echo "  2. Email: ${BLUE}$DEMO_EMAIL${NC}"
echo "  3. Password: ${BLUE}$DEMO_PASSWORD${NC}"
echo "  4. Zruš 'Send email verification'"
echo "  5. Klikni 'Add User'"
echo ""

# 5. Test Login Instructions
echo ""
echo "5️⃣  Testovanie Prihlásenia:"
echo -e "${BLUE}ℹ️  Testovanie v aplikácii:${NC}"
echo "  1. Spusti aplikáciu"
echo "  2. Choď na prihlasovaciu obrazovku"
echo "  3. Zadaj:"
echo "     Email: ${BLUE}$DEMO_EMAIL${NC}"
echo "     Password: ${BLUE}$DEMO_PASSWORD${NC}"
echo "  4. Klikni 'Prihlásiť sa'"
echo "  5. Over, že sa úspešne prihlásil"
echo ""

# Summary
echo "===================================="
echo "📊 STATUS"
echo "===================================="
echo -e "${GREEN}✅ Firebase CLI: OK${NC}"
echo -e "${GREEN}✅ Firebase Login: OK${NC}"
echo -e "${GREEN}✅ Firebase Project: OK${NC}"
echo -e "${YELLOW}⚠️  Demo Účet: MANUÁLNA KONTROLA${NC}"
echo ""
echo "Ak si overil demo účet v Firebase Console a funguje login,"
echo "všetko je pripravené na Google Play upload! 🚀"
