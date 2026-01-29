import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:bizagent/features/expenses/providers/expenses_repository.dart';
import 'package:bizagent/features/expenses/models/expense_model.dart';
import 'package:bizagent/features/expenses/models/expense_category.dart';
import 'package:bizagent/core/services/local_persistence_service.dart';

class FakeLocalPersistenceService extends LocalPersistenceService {
  @override
  List<Map<String, dynamic>> getExpenses() => [];
  @override
  Future<void> saveExpense(String id, Map<String, dynamic> data) async {}
  @override
  Future<void> deleteExpense(String id) async {}
}

void main() {
  group('ExpensesRepository', () {
    late FakeFirebaseFirestore fakeFirestore;
    late ExpensesRepository repository;
    late FakeLocalPersistenceService fakePersistence;
    const userId = 'test-user-123';

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      fakePersistence = FakeLocalPersistenceService();
      repository = ExpensesRepository(fakeFirestore, fakePersistence);
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

    test('addExpense adds document to Firestore', () async {
      await repository.addExpense(userId, dummyExpense);

      final snapshot = await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('expenses')
          .get();

      expect(snapshot.docs.length, 1);
      final data = snapshot.docs.first.data();
      expect(data['vendorName'], 'Test Vendor');
      expect(data['category'], 'officeSupplies');
    });

    test('deleteExpense removes document', () async {
      // Add initial
      await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('expenses')
          .doc(dummyExpense.id)
          .set(dummyExpense.toMap());

      await repository.deleteExpense(userId, dummyExpense.id);

      final snapshot = await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('expenses')
          .get();

      expect(snapshot.docs.length, 0);
    });

    test('watchExpenses emits updates from Firestore', () async {
      // FakeFirestore may emit an initial empty snapshot more than once.
      // Allow for a couple of empty emissions before the added item arrives.
      expectLater(
        repository.watchExpenses(userId),
        emitsInOrder([
          isEmpty,
          isEmpty,
          isA<List<ExpenseModel>>().having((l) => l.length, 'length', 1),
        ]),
      );

      // Add expense triggers stream
      await Future.delayed(Duration.zero);
      await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('expenses')
          .add(dummyExpense.toMap());
    });
  });
}

