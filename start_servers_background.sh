#!/bin/bash

# Spustenie všetkých serverov v pozadí (background)
# Vhodné pre vývoj, kde chcete mať servery bežať na pozadí

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

echo "🚀 Spúšťam servery v pozadí..."
echo ""

# 1. Flutter Web App
echo "1️⃣  Flutter Web App (port 5000)..."
nohup flutter run -d chrome --web-port=5000 > /tmp/flutter_server.log 2>&1 &
FLUTTER_PID=$!
echo "   PID: $FLUTTER_PID"
echo "   Log: tail -f /tmp/flutter_server.log"
echo ""

# 2. Firebase Functions Emulator
echo "2️⃣  Firebase Functions Emulator..."
# Zastavíme existujúce procesy na portoch
lsof -ti:5001 | xargs kill -9 2>/dev/null || true
lsof -ti:4000 | xargs kill -9 2>/dev/null || true
lsof -ti:4400 | xargs kill -9 2>/dev/null || true
sleep 1

cd functions
if [ ! -d "node_modules" ]; then
    echo "   Inštalujem závislosti..."
    npm install > /dev/null 2>&1
fi
cd ..
nohup firebase emulators:start --only functions > /tmp/firebase_functions.log 2>&1 &
FIREBASE_PID=$!
echo "   PID: $FIREBASE_PID"
echo "   Log: tail -f /tmp/firebase_functions.log"
echo "   UI: http://localhost:4000"
echo ""

# 3. Vercel Dev Server (ak je nainštalované)
if command -v vercel &> /dev/null; then
    echo "3️⃣  Vercel Dev Server (port 3000)..."
    nohup vercel dev --listen 3000 > /tmp/vercel_server.log 2>&1 &
    VERCEL_PID=$!
    echo "   PID: $VERCEL_PID"
    echo "   Log: tail -f /tmp/vercel_server.log"
    echo ""
else
    echo "3️⃣  Vercel Dev Server - preskočené (nie je nainštalované)"
    echo ""
fi

# Uloženie PID do súboru pre ľahké zastavenie
echo "$FLUTTER_PID" > /tmp/bizagent_flutter.pid
echo "$FIREBASE_PID" > /tmp/bizagent_firebase.pid
if [ ! -z "$VERCEL_PID" ]; then
    echo "$VERCEL_PID" > /tmp/bizagent_vercel.pid
fi

echo "✅ Servery sú spustené v pozadí!"
echo ""
echo "📋 Prehľad:"
echo "   • Flutter Web App:    http://localhost:5000"
echo "   • Firebase Functions: http://localhost:5001"
if [ ! -z "$VERCEL_PID" ]; then
    echo "   • Vercel API Server:  http://localhost:3000"
fi
echo ""
echo "🛑 Zastavenie: ./stop_all_servers.sh"
echo ""
