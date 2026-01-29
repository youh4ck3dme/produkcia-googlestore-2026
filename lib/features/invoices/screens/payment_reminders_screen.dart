import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:bizagent/features/invoices/providers/invoices_provider.dart';
import 'package:bizagent/features/invoices/providers/reminder_service.dart';
import '../../../core/ui/biz_theme.dart';

class PaymentRemindersScreen extends ConsumerWidget {
  const PaymentRemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoicesAsync = ref.watch(invoicesProvider);
    final reminderService = ref.watch(reminderServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Platobné upomienky')),
      body: invoicesAsync.when(
        data: (invoices) {
          final overdueInvoices = reminderService.getOverdueInvoices(invoices);

          if (overdueInvoices.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 64, color: BizTheme.slovakBlue),
                  SizedBox(height: 16),
                  Text('Žiadne faktúry po splatnosti! 🎉',
                      style: TextStyle(fontSize: 14.4)), // Reduced by 20% (18 * 0.8)
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: overdueInvoices.length,
            itemBuilder: (context, index) {
              final invoice = overdueInvoices[index];
              final daysOverdue = reminderService.getDaysOverdue(invoice);
              final amount = NumberFormat.currency(symbol: '€', locale: 'sk')
                  .format(invoice.grandTotal);

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: BizTheme.richCrimson.withValues(alpha: 0.1),
                    child: const Icon(Icons.warning_amber, color: BizTheme.richCrimson),
                  ),
                  title: Text(
                    'Faktúra ${invoice.number}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Klient: ${invoice.clientName}'),
                      Text('Suma: $amount'),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: BizTheme.richCrimson.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: BizTheme.richCrimson.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          '$daysOverdue dní po splatnosti',
                          style: const TextStyle(
                              color: BizTheme.richCrimson,
                              fontWeight: FontWeight.bold,
                              fontSize: 9.6), // Reduced by 20% (12 * 0.8)
                        ),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.send, color: BizTheme.slovakBlue),
                    onPressed: () {
                      // Navigate to Email Generator with pre-filled context
                      // We need to pass arguments.
                      // Since we use GoRouter, we can use query params or 'extra'
                      // But our route structure might define how we pass it.
                      // Let's pass a Map or simple object via 'extra' if route allows,
                      // or query params.
                      // The AiEmailGeneratorScreen constructor accepts fields.

                      final contextText =
                          'Faktúra č. ${invoice.number} pre ${invoice.clientName} v sume $amount je $daysOverdue dní po splatnosti.';

                      context.push('/ai-tools/email-generator', extra: {
                        'type': 'reminder',
                        'context': contextText,
                      });
                    },
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Chyba: $err')),
      ),
    );
  }
}
