import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bizagent/app.dart';
import 'package:bizagent/features/auth/providers/auth_repository.dart';
import 'package:bizagent/features/auth/models/user_model.dart';
import 'package:bizagent/features/intro/providers/onboarding_provider.dart';
import 'package:bizagent/features/invoices/providers/invoices_provider.dart';
import 'package:bizagent/features/expenses/providers/expenses_provider.dart';
import 'package:bizagent/features/settings/providers/settings_provider.dart';
import 'package:bizagent/features/settings/models/user_settings_model.dart';
import 'package:bizagent/core/services/analytics_service.dart';
import 'package:bizagent/core/router/app_router.dart';
import 'package:bizagent/core/services/initialization_service.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:bizagent/features/notifications/services/notification_service.dart';
import 'package:bizagent/features/tools/services/monitoring_service.dart';
import 'dart:async';

class MockAuthRepository implements AuthRepository {
  @override
  UserModel? get currentUser =>
      const UserModel(id: '123', email: 'test@test.com');

  @override
  late final Stream<UserModel?> authStateChanges;

  @override
  Future<String?> get currentUserToken async => 'fake-token-123';

  MockAuthRepository() {
    authStateChanges = Stream.value(currentUser);
  }

  @override
  Future<UserModel?> signIn(String email, String password) async => currentUser;
  @override
  Future<UserModel?> signUp(String email, String password) async => currentUser;
  @override
  Future<UserModel?> signInWithGoogle() async => currentUser;
  @override
  Future<UserModel?> signInAnonymously() async => currentUser;
  @override
  Future<void> signOut() async {}
  @override
  void dispose() {}
}

class MockFirebaseAnalytics extends Fake implements FirebaseAnalytics {
  @override
  Future<void> logEvent(
      {required String name,
      Map<String, Object?>? parameters,
      AnalyticsCallOptions? callOptions}) async {}
  @override
  Future<void> logAppOpen(
      {Map<String, Object?>? parameters,
      AnalyticsCallOptions? callOptions}) async {}
  @override
  Future<void> logScreenView(
      {String? screenClass,
      String? screenName,
      Map<String, Object?>? parameters,
      AnalyticsCallOptions? callOptions}) async {}
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
  Stream<List<Map<String, dynamic>>> notifications() {
    return Stream.value([]);
  }
  
  @override
  Future<void> markAsRead(String id) async {}
  
  @override
  Future<void> markAllAsRead() async {}
}

class TestInitializationService extends InitializationService {
  TestInitializationService(super.ref) {
    state = const InitState(progress: 1.0, message: 'Hotovo!', isCompleted: true);
  }

  @override
  Future<void> initializeApp() async {}
}

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    SharedPreferences.setMockInitialValues({
      'seen_onboarding': true,
      // Prevent TutorialService from showing an overlay during tests.
      'hasSeenTutorial_123': true,
    });
    final mockAuth = MockAuthRepository();
    final mockAnalytics = MockFirebaseAnalytics();
    final fakeNotifications = FakeNotificationService();

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuth),
          authStateProvider.overrideWith((ref) => mockAuth.authStateChanges),
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
          notificationServiceProvider.overrideWithValue(fakeNotifications),
          monitoringServiceProvider.overrideWithValue(FakeMonitoringService()),
        ],
        child: const BizAgentApp(),
      ),
    );

    // Initial pump for Splash
    await tester.pump();
    // Allow for redirect to Dashboard
    await tester.pump(const Duration(milliseconds: 100));
    // Dashboard has shimmer animation which is infinite, use pump(Duration)
    await tester.pump(const Duration(seconds: 2));

    // Verify that the dashboard app bar is shown (stable signal).
    expect(find.byIcon(Icons.logout), findsOneWidget);
  });
}
