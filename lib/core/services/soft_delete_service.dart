import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../supabase/supabase_config.dart';
import '../supabase/supabase_providers.dart';
import '../supabase/supabase_table_store.dart';

/// Soft delete cez Supabase `trash_items` + `is_deleted` na faktúrach.
class SoftDeleteService {
  SoftDeleteService(this._store);

  final SupabaseTableStore? _store;

  static const _trashTable = 'trash_items';
  static const _invoicesTable = 'invoices';
  static const _retentionDays = 7;

  DateTime get _sevenDaysAgo =>
      DateTime.now().subtract(const Duration(days: _retentionDays));

  bool _withinRetention(dynamic deletedAt) {
    if (deletedAt == null) return false;
    final dt = deletedAt is DateTime
        ? deletedAt
        : DateTime.tryParse(deletedAt.toString());
    if (dt == null) return false;
    return dt.isAfter(_sevenDaysAgo);
  }

  Future<void> softDeleteItem(
    String collection,
    String userId,
    String itemId, {
    String? reason,
  }) async {
    final store = _store;
    if (store == null || !store.isAvailable) return;

    final now = DateTime.now().toIso8601String();
    var itemData = <String, dynamic>{};

    if (collection == SoftDeleteCollections.invoices) {
      final row = await store.selectMaybeSingle(
        _invoicesTable,
        columns: ['data'],
        eq: {'id': itemId, 'user_id': userId},
      );
      if (row != null) {
        itemData = Map<String, dynamic>.from(row['data'] as Map);
      }
    } else {
      final existing = await store.selectMaybeSingle(
        _trashTable,
        columns: ['data'],
        eq: {'id': itemId, 'user_id': userId, 'collection': collection},
      );
      if (existing != null) {
        itemData = Map<String, dynamic>.from(existing['data'] as Map);
      }
    }

    itemData['deletedAt'] = now;
    if (reason != null) itemData['deleteReason'] = reason;

    await store.upsert(_trashTable, {
      'id': itemId,
      'user_id': userId,
      'collection': collection,
      'data': itemData,
      'deleted_at': now,
    });

    if (collection == SoftDeleteCollections.invoices) {
      await store.update(
        _invoicesTable,
        {'is_deleted': true, 'updated_at': now},
        eq: {'id': itemId, 'user_id': userId},
      );
    }
  }

  Future<void> restoreItem(String collection, String userId, String itemId) async {
    final store = _store;
    if (store == null || !store.isAvailable) return;

    final trash = await store.selectMaybeSingle(
      _trashTable,
      columns: ['data'],
      eq: {'id': itemId, 'user_id': userId, 'collection': collection},
    );

    if (collection == SoftDeleteCollections.invoices && trash != null) {
      final data = Map<String, dynamic>.from(trash['data'] as Map);
      data.remove('deletedAt');
      data.remove('deleteReason');

      await store.upsert(_invoicesTable, {
        'id': itemId,
        'user_id': userId,
        'data': data,
        'date_issued': data['dateIssued'],
        'status': data['status'],
        'is_deleted': false,
        'updated_at': DateTime.now().toIso8601String(),
      });
    }

    await store.delete(
      _trashTable,
      eq: {'id': itemId, 'user_id': userId, 'collection': collection},
    );
  }

  Future<void> cleanupExpiredItems(String collection, String userId) async {
    final store = _store;
    if (store == null || !store.isAvailable) return;

    final rows = await store.select(
      _trashTable,
      eq: {'user_id': userId, 'collection': collection},
    );

    for (final row in rows) {
      if (!_withinRetention(row['deleted_at'])) {
        await _permanentDeleteRow(store, collection, userId, row['id'] as String);
      }
    }
  }

  Stream<List<Map<String, dynamic>>> getTrashItems(
    String collection,
    String userId,
  ) {
    final store = _store;
    if (store == null || !store.isAvailable) {
      return Stream.value([]);
    }

    return store
        .stream(
          _trashTable,
          primaryKey: ['id'],
          eq: {'user_id': userId, 'collection': collection},
          orderColumn: 'deleted_at',
          ascending: false,
        )
        .map((rows) => rows
            .where((row) => _withinRetention(row['deleted_at']))
            .map((row) => {
                  'id': row['id'],
                  'data': {
                    ...Map<String, dynamic>.from(row['data'] as Map),
                    'deletedAt': row['deleted_at'],
                  },
                  'collection': collection,
                })
            .toList());
  }

  Stream<int> getTrashCount(String collection, String userId) {
    return getTrashItems(collection, userId).map((items) => items.length);
  }

  Future<void> permanentDeleteItem(
    String collection,
    String userId,
    String itemId,
  ) async {
    final store = _store;
    if (store == null || !store.isAvailable) return;
    await _permanentDeleteRow(store, collection, userId, itemId);
  }

  Future<void> emptyTrash(String collection, String userId) async {
    final store = _store;
    if (store == null || !store.isAvailable) return;

    final rows = await store.select(
      _trashTable,
      eq: {'user_id': userId, 'collection': collection},
    );

    for (final row in rows) {
      if (_withinRetention(row['deleted_at'])) {
        await _permanentDeleteRow(
          store,
          collection,
          userId,
          row['id'] as String,
        );
      }
    }
  }

  Future<void> _permanentDeleteRow(
    SupabaseTableStore store,
    String collection,
    String userId,
    String itemId,
  ) async {
    if (collection == SoftDeleteCollections.invoices) {
      await store.delete(
        _invoicesTable,
        eq: {'id': itemId, 'user_id': userId},
      );
    }

    await store.delete(
      _trashTable,
      eq: {'id': itemId, 'user_id': userId, 'collection': collection},
    );
  }
}

class SoftDeleteCollections {
  static const String invoices = 'soft_deleted_invoices';
  static const String bizBotConversations = 'soft_deleted_bizbot_conversations';
  static const String notepadItems = 'soft_deleted_notepad_items';
}

final softDeleteServiceProvider = Provider<SoftDeleteService>((ref) {
  return SoftDeleteService(
    SupabaseConfig.isReady
        ? ref.watch(supabaseTableStoreProvider)
        : null,
  );
});