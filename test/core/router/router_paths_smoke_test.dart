import 'dart:async';
import 'dart:typed_data';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:bizagent/core/i18n/l10n.dart';
import 'package:bizagent/core/router/app_router.dart';
import 'package:bizagent/core/services/analytics_service.dart';
import 'package:bizagent/core/services/initialization_service.dart';
import 'package:bizagent/core/services/pdf_service.dart';
import 'package:bizagent/features/ai_tools/providers/ai_email_service.dart';
import 'package:bizagent/features/ai_tools/providers/bizbot_history_provider.dart';
import 'package:bizagent/features/analytics/providers/expense_insights_provider.dart';
import 'package:bizagent/features/auth/models/user_model.dart';
import 'package:bizagent/features/auth/providers/auth_repository.dart';
import 'package:bizagent/features/dashboard/providers/profit_provider.dart';
import 'package:bizagent/features/dashboard/providers/revenue_provider.dart';
import 'package:bizagent/features/expenses/providers/expenses_provider.dart';
import 'package:bizagent/features/intro/providers/onboarding_provider.dart';
import 'package:bizagent/features/invoices/models/invoice_model.dart';
import 'package:bizagent/features/invoices/providers/invoices_provider.dart';
import 'package:bizagent/features/notifications/services/notification_service.dart';
import 'package:bizagent/features/settings/models/user_settings_model.dart';
import 'package:bizagent/features/settings/providers/settings_provider.dart';
import 'package:bizagent/features/tax/providers/tax_estimation_service.dart';
import 'package:bizagent/features/tax/providers/tax_provider.dart';
import 'package:bizagent/features/tax/providers/tax_thermometer_service.dart';
import 'package:bizagent/features/tools/services/monitoring_service.dart';

/// Kritické routes aplikácie – smoke test overí navigáciu a render bez pádu.
class _CriticalRoute {
  const _CriticalRoute({
    required this.path,
    required this.comment,
    this.extra,
    this.expectedText,
  });

  final String path;
  final String comment;
  final Object? extra;
  final String? expectedText;
}

const _testUser = UserModel(id: 'smoke-test-user', email: 'smoke@test.com');

const _criticalRoutes = <_CriticalRoute>[
  _CriticalRoute(
    path: '/dashboard',
    comment: 'Hlavný prehľad – dashboard s quick actions',
    expectedText: 'Rýchle akcie',
  ),
  _CriticalRoute(
    path: '/expenses',
    comment: 'Zoznam výdavkov',
    expectedText: 'Výdavky',
  ),
  _CriticalRoute(
    path: '/invoices',
    comment: 'Zoznam faktúr',
    expectedText: 'Zatiaľ žiadne faktúry',
  ),
  _CriticalRoute(
    path: '/export',
    comment: 'Export pre účtovníčku (PDF/CSV balík)',
    expectedText: 'Export pre účtovníčku',
  ),
  _CriticalRoute(
    path: '/invoices/preview',
    comment: 'Náhľad PDF faktúry – vyžaduje InvoiceModel v extra',
    extra: null, // doplní sa v setUp fixture
    expectedText: 'Náhľad faktúry',
  ),
];

class _MockAuthRepository implements AuthRepository {
  _MockAuthRepository(Stream<UserModel?> stream) {
    authStateChanges = stream;
  }

  @override
  UserModel? get currentUser => _testUser;

  @override
  late final Stream<UserModel?> authStateChanges;

  @override
  Future<String?> get currentUserToken async => 'fake-token';

  @override
  Future<UserModel?> signIn(String email, String password) async => null;

  @override
  Future<UserModel?> signUp(String email, String password) async => null;

  @override
  Future<UserModel?> signInWithGoogle() async => null;

  @override
  Future<UserModel?> signInAnonymously() async => null;

  @override
  Future<void> signOut() async {}

  @override
  Future<void> deleteAccount() async {}

  @override
  void dispose() {}
}

class _MockFirebaseAnalytics extends Fake implements FirebaseAnalytics {
  @override
  Future<void> logScreenView({
    String? screenName,
    String? screenClass,
    Map<String, Object>? parameters,
    AnalyticsCallOptions? callOptions,
  }) async {}

  @override
  Future<void> logEvent({
    required String name,
    Map<String, Object?>? parameters,
    AnalyticsCallOptions? callOptions,
  }) async {}

  @override
  Future<void> logAppOpen({
    Map<String, Object?>? parameters,
    AnalyticsCallOptions? callOptions,
  }) async {}
}

class _TestInitializationService extends InitializationService {
  _TestInitializationService(super.ref) {
    state = const InitState(progress: 1.0, message: 'Hotovo!', isCompleted: true);
  }

  @override
  Future<void> initializeApp() async {}
}

class _FakeNotificationService extends Fake implements NotificationService {
  @override
  Future<void> init() async {}

  @override
  Future<bool?> requestPermissions() async => true;

  @override
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {}

  @override
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {}
}

class _FakeMonitoringService extends Fake implements MonitoringService {
  @override
  void startListening(String uid) {}

  @override
  void stopListening() {}

  @override
  Stream<List<Map<String, dynamic>>> notifications() => Stream.value([]);

  @override
  Future<void> markAsRead(String id) async {}

  @override
  Future<void> markAllAsRead() async {}
}

class _MockAiEmailService implements AiEmailService {
  @override
  Future<String> generateEmail({
    required String type,
    required String tone,
    required String context,
  }) async =>
      'Mock e-mail – bez volania API.';
}

class _MockPdfService implements PdfService {
  @override
  Future<Uint8List> generateInvoice(
    InvoiceModel invoice,
    UserSettingsModel settings,
  ) async =>
      Uint8List.fromList(const [0x25, 0x50, 0x44, 0x46]); // %PDF stub
}

List<Override> _authenticatedRouterOverrides() {
  final mockAnalytics = _MockFirebaseAnalytics();
  return [
    authRepositoryProvider.overrideWithValue(
      _MockAuthRepository(Stream.value(_testUser)),
    ),
    authStateProvider.overrideWith((ref) => Stream.value(_testUser)),
    onboardingProvider
        .overrideWith((ref) => OnboardingNotifier.test(ref, seen: true)),
    initializationServiceProvider
        .overrideWith((ref) => _TestInitializationService(ref)),
    invoicesProvider.overrideWith((ref) => Stream.value([])),
    expensesProvider.overrideWith((ref) => Stream.value([])),
    settingsProvider
        .overrideWith((ref) => Stream.value(UserSettingsModel.empty())),
    firebaseAnalyticsProvider.overrideWithValue(mockAnalytics),
    analyticsServiceProvider.overrideWithValue(AnalyticsService(mockAnalytics)),
    notificationServiceProvider.overrideWithValue(_FakeNotificationService()),
    monitoringServiceProvider.overrideWithValue(_FakeMonitoringService()),
    expenseInsightsProvider.overrideWith((ref) => []),
    revenueMetricsProvider.overrideWith(
      (ref) => Future.value(
        RevenueMetrics(
          totalRevenue: 0,
          thisMonthRevenue: 0,
          lastMonthRevenue: 0,
          unpaidAmount: 0,
          overdueCount: 0,
          averageInvoiceValue: 0,
        ),
      ),
    ),
    profitMetricsProvider.overrideWith(
      (ref) => Future.value(
        ProfitMetrics(profit: 0, profitMargin: 0, thisMonthProfit: 0),
      ),
    ),
    taxThermometerProvider.overrideWith(
      (ref) => AsyncValue.data(TaxThermometerResult(currentTurnover: 0)),
    ),
    taxEstimationProvider.overrideWith(
      (ref) => AsyncValue.data(TaxEstimationModel.empty()),
    ),
    upcomingTaxDeadlinesProvider.overrideWith((ref) => []),
    aiEmailServiceProvider.overrideWithValue(_MockAiEmailService()),
    bizBotMessagesProvider.overrideWith((ref) => Stream.value([])),
    pdfServiceProvider.overrideWithValue(_MockPdfService()),
  ];
}

ProviderContainer _createAuthenticatedContainer() {
  return ProviderContainer(overrides: _authenticatedRouterOverrides());
}

Future<void> _pumpRouterApp(WidgetTester tester, ProviderContainer container) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() => tester.view.resetPhysicalSize());

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: L10n(
        locale: AppLocale.sk,
        child: Consumer(
          builder: (context, ref, _) {
            return MaterialApp.router(
              routerConfig: ref.watch(routerProvider),
            );
          },
        ),
      ),
    ),
  );

  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

InvoiceModel _sampleInvoice() {
  return InvoiceModel(
    id: 'smoke-invoice-1',
    userId: _testUser.id,
    createdAt: DateTime(2026, 1, 1),
    number: '2026/001',
    clientName: 'Smoke Test Client',
    dateIssued: DateTime(2026, 1, 1),
    dateDue: DateTime(2026, 1, 15),
    items: [],
    totalAmount: 100,
    status: InvoiceStatus.draft,
  );
}

Object? _extraForRoute(_CriticalRoute route) {
  if (route.path == '/invoices/preview') {
    return _sampleInvoice();
  }
  return route.extra;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('sk');
  });

  group('Critical route paths – smoke', () {
    test('routerProvider can be created without throw', () {
      final container = _createAuthenticatedContainer();
      addTearDown(container.dispose);

      expect(() => container.read(routerProvider), returnsNormally);
    });

    for (final route in _criticalRoutes) {
      testWidgets('${route.path} builds without crash (${route.comment})',
          (tester) async {
        final container = _createAuthenticatedContainer();
        addTearDown(container.dispose);

        await _pumpRouterApp(tester, container);

        final router = container.read(routerProvider);
        expect(router.state.uri.path, '/dashboard');

        expect(
          () => router.go(route.path, extra: _extraForRoute(route)),
          returnsNormally,
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(
          router.state.uri.path,
          route.path,
          reason: 'Router should land on ${route.path}',
        );

        expect(find.byType(Scaffold), findsWidgets);

        if (route.expectedText != null) {
          expect(find.textContaining(route.expectedText!), findsWidgets);
        }

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(seconds: 1));
      });
    }

    testWidgets('Neexistujúca cesta zobrazí GoRouter error page', (tester) async {
      final container = _createAuthenticatedContainer();
      addTearDown(container.dispose);

      await _pumpRouterApp(tester, container);

      final router = container.read(routerProvider);
      router.go('/__route_neexistuje__');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('Page Not Found'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
