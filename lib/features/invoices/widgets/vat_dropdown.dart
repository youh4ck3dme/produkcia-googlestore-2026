import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/i18n/l10n.dart';
import '../../../core/services/tax_calculation_service.dart';
import '../providers/invoice_draft_provider.dart';

class VatDropdown extends ConsumerWidget {
  const VatDropdown({super.key, required this.index, required this.value});

  final int index;
  final double value;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DropdownButtonFormField<double>(
      initialValue: value,
      decoration: InputDecoration(labelText: context.t(AppStr.vatLabel)),
      items: TaxCalculationService.vatRates
          .map(
            (rate) => DropdownMenuItem(
              value: rate,
              child: Text(TaxCalculationService.vatRateLabel(rate)),
            ),
          )
          .toList(),
      onChanged: (v) {
        if (v == null) return;
        ref.read(invoiceDraftProvider.notifier).updateItemVat(index, v);
      },
    );
  }
}
