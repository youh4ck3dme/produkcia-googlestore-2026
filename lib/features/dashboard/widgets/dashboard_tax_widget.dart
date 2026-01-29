import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../tax/providers/tax_provider.dart';
import '../../tax/providers/tax_thermometer_service.dart';
import '../../tax/providers/tax_estimation_service.dart';
import '../../../core/i18n/l10n.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/ui/biz_theme.dart';

class DashboardTaxWidget extends ConsumerWidget {
  const DashboardTaxWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final deadlines = ref.watch(upcomingTaxDeadlinesProvider);
    final thermometerAsync = ref.watch(taxThermometerProvider);
    final estimationAsync = ref.watch(taxEstimationProvider);

    return Card(
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BizTheme.radiusLg),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(BizTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Tax Thermometer Section
            _buildThermometer(context, thermometerAsync),

            const SizedBox(height: 24),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // 2. Tax Estimates Section
            _buildEstimates(context, estimationAsync),

            const SizedBox(height: 24),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // 3. Deadlines Section
            Row(
              children: [
                Icon(Icons.calendar_month_outlined,
                    color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(context.t(AppStr.taxCalendar),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.8, // Reduced by 20% (16 * 0.8)
                      color: colorScheme.onSurface,
                    )),
              ],
            ),
            const SizedBox(height: 16),

            if (deadlines.isEmpty)
              Text(
                  context.t(AppStr
                      .invoiceEmptyTitle), // Or a specific "no deadlines" string
                  style: TextStyle(color: colorScheme.onSurfaceVariant))
            else
              ...deadlines
                  .take(2)
                  .map((deadline) => _buildDeadlineItem(context, deadline)),

            if (deadlines.length > 2)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text('+ ${deadlines.length - 2} ďalšie',
                      style: TextStyle(
                        fontSize: 9.6, // Reduced by 20% (12 * 0.8)
                        color: colorScheme.onSurfaceVariant,
                      )),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildThermometer(
      BuildContext context, AsyncValue<TaxThermometerResult> asyncValue) {
    final colorScheme = Theme.of(context).colorScheme;
    return asyncValue.when(
      loading: () => const LinearProgressIndicator(),
      error: (err, stack) => const Text('Chyba výpočtu obratu'),
      data: (result) {
        final currency = NumberFormat.currency(locale: 'sk_SK', symbol: '€');
        Color color = BizTheme.successGreen;
        String statusText = context.t(AppStr.everythingOk);

        if (result.isCritical) {
          color = colorScheme.error;
          statusText = context.t(AppStr.dphRegistrationAlert);
        } else if (result.isWarning) {
          color = BizTheme.warningAmber;
          statusText = context.t(AppStr.approachingLimit);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.thermostat, color: color, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      context.t(AppStr.turnoverLTM),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(BizTheme.radiusMd),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(BizTheme.radiusMd),
              child: LinearProgressIndicator(
                value: result.percentage.clamp(0.0, 1.0),
                backgroundColor: colorScheme.surfaceContainerHighest,
                color: color,
                minHeight: 12,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  currency.format(result.currentTurnover),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  '/ ${currency.format(result.threshold)}',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildEstimates(
      BuildContext context, AsyncValue<TaxEstimationModel> asyncValue) {
    final colorScheme = Theme.of(context).colorScheme;

    return asyncValue.when(
      loading: () => const SizedBox.shrink(),
      error: (err, stack) => const Text('Chyba pri výpočte odhadov'),
      data: (data) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics_outlined, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Odhady daní (YTD)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildEstimateItem(
              context,
              'Daň z príjmu (odhad)',
              data.estimatedIncomeTax,
              Icons.trending_down,
              BizTheme.nationalRed,
            ),
            if (data.isVatPayer) ...[
              const SizedBox(height: 12),
              _buildEstimateItem(
                context,
                'DPH k úhrade (odhad)',
                data.estimatedVatLiability,
                Icons.account_balance,
                BizTheme.slovakBlue,
              ),
            ],
            const SizedBox(height: 12),
            _buildEstimateItem(
              context,
              'Čistý zisk po zdanení',
              data.netProfit - data.estimatedIncomeTax,
              Icons.auto_graph,
              BizTheme.successGreen,
            ),
          ],
        );
      },
    );
  }

  Widget _buildEstimateItem(BuildContext context, String title, double amount,
      IconData icon, Color color) {
    final currency = NumberFormat.currency(locale: 'sk_SK', symbol: '€');
    return Row(
      children: [
        Icon(icon, color: color.withValues(alpha: 0.7), size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 9.6, color: Colors.black54), // Reduced by 20% (12 * 0.8)
          ),
        ),
        Text(
          currency.format(amount),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: amount < 0 ? BizTheme.nationalRed : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildDeadlineItem(BuildContext context, dynamic deadline) {
    final colorScheme = Theme.of(context).colorScheme;
    final isToday = deadline.date.year == DateTime.now().year &&
        deadline.date.month == DateTime.now().month &&
        deadline.date.day == DateTime.now().day;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Container(
            width: 50,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: isToday
                  ? colorScheme.error.withValues(alpha: 0.1)
                  : colorScheme.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(BizTheme.radiusMd),
            ),
            child: Column(
              children: [
                Text(
                  DateFormat('dd').format(deadline.date),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isToday ? colorScheme.error : colorScheme.primary,
                  ),
                ),
                Text(
                  DateFormat('MMM').format(deadline.date).toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isToday ? colorScheme.error : colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deadline.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  deadline.description,
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
