import 'package:flutter_test/flutter_test.dart';
import 'package:bizagent/core/services/ocr_service.dart';

void main() {
  group('Smart OCR Regex Tests', () {
    late OcrService ocrService;

    setUp(() {
      ocrService = OcrService();
    });

    test('Parses standard receipt correctly', () {
      const receiptText = '''
        SUPERMARKET TESCO
        Dátum: 15.01.2024
        Čas: 14:30
        
        Položka 1 .... 1.50
        Položka 2 .... 2.50
        
        Celkom: 4.00 EUR
        IČO: 12345678
      ''';

      final result = ocrService.parseReceipt(receiptText);

      expect(result.totalAmount, equals('4.00'));
      expect(result.date, equals('15.01.2024'));
      expect(result.vendorId, equals('12345678'));
    });

    test('Parses receipt with different amount label', () {
      const receiptText = '''
        Obchod ABC
        Suma: 12,50 €
        Datum: 2024-02-28
      ''';

      final result = ocrService.parseReceipt(receiptText);

      expect(result.totalAmount, equals('12.50')); // Should normalize comma
      expect(result.date, equals('2024-02-28')); // Should handle YYYY-MM-DD
    });

    test('Parses receipt with ICO label variation', () {
      const receiptText = '''
        Firma XYZ
        ICO: 87654321
        Spolu 100.00
      ''';

      final result = ocrService.parseReceipt(receiptText);

      expect(result.vendorId, equals('87654321'));
      expect(result.totalAmount, equals('100.00'));
    });
  });
}
