#!/bin/bash

# Spustenie Firebase Functions Emulator
# Tento skript zabezpečí, že porty sú voľné a emulator sa spustí správne

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

echo "🔥 Spúšťam Firebase Functions Emulator..."
echo ""

# Zastavenie existujúcich emulatorov
echo "1️⃣  Kontrola existujúcich emulatorov..."
if lsof -ti:5001 > /dev/null 2>&1; then
    echo "   Zastavujem existujúci emulator na porte 5001..."
    lsof -ti:5001 | xargs kill -9 2>/dev/null || true
    sleep 2
fi

if lsof -ti:4000 > /dev/null 2>&1; then
    echo "   Zastavujem existujúci UI na porte 4000..."
    lsof -ti:4000 | xargs kill -9 2>/dev/null || true
    sleep 1
fi

if lsof -ti:4400 > /dev/null 2>&1; then
    echo "   Zastavujem existujúci Hub na porte 4400..."
    lsof -ti:4400 | xargs kill -9 2>/dev/null || true
    sleep 1
fi

echo "   ✅ Porty sú voľné"
echo ""

# Kontrola závislostí
echo "2️⃣  Kontrola závislostí..."
cd functions
if [ ! -d "node_modules" ]; then
    echo "   Inštalujem závislosti..."
    npm install
fi
cd ..

echo ""

# Spustenie emulatora
echo "3️⃣  Spúšťam Firebase Functions Emulator..."
echo ""
echo "📋 Konfigurácia:"
echo "   • Functions: http://localhost:5001"
echo "   • UI: http://localhost:4000"
echo "   • Hub: http://localhost:4400"
echo ""
echo "🛑 Stlačte Ctrl+C pre zastavenie"
echo ""

firebase emulators:start --only functions
