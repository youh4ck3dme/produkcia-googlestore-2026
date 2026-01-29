// lib/core/services/tax_calculation_service.dart
import '../utils/money.dart';

class TaxLine {
  TaxLine({
    required this.base,
    required this.vatRate,
    required this.vatAmount,
    required this.total,
  });

  final double base; // bez DPH (net)
  final double vatRate; // 0.0, 0.1, 0.2
  final double vatAmount; // zaokrúhlené na 2 des.
  final double total; // base + vatAmount (round2)
}

class TaxTotals {
  TaxTotals({
    required this.baseTotal,
    required this.vatTotal,
    required this.grandTotal,
    required this.vatBreakdown, // napr. {0.2: 24.60, 0.1: 3.20}
  });

  final double baseTotal;
  final double vatTotal;
  final double grandTotal;
  final Map<double, double> vatBreakdown;
}

class TaxCalculationService {
  /// Item base is assumed NET (bez DPH).
  TaxLine calcLine({required double baseAmount, required double vatRate}) {
    final base = Money.round2(baseAmount);
    final vat = Money.round2(base * vatRate);
    final total = Money.round2(base + vat);
    return TaxLine(base: base, vatRate: vatRate, vatAmount: vat, total: total);
  }

  /// Sumarizácia: používa per-item rounding (aby PDF/UI sedelo)
  TaxTotals calcTotals(Iterable<TaxLine> lines) {
    final baseTotal = Money.sumRound2(lines.map((l) => l.base));
    final vatTotal = Money.sumRound2(lines.map((l) => l.vatAmount));
    final grandTotal = Money.round2(baseTotal + vatTotal);

    final breakdown = <double, double>{};
    for (final l in lines) {
      breakdown[l.vatRate] =
          Money.round2((breakdown[l.vatRate] ?? 0) + l.vatAmount);
    }

    return TaxTotals(
      baseTotal: baseTotal,
      vatTotal: vatTotal,
      grandTotal: grandTotal,
      vatBreakdown: breakdown,
    );
  }
}
