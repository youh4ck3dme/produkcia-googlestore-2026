import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/i18n/l10n.dart';
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
      items: const [
        DropdownMenuItem(value: 0.2, child: Text('20 %')),
        DropdownMenuItem(value: 0.1, child: Text('10 %')),
        DropdownMenuItem(value: 0.0, child: Text('0 %')),
      ],
      onChanged: (v) {
        if (v == null) return;
        ref.read(invoiceDraftProvider.notifier).updateItemVat(index, v);
      },
    );
  }
}
