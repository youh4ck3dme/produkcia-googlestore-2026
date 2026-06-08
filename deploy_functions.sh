#!/bin/bash

# Kompletný príkaz na kontrolu a deploy Firebase Functions
# Použitie: ./deploy_functions.sh

set -e

echo "🔍 Kontrola .env súboru..."
if [ -f "functions/.env" ]; then
    echo "✅ .env existuje"
    echo "📋 Premenné v .env:"
    grep -E "^[A-Z_]+=" functions/.env | sed 's/=.*/=***/' || true
else
    echo "❌ .env súbor neexistuje!"
    exit 1
fi

echo ""
echo "🔨 Build TypeScript funkcií..."
cd functions
npm install --no-fund
npm run build
cd ..

echo ""
echo "☁️  Deploy Firebase Functions..."
PROJECT="${FIREBASE_PROJECT:-bizagent-pro-2026}"
echo "   Projekt: $PROJECT (Blaze / platený)"
firebase use "$PROJECT"

firebase deploy --only functions --project "$PROJECT"

echo ""
echo "✅ Hotovo! Functions nasadené na $PROJECT"
echo "   URL: https://us-central1-${PROJECT}.cloudfunctions.net/generateContent"
