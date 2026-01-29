import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../core/config.dart';
import '../../core/remote_config.dart';
import 'billing_service.dart';

class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billingState = ref.watch(billingProvider);
    final remoteConfig = BizRemoteConfig();

    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/paywall_bg.webp'), // Placeholder
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            color: const Color(0xFF0F172A).withValues(alpha: 0.85), // Dark overlay
          ),

          SafeArea(
            child: Column(
              children: [
                // Close button
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        const Text(
                          "Odomknite plný potenciál",
                          style: TextStyle(
                            fontSize: 22.4, // Reduced by 20% (28 * 0.8)
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "Neobmedzené faktúry, AI analýza a exporty.",
                          style: TextStyle(
                            fontSize: 12.8, // Reduced by 20% (16 * 0.8)
                            color: Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),

                        if (billingState.isLoading)
                          const Center(child: CircularProgressIndicator())
                        else if (billingState.errorMessage != null)
                          Text("Chyba: ${billingState.errorMessage}", style: const TextStyle(color: Colors.red))
                        else
                          ..._buildProductList(ref, billingState.products, remoteConfig),
                        
                        const SizedBox(height: 20),
                        TextButton(
                          onPressed: () {
                            ref.read(billingProvider.notifier).restorePurchases();
                          },
                          child: const Text("Obnoviť nákupy", style: TextStyle(color: Colors.white54)),
                        ),
                         const SizedBox(height: 10),
                        const Text(
                          "Predplatné sa automaticky obnovuje. Zrušiť môžete kedykoľvek v Google Play.",
                          style: TextStyle(color: Colors.white24, fontSize: 10),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildProductList(WidgetRef ref, List<ProductDetails> products, BizRemoteConfig config) {
    // Basic sorting: Yearly first if discounted, else Monthly
    final yearly = products.firstWhere((p) => p.id == BizConfig.productProYearly, orElse: () => _mockProduct(BizConfig.productProYearly));
    final monthly = products.firstWhere((p) => p.id == BizConfig.productProMonthly, orElse: () => _mockProduct(BizConfig.productProMonthly));
    final oneTime = products.firstWhere((p) => p.id == BizConfig.productOneTimeStarter, orElse: () => _mockProduct(BizConfig.productOneTimeStarter));

    return [
      const _FeatureRow(icon: Icons.check, text: "Neobmedzené faktúry"),
      const _FeatureRow(icon: Icons.check, text: "AI Daňový poradca"),
      const _FeatureRow(icon: Icons.check, text: "Excel Exporty"),
      const _FeatureRow(icon: Icons.check, text: "Prioritná podpora"),
      const SizedBox(height: 30),

      // Yearly Deal (Highlight)
      _PricingCard(
        product: yearly,
        isBestValue: true,
        discountPercent: config.annualDiscount,
        onTap: () => ref.read(billingProvider.notifier).purchaseProduct(yearly),
      ),
      const SizedBox(height: 16),

      // Monthly
      _PricingCard(
        product: monthly,
        isBestValue: false,
        onTap: () => ref.read(billingProvider.notifier).purchaseProduct(monthly),
      ),
      
      // Anchor Price (One Time)
      if (config.enableOneTimePurchase) ...[
         const SizedBox(height: 16),
         const Divider(color: Colors.white12),
         const SizedBox(height: 16),
         _PricingCard(
          product: oneTime,
          isBestValue: false,
          isOneTime: true,
          onTap: () => ref.read(billingProvider.notifier).purchaseProduct(oneTime),
        ),
      ]
    ];
  }

  // Mock for development if store not connected
  ProductDetails _mockProduct(String id) {
     return ProductDetails(
       id: id,
       title: id.contains('year') ? "Ročné PRO" : (id.contains('one') ? "Doživotný Štart" : "Mesačné PRO"),
       description: "Description",
       price: id.contains('year') ? "99.99 €" : (id.contains('one') ? "14.99 €" : "9.99 €"),
       rawPrice: 10,
       currencyCode: "EUR",
     );
  }
}

class _PricingCard extends StatelessWidget {
  final ProductDetails product;
  final bool isBestValue;
  final int? discountPercent;
  final bool isOneTime;
  final VoidCallback onTap;

  const _PricingCard({
    required this.product,
    required this.onTap,
    this.isBestValue = false,
    this.discountPercent,
    this.isOneTime = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassmorphicContainer(
        width: double.infinity,
        height: 80,
        borderRadius: 16,
        blur: 20,
        alignment: Alignment.center,
        border: 2,
        linearGradient: LinearGradient(
          colors: isBestValue 
              ? [Colors.blue.withValues(alpha: 0.3), Colors.purple.withValues(alpha: 0.3)]
              : [Colors.white.withValues(alpha: 0.1), Colors.white.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderGradient: LinearGradient(
          colors: isBestValue
              ? [Colors.blueAccent.withValues(alpha: 0.5), Colors.purpleAccent.withValues(alpha: 0.5)]
              : [Colors.white24, Colors.white10],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isOneTime ? "JEDNORAZOVO" : (product.id.contains('year') ? "ROČNE" : "MESAČNE"),
                    style: TextStyle(
                      color: isBestValue ? Colors.blueAccent[100] : Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 9.6, // Reduced by 20% (12 * 0.8)
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.price,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.4, // Reduced by 20% (18 * 0.8)
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (isBestValue && discountPercent != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "UŠETRÍTE $discountPercent%",
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
     return Padding(
       padding: const EdgeInsets.only(bottom: 12),
       child: Row(
         children: [
           Icon(icon, color: Colors.greenAccent, size: 20),
           const SizedBox(width: 12),
           Text(text, style: const TextStyle(color: Colors.white, fontSize: 11.2)), // Reduced by 20% (14 * 0.8)
         ],
       ),
     );
  }
}
