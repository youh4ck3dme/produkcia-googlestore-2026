#!/bin/bash

# Zastavenie všetkých serverov

echo "🛑 Zastavujem všetky servery..."
echo ""

# Zastavenie podľa PID súborov
if [ -f /tmp/bizagent_flutter.pid ]; then
    FLUTTER_PID=$(cat /tmp/bizagent_flutter.pid)
    if ps -p $FLUTTER_PID > /dev/null 2>&1; then
        echo "   Zastavujem Flutter (PID: $FLUTTER_PID)..."
        kill $FLUTTER_PID 2>/dev/null || true
        rm /tmp/bizagent_flutter.pid
    fi
fi

if [ -f /tmp/bizagent_firebase.pid ]; then
    FIREBASE_PID=$(cat /tmp/bizagent_firebase.pid)
    if ps -p $FIREBASE_PID > /dev/null 2>&1; then
        echo "   Zastavujem Firebase Functions (PID: $FIREBASE_PID)..."
        kill $FIREBASE_PID 2>/dev/null || true
        rm /tmp/bizagent_firebase.pid
    fi
fi

if [ -f /tmp/bizagent_vercel.pid ]; then
    VERCEL_PID=$(cat /tmp/bizagent_vercel.pid)
    if ps -p $VERCEL_PID > /dev/null 2>&1; then
        echo "   Zastavujem Vercel (PID: $VERCEL_PID)..."
        kill $VERCEL_PID 2>/dev/null || true
        rm /tmp/bizagent_vercel.pid
    fi
fi

# Zastavenie podľa portov (fallback)
echo "   Kontrolujem porty..."

# Port 5000 (Flutter)
lsof -ti:5000 | xargs kill -9 2>/dev/null || true

# Port 5001 (Firebase Functions)
lsof -ti:5001 | xargs kill -9 2>/dev/null || true

# Port 3000 (Vercel)
lsof -ti:3000 | xargs kill -9 2>/dev/null || true

# Port 4000 (Firebase UI)
lsof -ti:4000 | xargs kill -9 2>/dev/null || true

echo ""
echo "✅ Všetky servery sú zastavené!"
