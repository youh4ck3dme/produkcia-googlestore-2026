import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/ui/biz_theme.dart';

class BizInvoiceCard extends StatelessWidget {
  static const Key amountTextKey = Key('biz_invoice_card_amount_text');
  static const Key dateTextKey = Key('biz_invoice_card_date_text');

  final String title;
  final String subtitle;
  final double amount;
  final DateTime date;
  final String status;
  final Color? statusColor;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;

  const BizInvoiceCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.date,
    required this.status,
    this.statusColor,
    this.onTap,
    this.onLongPress,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currency = NumberFormat.currency(locale: 'sk', symbol: '€');
    final activeStatusColor = statusColor ?? theme.colorScheme.primary;
    
    return Card(
      elevation: isSelected ? 4 : 0,
      shadowColor: theme.colorScheme.primary.withValues(alpha: 0.1),
      color: isSelected && !isDark ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BizTheme.radiusLg),
        side: BorderSide(
          color: isSelected 
              ? theme.colorScheme.primary 
              : (isDark ? BizTheme.darkOutline : BizTheme.gray100),
          width: isSelected ? 2 : 1,
        ),
      ),
      margin: const EdgeInsets.only(bottom: BizTheme.spacingSm),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(BizTheme.radiusLg),
        child: Semantics(
          label: 'Faktúra $subtitle pre $title, suma ${currency.format(amount)}, dátum ${DateFormat('dd.MM.yyyy').format(date)}',
          button: true,
          child: Padding(
            padding: const EdgeInsets.all(BizTheme.spacingMd),
            child: Row(
              children: [
                // Status Indicator
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: activeStatusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(BizTheme.radiusMd),
                  ),
                  child: Icon(
                    _getStatusIcon(status),
                    color: activeStatusColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: BizTheme.spacingMd),
                
                // Main Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.numbers, size: 12, color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            subtitle,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Amount & Date
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currency.format(amount),
                      key: amountTextKey,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : BizTheme.slovakBlue,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('dd.MM.yyyy').format(date),
                      key: dateTextKey,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.05);
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'zaplatená':
      case 'paid':
        return Icons.check_circle_outline;
      case 'po lehote':
      case 'overdue':
        return Icons.error_outline;
      case 'rozpracovaná':
      case 'draft':
        return Icons.edit_note;
      default:
        return Icons.receipt_long_outlined;
    }
  }
}
