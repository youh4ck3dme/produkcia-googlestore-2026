
/// Base model for soft-deletable items following Google/Firebase data retention policies
abstract class SoftDeleteModel {
  final String id;
  final String userId;
  final DateTime createdAt;
  final DateTime? deletedAt; // null = not deleted, set = soft deleted
  final String? deleteReason; // optional reason for deletion

  SoftDeleteModel({
    required this.id,
    required this.userId,
    required this.createdAt,
    this.deletedAt,
    this.deleteReason,
  });

  /// Check if item is soft deleted
  bool get isDeleted => deletedAt != null;

  /// Check if item can still be restored (within 7 days per Google policy)
  bool get canBeRestored {
    if (!isDeleted) return false;
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    return deletedAt!.isAfter(sevenDaysAgo);
  }

  /// Check if item should be permanently deleted (after 7 days)
  bool get shouldBePermanentlyDeleted {
    if (!isDeleted) return false;
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    return deletedAt!.isBefore(sevenDaysAgo);
  }

  /// Mark item as soft deleted
  SoftDeleteModel softDelete({String? reason}) {
    return copyWith(deletedAt: DateTime.now(), deleteReason: reason);
  }

  /// Restore item from soft delete
  SoftDeleteModel restore() {
    return copyWith(deletedAt: null, deleteReason: null);
  }

  /// Create copy with updated fields
  SoftDeleteModel copyWith({
    String? id,
    String? userId,
    DateTime? createdAt,
    DateTime? deletedAt,
    String? deleteReason,
  });

  /// Convert to Firestore document data
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'deleteReason': deleteReason,
    };
  }

  /// Create from Firestore document
  static SoftDeleteModel? fromFirestore(
    Map<String, dynamic> data,
    String docId,
    SoftDeleteModel Function(Map<String, dynamic>) factory,
  ) {
    // If permanently deleted (older than 7 days), don't return
    final deletedAt = data['deletedAt'] != null
        ? DateTime.parse(data['deletedAt'])
        : null;

    if (deletedAt != null) {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      if (deletedAt.isBefore(sevenDaysAgo)) {
        return null; // Permanently deleted, don't return
      }
    }

    return factory(data);
  }
}
