import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../features/expenses/models/expense_category.dart';
import '../../features/expenses/models/expense_model.dart';
import '../../features/settings/providers/settings_provider.dart';
import '../../features/tools/services/monitoring_service.dart';
import '../services/tax_calculation_service.dart';
import 'ai_ocr_service.dart';
import 'expense_parser_service.dart';
import 'ocr_service.dart';

/// Minimálna spoľahlivosť pre automatické uloženie bez zásahu používateľa.
const double kAutopilotConfidenceThreshold = 0.75;

enum ExpenseAutopilotStatus {
  autoCommitted,
  pendingReview,
  failed,
}

class ExpenseAutopilotResult {
  const ExpenseAutopilotResult({
    required this.status,
    this.expense,
    this.confidence = 0,
    this.reviewReasons = const [],
    this.estimatedVatAmount,
  });

  final ExpenseAutopilotStatus status;
  final ExpenseModel? expense;
  final double confidence;
  final List<String> reviewReasons;
  final double? estimatedVatAmount;

  bool get needsUserAction => status == ExpenseAutopilotStatus.pendingReview;
}

final expenseAutopilotServiceProvider = Provider<ExpenseAutopilotService>((ref) {
  return ExpenseAutopilotService(
    aiOcr: ref.watch(aiOcrServiceProvider),
    parser: ref.watch(expenseParserServiceProvider),
    monitoring: ref.watch(monitoringServiceProvider),
    isVatPayer: ref.watch(settingsProvider).value?.isVatPayer ?? false,
  );
});

/// Autopilot: OCR → AI parsing → DPH odhad → výdavok (+ human checkpoint).
class ExpenseAutopilotService {
  ExpenseAutopilotService({
    required AiOcrService aiOcr,
    required ExpenseParserService parser,
    required MonitoringService monitoring,
    required bool isVatPayer,
  })  : _aiOcr = aiOcr,
        _parser = parser,
        _monitoring = monitoring,
        _isVatPayer = isVatPayer;

  final AiOcrService _aiOcr;
  final ExpenseParserService _parser;
  final MonitoringService _monitoring;
  final bool _isVatPayer;
  final _tax = TaxCalculationService();
  final _uuid = const Uuid();

  Future<ExpenseAutopilotResult> processReceipt({
    required String userId,
    required ParsedReceipt ocrResult,
  }) async {
    final refined = await _aiOcr.refineWithAi(
      ocrResult.originalText,
      imagePath: ocrResult.imagePath,
    );

    final merged = _mergeOcr(ocrResult, refined);
    final amount = _parseAmount(merged.totalAmount);
    final vendorIco = merged.vendorId?.trim() ?? '';
    final date = _parseDate(merged.date) ?? DateTime.now();

    final parserInput = '''
Bloček / účtenka:
${merged.originalText}
Suma: ${merged.totalAmount ?? '-'}
IČO predajcu: ${vendorIco.isEmpty ? '-' : vendorIco}
Dátum: ${merged.date ?? '-'}
''';

    final parsed = await _parser.parseExpenseText(parserInput);
    final confidence = parsed?.confidence ?? 0.55;
    final description = parsed?.description ??
        (merged.originalText.split('\n').first.trim().isNotEmpty
            ? merged.originalText.split('\n').first.trim()
            : 'Výdavok z bločku');
    final category = _mapCategory(parsed?.category);
    final finalAmount = parsed?.amount ?? amount ?? 0;

    final reviewReasons = <String>[];
    if (confidence < kAutopilotConfidenceThreshold) {
      reviewReasons.add('Nízka spoľahlivosť AI (${(confidence * 100).round()} %)');
    }
    if (finalAmount <= 0) {
      reviewReasons.add('Chýba alebo je neplatná suma');
    }
    if (vendorIco.isEmpty) {
      reviewReasons.add('Chýba IČO predajcu');
    }

    final estimatedVat = _isVatPayer && finalAmount > 0
        ? _tax
            .calcLine(
              baseAmount: finalAmount / (1 + TaxCalculationService.vatStandardRate),
              vatRate: TaxCalculationService.vatStandardRate,
            )
            .vatAmount
        : null;

    if (finalAmount <= 0 && parsed == null) {
      return const ExpenseAutopilotResult(status: ExpenseAutopilotStatus.failed);
    }

    final needsReview = reviewReasons.isNotEmpty;
    final expense = ExpenseModel(
      id: _uuid.v4(),
      userId: userId,
      vendorName: vendorIco.isNotEmpty ? vendorIco : (parsed?.merchant ?? ''),
      description: description,
      amount: finalAmount,
      date: parsed?.date ?? date,
      category: category,
      categorizationConfidence: (confidence * 100).round(),
      receiptUrls: merged.imagePath != null ? [merged.imagePath!] : const [],
      receiptScannedAt: DateTime.now(),
      isOcrVerified: !needsReview,
      needsReview: needsReview,
      vendorIco: vendorIco.isEmpty ? null : vendorIco,
      autopilotConfidence: confidence,
    );

    if (needsReview) {
      await _monitoring.publishUserNotification(
        userId: userId,
        title: 'Výdavok čaká na potvrdenie',
        body:
            'Autopilot spracoval bloček, ale potrebuje vašu kontrolu: ${reviewReasons.join('; ')}',
        type: 'expense_review',
        expenseId: expense.id,
      );
    }

    return ExpenseAutopilotResult(
      status: needsReview
          ? ExpenseAutopilotStatus.pendingReview
          : ExpenseAutopilotStatus.autoCommitted,
      expense: expense,
      confidence: confidence,
      reviewReasons: reviewReasons,
      estimatedVatAmount: estimatedVat,
    );
  }

  ParsedReceipt _mergeOcr(ParsedReceipt base, ParsedReceipt? refined) {
    if (refined == null) return base;
    return ParsedReceipt(
      totalAmount: refined.totalAmount ?? base.totalAmount,
      date: refined.date ?? base.date,
      vendorId: refined.vendorId ?? base.vendorId,
      originalText: base.originalText,
      imagePath: base.imagePath ?? refined.imagePath,
    );
  }

  double? _parseAmount(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final normalized = raw.replaceAll(RegExp(r'[^\d,.-]'), '').replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  DateTime? _parseDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      if (raw.contains('.')) {
        final parts = raw.split('.');
        if (parts.length == 3) {
          return DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
        }
      }
      return DateTime.parse(raw);
    } catch (_) {
      return null;
    }
  }

  ExpenseCategory? _mapCategory(String? label) {
    if (label == null || label.trim().isEmpty) return null;
    final direct = expenseCategoryFromString(label);
    if (direct != null) return direct;

    switch (label.toLowerCase()) {
      case 'jedlo':
      case 'strava':
        return ExpenseCategory.meals;
      case 'doprava':
        return ExpenseCategory.fuel;
      case 'kancelária':
      case 'kancelaria':
        return ExpenseCategory.officeSupplies;
      case 'marketing':
        return ExpenseCategory.marketing;
      case 'služby':
      case 'sluzby':
        return ExpenseCategory.accounting;
      default:
        return ExpenseCategory.other;
    }
  }
}