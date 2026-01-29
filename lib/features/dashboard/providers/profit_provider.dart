import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../expenses/providers/expenses_provider.dart';
import 'revenue_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'profit_provider.g.dart';

class ProfitMetrics {
  final double profit;
  final double profitMargin;
  final double thisMonthProfit;

  ProfitMetrics({
    required this.profit,
    required this.profitMargin,
    required this.thisMonthProfit,
  });
}

@riverpod
Future<ProfitMetrics> profitMetrics(Ref ref) async {
  final revenueAsync = await ref.watch(revenueMetricsProvider.future);
  final expensesAsync = ref.watch(expensesProvider);
  final expenses = expensesAsync.value ?? [];

  final now = DateTime.now();
  final thisMonthStart = DateTime(now.year, now.month, 1);

  final totalExpenses = expenses.fold(0.0, (sum, exp) => sum + exp.amount);
  final thisMonthExpenses = expenses
      .where((exp) =>
          exp.date.isAfter(thisMonthStart.subtract(const Duration(seconds: 1))))
      .fold(0.0, (sum, exp) => sum + exp.amount);

  final profit = revenueAsync.totalRevenue - totalExpenses;
  final profitMargin =
      revenueAsync.totalRevenue == 0 ? 0.0 : profit / revenueAsync.totalRevenue;
  final thisMonthProfit = revenueAsync.thisMonthRevenue - thisMonthExpenses;

  return ProfitMetrics(
    profit: profit,
    profitMargin: profitMargin,
    thisMonthProfit: thisMonthProfit,
  );
}
