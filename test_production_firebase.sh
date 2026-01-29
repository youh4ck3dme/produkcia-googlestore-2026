#!/bin/bash
# Komplexný testovací skript pre Firebase produkčné API
# Spustenie: ./test_production_firebase.sh

# Don't exit on error - we want to run all tests
set +e

PROJECT_ID="bizagent-live-2026"
DEMO_EMAIL="bizbizagent@bizbizagent.com"
DEMO_PASSWORD="1369#1369#1369#"

echo "🧪 BizAgent Production Firebase Test Suite"
echo "=========================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PASSED=0
FAILED=0
WARNINGS=0

test_pass() {
    echo -e "${GREEN}✅ PASS:${NC} $1"
    ((PASSED++))
}

test_fail() {
    echo -e "${RED}❌ FAIL:${NC} $1"
    ((FAILED++))
}

test_warn() {
    echo -e "${YELLOW}⚠️  WARN:${NC} $1"
    ((WARNINGS++))
}

# 1. Firebase CLI Check
echo "📋 Test 1: Firebase CLI"
if command -v firebase &> /dev/null; then
    FIREBASE_VERSION=$(firebase --version)
    test_pass "Firebase CLI installed ($FIREBASE_VERSION)"
else
    test_fail "Firebase CLI not installed. Install: npm install -g firebase-tools"
    exit 1
fi

# 2. Firebase Login Check
echo ""
echo "📋 Test 2: Firebase Authentication"
if firebase projects:list > /dev/null 2>&1; then
    test_pass "Logged into Firebase"
else
    test_fail "Not logged in. Run: firebase login"
    exit 1
fi

# 3. Project Selection
echo ""
echo "📋 Test 3: Firebase Project"
CURRENT_PROJECT=$(firebase use 2>&1 | grep "Using" | awk '{print $2}' || echo "")
if [ "$CURRENT_PROJECT" == "$PROJECT_ID" ]; then
    test_pass "Using project: $PROJECT_ID"
else
    test_warn "Project not set. Setting to $PROJECT_ID..."
    firebase use $PROJECT_ID || test_fail "Failed to set project"
fi

# 4. Firestore Rules Check
echo ""
echo "📋 Test 4: Firestore Security Rules"
if [ -f "firebase/firestore.rules" ]; then
    if grep -q "isAuthenticated()" firebase/firestore.rules && \
       grep -q "match /invoices/" firebase/firestore.rules && \
       grep -q "match /expenses/" firebase/firestore.rules; then
        test_pass "Firestore rules file exists and contains required rules"
    else
        test_fail "Firestore rules missing required patterns"
    fi
else
    test_fail "firebase/firestore.rules not found"
fi

# 5. Storage Rules Check
echo ""
echo "📋 Test 5: Storage Security Rules"
if [ -f "firebase/storage.rules" ]; then
    if grep -q "request.auth" firebase/storage.rules; then
        test_pass "Storage rules file exists and requires authentication"
    else
        test_fail "Storage rules missing authentication check"
    fi
else
    test_fail "firebase/storage.rules not found"
fi

# 6. Cloud Functions Check
echo ""
echo "📋 Test 6: Cloud Functions"
if [ -f "functions/index.js" ]; then
    FUNCTIONS=("generateEmail" "analyzeReceipt" "lookupCompany")
    ALL_FUNCTIONS_EXIST=true
    
    for func in "${FUNCTIONS[@]}"; do
        if grep -q "exports.$func" functions/index.js; then
            test_pass "Function '$func' exists"
        else
            test_fail "Function '$func' not found"
            ALL_FUNCTIONS_EXIST=false
        fi
    done
    
    # Check for API keys (should be in secrets)
    if grep -q "GEMINI_API_KEY\|ICOATLAS_API_KEY" functions/index.js; then
        test_pass "Functions reference API keys (should be in secrets)"
    else
        test_warn "API keys not found in functions (may be using secrets)"
    fi
else
    test_fail "functions/index.js not found"
fi

# 7. Firebase Configuration Files
echo ""
echo "📋 Test 7: Firebase Configuration"
if [ -f "lib/firebase_options.dart" ]; then
    if grep -q "bizagent-live-2026" lib/firebase_options.dart; then
        test_pass "firebase_options.dart contains correct project ID"
    else
        test_fail "firebase_options.dart has wrong project ID"
    fi
else
    test_fail "lib/firebase_options.dart not found"
fi

# 8. Check if functions are deployed
echo ""
echo "📋 Test 8: Cloud Functions Deployment Status"
if firebase functions:list > /dev/null 2>&1; then
    DEPLOYED_FUNCTIONS=$(firebase functions:list 2>/dev/null | grep -E "(generateEmail|analyzeReceipt|lookupCompany)" || echo "")
    if [ -n "$DEPLOYED_FUNCTIONS" ]; then
        test_pass "Cloud Functions are deployed"
        echo "   Deployed: $DEPLOYED_FUNCTIONS"
    else
        test_warn "Cloud Functions may not be deployed. Run: firebase deploy --only functions"
    fi
else
    test_warn "Cannot check deployed functions (may require Blaze plan or not deployed yet)"
fi

# 9. Firestore Indexes
echo ""
echo "📋 Test 9: Firestore Indexes"
if [ -f "firestore.indexes.json" ]; then
    test_pass "firestore.indexes.json exists"
else
    test_warn "firestore.indexes.json not found (may not be needed)"
fi

# 10. Demo Account Check (Manual)
echo ""
echo "📋 Test 10: Demo Account Verification"
test_warn "Manual check required:"
echo "   1. Go to Firebase Console > Authentication > Users"
echo "   2. Verify user exists: $DEMO_EMAIL"
echo "   3. Verify provider is 'Email/Password' (not Google)"
echo "   4. Test login with: email=$DEMO_EMAIL, password=$DEMO_PASSWORD"
echo ""
echo "   💡 Tip: Run './create_demo_account.sh' to create the account automatically"

# 11. API Keys Check (Secrets)
echo ""
echo "📋 Test 11: API Keys (Secrets)"
if firebase functions:secrets:access GEMINI_API_KEY &> /dev/null 2>&1; then
    test_pass "GEMINI_API_KEY secret exists"
else
    test_warn "GEMINI_API_KEY secret not set. Run: firebase functions:secrets:set GEMINI_API_KEY"
fi

if firebase functions:secrets:access ICOATLAS_API_KEY &> /dev/null 2>&1; then
    test_pass "ICOATLAS_API_KEY secret exists"
else
    test_warn "ICOATLAS_API_KEY secret not set (optional, uses mock data if missing)"
fi

# Summary
echo ""
echo "=========================================="
echo "📊 TEST SUMMARY"
echo "=========================================="
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
