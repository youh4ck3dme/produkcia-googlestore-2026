// lib/features/bank_import/screens/bank_import_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/biz_buttons.dart';
import '../../../shared/widgets/biz_card.dart';
import '../../../shared/widgets/biz_empty_state.dart';
import '../../../shared/widgets/biz_section_header.dart';
import '../models/bank_csv_profile.dart';
import '../providers/bank_import_provider.dart';
import '../providers/invoice_like_repo_provider.dart';
import '../widgets/bank_tx_table.dart';

class BankImportScreen extends ConsumerWidget {
  const BankImportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(bankImportProvider);
    // For now, we'll use a hardcoded user ID - in real app this would come from auth
    final invoicesAsync = ref.watch(invoiceLikeRepoProvider('test-user'));
    final ctrl = ref.read(bankImportProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bank CSV Import'),
        actions: [
          IconButton(
            tooltip: 'Clear',
            onPressed: ctrl.clear,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const BizSectionHeader(title: '1) Paste bank CSV'),
          BizCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<BankCsvProfile>(
                  initialValue: st.profile,
                  decoration: const InputDecoration(
                    labelText: 'Profile',
                    prefixIcon: Icon(Icons.account_balance),
                  ),
                  items: BankCsvProfile.all
                      .map((p) =>
                          DropdownMenuItem(value: p, child: Text(p.name)))
                      .toList(),
                  onChanged: (p) {
                    if (p != null) ctrl.setProfile(p);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  minLines: 6,
                  maxLines: 14,
                  initialValue: st.csvText,
                  onChanged: ctrl.setCsvText,
                  decoration: const InputDecoration(
                    labelText: 'CSV text',
                    hintText: 'Paste CSV here (including header row)...',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.paste),
                  ),
                ),
                const SizedBox(height: 12),
                BizPrimaryButton(
                  label: st.isLoading ? 'Parsing...' : 'Parse CSV',
                  icon: Icons.play_arrow,
                  isLoading: st.isLoading,
                  onPressed: st.csvText.trim().isEmpty ? null : ctrl.parseNow,
                ),
                if (st.warnings.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ...st.warnings.map((w) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, size: 18),
                            const SizedBox(width: 8),
                            Expanded(child: Text(w)),
                          ],
                        ),
                      )),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          const BizSectionHeader(title: '2) Preview transactions'),
          if (st.txs.isEmpty)
            BizEmptyState(
              title: 'No transactions yet',
              body: 'Parse a CSV to see transactions here.',
              ctaLabel: 'Parse',
              onCta: st.csvText.trim().isEmpty ? null : ctrl.parseNow,
              imageAsset: 'assets/images/empty_state_generic.png',
            )
          else
            BizCard(child: BankTxTable(txs: st.txs)),
          const SizedBox(height: 16),
          const BizSectionHeader(title: '3) Auto-match invoices'),
          BizCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                    'Repo invoices: ${(invoicesAsync.value ?? const []).length}'),
                const SizedBox(height: 8),
                const Text('MVP: match by VS + amount + counterparty name.'),
                const SizedBox(height: 12),
                BizPrimaryButton(
                  label: 'Auto-match (from repo)',
                  icon: Icons.auto_awesome,
                  onPressed: (st.txs.isEmpty || invoicesAsync.isLoading)
                      ? null
                      : () {
                          final invoices = invoicesAsync.value ?? const [];
                          ctrl.autoMatch(invoices);
                          final matches = ref.read(bankImportProvider).matches;
                          final best =
                              matches.where((m) => m.invoice != null).length;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    'Matched: $best / ${matches.length} (invoices: ${invoices.length})')),
                          );
                        },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
