import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../analytics/providers/expense_insights_provider.dart';
import '../../analytics/models/expense_insight_model.dart';
import '../../../shared/widgets/biz_shimmer.dart';
import '../../../core/i18n/l10n.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/ui/biz_theme.dart';

class SmartInsightsWidget extends ConsumerWidget {
  const SmartInsightsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightsAsync = ref.watch(expenseInsightsProvider);

    return insightsAsync.when(
      data: (insights) {
        if (insights.isEmpty) return const SizedBox.shrink();

        // Take the most relevant insight (e.g., highest priority or first)
        final topInsight = insights.first;

        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: _InsightCard(insight: topInsight),
        );
      },
      loading: () => const _LoadingShimmer(),
      error: (e, st) => const SizedBox.shrink(), // Silent error on dashboard
    );
  }
}

class _InsightCard extends StatelessWidget {
  final ExpenseInsight insight;

  const _InsightCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            insight.color.withValues(alpha: 0.1),
            insight.color.withValues(alpha: 0.05),
            cs.surface,
          ],
        ),
        border: Border.all(
          color: insight.color.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: insight.color.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () =>
              context.push('/analytics'), // Or specific insights screen
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: insight.color.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(insight.icon, color: insight.color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  context.t(AppStr.aiInsightTag),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                    color: insight.color,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (insight.priority == InsightPriority.high)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: BizTheme.richCrimson.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    context.t(AppStr.importantTag),
                                    style: const TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      color: BizTheme.richCrimson,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          Text(
                            insight.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                             fontSize: 12.8, // Reduced by 20% (16 * 0.8)
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.auto_awesome,
                        color: Colors.amber.withValues(alpha: 0.6), size: 18),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  insight.description,
                  style: TextStyle(
                    fontSize: 11.2, // Reduced by 20% (14 * 0.8)
                    color: cs.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                if (insight.potentialSavings != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: BizTheme.successGreen.withValues(alpha: 0.1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.trending_up,
                            color: BizTheme.successGreen, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '+12%',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: BizTheme.successGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingShimmer extends StatelessWidget {
  const _LoadingShimmer();

  @override
  Widget build(BuildContext context) {
    return const BizShimmer.rectangular(
      height: 140,
      width: double.infinity,
    );
  }
}
