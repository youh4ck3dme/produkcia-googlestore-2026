#!/bin/bash
# Komplexný testovací skript pre všetky funkcie BizAgent
# Spustenie: ./comprehensive_test.sh

set +e
PROJECT_ID="bizagent-live-2026"
DEMO_EMAIL="bizbizagent@bizbizagent.com"

echo "🧪 BizAgent Comprehensive Test Suite"
echo "===================================="
echo ""

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASSED=0
FAILED=0
WARNINGS=0

test_pass() { echo -e "${GREEN}✅ PASS:${NC} $1"; ((PASSED++)); }
test_fail() { echo -e "${RED}❌ FAIL:${NC} $1"; ((FAILED++)); }
test_warn() { echo -e "${YELLOW}⚠️  WARN:${NC} $1"; ((WARNINGS++)); }
test_info() { echo -e "${BLUE}ℹ️  INFO:${NC} $1"; }

# 1. ZÁKLADNÉ FUNKCIE
echo -e "${BLUE}1. ZÁKLADNÉ FUNKCIE${NC}"
echo "─────────────────────────────────"

# Faktúry
echo ""
echo "📄 Faktúry:"
if [ -f "lib/features/invoices/models/invoice_model.dart" ]; then
    test_pass "Invoice model exists"
else
    test_fail "Invoice model missing"
fi

if [ -f "lib/features/invoices/providers/invoices_repository.dart" ]; then
    test_pass "Invoices repository exists"
else
    test_fail "Invoices repository missing"
fi

if grep -q "collection('invoices')" lib/features/invoices/providers/invoices_repository.dart 2>/dev/null; then
    test_pass "Invoices Firestore integration"
else
    test_fail "Invoices Firestore integration missing"
fi

# Výdavky
echo ""
echo "💰 Výdavky:"
if [ -f "lib/features/expenses/models/expense_model.dart" ]; then
    test_pass "Expense model exists"
else
    test_fail "Expense model missing"
fi

if [ -f "lib/features/expenses/providers/expenses_repository.dart" ]; then
    test_pass "Expenses repository exists"
else
    test_fail "Expenses repository missing"
fi

if grep -q "collection('expenses')" lib/features/expenses/providers/expenses_repository.dart 2>/dev/null; then
    test_pass "Expenses Firestore integration"
else
    test_fail "Expenses Firestore integration missing"
fi

# OCR Skenovanie
echo ""
echo "📷 OCR Skenovanie:"
if [ -f "lib/core/services/ocr_service.dart" ]; then
    test_pass "OCR service exists"
else
    test_fail "OCR service missing"
fi

if grep -q "google_mlkit_text_recognition" pubspec.yaml; then
    test_pass "ML Kit dependency configured"
else
    test_fail "ML Kit dependency missing"
fi

if grep -q "scanReceipt\|parseReceipt" lib/core/services/ocr_service.dart 2>/dev/null; then
    test_pass "OCR receipt scanning implemented"
else
    test_fail "OCR receipt scanning not implemented"
fi

# Daňový Teplomer
echo ""
echo "🌡️  Daňový Teplomer:"
if [ -f "lib/features/tax/providers/tax_thermometer_service.dart" ]; then
    test_pass "Tax thermometer service exists"
else
    test_fail "Tax thermometer service missing"
fi

if grep -q "vatRegistrationThreshold\|49790" lib/features/tax/providers/tax_thermometer_service.dart 2>/dev/null; then
    test_pass "VAT threshold configured (49,790 €)"
else
    test_warn "VAT threshold not found"
fi

# 2. FIREBASE INTEGRÁCIA
echo ""
echo -e "${BLUE}2. FIREBASE INTEGRÁCIA${NC}"
echo "─────────────────────────────────"

# Auth
echo ""
echo "🔐 Firebase Auth:"
if grep -q "firebase_auth" pubspec.yaml; then
    test_pass "Firebase Auth dependency"
else
    test_fail "Firebase Auth dependency missing"
fi

if [ -f "lib/firebase_options.dart" ]; then
    test_pass "Firebase options configured"
else
    test_fail "Firebase options missing"
fi

# Firestore
echo ""
echo "💾 Firestore:"
if grep -q "cloud_firestore" pubspec.yaml; then
    test_pass "Firestore dependency"
else
    test_fail "Firestore dependency missing"
fi

if [ -f "firestore.rules" ] || [ -f "firebase/firestore.rules" ]; then
    test_pass "Firestore security rules exist"
else
    test_fail "Firestore security rules missing"
fi

# Storage
echo ""
echo "📦 Firebase Storage:"
if grep -q "firebase_storage" pubspec.yaml; then
    test_pass "Firebase Storage dependency"
else
    test_fail "Firebase Storage dependency missing"
fi

if [ -f "storage.rules" ] || [ -f "firebase/storage.rules" ]; then
    test_pass "Storage security rules exist"
else
    test_fail "Storage security rules missing"
fi

# Analytics
echo ""
echo "📊 Analytics:"
if grep -q "firebase_analytics" pubspec.yaml; then
    test_pass "Firebase Analytics dependency"
else
    test_fail "Firebase Analytics dependency missing"
fi

if [ -f "lib/core/services/analytics_service.dart" ]; then
    test_pass "Analytics service exists"
else
    test_fail "Analytics service missing"
fi

# Crashlytics
echo ""
echo "🐛 Crashlytics:"
if grep -q "firebase_crashlytics" pubspec.yaml; then
    test_pass "Crashlytics dependency"
else
    test_warn "Crashlytics dependency missing (optional)"
fi

# 3. DOKUMENTÁCIA
echo ""
echo -e "${BLUE}3. DOKUMENTÁCIA${NC}"
echo "─────────────────────────────────"

DOC_COUNT=$(find docs -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
if [ "$DOC_COUNT" -ge 9 ]; then
    test_pass "Documentation files: $DOC_COUNT (>= 9)"
else
    test_warn "Documentation files: $DOC_COUNT (< 9 expected)"
fi

# Kľúčové dokumenty
KEY_DOCS=(
    "docs/GOOGLE_PLAY_SUBMISSION.md"
    "docs/RELEASE_CHECKLIST.md"
    "docs/PRODUCTION_API_TEST.md"
    "docs/DEMO_ACCOUNT_SETUP.md"
    "docs/ARCHITECTURE.md"
    "docs/SETUP.md"
    "docs/DEPLOYMENT.md"
    "docs/SECURITY.md"
    "docs/TESTING.md"
)

for doc in "${KEY_DOCS[@]}"; do
    if [ -f "$doc" ]; then
        test_pass "$(basename $doc)"
    else
        test_warn "$(basename $doc) missing"
    fi
done

# 4. ANDROID BUILD
echo ""
echo -e "${BLUE}4. ANDROID BUILD${NC}"
echo "─────────────────────────────────"

if [ -d "android" ]; then
    test_pass "Android directory exists"
else
    test_fail "Android directory missing"
fi

if [ -f "android/app/build.gradle" ] || [ -f "android/app/build.gradle.kts" ]; then
    test_pass "Android build.gradle exists"
else
    test_fail "Android build.gradle missing"
fi

if [ -f "build/app/outputs/bundle/release/app-release.aab" ]; then
    AAB_SIZE=$(du -h build/app/outputs/bundle/release/app-release.aab 2>/dev/null | cut -f1)
    test_pass "AAB file exists ($AAB_SIZE)"
else
    test_warn "AAB file not found (run: flutter build appbundle --release)"
fi

# 5. WEB PWA
echo ""
echo -e "${BLUE}5. WEB PWA${NC}"
echo "─────────────────────────────────"

if [ -d "web" ]; then
    test_pass "Web directory exists"
else
    test_fail "Web directory missing"
fi

if [ -f "web/index.html" ]; then
    test_pass "Web index.html exists"
else
    test_fail "Web index.html missing"
fi

if [ -f "web/manifest.json" ]; then
    test_pass "PWA manifest.json exists"
else
    test_fail "PWA manifest.json missing"
fi

if [ -d "build/web" ]; then
    WEB_SIZE=$(du -sh build/web 2>/dev/null | cut -f1)
    test_pass "Web build directory exists ($WEB_SIZE)"
else
    test_warn "Web build directory not found (run: flutter build web --release)"
fi

# Summary
echo ""
echo "===================================="
echo "📊 TEST SUMMARY"
echo "===================================="
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo -e "${YELLOW}Warnings: $WARNINGS${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ All critical tests passed!${NC}"
    exit 0
else
    echo -e "${RED}❌ Some tests failed. Please fix issues above.${NC}"
    exit 1
fi
