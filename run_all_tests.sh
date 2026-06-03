#!/bin/bash
# BizAgent — FULL unit/widget suite (nie CORE GATE)
#
# Čo robí:
#   - flutter test (celý adresár test/) — všetky unit/widget testy
#   - opätovne widget_test.dart (duplicitné oproti bodu vyššie)
#   - informácia o integration_test (nespúšťa ich)
#   - voliteľný coverage report
#   - flutter analyze (celý projekt, nie len lib)
#   - voliteľný debug APK build
#
# Kedy: pred release (spolu s verify_demo_account.sh a build_release_aab.sh),
#       alebo keď potrebuješ celé test/ + coverage.
# Pre commit/PR minimum používaj: ./run_core_tests.sh
#
# Spustenie: ./run_all_tests.sh

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "🧪 BizAgent — full test/ suite (NOT core gate)"
echo "=============================================="
echo -e "${YELLOW}ℹ️  Commit/PR minimum: ./run_core_tests.sh${NC}"
echo ""

# 1. Unit Tests (entire test/)
echo -e "${BLUE}1️⃣  flutter test test/ (full suite)${NC}"
echo "─────────────────────────────────"
if flutter test --dart-define=PLAY_MVP=false --no-pub 2>&1 | tee /tmp/flutter_test_output.txt | grep -q "All tests passed"; then
    UNIT_PASSED=$(grep -o "[0-9]* passed" /tmp/flutter_test_output.txt | head -1)
    echo -e "${GREEN}✅ Full test/ suite passed: $UNIT_PASSED${NC}"
else
    UNIT_FAILED=$(grep -o "[0-9]* failed" /tmp/flutter_test_output.txt | head -1 || echo "Some")
    echo -e "${RED}❌ test/ failed: $UNIT_FAILED${NC}"
    echo "Zobrazujem chyby:"
    grep -A 5 "FAILED\|Error\|Exception" /tmp/flutter_test_output.txt | head -30
    exit 1
fi
echo ""

# 2. Widget Tests (redundant check — kept for visibility)
echo -e "${BLUE}2️⃣  widget_test.dart (explicit)${NC}"
echo "─────────────────────────────────"
if flutter test --dart-define=PLAY_MVP=false test/widget_test.dart --no-pub 2>&1 | tee /tmp/widget_test_output.txt | grep -q "All tests passed"; then
    echo -e "${GREEN}✅ widget_test.dart passed${NC}"
else
    echo -e "${YELLOW}⚠️  widget_test.dart issues (see output)${NC}"
fi
echo ""

# 3. Integration Tests (device only — not run here)
echo -e "${BLUE}3️⃣  integration_test/ (manual)${NC}"
echo "─────────────────────────────────"
if [ -d "integration_test" ] && [ "$(ls -A integration_test/*.dart 2>/dev/null)" ]; then
    echo "Nájdené integration testy:"
    ls -1 integration_test/*.dart
    echo ""
    echo -e "${YELLOW}ℹ️  Vyžadujú zariadenie/emulátor — nespúšťané týmto skriptom.${NC}"
    echo "   flutter test integration_test/"
else
    echo -e "${YELLOW}⚠️  integration_test/ prázdny alebo chýba${NC}"
fi
echo ""

# 4. Code Coverage (optional)
echo -e "${BLUE}4️⃣  Coverage (voliteľné)${NC}"
echo "─────────────────────────────────"
if flutter test --dart-define=PLAY_MVP=false --coverage --no-pub 2>&1 | grep -q "All tests passed"; then
    echo -e "${GREEN}✅ Coverage report generated${NC}"
    if command -v genhtml &> /dev/null; then
        genhtml coverage/lcov.info -o coverage/html 2>/dev/null && \
        echo -e "${GREEN}✅ HTML report: coverage/html/index.html${NC}"
    else
        echo -e "${YELLOW}⚠️  genhtml nie je nainštalovaný (lcov)${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Coverage generation failed${NC}"
fi
echo ""

# 5. Analyze (whole project)
echo -e "${BLUE}5️⃣  flutter analyze (project-wide)${NC}"
echo "─────────────────────────────────"
if flutter analyze --no-pub 2>&1 | tee /tmp/analyze_output.txt | grep -q "No issues found"; then
    echo -e "${GREEN}✅ No analyzer issues${NC}"
else
    ISSUES=$(grep -c "issue" /tmp/analyze_output.txt || echo "0")
    echo -e "${YELLOW}⚠️  Analyzer reported issues (count ~$ISSUES)${NC}"
    grep "issue\|error\|warning" /tmp/analyze_output.txt | head -10
fi
echo ""

# 6. Debug APK (optional sanity build)
echo -e "${BLUE}6️⃣  Debug APK build (voliteľné)${NC}"
echo "─────────────────────────────────"
if flutter build apk --debug --no-pub 2>&1 | tee /tmp/build_output.txt | grep -q "Built.*apk"; then
    echo -e "${GREEN}✅ Android debug build OK${NC}"
else
    echo -e "${YELLOW}⚠️  Debug build skipped or failed (SDK?)${NC}"
fi
echo ""

echo "========================================"
echo -e "${BLUE}📊 Summary${NC}"
echo "========================================"
echo -e "${GREEN}✅ flutter test test/ — passed${NC}"
echo -e "${YELLOW}⚠️  integration_test — manual only${NC}"
echo ""
echo "Release gate (Play): flutter test + ./verify_demo_account.sh + ./build_release_aab.sh"
echo "Integration: flutter test integration_test/"
