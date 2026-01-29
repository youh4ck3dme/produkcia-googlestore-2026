import 'bank_csv_profile.dart';
import 'bank_tx.dart';
import 'invoice_like.dart';

enum BankMatchType {
  none,
  exactVs,
  amountVs,
  fuzzyName,
  amountOnly,
  manual,
}

class BankMatch {
  final BankTx tx;
  final InvoiceLike? invoice;
  final BankCsvProfile profile;
  final double confidence;

  final String? reason;
  final String? vs;
  final BankMatchType matchType;

  BankMatch({
    BankTx? tx,
    BankTx? transaction, // legacy/expected name from older code
    required this.profile,
    required this.confidence,
    this.invoice,
    this.reason,
    this.vs,
    this.matchType = BankMatchType.none,
  }) : tx = tx ?? transaction!;

  // UI/service compat
  BankTx get transaction => tx;
  bool get isMatched => invoice != null;
  bool get isUnmatched => invoice == null;

  // legacy compat
  String? get variableSymbol => vs ?? tx.variableSymbol;
}
