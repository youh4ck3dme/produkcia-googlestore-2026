import 'expense_category.dart';

class ExpenseModel {
  final String id;
  final String userId;
  final String vendorName;
  final String description;
  final double amount;
  final DateTime date;

  // Kategorizácia
  final ExpenseCategory? category;
  final int? categorizationConfidence; // 0-100

  // Správa účteniek
  final List<String> receiptUrls; // Viacero obrázkov
  final String? thumbnailUrl; // Miniatura prvého obrázku
  final DateTime? receiptScannedAt; // Kedy naskenované
  final bool isOcrVerified; // Používateľ potvrdil OCR dáta

  ExpenseModel({
    required this.id,
    required this.userId,
    required this.vendorName,
    required this.description,
    required this.amount,
    required this.date,
    this.category,
    this.categorizationConfidence,
    List<String>? receiptUrls,
    this.thumbnailUrl,
    this.receiptScannedAt,
    this.isOcrVerified = false,
  }) : receiptUrls = receiptUrls ?? [];

  factory ExpenseModel.fromMap(Map<String, dynamic> map, String id) {
    return ExpenseModel(
      id: id,
      userId: map['userId'] ?? '',
      vendorName: map['vendorName'] ?? '',
      description: map['description'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      date: DateTime.parse(map['date']),
      category: expenseCategoryFromString(map['category']),
      categorizationConfidence: map['categorizationConfidence'],
      receiptUrls: map['receiptUrls'] != null
          ? List<String>.from(map['receiptUrls'])
          : [],
      thumbnailUrl: map['thumbnailUrl'],
      receiptScannedAt: map['receiptScannedAt'] != null
          ? DateTime.parse(map['receiptScannedAt'])
          : null,
      isOcrVerified: map['isOcrVerified'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'vendorName': vendorName,
      'description': description,
      'amount': amount,
      'date': date.toIso8601String(),
      'category': category?.name,
      'categorizationConfidence': categorizationConfidence,
      'receiptUrls': receiptUrls,
      'thumbnailUrl': thumbnailUrl,
      'receiptScannedAt': receiptScannedAt?.toIso8601String(),
      'isOcrVerified': isOcrVerified,
    };
  }

  ExpenseModel copyWith({
    String? id,
    String? userId,
    String? vendorName,
    String? description,
    double? amount,
    DateTime? date,
    ExpenseCategory? category,
    int? categorizationConfidence,
    List<String>? receiptUrls,
    String? thumbnailUrl,
    DateTime? receiptScannedAt,
    bool? isOcrVerified,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      vendorName: vendorName ?? this.vendorName,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      categorizationConfidence:
          categorizationConfidence ?? this.categorizationConfidence,
      receiptUrls: receiptUrls ?? this.receiptUrls,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      receiptScannedAt: receiptScannedAt ?? this.receiptScannedAt,
      isOcrVerified: isOcrVerified ?? this.isOcrVerified,
    );
  }
}
