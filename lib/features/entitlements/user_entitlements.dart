import 'dart:convert';

class UserEntitlements {
  final bool isPro;
  final String? activePlanId;
  final DateTime? expiryDate;
  
  final int invoiceCount;
  final int icoLookupsCount;
  final int aiRequestsCount;

  const UserEntitlements({
    this.isPro = false,
    this.activePlanId,
    this.expiryDate,
    this.invoiceCount = 0,
    this.icoLookupsCount = 0,
    this.aiRequestsCount = 0,
  });

  bool get isFree => !isPro;

  bool get isExpired =>
      expiryDate != null && expiryDate!.isBefore(DateTime.now());

  UserEntitlements copyWith({
    bool? isPro,
    String? activePlanId,
    DateTime? expiryDate,
    int? invoiceCount,
    int? icoLookupsCount,
    int? aiRequestsCount,
  }) {
    return UserEntitlements(
      isPro: isPro ?? this.isPro,
      activePlanId: activePlanId ?? this.activePlanId,
      expiryDate: expiryDate ?? this.expiryDate,
      invoiceCount: invoiceCount ?? this.invoiceCount,
      icoLookupsCount: icoLookupsCount ?? this.icoLookupsCount,
      aiRequestsCount: aiRequestsCount ?? this.aiRequestsCount,
    );
  }

  factory UserEntitlements.free() => const UserEntitlements();

  Map<String, dynamic> toJson() => {
        'isPro': isPro,
        'activePlanId': activePlanId,
        'expiryDate': expiryDate?.toIso8601String(),
      };

  factory UserEntitlements.fromJson(Map<String, dynamic> json) {
    return UserEntitlements(
      isPro: json['isPro'] as bool? ?? false,
      activePlanId: json['activePlanId'] as String?,
      expiryDate: json['expiryDate'] != null
          ? DateTime.tryParse(json['expiryDate'] as String)
          : null,
    );
  }

  static const spKey = 'cached_entitlements';

  String toSpString() => jsonEncode(toJson());

  static UserEntitlements? fromSpString(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return UserEntitlements.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
