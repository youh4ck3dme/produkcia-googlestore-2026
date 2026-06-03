import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/i18n/l10n.dart';
import '../../../shared/widgets/biz_empty_state.dart';
import '../../../shared/widgets/biz_shimmer.dart';
import '../providers/invoices_provider.dart';
import '../models/invoice_model.dart';
import '../../../core/ui/biz_theme.dart';
import '../../../shared/widgets/biz_widgets.dart';
import '../../../shared/widgets/biz_glass_appbar.dart';
import '../../../core/services/tutorial_service.dart';
import '../../billing/subscription_guard.dart';
import '../../billing/paywall_flow.dart';
import '../../../core/config/play_release_scope.dart';

class InvoicesScreen extends ConsumerStatefulWidget {
  const InvoicesScreen({super.key});

  @override
  ConsumerState<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends ConsumerState<InvoicesScreen> {
  final Set<String> _selectedIds = {};
  final GlobalKey _fabKey = GlobalKey();
  final GlobalKey _remindersKey = GlobalKey();

  bool get _isSelectionMode => _selectedIds.isNotEmpty;

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedIds.clear();
    });
  }

  Future<void> _deleteSelected() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Zmazať vybrané?'),
        content: Text('Naozaj chcete zmazať ${_selectedIds.length} faktúr?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Zrušiť')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Zmazať', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(invoicesControllerProvider.notifier)
          .deleteInvoices(_selectedIds.toList());
      _clearSelection();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Faktúry boli zmazané')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final invoicesAsync = ref.watch(invoicesProvider);

    return Scaffold(
      appBar: BizGlassAppBar(
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _clearSelection,
              )
            : null,
        title: _isSelectionMode
            ? Text('${_selectedIds.length} vybrané')
            : Text(context.t(AppStr.invoiceTitle)),
        actions: [
          if (_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.delete, color: BizTheme.nationalRed),
              tooltip: 'Zmazať označené',
              onPressed: _deleteSelected,
            )
          else ...[
            if (PlayReleaseScope.showAiToolsRoutes)
              IconButton(
                icon: const Icon(Icons.smart_toy_outlined),
                tooltip: 'AI',
                onPressed: () => context.push('/ai-tools/biz-bot'),
              ),
            if (PlayReleaseScope.showCoachMarkTutorials)
              BizTutorialButton(
                onPressed: () {
                  TutorialService.showInvoicesTutorial(
                    context: context,
                    fabKey: _fabKey,
                    remindersKey: _remindersKey,
                  );
                },
              ),
            if (PlayReleaseScope.showPaymentReminders)
              IconButton(
                key: _remindersKey,
                icon: const Icon(Icons.notifications_active_outlined),
                tooltip: 'Upomienky',
                onPressed: () => context.push('/invoices/reminders'),
              ),
          ]
        ],
      ),
      floatingActionButton: _isSelectionMode
          ? null
          : FloatingActionButton(
              key: _fabKey,
              backgroundColor: BizTheme.nationalRed,
              foregroundColor: Colors.white,
              onPressed: () async {
                if (await PaywallFlow.ensureAccess(
                  context,
                  ref,
                  BizFeature.createInvoice,
                )) {
                  if (context.mounted) context.push('/create-invoice');
                }
              },
              child: const Icon(Icons.add),
            ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(invoicesProvider);
          await ref.read(invoicesProvider.future);
           _clearSelection(); // Clear selection on refresh
        },
        child: invoicesAsync.when(
          data: (invoices) {
            if (invoices.isEmpty) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 24),
                          child: BizEmptyState(
                            title: context.t(AppStr.invoiceEmptyTitle),
                            body: context.t(AppStr.invoiceEmptyMsg),
                            ctaLabel: context.t(AppStr.invoiceEmptyCta),
                            onCta: () async {
                              if (await PaywallFlow.ensureAccess(
                                context,
                                ref,
                                BizFeature.createInvoice,
                              )) {
                                if (context.mounted) {
                                  context.push('/create-invoice');
                                }
                              }
                            },
                            icon: Icons.receipt_long,
                            imageAsset: 'assets/images/invoices_empty_state.png',
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: invoices.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final invoice = invoices[index];
                final isSelected = _selectedIds.contains(invoice.id);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: BizInvoiceCard(
                    title: invoice.clientName,
                    subtitle: invoice.number,
                    amount: invoice.totalAmount,
                    date: invoice.dateIssued,
                    status: invoice.status.toSlovak(),
                    statusColor: invoice.status.color(context),
                    isSelected: isSelected,
                    onTap: () {
                      if (_isSelectionMode) {
                        _toggleSelection(invoice.id);
                      } else {
                        context.push('/invoices/detail', extra: invoice);
                      }
                    },
                    onLongPress: () => _toggleSelection(invoice.id),
                  ),
                );
              },
            );
          },
          error: (err, stack) => Center(child: Text('Chyba: $err')),
          loading: () => const BizListShimmer(),
        ),
      ),
    );
  }
}
