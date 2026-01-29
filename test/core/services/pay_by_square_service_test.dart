import 'package:bizagent/core/services/pay_by_square_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PayBySquareService', () {
    test('generateString returns non-empty string', () {
      final qrString = PayBySquareService.generateString(
        iban: 'SK1211000000001234567890',
        swift: 'TATRUKBX',
        amount: 123.45,
        variableSymbol: '2023001',
        recipientName: 'Test Company',
        dateDue: '2023-12-31',
      );

      // print('Generated QR string: $qrString');
      expect(qrString, isNotEmpty);
      // Basic check for Base32 characteristics (roughly)
      expect(RegExp(r'^[A-Z2-7=]+$').hasMatch(qrString), isTrue);
    });

    test('generateString handles optional fields', () {
      final qrString = PayBySquareService.generateString(
        iban: 'SK1211000000001234567890',
        swift: 'TATRUKBX',
        amount: 50.00,
        variableSymbol: '2023002',
        recipientName: 'Test Company',
        note: 'Platba za služby',
      );

      expect(qrString, isNotEmpty);
    });
  });
}
