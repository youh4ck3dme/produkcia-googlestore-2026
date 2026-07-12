import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

import 'package:bizagent/core/router/app_router.dart';
import 'package:bizagent/core/services/analytics_service.dart';
import 'package:bizagent/core/services/initialization_service.dart';
import 'package:bizagent/core/i18n/l10n.dart';
import 'package:bizagent/core/supabase/supabase_config.dart';
import 'package:bizagent/features/auth/providers/auth_repository.dart';
import 'package:bizagent/features/intro/providers/onboarding_provider.dart';
import 'package:bizagent/features/invoices/providers/invoices_provider.dart';
import 'package:bizagent/features/expenses/providers/expenses_provider.dart';
import 'package:bizagent/features/settings/providers/settings_provider.dart';
import 'package:bizagent/features/settings/models/user_settings_model.dart';
import 'package:bizagent/features/dashboard/screens/dashboard_screen.dart';
import 'package:bizagent/features/auth/screens/firebase_login_screen.dart';
import 'package:bizagent/features/notifications/services/notification_service.dart';
import 'package:bizagent/features/tools/services/monitoring_service.dart';
import 'package:bizagent/features/analytics/providers/expense_insights_provider.dart';
import 'package:bizagent/features/dashboard/providers/revenue_provider.dart';
import 'package:bizagent/features/dashboard/providers/profit_provider.dart';
import 'package:bizagent/features/tax/providers/tax_thermometer_service.dart';
import 'package:bizagent/features/tax/providers/tax_estimation_service.dart';
import 'package:bizagent/features/tax/providers/tax_provider.dart';

import '../helpers/fake_monitoring_service.dart';
import '../helpers/fake_notification_service.dart';
import '../core/router/app_router_test.dart' show MockFirebaseAnalytics, TestInitializationService;

/// Live smoke: Supabase signIn → router presmeruje na dashboard.
@Tags(['live', 'smoke'])
void main() {
  final email = const String.fromEnvironment(
    'PLAY_SMOKE_EMAIL',
    defaultValue: 'bizagent@bizagent.sk',
  );
  late String password;
  late MockFirebaseAnalytics mockAnalytics;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await SupabaseConfig.initialize();
    mockAnalytics = MockFirebaseAnalytics();

    password = const String.fromEnvironment('PLAY_SMOKE_PASSWORD');
    if (password.isEmpty) {
      final file = File('.play_reviewer_password');
      if (file.existsSync()) {
        password = file.readAsStringSync().trim();
      }
    }
  });

  testWidgets('live login → dashboard home', (tester) async {
    if (!SupabaseConfig.isConfigured) {
      return;
    }
    if (password.isEmpty) {
      return;
    }
    if (!SupabaseConfig.isReady) {
      fail('Supabase nie je inicializovaný');
    }

    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final container = ProviderContainer(
      overrides: [
        onboardingProvider.overrideWith(() => OnboardingNotifier.test(seen: true)),
        initializationServiceProvider.overrideWith(() => TestInitializationService()),
        invoicesProvider.overrideWith((ref) => Stream.value([])),
        expensesProvider.overrideWith((ref) => Stream.value([])),
        settingsProvider.overrideWith((ref) => Stream.value(UserSettingsModel.empty())),
        firebaseAnalyticsProvider.overrideWithValue(mockAnalytics),
        analyticsServiceProvider.overrideWithValue(AnalyticsService(mockAnalytics)),
        notificationServiceProvider.overrideWithValue(FakeNotificationService()),
        monitoringServiceProvider.overrideWithValue(FakeMonitoringService()),
        expenseInsightsProvider.overrideWith((ref) => []),
        revenueMetricsProvider.overrideWith(
          (ref) => Future.value(RevenueMetrics(
            totalRevenue: 0,
            thisMonthRevenue: 0,
            lastMonthRevenue: 0,
            unpaidAmount: 0,
            overdueCount: 0,
            averageInvoiceValue: 0,
          )),
        ),
        profitMetricsProvider.overrideWith(
          (ref) => Future.value(ProfitMetrics(profit: 0, profitMargin: 0, thisMonthProfit: 0)),
        ),
        taxThermometerProvider.overrideWith(
          (ref) => AsyncValue.data(TaxThermometerResult(currentTurnover: 0)),
        ),
        taxEstimationProvider.overrideWith(
          (ref) => AsyncValue.data(TaxEstimationModel.empty()),
        ),
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

    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
      if (find.byType(FirebaseLoginScreen).evaluate().isNotEmpty) break;
    }
    expect(find.byType(FirebaseLoginScreen), findsOneWidget);

    final user = await container.read(authRepositoryProvider).signIn(email, password);
    expect(user, isNotNull);

    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 500));
      if (find.byType(DashboardScreen).evaluate().isNotEmpty) break;
    }

    expect(find.byType(DashboardScreen), findsOneWidget);
    expect(find.byType(FirebaseLoginScreen), findsNothing);
  });
}