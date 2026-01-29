// lib/core/utils/money.dart
// No imports needed

class Money {
  /// Round to 2 decimals (classic EUR)
  static double round2(double v) {
    return (v * 100).round() / 100.0;
  }

  /// Safe add with rounding at end
  static double sumRound2(Iterable<double> values) {
    final sum = values.fold<double>(0, (a, b) => a + b);
    return round2(sum);
  }

  static String eur(double v) => round2(v).toStringAsFixed(2);
}
