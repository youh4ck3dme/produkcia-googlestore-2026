# Testing Guide - BizAgent

## Test Philosophy

BizAgent používa **pyramídový test model**:
- **70% Unit tests** - Business logic (services, utils)
- **20% Widget tests** - UI components
- **10% Integration tests** - End-to-end flows

## Test Structure

```
test/
├── core/
│   ├── router/
│   │   └── router_paths_smoke_test.dart       # Router path validation
│   ├── services/
│   │   ├── invoice_numbering_service_test.dart  # Business logic
│   │   ├── qr_payment_service_test.dart
│   │   └── tax_calculation_service_test.dart    # VAT calculations
│   └── utils/
│       └── csv_test.dart                         # CSV escaping
│
├── features/
│   ├── dashboard/
│   │   ├── dashboard_first_run_banner_test.dart  # Empty state UI
│   │   └── dashboard_quick_actions_test.dart     # Quick actions tiles
│   ├── bank_import/
│   │   ├── bank_csv_parser_service_test.dart
│   │   └── bank_match_service_test.dart
│   └── export/
│       └── export_auth_guard_test.dart           # Auth protection
│
├── helpers/
│   └── test_app.dart                             # Test helper functions
│
├── regression/
│   └── no_plain_empty_text_test.dart            # BizEmptyState usage check
│
└── widget_test.dart                              # App smoke test
```

## Running Tests

### All Tests

```bash
flutter test

# Expected output:
# 00:06 +17: All tests passed!
```

### Specific Test File

```bash
flutter test test/features/dashboard/dashboard_quick_actions_test.dart
```

### Test with Coverage

```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

**Coverage target:** ≥75%

### Verbose Output

```bash
flutter test --reporter expanded
```

## Writing Tests

### Unit Test Pattern

```dart
// test/core/services/example_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:bizagent/core/services/example_service.dart';

void main() {
  group('ExampleService', () {
    late ExampleService service;
    
    setUp(() {
      service = ExampleService();
    });
    
    test('should calculate correctly', () {
      // Arrange
      final input = 100.0;
      
      // Act
      final result = service.calculate(input);
      
      // Assert
      expect(result, 120.0);
    });
    
    test('should throw on negative input', () {
      expect(
        () => service.calculate(-100),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
```

### Widget Test Pattern

```dart
// test/features/dashboard/dashboard_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bizagent/features/dashboard/screens/dashboard_screen.dart';
import 'package:bizagent/features/invoices/providers/invoices_provider.dart';
import 'package:bizagent/core/i18n/l10n.dart';

void main() {
  testWidgets('Dashboard shows empty state', (tester) async {
    // Arrange
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(null)),
          invoicesProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: L10n(
          locale: AppLocale.sk,
          child: const MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      ),
    );
    
    // Act
    await tester.pumpAndSettle();
    
    // Assert
    expect(find.text('Rýchle akcie'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsNWidgets(5));
  });
}
```

### Provider Override Pattern

**StreamProvider Mock:**
```dart
invoicesProvider.overrideWith((ref) {
  return Stream.value([
    InvoiceModel(id: '1', number: '2026/001', ...),
    InvoiceModel(id: '2', number: '2026/002', ...),
  ]);
});
```

**StateNotifierProvider Mock:**
```dart
invoicesControllerProvider.overrideWith((ref) {
  return FakeInvoicesController();
});

class FakeInvoicesController extends StateNotifier<AsyncValue<void>> {
  FakeInvoicesController() : super(const AsyncData(null));
  
  Future<void> addInvoice(InvoiceModel invoice) async {
    // Mock implementation
    state = const AsyncData(null);
  }
}
```

## Test Helper Functions

### testApp() Wrapper

```dart
// test/helpers/test_app.dart
Widget testApp({
  required Widget child,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      home: L10n(locale: AppLocale.sk, child: child),
    ),
  );
}

// Usage
await tester.pumpWidget(
  testApp(
    child: const DashboardScreen(),
    overrides: [
      invoicesProvider.overrideWith((ref) => Stream.value([])),
    ],
  ),
);
```

## Regression Tests

### BizEmptyState Usage

```dart
// test/regression/no_plain_empty_text_test.dart
test('No plain empty texts remain (must use BizEmptyState)', () {
  final invoicesFile = File('lib/features/invoices/screens/invoices_screen.dart');
  final content = invoicesFile.readAsStringSync();
  
  expect(
    content.contains('BizEmptyState'),
    isTrue,
    reason: 'InvoicesScreen must use BizEmptyState widget',
  );
});
```

**Ensures:** Všetky empty states používajú konzistentný `BizEmptyState` widget.

## Integration Tests

### Example: Invoice Creation Flow

```dart
// integration_test/invoice_flow_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  testWidgets('Complete invoice creation flow', (tester) async {
    await tester.pumpWidget(const BizAgentApp());
    
    // 1. Login
    await tester.enterText(find.byType(TextField).first, 'test@example.com');
    await tester.enterText(find.byType(TextField).last, 'password123');
    await tester.tap(find.text('Prihlásiť sa'));
    await tester.pumpAndSettle();
    
    // 2. Navigate to create invoice
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    
    // 3. Fill invoice form
    await tester.enterText(find.bySemanticsLabel('Názov firmy'), 'Test Client');
    await tester.enterText(find.bySemanticsLabel('Popis'), 'Test Item');
    await tester.enterText(find.bySemanticsLabel('Cena/ks'), '100');
    
    // 4. Add item
    await tester.tap(find.byIcon(Icons.add_circle));
    await tester.pumpAndSettle();
    
    // 5. Save invoice
    await tester.tap(find.text('Uložiť'));
    await tester.pumpAndSettle();
    
    // 6. Verify success
    expect(find.text('Faktúra vytvorená!'), findsOneWidget);
  });
}
```

**Run:**
```bash
flutter test integration_test/invoice_flow_test.dart
```

## Common Test Issues

### Issue: "L10n not found"

**Symptom:**
```
Assertion failed: L10n not found. Wrap app with L10n.
```

**Fix:**
```dart
await tester.pumpWidget(
  L10n(  // ✅ Add L10n wrapper
    locale: AppLocale.sk,
    child: const MaterialApp(home: DashboardScreen()),
  ),
);
```

### Issue: "Provider not found in scope"

**Symptom:**
```
Error: Could not find provider invoicesProvider
```

**Fix:**
```dart
await tester.pumpWidget(
  ProviderScope(  // ✅ Add ProviderScope
    overrides: [
      invoicesProvider.overrideWith((ref) => Stream.value([])),
    ],
    child: ...,
  ),
);
```

### Issue: "Multiple exceptions detected"

**Symptom:**
```
Multiple exceptions (3) were detected during the running of the current test
```

**Debug:**
```dart
testWidgets('test name', (tester) async {
  // Add error catching
  FlutterError.onError = (details) {
    print('ERROR: ${details.exception}');
    print('STACK: ${details.stack}');
  };
  
  await tester.pumpWidget(...);
});
```

## Golden Tests (Visual Regression)

### Setup

```dart
// test/golden/invoice_screen_golden_test.dart
testWidgets('InvoiceScreen golden test', (tester) async {
  await tester.pumpWidget(testApp(child: const InvoiceScreen()));
  await tester.pumpAndSettle();
  
  await expectLater(
    find.byType(InvoiceScreen),
    matchesGoldenFile('goldens/invoice_screen.png'),
  );
});
```

**Generate goldens:**
```bash
flutter test --update-goldens
```

## Performance Tests

### Widget Build Performance

```dart
test('DashboardScreen renders in <16ms', () async {
  final stopwatch = Stopwatch()..start();
  
  await tester.pumpWidget(testApp(child: const DashboardScreen()));
  await tester.pumpAndSettle();
  
  stopwatch.stop();
  
  expect(
    stopwatch.elapsedMilliseconds,
    lessThan(16),  // 60 FPS target
    reason: 'Widget build should be faster than 16ms for smooth 60fps',
  );
});
```

## Test Data Builders

### Invoice Builder

```dart
// test/helpers/builders/invoice_builder.dart
class InvoiceBuilder {
  String _id = 'test-id';
  String _number = '2026/001';
  double _totalAmount = 100.0;
  
  InvoiceBuilder withId(String id) {
    _id = id;
    return this;
  }
  
  InvoiceBuilder withNumber(String number) {
    _number = number;
    return this;
  }
  
  InvoiceBuilder withAmount(double amount) {
    _totalAmount = amount;
    return this;
  }
  
  InvoiceModel build() {
    return InvoiceModel(
      id: _id,
      number: _number,
      totalAmount: _totalAmount,
      // ... other required fields
    );
  }
}

// Usage
final invoice = InvoiceBuilder()
    .withNumber('2026/123')
    .withAmount(500.0)
    .build();
```

## CI/CD Testing

### GitHub Actions Workflow

```yaml
# .github/workflows/test.yml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.10.7'
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Analyze code
        run: flutter analyze --fatal-infos --fatal-warnings
      
      - name: Run tests
        run: flutter test --coverage
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage/lcov.info
```

## Test Coverage Goals

| Component | Target Coverage |
|-----------|----------------|
| Core Services | ≥90% |
| Business Logic | ≥85% |
| UI Widgets | ≥70% |
| Overall | ≥75% |

**Check coverage:**
```bash
flutter test --coverage
lcov --summary coverage/lcov.info
```

## Pre-Commit Testing

### Husky Hook Setup

```bash
# .husky/pre-commit
#!/bin/sh
flutter test
if [ $? -ne 0 ]; then
  echo "❌ Tests failed. Fix before committing."
  exit 1
fi
```

**Install:**
```bash
npm install --save-dev husky
npx husky install
npx husky add .husky/pre-commit "flutter test"
```

## Next Steps

1. ✅ Write tests for new features BEFORE implementation (TDD)
2. ✅ Run `flutter test` before každý commit
3. ✅ Maintain ≥75% test coverage
4. ✅ Add regression tests pre každý bug fix
5. ✅ Review test quality v code reviews
