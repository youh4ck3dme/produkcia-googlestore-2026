import 'dart:convert';
import 'dart:typed_data';
import 'package:base32/base32.dart';
import 'package:lzma/lzma.dart';

class PayBySquareService {
  /// Generates the PAY by square string for an invoice.
  static String generateString({
    required String iban,
    required String swift,
    required double amount,
    required String variableSymbol,
    required String recipientName,
    String currency = 'EUR',
    String? constantSymbol,
    String? specificSymbol,
    String? note,
    String? dateDue, // YYYY-MM-DD
  }) {
    // 1. Construct XML
    final xml = _buildXml(
      iban: iban,
      swift: swift,
      amount: amount,
      currency: currency,
      variableSymbol: variableSymbol,
      constantSymbol: constantSymbol,
      specificSymbol: specificSymbol,
      recipientName: recipientName,
      note: note,
      dateDue: dateDue,
    );

    // 2. Compress via LZMA
    // Uses 'lzma' package
    final List<int> compressed = _compressLzma(utf8.encode(xml));

    // 3. Base32 Encode
    // Returns the string that can be put into QR code
    return base32.encode(Uint8List.fromList(compressed));
  }

  static String _buildXml({
    required String iban,
    required String swift,
    required double amount,
    required String currency,
    required String variableSymbol,
    String? constantSymbol,
    String? specificSymbol,
    required String recipientName,
    String? note,
    String? dateDue,
  }) {
    final buffer = StringBuffer();
    // Simple XML construction without external dependency for simplicity
    buffer.write('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.write(
        '<BySquare xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://www.bysquare.com/bysquare_schema.xsd">');
    buffer.write('<Invoice>');
    buffer.write('<DirectPayment>');
    buffer.write('<Payment>');
    buffer.write('<PaymentOptions>payment_order</PaymentOptions>');
    buffer.write('<Amount>${amount.toStringAsFixed(2)}</Amount>');
    buffer.write('<CurrencyCode>$currency</CurrencyCode>');
    if (dateDue != null) {
      buffer.write('<PaymentDueDate>$dateDue</PaymentDueDate>');
    }
    buffer.write('<VariableSymbol>$variableSymbol</VariableSymbol>');
    if (constantSymbol != null && constantSymbol.isNotEmpty) {
      buffer.write('<ConstantSymbol>$constantSymbol</ConstantSymbol>');
    }
    if (specificSymbol != null && specificSymbol.isNotEmpty) {
      buffer.write('<SpecificSymbol>$specificSymbol</SpecificSymbol>');
    }
    if (note != null && note.isNotEmpty) {
      // Escape XML chars in note if needed
      buffer.write('<Note>${_escapeXml(note)}</Note>');
    }
    buffer.write('<BankAccounts>');
    buffer.write('<BankAccount>');
    buffer.write('<IBAN>$iban</IBAN>');
    buffer.write('<BIC>$swift</BIC>');
    buffer.write('</BankAccount>');
    buffer.write('</BankAccounts>');
    // RecipientName is optional in some strict parsers if IBAN is enough, but good for display
    buffer.write('</Payment>');
    buffer.write('</DirectPayment>');
    buffer.write('</Invoice>');
    buffer.write('</BySquare>');

    return buffer.toString();
  }

  static List<int> _compressLzma(List<int> input) {
    return lzma.encode(input);
  }

  static String _escapeXml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}
