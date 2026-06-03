import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/remote_config.dart';
import '../billing/billing_service.dart';
import 'billing_copy.dart';

enum BizFeature {
  createInvoice,
  icoLookup,
  icoPremiumProfile,
  aiAnalysis,
  exportExcel,
  removeWatermark,
  watchedCompanies, // New feature type
}

class SubscriptionGuard {
  final Ref ref;

  SubscriptionGuard(this.ref);

  bool canAccess(BizFeature feature) {
    final billingState = ref.read(billingProvider);
    final isPro = billingState.entitlements.isPro;
    final isBusiness = billingState.entitlements.isBusiness;

    if (isBusiness) return true; // Business has everything

    switch (feature) {
      case BizFeature.createInvoice:
        if (isPro) return true;
        final remoteConfig = BizRemoteConfig();
        if (!remoteConfig.showPaywallOnLimit) return true;
        return billingState.entitlements.invoiceCount < remoteConfig.invoiceLimit;
        
      case BizFeature.icoLookup:
         if (isPro) return true; // Pro has high limits, effectively unlimited for casual use
         return billingState.entitlements.icoLookupsCount < 5;

      case BizFeature.icoPremiumProfile:
        return isPro || isBusiness;

      case BizFeature.aiAnalysis:
        if (isBusiness) return true;
        if (isPro) return billingState.entitlements.aiRequestsCount < 50; 
        return billingState.entitlements.aiRequestsCount < 1;

      case BizFeature.exportExcel:
        return isPro;

      case BizFeature.removeWatermark:
        return isPro;

      case BizFeature.watchedCompanies:
        if (isBusiness || isPro) return true;
        // Limit for Free tier is 3. 
        // We rely on the button/UI to check current count against this entitlement.
        // BUT wait, the pattern here is checking if they are allowed to do X.
        // For limits based features, we usually just return true if they are NOT capped by tier, 
        // or we need to inject the current count.
        // User requested `final canWatch = ref.read(subscriptionGuardProvider).canWatchCompanies;`
        // which implies a property that returns bool.
        // Let's implement that Specific getter as requested by user instructions.
        return true; 
    }
  }

  // Requested by user instruction: "final canWatch = ref.read(subscriptionGuardProvider).canWatchCompanies;"
  // This likely means "Is the user ALLOWED to act on watched companies generally?" 
  // OR "Is the user UNLIMITED?".
  // Given the context of `_checkLimit` in button, the user wants us to replace:
  // `if (entitlements.isPro)` with `if (guard.canWatchCompanies)`.
  // So `canWatchCompanies` should basically mean "Is Pro / Unlimited".
  bool get canWatchCompanies {
    final billingState = ref.read(billingProvider);
    return billingState.entitlements.isPro || billingState.entitlements.isBusiness;
  }

  /// Má UI zobraziť paywall namiesto tichého failu.
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
