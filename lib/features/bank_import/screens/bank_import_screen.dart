// lib/features/bank_import/screens/bank_import_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_repository.dart';
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
    final user = ref.watch(authStateProvider).value ??
        ref.read(authRepositoryProvider).currentUser;
    final invoicesAsync =
        ref.watch(invoiceLikeRepoProvider(user?.id ?? ''));
    final ctrl = ref.read(bankImportProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Import bankového výpisu'),
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
          const BizSectionHeader(title: '1) Vložte CSV z banky'),
          BizCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<BankCsvProfile>(
                  initialValue: st.profile,
                  decoration: const InputDecoration(
                    labelText: 'Banka / formát',
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
                    labelText: 'CSV výpis',
                    hintText: 'Vložte CSV vrátane hlavičky (oddeľovač ; alebo ,)...',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.paste),
                  ),
                ),
                const SizedBox(height: 12),
                BizPrimaryButton(
                  label: st.isLoading ? 'Spracovávam...' : 'Spracovať CSV',
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
          const BizSectionHeader(title: '2) Náhľad transakcií'),
          if (st.txs.isEmpty)
            BizEmptyState(
              title: 'Zatiaľ žiadne transakcie',
              body: 'Spracujte CSV výpis, aby sa tu zobrazili pohyby na účte.',
              ctaLabel: 'Spracovať',
              onCta: st.csvText.trim().isEmpty ? null : ctrl.parseNow,
              imageAsset: 'assets/images/empty_state_generic.png',
            )
          else
            BizCard(child: BankTxTable(txs: st.txs)),
          const SizedBox(height: 16),
          const BizSectionHeader(title: '3) Párovanie s faktúrami'),
          BizCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                    'Faktúry v systéme: ${(invoicesAsync.value ?? const []).length}'),
                const SizedBox(height: 8),
                const Text(
                    'Automatické párovanie podľa VS, sumy a názvu protistrany.'),
                const SizedBox(height: 12),
                BizPrimaryButton(
                  label: 'Spárovať s faktúrami',
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
                                    'Spárované: $best / ${matches.length} (faktúry: ${invoices.length})')),
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
