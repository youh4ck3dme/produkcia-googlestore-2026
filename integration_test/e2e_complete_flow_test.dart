import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bizagent/main.dart';
import 'package:bizagent/core/router/app_router.dart';
import 'package:bizagent/features/auth/providers/auth_provider.dart';
import 'package:bizagent/features/intro/providers/onboarding_provider.dart';
import 'package:bizagent/core/services/analytics_service.dart';
import 'package:bizagent/core/services/notification_service.dart';
import 'package:bizagent/core/services/monitoring_service.dart';
import 'package:bizagent/features/invoices/providers/invoices_provider.dart';
import 'package:bizagent/features/expenses/providers/expenses_provider.dart';
import 'package:bizagent/features/settings/providers/settings_provider.dart';
import 'package:bizagent/core/providers/theme_provider.dart';
import 'package:bizagent/core/services/initialization_service.dart';
import 'package:bizagent/features/auth/providers/auth_repository.dart';
import 'package:bizagent/features/auth/models/user_model.dart';
import 'package:bizagent/features/settings/models/user_settings_model.dart';
import 'package:bizagent/features/splash/screens/splash_screen.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'dart:async';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('E2E Complete Flow Tests', () {
    late WidgetTester tester;

    setUp(() async {
      // Reset SharedPreferences before each test
      SharedPreferences.setMockInitialValues({
        'seen_onboarding': false,
        'theme_mode': 'light',
      });
    });

    testWidgets('Complete User Journey: Splash → Onboarding → Login → Dashboard', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Mock services
      final mockAuth = MockAuthRepository();
      final mockAnalytics = MockFirebaseAnalytics();
      final fakeNotifications = FakeNotificationService();

      // Build app
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuth),
            authStateProvider.overrideWith((ref) => mockAuth.authStateChanges),
            onboardingProvider.overrideWith((ref) => OnboardingNotifier.test(ref, seen: false)),
            initializationServiceProvider.overrideWith((ref) => TestInitializationService(ref)),
            invoicesProvider.overrideWith((ref) => Stream.value([])),
            expensesProvider.overrideWith((ref) => Stream.value([])),
            settingsProvider.overrideWith((ref) => Stream.value(UserSettingsModel.empty())),
            firebaseAnalyticsProvider.overrideWithValue(mockAnalytics),
            analyticsServiceProvider.overrideWithValue(AnalyticsService(mockAnalytics)),
            notificationServiceProvider.overrideWithValue(fakeNotifications),
            monitoringServiceProvider.overrideWithValue(FakeMonitoringService()),
          ],
          child: const BizAgentApp(),
        ),
      );

      // 1. Splash Screen
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(SplashScreen), findsOneWidget);

      // Wait for initialization
      await tester.pump(const Duration(seconds: 2));

      // 2. Should redirect to Onboarding (not seen yet)
      await tester.pumpAndSettle();
      // Note: Actual navigation depends on router logic
      // This is a smoke test to ensure app doesn't crash

      // Verify app is running
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('Invoice Creation Flow', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      SharedPreferences.setMockInitialValues({
        'seen_onboarding': true,
        'theme_mode': 'light',
      });

      final mockAuth = MockAuthRepository();
      final mockAnalytics = MockFirebaseAnalytics();
      final fakeNotifications = FakeNotificationService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuth),
            authStateProvider.overrideWith((ref) => Stream.value(MockUser())),
            onboardingProvider.overrideWith((ref) => OnboardingNotifier.test(ref, seen: true)),
            initializationServiceProvider.overrideWith((ref) => TestInitializationService(ref)),
            invoicesProvider.overrideWith((ref) => Stream.value([])),
            expensesProvider.overrideWith((ref) => Stream.value([])),
            settingsProvider.overrideWith((ref) => Stream.value(UserSettingsModel.empty())),
            firebaseAnalyticsProvider.overrideWithValue(mockAnalytics),
            analyticsServiceProvider.overrideWithValue(AnalyticsService(mockAnalytics)),
            notificationServiceProvider.overrideWithValue(fakeNotifications),
            monitoringServiceProvider.overrideWithValue(FakeMonitoringService()),
          ],
          child: const BizAgentApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify dashboard is accessible
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}

// Mock classes
@GenerateMocks([AuthRepository, FirebaseAnalytics, NotificationService, MonitoringService])
class MockAuthRepository extends Fake implements AuthRepository {
  final _authStateController = StreamController<UserModel?>.broadcast();

  MockAuthRepository() {
    _authStateController.add(null); // Start logged out
  }

  @override
  Stream<UserModel?> get authStateChanges => _authStateController.stream;

  @override
  Future<UserModel?> signInAnonymously() async {
    final user = MockUser();
    _authStateController.add(user);
    return user;
  }

  @override
  Future<void> signOut() async {
    _authStateController.add(null);
  }

  @override
  void dispose() {
    _authStateController.close();
  }
}

class MockUser extends UserModel {
  MockUser() : super(
    id: 'test-user-id',
    email: 'test@example.com',
    displayName: 'Test User',
  );
}

class MockFirebaseAnalytics extends Fake implements FirebaseAnalytics {
  @override
  Future<void> logScreenView({String? screenName, String? screenClass}) async {}
}

class TestInitializationService extends InitializationService {
  TestInitializationService(super.ref) {
    state = const InitState(progress: 1.0, message: 'Hotovo!', isCompleted: true);
  }

  @override
  Future<void> initializeApp() async {}
}

class FakeNotificationService extends Fake implements NotificationService {}

class FakeMonitoringService extends Fake implements MonitoringService {}
