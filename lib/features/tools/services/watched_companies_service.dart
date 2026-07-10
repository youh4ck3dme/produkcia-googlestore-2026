import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_config.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../core/supabase/supabase_table_store.dart';

final watchedCompaniesServiceProvider = Provider<WatchedCompaniesService>((ref) {
  return WatchedCompaniesService(
    SupabaseConfig.isReady ? ref.watch(supabaseTableStoreProvider) : null,
  );
});

class WatchedCompaniesService {
  WatchedCompaniesService(this._store, [this._testUid]);

  final SupabaseTableStore? _store;
  final String? _testUid;

  static const _table = 'watched_companies';

  String? get _uid =>
      _testUid ??
      (SupabaseConfig.isReady
          ? SupabaseConfig.client.auth.currentUser?.id
          : null);

  Future<void> watch(String icoNorm, String name) async {
    final uid = _uid;
    final store = _store;
    if (uid == null || store == null || !store.isAvailable) {
      throw Exception('User not logged in');
    }

    await store.upsert(_table, {
      'ico': icoNorm,
      'user_id': uid,
      'data': {
        'icoNorm': icoNorm,
        'name': name,
        'watchedAt': DateTime.now().toIso8601String(),
      },
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> unwatch(String icoNorm) async {
    final uid = _uid;
    final store = _store;
    if (uid == null || store == null || !store.isAvailable) return;

    await store.delete(
      _table,
      eq: {'user_id': uid, 'ico': icoNorm},
    );
  }

  Stream<bool> isWatched(String icoNorm) {
    final uid = _uid;
    final store = _store;
    if (uid == null || store == null || !store.isAvailable) {
      return Stream.value(false);
    }

    return store
        .stream(
          _table,
          primaryKey: ['ico'],
          eq: {'user_id': uid, 'ico': icoNorm},
        )
        .map((rows) => rows.isNotEmpty);
  }

  Future<int> getWatchedCount() async {
    final uid = _uid;
    final store = _store;
    if (uid == null || store == null || !store.isAvailable) return 0;

    final rows = await store.select(_table, eq: {'user_id': uid});
    return rows.length;
  }

  Stream<List<Map<String, dynamic>>> listWatched() {
    final uid = _uid;
    final store = _store;
    if (uid == null || store == null || !store.isAvailable) {
      return Stream.value([]);
    }

    return store
        .stream(
          _table,
          primaryKey: ['ico'],
          eq: {'user_id': uid},
          orderColumn: 'created_at',
          ascending: false,
        )
        .map((rows) => rows.map((row) {
              final data = Map<String, dynamic>.from(row['data'] as Map);
              data['ico'] = row['ico'];
              return data;
            }).toList());
  }
}