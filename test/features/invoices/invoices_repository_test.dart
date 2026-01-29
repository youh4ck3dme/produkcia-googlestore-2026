import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:bizagent/features/invoices/providers/invoices_repository.dart';
import 'package:bizagent/features/invoices/models/invoice_model.dart';
import 'package:bizagent/core/services/local_persistence_service.dart';

class FakeLocalPersistenceService extends LocalPersistenceService {
  @override
  List<Map<String, dynamic>> getInvoices() => [];
  @override
  Future<void> saveInvoice(String id, Map<String, dynamic> data) async {}
  @override
  Future<void> deleteInvoice(String id) async {}
}

void main() {
  group('InvoicesRepository', () {
    late FakeFirebaseFirestore fakeFirestore;
    late InvoicesRepository repository;
    const userId = 'test-user-123';

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      repository = InvoicesRepository(fakeFirestore, FakeLocalPersistenceService());
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

    test('addInvoice adds document to Firestore', () async {
      await repository.addInvoice(userId, dummyInvoice);

      final snapshot = await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('invoices')
          .get();

      expect(snapshot.docs.length, 1);
      final data = snapshot.docs.first.data();
      expect(data['number'], '2023001');
      expect(data['clientName'], 'Test Client');
      expect(data['items'], isNotEmpty);
    });

    test('getInvoices returns list of invoices sorted by dateIssued desc',
        () async {
      // Add multiple invoices
      final invoice1 = dummyInvoice; // Oct 1
      final invoice2 = InvoiceModel(
        id: 'invoice-2',
        userId: userId,
        createdAt: DateTime(2023, 11, 1),
        number: '2023002',
        clientName: 'Client 2',
        dateIssued: DateTime(2023, 11, 1), // Newer
        dateDue: DateTime(2023, 11, 15),
        items: [],
        totalAmount: 0,
        status: InvoiceStatus.draft,
      );

      // Add to firestore manually to mock existing data
      final collection =
          fakeFirestore.collection('users').doc(userId).collection('invoices');
      await collection.doc(invoice1.id).set(invoice1.toMap());
      await collection.doc(invoice2.id).set(invoice2.toMap());

      final results = await repository.getInvoices(userId);

      expect(results.length, 2);
      // specific assertion for descending order
      expect(results[0].number, '2023002'); // Newer should be first
      expect(results[1].number, '2023001');
    });

    test('updateInvoice updates existing document', () async {
      // Add initial
      await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('invoices')
          .doc(dummyInvoice.id)
          .set(dummyInvoice.toMap());

      // Modify
      final updatedInvoice = InvoiceModel(
        id: dummyInvoice.id,
        userId: userId,
        createdAt: dummyInvoice.createdAt,
        number: '2023001',
        clientName: 'Updated Client Name', // Changed
        dateIssued: dummyInvoice.dateIssued,
        dateDue: dummyInvoice.dateDue,
        items: dummyInvoice.items,
        totalAmount: dummyInvoice.totalAmount,
        status: dummyInvoice.status,
      );

      await repository.updateInvoice(userId, updatedInvoice);

      final doc = await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('invoices')
          .doc(dummyInvoice.id)
          .get();

      expect(doc.data()?['clientName'], 'Updated Client Name');
    });

    test('deleteInvoice removes document', () async {
      // Add initial
      await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('invoices')
          .doc(dummyInvoice.id)
          .set(dummyInvoice.toMap());

      await repository.deleteInvoice(userId, dummyInvoice.id);

      final snapshot = await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('invoices')
          .get();

      expect(snapshot.docs.length, 0);
    });

    test('watchInvoices emits updates from Firestore', () async {
      // Expect empty then 1 item
      expectLater(
        repository.watchInvoices(userId),
        emitsInOrder([
          isEmpty,
          // FakeFirestore may emit an initial empty snapshot more than once.
          isEmpty,
          isA<List<InvoiceModel>>().having((l) => l.length, 'length', 1),
        ]),
      );

      // Add invoice triggers stream (simulate delay to ensure listener is active)
      await Future.delayed(Duration.zero);
      await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('invoices')
          .add(dummyInvoice.toMap());
    });
  });
}
