import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bizagent/core/config.dart';
import 'package:bizagent/features/billing/billing_copy.dart';
import 'package:bizagent/features/billing/subscription_guard.dart';
import 'package:bizagent/features/billing/billing_service.dart';
import 'package:bizagent/features/entitlements/user_entitlements.dart';
import 'package:bizagent/features/limits/usage_limiter.dart';
import '../../helpers/fake_biz_remote_config.dart';

void main() {
  late UsageLimiter testLimiter;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    testLimiter = UsageLimiter(prefs);
  });

  setUp(() {
    FakeBizRemoteConfig.install();
  });

  tearDown(() {
    FakeBizRemoteConfig.reset();
  });

  ProviderContainer containerFor(BillingState state) {
    return ProviderContainer(
      overrides: [
        billingProvider.overrideWith((ref) => BillingService.forTest(state, testLimiter)),
      ],
    );
  }

  SubscriptionGuard guardFor(BillingState state) {
    final container = containerFor(state);
    addTearDown(container.dispose);
    return container.read(subscriptionGuardProvider);
  }

  group('SubscriptionGuard', () {
    group('canWatchCompanies', () {
      test('false for free', () {
        final guard = guardFor(BillingState(entitlements: UserEntitlements.free()));
        expect(guard.canWatchCompanies, isFalse);
      });

      test('true for pro', () {
        final guard = guardFor(
          BillingState(entitlements: const UserEntitlements(isPro: true)),
        );
        expect(guard.canWatchCompanies, isTrue);
      });
    });

    group('canAccess — free tier', () {
      test('createInvoice allowed under monthly limit', () {
        final guard = guardFor(
          BillingState(
            entitlements: UserEntitlements.free().copyWith(invoiceCount: 2),
          ),
        );
        expect(guard.canAccess(BizFeature.createInvoice), isTrue);
      });

      test('createInvoice locked at monthly limit', () {
        final guard = guardFor(
          BillingState(
            entitlements: UserEntitlements.free().copyWith(
              invoiceCount: BizConfig.freeInvoiceLimitMonthly,
            ),
          ),
        );
        expect(guard.canAccess(BizFeature.createInvoice), isFalse);
      });

      test('aiAnalysis allowed with remaining free request', () {
        final guard = guardFor(
          BillingState(
            entitlements: UserEntitlements.free().copyWith(aiRequestsCount: 0),
          ),
        );
        expect(guard.canAccess(BizFeature.aiAnalysis), isTrue);
      });

      test('aiAnalysis locked after free request used', () {
        final guard = guardFor(
          BillingState(
            entitlements: UserEntitlements.free().copyWith(aiRequestsCount: 1),
          ),
        );
        expect(guard.canAccess(BizFeature.aiAnalysis), isFalse);
      });

      test('exportExcel locked for free', () {
        final guard = guardFor(BillingState(entitlements: UserEntitlements.free()));
        expect(guard.canAccess(BizFeature.exportExcel), isFalse);
      });

      test('icoPremiumProfile locked for free', () {
        final guard = guardFor(BillingState(entitlements: UserEntitlements.free()));
        expect(guard.canAccess(BizFeature.icoPremiumProfile), isFalse);
      });
    });

    group('canAccess — trial (PRO / starter)', () {
      test('createInvoice and export allowed for starter plan', () {
        final guard = guardFor(
          BillingState(
            entitlements: const UserEntitlements(
              isPro: true,
              activePlanId: BizConfig.productOneTimeStarter,
            ),
          ),
        );
        expect(guard.canAccess(BizFeature.createInvoice), isTrue);
        expect(guard.canAccess(BizFeature.exportExcel), isTrue);
        expect(guard.canWatchCompanies, isTrue);
      });

      test('createInvoice allowed for pro trial with future expiry', () {
        final guard = guardFor(
          BillingState(
            entitlements: UserEntitlements(
              isPro: true,
              activePlanId: BizConfig.productProMonthly,
              expiryDate: DateTime.now().add(const Duration(days: 7)),
            ),
          ),
        );
        expect(guard.canAccess(BizFeature.createInvoice), isTrue);
      });
    });

    group('canAccess — paid subscription', () {
      test('pro unlocks premium features regardless of usage counters', () {
        final guard = guardFor(
          BillingState(
            entitlements: const UserEntitlements(
              isPro: true,
              activePlanId: BizConfig.productProYearly,
              invoiceCount: 99,
              aiRequestsCount: 99,
            ),
          ),
        );
        expect(guard.canAccess(BizFeature.createInvoice), isTrue);
        expect(guard.canAccess(BizFeature.exportExcel), isTrue);
        expect(guard.canAccess(BizFeature.icoPremiumProfile), isTrue);
      });

      test('business unlocks all features', () {
        final guard = guardFor(
          BillingState(
            entitlements: const UserEntitlements(
              isBusiness: true,
              isPro: true,
              activePlanId: BizConfig.productBusinessMonthly,
            ),
          ),
        );
        expect(guard.canAccess(BizFeature.createInvoice), isTrue);
        expect(guard.canAccess(BizFeature.aiAnalysis), isTrue);
        expect(guard.canAccess(BizFeature.icoPremiumProfile), isTrue);
      });
    });

    group('canAccess — paywall experiment off', () {
      test('createInvoice not locked at limit when showPaywallOnLimit is false', () {
        FakeBizRemoteConfig.install(showPaywallOnLimit: false);
        final guard = guardFor(
          BillingState(
            entitlements: UserEntitlements.free().copyWith(
              invoiceCount: BizConfig.freeInvoiceLimitMonthly,
            ),
          ),
        );
        expect(guard.canAccess(BizFeature.createInvoice), isTrue);
      });

      test('createInvoice still locked at limit when experiment is on', () {
        FakeBizRemoteConfig.install(showPaywallOnLimit: true);
        final guard = guardFor(
          BillingState(
            entitlements: UserEntitlements.free().copyWith(
              invoiceCount: BizConfig.freeInvoiceLimitMonthly,
            ),
          ),
        );
        expect(guard.canAccess(BizFeature.createInvoice), isFalse);
      });
    });

    test('getUpgradeMessage returns correct messages', () {
      final guard = guardFor(BillingState(entitlements: UserEntitlements.free()));
      expect(guard.getUpgradeMessage(BizFeature.createInvoice), BillingCopy.invoiceLimit);
      expect(guard.getUpgradeMessage(BizFeature.exportExcel), BillingCopy.exportLocked);
      expect(guard.getUpgradeMessage(BizFeature.aiAnalysis), BillingCopy.aiLocked);
    });
  });
}
