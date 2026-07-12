import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  group('BillingService dispose', () {
    test('forTest dispose does not throw', () {
      final container = ProviderContainer(
        overrides: [
          billingProvider.overrideWith(
            () => BillingService.forTest(
              BillingState(entitlements: UserEntitlements.free()),
              testLimiter,
            ),
          ),
        ],
      );

      container.read(billingProvider);
      expect(() => container.dispose(), returnsNormally);
    });

    test('production dispose before _init completes does not throw', () {
      final container = ProviderContainer(
        overrides: [
          usageLimiterProvider.overrideWithValue(testLimiter),
        ],
      );

      container.read(billingProvider);
      expect(() => container.dispose(), returnsNormally);
    });
  });
}
