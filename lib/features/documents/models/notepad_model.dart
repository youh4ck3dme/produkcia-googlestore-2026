import '../../../core/models/soft_delete_model.dart';

enum NotepadItemType {
  note,
  receipt,
  memo,
  reminder,
  other,
}

extension NotepadItemTypeX on NotepadItemType {
  String toSlovak() {
    switch (this) {
      case NotepadItemType.note:
        return 'Poznámka';
      case NotepadItemType.receipt:
        return 'Blok';
      case NotepadItemType.memo:
        return 'Memo';
      case NotepadItemType.reminder:
        return 'Pripomienka';
      case NotepadItemType.other:
        return 'Iné';
    }
  }
}

class NotepadItemModel extends SoftDeleteModel {
  final String title;
  final String content;
  final NotepadItemType type;
  final List<String>? attachments; // URLs to attached files/images
  final Map<String, dynamic>? metadata; // Additional data like OCR results, amounts, etc.
  final DateTime lastModified;

  NotepadItemModel({
    required super.id,
    required super.userId,
    required super.createdAt,
    super.deletedAt,
    super.deleteReason,
    required this.title,
    required this.content,
    required this.type,
    this.attachments,
    this.metadata,
    required this.lastModified,
  });

  @override
  NotepadItemModel copyWith({
    String? id,
    String? userId,
    DateTime? createdAt,
    DateTime? deletedAt,
    String? deleteReason,
    String? title,
    String? content,
    NotepadItemType? type,
    List<String>? attachments,
    Map<String, dynamic>? metadata,
    DateTime? lastModified,
  }) {
    return NotepadItemModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt,
      deleteReason: deleteReason,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      attachments: attachments ?? this.attachments,
      metadata: metadata ?? this.metadata,
      lastModified: lastModified ?? this.lastModified,
    );
  }

  factory NotepadItemModel.fromMap(Map<String, dynamic> map, String id) {
    return NotepadItemModel(
      id: id,
      userId: map['userId'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      deletedAt: map['deletedAt'] != null
          ? DateTime.parse(map['deletedAt'])
          : null,
      deleteReason: map['deleteReason'],
      title: map['title'] ?? 'Bez názvu',
      content: map['content'] ?? '',
      type: NotepadItemType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => NotepadItemType.note,
      ),
      attachments: (map['attachments'] as List<dynamic>?)?.cast<String>(),
      metadata: map['metadata'],
      lastModified: map['lastModified'] != null
          ? DateTime.parse(map['lastModified'])
          : DateTime.now(),
    );
  }

  @override
  Map<String, dynamic> toFirestore() {
    return {
      ...super.toFirestore(),
      'title': title,
      'content': content,
      'type': type.name,
      'attachments': attachments,
      'metadata': metadata,
      'lastModified': lastModified.toIso8601String(),
    };
  }

  // Helper getters for receipt-specific data
  double? get receiptAmount => metadata?['amount'] as double?;
  String? get receiptVendor => metadata?['vendor'] as String?;
  DateTime? get receiptDate => metadata?['date'] != null
      ? DateTime.parse(metadata!['date'])
      : null;
}
