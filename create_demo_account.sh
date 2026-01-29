#!/bin/bash
# Skript na vytvorenie demo účtu v Firebase Authentication
# Spustenie: ./create_demo_account.sh

set -e

PROJECT_ID="bizagent-live-2026"
DEMO_EMAIL="bizbizagent@bizbizagent.com"
DEMO_PASSWORD="1369#1369#1369#"

echo "🔐 Vytváranie demo účtu v Firebase"
echo "=================================="
echo ""
echo "Email: $DEMO_EMAIL"
echo "Password: $DEMO_PASSWORD"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo -e "${RED}❌ Firebase CLI not found. Install: npm install -g firebase-tools${NC}"
    exit 1
fi

# Check if logged in
if ! firebase projects:list > /dev/null 2>&1; then
    echo -e "${RED}❌ Not logged into Firebase. Run: firebase login${NC}"
    exit 1
fi

# Set project
echo "📋 Setting Firebase project to $PROJECT_ID..."
firebase use $PROJECT_ID > /dev/null 2>&1 || {
    echo -e "${RED}❌ Failed to set project${NC}"
    exit 1
}

echo ""
echo "⚠️  MANUÁLNY KROK POTREBNÝ:"
echo ""
echo "Firebase CLI nepodporuje priame vytváranie používateľov cez CLI."
echo "Musíš vytvoriť účet manuálne v Firebase Console:"
echo ""
echo "1. Otvor: https://console.firebase.google.com/project/$PROJECT_ID/authentication/users"
echo ""
echo "2. Klikni na 'Add User' (alebo 'Pridať používateľa')"
echo ""
echo "3. Vyplň:"
echo "   - Email: ${GREEN}$DEMO_EMAIL${NC}"
echo "   - Password: ${GREEN}$DEMO_PASSWORD${NC}"
echo "   - Disable: 'Send email verification' (voliteľné)"
echo ""
echo "4. Klikni 'Add User'"
echo ""
echo "5. Over, že v stĺpci 'Provider' vidíš ikonu obálky (Email), nie G (Google)"
echo ""
echo "✅ Hotovo! Účet je pripravený na použitie."
echo ""
echo "📝 Testovanie:"
echo "   - Skús sa prihlásiť v aplikácii s týmito údajmi"
echo "   - Alebo použij Firebase Console > Authentication > Users > Test User"
echo ""

# Alternative: Use Firebase Admin SDK if available
echo ""
echo "💡 ALTERNATÍVA: Použiť Node.js skript (ak máš Firebase Admin SDK)"
echo "   Spusti: node create_demo_account.js"
echo ""
