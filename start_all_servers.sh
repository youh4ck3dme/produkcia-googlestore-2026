#!/bin/bash

# Spustenie všetkých serverov pre BizAgent
# 1. Flutter Web App
# 2. Firebase Functions Emulator (API)
# 3. Vercel Dev Server (pre API endpoints)

set -e

# Farba pre výstup
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🚀 Spúšťam všetky servery pre BizAgent..."
echo ""

# Získanie absolútnej cesty k projektu
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

# Funkcia na cleanup pri ukončení
cleanup() {
    echo ""
    echo "🛑 Zastavujem všetky servery..."
    kill $FLUTTER_PID $FIREBASE_PID $VERCEL_PID 2>/dev/null || true
    exit 0
}

trap cleanup SIGINT SIGTERM

# 1. Flutter Web App (Port 5050)
echo -e "${BLUE}1️⃣  Spúšťam Flutter Web App na porte 5050...${NC}"
flutter run -d chrome --web-port=5050 > /tmp/flutter_server.log 2>&1 &
FLUTTER_PID=$!
echo "   PID: $FLUTTER_PID"
echo "   URL: http://localhost:5050"
echo ""

# Počkaj chvíľu, kým sa Flutter spustí
sleep 3

# 2. Firebase Functions Emulator (Port 5001)
echo -e "${BLUE}2️⃣  Spúšťam Firebase Functions Emulator...${NC}"
cd functions
if [ ! -d "node_modules" ]; then
    echo "   Inštalujem závislosti..."
    npm install > /dev/null 2>&1
fi
firebase emulators:start --only functions > /tmp/firebase_functions.log 2>&1 &
FIREBASE_PID=$!
cd ..
echo "   PID: $FIREBASE_PID"
echo "   URL: http://localhost:5001"
echo "   Functions UI: http://localhost:4000"
echo ""

# Počkaj chvíľu, kým sa Firebase emulator spustí
sleep 5

# 3. Vercel Dev Server (pre API endpoints) - Port 3000
echo -e "${BLUE}3️⃣  Spúšťam Vercel Dev Server pre API...${NC}"
if command -v vercel &> /dev/null; then
    vercel dev --listen 3000 > /tmp/vercel_server.log 2>&1 &
    VERCEL_PID=$!
    echo "   PID: $VERCEL_PID"
    echo "   URL: http://localhost:3000"
    echo ""
else
    echo -e "${YELLOW}   ⚠️  Vercel CLI nie je nainštalované${NC}"
    echo "   Inštalácia: npm install -g vercel"
    echo "   Alebo použite: npx vercel dev --listen 3000"
    VERCEL_PID=""
fi

echo ""
echo -e "${GREEN}✅ Všetky servery sú spustené!${NC}"
echo ""
echo "📋 Prehľad:"
echo "   • Flutter Web App:    http://localhost:5050"
echo "   • Firebase Functions: http://localhost:5001"
if [ ! -z "$VERCEL_PID" ]; then
    echo "   • Vercel API Server:  http://localhost:3000"
fi
echo ""
echo "📊 Logy:"
echo "   • Flutter:    tail -f /tmp/flutter_server.log"
echo "   • Firebase:   tail -f /tmp/firebase_functions.log"
if [ ! -z "$VERCEL_PID" ]; then
    echo "   • Vercel:     tail -f /tmp/vercel_server.log"
fi
echo ""
echo "🛑 Stlačte Ctrl+C pre zastavenie všetkých serverov"
echo ""

# Počkaj, kým používateľ nestlačí Ctrl+C
wait
