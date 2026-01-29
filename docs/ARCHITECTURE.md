# Architecture - BizAgent

## Prehľad

BizAgent je Flutter aplikácia pre SZČO a malé firmy postavená na **clean architecture** princípoch s použitím **Riverpod** pre state management a **GoRouter** pre navigáciu.

## Štruktúra Projektu

```
lib/
├── core/                    # Základné building blocky
│   ├── constants/          # App konštanty
│   ├── i18n/              # Lokalizácia (SK primárne)
│   ├── providers/         # Core providers (theme)
│   ├── router/            # GoRouter konfigurácia
│   ├── services/          # Shared services (PDF, OCR, QR payment, tax calc)
│   ├── theme/             # App témy a BizTheme
│   └── utils/             # Utility funkcie (CSV, file names, money)
│
├── features/              # Feature modules
│   ├── auth/             # Firebase Authentication
│   ├── bank_import/      # Bank CSV import + auto-matching
│   ├── cashflow/         # Cash flow overview
│   ├── dashboard/        # Home screen, quick actions
│   ├── documents/        # Document management
│   ├── expenses/         # Expense tracking
│   ├── export/           # ZIP export pre účtovníka
│   ├── invoices/         # Invoice creation, numbering
│   ├── settings/         # User settings, company info
│   └── tax/              # Tax calculations, deadlines
│
├── shared/               # Shared widgets
│   ├── models/          # Shared models
│   └── widgets/         # Reusable widgets (BizCard, BizEmptyState, etc.)
│
└── main.dart            # Entry point
```

### Feature Module Pattern

Každý feature modul dodržiava konzistentnú štruktúru:

```
feature/
├── data/           # Repository implementations
├── models/         # Data models (freezed/copyWith)
├── providers/      # Riverpod providers
├── screens/        # UI screens
├── services/       # Business logic
└── widgets/        # Feature-specific widgets
```

## State Management - Riverpod

### Provider Types

**StreamProvider** - Real-time Firebase data:
```dart
final invoicesProvider = StreamProvider<List<InvoiceModel>>((ref) {
  final uid = ref.watch(authStateProvider).value?.id;
  if (uid == null) return Stream.value([]);
  return ref.read(invoicesRepositoryProvider).watchInvoices(uid);
});
```

**StateNotifierProvider** - Mutable state + business logic:
```dart
final invoicesControllerProvider = 
    StateNotifierProvider<InvoicesController, AsyncValue<void>>(...);
```

**Provider** - Immutable data:
```dart
final ocrServiceProvider = Provider((ref) => OcrService());
```

### Provider Overrides (Testing)

```dart
ProviderScope(
  overrides: [
    authStateProvider.overrideWith((ref) => Stream.value(null)),
    invoicesProvider.overrideWith((ref) => Stream.value([])),
  ],
  child: MaterialApp(...),
)
```

## Router & Navigation - GoRouter

### Redirect Logic (Auth Guard)

```dart
redirect: (context, state) {
  final isLoggedIn = authState.valueOrNull != null;
  final isLoggingIn = state.uri.path == '/login';
  
  if (!isLoggedIn && !isLoggingIn) return '/login';
  if (isLoggedIn && isLoggingIn) return '/dashboard';
  return null;
}
```

### Navigačné Cesty

| Cesta | Screen | Auth Required |
|-------|--------|---------------|
| `/login` | LoginScreen | ❌ |
| `/dashboard` | DashboardScreen | ✅ |
| `/invoices` | InvoicesScreen | ✅ |
| `/expenses` | ExpensesScreen | ✅ |
| `/create-invoice` | CreateInvoiceScreen | ✅ |
| `/create-expense` | CreateExpenseScreen | ✅ |
| `/bank-import` | BankImportScreen | ✅ |
| `/export` | ExportScreen | ✅ |
| `/settings` | SettingsScreen | ✅ |

### StatefulShellRoute (Bottom Navigation)

5 hlavných tabov v bottom nav:
1. Dashboard
2. Invoices
3. Expenses
4. AI Tools
5. Settings

## Data Flow

### Invoice Creation Flow

```
CreateInvoiceScreen
  ↓
InvoicesController.addInvoice()
  ↓
InvoicesRepository.addInvoice()
  ↓
Firestore Collection: invoices/{userId}/invoices/{invoiceId}
  ↓
StreamProvider refresh (real-time)
  ↓
InvoicesScreen automaticky dostane nové dáta
```

### Bank Import Flow

```
BankImportScreen
  ↓
1. User vyberá CSV súbor (file_picker)
  ↓
2. BankCsvParserService parsuje CSV
  ↓
3. BankMatchService hľadá matches (VS + amount)
  ↓
4. User potvrdí matches
  ↓
5. InvoicesRepository.updateInvoiceStatus()
```

### Export Flow

```
ExportScreen
  ↓
1. ExportService.createZipExport()
  ↓
2. Zbiera: Invoices PDF, Expense photos, Summary CSV, Data JSON
  ↓
3. Archivuje do ZIP (archive package)
  ↓
4. User zdieľa cez share_plus alebo uloží do Files
```

## Core Services

### OCR Service
- **Package:** `google_mlkit_text_recognition`
- **Použitie:** Skenovanie bločkov (expenses)
- **Flow:** Camera → ML Kit → Extract text → Pre-fill expense form

### PDF Service
- **Package:** `pdf`, `printing`
- **Použitie:** Generovanie faktu PDF
- **Obsahuje:** QR kód pre platbu (EPC-QR), firemné údaje, DPH kalkulácie

### QR Payment Service
- **Standard:** EPC-QR (SEPA payments)
- **Obsahuje:** IBAN, amount, VS, message
- **Package:** `qr_flutter`

### OCR & Intelligence Service
- **CategorizationService**: Inteligentná auto-kategorizácia na základe regex pravidiel a kľúčových slov dodávateľov.
- **Matched Patterns**: 80+ overených slovenských a medzinárodných značiek.
- **OCR Integration**: Plynulý prechod od extrakcie textu k návrhu kategórie.

### Analytics & Charting
- **Package**: `fl_chart`
- **Typy**: PieChart (rozdelenie nákladov), BarChart (denný/mesačný trend).
- **Logika**: Real-time agregácia dát z `expensesProvider` pomocou Riverpod state managementu.

### Tax Calculation Service
- **Per-line VAT rounding** (podľa SR legislatívy)
- **Supports:** 0%, 10%, 20% VAT rates
- **Testované:** `test/core/services/tax_calculation_service_test.dart`

## Firebase Integration

### Collections

```
users/{userId}
  └── settings (dokument)

invoices/{userId}
  └── invoices/{invoiceId}

expenses/{userId}
  └── expenses/{expenseId}

receipts/ (Firebase Storage)
  └── users/{userId}/receipts/{fileName}

invoice_numbering/{userId}
  └── state (dokument - počítadlo faktúr)
```

### Security Rules

- User môže čítať/písať iba vlastné dáta (`request.auth.uid == userId`)
- Invoice numbering: atomic increment pre collision-free numbering

## Testing Strategy

### Test Layout

```
test/
├── core/              # Core service tests
│   ├── router/       # Router path smoke tests
│   ├── services/     # Business logic unit tests
│   └── utils/        # Utility tests (CSV, money)
├── features/         # Feature widget tests
│   ├── dashboard/    # Dashboard empty state, quick actions
│   ├── bank_import/  # CSV parser, matching logic
│   └── export/       # Export auth guard
├── helpers/          # Test helpers (testApp wrapper)
└── regression/       # Regression tests (BizEmptyState usage)
```

### Test Helper - testApp()

```dart
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
```

### Provider Override Pattern

```dart
testWidgets('test name', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authStateProvider.overrideWith((ref) => Stream.value(null)),
        invoicesProvider.overrideWith((ref) => Stream.value([])),
      ],
      child: L10n(
        locale: AppLocale.sk,
        child: const MaterialApp(home: DashboardScreen()),
      ),
    ),
  );
  
  await tester.pumpAndSettle();
  expect(find.text('Expected text'), findsOneWidget);
});
```

## Localization (i18n)

### L10n Pattern

```dart
// core/i18n/l10n.dart
class L10n extends InheritedWidget {
  final AppLocale locale;
  
  static L10n of(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<L10n>();
    assert(result != null, 'L10n not found. Wrap app with L10n.');
    return result!;
  }
}

// Usage in widgets
context.t(AppStr.invoiceTitle); // "Faktúra"
```

### String Keys (app_strings.dart)

Enum-based keys pre type safety:
```dart
enum AppStr {
  invoiceTitle,
  invoiceEmptyTitle,
  expensesTitle,
  // ...
}
```

## Known Architecture Gotchas

### 1. Hero Tag Duplicates
**Issue:** Multiple FABs v bottom navigation majú rovnaký tag.
**Fix:** Unique hero tags pre každý tab's FAB.

### 2. Auth Redirect Loop
**Symptom:** Infinite redirect medzi `/login` a `/dashboard`.
**Fix:** Check `authState.isLoading` pred redirect decision.

### 3. Test L10n Wrapper
**Symptom:** `L10n not found` assertion v testoch.
**Fix:** Vždy wrap test widget s `L10n(locale: AppLocale.sk, child: ...)`.

## Performance Optimizations

- **StreamProvider caching** - Firestore real-time listeners sú shared
- **ConsumerWidget** - Rebuild len časti widgetu pri state change
- **ListView.builder** - Lazy rendering dlhých listov
- **Image caching** - Firebase Storage URLs sú cachované

## TODO / Budúce Vylepšenia

- [ ] Offline mode (Firestore persistence)
- [ ] Multi-language support (EN translations dokončiť)
- [ ] Dark mode improvements
- [ ] Invoice templates (custom designs)
- [ ] Recurring invoices automation
