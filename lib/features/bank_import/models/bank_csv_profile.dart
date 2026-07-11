class BankCsvProfile {
  final String id;
  final String name;

  /// Candidate header names per field (case-insensitive; diacritics tolerant handled by parser)
  final List<String> dateHeaders;
  final List<String> amountHeaders;
  final List<String> currencyHeaders;
  final List<String> counterpartyNameHeaders;
  final List<String> counterpartyIbanHeaders;
  final List<String> variableSymbolHeaders;
  final List<String> messageHeaders;
  final List<String> referenceHeaders;

  const BankCsvProfile({
    required this.id,
    required this.name,
    required this.dateHeaders,
    required this.amountHeaders,
    required this.currencyHeaders,
    required this.counterpartyNameHeaders,
    required this.counterpartyIbanHeaders,
    required this.variableSymbolHeaders,
    required this.messageHeaders,
    required this.referenceHeaders,
  });

  static const generic = BankCsvProfile(
    id: 'generic',
    name: 'Generic CSV',
    dateHeaders: ['date', 'datum', 'dátum', 'booking date', 'transaction date'],
    amountHeaders: ['amount', 'suma', 'čiastka', 'ciastka', 'debit', 'credit'],
    currencyHeaders: ['currency', 'mena', 'ccy'],
    counterpartyNameHeaders: [
      'counterparty',
      'protistrana',
      'názov protistrany',
      'nazov protistrany',
      'receiver',
      'sender',
      'name'
    ],
    counterpartyIbanHeaders: ['iban', 'ucet', 'účet', 'account'],
    variableSymbolHeaders: [
      'vs',
      'variable symbol',
      'variabilny symbol',
      'variabilný symbol'
    ],
    messageHeaders: [
      'message',
      'poznámka',
      'poznamka',
      'popis',
      'description',
      'purpose'
    ],
    referenceHeaders: ['reference', 'ref', 'id', 'transaction id', 'bank ref'],
  );

  /// Slovak-ish templates (real exports vary; parser still tries best-effort)
  static const tatra = BankCsvProfile(
    id: 'tatrabanka',
    name: 'Tatra banka',
    dateHeaders: ['dátum', 'datum', 'dátum zaúčtovania', 'datum zauctovania'],
    amountHeaders: ['suma', 'čiastka', 'ciastka', 'suma transakcie'],
    currencyHeaders: ['mena', 'currency'],
    counterpartyNameHeaders: [
      'protistrana',
      'názov protistrany',
      'nazov protistrany',
      'príjemca',
      'prijemca',
      'odosielateľ',
      'odosielatel'
    ],
    counterpartyIbanHeaders: [
      'iban',
      'účet protistrany',
      'ucet protistrany',
      'číslo účtu',
      'cislo uctu'
    ],
    variableSymbolHeaders: ['vs', 'variabilný symbol', 'variabilny symbol'],
    messageHeaders: [
      'poznámka',
      'poznamka',
      'popis',
      'správa pre prijímateľa',
      'sprava pre prijimatela'
    ],
    referenceHeaders: ['referencia', 'reference', 'id transakcie', 'id'],
  );

  static const slsp = BankCsvProfile(
    id: 'slsp',
    name: 'Slovenská sporiteľňa',
    dateHeaders: ['dátum', 'datum', 'dátum zaúčtovania', 'datum zauctovania'],
    amountHeaders: ['suma', 'čiastka', 'ciastka', 'hodnota'],
    currencyHeaders: ['mena', 'currency'],
    counterpartyNameHeaders: [
      'protistrana',
      'názov protistrany',
      'nazov protistrany',
      'príjemca',
      'prijemca',
      'odosielateľ',
      'odosielatel'
    ],
    counterpartyIbanHeaders: [
      'iban',
      'účet protistrany',
      'ucet protistrany',
      'číslo účtu',
      'cislo uctu'
    ],
    variableSymbolHeaders: ['vs', 'variabilný symbol', 'variabilny symbol'],
    messageHeaders: ['poznámka', 'poznamka', 'popis', 'správa', 'sprava'],
    referenceHeaders: [
      'referencia',
      'reference',
      'id',
      'identifikátor',
      'identifikator'
    ],
  );

  static const vub = BankCsvProfile(
    id: 'vub',
    name: 'VÚB banka',
    dateHeaders: [
      'dátum',
      'datum',
      'dátum zaúčtovania',
      'datum zauctovania',
      'dátum transakcie',
      'datum transakcie',
    ],
    amountHeaders: ['suma', 'čiastka', 'ciastka', 'suma transakcie', 'hodnota'],
    currencyHeaders: ['mena', 'currency'],
    counterpartyNameHeaders: [
      'protistrana',
      'názov protistrany',
      'nazov protistrany',
      'názov protiúčtu',
      'nazov protiuctu',
      'partner',
    ],
    counterpartyIbanHeaders: [
      'iban',
      'protiúčet',
      'protiucet',
      'účet protistrany',
      'ucet protistrany',
      'číslo účtu',
      'cislo uctu',
    ],
    variableSymbolHeaders: [
      'vs',
      'variabilný symbol',
      'variabilny symbol',
      'var. symbol',
    ],
    messageHeaders: [
      'poznámka',
      'poznamka',
      'popis',
      'správa',
      'sprava',
      'popis transakcie',
      'informácia pre príjemcu',
      'informacia pre prijemcu',
    ],
    referenceHeaders: ['referencia', 'reference', 'id transakcie', 'id'],
  );

  static const csob = BankCsvProfile(
    id: 'csob',
    name: 'ČSOB',
    dateHeaders: [
      'dátum',
      'datum',
      'dátum zaúčtovania',
      'datum zauctovania',
      'dátum transakcie',
      'datum transakcie',
    ],
    amountHeaders: [
      'suma',
      'čiastka',
      'ciastka',
      'suma v eur',
      'suma v mene účtu',
      'suma v mene uctu',
    ],
    currencyHeaders: ['mena', 'currency', 'mena transakcie'],
    counterpartyNameHeaders: [
      'názov protistrany',
      'nazov protistrany',
      'protistrana',
      'partner',
      'príjemca',
      'prijemca',
      'odosielateľ',
      'odosielatel',
    ],
    counterpartyIbanHeaders: [
      'iban',
      'číslo účtu protistrany',
      'cislo uctu protistrany',
      'účet protistrany',
      'ucet protistrany',
      'protiúčet',
      'protiucet',
    ],
    variableSymbolHeaders: [
      'variabilný symbol',
      'variabilny symbol',
      'vs',
      'var. symbol',
    ],
    messageHeaders: [
      'správa pre príjemcu',
      'sprava pre prijemcu',
      'poznámka',
      'poznamka',
      'popis',
      'informácia',
      'informacia',
    ],
    referenceHeaders: ['referencia', 'reference', 'id', 'číslo dokladu', 'cislo dokladu'],
  );

  static const mbank = BankCsvProfile(
    id: 'mbank',
    name: 'mBank',
    dateHeaders: [
      'dátum operácie',
      'datum operacie',
      'dátum',
      'datum',
      'dátum zaúčtovania',
      'datum zauctovania',
    ],
    amountHeaders: ['suma', 'čiastka', 'ciastka', 'suma transakcie'],
    currencyHeaders: ['mena', 'currency'],
    counterpartyNameHeaders: [
      'protistrana',
      'názov protistrany',
      'nazov protistrany',
      'kontrahent',
      'partner',
    ],
    counterpartyIbanHeaders: [
      'iban',
      'účet protistrany',
      'ucet protistrany',
      'číslo účtu',
      'cislo uctu',
    ],
    variableSymbolHeaders: ['vs', 'variabilný symbol', 'variabilny symbol'],
    messageHeaders: ['popis', 'poznámka', 'poznamka', 'správa', 'sprava', 'titul'],
    referenceHeaders: ['referencia', 'reference', 'id transakcie', 'id'],
  );

  static const unicredit = BankCsvProfile(
    id: 'unicredit',
    name: 'UniCredit Bank',
    dateHeaders: [
      'dátum',
      'datum',
      'dátum zaúčtovania',
      'datum zauctovania',
      'booking date',
      'value date',
    ],
    amountHeaders: ['suma', 'čiastka', 'ciastka', 'amount', 'suma transakcie'],
    currencyHeaders: ['mena', 'currency', 'ccy'],
    counterpartyNameHeaders: [
      'protistrana',
      'názov protistrany',
      'nazov protistrany',
      'partner name',
      'partner',
      'príjemca',
      'prijemca',
    ],
    counterpartyIbanHeaders: [
      'iban',
      'partner account',
      'účet protistrany',
      'ucet protistrany',
      'číslo účtu',
      'cislo uctu',
    ],
    variableSymbolHeaders: ['vs', 'variabilný symbol', 'variabilny symbol'],
    messageHeaders: [
      'správa',
      'sprava',
      'poznámka',
      'poznamka',
      'popis',
      'message',
      'details',
    ],
    referenceHeaders: ['referencia', 'reference', 'transaction id', 'id'],
  );

  static const bank365 = BankCsvProfile(
    id: '365bank',
    name: '365.bank',
    dateHeaders: [
      'dátum uskutočnenia',
      'datum uskutocnenia',
      'dátum',
      'datum',
      'dátum zaúčtovania',
      'datum zauctovania',
    ],
    amountHeaders: [
      'suma v eur',
      'suma',
      'čiastka',
      'ciastka',
      'suma transakcie',
    ],
    currencyHeaders: ['mena', 'currency'],
    counterpartyNameHeaders: ['partner', 'protistrana', 'názov', 'nazov', 'príjemca', 'prijemca'],
    counterpartyIbanHeaders: ['iban', 'účet', 'ucet', 'číslo účtu', 'cislo uctu'],
    variableSymbolHeaders: ['vs', 'variabilný symbol', 'variabilny symbol'],
    messageHeaders: ['správa', 'sprava', 'poznámka', 'poznamka', 'popis'],
    referenceHeaders: ['referencia', 'reference', 'id'],
  );

  static const revolut = BankCsvProfile(
    id: 'revolut',
    name: 'Revolut',
    dateHeaders: ['completed date', 'started date', 'date', 'datum'],
    amountHeaders: ['amount', 'paid out', 'paid in'],
    currencyHeaders: ['currency', 'ccy'],
    counterpartyNameHeaders: [
      'description',
      'merchant',
      'counterparty',
      'name'
    ],
    counterpartyIbanHeaders: ['iban', 'counterparty iban', 'account'],
    variableSymbolHeaders: ['vs', 'variable symbol'],
    messageHeaders: ['description', 'notes', 'message'],
    referenceHeaders: ['id', 'reference', 'transaction id'],
  );

  static const all = <BankCsvProfile>[
    generic,
    tatra,
    slsp,
    vub,
    csob,
    mbank,
    unicredit,
    bank365,
    revolut,
  ];
}
