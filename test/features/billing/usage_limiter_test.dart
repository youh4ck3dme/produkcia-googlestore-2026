import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:bizagent/features/billing/services/usage_limiter.dart';
import 'package:bizagent/features/billing/services/billing_service.dart';

class MockBillingService extends Mock implements BillingService {}

void main() {
  group('UsageLimiter', () {
    late MockBillingService mockBillingService;
    late UsageLimiter usageLimiter;

    setUp(() {
      mockBillingService = MockBillingService();
      usageLimiter = UsageLimiter(mockBillingService);
    });

    group('checkInvoiceLimit', () {
      test('should allow invoice creation within free plan limits', () async {
        // Arrange
        final usage = Usage(
          invoiceCount: 9, // Under free limit of 10
          expenseCount: 0,
          geminiUsage: 0,
          lastResetDate: DateTime.now().subtract(Duration(days: 1)),
        );

        when(mockBillingService.getUsage('user123'))
            .thenAnswer((_) async => usage);

        // Act
        final canCreate = await usageLimiter.canCreateInvoice('user123');

        // Assert
        expect(canCreate, isTrue);
      });

      test('should block invoice creation exceeding free plan limits', () async {
        // Arrange
        final usage = Usage(
          invoiceCount: 10, // At free limit of 10
          expenseCount: 0,
          geminiUsage: 0,
          lastResetDate: DateTime.now().subtract(Duration(days: 1)),
        );

        when(mockBillingService.getUsage('user123'))
            .thenAnswer((_) async => usage);

        // Act
        final canCreate = await usageLimiter.canCreateInvoice('user123');

        // Assert
        expect(canCreate, isFalse);
      });

      test('should allow unlimited invoices for premium plan', () async {
        // Arrange
        final usage = Usage(
          invoiceCount: 1000, // Well over free limit
          expenseCount: 0,
          geminiUsage: 0,
          lastResetDate: DateTime.now().subtract(Duration(days: 1)),
        );

        when(mockBillingService.getUsage('user123'))
            .thenAnswer((_) async => usage);
        when(mockBillingService.hasFeatureAccess(
          'user123',
          BillingFeature.expenseIntelligence,
        )).thenAnswer((_) async => true); // Premium feature access

        // Act
        final canCreate = await usageLimiter.canCreateInvoice('user123');

        // Assert
        expect(canCreate, isTrue);
      });

      test('should reset invoice count when subscription is upgraded', () async {
        // Arrange
        final usage = Usage(
          invoiceCount: 10, // At free limit
          expenseCount: 0,
          geminiUsage: 0,
          lastResetDate: DateTime.now().subtract(Duration(days: 1)),
        );

        when(mockBillingService.getUsage('user123'))
            .thenAnswer((_) async => usage);

        // Act
        await usageLimiter.resetInvoiceCount('user123');

        // Assert
        verify(mockBillingService.updateUsage(
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

    group('checkExpenseLimit', () {
      test('should allow expense creation within free plan limits', () async {
        // Arrange
        final usage = Usage(
          invoiceCount: 0,
          expenseCount: 4, // Under free limit of 5
          geminiUsage: 0,
          lastResetDate: DateTime.now().subtract(Duration(days: 1)),
        );

        when(mockBillingService.getUsage('user123'))
            .thenAnswer((_) async => usage);

        // Act
        final canCreate = await usageLimiter.canCreateExpense('user123');

        // Assert
        expect(canCreate, isTrue);
      });

      test('should block expense creation exceeding free plan limits', () async {
        // Arrange
        final usage = Usage(
          invoiceCount: 0,
          expenseCount: 5, // At free limit of 5
          geminiUsage: 0,
          lastResetDate: DateTime.now().subtract(Duration(days: 1)),
        );

        when(mockBillingService.getUsage('user123'))
            .thenAnswer((_) async => usage);

        // Act
        final canCreate = await usageLimiter.canCreateExpense('user123');

        // Assert
        expect(canCreate, isFalse);
      });

      test('should allow unlimited expenses for premium plan', () async {
        // Arrange
        final usage = Usage(
          invoiceCount: 0,
          expenseCount: 500, // Well over free limit
          geminiUsage: 0,
          lastResetDate: DateTime.now().subtract(Duration(days: 1)),
        );

        when(mockBillingService.getUsage('user123'))
            .thenAnswer((_) async => usage);
        when(mockBillingService.hasFeatureAccess(
          'user123',
          BillingFeature.expenseIntelligence,
        )).thenAnswer((_) async => true); // Premium feature access

        // Act
        final canCreate = await usageLimiter.canCreateExpense('user123');

        // Assert
        expect(canCreate, isTrue);
      });
    });

    group('checkGeminiUsageLimit', () {
      test('should allow gemini usage within free plan limits', () async {
        // Arrange
        final usage = Usage(
          invoiceCount: 0,
          expenseCount: 0,
          geminiUsage: 4, // Under free limit of 5
          lastResetDate: DateTime.now().subtract(Duration(days: 1)),
        );

        when(mockBillingService.getUsage('user123'))
            .thenAnswer((_) async => usage);

        // Act
        final canUse = await usageLimiter.canUseGemini('user123');

        // Assert
        expect(canUse, isTrue);
      });

      test('should block gemini usage exceeding free plan limits', () async {
        // Arrange
        final usage = Usage(
          invoiceCount: 0,
          expenseCount: 0,
          geminiUsage: 5, // At free limit of 5
          lastResetDate: DateTime.now().subtract(Duration(days: 1)),
        );

        when(mockBillingService.getUsage('user123'))
            .thenAnswer((_) async => usage);

        // Act
        final canUse = await usageLimiter.canUseGemini('user123');

        // Assert
        expect(canUse, isFalse);
      });

      test('should allow unlimited gemini usage for premium plan', () async {
        // Arrange
        final usage = Usage(
          invoiceCount: 0,
          expenseCount: 0,
          geminiUsage: 100, // Well over free limit
          lastResetDate: DateTime.now().subtract(Duration(days: 1)),
        );

        when(mockBillingService.getUsage('user123'))
            .thenAnswer((_) async => usage);
        when(mockBillingService.hasFeatureAccess(
          'user123',
          BillingFeature.geminiAi,
        )).thenAnswer((_) async => true); // Premium feature access

        // Act
        final canUse = await usageLimiter.canUseGemini('user123');

        // Assert
        expect(canUse, isTrue);
      });

      test('should reset gemini usage when subscription is upgraded', () async {
        // Arrange
        final usage = Usage(
          invoiceCount: 0,
          expenseCount: 0,
          geminiUsage: 5, // At free limit
          lastResetDate: DateTime.now().subtract(Duration(days: 1)),
        );

        when(mockBillingService.getUsage('user123'))
            .thenAnswer((_) async => usage);

        // Act
        await usageLimiter.resetGeminiUsage('user123');

        // Assert
        verify(mockBillingService.updateUsage(
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

    group('getRemainingLimits', () {
      test('should return correct remaining limits for free plan', () async {
        // Arrange
        final usage = Usage(
          invoiceCount: 5,
          expenseCount: 3,
          geminiUsage: 2,
          lastResetDate: DateTime.now().subtract(Duration(days: 1)),
        );

        when(mockBillingService.getUsage('user123'))
            .thenAnswer((_) async => usage);
        when(mockBillingService.hasFeatureAccess(
          'user123',
          BillingFeature.expenseIntelligence,
        )).thenAnswer((_) async => false); // Free plan
        when(mockBillingService.hasFeatureAccess(
          'user123',
          BillingFeature.geminiAi,
        )).thenAnswer((_) async => false); // Free plan

        // Act
        final limits = await usageLimiter.getRemainingLimits('user123');

        // Assert
        expect(limits.remainingInvoices, 5); // 10 - 5
        expect(limits.remainingExpenses, 2); // 5 - 3
        expect(limits.remainingGeminiUsage, 3); // 5 - 2
        expect(limits.isPremium, false);
      });

      test('should return unlimited limits for premium plan', () async {
        // Arrange
        final usage = Usage(
          invoiceCount: 100,
          expenseCount: 50,
          geminiUsage: 20,
          lastResetDate: DateTime.now().subtract(Duration(days: 1)),
        );

        when(mockBillingService.getUsage('user123'))
            .thenAnswer((_) async => usage);
        when(mockBillingService.hasFeatureAccess(
          'user123',
          BillingFeature.expenseIntelligence,
        )).thenAnswer((_) async => true); // Premium plan
        when(mockBillingService.hasFeatureAccess(
          'user123',
          BillingFeature.geminiAi,
        )).thenAnswer((_) async => true); // Premium plan

        // Act
        final limits = await usageLimiter.getRemainingLimits('user123');

        // Assert
        expect(limits.remainingInvoices, -1); // -1 indicates unlimited
        expect(limits.remainingExpenses, -1); // -1 indicates unlimited
        expect(limits.remainingGeminiUsage, -1); // -1 indicates unlimited
        expect(limits.isPremium, true);
      });
    });

    group('usage tracking', () {
      test('should increment invoice count', () async {
        // Arrange
        final usage = Usage(
          invoiceCount: 5,
          expenseCount: 0,
          geminiUsage: 0,
          lastResetDate: DateTime.now().subtract(Duration(days: 1)),
        );

        when(mockBillingService.getUsage('user123'))
            .thenAnswer((_) async => usage);

        // Act
        await usageLimiter.incrementInvoiceCount('user123');

        // Assert
        verify(mockBillingService.updateUsage(
          'user123',
          Usage(
            invoiceCount: 6, // 5 + 1
            expenseCount: 0,
            geminiUsage: 0,
            lastResetDate: anyNamed('lastResetDate'),
          ),
        )).called(1);
      });

      test('should increment expense count', () async {
        // Arrange
        final usage = Usage(
          invoiceCount: 0,
          expenseCount: 3,
          geminiUsage: 0,
          lastResetDate: DateTime.now().subtract(Duration(days: 1)),
        );

        when(mockBillingService.getUsage('user123'))
            .thenAnswer((_) async => usage);

        // Act
        await usageLimiter.incrementExpenseCount('user123');

        // Assert
        verify(mockBillingService.updateUsage(
          'user123',
          Usage(
            invoiceCount: 0,
            expenseCount: 4, // 3 + 1
            geminiUsage: 0,
            lastResetDate: anyNamed('lastResetDate'),
          ),
        )).called(1);
      });

      test('should increment gemini usage count', () async {
        // Arrange
        final usage = Usage(
          invoiceCount: 0,
          expenseCount: 0,
          geminiUsage: 2,
          lastResetDate: DateTime.now().subtract(Duration(days: 1)),
        );

        when(mockBillingService.getUsage('user123'))
            .thenAnswer((_) async => usage);

        // Act
        await usageLimiter.incrementGeminiUsage('user123');

        // Assert
        verify(mockBillingService.updateUsage(
          'user123',
          Usage(
            invoiceCount: 0,
            expenseCount: 0,
            geminiUsage: 3, // 2 + 1
            lastResetDate: anyNamed('lastResetDate'),
          ),
        )).called(1);
      });
    });

    group('billing cycle management', () {
      test('should reset usage at billing cycle start', () async {
        // Arrange
        final usage = Usage(
          invoiceCount: 10,
          expenseCount: 5,
          geminiUsage: 5,
          lastResetDate: DateTime.now().subtract(Duration(days: 30)),
        );

        when(mockBillingService.getUsage('user123'))
            .thenAnswer((_) async => usage);

        // Act
        await usageLimiter.resetUsageForNewCycle('user123');

        // Assert
        verify(mockBillingService.updateUsage(
          'user123',
          Usage(
            invoiceCount: 0,
            expenseCount: 0,
            geminiUsage: 0,
            lastResetDate: anyNamed('lastResetDate'),
          ),
        )).called(1);
      });

      test('should check if billing cycle needs reset', () async {
        // Arrange
        final usage = Usage(
          invoiceCount: 5,
          expenseCount: 3,
          geminiUsage: 2,
          lastResetDate: DateTime.now().subtract(Duration(days: 30)),
        );

        when(mockBillingService.getUsage('user123'))
            .thenAnswer((_) async => usage);

        // Act
        final needsReset = await usageLimiter.needsBillingCycleReset('user123');

        // Assert
        expect(needsReset, isTrue);
      });

      test('should not reset billing cycle if recently reset', () async {
        // Arrange
        final usage = Usage(
          invoiceCount: 5,
          expenseCount: 3,
          geminiUsage: 2,
          lastResetDate: DateTime.now().subtract(Duration(days: 1)),
        );

        when(mockBillingService.getUsage('user123'))
            .thenAnswer((_) async => usage);

        // Act
        final needsReset = await usageLimiter.needsBillingCycleReset('user123');

        // Assert
        expect(needsReset, isFalse);
      });
    });
  });
}