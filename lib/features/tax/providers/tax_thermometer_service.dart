import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../invoices/providers/invoices_provider.dart';
import '../../invoices/models/invoice_model.dart';

// Threshold for SK VAT registration (12 consecutive months)
const double vatRegistrationThreshold = 49790.00;

class TaxThermometerResult {
  final double currentTurnover;
  final double threshold;
  final double percentage; // 0.0 to 1.0+
  final bool isSafe; // < 80%
  final bool isWarning; // 80% - 99.9%
  final bool isCritical; // >= 100%

  TaxThermometerResult({
    required this.currentTurnover,
    this.threshold = vatRegistrationThreshold,
  })  : percentage = currentTurnover / vatRegistrationThreshold,
        isSafe = (currentTurnover / vatRegistrationThreshold) < 0.8,
        isWarning = (currentTurnover / vatRegistrationThreshold) >= 0.8 &&
            (currentTurnover / vatRegistrationThreshold) < 1.0,
        isCritical = (currentTurnover / vatRegistrationThreshold) >= 1.0;
}

final taxThermometerProvider =
    Provider<AsyncValue<TaxThermometerResult>>((ref) {
  final invoicesAsync = ref.watch(invoicesProvider);

  return invoicesAsync.whenData((invoices) {
    if (invoices.isEmpty) return TaxThermometerResult(currentTurnover: 0);

    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 365));

    final validInvoices = invoices.where((invoice) {
      final isWithinWindow = invoice.dateIssued.isAfter(startDate) &&
          invoice.dateIssued.isBefore(now.add(const Duration(days: 1)));
      final isNotCancelled = invoice.status != InvoiceStatus.cancelled;
      final isValidStatus = invoice.status != InvoiceStatus.draft;

      return isWithinWindow && isNotCancelled && isValidStatus;
    });

    final double turnover =
        validInvoices.fold(0.0, (sum, invoice) => sum + invoice.totalAmount);

    return TaxThermometerResult(currentTurnover: turnover);
  });
});
