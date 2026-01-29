import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import '../../core/config.dart';

class BizRemoteConfig {
  static final BizRemoteConfig _instance = BizRemoteConfig._internal();
  factory BizRemoteConfig() => _instance;
  BizRemoteConfig._internal();

  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  Future<void> initialize() async {
    try {
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: kDebugMode ? const Duration(minutes: 5) : const Duration(hours: 12),
      ));

      await _remoteConfig.setDefaults({
        'show_paywall_on_invoice_limit': true,
        'invoice_limit': BizConfig.freeInvoiceLimitMonthly,
        'annual_discount_percentage': 20,
        'enable_one_time_purchase': true,
      });

      await _remoteConfig.fetchAndActivate();
    } catch (e) {
      debugPrint('Remote Config sync failed: $e');
    }
  }

  int get invoiceLimit => _remoteConfig.getInt('invoice_limit');
  bool get showPaywallOnLimit => _remoteConfig.getBool('show_paywall_on_invoice_limit');
  int get annualDiscount => _remoteConfig.getInt('annual_discount_percentage');
  bool get enableOneTimePurchase => _remoteConfig.getBool('enable_one_time_purchase');
}
