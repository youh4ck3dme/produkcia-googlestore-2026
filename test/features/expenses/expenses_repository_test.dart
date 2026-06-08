import 'package:flutter_test/flutter_test.dart';
import 'package:bizagent/features/expenses/providers/expenses_repository.dart';
import 'package:bizagent/features/expenses/models/expense_model.dart';
import 'package:bizagent/features/expenses/models/expense_category.dart';
import '../../helpers/memory_local_persistence.dart';

void main() {
  group('ExpensesRepository (offline / local cache)', () {
    late MemoryLocalPersistenceService persistence;
    late ExpensesRepository repository;
    const userId = 'test-user-123';

    setUp(() {
      persistence = MemoryLocalPersistenceService();
      repository = ExpensesRepository(null, persistence);
    });

    final dummyExpense = ExpenseModel(
      id: 'expense-1',
      userId: userId,
      vendorName: 'Test Vendor',
      description: 'Office Supplies',
      amount: 50.0,
      date: DateTime(2023, 10, 1),
      category: ExpenseCategory.officeSupplies,
      categorizationConfidence: 90,
    );

    test('addExpense ukladá do lokálnej cache', () async {
      await repository.addExpense(userId, dummyExpense);

      final local = persistence.getExpenses();
      expect(local.length, 1);
      expect(local.first['vendorName'], 'Test Vendor');
    });

    test('deleteExpense odstráni z lokálnej cache', () async {
      await repository.addExpense(userId, dummyExpense);
      await repository.deleteExpense(userId, dummyExpense.id);

      expect(persistence.getExpenses(), isEmpty);
    });

    test('watchExpenses emituje lokálne dáta', () async {
      expectLater(
        repository.watchExpenses(userId),
        emits(isA<List<ExpenseModel>>()),
      );

      await repository.addExpense(userId, dummyExpense);
    });
  });
}
