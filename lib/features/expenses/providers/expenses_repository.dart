import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../core/services/local_persistence_service.dart';
import '../models/expense_model.dart';

final expensesRepositoryProvider = Provider<ExpensesRepository>((ref) {
  final persistence = ref.watch(localPersistenceServiceProvider);
  return ExpensesRepository(
    SupabaseConfig.isConfigured ? SupabaseConfig.client : null,
    persistence,
  );
});

/// Výdavky — Supabase Postgres (tabuľka `expenses`) + lokálna Hive cache.
class ExpensesRepository {
  final SupabaseClient? _client;
  final LocalPersistenceService _persistence;

  ExpensesRepository(this._client, this._persistence);

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

    final client = _client;
    if (client == null) return;

    final stream = client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('date', ascending: false);

    await for (final rows in stream) {
      final expenses = rows.map((r) {
        final row = Map<String, dynamic>.from(r);
        final expense = _rowToExpense(row);
        final cache = Map<String, dynamic>.from(row['data'] as Map);
        cache['id'] = expense.id;
        _persistence.saveExpense(expense.id, cache);
        return expense;
      }).toList();

      yield expenses;
    }
  }

  Future<void> addExpense(String userId, ExpenseModel expense) async {
    final id = expense.id.isEmpty
        ? DateTime.now().millisecondsSinceEpoch.toString()
        : expense.id;
    final data = expense.toMap();
    data['id'] = id;
    await _persistence.saveExpense(id, data);

    await _client?.from(_table).upsert(_expenseToRow(userId, expense, id));
  }

  Future<void> deleteExpense(String userId, String expenseId) async {
    await _persistence.deleteExpense(expenseId);
    await _client
        ?.from(_table)
        .delete()
        .eq('id', expenseId)
        .eq('user_id', userId);
  }
}
