import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bizagent/features/dashboard/providers/revenue_provider.dart';
import 'package:bizagent/features/invoices/providers/invoices_provider.dart';
import 'package:bizagent/features/invoices/models/invoice_model.dart';
// ClientModel and InvoiceItemModel are not separate imports or don't exist as used previously

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  InvoiceModel createInvoice({
    required String id,
    required double amount,
    required DateTime dateIssued,
    required DateTime dateDue,
    required InvoiceStatus status,
  }) {
    return InvoiceModel(
      id: id,
      userId: 'user-1',
      createdAt: dateIssued,
      number: 'INV-$id',
      variableSymbol: 'VS$id',
      dateIssued: dateIssued,
      dateDue: dateDue,
      clientName: 'Test Client',
      clientIco: '12345678',
      items: [
        InvoiceItemModel(
            title: 'Item',
            amount: amount, // NET amount
            vatRate: 0.0)
      ],
      totalAmount: amount, // Assuming 0% VAT for simplicity in this test
      status: status,
    );
  }

  test('RevenueMetrics should calculate correctly for empty invoices',
      () async {
    container = ProviderContainer(
      overrides: [
        invoicesProvider.overrideWith((ref) => Stream.value([])),
      ],
    );

    // Keep provider alive
    container.listen(revenueMetricsProvider, (_, __) {});

    final metrics = await container.read(revenueMetricsProvider.future);

    expect(metrics.totalRevenue, 0.0);
    expect(metrics.thisMonthRevenue, 0.0);
    expect(metrics.lastMonthRevenue, 0.0);
    expect(metrics.unpaidAmount, 0.0);
    expect(metrics.overdueCount, 0);
    expect(metrics.averageInvoiceValue, 0.0);
  });

  test('RevenueMetrics should calculate revenue for different periods',
      () async {
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month, 10);
    // Be careful with months, subtract logic is safer
    final lastMonth =
        DateTime(now.year, now.month, 1).subtract(const Duration(days: 15));
    final older =
        DateTime(now.year, now.month, 1).subtract(const Duration(days: 45));

    final invoices = [
      createInvoice(
          id: '1',
          amount: 100,
          dateIssued: thisMonth,
          dateDue: thisMonth.add(const Duration(days: 14)),
          status: InvoiceStatus.paid),
      createInvoice(
          id: '2',
          amount: 200,
          dateIssued: lastMonth,
          dateDue: lastMonth.add(const Duration(days: 14)),
          status: InvoiceStatus.paid),
      createInvoice(
          id: '3',
          amount: 300,
          dateIssued: older,
          dateDue: older.add(const Duration(days: 14)),
          status: InvoiceStatus.paid),
    ];

    container = ProviderContainer(
      overrides: [
        invoicesProvider.overrideWith((ref) => Stream.value(invoices)),
      ],
    );

    // Keep provider alive
    container.listen(revenueMetricsProvider, (_, __) {});

    final metrics = await container.read(revenueMetricsProvider.future);

    expect(metrics.totalRevenue, 600.0);
    expect(metrics.thisMonthRevenue, 100.0);
    expect(metrics.lastMonthRevenue, 200.0);
  });

  test('RevenueMetrics should calculate unpaid amount and overdue count',
      () async {
    final now = DateTime.now();
    final pastDue = now.subtract(const Duration(days: 5));
    final futureDue = now.add(const Duration(days: 5));

    final invoices = [
      // Paid (Ignored for unpaid/overdue)
      createInvoice(
          id: '1',
          amount: 100,
          dateIssued: now,
          dateDue: futureDue,
          status: InvoiceStatus.paid),

      // Sent, Future Due (Unpaid, Not Overdue)
      createInvoice(
          id: '2',
          amount: 200,
          dateIssued: now,
          dateDue: futureDue,
          status: InvoiceStatus.sent),

      // Sent, Past Due (Unpaid, Overdue via date check)
      createInvoice(
          id: '3',
          amount: 300,
          dateIssued: now,
          dateDue: pastDue,
          status: InvoiceStatus.sent),

      // Overdue Status (Unpaid, Overdue via status)
      createInvoice(
          id: '4',
          amount: 400,
          dateIssued: now,
          dateDue: pastDue,
          status: InvoiceStatus.overdue),

      // Draft (Ignored)
      createInvoice(
          id: '5',
          amount: 500,
          dateIssued: now,
          dateDue: futureDue,
          status: InvoiceStatus.draft),
    ];

    container = ProviderContainer(
      overrides: [
        invoicesProvider.overrideWith((ref) => Stream.value(invoices)),
      ],
    );

    // Keep provider alive
    container.listen(revenueMetricsProvider, (_, __) {});

    final metrics = await container.read(revenueMetricsProvider.future);

    // Unpaid = Sent + Overdue = 200 + 300 + 400 = 900
    expect(metrics.unpaidAmount, 900.0);

    // Overdue Count = (Status.overdue) + (Status.sent & pastDue)
    // ID 3 (Sent, PastDue) + ID 4 (Overdue) = 2
    expect(metrics.overdueCount, 2);
  });
}
