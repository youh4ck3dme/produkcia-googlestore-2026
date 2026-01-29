import 'package:flutter_test/flutter_test.dart';
import 'package:bizagent/features/bank_import/models/bank_models.dart';
import 'package:bizagent/features/bank_import/services/bank_match_service.dart';

void main() {
  test('matches invoice by VS and amount', () {
    const invoices = [
      InvoiceLike(
        id: 'inv1',
        number: '2026-0001',
        variableSymbol: '20260001',
        total: 120.00,
        clientName: 'ACME s.r.o.',
      ),
    ];

    final txs = [
      BankTx(
        id: 'test_tx_1',
        date: DateTime(2026, 1, 12),
        amount: 120.00,
        currency: 'EUR',
        counterpartyName: 'ACME s.r.o.',
        counterpartyIban: 'SK1211000000002912345678',
        variableSymbol: '20260001',
        message: 'FA 2026-0001',
        reference: 'X1',
      ),
    ];

    const svc = BankMatchService();
    final res = svc.match(txs: txs, invoices: invoices);

    expect(res.length, 1);
    expect(res.first.invoice?.id, 'inv1');
    expect(res.first.confidence, greaterThan(0.8));
  });
}
