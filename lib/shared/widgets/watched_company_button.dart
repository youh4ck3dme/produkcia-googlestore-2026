import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/tools/services/watched_companies_service.dart';
import '../../features/billing/subscription_guard.dart';
import '../../features/billing/paywall_flow.dart';

class WatchedCompanyButton extends ConsumerWidget {
  final String icoNorm;
  final String name;
  final Color? activeColor;
  final Color? inactiveColor;

  const WatchedCompanyButton({
    super.key,
    required this.icoNorm,
    required this.name,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (icoNorm.isEmpty) return const SizedBox.shrink();

    final watchedService = ref.watch(watchedCompaniesServiceProvider);
    
    return StreamBuilder<bool>(
      stream: watchedService.isWatched(icoNorm),
      builder: (context, snapshot) {
        final isWatched = snapshot.data ?? false;

        return IconButton(
          icon: Icon(
            isWatched ? Icons.star : Icons.star_border,
            color: isWatched ? (activeColor ?? Colors.amber) : (inactiveColor ?? Colors.grey),
          ),
          tooltip: isWatched ? 'Prestať sledovať' : 'Sledovať firmu',
          onPressed: () => _handlePress(context, ref, watchedService, isWatched),
        );
      },
    );
  }

  Future<void> _handlePress(
    BuildContext context, 
    WidgetRef ref, 
    WatchedCompaniesService service, 
    bool isCurrentlyWatched
  ) async {
    if (isCurrentlyWatched) {
      // Unwatch is always allowed
      await service.unwatch(icoNorm);
      // Optional: Show snackbar
    } else {
      // Check limits before watching
      final canWatch = await _checkLimit(ref);
      if (canWatch) {
        await service.watch(icoNorm, name);
      } else {
        if (!context.mounted) return;
        final guard = ref.read(subscriptionGuardProvider);
        await PaywallFlow.showFeaturePaywall(
          context,
          feature: BizFeature.watchedCompanies,
          reason: guard.getUpgradeMessage(BizFeature.watchedCompanies),
        );
      }
    }
  }

  Future<bool> _checkLimit(WidgetRef ref) async {
    // FIX: Use SubscriptionGuard simple check
    // "Is the user allowed to add more watched companies?"
    // The previous implementation of canAccess(BizFeature.watchedCompanies) returns boolean based on tier
    // but ideally it should know the count OR we assume the button logic calls paywall if returns false.
    // Let's use the pattern:
    
    final canAccess = ref.read(subscriptionGuardProvider).canAccess(BizFeature.watchedCompanies);
    
    if (canAccess) return true;

    final watchedService = ref.read(watchedCompaniesServiceProvider);
    final count = await watchedService.getWatchedCount();
    return count < 3;
  }
}
