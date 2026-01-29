import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../../../core/services/pdf_service.dart';
import '../../settings/providers/settings_provider.dart';
import '../models/invoice_model.dart';
import '../providers/invoices_provider.dart';
import '../../../core/services/analytics_service.dart';
import 'package:share_plus/share_plus.dart';

class InvoiceDetailScreen extends ConsumerWidget {
  final InvoiceModel invoice;

  const InvoiceDetailScreen({super.key, required this.invoice});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          if (invoice.status == InvoiceStatus.sent ||
              invoice.status == InvoiceStatus.overdue)
            IconButton(
              icon: const Icon(Icons.check_circle_outline, color: Colors.green),
              tooltip: 'Označiť ako uhradenú',
              onPressed: () {
                ref
                    .read(invoicesControllerProvider.notifier)
                    .updateStatus(invoice.id, InvoiceStatus.paid);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Faktúra bola označená ako uhradená')));
              },
            ),
          PopupMenuButton<InvoiceStatus>(
            icon: const Icon(Icons.edit_note),
            tooltip: 'Zmeniť stav',
            onSelected: (status) {
              ref
                  .read(invoicesControllerProvider.notifier)
                  .updateStatus(invoice.id, status);
            },
            itemBuilder: (context) => InvoiceStatus.values.map((status) {
              return PopupMenuItem(
                value: status,
                child: Row(
                  children: [
                    Icon(Icons.circle,
                        color: _getStatusColor(status), size: 12),
                    const SizedBox(width: 10),
                    Text(_getStatusLabel(status)),
                  ],
                ),
              );
            }).toList(),
          ),
          IconButton(
            icon: const Icon(Icons.visibility),
            tooltip: 'Náhľad PDF',
            onPressed: () {
              context.push('/invoices/preview', extra: invoice);
            },
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () async {
              final pdfService = ref.read(pdfServiceProvider);
              final settings = await ref.read(settingsProvider.future);
              final bytes = await pdfService.generateInvoice(invoice, settings);
              await Printing.layoutPdf(
                onLayout: (format) async => bytes,
                name: 'Faktura_${invoice.number}.pdf',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_2),
            tooltip: 'Zdieľať platobné údaje',
            onPressed: () {
              ref.read(analyticsServiceProvider).logQrShared();
              final amount = NumberFormat.currency(symbol: '€')
                  .format(invoice.totalAmount);
              // ignore: deprecated_member_use
              Share.share(
                'Prosím o úhradu faktúry ${invoice.number} v sume $amount. '
                'Variabilný symbol: ${invoice.variableSymbol}. '
                'Môžete použiť PAY by square QR kód v prílohe faktúry.',
                subject: 'Podklady k platbe - ${invoice.number}',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              showDialog(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text('Zmazať faktúru?'),
                  content: const Text('Táto akcia je nevratná.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(c),
                        child: const Text('Zrušiť')),
                    TextButton(
                      onPressed: () {
                        ref
                            .read(invoicesControllerProvider.notifier)
                            .deleteInvoice(invoice.id);
                        Navigator.pop(c); // Close dialog
                        Navigator.pop(context); // Close screen
                      },
                      child: const Text('Zmazať',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Stav faktúry:',
                    style: TextStyle(color: Colors.grey)),
                Chip(
                  label: Text(
                    _getStatusLabel(invoice.status).toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: _getStatusColor(invoice.status),
                  padding: EdgeInsets.zero,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Client
            Card(
              child: ListTile(
                title: Text(invoice.clientName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14.4)), // Reduced by 20% (18 * 0.8)
                subtitle: invoice.clientIco != null
                    ? Text('IČO: ${invoice.clientIco}')
                    : null,
                leading: const Icon(Icons.business),
              ),
            ),
            const SizedBox(height: 16),

            // Payment Info (New)
            if (invoice.status == InvoiceStatus.paid)
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.verified, color: Colors.green),
                          SizedBox(width: 12),
                          Text('Informácie o úhrade',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green)),
                        ],
                      ),
                      const Divider(),
                      _buildPaymentRow(
                          'Dátum úhrady',
                          invoice.paymentDate != null
                              ? DateFormat('dd.MM.yyyy')
                                  .format(invoice.paymentDate!)
                              : 'Neuvedený'),
                      _buildPaymentRow(
                          'Spôsob úhrady', invoice.paymentMethod ?? 'Prevodom'),
                    ],
                  ),
                ),
              ),
            if (invoice.status == InvoiceStatus.paid)
              const SizedBox(height: 16),

            // Dates
            Row(
              children: [
                Expanded(
                  child: _DateCard(
                      label: 'Vystavené',
                      date: invoice.dateIssued,
                      icon: Icons.calendar_today),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _DateCard(
                      label: 'Splatné',
                      date: invoice.dateDue,
                      icon: Icons.event,
                      isDue: true),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Items
            const Text('Položky',
                style: TextStyle(fontSize: 14.4, fontWeight: FontWeight.bold)), // Reduced by 20% (18 * 0.8)
            const SizedBox(height: 8),
            Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: invoice.items.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final item = invoice.items[index];
                  return ListTile(
                    title: Text(item.description),
                    subtitle: Text('${item.quantity} x ${item.unitPrice} €'),
                    trailing: Text(
                      '${item.total.toStringAsFixed(2)} €',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Total
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Spolu: ${NumberFormat.currency(symbol: '€').format(invoice.totalAmount)}',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold, color: Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Color _getStatusColor(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.draft:
        return Colors.grey;
      case InvoiceStatus.sent:
        return Colors.blue;
      case InvoiceStatus.paid:
        return Colors.green;
      case InvoiceStatus.overdue:
        return Colors.red;
      case InvoiceStatus.cancelled:
        return Colors.black;
    }
  }

  String _getStatusLabel(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.draft:
        return 'Návrh';
      case InvoiceStatus.sent:
        return 'Odoslaná';
      case InvoiceStatus.paid:
        return 'Uhradená';
      case InvoiceStatus.overdue:
        return 'Po splatnosti';
      case InvoiceStatus.cancelled:
        return 'Zrušená';
    }
  }
}

class _DateCard extends StatelessWidget {
  final String label;
  final DateTime date;
  final IconData icon;
  final bool isDue;

  const _DateCard(
      {required this.label,
      required this.date,
      required this.icon,
      this.isDue = false});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isDue ? Colors.orange.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Icon(icon, color: isDue ? Colors.orange : Colors.grey),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 9.6)), // Reduced by 20% (12 * 0.8)
            const SizedBox(height: 4),
            Text(
              DateFormat('dd.MM.yyyy').format(date),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
