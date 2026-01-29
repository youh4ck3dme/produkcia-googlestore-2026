import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/invoice_model.dart';

final reminderServiceProvider = Provider<ReminderService>((ref) {
  return ReminderService();
});

class ReminderService {
  List<InvoiceModel> getOverdueInvoices(List<InvoiceModel> invoices) {
    final now = DateTime.now();
    // Normalize today to start of day for fair comparison
    final today = DateTime(now.year, now.month, now.day);

    return invoices.where((invoice) {
      // Consider 'sent' and 'overdue' as potentially unpaid/overdue
      // 'draft', 'paid', 'cancelled' are ignored
      final isUnpaid = invoice.status == InvoiceStatus.sent ||
          invoice.status == InvoiceStatus.overdue;

      if (!isUnpaid) return false;

      // Check if due date is strictly before today
      final isPastDue = invoice.dateDue.isBefore(today);
      return isPastDue;
    }).toList();
  }

  int getDaysOverdue(InvoiceModel invoice) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Difference in days. Positive if overdue.
    // If due date was yesterday (20th), and today is 21st, diff is 1.
    return today.difference(invoice.dateDue).inDays;
  }
}
