import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import '../../core/config.dart';

/// Injected in unit tests via [BizRemoteConfig.testing] (see test/helpers/fake_biz_remote_config.dart).
@visibleForTesting
class BizRemoteConfigOverrides {
  final int? invoiceLimit;
  final bool? showPaywallOnLimit;
  final int? annualDiscount;
  final bool? enableOneTimePurchase;

  const BizRemoteConfigOverrides({
    this.invoiceLimit,
    this.showPaywallOnLimit,
    this.annualDiscount,
    this.enableOneTimePurchase,
  });
}

class BizRemoteConfig {
  static final BizRemoteConfig _instance = BizRemoteConfig._internal();
  factory BizRemoteConfig() => _instance;
  BizRemoteConfig._internal();

  @visibleForTesting
  static BizRemoteConfigOverrides? testing;

  FirebaseRemoteConfig? _remoteConfig;
  FirebaseRemoteConfig get _firebase {
    return _remoteConfig ??= FirebaseRemoteConfig.instance;
  }

  Future<void> initialize() async {
    try {
      await _firebase.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: kDebugMode ? const Duration(minutes: 5) : const Duration(hours: 12),
      ));

      await _firebase.setDefaults({
        'show_paywall_on_invoice_limit': true,
        'invoice_limit': BizConfig.freeInvoiceLimitMonthly,
        'annual_discount_percentage': 20,
        'enable_one_time_purchase': true,
      });

      await _firebase.fetchAndActivate();
    } catch (e) {
      debugPrint('Remote Config sync failed: $e');
    }
  }

  int get invoiceLimit =>
      testing?.invoiceLimit ?? _firebase.getInt('invoice_limit');

  bool get showPaywallOnLimit =>
      testing?.showPaywallOnLimit ??
      _firebase.getBool('show_paywall_on_invoice_limit');

  int get annualDiscount =>
      testing?.annualDiscount ?? _firebase.getInt('annual_discount_percentage');

  bool get enableOneTimePurchase =>
      testing?.enableOneTimePurchase ??
      _firebase.getBool('enable_one_time_purchase');
}
