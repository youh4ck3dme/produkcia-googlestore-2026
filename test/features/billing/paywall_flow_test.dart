import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bizagent/features/billing/billing_copy.dart';
import 'package:bizagent/features/billing/billing_service.dart';
import 'package:bizagent/features/billing/paywall_flow.dart';
import 'package:bizagent/features/billing/subscription_guard.dart';
import 'package:bizagent/features/entitlements/user_entitlements.dart';
import 'package:bizagent/features/limits/usage_limiter.dart';

import '../../helpers/fake_biz_remote_config.dart';
import '../../helpers/test_app.dart';

void main() {
  late UsageLimiter testLimiter;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    testLimiter = UsageLimiter(prefs);
  });

  setUp(() {
    FakeBizRemoteConfig.install(showPaywallOnLimit: true, invoiceLimit: 3);
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

  BillingState freeAtInvoiceLimit() {
    return BillingState(
      entitlements: UserEntitlements(
        invoiceCount: 3,
        aiRequestsCount: 0,
      ),
    );
  }

  BillingState proUser() {
    return BillingState(
      entitlements: UserEntitlements(isPro: true),
    );
  }

  group('PaywallFlow / SubscriptionGuard UX', () {
    test('free user at invoice limit triggers paywall UI flag', () {
      final guard = guardFor(freeAtInvoiceLimit());

      expect(guard.canAccess(BizFeature.createInvoice), isFalse);
      expect(guard.shouldShowPaywallUi(BizFeature.createInvoice), isTrue);
    });

    test('pro user has no paywall for export', () {
      final guard = guardFor(proUser());

      expect(guard.canAccess(BizFeature.exportExcel), isTrue);
      expect(guard.shouldShowPaywallUi(BizFeature.exportExcel), isFalse);
    });

    test('experiment off allows invoice without paywall UI', () {
      FakeBizRemoteConfig.install(showPaywallOnLimit: false, invoiceLimit: 3);
      final guard = guardFor(freeAtInvoiceLimit());

      expect(guard.canAccess(BizFeature.createInvoice), isTrue);
      expect(guard.shouldShowPaywallUi(BizFeature.createInvoice), isFalse);
    });
  });

  group('FeaturePaywallSheet widget', () {
    testWidgets('locked export shows reason and Pro CTA', (tester) async {
      await tester.pumpWidget(
        testApp(
          child: Builder(
            builder: (ctx) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => PaywallFlow.showFeaturePaywall(
                    ctx,
                    feature: BizFeature.exportExcel,
                    reason: BillingCopy.exportLocked,
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Export'), findsOneWidget);
      expect(find.text(BillingCopy.exportLocked), findsOneWidget);
      expect(find.text(BillingCopy.ctaUpgrade), findsOneWidget);
      expect(find.text(BillingCopy.ctaLater), findsOneWidget);
      expect(find.textContaining(BillingCopy.sheetUnlocksTitle), findsOneWidget);
    });
  });
}
