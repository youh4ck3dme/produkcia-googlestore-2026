import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../core/ui/biz_theme.dart';
import '../models/expense_model.dart';
import '../models/expense_category.dart';
import '../providers/expenses_provider.dart';
import '../../../shared/utils/biz_snackbar.dart';

class ExpenseDetailScreen extends ConsumerWidget {
  final ExpenseModel expense;

  const ExpenseDetailScreen({super.key, required this.expense});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = expense.category ?? ExpenseCategory.other;
    final hasReceipt = expense.receiptUrls.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail výdavku'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Category Icon and Amount
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: category.color.withValues(alpha: 0.05),
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: category.color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: category.color.withValues(alpha: 0.3),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(category.icon, color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    NumberFormat.currency(symbol: '€').format(expense.amount),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    expense.vendorName,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(Icons.calendar_today, 'Dátum',
                      DateFormat('d. MMMM yyyy', 'sk').format(expense.date)),
                  const SizedBox(height: 16),
                  _buildInfoRow(Icons.category_outlined, 'Kategória',
                      category.displayName),
                  if (expense.description.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildInfoRow(Icons.description_outlined, 'Popis',
                        expense.description),
                  ],
                  if (expense.categorizationConfidence != null) ...[
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      Icons.auto_awesome,
                      'Istota AI',
                      '${expense.categorizationConfidence}%',
                      trailing: _buildConfidenceIndicator(
                          expense.categorizationConfidence!),
                    ),
                  ],
                  const SizedBox(height: 32),
                  if (hasReceipt) ...[
                    const Text(
                      'DOKLAD',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () {
                        context.push('/expenses/receipt-viewer', extra: {
                          'url': expense.receiptUrls.first,
                          'isLocal': false
                        });
                      },
                      child: Container(
                        height: 300,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Hero(
                          tag: 'receipt_${expense.receiptUrls.first}',
                          child: Image.network(
                            expense.receiptUrls.first,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                  child: CircularProgressIndicator());
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {Widget? trailing}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: BizTheme.gray600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        if (trailing != null) ...[
          trailing,
        ],
      ],
    );
  }

  Widget _buildConfidenceIndicator(int confidence) {
    Color color = BizTheme.nationalRed;
    if (confidence > 80) {
      color = Colors.green;
    } else if (confidence > 50) {
      color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        confidence > 80 ? 'Vysoká' : (confidence > 50 ? 'Stredná' : 'Nízka'),
        style:
            TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Zmazať výdavok?'),
        content: Text('Naozaj chcete zmazať výdavok "${expense.vendorName}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Zrušiť')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: BizTheme.nationalRed),
              child: const Text('Zmazať')),
        ],
      ),
    );

    if (shouldDelete == true) {
      ref.read(expensesControllerProvider.notifier).deleteExpense(expense.id);
      if (context.mounted) {
        context.pop();
        BizSnackbar.showSuccess(context, 'Výdavok bol zmazaný');
      }
    }
  }
}
