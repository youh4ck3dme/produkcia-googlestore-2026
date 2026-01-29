// lib/core/services/qr_payment_service.dart
import 'dart:math';

class QrPaymentInput {
  QrPaymentInput({
    required this.iban,
    required this.beneficiaryName,
    required this.amountEur,
    this.paymentReference, // napr. VS
    this.remittanceInfo, // správa pre prijímateľa
  });

  final String iban;
  final String beneficiaryName;
  final double amountEur;
  final String? paymentReference;
  final String? remittanceInfo;
}

/// EPC SEPA Credit Transfer QR payload (text format).
/// Spec-friendly minimal variant:
/// BCD\n001\n1\nSCT\nBIC(optional)\nNAME\nIBAN\nEURxx.xx\n\n\nREMITTANCE
class QrPaymentService {
  static final _ibanClean = RegExp(r'[^A-Za-z0-9]');

  String normalizeIban(String iban) =>
      iban.replaceAll(_ibanClean, '').toUpperCase();

  bool isLikelyValidSkIban(String iban) {
    final x = normalizeIban(iban);
    // SK + 22 znakov = 24
    return RegExp(r'^SK[0-9A-Z]{22}$').hasMatch(x);
  }

  /// Formats amount with 2 decimals using dot as per EPC examples.
  String _formatAmount(double amountEur) {
    final clamped = max(0, amountEur);
    return clamped.toStringAsFixed(2);
  }

  /// Builds EPC payload string. BIC is optional; we omit it for simplicity.
  /// Remittance: we combine reference + message in a human-friendly line.
  String buildEpcPayload(QrPaymentInput input) {
    final iban = normalizeIban(input.iban);
    final name = _sanitizeLine(input.beneficiaryName, maxLen: 70);
    final amount = _formatAmount(input.amountEur);

    final ref = _sanitizeLine(input.paymentReference ?? '', maxLen: 35);
    final msg = _sanitizeLine(input.remittanceInfo ?? '', maxLen: 70);

    // We keep it simple: put reference into the message line if present.
    final remittance = _buildRemittance(ref: ref, msg: msg);

    final lines = <String>[
      'BCD',
      '001',
      '1',
      'SCT',
      '', // BIC (optional) - blank
      name,
      iban,
      'EUR$amount',
      '', // purpose (optional)
      '', // structured remittance (optional)
      remittance,
    ];

    return lines.join('\n');
  }

  String _buildRemittance({required String ref, required String msg}) {
    if (ref.isEmpty && msg.isEmpty) return '';
    if (ref.isNotEmpty && msg.isEmpty) return 'VS:$ref';
    if (ref.isEmpty && msg.isNotEmpty) return msg;
    return 'VS:$ref | $msg';
  }

  String _sanitizeLine(String s, {required int maxLen}) {
    // EPC payload is text-based; remove newlines and trim.
    final oneLine = s.replaceAll('\n', ' ').replaceAll('\r', ' ').trim();
    if (oneLine.length <= maxLen) return oneLine;
    return oneLine.substring(0, maxLen);
  }
}
