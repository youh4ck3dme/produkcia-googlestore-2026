import 'dart:async';
import 'package:bizagent/features/ai_tools/models/bizbot_message.dart';

/// In-memory BizBot história pre widget testy (bez Supabase).
class InMemoryBizBotHistoryRepository {
  final _messages = <BizBotMessage>[];
  final _controller = StreamController<List<BizBotMessage>>.broadcast();

  Stream<List<BizBotMessage>> streamMessages(String uid, {int limit = 100}) {
    _controller.add(List.unmodifiable(_messages));
    return _controller.stream;
  }

  Future<void> addMessage({
    required String uid,
    required String text,
    required bool isUser,
  }) async {
    _messages.add(BizBotMessage(
      id: 'msg-${_messages.length}',
      text: text,
      isUser: isUser,
      createdAt: DateTime.now(),
    ));
    _controller.add(List.unmodifiable(_messages));
  }

  Future<void> clearThread(String uid) async {
    _messages.clear();
    _controller.add(const []);
  }

  void dispose() => _controller.close();
}
