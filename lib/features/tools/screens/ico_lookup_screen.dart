import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/ui/biz_theme.dart';
import '../../../core/services/company_lookup_service.dart';
import '../../../core/models/ico_lookup_result.dart';
import '../../../shared/widgets/watched_company_button.dart';
import '../../billing/subscription_guard.dart';
import '../../billing/paywall_screen.dart';
import '../../limits/usage_limiter.dart';
import '../../billing/billing_service.dart';

// Provider for the search query and lookup result
final icoSearchQueryProvider = StateProvider<String>((ref) => '');

final icoLookupFutureProvider = FutureProvider<IcoLookupResult?>((ref) async {
  final query = ref.watch(icoSearchQueryProvider);
  if (query.length < 8) return null;
  
  final lookupService = ref.read(companyLookupServiceProvider);

  try {
    return await lookupService.lookupByIco(query);
  } catch (e) {
    debugPrint('Lookup failed: $e');
    // Rethrow to let UI handle specific errors (like socket exception if mapped)
    // Or return a specific failure object. For now returning null is handled as empty/error.
    // Ideally we propagate the error state to the UI provider.
    rethrow;
  }
});

class IcoLookupScreen extends ConsumerStatefulWidget {
  const IcoLookupScreen({super.key});

  @override
  ConsumerState<IcoLookupScreen> createState() => _IcoLookupScreenState();
}

class _IcoLookupScreenState extends ConsumerState<IcoLookupScreen> {
  final TextEditingController _controller = TextEditingController();
  // bool _isSearching = false;

  void _handleSearch() {
    final query = _controller.text.trim();
    if (query.length == 8) {
      final guard = ref.read(subscriptionGuardProvider);
      if (guard.canAccess(BizFeature.icoLookup)) {
        // Debounce protection: Check if already loading
        if (ref.read(icoLookupFutureProvider).isLoading) return;

        ref.read(icoSearchQueryProvider.notifier).state = query;
        ref.read(usageLimiterProvider).incrementIco();
        ref.read(billingProvider.notifier).refreshUsage();
      } else {
         Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PaywallScreen()),
         );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zadajte platné 8-miestne IČO')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lookupAsync = ref.watch(icoLookupFutureProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Overenie Firmy'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(BizTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'IČO Register',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: BizTheme.slovakBlue,
              ),
            ),
            const SizedBox(height: BizTheme.spacingXs),
            Text(
              'Okamžitá kontrola rizikovosti a stavu firmy.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: BizTheme.spacingXl),
            
            // Search Field
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(BizTheme.radiusLg),
                border: Border.all(color: isDark ? BizTheme.darkOutline : BizTheme.gray100),
                boxShadow: isDark ? null : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                maxLength: 8,
                style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: 'Zadajte IČO (napr. 35742364)',
                  counterText: '',
                  prefixIcon: const Icon(Icons.search, color: BizTheme.slovakBlue),
                  suffixIcon: IconButton(
                    icon: lookupAsync.isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.arrow_forward_rounded, color: BizTheme.slovakBlue),
                    onPressed: lookupAsync.isLoading ? null : _handleSearch,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.all(BizTheme.spacingLg),
                ),
                onSubmitted: (_) => _handleSearch(),
              ),
            ),
            
            const SizedBox(height: BizTheme.spacing2xl),
            
            // Result Area
            lookupAsync.when(
              data: (result) {
                if (result == null) {
                  return _buildEmptyState();
                }
                if (result.isRateLimited) {
                  return _buildRateLimitedState(result.resetIn);
                }
                if (result.isPaymentRequired) {
                  return _buildPaymentRequiredState();
                }
                return _buildResultCard(result);
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(BizTheme.spacing3xl),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) {
                // Better Offline / Error UX
                final msg = e.toString().toLowerCase();
                final isOffline = msg.contains('socket') || msg.contains('connection') || msg.contains('internet');
                return _buildErrorState(isOffline 
                    ? 'Skontrolujte pripojenie na internet.' 
                    : 'Nepodarilo sa načítať údaje.');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(IcoLookupResult result) {
    final theme = Theme.of(context);
    final isReliable = result.status.toLowerCase().contains('aktív') || result.status.toLowerCase().contains('pôsob');
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(BizTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isReliable ? Colors.green : Colors.orange).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(BizTheme.radiusSm),
                  ),
                  child: Text(
                    result.status.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isReliable ? Colors.green[700] : Colors.orange[700],
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      isReliable ? Icons.verified_rounded : Icons.warning_amber_rounded,
                      color: isReliable ? Colors.green : Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    WatchedCompanyButton(
                      icoNorm: result.icoNorm,
                      name: result.name,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: BizTheme.spacingLg),
            Text(
              result.name,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: BizTheme.spacingSm),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 16, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    result.fullAddress,
                    style: theme.textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (result.headline != null || result.explanation != null) ...[
              const SizedBox(height: BizTheme.spacingLg),
              Container(
                padding: const EdgeInsets.all(BizTheme.spacingLg),
                decoration: BoxDecoration(
                  color: BizTheme.slovakBlue.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(BizTheme.radiusMd),
                  border: Border.all(color: BizTheme.slovakBlue.withValues(alpha: 0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: BizTheme.slovakBlue, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'AI VERDIKT',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: BizTheme.slovakBlue,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const Spacer(),
                        if (result.confidence != null)
                          Text(
                            '${(result.confidence! * 100).toInt()}% istota',
                            style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                      ],
                    ),
                    const SizedBox(height: BizTheme.spacingSm),
                    Text(
                      result.headline ?? 'Analýza dokončená',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      result.explanation ?? '',
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
            
            // Risk Badge (LOW / MEDIUM / HIGH)
            if (result.riskLevel != null || result.riskHint != null) ...[
              const SizedBox(height: BizTheme.spacingMd),
              _buildRiskBadge(result.riskLevel, result.riskHint),
            ],
            const SizedBox(height: BizTheme.spacingXl),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      context.push(
                        '/create-invoice',
                        extra: {
                          'clientName': result.name,
                          'clientIco': _controller.text,
                          'clientAddress': result.fullAddress,
                          'clientDic': result.dic,
                          'clientIcDph': result.icDph,
                        },
                      );
                    },
                    icon: const Icon(Icons.receipt_long, size: 18),
                    label: const Text('VYSTAVIŤ FAKTÚRU'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: BizTheme.spacingSm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  // Logic to add to contacts would go here
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Firma bola pridaná do kontaktov')),
                  );
                },
                icon: const Icon(Icons.person_add_outlined, size: 18),
                label: const Text('PRIDAŤ DO KONTAKTOV'),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05);
  }

  Widget _buildPaymentRequiredState() {
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(BizTheme.spacingLg),
      decoration: BoxDecoration(
        color: BizTheme.slovakBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(BizTheme.radiusLg),
        border: Border.all(color: BizTheme.slovakBlue.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.lock_person_outlined, size: 48, color: BizTheme.slovakBlue),
          const SizedBox(height: BizTheme.spacingMd),
          Text(
            'Secure Gateway: Premium',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: BizTheme.slovakBlue,
            ),
          ),
          const SizedBox(height: BizTheme.spacingSm),
          const Text(
            'Váš aktuálny plán nepovoľuje neobmedzené lookupy cez bezpečný gateway.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: BizTheme.spacingXl),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {},
              child: const Text('AKTIVOVAŤ SOLO/GROWTH PLÁN'),
            ),
          ),
        ],
      ),
    ).animate().shake();
  }

  Widget _buildRateLimitedState(int? resetIn) {
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(BizTheme.spacingLg),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(BizTheme.radiusLg),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.speed_rounded, size: 48, color: Colors.orange),
          const SizedBox(height: BizTheme.spacingMd),
          Text(
            'Limit dosiahnutý',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.orange[900],
            ),
          ),
          const SizedBox(height: BizTheme.spacingSm),
          Text(
            'Bezplatný limit pre verejné vyhľadávanie je 10 dopytov za 10 minút.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.orange[800]),
          ),
          if (resetIn != null) ...[
            const SizedBox(height: BizTheme.spacingMd),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(BizTheme.radiusXl),
              ),
              child: Text(
                'Skúste to znova o ${resetIn ~/ 60} minút',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold, 
                  color: Colors.orange[900],
                ),
              ),
            ),
          ],
          const SizedBox(height: BizTheme.spacingXl),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {},
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange[700],
              ),
              child: const Text('PREJSŤ NA PREMIUM (BEZ LIMITOV)'),
            ),
          ),
        ],
      ),
    ).animate().shake();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Opacity(
        opacity: 0.5,
        child: Column(
          children: [
            const Icon(Icons.business_center_outlined, size: 80),
            const SizedBox(height: BizTheme.spacingMd),
            Text(
              'Zadajte IČO pre okamžité overenie',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(BizTheme.spacingLg),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: BizTheme.nationalRed, size: 48),
            const SizedBox(height: BizTheme.spacingMd),
            const Text(
              'Vyskytla sa chyba pri načítaní.',
              textAlign: TextAlign.center,
              style: TextStyle(color: BizTheme.nationalRed, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              error,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskBadge(String? level, String? hint) {
    final theme = Theme.of(context);
    final color = switch (level?.toUpperCase()) {
      'LOW' => Colors.green,
      'MEDIUM' => Colors.orange,
      'HIGH' => BizTheme.nationalRed,
      _ => Colors.blue,
    };

    return Container(
      padding: const EdgeInsets.all(BizTheme.spacingMd),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(BizTheme.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(Icons.shield_outlined, color: color, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Risk Score: ${level ?? "UNKNOWN"}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (hint != null)
                  Text(
                    hint,
                    style: theme.textTheme.bodySmall?.copyWith(color: color),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
