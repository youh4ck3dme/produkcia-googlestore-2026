import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../core/config.dart';
import '../entitlements/user_entitlements.dart';
import '../limits/usage_limiter.dart';

// Provider state
class BillingState {
  final UserEntitlements entitlements;
  final List<ProductDetails> products;
  final bool isLoading;
  final String? errorMessage;

  BillingState({
    required this.entitlements,
    this.products = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  BillingState copyWith({
     UserEntitlements? entitlements,
     List<ProductDetails>? products,
     bool? isLoading,
     String? errorMessage,
  }) {
    return BillingState(
      entitlements: entitlements ?? this.entitlements,
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage, // Nullable to clear error
    );
  }
}

// Provider
final billingProvider = StateNotifierProvider<BillingService, BillingState>((ref) {
  final usageLimiter = ref.watch(usageLimiterProvider);
  return BillingService(usageLimiter);
});

class BillingService extends StateNotifier<BillingState> {
  final InAppPurchase _iap = InAppPurchase.instance;
  final UsageLimiter _usageLimiter;
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  BillingService(this._usageLimiter) : super(BillingState(entitlements: UserEntitlements.free())) {
    _init();
  }

  Future<void> _init() async {
    final available = await _iap.isAvailable();
    if (!available) {
      state = state.copyWith(errorMessage: "Store not available");
      return;
    }

    // Listen to purchase updates
    final purchaseUpdated = _iap.purchaseStream;
    _subscription = purchaseUpdated.listen(
      (purchaseDetailsList) {
        _listenToPurchaseUpdated(purchaseDetailsList);
      },
      onDone: () {
        _subscription.cancel();
      },
      onError: (error) {
        state = state.copyWith(errorMessage: error.toString());
      },
    );

    await _usageLimiter.checkAndResetMonthly();
    _updateEntitlementsWithUsage();

    await loadProducts();
    await restorePurchases();
  }

  void refreshUsage() {
    _updateEntitlementsWithUsage();
  }

  void _updateEntitlementsWithUsage() {
    state = state.copyWith(
      entitlements: state.entitlements.copyWith(
        invoiceCount: _usageLimiter.invoiceCount,
        icoLookupsCount: _usageLimiter.icoCount,
      ),
    );
  }

  Future<void> loadProducts() async {
    state = state.copyWith(isLoading: true);
    try {
      const Set<String> productIds = <String>{
        BizConfig.productProMonthly,
        BizConfig.productProYearly,
        BizConfig.productBusinessMonthly,
        BizConfig.productOneTimeStarter,
      };
      
      final ProductDetailsResponse response = await _iap.queryProductDetails(productIds);
      
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('Products not found: ${response.notFoundIDs}');
      }
      
      state = state.copyWith(
        products: response.productDetails,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> purchaseProduct(ProductDetails product) async {
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    
    // For subscriptions, we might need to handle upgrades/downgrades here
    // But keeping it simple for now
    
    if (BizConfig.allProducts.contains(product.id)) {
        // Consumables vs Non-consumables handling
        // Subscriptions are non-consumable in context of buying again immediately
        await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    }
  }

  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        state = state.copyWith(isLoading: true);
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          state = state.copyWith(isLoading: false, errorMessage: purchaseDetails.error?.message);
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
                   purchaseDetails.status == PurchaseStatus.restored) {
          
          _verifyAndDeliverProduct(purchaseDetails);
        }
        
        if (purchaseDetails.pendingCompletePurchase) {
          _iap.completePurchase(purchaseDetails);
        }
      }
    }
  }

  Future<void> _verifyAndDeliverProduct(PurchaseDetails purchaseDetails) async {
    // Ideally, verify purchase with backend here (Cloud Function)
    // For now, optimistic local grant
    
    bool isPro = false;
    bool isBusiness = false;
    
    final id = purchaseDetails.productID;
    
    if (id == BizConfig.productProMonthly || 
        id == BizConfig.productProYearly || 
        id == BizConfig.productOneTimeStarter) {
      isPro = true;
    } else if (id == BizConfig.productBusinessMonthly) {
      isBusiness = true;
      isPro = true; // Business includes Pro
    }

    // Update state
    state = state.copyWith(
      isLoading: false,
      entitlements: state.entitlements.copyWith(
        isPro: isPro,
        isBusiness: isBusiness,
        activePlanId: id,
      ),
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
