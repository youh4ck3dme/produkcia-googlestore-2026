class CompanyInfo {
  final String name;
  final String ico;
  final String? dic;
  final String? icDph;
  final String address;

  const CompanyInfo({
    required this.name,
    required this.ico,
    this.dic,
    this.icDph,
    required this.address,
  });

  factory CompanyInfo.fromMap(Map<String, dynamic> map) {
    return CompanyInfo(
      name: map['name'] ?? '',
      ico: map['ico'] ?? '',
      dic: map['dic'],
      icDph: map['icDph'],
      address: map['address'] ?? '',
    );
  }
}
