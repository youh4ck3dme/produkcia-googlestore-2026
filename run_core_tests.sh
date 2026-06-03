#!/bin/bash
# BizAgent — CORE GATE (commit / PR minimum)
#
# Čo robí:
#   1. dart analyze lib
#   2. flutter test — jadro: core, auth, invoices, expenses, billing
#
# Kedy: pred každým commitom a v CI pre PR.
# Nie je to: celý test/, integration_test, Firebase shell testy, release AAB.
#
# Spustenie: ./run_core_tests.sh

set -e

cd "$(dirname "$0")"

if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Spúšťaj z root adresára projektu (pubspec.yaml chýba)."
    exit 1
fi

echo "🔒 BizAgent CORE GATE"
echo "====================="
echo ""

echo "1/2 dart analyze lib"
dart analyze lib
echo ""

echo "2/2 flutter test (core + auth + invoices + expenses + billing)"
flutter test --dart-define=PLAY_MVP=false \
    test/core \
    test/features/auth \
    test/features/invoices \
    test/features/expenses \
    test/features/billing

echo ""
echo "✅ CORE GATE passed"
