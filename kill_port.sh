#!/bin/bash
# Skript na uvoľnenie obsadeného portu
# Použitie: ./kill_port.sh [PORT]
# Príklad: ./kill_port.sh 3001

PORT=${1:-3001}

echo "🔍 Hľadanie procesu na porte $PORT..."

# macOS/Linux kompatibilné
PID=$(lsof -ti:$PORT 2>/dev/null | head -1)

if [ -z "$PID" ]; then
    echo "✅ Port $PORT nie je obsadený"
    exit 0
fi

echo "⚠️  Port $PORT je obsadený procesom PID: $PID"
echo ""
echo "Proces info:"
ps -p $PID -o pid,comm,args 2>/dev/null || echo "Proces už neexistuje"

echo ""
read -p "Chceš ukončiť tento proces? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    kill -9 $PID 2>/dev/null
    sleep 1
    
    # Overenie
    if lsof -ti:$PORT >/dev/null 2>&1; then
        echo "❌ Nepodarilo sa ukončiť proces"
        exit 1
    else
        echo "✅ Port $PORT je teraz voľný"
    fi
else
    echo "❌ Zrušené"
    exit 0
fi
