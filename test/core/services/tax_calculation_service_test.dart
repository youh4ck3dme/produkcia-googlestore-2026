import 'package:flutter_test/flutter_test.dart';
import 'package:bizagent/core/services/tax_calculation_service.dart';

void main() {
  test('SK VAT constants 2026', () {
    expect(TaxCalculationService.vatRates, [0.2, 0.1, 0.0]);
    expect(TaxCalculationService.vatRegistrationThresholdEur, 49790.0);
    expect(TaxCalculationService.microTaxpayerIncomeLimitEur, 100000.0);
  });

  test('VAT line rounding (20%)', () {
    final tax = TaxCalculationService();
    final line = tax.calcLine(
      baseAmount: 10.00,
      vatRate: TaxCalculationService.vatStandardRate,
    );
    expect(line.vatAmount, 2.00);
    expect(line.total, 12.00);
  });

  test('Totals sum using per-line rounded VAT', () {
    final tax = TaxCalculationService();
    final lines = [
      tax.calcLine(
        baseAmount: 9.99,
        vatRate: TaxCalculationService.vatStandardRate,
      ),
      tax.calcLine(
        baseAmount: 10.01,
        vatRate: TaxCalculationService.vatStandardRate,
      ),
    ];
    final totals = tax.calcTotals(lines);
    expect(totals.baseTotal, 20.00);
    expect(totals.vatTotal, 4.00);
    expect(totals.grandTotal, 24.00);
  });
}
