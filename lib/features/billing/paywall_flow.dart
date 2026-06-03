import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/utils/biz_snackbar.dart';
import 'feature_paywall_sheet.dart';
import 'subscription_guard.dart';

/// Jednotný entry point pre zamknuté prémiové funkcie.
class PaywallFlow {
  PaywallFlow._();

  /// `true` = môže pokračovať, `false` = zobrazil sa paywall alebo fallback.
  static Future<bool> ensureAccess(
    BuildContext context,
    WidgetRef ref,
    BizFeature feature,
  ) async {
    final guard = ref.read(subscriptionGuardProvider);
    if (guard.canAccess(feature)) return true;

    if (!guard.shouldShowPaywallUi(feature)) {
      if (context.mounted) {
        BizSnackbar.showInfo(context, guard.getUpgradeMessage(feature));
      }
      return false;
    }

    if (!context.mounted) return false;
    await showFeaturePaywall(context, feature: feature, reason: guard.getUpgradeMessage(feature));
    return false;
  }

  static Future<void> showFeaturePaywall(
    BuildContext context, {
    required BizFeature feature,
    required String reason,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      builder: (ctx) => FeaturePaywallSheet(feature: feature, reason: reason),
    );
  }
}
