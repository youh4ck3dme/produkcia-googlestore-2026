import 'package:flutter_test/flutter_test.dart';
import 'package:bizagent/features/bank_import/models/bank_csv_profile.dart';
import 'package:bizagent/features/bank_import/services/bank_csv_parser_service.dart';

void main() {
  test('parses semicolon CSV with SK headers', () {
    const csv =
        'Dátum;Čas;Typ transakcie;Suma;Mena;Protistrana;IBAN;VS;Správa;Referencia\n'
        '12.01.2026;10:30;Odchod;-100,00;EUR;Firma s.r.o.;SK3112000000198742637541;2024001;Platba za služby;X1\n';

    const svc = BankCsvParserService();
    final res = svc.parse(csvText: csv, profileHint: BankCsvProfile.tatra);

    expect(res.txs.length, 1);
    expect(res.txs.first.amount, -100.0);
    expect(res.txs.first.currency, 'EUR');
    expect(res.txs.first.variableSymbol, '2024001');
  });
}
