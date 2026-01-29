import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bizagent/features/limits/usage_limiter.dart';

/// UsageLimiter unit tests (SharedPreferences-backed invoice/ICO counters).
void main() {
  late SharedPreferences prefs;
  late UsageLimiter limiter;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    limiter = UsageLimiter(prefs);
  });

  group('UsageLimiter', () {
    test('invoiceCount and icoCount start at 0', () {
      expect(limiter.invoiceCount, 0);
      expect(limiter.icoCount, 0);
    });

    test('incrementInvoice increases invoice count', () async {
      expect(limiter.invoiceCount, 0);
      await limiter.incrementInvoice();
      expect(limiter.invoiceCount, 1);
      await limiter.incrementInvoice();
      expect(limiter.invoiceCount, 2);
    });

    test('incrementIco increases ico count', () async {
      expect(limiter.icoCount, 0);
      await limiter.incrementIco();
      expect(limiter.icoCount, 1);
      await limiter.incrementIco();
      expect(limiter.icoCount, 2);
    });

    test('resetCounts zeros both counts', () async {
      await limiter.incrementInvoice();
      await limiter.incrementIco();
      expect(limiter.invoiceCount, 1);
      expect(limiter.icoCount, 1);
      await limiter.resetCounts();
      expect(limiter.invoiceCount, 0);
      expect(limiter.icoCount, 0);
    });

    test('checkAndResetMonthly does not reset in same month', () async {
      await limiter.incrementInvoice();
      await limiter.checkAndResetMonthly();
      expect(limiter.invoiceCount, 1);
    });

    test('counts persist across new UsageLimiter instance', () async {
      await limiter.incrementInvoice();
      await limiter.incrementIco();
      final prefs2 = await SharedPreferences.getInstance();
      final limiter2 = UsageLimiter(prefs2);
      expect(limiter2.invoiceCount, 1);
      expect(limiter2.icoCount, 1);
    });
  });
}
