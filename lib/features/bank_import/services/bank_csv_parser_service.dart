// lib/features/bank_import/services/bank_csv_parser_service.dart
import 'dart:convert';

import 'package:csv/csv.dart';

import '../models/bank_csv_profile.dart';
import '../models/bank_tx.dart';

class BankCsvParseResult {
  final BankCsvProfile profile;
  final List<BankTx> txs;
  final List<String> warnings;

  const BankCsvParseResult({
    required this.profile,
    required this.txs,
    required this.warnings,
  });
}

class BankCsvParserService {
  const BankCsvParserService();

  BankCsvParseResult parse({
    required String csvText,
    BankCsvProfile? profileHint,
    String defaultCurrency = 'EUR',
  }) {
    final warnings = <String>[];

    final normalized = _stripBom(csvText).trim();
    if (normalized.isEmpty) {
      return const BankCsvParseResult(
          profile: BankCsvProfile.generic,
          txs: [],
          warnings: ['Empty CSV']);
    }

    final delimiter = _detectDelimiter(normalized);
    final rows = const CsvToListConverter(
      shouldParseNumbers: false,
      eol: '\n',
    ).convert(normalized, fieldDelimiter: delimiter);

    if (rows.isEmpty) {
      return const BankCsvParseResult(
          profile: BankCsvProfile.generic,
          txs: [],
          warnings: ['No rows parsed']);
    }

    final headerRow = rows.first.map((e) => (e ?? '').toString()).toList();
    final dataRows = rows.skip(1).toList();

    final profile = profileHint ?? _bestProfile(headerRow);
    final map = _buildHeaderIndexMap(headerRow, profile);

    if (map['date'] == null) {
      warnings.add('Missing date column (best effort parsing may fail)');
    }
    if (map['amount'] == null) {
      warnings.add('Missing amount column (rows may be skipped)');
    }

    final txs = <BankTx>[];
    for (final raw in dataRows) {
      final row = raw.map((e) => (e ?? '').toString()).toList();

      final amountStr = _at(row, map['amount']);
      final debitStr = _at(row, map['debit']);
      final creditStr = _at(row, map['credit']);

      final amount = _parseAmountPreferSigned(amountStr,
          debitStr: debitStr, creditStr: creditStr);
      if (amount == null) continue;

      final date = _parseDate(_at(row, map['date']));
      if (date == null) continue;

      final currency = (_at(row, map['currency']).isEmpty
              ? defaultCurrency
              : _at(row, map['currency']))
          .toUpperCase();

      final tx = BankTx(
        id: '${date.toIso8601String()}_${amount}_${_at(row, map['counterpartyName'])}',
        date: date,
        amount: amount,
        currency: currency,
        counterpartyName: _at(row, map['counterpartyName']),
        counterpartyIban: _normalizeIban(_at(row, map['counterpartyIban'])),
        variableSymbol: _digitsOnly(_at(row, map['variableSymbol'])),
        message: _at(row, map['message']),
        reference: _at(row, map['reference']),
      );

      txs.add(tx);
    }

    if (txs.isEmpty) {
      warnings.add(
          'No transactions parsed (check delimiter / headers / date format)');
    }

    return BankCsvParseResult(profile: profile, txs: txs, warnings: warnings);
  }

  // ---------- internals ----------

  String _stripBom(String s) {
    final bytes = utf8.encode(s);
    if (bytes.length >= 3 &&
        bytes[0] == 0xEF &&
        bytes[1] == 0xBB &&
        bytes[2] == 0xBF) {
      return utf8.decode(bytes.sublist(3));
    }
    return s;
  }

  String _detectDelimiter(String text) {
    final sample = text.split('\n').take(5).join('\n');
    final candidates = <String, int>{
      ';': _count(sample, ';'),
      ',': _count(sample, ','),
      '\t': _count(sample, '\t'),
      '|': _count(sample, '|'),
    };
    final best =
        candidates.entries.reduce((a, b) => a.value >= b.value ? a : b);
    return best.value == 0 ? ',' : best.key;
  }

  int _count(String s, String ch) => s.split(ch).length - 1;

  BankCsvProfile _bestProfile(List<String> headers) {
    int score(BankCsvProfile p) {
      final hset = headers.map(_normKey).toSet();
      int hits(List<String> candidates) =>
          candidates.map(_normKey).where(hset.contains).length;
      return hits(p.dateHeaders) +
          hits(p.amountHeaders) +
          hits(p.currencyHeaders) +
          hits(p.variableSymbolHeaders) +
          hits(p.counterpartyNameHeaders);
    }

    final all = BankCsvProfile.all;
    all.sort((a, b) => score(b).compareTo(score(a)));
    return all.first;
  }

  Map<String, int?> _buildHeaderIndexMap(
      List<String> headers, BankCsvProfile p) {
    int? findIndex(List<String> candidates) {
      final norms = headers.map(_normKey).toList();
      for (final c in candidates) {
        final idx = norms.indexOf(_normKey(c));
        if (idx >= 0) return idx;
      }
      return null;
    }

    // special: some banks export debit/credit separately; keep hook
    final debitIdx = findIndex(
        const ['debit', 'na ťarchu', 'na tarchu', 'výdavok', 'vydavok']);
    final creditIdx =
        findIndex(const ['credit', 'v prospech', 'príjem', 'prijem']);

    return {
      'date': findIndex(p.dateHeaders),
      'amount': findIndex(p.amountHeaders),
      'currency': findIndex(p.currencyHeaders),
      'counterpartyName': findIndex(p.counterpartyNameHeaders),
      'counterpartyIban': findIndex(p.counterpartyIbanHeaders),
      'variableSymbol': findIndex(p.variableSymbolHeaders),
      'message': findIndex(p.messageHeaders),
      'reference': findIndex(p.referenceHeaders),
      'debit': debitIdx,
      'credit': creditIdx,
    };
  }

  String _at(List<String> row, int? i) {
    if (i == null) return '';
    if (i < 0 || i >= row.length) return '';
    return row[i].trim();
  }

  String _normKey(String s) {
    // lower + strip spaces + basic diacritics
    final low = s.toLowerCase().trim();
    return low
        .replaceAll(' ', '')
        .replaceAll('\u00A0', '')
        .replaceAll('á', 'a')
        .replaceAll('ä', 'a')
        .replaceAll('č', 'c')
        .replaceAll('ď', 'd')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ĺ', 'l')
        .replaceAll('ľ', 'l')
        .replaceAll('ň', 'n')
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('ŕ', 'r')
        .replaceAll('š', 's')
        .replaceAll('ť', 't')
        .replaceAll('ú', 'u')
        .replaceAll('ý', 'y')
        .replaceAll('ž', 'z');
  }

  String _digitsOnly(String s) => s.replaceAll(RegExp(r'[^0-9]'), '');

  String _normalizeIban(String s) => s.replaceAll(' ', '').toUpperCase();

  double? _parseAmountPreferSigned(String s,
      {required String debitStr, required String creditStr}) {
    // If explicit debit/credit exist, use those (credit positive, debit negative)
    final d = _parseDouble(debitStr);
    final c = _parseDouble(creditStr);
    if (c != null && c != 0) return c;
    if (d != null && d != 0) return -d;

    // Otherwise parse signed amount
    return _parseDouble(s);
  }

  double? _parseDouble(String s) {
    var x = s.trim();
    if (x.isEmpty) return null;

    // remove currency symbols and thousands separators
    x = x.replaceAll(RegExp(r'[^\d,\.\-\+]'), '');

    // "1 234,56" -> "1234,56" -> "1234.56"
    // if both comma and dot exist, assume comma thousands and dot decimal OR vice versa
    final hasComma = x.contains(',');
    final hasDot = x.contains('.');
    if (hasComma && !hasDot) {
      x = x.replaceAll('.', '');
      x = x.replaceAll(',', '.');
    } else if (hasComma && hasDot) {
      // choose last separator as decimal
      final lastComma = x.lastIndexOf(',');
      final lastDot = x.lastIndexOf('.');
      if (lastComma > lastDot) {
        x = x.replaceAll('.', '');
        x = x.replaceAll(',', '.');
      } else {
        x = x.replaceAll(',', '');
      }
    }
    return double.tryParse(x);
  }

  DateTime? _parseDate(String s) {
    final x = s.trim();
    if (x.isEmpty) return null;

    // Try ISO first
    final iso = DateTime.tryParse(x);
    if (iso != null) return DateTime(iso.year, iso.month, iso.day);

    // Try dd.mm.yyyy or dd/mm/yyyy
    final m =
        RegExp(r'^(\d{1,2})[\.\/\-](\d{1,2})[\.\/\-](\d{4})').firstMatch(x);
    if (m != null) {
      final d = int.parse(m.group(1)!);
      final mo = int.parse(m.group(2)!);
      final y = int.parse(m.group(3)!);
      return DateTime(y, mo, d);
    }

    // Try yyyy-mm-dd somewhere in string
    final m2 =
        RegExp(r'(\d{4})[\.\/\-](\d{1,2})[\.\/\-](\d{1,2})').firstMatch(x);
    if (m2 != null) {
      final y = int.parse(m2.group(1)!);
      final mo = int.parse(m2.group(2)!);
      final d = int.parse(m2.group(3)!);
      return DateTime(y, mo, d);
    }

    return null;
  }
}
