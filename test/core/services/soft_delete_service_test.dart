import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:bizagent/core/services/soft_delete_service.dart';

void main() {
  group('SoftDeleteService', () {
    late FakeFirebaseFirestore fakeFirestore;
    late SoftDeleteService service;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      service = SoftDeleteService(fakeFirestore);
    });

    group('softDeleteItem', () {
      test('should mark item as deleted with deletedAt timestamp', () async {
        // Arrange
        const collection = 'invoices';
        const userId = 'user123';
        const itemId = 'invoice1';

        // Create initial document
        await fakeFirestore
            .collection(collection)
            .doc(userId)
            .collection('items')
            .doc(itemId)
            .set({'name': 'Test Invoice', 'amount': 100.0});

        // Act
        await service.softDeleteItem(collection, userId, itemId);

        // Assert
        final doc = await fakeFirestore
            .collection(collection)
            .doc(userId)
            .collection('items')
            .doc(itemId)
            .get();

        expect(doc.exists, isTrue);
        expect(doc.data()?['deletedAt'], isNotNull);
        expect(doc.data()?['name'], 'Test Invoice'); // Original data preserved
      });

      test('should include delete reason when provided', () async {
        // Arrange
        const collection = 'invoices';
        const userId = 'user123';
        const itemId = 'invoice1';
        const reason = 'User requested deletion';

        await fakeFirestore
            .collection(collection)
            .doc(userId)
            .collection('items')
            .doc(itemId)
            .set({'name': 'Test Invoice'});

        // Act
        await service.softDeleteItem(collection, userId, itemId, reason: reason);

        // Assert
        final doc = await fakeFirestore
            .collection(collection)
            .doc(userId)
            .collection('items')
            .doc(itemId)
            .get();

        expect(doc.data()?['deleteReason'], reason);
      });
    });

    group('restoreItem', () {
      test('should remove deletedAt and deleteReason fields', () async {
        // Arrange
        const collection = 'invoices';
        const userId = 'user123';
        const itemId = 'invoice1';

        await fakeFirestore
            .collection(collection)
            .doc(userId)
            .collection('items')
            .doc(itemId)
            .set({
          'name': 'Test Invoice',
          'deletedAt': DateTime.now(),
          'deleteReason': 'Test reason',
        });

        // Act
        await service.restoreItem(collection, userId, itemId);

        // Assert
        final doc = await fakeFirestore
            .collection(collection)
            .doc(userId)
            .collection('items')
            .doc(itemId)
            .get();

        expect(doc.data()?['deletedAt'], isNull);
        expect(doc.data()?['deleteReason'], isNull);
        expect(doc.data()?['name'], 'Test Invoice'); // Original data preserved
      });
    });

    group('cleanupExpiredItems', () {
      test('should permanently delete items older than 7 days', () async {
        // Arrange
        const collection = 'invoices';
        const userId = 'user123';
        final eightDaysAgo = DateTime.now().subtract(const Duration(days: 8));
        final sixDaysAgo = DateTime.now().subtract(const Duration(days: 6));

        // Create expired item
        await fakeFirestore
            .collection(collection)
            .doc(userId)
            .collection('items')
            .doc('expired1')
            .set({'deletedAt': eightDaysAgo});

        // Create non-expired item
        await fakeFirestore
            .collection(collection)
            .doc(userId)
            .collection('items')
            .doc('recent1')
            .set({'deletedAt': sixDaysAgo});

        // Act
        await service.cleanupExpiredItems(collection, userId);

        // Assert
        final expiredDoc = await fakeFirestore
            .collection(collection)
            .doc(userId)
            .collection('items')
            .doc('expired1')
            .get();
        final recentDoc = await fakeFirestore
            .collection(collection)
            .doc(userId)
            .collection('items')
            .doc('recent1')
            .get();

        expect(expiredDoc.exists, isFalse); // Should be deleted
        expect(recentDoc.exists, isTrue); // Should remain
      });

      test('should not delete anything if no expired items exist', () async {
        // Arrange
        const collection = 'invoices';
        const userId = 'user123';
        final sixDaysAgo = DateTime.now().subtract(const Duration(days: 6));

        await fakeFirestore
            .collection(collection)
            .doc(userId)
            .collection('items')
            .doc('recent1')
            .set({'deletedAt': sixDaysAgo});

        // Act
        await service.cleanupExpiredItems(collection, userId);

        // Assert
        final doc = await fakeFirestore
            .collection(collection)
            .doc(userId)
            .collection('items')
            .doc('recent1')
            .get();

        expect(doc.exists, isTrue);
      });
    });

    group('getTrashItems', () {
      test('should return only items deleted within last 7 days', () async {
        // Arrange
        const collection = 'invoices';
        const userId = 'user123';
        final sixDaysAgo = DateTime.now().subtract(const Duration(days: 6));
        final eightDaysAgo = DateTime.now().subtract(const Duration(days: 8));

        await fakeFirestore
            .collection(collection)
            .doc(userId)
            .collection('items')
            .doc('recent1')
            .set({'name': 'Recent', 'deletedAt': sixDaysAgo});

        await fakeFirestore
            .collection(collection)
            .doc(userId)
            .collection('items')
            .doc('expired1')
            .set({'name': 'Expired', 'deletedAt': eightDaysAgo});

        // Act
        final stream = service.getTrashItems(collection, userId);
        final items = await stream.first;

        // Assert
        expect(items.length, 1);
        expect(items.first['id'], 'recent1');
        expect(items.first['collection'], collection);
      });
    });

    group('getTrashCount', () {
      test('should return count of items in trash', () async {
        // Arrange
        const collection = 'invoices';
        const userId = 'user123';
        final sixDaysAgo = DateTime.now().subtract(const Duration(days: 6));

        await fakeFirestore
            .collection(collection)
            .doc(userId)
            .collection('items')
            .doc('item1')
            .set({'deletedAt': sixDaysAgo});

        await fakeFirestore
            .collection(collection)
            .doc(userId)
            .collection('items')
            .doc('item2')
            .set({'deletedAt': sixDaysAgo});

        // Act
        final stream = service.getTrashCount(collection, userId);
        final count = await stream.first;

        // Assert
        expect(count, 2);
      });
    });

    group('permanentDeleteItem', () {
      test('should permanently delete item', () async {
        // Arrange
        const collection = 'invoices';
        const userId = 'user123';
        const itemId = 'invoice1';

        await fakeFirestore
            .collection(collection)
            .doc(userId)
            .collection('items')
            .doc(itemId)
            .set({'name': 'Test Invoice'});

        // Act
        await service.permanentDeleteItem(collection, userId, itemId);

        // Assert
        final doc = await fakeFirestore
            .collection(collection)
            .doc(userId)
            .collection('items')
            .doc(itemId)
            .get();

        expect(doc.exists, isFalse);
      });
    });

    group('emptyTrash', () {
      test('should permanently delete all items in trash', () async {
        // Arrange
        const collection = 'invoices';
        const userId = 'user123';
        final sixDaysAgo = DateTime.now().subtract(const Duration(days: 6));

        await fakeFirestore
            .collection(collection)
            .doc(userId)
            .collection('items')
            .doc('item1')
            .set({'deletedAt': sixDaysAgo});

        await fakeFirestore
            .collection(collection)
            .doc(userId)
            .collection('items')
            .doc('item2')
            .set({'deletedAt': sixDaysAgo});

        // Act
        await service.emptyTrash(collection, userId);

        // Assert
        final snapshot = await fakeFirestore
            .collection(collection)
            .doc(userId)
            .collection('items')
            .get();

        expect(snapshot.docs.length, 0);
      });
    });
  });
}
