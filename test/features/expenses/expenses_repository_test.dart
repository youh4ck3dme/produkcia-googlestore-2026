import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:bizagent/features/expenses/providers/expenses_repository.dart';
import 'package:bizagent/features/expenses/models/expense_model.dart';
import 'package:bizagent/features/expenses/models/expense_category.dart';
import '../../helpers/memory_local_persistence.dart';
import '../../helpers/in_memory_supabase_store.dart';

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

  group('ExpensesRepository (with Supabase store)', () {
    late MemoryLocalPersistenceService persistence;
    late InMemorySupabaseStore store;
    late ExpensesRepository repository;
    const userId = 'test-user-123';

    setUp(() {
      persistence = MemoryLocalPersistenceService();
      store = InMemorySupabaseStore();
      repository = ExpensesRepository(store, persistence);
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

    test('addExpense syncs to Supabase store', () async {
      await repository.addExpense(userId, dummyExpense);

      final rows = await store.select('expenses', eq: {'user_id': userId});
      expect(rows.length, 1);
      expect(rows.first['id'], 'expense-1');
    });

    test('deleteExpense removes remote row', () async {
      await repository.addExpense(userId, dummyExpense);
      await repository.deleteExpense(userId, dummyExpense.id);

      final rows = await store.select('expenses', eq: {'user_id': userId});
      expect(rows, isEmpty);
    });

    test('watchExpenses emits after remote upsert', () async {
      final values = <List<ExpenseModel>>[];
      final sub = repository.watchExpenses(userId).listen(values.add);

      await repository.addExpense(userId, dummyExpense);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(
        values.any((list) => list.any((e) => e.vendorName == 'Test Vendor')),
        isTrue,
      );
      unawaited(sub.cancel());
    });
  });
}
