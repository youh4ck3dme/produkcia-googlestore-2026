import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/i18n/l10n.dart';
import '../../../core/utils/money.dart';
import '../../../shared/widgets/biz_card.dart';
import '../providers/invoice_draft_provider.dart';

class InvoiceSummaryBox extends ConsumerWidget {
  const InvoiceSummaryBox({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(invoiceDraftProvider);
    final totals = ref.watch(invoiceDraftProvider.notifier).totals;

    if (draft.items.isEmpty) return const SizedBox.shrink();

    return BizCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    '${context.t(AppStr.summaryBase)}: ${Money.eur(totals.baseTotal)} €'),
                const SizedBox(height: 4),
                Text(
                    '${context.t(AppStr.summaryVat)}: ${Money.eur(totals.vatTotal)} €'),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(context.t(AppStr.summaryTotal),
                  style: Theme.of(context).textTheme.labelMedium),
              Text('${Money.eur(totals.grandTotal)} €',
                  style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ],
      ),
    );
  }
}
