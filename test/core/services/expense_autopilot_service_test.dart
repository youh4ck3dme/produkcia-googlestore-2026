import 'package:flutter_test/flutter_test.dart';

import 'package:bizagent/core/services/ai_ocr_service.dart';
import 'package:bizagent/core/services/expense_autopilot_service.dart';
import 'package:bizagent/core/services/expense_parser_service.dart';
import 'package:bizagent/core/services/gemini_service.dart';
import 'package:bizagent/core/services/ocr_service.dart';
import '../../helpers/fake_monitoring_service.dart';

class _HighConfidenceParser extends ExpenseParserService {
  _HighConfidenceParser() : super(_HighConfidenceGemini());

  @override
  Future<ParsedExpense?> parseExpenseText(String text) async {
    return ParsedExpense(
      description: 'Nákup potravín',
      amount: 42.99,
      category: 'Jedlo',
      date: DateTime(2024, 3, 15),
      merchant: 'Tesco',
      confidence: 0.92,
    );
  }
}

class _LowConfidenceParser extends ExpenseParserService {
  _LowConfidenceParser() : super(_HighConfidenceGemini());

  @override
  Future<ParsedExpense?> parseExpenseText(String text) async {
    return ParsedExpense(
      description: 'Neznámy bloček',
      amount: 12.0,
      category: 'Iné',
      date: DateTime.now(),
      confidence: 0.4,
    );
  }
}

class _HighConfidenceGemini extends GeminiService {
  @override
  Future<String> analyzeJson(String context, String schema) async => '{}';
}

class _StubAiOcr extends AiOcrService {
  _StubAiOcr() : super(_HighConfidenceGemini());

  @override
  Future<ParsedReceipt?> refineWithAi(String rawText, {String? imagePath}) async {
    return ParsedReceipt(
      totalAmount: '42.99',
      date: '2024-03-15',
      vendorId: '36396567',
      originalText: rawText,
      imagePath: imagePath,
    );
  }
}

class _MissingIcoAiOcr extends AiOcrService {
  _MissingIcoAiOcr() : super(_HighConfidenceGemini());

  @override
  Future<ParsedReceipt?> refineWithAi(String rawText, {String? imagePath}) async {
    return ParsedReceipt(
      totalAmount: '15.00',
      date: '2024-03-15',
      vendorId: '',
      originalText: rawText,
      imagePath: imagePath,
    );
  }
}

void main() {
  final ocrBase = ParsedReceipt(
    totalAmount: '42.99',
    date: '2024-03-15',
    vendorId: '36396567',
    originalText: 'TESCO\nCelkom 42.99 EUR',
    imagePath: '/tmp/receipt.jpg',
  );

  test('autopilot auto-commits when confidence and fields are OK', () async {
    final service = ExpenseAutopilotService(
      aiOcr: _StubAiOcr(),
      parser: _HighConfidenceParser(),
      monitoring: FakeMonitoringService(),
      isVatPayer: true,
    );

    final result = await service.processReceipt(
      userId: 'user-1',
      ocrResult: ocrBase,
    );

    expect(result.status, ExpenseAutopilotStatus.autoCommitted);
    expect(result.confidence, greaterThan(kAutopilotConfidenceThreshold));
    expect(result.expense?.isOcrVerified, isTrue);
    expect(result.expense?.needsReview, isFalse);
    expect(result.estimatedVatAmount, isNotNull);
  });

  test('autopilot pending review when IČO missing', () async {
    final monitoring = FakeMonitoringService();
    final service = ExpenseAutopilotService(
      aiOcr: _MissingIcoAiOcr(),
      parser: _HighConfidenceParser(),
      monitoring: monitoring,
      isVatPayer: false,
    );

    final result = await service.processReceipt(
      userId: 'user-1',
      ocrResult: ocrBase.copyWith(vendorId: null),
    );

    expect(result.status, ExpenseAutopilotStatus.pendingReview);
    expect(result.needsUserAction, isTrue);
    expect(result.reviewReasons, contains('Chýba IČO predajcu'));
    expect(result.expense?.needsReview, isTrue);
  });

  test('autopilot pending review when confidence below threshold', () async {
    final service = ExpenseAutopilotService(
      aiOcr: _StubAiOcr(),
      parser: _LowConfidenceParser(),
      monitoring: FakeMonitoringService(),
      isVatPayer: false,
    );

    final result = await service.processReceipt(
      userId: 'user-1',
      ocrResult: ocrBase,
    );

    expect(result.status, ExpenseAutopilotStatus.pendingReview);
    expect(
      result.reviewReasons.any((r) => r.contains('Nízka spoľahlivosť')),
      isTrue,
    );
  });
}

extension on ParsedReceipt {
  ParsedReceipt copyWith({String? vendorId}) {
    return ParsedReceipt(
      totalAmount: totalAmount,
      date: date,
      vendorId: vendorId ?? this.vendorId,
      originalText: originalText,
      imagePath: imagePath,
    );
  }
}