class BizBotMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime createdAt;

  const BizBotMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.createdAt,
  });

  /// Z riadku Supabase tabuľky `bizbot_messages`.
  static BizBotMessage fromRow(Map<String, dynamic> row) {
    final text = (row['text'] as String?)?.trim() ?? '';
    final isUser = row['is_user'] == true;

    DateTime createdAt;
    final created = row['created_at'];
    if (created is String) {
      createdAt = DateTime.tryParse(created) ?? DateTime.fromMillisecondsSinceEpoch(0);
    } else {
      createdAt = DateTime.fromMillisecondsSinceEpoch(0);
    }

    return BizBotMessage(
      id: row['id']?.toString() ?? '',
      text: text,
      isUser: isUser,
      createdAt: createdAt,
    );
  }
}
