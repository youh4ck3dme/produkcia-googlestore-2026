import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_repository.dart';
import '../models/expense_model.dart';
import 'expenses_repository.dart';

final expensesProvider = StreamProvider<List<ExpenseModel>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return ref.watch(expensesRepositoryProvider).watchExpenses(user.id);
});

final expensesControllerProvider =
    StateNotifierProvider<ExpensesController, AsyncValue<void>>((ref) {
  return ExpensesController(ref);
});

class ExpensesController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  ExpensesController(this._ref) : super(const AsyncValue.data(null));

  Future<void> addExpense(ExpenseModel expense) async {
    final user = _ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() =>
        _ref.read(expensesRepositoryProvider).addExpense(user.id, expense));
  }

  Future<void> deleteExpense(String expenseId) async {
    final user = _ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _ref
        .read(expensesRepositoryProvider)
        .deleteExpense(user.id, expenseId));
  }
}
