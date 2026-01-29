class UserEntitlements {
  final bool isPro;
  final bool isBusiness;
  final String? activePlanId;
  final DateTime? expiryDate;
  
  // Usage counters (would normally be synced with specific UsageService)
  final int invoiceCount;
  final int icoLookupsCount;
  final int aiRequestsCount;

  const UserEntitlements({
    this.isPro = false,
    this.isBusiness = false,
    this.activePlanId,
    this.expiryDate,
    this.invoiceCount = 0,
    this.icoLookupsCount = 0,
    this.aiRequestsCount = 0,
  });

  bool get isFree => !isPro;

  UserEntitlements copyWith({
    bool? isPro,
    bool? isBusiness,
    String? activePlanId,
    DateTime? expiryDate,
    int? invoiceCount,
    int? icoLookupsCount,
    int? aiRequestsCount,
  }) {
    return UserEntitlements(
      isPro: isPro ?? this.isPro,
      isBusiness: isBusiness ?? this.isBusiness,
      activePlanId: activePlanId ?? this.activePlanId,
      expiryDate: expiryDate ?? this.expiryDate,
      invoiceCount: invoiceCount ?? this.invoiceCount,
      icoLookupsCount: icoLookupsCount ?? this.icoLookupsCount,
      aiRequestsCount: aiRequestsCount ?? this.aiRequestsCount,
    );
  }

  factory UserEntitlements.free() => const UserEntitlements();
}
