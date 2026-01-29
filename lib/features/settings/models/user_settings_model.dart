class UserSettingsModel {
  final String companyName;
  final String companyAddress;
  final String companyIco;
  final String companyDic;
  final String companyIcDph;
  final String bankAccount;
  final String swift;
  final String registerInfo;
  final bool showQrCode;
  final bool isVatPayer;
  final String? iban;
  final String? companyIban;
  final String? companySwift;
  final bool showQrOnInvoice;
  final bool biometricEnabled;
  final String language;
  final String currency;

  UserSettingsModel({
    required this.companyName,
    required this.companyAddress,
    required this.companyIco,
    required this.companyDic,
    required this.companyIcDph,
    required this.bankAccount,
    required this.swift,
    required this.registerInfo,
    this.showQrCode = true,
    this.isVatPayer = false,
    this.iban,
    this.companyIban,
    this.companySwift,
    this.showQrOnInvoice = false,
    this.biometricEnabled = false,
    this.language = 'sk',
    this.currency = 'EUR',
  });

  factory UserSettingsModel.fromMap(Map<String, dynamic> map) {
    return UserSettingsModel(
      companyName: map['companyName'] ?? '',
      companyAddress: map['companyAddress'] ?? '',
      companyIco: map['companyIco'] ?? '',
      companyDic: map['companyDic'] ?? '',
      companyIcDph: map['companyIcDph'] ?? '',
      bankAccount: map['bankAccount'] ?? '',
      swift: map['swift'] ?? '',
      registerInfo: map['registerInfo'] ?? '',
      showQrCode: map['showQrCode'] ?? true,
      isVatPayer: map['isVatPayer'] ?? false,
      iban: map['iban'],
      companyIban: map['companyIban'],
      companySwift: map['companySwift'],
      showQrOnInvoice: map['showQrOnInvoice'] ?? false,
      biometricEnabled: map['biometricEnabled'] ?? false,
      language: map['language'] ?? 'sk',
      currency: map['currency'] ?? 'EUR',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'companyName': companyName,
      'companyAddress': companyAddress,
      'companyIco': companyIco,
      'companyDic': companyDic,
      'companyIcDph': companyIcDph,
      'bankAccount': bankAccount,
      'swift': swift,
      'registerInfo': registerInfo,
      'showQrCode': showQrCode,
      'isVatPayer': isVatPayer,
      'iban': iban,
      'companyIban': companyIban,
      'companySwift': companySwift,
      'showQrOnInvoice': showQrOnInvoice,
      'biometricEnabled': biometricEnabled,
      'language': language,
      'currency': currency,
    };
  }

  UserSettingsModel copyWith({
    String? companyName,
    String? companyAddress,
    String? companyIco,
    String? companyDic,
    String? companyIcDph,
    String? bankAccount,
    String? swift,
    String? registerInfo,
    bool? showQrCode,
    bool? isVatPayer,
    String? iban,
    String? companyIban,
    String? companySwift,
    bool? showQrOnInvoice,
    bool? biometricEnabled,
    String? language,
    String? currency,
  }) {
    return UserSettingsModel(
      companyName: companyName ?? this.companyName,
      companyAddress: companyAddress ?? this.companyAddress,
      companyIco: companyIco ?? this.companyIco,
      companyDic: companyDic ?? this.companyDic,
      companyIcDph: companyIcDph ?? this.companyIcDph,
      bankAccount: bankAccount ?? this.bankAccount,
      swift: swift ?? this.swift,
      registerInfo: registerInfo ?? this.registerInfo,
      showQrCode: showQrCode ?? this.showQrCode,
      isVatPayer: isVatPayer ?? this.isVatPayer,
      iban: iban ?? this.iban,
      companyIban: companyIban ?? this.companyIban,
      companySwift: companySwift ?? this.companySwift,
      showQrOnInvoice: showQrOnInvoice ?? this.showQrOnInvoice,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      language: language ?? this.language,
      currency: currency ?? this.currency,
    );
  }

  static UserSettingsModel empty() => UserSettingsModel(
        companyName: '',
        companyAddress: '',
        companyIco: '',
        companyDic: '',
        companyIcDph: '',
        bankAccount: '',
        swift: '',
        registerInfo: '',
        showQrCode: true,
        isVatPayer: false,
        iban: null,
        showQrOnInvoice: false,
        biometricEnabled: false,
        language: 'sk',
        currency: 'EUR',
      );
}
