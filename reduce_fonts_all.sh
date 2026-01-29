#!/bin/bash
# Skript na zmenšenie všetkých fontov o 20% v celom projekte
# Spustenie: ./reduce_fonts_all.sh

echo "🔍 Hľadanie všetkých hardcodovaných fontov..."
echo ""

# Nájdi všetky súbory s fontSize
FILES=$(grep -r "fontSize:" lib/ --include="*.dart" | grep -v "// Reduced by 20%" | cut -d: -f1 | sort -u)

echo "📋 Nájdené súbory s hardcodovanými fontmi:"
echo "$FILES" | head -20
echo ""

echo "⚠️  Poznámka: Hlavné fonty sú už zmenšené v biz_theme.dart"
echo "   Tento skript nájde ďalšie hardcodované fonty, ktoré treba manuálne upraviť"
echo ""
echo "📝 Pre manuálnu úpravu použite:"
echo "   - Nájdite fontSize: XX"
echo "   - Zmeňte na fontSize: XX * 0.8"
echo ""
