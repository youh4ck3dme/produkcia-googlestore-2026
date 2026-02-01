class IcoPremiumProfile {
  final Map<String, dynamic> data;
  final List<dynamic> related;
  final Map<String, dynamic> meta;
  final String? message;

  const IcoPremiumProfile({
    required this.data,
    required this.related,
    required this.meta,
    required this.message,
  });

  factory IcoPremiumProfile.fromCallable(Map<String, dynamic> json) {
    // Expected:
    // { ok: true, data: {...}, related: [...], meta: {...}, message: "OK" }
    final rawData = json['data'];
    return IcoPremiumProfile(
      data: rawData is Map<String, dynamic> ? rawData : <String, dynamic>{},
      related: (json['related'] is List) ? List<dynamic>.from(json['related'] as List) : const [],
      meta: (json['meta'] is Map<String, dynamic>) ? Map<String, dynamic>.from(json['meta'] as Map) : <String, dynamic>{},
      message: json['message']?.toString(),
    );
  }

  /// Convenience lookup for multiple possible key variants.
  String? pickString(List<String> keys) {
    for (final k in keys) {
      final v = data[k];
      if (v == null) continue;
      final s = v.toString().trim();
      if (s.isNotEmpty) return s;
    }
    return null;
  }

  List<String> pickStringList(List<String> keys) {
    for (final k in keys) {
      final v = data[k];
      if (v is List) {
        return v.map((e) => e?.toString() ?? '').where((s) => s.trim().isNotEmpty).toList();
      }
    }
    return const [];
  }

  // Common fields (best-effort, depends on icoatlas payload).
  String get ico => pickString(['ico', 'IČO', 'icoNorm']) ?? '';
  String get name => pickString(['name', 'company_name', 'companyName']) ?? '';
  String get dic => pickString(['dic', 'dič', 'tax_id']) ?? '';
  String get icDph => pickString(['ic_dph', 'icDph', 'vat_id']) ?? '';
  String get status => pickString(['status', 'company_status']) ?? '';
  String get address => pickString(['address', 'street', 'registered_address']) ?? '';
  String get city => pickString(['city', 'municipality']) ?? '';
  String get zip => pickString(['zip', 'postal_code', 'psc']) ?? '';

  String? get legalForm => pickString(['legal_form', 'legalForm', 'form']);
  String? get registrationDate => pickString(['registration_date', 'registrationDate', 'established_on', 'created_at']);
  String? get nace => pickString(['nace', 'sk_nace', 'activity_code']);
}

