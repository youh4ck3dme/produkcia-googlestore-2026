import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../expenses/providers/expenses_provider.dart';
import '../models/expense_insight_model.dart';
import '../services/expense_insights_service.dart';

final expenseInsightsProvider =
    FutureProvider<List<ExpenseInsight>>((ref) async {
  ref.watch(expensesProvider);
  await Future<void>.delayed(Duration.zero);

  final expensesAsync = ref.read(expensesProvider);
  if (expensesAsync.hasError) {
    Error.throwWithStackTrace(
      expensesAsync.error!,
      expensesAsync.stackTrace ?? StackTrace.empty,
    );
  }

  final expenses = expensesAsync.hasValue
      ? expensesAsync.requireValue
      : await ref.read(expensesProvider.future);
  final service = ref.watch(expenseInsightsServiceProvider);

  // Sort expenses by date to give context
  final sortedExpenses = [...expenses]
    ..sort((a, b) => b.date.compareTo(a.date));

  // Take only last 50 expenses for analysis to stay within token limits and focus on recent data
  final recentExpenses = sortedExpenses.length > 50
      ? sortedExpenses.sublist(0, 50)
      : sortedExpenses;

  return service.analyzeExpenses(recentExpenses);
});
