import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/local_persistence_service.dart';
import '../models/expense_model.dart';

final expensesRepositoryProvider = Provider<ExpensesRepository>((ref) {
  final persistence = ref.watch(localPersistenceServiceProvider);
  return ExpensesRepository(FirebaseFirestore.instance, persistence);
});

class ExpensesRepository {
  final FirebaseFirestore _firestore;
  final LocalPersistenceService _persistence;

  ExpensesRepository(this._firestore, this._persistence);

  Stream<List<ExpenseModel>> watchExpenses(String userId) async* {
    // Emit local first
    final localData = _persistence.getExpenses();
    yield localData
        .map((data) => ExpenseModel.fromMap(data, data['id'] ?? ''))
        .toList();

    final stream = _firestore
        .collection('users')
        .doc(userId)
        .collection('expenses')
        .orderBy('date', descending: true)
        .snapshots();

    await for (final snapshot in stream) {
      final expenses = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        _persistence.saveExpense(doc.id, data);
        return ExpenseModel.fromMap(data, doc.id);
      }).toList();

      yield expenses;
    }
  }

  Future<void> addExpense(String userId, ExpenseModel expense) async {
    final id = expense.id.isEmpty ? DateTime.now().millisecondsSinceEpoch.toString() : expense.id;
    final data = expense.toMap();
    data['id'] = id;
    await _persistence.saveExpense(id, data);

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('expenses')
        .doc(id)
        .set(expense.toMap());
  }

  Future<void> deleteExpense(String userId, String expenseId) async {
    await _persistence.deleteExpense(expenseId);
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('expenses')
        .doc(expenseId)
        .delete();
  }
}
