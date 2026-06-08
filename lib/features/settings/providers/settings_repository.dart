import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase/supabase_config.dart';
import '../models/user_settings_model.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(
    SupabaseConfig.isConfigured ? SupabaseConfig.client : null,
  );
});

/// Nastavenia používateľa — Supabase (tabuľka `user_settings`, 1 riadok / user).
class SettingsRepository {
  final SupabaseClient? _client;

  SettingsRepository(this._client);

  static const _table = 'user_settings';

  Stream<UserSettingsModel> watchSettings(String userId) {
    final client = _client;
    if (client == null) {
      return Stream<UserSettingsModel>.value(UserSettingsModel.empty());
    }
    return client
        .from(_table)
        .stream(primaryKey: ['user_id'])
        .eq('user_id', userId)
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
    final client = _client;
    if (client == null) return UserSettingsModel.empty();

    final row = await client
        .from(_table)
        .select('data')
        .eq('user_id', userId)
        .maybeSingle();

    final data = row?['data'];
    if (data is Map) {
      return UserSettingsModel.fromMap(Map<String, dynamic>.from(data));
    }
    return UserSettingsModel.empty();
  }

  Future<void> updateSettings(String userId, UserSettingsModel settings) async {
    await _client?.from(_table).upsert({
      'user_id': userId,
      'data': settings.toMap(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}
