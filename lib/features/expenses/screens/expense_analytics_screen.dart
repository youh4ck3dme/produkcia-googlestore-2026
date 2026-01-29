import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/expense_model.dart';
import '../models/expense_category.dart';
import '../providers/expenses_provider.dart';

class ExpenseAnalyticsScreen extends ConsumerStatefulWidget {
  const ExpenseAnalyticsScreen({super.key});

  @override
  ConsumerState<ExpenseAnalyticsScreen> createState() =>
      _ExpenseAnalyticsScreenState();
}

class _ExpenseAnalyticsScreenState
    extends ConsumerState<ExpenseAnalyticsScreen> {
  int _touchedIndex = -1;
  bool _showWeekly = true; // true = Weekly, false = Monthly

  @override
  Widget build(BuildContext context) {
    // Watch all expenses directly from the stream provider to handle loading/error states
    final expensesAsync = ref.watch(expensesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analýza výdavkov'),
        actions: [
          // Toggle Time Period
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ToggleButtons(
              constraints: const BoxConstraints(minHeight: 32, minWidth: 60),
              borderRadius: BorderRadius.circular(8),
              isSelected: [_showWeekly, !_showWeekly],
              onPressed: (index) {
                setState(() {
                  _showWeekly = index == 0;
                });
              },
              children: const [
                Text('7 dní'),
                Text('Mesiac'),
              ],
            ),
          ),
        ],
      ),
      body: expensesAsync.when(
        data: (expenses) => _buildContent(expenses),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Chyba: $err')),
      ),
    );
  }

  Widget _buildContent(List<ExpenseModel> allExpenses) {
    if (allExpenses.isEmpty) {
      return const Center(
        child: Text('Žiadne výdavky na analýzu'),
      );
    }

    final filteredExpenses = _filterExpensesByPeriod(allExpenses);
    if (filteredExpenses.isEmpty) {
      return const Center(
        child: Text('Žiadne výdavky vo vybranom období'),
      );
    }

    final totalAmount =
        filteredExpenses.fold(0.0, (sum, item) => sum + item.amount);
    final categoryTotals = _calculateCategoryTotals(filteredExpenses);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total Summary Card
          _buildTotalSummaryCard(totalAmount, filteredExpenses.length),
          const SizedBox(height: 24),

          // Pie Chart Section
          Text(
            'Podľa kategórie',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              _touchedIndex = -1;
                              return;
                            }
                            _touchedIndex = pieTouchResponse
                                .touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections:
                          _generatePieSections(categoryTotals, totalAmount),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: _buildLegend(categoryTotals),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Bar Chart Section (Trend)
          Text(
            'Vývoj v čase',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              _generateBarChartData(filteredExpenses),
            ),
          ),

          const SizedBox(height: 32),

          // Top Spending List
          Text(
            'Top výdavky',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ..._buildTopExpensesList(filteredExpenses),
        ],
      ),
    );
  }

  Widget _buildTotalSummaryCard(double total, int count) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade200,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Celkové výdavky',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _showWeekly ? 'Posledných 7 dní' : 'Tento mesiac',
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            NumberFormat.currency(symbol: '€', decimalDigits: 2).format(total),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$count transakcií',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(Map<ExpenseCategory, double> categoryTotals) {
    if (categoryTotals.isEmpty) return const SizedBox.shrink();

    final sortedEntries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Show top 4 + others
    final topEntries = sortedEntries.take(4).toList();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: topEntries.map((entry) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: entry.key.color,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  entry.key.displayName,
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  List<Widget> _buildTopExpensesList(List<ExpenseModel> expenses) {
    final topExpenses = List<ExpenseModel>.from(expenses)
      ..sort((a, b) => b.amount.compareTo(a.amount));

    return topExpenses.take(5).map((expense) {
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        elevation: 0,
        color: Colors.grey.shade50,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: expense.category?.color.withValues(alpha: 0.1) ??
                Colors.grey.shade200,
            child: Icon(
              expense.category?.icon ?? Icons.question_mark,
              color: expense.category?.color ?? Colors.grey,
              size: 20,
            ),
          ),
          title: Text(expense.vendorName,
              style: const TextStyle(fontWeight: FontWeight.w500)),
          subtitle: Text(DateFormat('d.M.yyyy').format(expense.date)),
          trailing: Text(
            NumberFormat.currency(symbol: '€').format(expense.amount),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
    }).toList();
  }

  List<PieChartSectionData> _generatePieSections(
      Map<ExpenseCategory, double> categoryTotals, double total) {
    if (categoryTotals.isEmpty) return [];

    final sortedEntries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedEntries.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final isTouched = index == _touchedIndex;
      final fontSize = isTouched ? 16.0 : 12.0;
      final radius = isTouched ? 60.0 : 50.0;
      final percentage = (data.value / total * 100);

      return PieChartSectionData(
        color: data.key.color,
        value: data.value,
        title: percentage > 5 ? '${percentage.toStringAsFixed(0)}%' : '',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: const [Shadow(color: Colors.black26, blurRadius: 2)],
        ),
      );
    }).toList();
  }

  BarChartData _generateBarChartData(List<ExpenseModel> expenses) {
    final Map<int, double> groupedData = {};

    // Initialize groups based on view mode
    final now = DateTime.now();

    if (_showWeekly) {
      // Last 7 days
      for (int i = 6; i >= 0; i--) {
        groupedData[i] = 0;
      }

      for (var expense in expenses) {
        final diff = now.difference(expense.date).inDays;
        if (diff >= 0 && diff < 7) {
          // 6 is today, 0 is 7 days ago in chart x-axis logic
          groupedData[6 - diff] = (groupedData[6 - diff] ?? 0) + expense.amount;
        }
      }
    } else {
      // Weeks in month (simplified to 4 weeks)
      for (int i = 0; i < 4; i++) {
        groupedData[i] = 0;
      }

      for (var expense in expenses) {
        final day = expense.date.day;
        // Simple bucketing into 4 weeks
        int weekIndex = ((day - 1) / 7).floor();
        if (weekIndex > 3) weekIndex = 3;
        groupedData[weekIndex] = (groupedData[weekIndex] ?? 0) + expense.amount;
      }
    }

    // Find max Y for scaling
    double maxY = 0;
    groupedData.forEach((_, value) {
      if (value > maxY) maxY = value;
    });
    if (maxY == 0) maxY = 100;

    // Add some headroom
    maxY *= 1.2;

    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: maxY,
      barTouchData: BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (_) => Colors.blueGrey,
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            return BarTooltipItem(
              '${rod.toY.toStringAsFixed(2)} €',
              const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              if (_showWeekly) {
                // Return day names
                final date = now.subtract(Duration(days: 6 - value.toInt()));
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(DateFormat('E', 'sk').format(date),
                      style: const TextStyle(fontSize: 10)),
                );
              } else {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('${value.toInt() + 1}. týž.',
                      style: const TextStyle(fontSize: 10)),
                );
              }
            },
            reservedSize: 30,
          ),
        ),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      barGroups: groupedData.entries.map((entry) {
        return BarChartGroupData(
          x: entry.key,
          barRods: [
            BarChartRodData(
              toY: entry.value,
              color: Colors.blue.shade400,
              width: 12,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ],
        );
      }).toList(),
    );
  }

  List<ExpenseModel> _filterExpensesByPeriod(List<ExpenseModel> expenses) {
    final now = DateTime.now();
    return expenses.where((expense) {
      if (_showWeekly) {
        // Last 7 days
        return expense.date.isAfter(now.subtract(const Duration(days: 7))) &&
            expense.date.isBefore(now.add(const Duration(days: 1)));
      } else {
        // Current month
        return expense.date.year == now.year && expense.date.month == now.month;
      }
    }).toList();
  }

  Map<ExpenseCategory, double> _calculateCategoryTotals(
      List<ExpenseModel> expenses) {
    final Map<ExpenseCategory, double> totals = {};
    for (var expense in expenses) {
      final category = expense.category ?? ExpenseCategory.other;
      totals[category] = (totals[category] ?? 0) + expense.amount;
    }
    return totals;
  }
}
