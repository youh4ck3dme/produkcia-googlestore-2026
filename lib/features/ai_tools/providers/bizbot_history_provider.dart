import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../auth/providers/auth_repository.dart';
import '../models/bizbot_message.dart';

/// História BizBot konverzácie — Supabase (tabuľka `bizbot_messages`).
class BizBotHistoryRepository {
  BizBotHistoryRepository(this._client);

  final SupabaseClient? _client;

  static const _table = 'bizbot_messages';
  static const _thread = 'main';

  Stream<List<BizBotMessage>> streamMessages(String uid, {int limit = 100}) {
    final client = _client;
    if (client == null) return Stream.value(const <BizBotMessage>[]);

    return client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('user_id', uid)
        .order('created_at')
        .limit(limit)
        .map((rows) => rows
            .map((r) => BizBotMessage.fromRow(Map<String, dynamic>.from(r)))
            .toList());
  }

  Future<void> addMessage({
    required String uid,
    required String text,
    required bool isUser,
  }) async {
    await _client?.from(_table).insert({
      'user_id': uid,
      'thread_id': _thread,
      'text': text,
      'is_user': isUser,
    });
  }

  Future<void> clearThread(String uid) async {
    await _client
        ?.from(_table)
        .delete()
        .eq('user_id', uid)
        .eq('thread_id', _thread);
  }
}

final bizBotHistoryRepositoryProvider = Provider<BizBotHistoryRepository>((ref) {
  return BizBotHistoryRepository(
    SupabaseConfig.isConfigured ? SupabaseConfig.client : null,
  );
});

final bizBotMessagesProvider = StreamProvider<List<BizBotMessage>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(const <BizBotMessage>[]);
  final repo = ref.watch(bizBotHistoryRepositoryProvider);
  return repo.streamMessages(user.id);
});
