import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import '../models/invoice_model.dart';
import '../../settings/providers/settings_provider.dart';
import '../../../core/services/pdf_service.dart';

class PdfPreviewScreen extends ConsumerWidget {
  final InvoiceModel invoice;

  const PdfPreviewScreen({super.key, required this.invoice});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final pdfService = ref.read(pdfServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Náhľad faktúry ${invoice.number}'),
      ),
      body: settingsAsync.when(
        data: (settings) => PdfPreview(
          build: (format) => pdfService.generateInvoice(invoice, settings),
          canDebug: false,
          allowPrinting: true,
          allowSharing: true,
          pdfFileName: 'faktura_${invoice.number}.pdf',
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) =>
            Center(child: Text('Chyba pri načítaní nastavení: $err')),
      ),
    );
  }
}
