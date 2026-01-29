# 🧪 Testovacia Stratégia - BizAgent

**Dátum:** 2026-01-29  
**Aktuálny stav:** 149 testov (145 ✅, 1 ⏭️, 4 ❌)

---

## 📊 Aktuálny Stav Pokrytia

### ✅ Pokryté Oblasti

- **Core Services:** Invoice numbering, Tax calculation, QR payment, CSV parsing
- **AI Tools:** Gemini service, BizBot, Email generator, OCR
- **Dashboard:** Quick actions, Empty states, Insights widgets
- **Expenses:** Categorization, Repository, Bank import
- **Invoices:** Repository, Payment reminders, PDF preview
- **Analytics:** Expense insights, Revenue/Profit providers
- **Notifications:** Scheduler, Service
- **Widgets:** BizInvoiceCard, BizStatsCard

### ⚠️ Kritické Oblasti Potrebujúce Testy

## 🔴 Kritické Testy (Vysoká Priorita)

### 1. **Firebase Functions (Backend)**

**Prečo:** Backend API je kritický pre fungovanie aplikácie

**Testy:**
- ✅ `generateEmail` - Generovanie e-mailov
- ✅ `analyzeReceipt` - Analýza bločkov
- ✅ `lookupCompany` - Hľadanie firiem podľa IČO
- ✅ `generateContent` - Univerzálna Gemini funkcia
- ❌ **Chýba:** Error handling pre API failures
- ❌ **Chýba:** Rate limiting a quota handling
- ❌ **Chýba:** CORS validácia
- ❌ **Chýba:** Authentication checks

**Vytvoriť:**
```bash
test/firebase_functions/
├── generate_email_test.dart
├── analyze_receipt_test.dart
├── lookup_company_test.dart
├── generate_content_test.dart
├── error_handling_test.dart
└── rate_limiting_test.dart
```

### 2. **Soft Delete Service**

**Prečo:** Kritická funkcionalita pre GDPR compliance

**Testy:**
- ❌ **Chýba:** Soft delete operácie
- ❌ **Chýba:** Restore operácie
- ❌ **Chýba:** Cleanup expired items (7 dní)
- ❌ **Chýba:** Trash items stream

**Vytvoriť:**
```dart
test/core/services/soft_delete_service_test.dart
```

### 3. **Local Persistence Service (Hive)**

**Prečo:** Offline funkcionalita a performance

**Testy:**
- ❌ **Chýba:** Save/Load invoices
- ❌ **Chýba:** Save/Load expenses
- ❌ **Chýba:** Settings persistence
- ❌ **Chýba:** Business profile persistence
- ❌ **Chýba:** Clear operations

**Vytvoriť:**
```dart
test/core/services/local_persistence_service_test.dart
```

### 4. **Invoice Numbering Service (Offline Scenarios)**

**Prečo:** Kritická business logika pre faktúry

**Testy:**
- ✅ Základné číslovanie
- ❌ **Chýba:** Offline fallback (TMP numbers)
- ❌ **Chýba:** Block reservation failures
- ❌ **Chýba:** Year transitions
- ❌ **Chýba:** Concurrent access handling

**Rozšíriť:**
```dart
test/core/services/invoice_numbering_service_test.dart
```

### 5. **Billing & Subscription**

**Prečo:** Monetizácia a access control

**Testy:**
- ❌ **Chýba:** Subscription status checks
- ❌ **Chýba:** Paywall display logic
- ❌ **Chýba:** Feature gating
- ❌ **Chýba:** Usage limits

**Vytvoriť:**
```dart
test/features/billing/
├── billing_service_test.dart
├── subscription_guard_test.dart
└── usage_limiter_test.dart
```

### 6. **Export Service**

**Prečo:** Dôležitá funkcionalita pre používateľov

**Testy:**
- ❌ **Chýba:** CSV export
- ❌ **Chýba:** PDF export
- ❌ **Chýba:** Data formatting
- ❌ **Chýba:** Error handling

**Vytvoriť:**
```dart
test/core/services/export_service_test.dart
```

### 7. **Settings Repository**

**Prečo:** Synchronizácia nastavení medzi zariadeniami

**Testy:**
- ❌ **Chýba:** Save settings
- ❌ **Chýba:** Load settings
- ❌ **Chýba:** Default values
- ❌ **Chýba:** Sync conflicts

**Vytvoriť:**
```dart
test/features/settings/settings_repository_test.dart
```

### 8. **Watched Companies Service**

**Prečo:** Monitoring zmien v firmách

**Testy:**
- ✅ Základné operácie
- ❌ **Chýba:** Change detection
- ❌ **Chýba:** Notification triggers
- ❌ **Chýba:** Batch refresh

**Rozšíriť:**
```dart
test/features/tools/services/watched_companies_service_test.dart
```

## 🟡 Dôležité Testy (Stredná Priorita)

### 9. **Auth Repository & Provider**

**Testy:**
- ❌ **Chýba:** Login flow
- ❌ **Chýba:** Logout flow
- ❌ **Chýba:** Auth state changes
- ❌ **Chýba:** Error handling

**Vytvoriť:**
```dart
test/features/auth/
├── auth_repository_test.dart
└── auth_provider_test.dart
```

### 10. **Tax Thermometer Service**

**Testy:**
- ✅ Základné výpočty
- ❌ **Chýba:** Threshold calculations
- ❌ **Chýba:** Progress tracking
- ❌ **Chýba:** Deadline warnings

**Rozšíriť:**
```dart
test/features/tax/tax_thermometer_service_test.dart
```

### 11. **Receipt Storage Service**

**Testy:**
- ❌ **Chýba:** Image upload
- ❌ **Chýba:** Image download
- ❌ **Chýba:** Storage paths
- ❌ **Chýba:** Cleanup operations

**Vytvoriť:**
```dart
test/features/expenses/services/receipt_storage_service_test.dart
```

### 12. **IcoAtlas Service**

**Testy:**
- ✅ Základné lookup
- ❌ **Chýba:** Error handling
- ❌ **Chýba:** Caching
- ❌ **Chýba:** Rate limiting

**Rozšíriť:**
```dart
test/core/services/icoatlas_service_test.dart
```

### 13. **Monitoring Service**

**Testy:**
- ❌ **Chýba:** Company monitoring
- ❌ **Chýba:** Change detection
- ❌ **Chýba:** Notification scheduling

**Vytvoriť:**
```dart
test/features/tools/services/monitoring_service_test.dart
```

## 🟢 Widget Testy (Nízka Priorita)

### 14. **Screen Widget Tests**

**Testy:**
- ❌ **Chýba:** CreateInvoiceScreen
- ❌ **Chýba:** CreateExpenseScreen
- ❌ **Chýba:** SettingsScreen
- ❌ **Chýba:** BusinessProfileScreen
- ❌ **Chýba:** TrashScreen

**Vytvoriť:**
```dart
test/features/invoices/screens/create_invoice_screen_test.dart
test/features/expenses/screens/create_expense_screen_test.dart
test/features/settings/screens/settings_screen_test.dart
test/features/settings/screens/business_profile_screen_test.dart
test/features/settings/screens/trash_screen_test.dart
```

## 🔵 Integration Testy

### 15. **End-to-End Flows**

**Testy:**
- ✅ Základný user journey
- ❌ **Chýba:** Invoice creation flow (kompletný)
- ❌ **Chýba:** Expense creation flow (kompletný)
- ❌ **Chýba:** Bank import flow
- ❌ **Chýba:** Export flow
- ❌ **Chýba:** Settings sync flow

**Rozšíriť:**
```dart
integration_test/
├── invoice_creation_flow_test.dart
├── expense_creation_flow_test.dart
├── bank_import_flow_test.dart
├── export_flow_test.dart
└── settings_sync_flow_test.dart
```

### 16. **Firebase Emulator Tests**

**Testy:**
- ❌ **Chýba:** Firestore rules validation
- ❌ **Chýba:** Storage rules validation
- ❌ **Chýba:** Auth rules validation
- ❌ **Chýba:** Functions integration

**Vytvoriť:**
```dart
integration_test/firebase/
├── firestore_rules_test.dart
├── storage_rules_test.dart
└── auth_rules_test.dart
```

## 📋 Testovací Checklist

### Kritické Testy (Musia Prejsť Pred Release)

- [ ] Firebase Functions error handling
- [ ] Soft Delete Service (GDPR compliance)
- [ ] Local Persistence Service (offline mode)
- [ ] Invoice Numbering offline scenarios
- [ ] Billing & Subscription logic
- [ ] Export Service
- [ ] Settings Repository sync

### Dôležité Testy (Odporúčané Pred Release)

- [ ] Auth Repository & Provider
- [ ] Tax Thermometer edge cases
- [ ] Receipt Storage Service
- [ ] IcoAtlas Service error handling
- [ ] Monitoring Service

### Widget Testy (Post-Release)

- [ ] Screen widget tests
- [ ] Form validation tests
- [ ] Navigation tests

### Integration Testy (Continuous)

- [ ] E2E flows
- [ ] Firebase Emulator tests
- [ ] Performance tests

## 🎯 Test Coverage Goals

| Komponent | Aktuálne | Cieľ | Priorita |
|-----------|----------|------|----------|
| Core Services | ~70% | ≥90% | 🔴 Kritické |
| Business Logic | ~65% | ≥85% | 🔴 Kritické |
| Firebase Functions | ~40% | ≥80% | 🔴 Kritické |
| Repositories | ~60% | ≥80% | 🟡 Dôležité |
| UI Widgets | ~50% | ≥70% | 🟢 Nízka |
| **Celkové** | **~65%** | **≥75%** | - |

## 🚀 Implementačný Plán

### Fáza 1: Kritické Testy (1-2 týždne)

1. Firebase Functions testy
2. Soft Delete Service testy
3. Local Persistence Service testy
4. Invoice Numbering offline testy
5. Billing & Subscription testy

### Fáza 2: Dôležité Testy (1 týždeň)

1. Auth Repository testy
2. Tax Thermometer rozšírenie
3. Receipt Storage testy
4. IcoAtlas Service rozšírenie

### Fáza 3: Widget & Integration (1 týždeň)

1. Screen widget testy
2. E2E flow testy
3. Firebase Emulator testy

## 📝 Testovacie Best Practices

### 1. **Arrange-Act-Assert Pattern**

```dart
test('should calculate VAT correctly', () {
  // Arrange
  final service = TaxCalculationService();
  final amount = 100.0;
  
  // Act
  final result = service.calculateVAT(amount);
  
  // Assert
  expect(result, 20.0);
});
```

### 2. **Mocking External Dependencies**

```dart
test('should handle API errors gracefully', () async {
  // Arrange
  final mockFirebaseFunctions = MockFirebaseFunctions();
  when(mockFirebaseFunctions.httpsCallable(any))
      .thenThrow(FirebaseFunctionsException(...));
  
  final service = GeminiService(mockFirebaseFunctions);
  
  // Act & Assert
  expect(
    () => service.generateEmail(...),
    throwsA(isA<ServiceException>()),
  );
});
```

### 3. **Test Data Builders**

```dart
final invoice = InvoiceBuilder()
    .withNumber('2026/001')
    .withAmount(1000.0)
    .withClient('Test Client')
    .build();
```

### 4. **Integration Test Helpers**

```dart
Future<void> loginUser(WidgetTester tester) async {
  await tester.enterText(find.byKey(Key('email')), 'test@example.com');
  await tester.enterText(find.byKey(Key('password')), 'password123');
  await tester.tap(find.text('Prihlásiť sa'));
  await tester.pumpAndSettle();
}
```

## 🔧 Nástroje a Utilities

### Test Helpers

```dart
// test/helpers/test_data_builders.dart
class InvoiceBuilder { ... }
class ExpenseBuilder { ... }
class UserBuilder { ... }

// test/helpers/mock_factories.dart
MockFirebaseFirestore createMockFirestore() { ... }
MockFirebaseAuth createMockAuth() { ... }

// test/helpers/test_app.dart
Widget testApp({required Widget child, List<Override> overrides = const []}) { ... }
```

## 📚 Referencie

- [Flutter Testing Guide](https://docs.flutter.dev/testing)
- [Firebase Emulator Suite](https://firebase.google.com/docs/emulator-suite)
- [Mockito Documentation](https://pub.dev/packages/mockito)
- [Riverpod Testing](https://riverpod.dev/docs/concepts/testing)

---

**Poznámka:** Tento dokument by mal byť aktualizovaný po implementácii každého testu.
