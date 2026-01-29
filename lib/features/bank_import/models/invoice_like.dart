class InvoiceLike {
  final String id;
  final String number;
  final String variableSymbol;
  final double total;
  final String clientName;

  const InvoiceLike({
    required this.id,
    required this.number,
    required this.variableSymbol,
    required this.total,
    required this.clientName,
  });
}
