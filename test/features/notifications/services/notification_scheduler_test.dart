import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:bizagent/features/notifications/services/notification_service.dart';
import 'package:bizagent/features/notifications/services/notification_scheduler.dart';
import 'package:bizagent/features/invoices/providers/invoices_provider.dart';
import 'package:bizagent/features/invoices/models/invoice_model.dart';
import 'package:bizagent/features/tax/providers/tax_provider.dart';
import 'package:bizagent/features/tax/models/tax_deadline_model.dart';

import 'notification_scheduler_test.mocks.dart';

@GenerateMocks([NotificationService])
void main() {
  late MockNotificationService mockService;
  late ProviderContainer container;

  setUp(() {
    mockService = MockNotificationService();

    container = ProviderContainer(
      overrides: [
        notificationServiceProvider.overrideWithValue(mockService),
        invoicesProvider.overrideWith((ref) => Stream.value([
              InvoiceModel(
      createdAt: DateTime.now(),
                id: 'inv-1',
                userId: 'u1',
                clientName: 'Client A',
                clientIco: '123',
                number: '2024001',
                dateIssued: DateTime.now(),
                dateDue:
                    DateTime.now().add(const Duration(days: 4)), // In 4 days
                status: InvoiceStatus.sent,
                items: [],
                totalAmount: 100,
                variableSymbol: '2024001',
              ),
              InvoiceModel(
      createdAt: DateTime.now(),
                id: 'inv-2',
                userId: 'u1',
                clientName: 'Client B',
                clientIco: '456',
                number: '2024002',
                dateIssued: DateTime.now(),
                dateDue: DateTime.now()
                    .subtract(const Duration(days: 1)), // Already due
                status: InvoiceStatus.sent,
                items: [],
                totalAmount: 200,
                variableSymbol: '2024002',
              ),
            ])),
        upcomingTaxDeadlinesProvider.overrideWithValue([
          TaxDeadlineModel(
            title: 'VAT Q1',
            date: DateTime.now().add(const Duration(days: 10)),
            description: 'Desc',
          ),
        ]),
      ],
    );

    when(mockService.scheduleNotification(
      id: anyNamed('id'),
      title: anyNamed('title'),
      body: anyNamed('body'),
      scheduledDate: anyNamed('scheduledDate'),
      payload: anyNamed('payload'),
    )).thenAnswer((_) async => {});
  });

  test(
      'NotificationScheduler should schedule alerts for sent invoices and tax deadlines',
      () async {
    // Ensure data is loaded
    await container.read(invoicesProvider.future);

    final scheduler = container.read(notificationSchedulerProvider);

    await scheduler.scheduleAllAlerts();

    // Verify Invoice alert
    verify(mockService.scheduleNotification(
      id: anyNamed('id'),
      title: anyNamed('title'),
      body: anyNamed('body'),
      scheduledDate: anyNamed('scheduledDate'),
      payload: anyNamed('payload'),
    )).called(3); // 1 invoice + 1 tax + 1 summary
  });
}
