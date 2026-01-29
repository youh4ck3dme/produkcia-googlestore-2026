import 'package:flutter_test/flutter_test.dart';
import 'package:bizagent/core/services/tax_calculation_service.dart';

void main() {
  test('VAT line rounding (20%)', () {
    final tax = TaxCalculationService();
    final line = tax.calcLine(baseAmount: 10.00, vatRate: 0.2);
    expect(line.vatAmount, 2.00);
    expect(line.total, 12.00);
  });

  test('Totals sum using per-line rounded VAT', () {
    final tax = TaxCalculationService();
    final lines = [
      tax.calcLine(baseAmount: 9.99, vatRate: 0.2), // vat=2.00 (1.998 -> 2.00)
      tax.calcLine(baseAmount: 10.01, vatRate: 0.2), // vat=2.00 (2.002 -> 2.00)
    ];
    final totals = tax.calcTotals(lines);
    expect(totals.baseTotal, 20.00);
    expect(totals.vatTotal, 4.00);
    expect(totals.grandTotal, 24.00);
  });
}
