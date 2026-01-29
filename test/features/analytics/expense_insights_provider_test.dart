import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:bizagent/features/analytics/providers/expense_insights_provider.dart';
import 'package:bizagent/features/analytics/services/expense_insights_service.dart';
import 'package:bizagent/features/analytics/models/expense_insight_model.dart';
import 'package:bizagent/features/expenses/models/expense_model.dart';
import 'package:bizagent/features/expenses/models/expense_category.dart';
import 'package:bizagent/features/expenses/providers/expenses_provider.dart';

// Mock classes
class MockExpenseInsightsService extends Mock
    implements ExpenseInsightsService {
  List<ExpenseModel>? capturedExpenses;

  @override
  Future<List<ExpenseInsight>> analyzeExpenses(
      List<ExpenseModel>? expenses) async {
    capturedExpenses = expenses;

    if (expenses == null || expenses.isEmpty) return [];

    // Return mock insights for testing
    return [
      ExpenseInsight(
        id: '1',
        title: 'Test Insight',
        description: 'Mock insight for testing',
        icon: Icons.lightbulb,
        color: Colors.blue,
        potentialSavings: 100.0,
        priority: InsightPriority.medium,
        category: 'optimization',
        createdAt: DateTime.now(),
      )
    ];
  }
}

void main() {
  late ProviderContainer container;
  late MockExpenseInsightsService mockService;

  setUp(() {
    mockService = MockExpenseInsightsService();
    // Reset capture
    mockService.capturedExpenses = null;

    container = ProviderContainer(
      overrides: [
        expenseInsightsServiceProvider.overrideWithValue(mockService),
        // Mock expenses provider with sample data
        expensesProvider.overrideWith((ref) => Stream.value([
              ExpenseModel(
                id: '1',
                userId: 'test-user',
                vendorName: 'Test Vendor',
                description: 'Test expense',
                amount: 50.0,
                date: DateTime.now(),
                category: ExpenseCategory.fuel,
              ),
              ExpenseModel(
                id: '2',
                userId: 'test-user',
                vendorName: 'Another Vendor',
                description: 'Another expense',
                amount: 25.0,
                date: DateTime.now().subtract(const Duration(days: 1)),
                category: ExpenseCategory.officeSupplies,
              ),
            ])),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('ExpenseInsightsProvider', () {
    test('should provide insights when expenses are available', () async {
      // Wait for the stream to emit
      await container.read(expensesProvider.future);

      // It might be loading initially if FutureProvider hasn't completed
      // But mock service is fast.
      // Better to await the future.
      final insights = await container.read(expenseInsightsProvider.future);

      expect(insights, isNotEmpty);
      expect(insights.length, 1);
      expect(insights.first.title, 'Test Insight');
    });

    test('should call service with sorted expenses', () async {
      // Need to read the future to trigger execution
      await container.read(expenseInsightsProvider.future);

      expect(mockService.capturedExpenses, isNotNull);
      // Verify sorting: index 0 should be newer (Test Vendor, date now)
      // index 1 should be older (Another Vendor, date now-1d)
      final captured = mockService.capturedExpenses!;
      expect(captured.length, 2);
      expect(captured[0].vendorName, 'Test Vendor');
      expect(captured[1].vendorName, 'Another Vendor');
    });

    test('should limit expenses to last 50 for analysis', () async {
      // Create container with more than 50 expenses
      final manyExpenses = List.generate(
        60,
        (index) => ExpenseModel(
          id: index.toString(),
          userId: 'test-user',
          vendorName: 'Vendor $index',
          description: 'Expense $index',
          amount: 10.0,
          date: DateTime.now().subtract(Duration(days: index)),
          category: ExpenseCategory.other,
        ),
      );

      final containerWithMany = ProviderContainer(
        overrides: [
          expenseInsightsServiceProvider.overrideWithValue(mockService),
          expensesProvider.overrideWith((ref) => Stream.value(manyExpenses)),
        ],
      );

      await containerWithMany.read(expenseInsightsProvider.future);

      expect(mockService.capturedExpenses, isNotNull);
      expect(mockService.capturedExpenses!.length, 50);

      containerWithMany.dispose();
    });

    test('should handle empty expenses list', () async {
      final containerEmpty = ProviderContainer(
        overrides: [
          expenseInsightsServiceProvider.overrideWithValue(mockService),
          expensesProvider.overrideWith((ref) => Stream.value([])),
        ],
      );

      final result = await containerEmpty.read(expenseInsightsProvider.future);
      expect(result, isEmpty);

      containerEmpty.dispose();
    });

    test('should handle expenses loading state', () {
      final containerLoading = ProviderContainer(
        overrides: [
          expenseInsightsServiceProvider.overrideWithValue(mockService),
          expensesProvider.overrideWith((ref) =>
              Stream.fromFuture(Completer<List<ExpenseModel>>().future)),
        ],
      );

      final insightsAsync = containerLoading.read(expenseInsightsProvider);

      expect(insightsAsync.isLoading, isTrue);
      containerLoading.dispose();
    });

    test('should handle expenses error state', () async {
      final containerError = ProviderContainer(
        overrides: [
          expenseInsightsServiceProvider.overrideWithValue(mockService),
          expensesProvider.overrideWith(
              (ref) => Stream.error('Test error', StackTrace.current)),
        ],
      );

      await expectLater(
        containerError.read(expenseInsightsProvider.future),
        throwsA(anything),
      );

      containerError.dispose();
    });

    test('should sort expenses by date before analysis', () async {
      final unsortedExpenses = [
        ExpenseModel(
          id: '1',
          userId: 'test-user',
          vendorName: 'Old Expense',
          description: 'Old expense',
          amount: 30.0,
          date: DateTime.now().subtract(const Duration(days: 10)),
          category: ExpenseCategory.fuel,
        ),
        ExpenseModel(
          id: '2',
          userId: 'test-user',
          vendorName: 'New Expense',
          description: 'New expense',
          amount: 40.0,
          date: DateTime.now(),
          category: ExpenseCategory.officeSupplies,
        ),
      ];

      final containerSorted = ProviderContainer(
        overrides: [
          expenseInsightsServiceProvider.overrideWithValue(mockService),
          expensesProvider
              .overrideWith((ref) => Stream.value(unsortedExpenses)),
        ],
      );

      await containerSorted.read(expenseInsightsProvider.future);

      expect(mockService.capturedExpenses, isNotNull);
      final captured = mockService.capturedExpenses!;
      expect(captured[0].vendorName, 'New Expense'); // Newer date first
      expect(captured[1].vendorName, 'Old Expense');

      containerSorted.dispose();
    });
  });
}
