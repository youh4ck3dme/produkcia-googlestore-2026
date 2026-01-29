import 'package:flutter_test/flutter_test.dart';
import 'package:bizagent/core/services/qr_payment_service.dart';

void main() {
  group('QrPaymentService', () {
    test('normalizes IBAN', () {
      final s = QrPaymentService();
      expect(s.normalizeIban('sk12 3456 7890 1234 5678 9012'),
          'SK1234567890123456789012');
    });

    test('validates likely SK IBAN', () {
      final s = QrPaymentService();
      expect(s.isLikelyValidSkIban('SK1234567890123456789012'), true);
      expect(s.isLikelyValidSkIban('SK12'), false);
    });

    test('builds EPC payload with required lines', () {
      final s = QrPaymentService();
      final payload = s.buildEpcPayload(QrPaymentInput(
        iban: 'SK1234567890123456789012',
        beneficiaryName: 'BizAgent s.r.o.',
        amountEur: 148.14,
        paymentReference: '2026001',
        remittanceInfo: 'Faktura 2026/001',
      ));

      // základné signatúry
      expect(payload.startsWith('BCD\n001\n1\nSCT\n'), true);
      expect(payload.contains('\nBizAgent s.r.o.\n'), true);
      expect(payload.contains('\nSK1234567890123456789012\n'), true);
      expect(payload.contains('\nEUR148.14\n'), true);
      expect(payload.contains('VS:2026001'), true);
    });
  });
}
