class BankTx {
  final String? id;

  final DateTime date;
  final String counterparty;
  final String message;
  final double amount;
  final String? currency;

  /// Optional VS detected by parser
  final String? vs;

  /// Optional extra identifiers if parser provides them later
  final String? counterpartyIban;
  final String? reference;

  const BankTx({
    this.id,
    required this.date,
    String? counterparty,
    String? counterpartyName,
    String? message,
    required this.amount,
    this.currency,
    String? vs,
    String? variableSymbol,
    this.counterpartyIban,
    this.reference,
  })  : counterparty = counterparty ?? counterpartyName ?? '',
        vs = vs ?? variableSymbol,
        message = message ?? '',
        assert(counterparty != null || counterpartyName != null,
            'counterparty required');

  // Backward/expected getters used by matcher + UI
  String get counterpartyName => counterparty;
  String? get variableSymbol => vs;

  bool get isIncome => amount >= 0;
}
