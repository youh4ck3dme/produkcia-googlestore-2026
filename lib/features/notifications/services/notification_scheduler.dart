import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../invoices/providers/invoices_provider.dart';
import '../../invoices/models/invoice_model.dart';
import '../../tax/providers/tax_provider.dart';
import 'notification_service.dart';

final notificationSchedulerProvider = Provider<NotificationScheduler>((ref) {
  return NotificationScheduler(ref);
});

class NotificationScheduler {
  final Ref _ref;

  NotificationScheduler(this._ref);

  Future<void> scheduleAllAlerts() async {
    final service = _ref.read(notificationServiceProvider);

    // 1. Invoices Due in 3 Days
    final invoices = _ref.read(invoicesProvider).value ?? [];
    for (final invoice in invoices) {
      if (invoice.status == InvoiceStatus.sent) {
        final alertDate = invoice.dateDue.subtract(const Duration(days: 3));
        if (alertDate.isAfter(DateTime.now())) {
          await service.scheduleNotification(
            id: invoice.id.hashCode,
            title: 'Blíži sa splatnosť faktúry',
            body:
                'Faktúra ${invoice.number} pre ${invoice.clientName} je splatná o 3 dni.',
            scheduledDate: alertDate,
            payload: '/invoices/${invoice.id}',
          );
        }
      }
    }

    // 2. Tax Deadlines (7 days before)
    final taxDeadlines = _ref.read(upcomingTaxDeadlinesProvider);
    for (final deadline in taxDeadlines) {
      final alertDate = deadline.date.subtract(const Duration(days: 7));
      if (alertDate.isAfter(DateTime.now())) {
        await service.scheduleNotification(
          id: deadline.title.hashCode,
          title: 'Daňový termín sa blíži',
          body:
              '${deadline.title} je o 7 dní (${deadline.date.day}.${deadline.date.month}).',
          scheduledDate: alertDate,
          payload: '/tax',
        );
      }
    }

    // 3. Monthly Summary (1st of next month)
    final now = DateTime.now();
    final nextMonthFirst =
        DateTime(now.year, now.month + 1, 1, 9, 0); // 9:00 AM
    await service.scheduleNotification(
      id: 9999,
      title: 'Mesačný prehľad BizAgent',
      body:
          'Vaše štatistiky za minulý mesiac sú pripravené. Pozrite si ich na dashboarde.',
      scheduledDate: nextMonthFirst,
      payload: '/dashboard',
    );
  }
}
