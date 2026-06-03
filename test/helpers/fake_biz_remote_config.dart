import 'package:bizagent/core/config.dart';
import 'package:bizagent/core/remote_config.dart';

/// Installs deterministic Remote Config values for unit tests (no Firebase backend).
class FakeBizRemoteConfig {
  FakeBizRemoteConfig._();

  static void install({
    int invoiceLimit = BizConfig.freeInvoiceLimitMonthly,
    bool showPaywallOnLimit = true,
    int annualDiscount = 20,
    bool enableOneTimePurchase = true,
  }) {
    BizRemoteConfig.testing = BizRemoteConfigOverrides(
      invoiceLimit: invoiceLimit,
      showPaywallOnLimit: showPaywallOnLimit,
      annualDiscount: annualDiscount,
      enableOneTimePurchase: enableOneTimePurchase,
    );
  }

  static void reset() {
    BizRemoteConfig.testing = null;
  }
}
