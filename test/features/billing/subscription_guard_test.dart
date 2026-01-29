import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:bizagent/features/billing/services/subscription_guard.dart';
import 'package:bizagent/features/billing/services/billing_service.dart';

class MockBillingService extends Mock implements BillingService {}

void main() {
  group('SubscriptionGuard', () {
    late MockBillingService mockBillingService;
    late SubscriptionGuard subscriptionGuard;

    setUp(() {
      mockBillingService = MockBillingService();
      subscriptionGuard = SubscriptionGuard(mockBillingService);
    });

    group('canAccessFeature', () {
      test('should allow access to free features without subscription', () async {
        // Arrange
        when(mockBillingService.getCurrentSubscription('user123'))
            .thenAnswer((_) async => null);

        // Act
        final canAccess = await subscriptionGuard.canAccessFeature(
          'user123',
          BillingFeature.basicInvoices,
        );

        // Assert
        expect(canAccess, isTrue);
        verifyNever(mockBillingService.isSubscriptionExpired('user123'));
      });

      test('should deny access to premium features without subscription', () async {
        // Arrange
        when(mockBillingService.getCurrentSubscription('user123'))
            .thenAnswer((_) async => null);

        // Act
        final canAccess = await subscriptionGuard.canAccessFeature(
          'user123',
          BillingFeature.expenseIntelligence,
        );

        // Assert
        expect(canAccess, isFalse);
      });

      test('should allow access to premium features with active premium subscription', () async {
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

        when(mockBillingService.getCurrentSubscription('user123'))
            .thenAnswer((_) async => premiumSubscription);
        when(mockBillingService.isSubscriptionExpired('user123'))
            .thenAnswer((_) async => false);

        // Act
        final canAccess = await subscriptionGuard.canAccessFeature(
          'user123',
          BillingFeature.expenseIntelligence,
        );

        // Assert
        expect(canAccess, isTrue);
      });

      test('should deny access when subscription is expired', () async {
        // Arrange
        final expiredSubscription = Subscription(
          id: 'sub_premium',
          userId: 'user123',
          plan: SubscriptionPlan.premium,
          status: SubscriptionStatus.expired,
          startDate: DateTime.now().subtract(Duration(days: 60)),
          endDate: DateTime.now().subtract(Duration(days: 1)),
          autoRenew: false,
        );

        when(mockBillingService.getCurrentSubscription('user123'))
            .thenAnswer((_) async => expiredSubscription);
        when(mockBillingService.isSubscriptionExpired('user123'))
            .thenAnswer((_) async => true);

        // Act
        final canAccess = await subscriptionGuard.canAccessFeature(
          'user123',
          BillingFeature.expenseIntelligence,
        );

        // Assert
        expect(canAccess, isFalse);
      });

      test('should deny access when subscription is cancelled', () async {
        // Arrange
        final cancelledSubscription = Subscription(
          id: 'sub_premium',
          userId: 'user123',
          plan: SubscriptionPlan.premium,
          status: SubscriptionStatus.cancelled,
          startDate: DateTime.now().subtract(Duration(days: 30)),
          endDate: DateTime.now().add(Duration(days: 30)),
          autoRenew: false,
        );

        when(mockBillingService.getCurrentSubscription('user123'))
            .thenAnswer((_) async => cancelledSubscription);
        when(mockBillingService.isSubscriptionExpired('user123'))
            .thenAnswer((_) async => false);

        // Act
        final canAccess = await subscriptionGuard.canAccessFeature(
          'user123',
          BillingFeature.expenseIntelligence,
        );

        // Assert
        expect(canAccess, isFalse);
      });
    });

    group('shouldShowPaywall', () {
      test('should show paywall for premium features without subscription', () async {
        // Arrange
        when(mockBillingService.getCurrentSubscription('user123'))
            .thenAnswer((_) async => null);

        // Act
        final shouldShow = await subscriptionGuard.shouldShowPaywall(
          'user123',
          BillingFeature.expenseIntelligence,
        );

        // Assert
        expect(shouldShow, isTrue);
      });

      test('should not show paywall for free features', () async {
        // Arrange
        when(mockBillingService.getCurrentSubscription('user123'))
            .thenAnswer((_) async => null);

        // Act
        final shouldShow = await subscriptionGuard.shouldShowPaywall(
          'user123',
          BillingFeature.basicInvoices,
        );

        // Assert
        expect(shouldShow, isFalse);
      });

      test('should not show paywall for premium features with active subscription', () async {
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

        when(mockBillingService.getCurrentSubscription('user123'))
            .thenAnswer((_) async => premiumSubscription);

        // Act
        final shouldShow = await subscriptionGuard.shouldShowPaywall(
          'user123',
          BillingFeature.expenseIntelligence,
        );

        // Assert
        expect(shouldShow, isFalse);
      });

      test('should show paywall when subscription is expired', () async {
        // Arrange
        final expiredSubscription = Subscription(
          id: 'sub_premium',
          userId: 'user123',
          plan: SubscriptionPlan.premium,
          status: SubscriptionStatus.expired,
          startDate: DateTime.now().subtract(Duration(days: 60)),
          endDate: DateTime.now().subtract(Duration(days: 1)),
          autoRenew: false,
        );

        when(mockBillingService.getCurrentSubscription('user123'))
            .thenAnswer((_) async => expiredSubscription);

        // Act
        final shouldShow = await subscriptionGuard.shouldShowPaywall(
          'user123',
          BillingFeature.expenseIntelligence,
        );

        // Assert
        expect(shouldShow, isTrue);
      });
    });

    group('getSubscriptionStatus', () {
      test('should return free status when no subscription exists', () async {
        // Arrange
        when(mockBillingService.getCurrentSubscription('user123'))
            .thenAnswer((_) async => null);

        // Act
        final status = await subscriptionGuard.getSubscriptionStatus('user123');

        // Assert
        expect(status, SubscriptionStatus.free);
      });

      test('should return subscription status when subscription exists', () async {
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

        when(mockBillingService.getCurrentSubscription('user123'))
            .thenAnswer((_) async => premiumSubscription);

        // Act
        final status = await subscriptionGuard.getSubscriptionStatus('user123');

        // Assert
        expect(status, SubscriptionStatus.active);
      });

      test('should return expired status when subscription is expired', () async {
        // Arrange
        final expiredSubscription = Subscription(
          id: 'sub_premium',
          userId: 'user123',
          plan: SubscriptionPlan.premium,
          status: SubscriptionStatus.expired,
          startDate: DateTime.now().subtract(Duration(days: 60)),
          endDate: DateTime.now().subtract(Duration(days: 1)),
          autoRenew: false,
        );

        when(mockBillingService.getCurrentSubscription('user123'))
            .thenAnswer((_) async => expiredSubscription);

        // Act
        final status = await subscriptionGuard.getSubscriptionStatus('user123');

        // Assert
        expect(status, SubscriptionStatus.expired);
      });
    });

    group('hasPremiumAccess', () async {
      test('should return false when no subscription exists', () async {
        // Arrange
        when(mockBillingService.getCurrentSubscription('user123'))
            .thenAnswer((_) async => null);

        // Act
        final hasPremium = await subscriptionGuard.hasPremiumAccess('user123');

        // Assert
        expect(hasPremium, isFalse);
      });

      test('should return true for premium subscription', () async {
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

        when(mockBillingService.getCurrentSubscription('user123'))
            .thenAnswer((_) async => premiumSubscription);

        // Act
        final hasPremium = await subscriptionGuard.hasPremiumAccess('user123');

        // Assert
        expect(hasPremium, isTrue);
      });

      test('should return false for free subscription', () async {
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

        when(mockBillingService.getCurrentSubscription('user123'))
            .thenAnswer((_) async => freeSubscription);

        // Act
        final hasPremium = await subscriptionGuard.hasPremiumAccess('user123');

        // Assert
        expect(hasPremium, isFalse);
      });

      test('should return false when subscription is expired', () async {
        // Arrange
        final expiredSubscription = Subscription(
          id: 'sub_premium',
          userId: 'user123',
          plan: SubscriptionPlan.premium,
          status: SubscriptionStatus.expired,
          startDate: DateTime.now().subtract(Duration(days: 60)),
          endDate: DateTime.now().subtract(Duration(days: 1)),
          autoRenew: false,
        );

        when(mockBillingService.getCurrentSubscription('user123'))
            .thenAnswer((_) async => expiredSubscription);

        // Act
        final hasPremium = await subscriptionGuard.hasPremiumAccess('user123');

        // Assert
        expect(hasPremium, isFalse);
      });
    });

    group('getAvailableFeatures', () {
      test('should return only free features when no subscription exists', () async {
        // Arrange
        when(mockBillingService.getCurrentSubscription('user123'))
            .thenAnswer((_) async => null);

        // Act
        final features = await subscriptionGuard.getAvailableFeatures('user123');

        // Assert
        expect(features, contains(BillingFeature.basicInvoices));
        expect(features, contains(BillingFeature.basicExpenses));
        expect(features, isNot(contains(BillingFeature.expenseIntelligence)));
        expect(features, isNot(contains(BillingFeature.geminiAi)));
      });

      test('should return all features for premium subscription', () async {
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

        when(mockBillingService.getCurrentSubscription('user123'))
            .thenAnswer((_) async => premiumSubscription);

        // Act
        final features = await subscriptionGuard.getAvailableFeatures('user123');

        // Assert
        expect(features, contains(BillingFeature.basicInvoices));
        expect(features, contains(BillingFeature.basicExpenses));
        expect(features, contains(BillingFeature.expenseIntelligence));
        expect(features, contains(BillingFeature.geminiAi));
      });

      test('should return only free features when subscription is expired', () async {
        // Arrange
        final expiredSubscription = Subscription(
          id: 'sub_premium',
          userId: 'user123',
          plan: SubscriptionPlan.premium,
          status: SubscriptionStatus.expired,
          startDate: DateTime.now().subtract(Duration(days: 60)),
          endDate: DateTime.now().subtract(Duration(days: 1)),
          autoRenew: false,
        );

        when(mockBillingService.getCurrentSubscription('user123'))
            .thenAnswer((_) async => expiredSubscription);

        // Act
        final features = await subscriptionGuard.getAvailableFeatures('user123');

        // Assert
        expect(features, contains(BillingFeature.basicInvoices));
        expect(features, contains(BillingFeature.basicExpenses));
        expect(features, isNot(contains(BillingFeature.expenseIntelligence)));
        expect(features, isNot(contains(BillingFeature.geminiAi)));
      });
    });
  });
}