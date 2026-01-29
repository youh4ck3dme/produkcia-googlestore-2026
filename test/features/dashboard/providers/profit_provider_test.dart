import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bizagent/features/dashboard/providers/profit_provider.dart';
import 'package:bizagent/features/dashboard/providers/revenue_provider.dart';
import 'package:bizagent/features/expenses/providers/expenses_provider.dart';
import 'package:bizagent/features/expenses/models/expense_model.dart';
import 'package:bizagent/features/expenses/models/expense_category.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  ExpenseModel createExpense({
    required String id,
    required double amount,
    required DateTime date,
  }) {
    return ExpenseModel(
      id: id,
      userId: 'user-1',
      vendorName: 'Vendor $id',
      description: 'Desc',
      amount: amount,
      date: date,
      category: ExpenseCategory.officeSupplies,
      receiptUrls: [],
    );
  }

  RevenueMetrics createRevenueMetrics({
    double totalRevenue = 0,
    double thisMonthRevenue = 0,
  }) {
    return RevenueMetrics(
      totalRevenue: totalRevenue,
      thisMonthRevenue: thisMonthRevenue,
      lastMonthRevenue: 0,
      unpaidAmount: 0,
      overdueCount: 0,
      averageInvoiceValue: 0,
    );
  }

  test('ProfitMetrics should calculate profit correctly', () async {
    final revenue =
        createRevenueMetrics(totalRevenue: 1000.0, thisMonthRevenue: 500.0);
    final expenses = [
      createExpense(id: '1', amount: 200.0, date: DateTime.now()),
      createExpense(
          id: '2',
          amount: 300.0,
          date: DateTime.now().subtract(const Duration(days: 60))), // Older
    ];

    container = ProviderContainer(
      overrides: [
        revenueMetricsProvider.overrideWith((ref) => Future.value(revenue)),
        expensesProvider.overrideWith((ref) => Stream.value(expenses)),
      ],
    );

    // Keep alive
    container.listen(profitMetricsProvider, (_, __) {});

    // Check that expenses are loaded
    await container.read(expensesProvider.future);

    final metrics = await container.read(profitMetricsProvider.future);

    // Total Profit = Total Revenue (1000) - Total Expenses (200+300=500) = 500
    expect(metrics.profit, 500.0);

    // Margin = Profit / Revenue = 500 / 1000 = 0.5 (50%)
    expect(metrics.profitMargin, 0.5);
  });

  test('ProfitMetrics should calculate this month profit', () async {
    final now = DateTime.now();
    final thisMonthExpDate = DateTime(now.year, now.month, 10);

    final revenue =
        createRevenueMetrics(totalRevenue: 1000.0, thisMonthRevenue: 500.0);
    final expenses = [
      createExpense(id: '1', amount: 100.0, date: thisMonthExpDate),
      createExpense(
          id: '2',
          amount: 300.0,
          date: now.subtract(const Duration(days: 60))), // Old
    ];

    container = ProviderContainer(
      overrides: [
        revenueMetricsProvider.overrideWith((ref) => Future.value(revenue)),
        expensesProvider.overrideWith((ref) => Stream.value(expenses)),
      ],
    );

    // Keep alive
    container.listen(profitMetricsProvider, (_, __) {});

    // Check that expenses are loaded
    await container.read(expensesProvider.future);

    final metrics = await container.read(profitMetricsProvider.future);

    // This Month Profit = This Month Revenue (500) - This Month Expenses (100) = 400
    expect(metrics.thisMonthProfit, 400.0);
  });

  test('ProfitMetrics should handle zero revenue for margin calculation',
      () async {
    final revenue = createRevenueMetrics(totalRevenue: 0, thisMonthRevenue: 0);

    container = ProviderContainer(
      overrides: [
        revenueMetricsProvider.overrideWith((ref) => Future.value(revenue)),
        expensesProvider.overrideWith((ref) => Stream.value([])),
      ],
    );

    // Keep alive
    container.listen(profitMetricsProvider, (_, __) {});

    // Check that expenses are loaded
    await container.read(expensesProvider.future);

    final metrics = await container.read(profitMetricsProvider.future);

    expect(metrics.profitMargin, 0.0);
  });
}
