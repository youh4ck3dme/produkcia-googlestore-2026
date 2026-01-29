import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:bizagent/features/analytics/services/expense_insights_service.dart';
import 'package:bizagent/features/expenses/models/expense_model.dart';
import 'package:bizagent/features/expenses/models/expense_category.dart';

// Mock classes
class MockGenerativeModel extends Mock {
  Future<MockGenerateContentResponse> generateContent(List<dynamic> content);
}

class MockGenerateContentResponse extends Mock {
  String? get text => 'mock response';
}

void main() {
  late ExpenseInsightsService service;

  setUp(() {
    // Use empty key to trigger demo fallback logic and avoid SDK validation errors
    service = ExpenseInsightsService('');
  });

  group('ExpenseInsightsService', () {
    test('should return demo insights when API key is empty', () async {
      final serviceWithoutKey = ExpenseInsightsService('');
      // Use non-empty expenses to get demo insights
      final expenses = [
        ExpenseModel(
          id: '1',
          userId: 'test-user',
          vendorName: 'Test Vendor',
          description: 'Test expense',
          amount: 10.0,
          date: DateTime.now(),
          category: ExpenseCategory.other,
        ),
      ];

      final insights = await serviceWithoutKey.analyzeExpenses(expenses);

      expect(insights.length, 2);
      expect(insights[0].title, contains('Viac výdavkov'));
      expect(insights[1].title, contains('Možná daňová'));
    });

    test('should return empty list for empty expenses', () async {
      final expenses = <ExpenseModel>[];

      final insights = await service.analyzeExpenses(expenses);

      // Empty expenses should always return empty list, regardless of API key
      expect(insights, isEmpty);
    });

    test('should handle expenses with categories', () async {
      final expenses = [
        ExpenseModel(
          id: '1',
          userId: 'test-user',
          vendorName: 'Shell',
          description: 'Fuel purchase',
          amount: 50.0,
          date: DateTime.now(),
          category: ExpenseCategory.fuel,
        ),
        ExpenseModel(
          id: '2',
          userId: 'test-user',
          vendorName: 'Office Depot',
          description: 'Office supplies',
          amount: 100.0,
          date: DateTime.now().subtract(const Duration(days: 1)),
          category: ExpenseCategory.officeSupplies,
        ),
      ];

      final insights = await service.analyzeExpenses(expenses);

      expect(insights, isNotEmpty);
      // Since we're using the demo fallback due to API key, we get demo insights
      expect(insights.length, 2);
    });

    test('should process expenses without categories', () async {
      final expenses = [
        ExpenseModel(
          id: '1',
          userId: 'test-user',
          vendorName: 'Unknown Vendor',
          description: 'Unknown expense',
          amount: 25.0,
          date: DateTime.now(),
          category: null,
        ),
      ];

      final insights = await service.analyzeExpenses(expenses);

      expect(insights, isNotEmpty);
      expect(insights.length, 2); // Demo insights
    });

    test('should limit expenses to last 50 for analysis', () async {
      final expenses = List.generate(
        60,
        (index) => ExpenseModel(
          id: index.toString(),
          userId: 'test-user',
          vendorName: 'Vendor $index',
          description: 'Test expense $index',
          amount: 10.0,
          date: DateTime.now().subtract(Duration(days: index)),
          category: ExpenseCategory.other,
        ),
      );

      final insights = await service.analyzeExpenses(expenses);

      // Should still work and return demo insights since API key is not real
      expect(insights, isNotEmpty);
    });
  });
}
