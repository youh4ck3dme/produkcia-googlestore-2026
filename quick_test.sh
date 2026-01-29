#!/bin/bash
# Rýchly test produkčného API - jednoduchá verzia
# Spustenie: ./quick_test.sh

echo "🚀 BizAgent Quick Production Test"
echo "================================"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 1. Firebase CLI
echo "1️⃣  Checking Firebase CLI..."
if command -v firebase &> /dev/null; then
    echo -e "${GREEN}✓${NC} Firebase CLI installed"
else
    echo -e "${RED}✗${NC} Firebase CLI not found. Install: npm install -g firebase-tools"
    exit 1
fi

# 2. Firebase Login
echo ""
echo "2️⃣  Checking Firebase login..."
if firebase projects:list &> /dev/null; then
    echo -e "${GREEN}✓${NC} Logged into Firebase"
else
    echo -e "${RED}✗${NC} Not logged in. Run: firebase login"
    exit 1
fi

# 3. Project
echo ""
echo "3️⃣  Checking Firebase project..."
CURRENT=$(firebase use 2>&1 | grep "Using" | awk '{print $2}' || echo "")
if [ "$CURRENT" == "bizagent-live-2026" ]; then
    echo -e "${GREEN}✓${NC} Using project: bizagent-live-2026"
else
    echo -e "${YELLOW}⚠${NC}  Setting project to bizagent-live-2026..."
    firebase use bizagent-live-2026 || exit 1
fi

# 4. Files Check
echo ""
echo "4️⃣  Checking configuration files..."
FILES_OK=true

[ -f "lib/firebase_options.dart" ] && echo -e "${GREEN}✓${NC} firebase_options.dart" || { echo -e "${RED}✗${NC} firebase_options.dart missing"; FILES_OK=false; }
[ -f "firebase/firestore.rules" ] && echo -e "${GREEN}✓${NC} firestore.rules" || { echo -e "${RED}✗${NC} firestore.rules missing"; FILES_OK=false; }
[ -f "firebase/storage.rules" ] && echo -e "${GREEN}✓${NC} storage.rules" || { echo -e "${RED}✗${NC} storage.rules missing"; FILES_OK=false; }
[ -f "functions/index.js" ] && echo -e "${GREEN}✓${NC} functions/index.js" || { echo -e "${RED}✗${NC} functions/index.js missing"; FILES_OK=false; }

if [ "$FILES_OK" = false ]; then
    exit 1
fi

# 5. Cloud Functions Check
echo ""
echo "5️⃣  Checking Cloud Functions..."
FUNCTIONS_OK=true
if grep -q "exports.generateEmail" functions/index.js; then
    echo -e "${GREEN}✓${NC} generateEmail function"
else
    echo -e "${RED}✗${NC} generateEmail function missing"
    FUNCTIONS_OK=false
fi

if grep -q "exports.analyzeReceipt" functions/index.js; then
    echo -e "${GREEN}✓${NC} analyzeReceipt function"
else
    echo -e "${RED}✗${NC} analyzeReceipt function missing"
    FUNCTIONS_OK=false
fi

if grep -q "exports.lookupCompany" functions/index.js; then
    echo -e "${GREEN}✓${NC} lookupCompany function"
else
    echo -e "${RED}✗${NC} lookupCompany function missing"
    FUNCTIONS_OK=false
fi

if [ "$FUNCTIONS_OK" = false ]; then
    exit 1
fi

# 6. API Secrets Check
echo ""
echo "6️⃣  Checking API Secrets..."
if firebase functions:secrets:access GEMINI_API_KEY &> /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} GEMINI_API_KEY secret exists"
else
    echo -e "${YELLOW}⚠${NC}  GEMINI_API_KEY secret not set"
    echo "   Run: firebase functions:secrets:set GEMINI_API_KEY"
fi

# Summary
echo ""
echo "================================"
echo -e "${GREEN}✅ Basic checks passed!${NC}"
echo ""
echo "📝 Next steps:"
echo "   1. Run full test: ./test_production_firebase.sh"
echo "   2. Create demo account: ./create_demo_account.sh"
echo "   3. Deploy functions: firebase deploy --only functions"
echo "   4. See docs/PRODUCTION_API_TEST.md for details"
