import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UsageLimiter {
  static const String _kInvoiceCount = 'usage_invoice_count';
  static const String _kIcoCount = 'usage_ico_count';
  static const String _kLastReset = 'usage_last_reset';

  final SharedPreferences prefs;

  UsageLimiter(this.prefs);

  int get invoiceCount => prefs.getInt(_kInvoiceCount) ?? 0;
  int get icoCount => prefs.getInt(_kIcoCount) ?? 0;

  Future<void> incrementInvoice() async {
    await prefs.setInt(_kInvoiceCount, invoiceCount + 1);
  }

  Future<void> incrementIco() async {
    await prefs.setInt(_kIcoCount, icoCount + 1);
  }

  Future<void> checkAndResetMonthly() async {
    final lastResetStr = prefs.getString(_kLastReset);
    final now = DateTime.now();
    
    if (lastResetStr != null) {
      final lastReset = DateTime.parse(lastResetStr);
      if (now.month != lastReset.month || now.year != lastReset.year) {
        await resetCounts();
      }
    } else {
      await prefs.setString(_kLastReset, now.toIso8601String());
    }
  }

  Future<void> resetCounts() async {
    await prefs.setInt(_kInvoiceCount, 0);
    await prefs.setInt(_kIcoCount, 0);
    await prefs.setString(_kLastReset, DateTime.now().toIso8601String());
  }
}

final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize this in main.dart via overrides');
});

final usageLimiterProvider = Provider<UsageLimiter>((ref) {
  final prefs = ref.watch(sharedPrefsProvider);
  return UsageLimiter(prefs);
});
