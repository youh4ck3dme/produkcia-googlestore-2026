import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config.dart';
import '../../core/remote_config.dart';
import '../auth/providers/auth_repository.dart';
import '../billing/billing_service.dart';
import 'billing_copy.dart';

enum BizFeature {
  createInvoice,
  icoLookup,
  icoPremiumProfile,
  aiAnalysis,
  exportExcel,
  removeWatermark,
  watchedCompanies,
}

class SubscriptionGuard {
  final Ref ref;

  SubscriptionGuard(this.ref);

  bool get _isSuperAdmin =>
      ref.read(authRepositoryProvider).currentUser?.isSuperAdmin == true;

  bool canAccess(BizFeature feature) {
    if (_isSuperAdmin) return true;

    final billingState = ref.read(billingProvider);
    final isPro = billingState.entitlements.isPro;

    switch (feature) {
      case BizFeature.createInvoice:
        if (isPro) return true;
        final remoteConfig = BizRemoteConfig();
        if (!remoteConfig.showPaywallOnLimit) return true;
        return billingState.entitlements.invoiceCount < remoteConfig.invoiceLimit;
        
      case BizFeature.icoLookup:
        if (isPro) return true;
        return billingState.entitlements.icoLookupsCount < BizConfig.freeIcoLookupLimit;

      case BizFeature.icoPremiumProfile:
        return isPro;

      case BizFeature.aiAnalysis:
        if (isPro) return billingState.entitlements.aiRequestsCount < BizConfig.proAiUsageLimit;
        return billingState.entitlements.aiRequestsCount < BizConfig.freeAiUsageLimit;

      case BizFeature.exportExcel:
        return isPro;

      case BizFeature.removeWatermark:
        return isPro;

      case BizFeature.watchedCompanies:
        return isPro;
    }
  }

  bool get canWatchCompanies {
    if (_isSuperAdmin) return true;
    final billingState = ref.read(billingProvider);
    return billingState.entitlements.isPro;
  }

  bool shouldShowPaywallUi(BizFeature feature) {
    if (canAccess(feature)) return false;
    switch (feature) {
      case BizFeature.createInvoice:
        return BizRemoteConfig().showPaywallOnLimit;
      default:
        return true;
    }
  }

  String getUpgradeMessage(BizFeature feature) => BillingCopy.messageFor(feature);
}

final subscriptionGuardProvider = Provider<SubscriptionGuard>((ref) {
  return SubscriptionGuard(ref);
});
