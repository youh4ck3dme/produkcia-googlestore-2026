#!/bin/bash

# Test Cloud Functions pre Gemini API
# Ostré testy pre produkciu

set -e

echo "🧪 Testovanie Cloud Functions pre Gemini API"
echo "=============================================="
echo ""

# Farba pre výstup
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Firebase projekt
PROJECT_ID="bizagent-live-2026"
FUNCTIONS_URL="https://us-central1-${PROJECT_ID}.cloudfunctions.net"

echo "📋 Konfigurácia:"
echo "  Projekt: ${PROJECT_ID}"
echo "  Functions URL: ${FUNCTIONS_URL}"
echo ""

# 1. Test: Overenie, že funkcie sú nasadené
echo "1️⃣  Kontrola nasadených funkcií..."
echo ""

if firebase functions:list --project ${PROJECT_ID} 2>/dev/null | grep -q "generateContent"; then
    echo -e "${GREEN}✅ generateContent funkcia je nasadená${NC}"
else
    echo -e "${RED}❌ generateContent funkcia NIE JE nasadená${NC}"
    echo "   Spustite: firebase deploy --only functions"
    exit 1
fi

if firebase functions:list --project ${PROJECT_ID} 2>/dev/null | grep -q "generateEmail"; then
    echo -e "${GREEN}✅ generateEmail funkcia je nasadená${NC}"
else
    echo -e "${YELLOW}⚠️  generateEmail funkcia nie je nasadená (voliteľné)${NC}"
fi

echo ""

# 2. Test: Overenie API kľúča
echo "2️⃣  Kontrola Gemini API kľúča..."
echo ""

if firebase functions:secrets:access GEMINI_API_KEY --project ${PROJECT_ID} 2>/dev/null | grep -q "AIza"; then
    echo -e "${GREEN}✅ GEMINI_API_KEY secret je nastavený${NC}"
    API_KEY_SET=true
else
    echo -e "${RED}❌ GEMINI_API_KEY secret NIE JE nastavený${NC}"
    echo "   Spustite: firebase functions:secrets:set GEMINI_API_KEY"
    API_KEY_SET=false
fi

echo ""

# 3. Test: Volanie generateContent funkcie (ak je API kľúč nastavený)
if [ "$API_KEY_SET" = true ]; then
    echo "3️⃣  Test volania generateContent funkcie..."
    echo ""
    
    # Získanie auth tokenu (ak je používateľ prihlásený)
    AUTH_TOKEN=$(firebase auth:export --format json 2>/dev/null | jq -r '.users[0].customToken' 2>/dev/null || echo "")
    
    if [ -z "$AUTH_TOKEN" ]; then
        echo -e "${YELLOW}⚠️  Nie ste prihlásený do Firebase${NC}"
        echo "   Pre plný test sa prihláste: firebase login"
        echo ""
        echo "   Test bez autentifikácie (ak je povolené)..."
    fi
    
    # Test prompt
    TEST_PROMPT="Napíš krátku odpoveď: Čo je BizAgent?"
    
    echo "   Prompt: \"${TEST_PROMPT}\""
    echo "   Volanie funkcie..."
    echo ""
    
    # Vytvorenie test súboru pre curl
    TEST_DATA=$(cat <<EOF
{
  "data": {
    "prompt": "${TEST_PROMPT}",
    "model": "gemini-1.5-flash"
  }
}
EOF
)
    
    # Volanie Cloud Function cez curl
    RESPONSE=$(curl -s -X POST \
        "${FUNCTIONS_URL}/generateContent" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer ${AUTH_TOKEN:-anonymous}" \
        -d "${TEST_DATA}" \
        2>&1)
    
    if echo "$RESPONSE" | grep -q "text"; then
        echo -e "${GREEN}✅ Funkcia odpovedala úspešne!${NC}"
        echo ""
        echo "📝 Odpoveď:"
        echo "$RESPONSE" | jq -r '.result.text' 2>/dev/null || echo "$RESPONSE"
    elif echo "$RESPONSE" | grep -q "unauthenticated\|permission-denied"; then
        echo -e "${YELLOW}⚠️  Funkcia vyžaduje autentifikáciu${NC}"
        echo "   Odpoveď: $RESPONSE"
    elif echo "$RESPONSE" | grep -q "failed-precondition"; then
        echo -e "${RED}❌ API kľúč nie je správne nastavený${NC}"
        echo "   Odpoveď: $RESPONSE"
    else
        echo -e "${YELLOW}⚠️  Neočakávaná odpoveď${NC}"
        echo "   Odpoveď: $RESPONSE"
    fi
else
    echo "3️⃣  Preskočené (API kľúč nie je nastavený)"
fi

echo ""
echo "=============================================="
echo "✅ Test dokončený!"
echo ""
echo "📋 Ďalšie kroky:"
echo "   1. firebase functions:secrets:set GEMINI_API_KEY"
echo "   2. firebase deploy --only functions"
echo "   3. flutter build web --release"
echo "   4. git push (alebo vercel --prod)"
echo ""
