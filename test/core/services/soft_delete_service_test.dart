import 'package:flutter_test/flutter_test.dart';
import 'package:bizagent/core/services/soft_delete_service.dart';
import '../../helpers/in_memory_supabase_store.dart';

void main() {
  group('SoftDeleteService', () {
    late InMemorySupabaseStore store;
    late SoftDeleteService service;

    setUp(() {
      store = InMemorySupabaseStore();
      service = SoftDeleteService(store);
    });

    group('softDeleteItem', () {
      test('should mark invoice as deleted in trash_items', () async {
        const collection = SoftDeleteCollections.invoices;
        const userId = 'user123';
        const itemId = 'invoice1';

        await store.upsert('invoices', {
          'id': itemId,
          'user_id': userId,
          'data': {'name': 'Test Invoice', 'amount': 100.0, 'number': '2026-001'},
          'is_deleted': false,
        });

        await service.softDeleteItem(collection, userId, itemId);

        final trash = await store.select(
          'trash_items',
          eq: {'user_id': userId, 'collection': collection, 'id': itemId},
        );
        final invoice = await store.select(
          'invoices',
          eq: {'id': itemId, 'user_id': userId},
        );

        expect(trash.length, 1);
        expect(trash.first['data']['name'], 'Test Invoice');
        expect(trash.first['data']['deletedAt'], isNotNull);
        expect(invoice.first['is_deleted'], true);
      });

      test('should include delete reason when provided', () async {
        const collection = SoftDeleteCollections.invoices;
        const userId = 'user123';
        const itemId = 'invoice1';
        const reason = 'User requested deletion';

        await store.upsert('invoices', {
          'id': itemId,
          'user_id': userId,
          'data': {'name': 'Test Invoice'},
          'is_deleted': false,
        });

        await service.softDeleteItem(
          collection,
          userId,
          itemId,
          reason: reason,
        );

        final trash = await store.select(
          'trash_items',
          eq: {'user_id': userId, 'collection': collection, 'id': itemId},
        );

        expect(trash.first['data']['deleteReason'], reason);
      });
    });

    group('restoreItem', () {
      test('should restore invoice and remove trash entry', () async {
        const collection = SoftDeleteCollections.invoices;
        const userId = 'user123';
        const itemId = 'invoice1';

        await store.upsert('invoices', {
          'id': itemId,
          'user_id': userId,
          'data': {'name': 'Test Invoice', 'status': 'draft'},
          'is_deleted': true,
        });
        await store.upsert('trash_items', {
          'id': itemId,
          'user_id': userId,
          'collection': collection,
          'data': {
            'name': 'Test Invoice',
            'status': 'draft',
            'deletedAt': DateTime.now().toIso8601String(),
            'deleteReason': 'Test reason',
          },
          'deleted_at': DateTime.now().toIso8601String(),
        });

        await service.restoreItem(collection, userId, itemId);

        final trash = await store.select(
          'trash_items',
          eq: {'user_id': userId, 'collection': collection},
        );
        final invoice = await store.select(
          'invoices',
          eq: {'id': itemId, 'user_id': userId},
        );

        expect(trash, isEmpty);
        expect(invoice.first['is_deleted'], false);
        expect(invoice.first['data']['deletedAt'], isNull);
      });
    });

    group('cleanupExpiredItems', () {
      test('should permanently delete items older than 7 days', () async {
        const collection = SoftDeleteCollections.invoices;
        const userId = 'user123';
        final eightDaysAgo =
            DateTime.now().subtract(const Duration(days: 8)).toIso8601String();
        final sixDaysAgo =
            DateTime.now().subtract(const Duration(days: 6)).toIso8601String();

        await store.upsert('trash_items', {
          'id': 'expired1',
          'user_id': userId,
          'collection': collection,
          'data': {'name': 'Expired'},
          'deleted_at': eightDaysAgo,
        });
        await store.upsert('invoices', {
          'id': 'expired1',
          'user_id': userId,
          'data': {'name': 'Expired'},
          'is_deleted': true,
        });
        await store.upsert('trash_items', {
          'id': 'recent1',
          'user_id': userId,
          'collection': collection,
          'data': {'name': 'Recent'},
          'deleted_at': sixDaysAgo,
        });

        await service.cleanupExpiredItems(collection, userId);

        final rows = await store.select(
          'trash_items',
          eq: {'user_id': userId, 'collection': collection},
        );

        expect(rows.length, 1);
        expect(rows.first['id'], 'recent1');
      });
    });

    group('getTrashItems', () {
      test('should return only items deleted within last 7 days', () async {
        const collection = SoftDeleteCollections.invoices;
        const userId = 'user123';
        final sixDaysAgo =
            DateTime.now().subtract(const Duration(days: 6)).toIso8601String();
        final eightDaysAgo =
            DateTime.now().subtract(const Duration(days: 8)).toIso8601String();

        await store.upsert('trash_items', {
          'id': 'recent1',
          'user_id': userId,
          'collection': collection,
          'data': {'name': 'Recent'},
          'deleted_at': sixDaysAgo,
        });
        await store.upsert('trash_items', {
          'id': 'expired1',
          'user_id': userId,
          'collection': collection,
          'data': {'name': 'Expired'},
          'deleted_at': eightDaysAgo,
        });

        final items = await service.getTrashItems(collection, userId).first;

        expect(items.length, 1);
        expect(items.first['id'], 'recent1');
        expect(items.first['collection'], collection);
      });
    });

    group('getTrashCount', () {
      test('should return count of items in trash', () async {
        const collection = SoftDeleteCollections.invoices;
        const userId = 'user123';
        final sixDaysAgo =
            DateTime.now().subtract(const Duration(days: 6)).toIso8601String();

        await store.upsert('trash_items', {
          'id': 'item1',
          'user_id': userId,
          'collection': collection,
          'data': {},
          'deleted_at': sixDaysAgo,
        });
        await store.upsert('trash_items', {
          'id': 'item2',
          'user_id': userId,
          'collection': collection,
          'data': {},
          'deleted_at': sixDaysAgo,
        });

        final count = await service.getTrashCount(collection, userId).first;

        expect(count, 2);
      });
    });

    group('permanentDeleteItem', () {
      test('should permanently delete trash and invoice row', () async {
        const collection = SoftDeleteCollections.invoices;
        const userId = 'user123';
        const itemId = 'invoice1';

        await store.upsert('trash_items', {
          'id': itemId,
          'user_id': userId,
          'collection': collection,
          'data': {'name': 'Test Invoice'},
          'deleted_at': DateTime.now().toIso8601String(),
        });
        await store.upsert('invoices', {
          'id': itemId,
          'user_id': userId,
          'data': {'name': 'Test Invoice'},
          'is_deleted': true,
        });

        await service.permanentDeleteItem(collection, userId, itemId);

        final trash = await store.select('trash_items', eq: {'id': itemId});
        final invoice = await store.select('invoices', eq: {'id': itemId});

        expect(trash, isEmpty);
        expect(invoice, isEmpty);
      });
    });

    group('emptyTrash', () {
      test('should permanently delete all items in trash', () async {
        const collection = SoftDeleteCollections.invoices;
        const userId = 'user123';
        final sixDaysAgo =
            DateTime.now().subtract(const Duration(days: 6)).toIso8601String();

        await store.upsert('trash_items', {
          'id': 'item1',
          'user_id': userId,
          'collection': collection,
          'data': {},
          'deleted_at': sixDaysAgo,
        });
        await store.upsert('trash_items', {
          'id': 'item2',
          'user_id': userId,
          'collection': collection,
          'data': {},
          'deleted_at': sixDaysAgo,
        });

        await service.emptyTrash(collection, userId);

        final rows = await store.select(
          'trash_items',
          eq: {'user_id': userId, 'collection': collection},
        );

        expect(rows, isEmpty);
      });
    });
  });
}