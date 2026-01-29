import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bizagent/features/billing/subscription_guard.dart';
import 'package:bizagent/features/billing/billing_service.dart';
import 'package:bizagent/features/entitlements/user_entitlements.dart';
import 'package:bizagent/features/limits/usage_limiter.dart';

void main() {
  late UsageLimiter testLimiter;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    testLimiter = UsageLimiter(prefs);
  });

  ProviderContainer containerFor(BillingState state) {
    return ProviderContainer(
      overrides: [
        billingProvider.overrideWith((ref) => BillingService.forTest(state, testLimiter)),
      ],
    );
  }

  group('SubscriptionGuard', () {
    test('canWatchCompanies false for free', () {
      final state = BillingState(
        entitlements: UserEntitlements.free(),
      );
      final container = containerFor(state);
      addTearDown(container.dispose);

      final guard = container.read(subscriptionGuardProvider);
      expect(guard.canWatchCompanies, isFalse);
    });

    test('canWatchCompanies true for pro', () {
      final state = BillingState(
        entitlements: UserEntitlements(isPro: true),
      );
      final container = containerFor(state);
      addTearDown(container.dispose);

      final guard = container.read(subscriptionGuardProvider);
      expect(guard.canWatchCompanies, isTrue);
    });

    test('getUpgradeMessage returns correct messages', () {
      final state = BillingState(entitlements: UserEntitlements.free());
      final container = containerFor(state);
      addTearDown(container.dispose);

      final guard = container.read(subscriptionGuardProvider);
      expect(
        guard.getUpgradeMessage(BizFeature.createInvoice),
        contains('limit faktúr'),
      );
      expect(
        guard.getUpgradeMessage(BizFeature.exportExcel),
        contains('Excel'),
      );
      expect(
        guard.getUpgradeMessage(BizFeature.aiAnalysis),
        contains('prémiová'),
      );
    });

    // Documented: canAccess(aiAnalysis) for free tier returns true when aiRequestsCount < 1
    // (0 = has 1 request left). Skipped until BizRemoteConfig is mockable.
    test('canAccess aiAnalysis free user with 0 requests returns true', () {
      final state = BillingState(
        entitlements: UserEntitlements.free().copyWith(aiRequestsCount: 0),
      );
      final container = containerFor(state);
      addTearDown(container.dispose);
      final guard = container.read(subscriptionGuardProvider);
      expect(guard.canAccess(BizFeature.aiAnalysis), isTrue);
    }, skip: 'canAccess uses BizRemoteConfig (Firebase); enable when mocked');
  });
}
