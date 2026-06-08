import 'package:flutter_test/flutter_test.dart';
import 'package:bizagent/features/invoices/providers/invoices_repository.dart';
import 'package:bizagent/features/invoices/models/invoice_model.dart';
import '../../helpers/memory_local_persistence.dart';

void main() {
  group('InvoicesRepository (offline / local cache)', () {
    late MemoryLocalPersistenceService persistence;
    late InvoicesRepository repository;
    const userId = 'test-user-123';

    setUp(() {
      persistence = MemoryLocalPersistenceService();
      repository = InvoicesRepository(null, persistence);
    });

    final dummyInvoice = InvoiceModel(
      id: 'invoice-1',
      userId: userId,
      createdAt: DateTime(2023, 10, 1),
      number: '2023001',
      clientName: 'Test Client',
      dateIssued: DateTime(2023, 10, 1),
      dateDue: DateTime(2023, 10, 15),
      items: [
        InvoiceItemModel(title: 'Service A', amount: 100, vatRate: 0.2),
      ],
      totalAmount: 120,
      status: InvoiceStatus.sent,
    );

    test('addInvoice ukladá do lokálnej cache keď Supabase nie je nakonfigurovaný', () async {
      await repository.addInvoice(userId, dummyInvoice);

      final local = persistence.getInvoices();
      expect(local.length, 1);
      expect(local.first['number'], '2023001');
      expect(local.first['clientName'], 'Test Client');
    });

    test('getInvoices vracia lokálne dáta bez Supabase', () async {
      await repository.addInvoice(userId, dummyInvoice);

      final invoice2 = InvoiceModel(
        id: 'invoice-2',
        userId: userId,
        createdAt: DateTime(2023, 11, 1),
        number: '2023002',
        clientName: 'Client 2',
        dateIssued: DateTime(2023, 11, 1),
        dateDue: DateTime(2023, 11, 15),
        items: [],
        totalAmount: 0,
        status: InvoiceStatus.draft,
      );
      await repository.addInvoice(userId, invoice2);

      final results = await repository.getInvoices(userId);
      expect(results.length, 2);
      expect(results.any((i) => i.number == '2023001'), isTrue);
      expect(results.any((i) => i.number == '2023002'), isTrue);
    });

    test('updateInvoice aktualizuje lokálnu cache', () async {
      await repository.addInvoice(userId, dummyInvoice);

      final updated = dummyInvoice.copyWith(clientName: 'Updated Client Name');
      await repository.updateInvoice(userId, updated);

      final results = await repository.getInvoices(userId);
      expect(results.first.clientName, 'Updated Client Name');
    });

    test('deleteInvoice odstráni z lokálnej cache', () async {
      await repository.addInvoice(userId, dummyInvoice);
      await repository.deleteInvoice(userId, dummyInvoice.id);

      expect(persistence.getInvoices(), isEmpty);
    });

    test('watchInvoices emituje lokálne dáta', () async {
      expectLater(
        repository.watchInvoices(userId),
        emits(isA<List<InvoiceModel>>()),
      );

      await repository.addInvoice(userId, dummyInvoice);
    });
  });
}
