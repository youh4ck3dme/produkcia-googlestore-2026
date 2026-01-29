import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/ui/biz_theme.dart';

class BizTransactionRow extends StatelessWidget {
  final String title;
  final DateTime date;
  final double amount;
  final bool isExpense;
  final String? category;
  
  const BizTransactionRow({
    super.key,
    required this.title,
    required this.date,
    required this.amount,
    this.isExpense = false,
    this.category,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = NumberFormat.currency(locale: 'sk', symbol: '€');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: BizTheme.spacingSm, horizontal: BizTheme.spacingMd),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isExpense ? BizTheme.accentRed : BizTheme.successGreen).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(BizTheme.radiusMd),
            ),
            child: Icon(
              isExpense ? Icons.arrow_upward : Icons.arrow_downward,
              color: isExpense ? BizTheme.accentRed : BizTheme.successGreen,
              size: 20,
            ),
          ),
          const SizedBox(width: BizTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  DateFormat('d. MMM yyyy').format(date),
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Text(
            '${isExpense ? '-' : '+'}${currency.format(amount.abs())}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isExpense ? BizTheme.errorRed : BizTheme.successGreen,
            ).copyWith(color: isExpense ? theme.colorScheme.error : theme.colorScheme.primary),
          ),
        ],
      ),
    );
  }
}
