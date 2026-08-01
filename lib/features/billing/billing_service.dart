import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config.dart';
import '../auth/providers/auth_repository.dart';
import '../entitlements/user_entitlements.dart';
import '../limits/usage_limiter.dart';

/// Lokálny plan id pre UI — nie je Google Play product.
const kSuperAdminPlanId = 'super_admin';

class BillingState {
  final UserEntitlements entitlements;
  final List<ProductDetails> products;
  final bool isLoading;
  final String? errorMessage;
  final bool purchaseSuccess;

  const BillingState({
    required this.entitlements,
    this.products = const [],
    this.isLoading = false,
    this.errorMessage,
    this.purchaseSuccess = false,
  });

  BillingState copyWith({
     UserEntitlements? entitlements,
     List<ProductDetails>? products,
     bool? isLoading,
     String? errorMessage,
     bool? purchaseSuccess,
  }) {
    return BillingState(
      entitlements: entitlements ?? this.entitlements,
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      purchaseSuccess: purchaseSuccess ?? this.purchaseSuccess,
    );
  }
}

final billingProvider = NotifierProvider<BillingService, BillingState>(() => BillingService());

class BillingService extends Notifier<BillingState> {
  late final InAppPurchase _iap;
  late UsageLimiter _usageLimiter;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _testMode = false;

  BillingService();

  @override
  BillingState build() {
    ref.onDispose(() => _subscription?.cancel());

    if (_testMode) {
      return _testState!;
    }

    _usageLimiter = ref.watch(usageLimiterProvider);
    _iap = InAppPurchase.instance;

    final cached = _loadCachedEntitlements();
    _init();
    return BillingState(entitlements: cached ?? UserEntitlements.free());
  }

  BillingState? _testState;

  BillingService.forTest(BillingState state, UsageLimiter usageLimiter) {
    _testMode = true;
    _testState = state;
    _usageLimiter = usageLimiter;
    _subscription = const Stream<List<PurchaseDetails>>.empty().listen((_) {});
  }

  UserEntitlements? _loadCachedEntitlements() {
    try {
      final prefs = ref.read(sharedPrefsProvider);
      final raw = prefs.getString(UserEntitlements.spKey);
      final cached = UserEntitlements.fromSpString(raw);
      if (cached != null && cached.isExpired) {
        prefs.remove(UserEntitlements.spKey);
        return null;
      }
      return cached;
    } catch (_) {
      return null;
    }
  }

  Future<void> _cacheEntitlements(UserEntitlements e) async {
    try {
      final prefs = ref.read(sharedPrefsProvider);
      await prefs.setString(UserEntitlements.spKey, e.toSpString());
    } catch (_) {
      // Non-critical
    }
  }

  Future<void> _init() async {
    try {
      final available = await _iap.isAvailable();
      if (!ref.mounted) return;
      if (!available) {
        state = state.copyWith(errorMessage: "Store not available");
        return;
      }

      final purchaseUpdated = _iap.purchaseStream;
      _subscription = purchaseUpdated.listen(
        (purchaseDetailsList) {
          _listenToPurchaseUpdated(purchaseDetailsList);
        },
        onDone: () {
          _subscription?.cancel();
        },
        onError: (error) {
          if (!ref.mounted) return;
          state = state.copyWith(errorMessage: error.toString());
        },
      );

      await _usageLimiter.checkAndResetMonthly();
      if (!ref.mounted) return;
      _updateEntitlementsWithUsage();
      _applySuperAdminEntitlements();

      await loadProducts();
      if (!ref.mounted) return;
      await restorePurchases();
      if (!ref.mounted) return;
      _applySuperAdminEntitlements();
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  void refreshUsage() {
    _updateEntitlementsWithUsage();
    _applySuperAdminEntitlements();
  }

  bool get _isSuperAdmin =>
      ref.read(authRepositoryProvider).currentUser?.isSuperAdmin == true;

  /// Super-admin → Pro UI bez falošného Play purchase tokenu.
  void _applySuperAdminEntitlements() {
    if (!_isSuperAdmin) return;
    if (state.entitlements.isPro &&
        state.entitlements.activePlanId == kSuperAdminPlanId) {
      return;
    }
    state = state.copyWith(
      entitlements: state.entitlements.copyWith(
        isPro: true,
        activePlanId: kSuperAdminPlanId,
      ),
    );
  }

  void _updateEntitlementsWithUsage() {
    state = state.copyWith(
      entitlements: state.entitlements.copyWith(
        invoiceCount: _usageLimiter.invoiceCount,
        icoLookupsCount: _usageLimiter.icoCount,
        aiRequestsCount: _usageLimiter.aiRequestCount,
      ),
    );
  }

  Future<void> recordAiRequest() async {
    if (_testMode) return;
    await _usageLimiter.incrementAiRequest();
    if (!ref.mounted) return;
    _updateEntitlementsWithUsage();
  }

  Future<void> loadProducts() async {
    state = state.copyWith(isLoading: true);
    try {
      const Set<String> productIds = <String>{
        BizConfig.productProMonthly,
        BizConfig.productProYearly,
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
    if (BizConfig.allProducts.contains(product.id)) {
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    }
  }

  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  void clearPurchaseSuccess() {
    state = state.copyWith(purchaseSuccess: false);
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
    final id = purchaseDetails.productID;
    DateTime? expiryDate;

    // Try server-side verification
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'verify-purchase',
        body: {
          'purchaseToken': purchaseDetails.verificationData.serverVerificationData,
          'productId': id,
          'packageName': 'sk.bizagent.app',
        },
      );

      if (response.status == 200) {
        final data = response.data is String
            ? jsonDecode(response.data as String) as Map<String, dynamic>
            : response.data as Map<String, dynamic>;
        if (data['valid'] == true) {
          final expiryStr = data['expiryDate'] as String?;
          if (expiryStr != null) expiryDate = DateTime.tryParse(expiryStr);
        }
      }
    } catch (e) {
      debugPrint('verify-purchase fallback to local grant: $e');
    }

    final isPro = id == BizConfig.productProMonthly ||
        id == BizConfig.productProYearly ||
        id == BizConfig.productOneTimeStarter;

    final updated = state.entitlements.copyWith(
      isPro: isPro,
      activePlanId: id,
      expiryDate: expiryDate,
    );

    state = state.copyWith(
      isLoading: false,
      purchaseSuccess: true,
      entitlements: updated,
    );

    await _cacheEntitlements(updated);
  }
}
