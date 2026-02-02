import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/ui/biz_theme.dart';
import '../../billing/subscription_guard.dart';
import '../../billing/paywall_screen.dart';
import 'ico_lookup_screen.dart';

class IcoAtlasHomeScreen extends ConsumerWidget {
  const IcoAtlasHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final guard = ref.watch(subscriptionGuardProvider);
    final hasPremium = guard.canAccess(BizFeature.icoPremiumProfile);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('ICOatlas – Overovanie firiem'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(BizTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero
            Container(
              padding: const EdgeInsets.all(BizTheme.spacingLg),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(BizTheme.radiusLg),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset(
                    'assets/icons/icoatlas-logo.png',
                    width: 48,
                    height: 48,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const SizedBox(width: 48, height: 48),
                  ),
                  const SizedBox(width: BizTheme.spacingMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Overovanie firiem podľa IČO',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Zadajte IČO a zobrazíme dostupné údaje v jednej prehľadnej karte.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'icoatlas.sk',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: BizTheme.spacingXl),

            // Lookup (embedded)
            const IcoLookupScreen(
              embedded: true,
              showHeader: false,
            ),

            const SizedBox(height: BizTheme.spacing2xl),

            // "Čo overujeme" (no unverifiable claims)
            Text(
              'Čo vieme overiť (podľa dostupných zdrojov v appke)',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: BizTheme.spacingSm),
            const Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: EdgeInsets.all(BizTheme.spacingLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Bullet(text: 'Základné údaje firmy (názov, IČO, adresa)'),
                    SizedBox(height: BizTheme.spacingSm),
                    _Bullet(text: 'Stav / status podľa dostupných údajov'),
                    SizedBox(height: BizTheme.spacingSm),
                    _Bullet(text: 'Prepojenia a doplnkové signály (ak sú dostupné)'),
                    SizedBox(height: BizTheme.spacingSm),
                    _Bullet(text: 'Sledovanie firmy (watchlist) pre upozornenia v appke'),
                  ],
                ),
              ),
            ),

            if (!hasPremium) ...[
              const SizedBox(height: BizTheme.spacing2xl),
              Text(
                'Premium profil firmy',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: BizTheme.spacingSm),
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(BizTheme.spacingLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rozšírené detaily sú dostupné v PRO/BUSINESS.',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: BizTheme.spacingMd),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const PaywallScreen()),
                            );
                          },
                          child: const Text('Získať Premium'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Icon(Icons.check_circle, size: 16, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: BizTheme.spacingSm),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

