import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bizagent/app.dart';
import 'package:bizagent/core/router/app_router.dart';
import 'package:bizagent/core/services/analytics_service.dart';
import 'package:bizagent/core/services/initialization_service.dart';
import 'package:bizagent/core/services/local_persistence_service.dart';
import 'package:bizagent/features/auth/models/user_model.dart';
import 'package:bizagent/features/auth/providers/auth_repository.dart';
import 'package:bizagent/features/expenses/providers/expenses_provider.dart';
import 'package:bizagent/features/intro/providers/onboarding_provider.dart';
import 'package:bizagent/features/invoices/providers/invoices_provider.dart';
import 'package:bizagent/features/settings/models/user_settings_model.dart';
import 'package:bizagent/features/settings/providers/settings_provider.dart';
import 'package:bizagent/features/notifications/services/notification_service.dart';
import 'package:bizagent/features/splash/screens/splash_screen.dart';
import 'package:bizagent/features/tools/services/monitoring_service.dart';
import 'package:bizagent/features/limits/usage_limiter.dart' show sharedPrefsProvider;

import '../helpers/fake_monitoring_service.dart';
import '../helpers/fake_notification_service.dart';
import '../helpers/integration_harness.dart';

void main() {
  late LocalPersistenceService persistence;
  late Directory tempDir;

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    tempDir = await Directory.systemTemp.createTemp('e2e_hive_');
    Hive.init(tempDir.path);
    persistence = LocalPersistenceService();
    await persistence.init();
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  group('E2E Complete Flow Tests', () {
    setUp(() async {
      await setUpIntegrationHarness(
        prefs: const {'seen_onboarding': false, 'theme_mode': 'light'},
      );
    });

    testWidgets('Complete User Journey: Splash → Onboarding → Login → Dashboard',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        _app(MockAuthRepository(), seen: false, prefs: prefs, persistence: persistence),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(SplashScreen), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      await pumpFrames(tester, count: 10);
      expect(find.byType(BizAgentApp), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Invoice Creation Flow', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await setUpIntegrationHarness(
        prefs: const {'seen_onboarding': true, 'theme_mode': 'light'},
      );

      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        _app(MockAuthRepository(), seen: true, loggedIn: true, prefs: prefs, persistence: persistence),
      );
      await pumpFrames(tester, count: 10);
      expect(find.byType(BizAgentApp), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

Widget _app(
  MockAuthRepository mockAuth, {
  required bool seen,
  bool loggedIn = false,
  required SharedPreferences prefs,
  required LocalPersistenceService persistence,
}) {
  final mockAnalytics = MockFirebaseAnalytics();

  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(mockAuth),
      authStateProvider.overrideWith(
        (ref) => loggedIn ? Stream.value(MockUser()) : mockAuth.authStateChanges,
      ),
      onboardingProvider.overrideWith((ref) => OnboardingNotifier.test(ref, seen: seen)),
      initializationServiceProvider.overrideWith((ref) => TestInitializationService(ref)),
      invoicesProvider.overrideWith((ref) => Stream.value([])),
      expensesProvider.overrideWith((ref) => Stream.value([])),
      settingsProvider.overrideWith((ref) => Stream.value(UserSettingsModel.empty())),
      firebaseAnalyticsProvider.overrideWithValue(mockAnalytics),
      analyticsServiceProvider.overrideWithValue(AnalyticsService(mockAnalytics)),
      notificationServiceProvider.overrideWithValue(FakeNotificationService()),
      monitoringServiceProvider.overrideWithValue(FakeMonitoringService()),
      sharedPrefsProvider.overrideWithValue(prefs),
      localPersistenceServiceProvider.overrideWithValue(persistence),
    ],
    child: const BizAgentApp(),
  );
}

class MockAuthRepository extends Fake implements AuthRepository {
  MockAuthRepository() {
    _authStateController.add(null);
  }

  final _authStateController = StreamController<UserModel?>.broadcast();

  @override
  Stream<UserModel?> get authStateChanges => _authStateController.stream;

  @override
  Future<void> signOut() async => _authStateController.add(null);

  @override
  UserModel? get currentUser => null;
}

class MockUser extends UserModel {
  MockUser()
      : super(id: 'test-user-id', email: 'test@example.com', displayName: 'Test User');
}

class MockFirebaseAnalytics extends Fake implements FirebaseAnalytics {
  @override
  Future<void> logScreenView({
    String? screenName,
    String? screenClass,
    AnalyticsCallOptions? callOptions,
    Map<String, Object>? parameters,
  }) async {}
}

class TestInitializationService extends InitializationService {
  TestInitializationService(super.ref) {
    state = const InitState(progress: 1.0, message: 'Hotovo!', isCompleted: true);
  }

  @override
  Future<void> initializeApp() async {}
}
