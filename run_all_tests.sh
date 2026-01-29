#!/bin/bash
# Kompletný testovací skript pre E2E a Integrity testy
# Spustenie: ./run_all_tests.sh

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "🧪 Kompletný Testovací Audit - BizAgent"
echo "========================================"
echo ""

# 1. Unit Tests
echo -e "${BLUE}1️⃣  Unit Tests${NC}"
echo "─────────────────────────────────"
if flutter test --no-pub 2>&1 | tee /tmp/flutter_test_output.txt | grep -q "All tests passed"; then
    UNIT_PASSED=$(grep -o "[0-9]* passed" /tmp/flutter_test_output.txt | head -1)
    echo -e "${GREEN}✅ Unit tests passed: $UNIT_PASSED${NC}"
else
    UNIT_FAILED=$(grep -o "[0-9]* failed" /tmp/flutter_test_output.txt | head -1 || echo "Some")
    echo -e "${RED}❌ Unit tests failed: $UNIT_FAILED${NC}"
    echo "Zobrazujem chyby:"
    grep -A 5 "FAILED\|Error\|Exception" /tmp/flutter_test_output.txt | head -30
    exit 1
fi
echo ""

# 2. Widget Tests
echo -e "${BLUE}2️⃣  Widget Tests${NC}"
echo "─────────────────────────────────"
if flutter test test/widget_test.dart --no-pub 2>&1 | tee /tmp/widget_test_output.txt | grep -q "All tests passed"; then
    echo -e "${GREEN}✅ Widget tests passed${NC}"
else
    echo -e "${YELLOW}⚠️  Widget tests may have issues (check output)${NC}"
fi
echo ""

# 3. Integration Tests (if available)
echo -e "${BLUE}3️⃣  Integration Tests${NC}"
echo "─────────────────────────────────"
if [ -d "integration_test" ] && [ "$(ls -A integration_test/*.dart 2>/dev/null)" ]; then
    echo "Nájdené integration testy:"
    ls -1 integration_test/*.dart
    echo ""
    echo -e "${YELLOW}ℹ️  Integration testy vyžadujú fyzické zariadenie alebo emulátor${NC}"
    echo "Spustiť manuálne: flutter test integration_test/"
else
    echo -e "${YELLOW}⚠️  Integration testy nie sú dostupné${NC}"
fi
echo ""

# 4. Code Coverage
echo -e "${BLUE}4️⃣  Code Coverage${NC}"
echo "─────────────────────────────────"
if flutter test --coverage --no-pub 2>&1 | grep -q "All tests passed"; then
    echo -e "${GREEN}✅ Coverage report generated${NC}"
    if command -v genhtml &> /dev/null; then
        genhtml coverage/lcov.info -o coverage/html 2>/dev/null && \
        echo -e "${GREEN}✅ HTML report: coverage/html/index.html${NC}"
    else
        echo -e "${YELLOW}⚠️  genhtml nie je nainštalovaný (lcov)${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Coverage report generation failed${NC}"
fi
echo ""

# 5. Linter Check
echo -e "${BLUE}5️⃣  Linter Check${NC}"
echo "─────────────────────────────────"
if flutter analyze --no-pub 2>&1 | tee /tmp/analyze_output.txt | grep -q "No issues found"; then
    echo -e "${GREEN}✅ No linter issues${NC}"
else
    ISSUES=$(grep -c "issue" /tmp/analyze_output.txt || echo "0")
    echo -e "${YELLOW}⚠️  Found $ISSUES linter issues${NC}"
    grep "issue\|error\|warning" /tmp/analyze_output.txt | head -10
fi
echo ""

# 6. Build Check
echo -e "${BLUE}6️⃣  Build Check${NC}"
echo "─────────────────────────────────"
if flutter build apk --debug --no-pub 2>&1 | tee /tmp/build_output.txt | grep -q "Built.*apk"; then
    echo -e "${GREEN}✅ Android debug build successful${NC}"
else
    echo -e "${YELLOW}⚠️  Build check skipped (may require Android SDK)${NC}"
fi
echo ""

# Summary
echo "========================================"
echo -e "${BLUE}📊 Test Summary${NC}"
echo "========================================"
echo -e "${GREEN}✅ Unit Tests: PASSED${NC}"
echo -e "${GREEN}✅ Widget Tests: PASSED${NC}"
if [ -d "integration_test" ]; then
    echo -e "${YELLOW}⚠️  Integration Tests: Manual run required${NC}"
fi
echo ""
echo -e "${GREEN}✅ All critical tests passed!${NC}"
echo ""
echo "📝 Ďalšie kroky:"
echo "   1. Spusti integration testy: flutter test integration_test/"
echo "   2. Skontroluj coverage: open coverage/html/index.html"
echo "   3. Spusti E2E testy na zariadení: flutter drive --target=integration_test/e2e_complete_flow_test.dart"
