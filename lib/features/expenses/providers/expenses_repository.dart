import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../core/supabase/supabase_table_store.dart';
import '../../../core/services/local_persistence_service.dart';
import '../models/expense_model.dart';

final expensesRepositoryProvider = Provider<ExpensesRepository>((ref) {
  final persistence = ref.watch(localPersistenceServiceProvider);
  return ExpensesRepository(
    SupabaseConfig.isReady
        ? SupabaseTableStore.fromClient(SupabaseConfig.client)
        : null,
    persistence,
  );
});

/// Výdavky — Supabase Postgres (tabuľka `expenses`) + lokálna Hive cache.
class ExpensesRepository {
  final SupabaseTableStore? _store;
  final LocalPersistenceService _persistence;

  ExpensesRepository(this._store, this._persistence);

  static const _table = 'expenses';

  List<ExpenseModel> _localExpenses(String userId) {
    return _persistence
        .getExpenses()
        .map((data) => ExpenseModel.fromMap(data, data['id'] ?? ''))
        .where((expense) => expense.userId == userId)
        .toList();
  }

  ExpenseModel _rowToExpense(Map<String, dynamic> row) {
    final data = Map<String, dynamic>.from(row['data'] as Map);
    data['id'] = row['id'];
    return ExpenseModel.fromMap(data, row['id'] as String);
  }

  Map<String, dynamic> _expenseToRow(String userId, ExpenseModel expense, String id) {
    final data = expense.toMap();
    data['id'] = id;
    return {
      'id': id,
      'user_id': userId,
      'data': data,
      'date': data['date'],
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  Stream<List<ExpenseModel>> watchExpenses(String userId) async* {
    yield _localExpenses(userId);

    final store = _store;
    if (store == null || !store.isAvailable) return;

    final stream = store.stream(
      _table,
      primaryKey: ['id'],
      eq: {'user_id': userId},
      orderColumn: 'date',
      ascending: false,
    );

    await for (final rows in stream) {
      final expenses = rows.map((row) {
        final expense = _rowToExpense(row);
        final cache = Map<String, dynamic>.from(row['data'] as Map);
        cache['id'] = expense.id;
        _persistence.saveExpense(expense.id, cache);
        return expense;
      }).toList();

      yield expenses;
    }
  }

  ExpenseModel _stampUser(String userId, ExpenseModel expense, String id) {
    return expense.copyWith(id: id, userId: userId);
  }

  Map<String, dynamic> _expenseData(String userId, ExpenseModel expense, String id) {
    final data = expense.toMap();
    data['id'] = id;
    data['userId'] = userId;
    return data;
  }

  Future<void> addExpense(String userId, ExpenseModel expense) async {
    final id = expense.id.isEmpty
        ? DateTime.now().millisecondsSinceEpoch.toString()
        : expense.id;
    final stamped = _stampUser(userId, expense, id);
    await _persistence.saveExpense(id, _expenseData(userId, stamped, id));

    final store = _store;
    if (store == null || !store.isAvailable) return;

    await store.upsert(_table, _expenseToRow(userId, stamped, id));
  }

  Future<void> deleteExpense(String userId, String expenseId) async {
    await _persistence.deleteExpense(expenseId);

    if (SupabaseConfig.isReady) {
      final res = await SupabaseConfig.client.functions.invoke(
        'delete-expense',
        body: {'expenseId': expenseId},
      );
      final data = res.data;
      if (data is Map && data['ok'] == true) return;
      if (data is Map && data['error'] != null) {
        throw Exception(data['error']);
      }
    }

    await _store?.delete(
      _table,
      eq: {'id': expenseId, 'user_id': userId},
    );
  }
}
