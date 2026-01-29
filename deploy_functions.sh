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
npm install
npm run build
cd ..

echo ""
echo "☁️  Deploy Firebase Functions..."
# Firebase Functions v2 s defineString vyžaduje .env súbor počas deployu
# Secrets sa použijú automaticky v produkcii, .env je len pre build proces
firebase deploy --only functions

echo ""
echo "✅ Hotovo! Funkcie sú nasadené."
