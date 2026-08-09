import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_repository.dart';
import '../models/expense_model.dart';
import 'expenses_repository.dart';

final expensesProvider = StreamProvider<List<ExpenseModel>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);
  return ref.watch(expensesRepositoryProvider).watchExpenses(user.id);
});

final expensesControllerProvider =
    NotifierProvider<ExpensesController, AsyncValue<void>>(ExpensesController.new);

class ExpensesController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> addExpense(ExpenseModel expense) async {
    final user = ref.read(authStateProvider).value ??
        ref.read(authRepositoryProvider).currentUser;
    if (user == null) {
      throw StateError('User not authenticated');
    }

    state = const AsyncValue.loading();
    try {
      await ref.read(expensesRepositoryProvider).addExpense(user.id, expense);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteExpense(String expenseId) async {
    final user = ref.read(authStateProvider).value ??
        ref.read(authRepositoryProvider).currentUser;
    if (user == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ref
        .read(expensesRepositoryProvider)
        .deleteExpense(user.id, expenseId));
  }
}
