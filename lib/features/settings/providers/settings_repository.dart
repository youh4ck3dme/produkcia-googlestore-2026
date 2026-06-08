import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../core/supabase/supabase_table_store.dart';
import '../models/user_settings_model.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(
    SupabaseConfig.isReady
        ? SupabaseTableStore.fromClient(SupabaseConfig.client)
        : null,
  );
});

/// Nastavenia používateľa — Supabase (tabuľka `user_settings`, 1 riadok / user).
class SettingsRepository {
  final SupabaseTableStore? _store;

  SettingsRepository(this._store);

  static const _table = 'user_settings';

  Stream<UserSettingsModel> watchSettings(String userId) {
    final store = _store;
    if (store == null || !store.isAvailable) {
      return Stream<UserSettingsModel>.value(UserSettingsModel.empty());
    }
    return store
        .stream(
          _table,
          primaryKey: ['user_id'],
          eq: {'user_id': userId},
        )
        .map((rows) {
      if (rows.isEmpty) return UserSettingsModel.empty();
      final data = rows.first['data'];
      if (data is Map) {
        return UserSettingsModel.fromMap(Map<String, dynamic>.from(data));
      }
      return UserSettingsModel.empty();
    });
  }

  Future<UserSettingsModel> getSettings(String userId) async {
    final store = _store;
    if (store == null || !store.isAvailable) return UserSettingsModel.empty();

    final row = await store.selectMaybeSingle(
      _table,
      columns: ['data'],
      eq: {'user_id': userId},
    );

    final data = row?['data'];
    if (data is Map) {
      return UserSettingsModel.fromMap(Map<String, dynamic>.from(data));
    }
    return UserSettingsModel.empty();
  }

  Future<void> updateSettings(String userId, UserSettingsModel settings) async {
    await _store?.upsert(_table, {
      'user_id': userId,
      'data': settings.toMap(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}
