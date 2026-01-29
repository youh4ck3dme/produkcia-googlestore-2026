import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final analyticsServiceProvider =
    Provider((ref) => AnalyticsService(FirebaseAnalytics.instance));

class AnalyticsService {
  final FirebaseAnalytics _analytics;

  AnalyticsService(this._analytics);

  // Generic log method
  Future<void> logEvent(String name, {Map<String, dynamic>? parameters}) async {
    await _analytics.logEvent(
      name: name,
      parameters: parameters?.cast<String, Object>(),
    );
  }

  // Scan Funnel
  Future<void> logScanStarted() async {
    await logEvent('scan_started');
  }

  Future<void> logScanSuccess(String vendor) async {
    await logEvent('scan_success', parameters: {'vendor': vendor});
  }

  Future<void> logExpenseCreated(double amount, String category) async {
    await logEvent('expense_created', parameters: {
      'amount': amount,
      'category': category,
    });
  }

  // Invoice Funnel
  Future<void> logInvoiceCreated(double amount) async {
    await logEvent('invoice_created', parameters: {'amount': amount});
  }

  Future<void> logQrShared() async {
    await logEvent('qr_shared');
  }

  // Onboarding Funnel
  Future<void> logOnboardingSeen() async {
    await logEvent('onboarding_seen');
  }

  Future<void> logOnboardingStarted() async {
    await logEvent('onboarding_started');
  }

  Future<void> logOnboardingCompleted() async {
    await logEvent('onboarding_completed');
  }

  Future<void> logTryWithoutRegistration() async {
    await logEvent('try_no_reg');
  }

  // Voice Expense Funnel
  Future<void> logVoiceExpenseStarted() async {
    await logEvent('voice_expense_started');
  }

  Future<void> logVoiceExpenseCompleted({required bool success}) async {
    await logEvent('voice_expense_completed', parameters: {'success': success});
  }

  // App Lifecycle
  Future<void> logAppOpen() async {
    await _analytics.logAppOpen();
  }
}
