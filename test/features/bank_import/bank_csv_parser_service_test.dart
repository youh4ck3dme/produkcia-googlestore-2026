import 'package:flutter_test/flutter_test.dart';
import 'package:bizagent/features/bank_import/models/bank_csv_profile.dart';
import 'package:bizagent/features/bank_import/services/bank_csv_parser_service.dart';

void main() {
  const svc = BankCsvParserService();

  test('parses Tatra banka semicolon CSV', () {
    const csv =
        'Dátum;Čas;Typ transakcie;Suma;Mena;Protistrana;IBAN;VS;Správa;Referencia\n'
        '12.01.2026;10:30;Odchod;-100,00;EUR;Firma s.r.o.;SK3112000000198742637541;2024001;Platba za služby;X1\n';

    final res = svc.parse(csvText: csv, profileHint: BankCsvProfile.tatra);

    expect(res.txs.length, 1);
    expect(res.txs.first.amount, -100.0);
    expect(res.txs.first.currency, 'EUR');
    expect(res.txs.first.variableSymbol, '2024001');
    expect(res.txs.first.counterpartyName, 'Firma s.r.o.');
  });

  test('parses SLSP debit/credit columns', () {
    const csv =
        'Dátum;Na ťarchu účtu;V prospech účtu;Mena;Protistrana;VS;Poznámka\n'
        '15.02.2026;;;EUR;Klient ABC;;; \n'
        '16.02.2026;;250,50;EUR;Klient ABC;998877;/VS998877/ Faktúra\n';

    final res = svc.parse(csvText: csv, profileHint: BankCsvProfile.slsp);

    expect(res.txs.length, 1);
    expect(res.txs.first.amount, 250.5);
    expect(res.txs.first.variableSymbol, '998877');
  });

  test('parses VÚB export with partial header names', () {
    const csv =
        'Dátum zaúčtovania;Suma transakcie;Mena;Názov protiúčtu;Protiúčet;Var. symbol;Popis transakcie\n'
        '03.03.2026;1 200,00;EUR;Beta s.r.o.;SK8330000000001234567890;20260301;Úhrada FA\n';

    final res = svc.parse(csvText: csv, profileHint: BankCsvProfile.vub);

    expect(res.txs.length, 1);
    expect(res.txs.first.amount, 1200.0);
    expect(res.txs.first.variableSymbol, '20260301');
    expect(res.txs.first.counterpartyIban, 'SK8330000000001234567890');
  });

  test('parses ČSOB CSV', () {
    const csv =
        'Dátum zaúčtovania;Suma;Mena;Názov protistrany;Číslo účtu protistrany;Variabilný symbol;Správa pre príjemcu\n'
        '01.04.2026;-45,90;EUR;Dodávateľ XY;SK1234567890123456789012;456789;Nákup materiálu\n';

    final res = svc.parse(csvText: csv, profileHint: BankCsvProfile.csob);

    expect(res.txs.length, 1);
    expect(res.txs.first.amount, -45.9);
    expect(res.txs.first.variableSymbol, '456789');
  });

  test('parses mBank CSV', () {
    const csv =
        'Dátum operácie;Suma;Mena;Protistrana;IBAN;VS;Popis\n'
        '10.05.2026;99,00;EUR;Shop s.r.o.;SK9050000000001234567891;112233;Nákup\n';

    final res = svc.parse(csvText: csv, profileHint: BankCsvProfile.mbank);

    expect(res.txs.length, 1);
    expect(res.txs.first.amount, 99.0);
    expect(res.txs.first.variableSymbol, '112233');
  });

  test('parses 365.bank CSV', () {
    const csv =
        'Dátum uskutočnenia;Suma v EUR;Partner;VS;Správa\n'
        '20.06.2026;15,75;Kaviareň;554433;Káva\n';

    final res = svc.parse(csvText: csv, profileHint: BankCsvProfile.bank365);

    expect(res.txs.length, 1);
    expect(res.txs.first.amount, 15.75);
    expect(res.txs.first.variableSymbol, '554433');
  });

  test('extracts VS from message when VS column is empty', () {
    const csv =
        'Dátum;Suma;Mena;Protistrana;VS;Poznámka\n'
        '01.07.2026;300,00;EUR;Partner s.r.o.;;/VS20260701/ Platba faktúry\n';

    final res = svc.parse(csvText: csv, profileHint: BankCsvProfile.generic);

    expect(res.txs.length, 1);
    expect(res.txs.first.variableSymbol, '20260701');
  });

  test('auto-detects bank profile from headers', () {
    const csv =
        'Dátum zaúčtovania;Suma transakcie;Mena;Názov protiúčtu;Var. symbol\n'
        '01.08.2026;50,00;EUR;Test;123\n';

    final res = svc.parse(csvText: csv);

    expect(res.profile.id, 'vub');
    expect(res.txs.length, 1);
  });
}