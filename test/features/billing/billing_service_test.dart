import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:bizagent/features/billing/services/billing_service.dart';
import 'package:bizagent/features/billing/models/subscription.dart';
import 'package:bizagent/features/billing/models/usage.dart';

class MockBillingRepository extends Mock implements BillingRepository {
  @override
  Future<Subscription?> getCurrentSubscription(String userId) async {
    return super.noSuchMethod(
      Invocation.method(#getCurrentSubscription, [userId]),
      returnValue: null,
    );
  }

  @override
  Future<void> saveSubscription(Subscription subscription) async {
    return super.noSuchMethod(
      Invocation.method(#saveSubscription, [subscription]),
    );
  }

  @override
  Future<Usage> getUsage(String userId) async {
    return super.noSuchMethod(
      Invocation.method(#getUsage, [userId]),
      returnValue: Usage(
        invoiceCount: 0,
        expenseCount: 0,
        geminiUsage: 0,
        lastResetDate: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> updateUsage(String userId, Usage usage) async {
    return super.noSuchMethod(
      Invocation.method(#updateUsage, [userId, usage]),
    );
  }
}

void main() {
  group('BillingService', () {
    late MockBillingRepository mockBillingRepository;
    late BillingService billingService;

    setUp(() {
      mockBillingRepository = MockBillingRepository();
      billingService = BillingService(mockBillingRepository);
    });

    group('subscription status checks', () {
      test('should return null when no subscription exists', () async {
        // Arrange
        when(mockBillingRepository.getCurrentSubscription('user123'))
            .thenAnswer((_) async => null);

        // Act
        final result = await billingService.getCurrentSubscription('user123');

        // Assert
        expect(result, isNull);
      });

      test('should return subscription when it exists', () async {
        // Arrange
        final subscription = Subscription(
          id: 'sub_123',
          userId: 'user123',
          plan: SubscriptionPlan.premium,
          status: SubscriptionStatus.active,
          startDate: DateTime.now().subtract(Duration(days: 30)),
          endDate: DateTime.now().add(Duration(days: 30)),
          autoRenew: true,
        );

        when(mockBillingRepository.getCurrentSubscription('user123'))
            .thenAnswer((_) async => subscription);

        // Act
        final result = await billingService.getCurrentSubscription('user123');

        // Assert
        expect(result, equals(subscription));
      });

      test('should detect expired subscription', () async {
        // Arrange
        final expiredSubscription = Subscription(
          id: 'sub_123',
          userId: 'user123',
          plan: SubscriptionPlan.premium,
          status: SubscriptionStatus.active,
          startDate: DateTime.now().subtract(Duration(days: 60)),
          endDate: DateTime.now().subtract(Duration(days: 1)),
          autoRenew: false,
        );

        when(mockBillingRepository.getCurrentSubscription('user123'))
            .thenAnswer((_) async => expiredSubscription);

        // Act
        final isExpired = await billingService.isSubscriptionExpired('user123');

        // Assert
        expect(isExpired, isTrue);
      });

      test('should detect active subscription', () async {
        // Arrange
        final activeSubscription = Subscription(
          id: 'sub_123',
          userId: 'user123',
          plan: SubscriptionPlan.premium,
          status: SubscriptionStatus.active,
          startDate: DateTime.now().subtract(Duration(days: 30)),
          endDate: DateTime.now().add(Duration(days: 30)),
          autoRenew: true,
        );

        when(mockBillingRepository.getCurrentSubscription('user123'))
            .thenAnswer((_) async => activeSubscription);

        // Act
        final isExpired = await billingService.isSubscriptionExpired('user123');

        // Assert
        expect(isExpired, isFalse);
      });
    });

    group('paywall display logic', () {
      test('should show paywall for free plan when feature requires premium', () async {
        // Arrange
        final freeSubscription = Subscription(
          id: 'sub_free',
          userId: 'user123',
          plan: SubscriptionPlan.free,
          status: SubscriptionStatus.active,
          startDate: DateTime.now().subtract(Duration(days: 30)),
          endDate: DateTime.now().add(Duration(days: 30)),
          autoRenew: true,
        );

        when(mockBillingRepository.getCurrentSubscription('user123'))
            .thenAnswer((_) async => freeSubscription);

        // Act
        final shouldShowPaywall = await billingService.shouldShowPaywall(
          'user123',
          BillingFeature.expenseIntelligence,
        );

        // Assert
        expect(shouldShowPaywall, isTrue);
      });

      test('should not show paywall for premium plan', () async {
        // Arrange
        final premiumSubscription = Subscription(
          id: 'sub_premium',
          userId: 'user123',
          plan: SubscriptionPlan.premium,
          status: SubscriptionStatus.active,
          startDate: DateTime.now().subtract(Duration(days: 30)),
          endDate: DateTime.now().add(Duration(days: 30)),
          autoRenew: true,
        );

        when(mockBillingRepository.getCurrentSubscription('user123'))
            .thenAnswer((_) async => premiumSubscription);

        // Act
        final shouldShowPaywall = await billingService.shouldShowPaywall(
          'user123',
          BillingFeature.expenseIntelligence,
        );

        // Assert
        expect(shouldShowPaywall, isFalse);
      });

      test('should show paywall when no subscription exists', () async {
        // Arrange
        when(mockBillingRepository.getCurrentSubscription('user123'))
            .thenAnswer((_) async => null);

        // Act
        final shouldShowPaywall = await billingService.shouldShowPaywall(
          'user123',
          BillingFeature.expenseIntelligence,
        );

        // Assert
        expect(shouldShowPaywall, isTrue);
      });

      test('should not show paywall for free features', () async {
        // Arrange
        when(mockBillingRepository.getCurrentSubscription('user123'))
            .thenAnswer((_) async => null);

        // Act
        final shouldShowPaywall = await billingService.shouldShowPaywall(
          'user123',
          BillingFeature.basicInvoices,
        );

        // Assert
        expect(shouldShowPaywall, isFalse);
      });
    });

    group('feature gating', () {
      test('should allow access to premium feature with active premium subscription', () async {
        // Arrange
        final premiumSubscription = Subscription(
          id: 'sub_premium',
          userId: 'user123',
          plan: SubscriptionPlan.premium,
          status: SubscriptionStatus.active,
          startDate: DateTime.now().subtract(Duration(days: 30)),
          endDate: DateTime.now().add(Duration(days: 30)),
          autoRenew: true,
        );

        when(mockBillingRepository.getCurrentSubscription('user123'))
            .thenAnswer((_) async => premiumSubscription);

        // Act
        final hasAccess = await billingService.hasFeatureAccess(
          'user123',
          BillingFeature.expenseIntelligence,
        );

        // Assert
        expect(hasAccess, isTrue);
      });

      test('should deny access to premium feature with free subscription', () async {
        // Arrange
        final freeSubscription = Subscription(
          id: 'sub_free',
          userId: 'user123',
          plan: SubscriptionPlan.free,
          status: SubscriptionStatus.active,
          startDate: DateTime.now().subtract(Duration(days: 30)),
          endDate: DateTime.now().add(Duration(days: 30)),
          autoRenew: true,
        );

        when(mockBillingRepository.getCurrentSubscription('user123'))
            .thenAnswer((_) async => freeSubscription);

        // Act
        final hasAccess = await billingService.hasFeatureAccess(
          'user123',
          BillingFeature.expenseIntelligence,
        );

        // Assert
        expect(hasAccess, isFalse);
      });

      test('should allow access to free features without subscription', () async {
        // Arrange
        when(mockBillingRepository.getCurrentSubscription('user123'))
            .thenAnswer((_) async => null);

        // Act
        final hasAccess = await billingService.hasFeatureAccess(
          'user123',
          BillingFeature.basicInvoices,
        );

        // Assert
        expect(hasAccess, isTrue);
      });
    });

    group('usage limits', () {
      test('should check usage limits for premium features', () async {
        // Arrange
        final usage = Usage(
          invoiceCount: 100,
          expenseCount: 50,
          geminiUsage: 10,
          lastResetDate: DateTime.now().subtract(Duration(days: 1)),
        );

        when(mockBillingRepository.getUsage('user123'))
            .thenAnswer((_) async => usage);

        // Act
        final isWithinLimits = await billingService.isWithinUsageLimits(
          'user123',
          BillingFeature.expenseIntelligence,
        );

        // Assert
        expect(isWithinLimits, isTrue);
      });

      test('should detect when usage limits are exceeded', () async {
        // Arrange
        final usage = Usage(
          invoiceCount: 1000, // Exceeds free plan limit
          expenseCount: 500,  // Exceeds free plan limit
          geminiUsage: 100,   // Exceeds free plan limit
          lastResetDate: DateTime.now().subtract(Duration(days: 1)),
        );

        when(mockBillingRepository.getUsage('user123'))
            .thenAnswer((_) async => usage);

        // Act
        final isWithinLimits = await billingService.isWithinUsageLimits(
          'user123',
          BillingFeature.expenseIntelligence,
        );

        // Assert
        expect(isWithinLimits, isFalse);
      });

      test('should reset usage tracking when subscription changes', () async {
        // Arrange
        final usage = Usage(
          invoiceCount: 100,
          expenseCount: 50,
          geminiUsage: 10,
          lastResetDate: DateTime.now().subtract(Duration(days: 30)),
        );

        when(mockBillingRepository.getUsage('user123'))
            .thenAnswer((_) async => usage);

        // Act
        await billingService.resetUsageTracking('user123');

        // Assert
        verify(mockBillingRepository.updateUsage(
          'user123',
          Usage(
            invoiceCount: 0,
            expenseCount: 0,
            geminiUsage: 0,
            lastResetDate: anyNamed('lastResetDate'),
          ),
        )).called(1);
      });
    });

    group('subscription management', () {
      test('should upgrade subscription', () async {
        // Arrange
        final currentSubscription = Subscription(
          id: 'sub_free',
          userId: 'user123',
          plan: SubscriptionPlan.free,
          status: SubscriptionStatus.active,
          startDate: DateTime.now().subtract(Duration(days: 30)),
          endDate: DateTime.now().add(Duration(days: 30)),
          autoRenew: true,
        );

        when(mockBillingRepository.getCurrentSubscription('user123'))
            .thenAnswer((_) async => currentSubscription);

        // Act
        await billingService.upgradeSubscription(
          'user123',
          SubscriptionPlan.premium,
        );

        // Assert
        verify(mockBillingRepository.saveSubscription(any)).called(1);
      });

      test('should downgrade subscription', () async {
        // Arrange
        final currentSubscription = Subscription(
          id: 'sub_premium',
          userId: 'user123',
          plan: SubscriptionPlan.premium,
          status: SubscriptionStatus.active,
          startDate: DateTime.now().subtract(Duration(days: 30)),
          endDate: DateTime.now().add(Duration(days: 30)),
          autoRenew: true,
        );

        when(mockBillingRepository.getCurrentSubscription('user123'))
            .thenAnswer((_) async => currentSubscription);

        // Act
        await billingService.downgradeSubscription(
          'user123',
          SubscriptionPlan.free,
        );

        // Assert
        verify(mockBillingRepository.saveSubscription(any)).called(1);
      });

      test('should cancel subscription', () async {
        // Arrange
        final currentSubscription = Subscription(
          id: 'sub_premium',
          userId: 'user123',
          plan: SubscriptionPlan.premium,
          status: SubscriptionStatus.active,
          startDate: DateTime.now().subtract(Duration(days: 30)),
          endDate: DateTime.now().add(Duration(days: 30)),
          autoRenew: true,
        );

        when(mockBillingRepository.getCurrentSubscription('user123'))
            .thenAnswer((_) async => currentSubscription);

        // Act
        await billingService.cancelSubscription('user123');

        // Assert
        verify(mockBillingRepository.saveSubscription(any)).called(1);
      });
    });

    group('billing cycle management', () {
      test('should calculate days remaining in billing cycle', () async {
        // Arrange
        final subscription = Subscription(
          id: 'sub_123',
          userId: 'user123',
          plan: SubscriptionPlan.premium,
          status: SubscriptionStatus.active,
          startDate: DateTime.now().subtract(Duration(days: 30)),
          endDate: DateTime.now().add(Duration(days: 30)),
          autoRenew: true,
        );

        when(mockBillingRepository.getCurrentSubscription('user123'))
            .thenAnswer((_) async => subscription);

        // Act
        final daysRemaining = await billingService.getDaysRemainingInCycle('user123');

        // Assert
        expect(daysRemaining, equals(30));
      });

      test('should return 0 days remaining for expired subscription', () async {
        // Arrange
        final expiredSubscription = Subscription(
          id: 'sub_123',
          userId: 'user123',
          plan: SubscriptionPlan.premium,
          status: SubscriptionStatus.expired,
          startDate: DateTime.now().subtract(Duration(days: 60)),
          endDate: DateTime.now().subtract(Duration(days: 1)),
          autoRenew: false,
        );

        when(mockBillingRepository.getCurrentSubscription('user123'))
            .thenAnswer((_) async => expiredSubscription);

        // Act
        final daysRemaining = await billingService.getDaysRemainingInCycle('user123');

        // Assert
        expect(daysRemaining, equals(0));
      });
    });
  });
}