#!/bin/bash
# Skript na inštaláciu PDF extension pre Cursor/VSCode
# Spustenie: ./install_pdf_extension.sh

echo "📄 Inštalácia PDF Extension pre Cursor"
echo "======================================"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if Cursor command exists
if command -v cursor &> /dev/null; then
    CMD="cursor"
    echo -e "${GREEN}✅${NC} Cursor CLI found"
elif command -v code &> /dev/null; then
    CMD="code"
    echo -e "${GREEN}✅${NC} VSCode CLI found (using as fallback)"
else
    echo -e "${YELLOW}⚠️${NC}  Cursor/VSCode CLI not found"
    echo ""
    echo "Manuálna inštalácia:"
    echo "1. Otvor Cursor"
    echo "2. Stlač Cmd+Shift+X (Extensions)"
    echo "3. Vyhľadaj: 'PDF'"
    echo "4. Nainštaluj: 'PDF' by Mathematic Inc"
    exit 1
fi

echo ""
echo "📦 Dostupné PDF Extensions:"
echo ""
echo "1. ${BLUE}PDF${NC} by Mathematic Inc (odporúčané)"
echo "   - Najpopulárnejšia (2.17M+ installs)"
echo "   - 5 hviezdičiek"
echo "   - Používa pdf.js"
echo ""
echo "2. ${BLUE}Modern PDF Preview (WASM)${NC}"
echo "   - Vysoký výkon"
echo "   - Anotácie (highlighting, notes)"
echo "   - WebAssembly powered"
echo ""
echo "3. ${BLUE}Cursor AI PDF/DOCX Reader${NC}"
echo "   - Špeciálne pre Cursor"
echo "   - AI integrácia"
echo ""

# Install recommended extension
echo "🔧 Inštalujem PDF extension (Mathematic Inc)..."
echo ""

if $CMD --install-extension mathematic.vscode-pdf --force 2>&1 | grep -q "successfully installed\|already installed"; then
    echo -e "${GREEN}✅${NC} PDF extension úspešne nainštalovaná!"
    echo ""
    echo "📝 Ďalšie kroky:"
    echo "   1. Reštartuj Cursor (Cmd+Q a znova otvor)"
    echo "   2. Otvor PDF súbor: bizagentvssumuop.pdf"
    echo "   3. PDF by sa mal automaticky zobraziť v preview móde"
else
    echo -e "${YELLOW}⚠️${NC}  Inštalácia cez CLI zlyhala"
    echo ""
    echo "Manuálna inštalácia:"
    echo "1. Otvor Cursor"
    echo "2. Stlač ${BLUE}Cmd+Shift+X${NC} (Extensions)"
    echo "3. Vyhľadaj: ${BLUE}PDF${NC}"
    echo "4. Nainštaluj: ${BLUE}PDF${NC} by Mathematic Inc"
    echo ""
    echo "Alebo použij tento link:"
    echo "https://marketplace.visualstudio.com/items?itemName=mathematic.vscode-pdf"
fi

echo ""
echo "✨ Hotovo!"
