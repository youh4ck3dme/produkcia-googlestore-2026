import 'package:flutter/material.dart';
import 'billing_copy.dart';
import 'subscription_guard.dart';
import 'paywall_screen.dart';

/// Jednotný vstupný paywall (bottom sheet) pred plnou PaywallScreen.
class FeaturePaywallSheet extends StatelessWidget {
  const FeaturePaywallSheet({
    super.key,
    required this.feature,
    required this.reason,
  });

  final BizFeature feature;
  final String reason;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Icon(Icons.lock_outline, size: 40, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              BillingCopy.titleFor(feature),
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              reason,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text(
              BillingCopy.sheetUnlocksTitle,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            ...BillingCopy.proBenefits.map(
              (b) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(child: Text(b, style: theme.textTheme.bodySmall)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PaywallScreen()),
                );
              },
              child: const Text(BillingCopy.ctaUpgrade),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(BillingCopy.ctaLater),
            ),
          ],
        ),
      ),
    );
  }
}
