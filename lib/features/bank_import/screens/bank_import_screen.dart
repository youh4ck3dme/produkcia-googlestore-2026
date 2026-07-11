// lib/features/bank_import/screens/bank_import_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../core/i18n/l10n.dart';
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
        title: Text(context.t(AppStr.bankImportTitle)),
        actions: [
          IconButton(
            tooltip: context.t(AppStr.bankImportClear),
            onPressed: ctrl.clear,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          BizSectionHeader(title: context.t(AppStr.bankImportStep1)),
          BizCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<BankCsvProfile>(
                  initialValue: st.profile,
                  decoration: InputDecoration(
                    labelText: context.t(AppStr.bankImportBankFormat),
                    prefixIcon: const Icon(Icons.account_balance),
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
                  decoration: InputDecoration(
                    labelText: context.t(AppStr.bankImportCsvLabel),
                    hintText: context.t(AppStr.bankImportCsvHint),
                    alignLabelWithHint: true,
                    prefixIcon: const Icon(Icons.paste),
                  ),
                ),
                const SizedBox(height: 12),
                BizPrimaryButton(
                  label: st.isLoading
                      ? context.t(AppStr.bankImportProcessing)
                      : context.t(AppStr.bankImportProcessCsv),
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
          BizSectionHeader(title: context.t(AppStr.bankImportStep2)),
          if (st.txs.isEmpty)
            BizEmptyState(
              title: context.t(AppStr.bankImportNoTransactions),
              body: context.t(AppStr.bankImportNoTransactionsBody),
              ctaLabel: context.t(AppStr.bankImportProcessCta),
              onCta: st.csvText.trim().isEmpty ? null : ctrl.parseNow,
              imageAsset: 'assets/images/empty_state_generic.png',
            )
          else
            BizCard(child: BankTxTable(txs: st.txs)),
          const SizedBox(height: 16),
          BizSectionHeader(title: context.t(AppStr.bankImportStep3)),
          BizCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(context.t(AppStr.bankImportInvoicesInSystem,
                    params: {
                      'count':
                          '${(invoicesAsync.value ?? const []).length}',
                    })),
                const SizedBox(height: 8),
                Text(context.t(AppStr.bankImportMatchDescription)),
                const SizedBox(height: 12),
                BizPrimaryButton(
                  label: context.t(AppStr.bankImportMatchButton),
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
                              content: Text(context.t(
                                AppStr.bankImportMatchResult,
                                params: {
                                  'matched': '$best',
                                  'total': '${matches.length}',
                                  'invoices': '${invoices.length}',
                                },
                              )),
                            ),
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