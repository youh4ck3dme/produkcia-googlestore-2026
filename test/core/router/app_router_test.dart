import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bizagent/core/router/app_router.dart';
import 'package:bizagent/core/services/analytics_service.dart';
import 'package:bizagent/features/auth/providers/auth_repository.dart';
import 'package:bizagent/features/auth/models/user_model.dart';
import 'package:bizagent/features/intro/providers/onboarding_provider.dart';
import 'package:bizagent/features/invoices/providers/invoices_provider.dart';
import 'package:bizagent/features/expenses/providers/expenses_provider.dart';
import 'package:bizagent/features/settings/providers/settings_provider.dart';
import 'package:bizagent/features/settings/models/user_settings_model.dart';
import 'package:bizagent/core/i18n/l10n.dart';
import 'package:bizagent/core/services/initialization_service.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:bizagent/features/notifications/services/notification_service.dart';
import 'package:bizagent/features/tools/services/monitoring_service.dart';
import 'package:bizagent/features/analytics/providers/expense_insights_provider.dart';
import 'dart:async';
import 'package:bizagent/features/dashboard/providers/revenue_provider.dart';
import 'package:bizagent/features/dashboard/providers/profit_provider.dart';
import 'package:bizagent/features/tax/providers/tax_thermometer_service.dart';
import 'package:bizagent/features/tax/providers/tax_estimation_service.dart';
import 'package:bizagent/features/tax/providers/tax_provider.dart';

class MockAuthRepository implements AuthRepository {
  @override
  UserModel? get currentUser => null;

  @override
  late final Stream<UserModel?> authStateChanges;

  @override
  Future<String?> get currentUserToken async => 'fake-token-123';

  MockAuthRepository(Stream<UserModel?> stream) {
    authStateChanges = stream;
  }

  @override
  Future<UserModel?> signIn(String email, String password) async => null;
  @override
  Future<UserModel?> signUp(String email, String password) async => null;
  @override
  Future<UserModel?> signInWithGoogle() async => null;
  @override
  Future<void> signOut() async {}
  @override
  Future<void> deleteAccount() async {}
  @override
  void dispose() {}
}

class MockFirebaseAnalytics extends Fake implements FirebaseAnalytics {
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

class TestInitializationService extends InitializationService {
  TestInitializationService(super.ref) {
    state = const InitState(progress: 1.0, message: 'Hotovo!', isCompleted: true);
  }

  @override
  Future<void> initializeApp() async {}
}

class FakeNotificationService extends Fake implements NotificationService {
  @override
  Future<void> init() async {}
  @override
  Future<bool?> requestPermissions() async => true;
  @override
  Future<void> showNotification(
      {required int id,
      required String title,
      required String body,
      String? payload}) async {}
  @override
  Future<void> scheduleNotification(
      {required int id,
      required String title,
      required String body,
      required DateTime scheduledDate,
      String? payload}) async {}
}

class FakeMonitoringService extends Fake implements MonitoringService {
  @override
  void startListening(String uid) {}

  @override
  void stopListening() {}

  @override
  Stream<List<Map<String, dynamic>>> notifications() {
    return Stream.value([]);
  }
  
  @override
  Future<void> markAsRead(String id) async {}
  
  @override
  Future<void> markAllAsRead() async {}
}

void main() {
  final mockAnalytics = MockFirebaseAnalytics();

  group('AppRouter Redirect Tests', () {
    testWidgets('Stays on /splash when auth is loading', (tester) async {
      tester.view.physicalSize = const Size(1000, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider
              .overrideWithValue(MockAuthRepository(const Stream.empty())),
          authStateProvider.overrideWith((ref) => const Stream.empty()),
          onboardingProvider
              .overrideWith((ref) => OnboardingNotifier.test(ref, seen: true)),
          initializationServiceProvider
              .overrideWith((ref) => TestInitializationService(ref)),
          firebaseAnalyticsProvider.overrideWithValue(mockAnalytics),
          analyticsServiceProvider
              .overrideWithValue(AnalyticsService(mockAnalytics)),
          notificationServiceProvider.overrideWithValue(FakeNotificationService()),
          monitoringServiceProvider.overrideWithValue(FakeMonitoringService()),
          expenseInsightsProvider.overrideWith((ref) => []),
          revenueMetricsProvider.overrideWith((ref) => Future.value(RevenueMetrics(totalRevenue: 0, thisMonthRevenue: 0, lastMonthRevenue: 0, unpaidAmount: 0, overdueCount: 0, averageInvoiceValue: 0))),
          profitMetricsProvider.overrideWith((ref) => Future.value(ProfitMetrics(profit: 0, profitMargin: 0, thisMonthProfit: 0))),
          taxThermometerProvider.overrideWith((ref) => AsyncValue.data(TaxThermometerResult(currentTurnover: 0))),
          taxEstimationProvider.overrideWith((ref) => AsyncValue.data(TaxEstimationModel.empty())),
          upcomingTaxDeadlinesProvider.overrideWith((ref) => []),
        ],
      );
      addTearDown(container.dispose);

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

      final router = container.read(routerProvider);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));
      expect(router.state.uri.path, '/splash');

      await tester.pumpWidget(const SizedBox.shrink());
      // Let any delayed flutter_animate timers fire to avoid timersPending at teardown.
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
    });

    testWidgets('Redirects to /onboarding when not seen', (tester) async {
      tester.view.physicalSize = const Size(1000, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider
              .overrideWithValue(MockAuthRepository(Stream.value(null))),
          authStateProvider.overrideWith((ref) => Stream.value(null)),
            onboardingProvider
              .overrideWith((ref) => OnboardingNotifier.test(ref, seen: false)),
          initializationServiceProvider
              .overrideWith((ref) => TestInitializationService(ref)),
          firebaseAnalyticsProvider.overrideWithValue(mockAnalytics),
          analyticsServiceProvider
              .overrideWithValue(AnalyticsService(mockAnalytics)),
          notificationServiceProvider.overrideWithValue(FakeNotificationService()),
          monitoringServiceProvider.overrideWithValue(FakeMonitoringService()),
          expenseInsightsProvider.overrideWith((ref) => []),
          revenueMetricsProvider.overrideWith((ref) => Future.value(RevenueMetrics(totalRevenue: 0, thisMonthRevenue: 0, lastMonthRevenue: 0, unpaidAmount: 0, overdueCount: 0, averageInvoiceValue: 0))),
          profitMetricsProvider.overrideWith((ref) => Future.value(ProfitMetrics(profit: 0, profitMargin: 0, thisMonthProfit: 0))),
          taxThermometerProvider.overrideWith((ref) => AsyncValue.data(TaxThermometerResult(currentTurnover: 0))),
          taxEstimationProvider.overrideWith((ref) => AsyncValue.data(TaxEstimationModel.empty())),
          upcomingTaxDeadlinesProvider.overrideWith((ref) => []),
        ],
      );
      addTearDown(container.dispose);

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
      await tester.pump(const Duration(milliseconds: 50));

      final router = container.read(routerProvider);
      expect(router.state.uri.path, '/onboarding');

      await tester.pumpWidget(const SizedBox.shrink());
      // Let any delayed flutter_animate timers fire to avoid timersPending at teardown.
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
    });

    testWidgets(
        'Redirects to /login when not authenticated and seen onboarding',
        (tester) async {
      tester.view.physicalSize = const Size(1000, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider
              .overrideWithValue(MockAuthRepository(Stream.value(null))),
          authStateProvider.overrideWith((ref) => Stream.value(null)),
            onboardingProvider
              .overrideWith((ref) => OnboardingNotifier.test(ref, seen: true)),
          initializationServiceProvider
              .overrideWith((ref) => TestInitializationService(ref)),
          firebaseAnalyticsProvider.overrideWithValue(mockAnalytics),
          analyticsServiceProvider
              .overrideWithValue(AnalyticsService(mockAnalytics)),
          notificationServiceProvider.overrideWithValue(FakeNotificationService()),
          monitoringServiceProvider.overrideWithValue(FakeMonitoringService()),
          expenseInsightsProvider.overrideWith((ref) => []),
          revenueMetricsProvider.overrideWith((ref) => Future.value(RevenueMetrics(totalRevenue: 0, thisMonthRevenue: 0, lastMonthRevenue: 0, unpaidAmount: 0, overdueCount: 0, averageInvoiceValue: 0))),
          profitMetricsProvider.overrideWith((ref) => Future.value(ProfitMetrics(profit: 0, profitMargin: 0, thisMonthProfit: 0))),
          taxThermometerProvider.overrideWith((ref) => AsyncValue.data(TaxThermometerResult(currentTurnover: 0))),
          taxEstimationProvider.overrideWith((ref) => AsyncValue.data(TaxEstimationModel.empty())),
          upcomingTaxDeadlinesProvider.overrideWith((ref) => []),
        ],
      );
      addTearDown(container.dispose);

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
      await tester.pump(const Duration(milliseconds: 50));

      final router = container.read(routerProvider);
      expect(router.state.uri.path, '/login');

      await tester.pumpWidget(const SizedBox.shrink());
      // Let any delayed flutter_animate timers fire to avoid timersPending at teardown.
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
    });

    testWidgets('Redirects to /dashboard when authenticated', (tester) async {
      tester.view.physicalSize = const Size(1000, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const user = UserModel(id: '123', email: 'test@test.com');
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider
              .overrideWithValue(MockAuthRepository(Stream.value(user))),
          authStateProvider.overrideWith((ref) => Stream.value(user)),
            onboardingProvider
              .overrideWith((ref) => OnboardingNotifier.test(ref, seen: true)),
          initializationServiceProvider
              .overrideWith((ref) => TestInitializationService(ref)),
          invoicesProvider.overrideWith((ref) => Stream.value([])),
          expensesProvider.overrideWith((ref) => Stream.value([])),
          settingsProvider
              .overrideWith((ref) => Stream.value(UserSettingsModel.empty())),
          firebaseAnalyticsProvider.overrideWithValue(mockAnalytics),
          analyticsServiceProvider
              .overrideWithValue(AnalyticsService(mockAnalytics)),
          notificationServiceProvider.overrideWithValue(FakeNotificationService()),
          monitoringServiceProvider.overrideWithValue(FakeMonitoringService()),
          expenseInsightsProvider.overrideWith((ref) => []),
          revenueMetricsProvider.overrideWith((ref) => Future.value(RevenueMetrics(totalRevenue: 0, thisMonthRevenue: 0, lastMonthRevenue: 0, unpaidAmount: 0, overdueCount: 0, averageInvoiceValue: 0))),
          profitMetricsProvider.overrideWith((ref) => Future.value(ProfitMetrics(profit: 0, profitMargin: 0, thisMonthProfit: 0))),
          taxThermometerProvider.overrideWith((ref) => AsyncValue.data(TaxThermometerResult(currentTurnover: 0))),
          taxEstimationProvider.overrideWith((ref) => AsyncValue.data(TaxEstimationModel.empty())),
          upcomingTaxDeadlinesProvider.overrideWith((ref) => []),
        ],
      );
      addTearDown(container.dispose);

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
      await tester.pump(const Duration(milliseconds: 50));

      final router = container.read(routerProvider);
      expect(router.state.uri.path, '/dashboard');

      await tester.pumpWidget(const SizedBox.shrink());
      // Let any delayed flutter_animate timers fire to avoid timersPending at teardown.
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
    });
  });
}
