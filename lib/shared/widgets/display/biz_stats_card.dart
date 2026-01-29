import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/ui/biz_theme.dart';

class BizStatsCard extends StatelessWidget {
  final String title;
  final String metric;
  final IconData icon;
  final Color? color;
  final String? trend;
  final bool isPositive;

  const BizStatsCard({
    super.key,
    required this.title,
    required this.metric,
    required this.icon,
    this.color,
    this.trend,
    this.isPositive = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = color ?? theme.colorScheme.primary;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BizTheme.radiusXl),
        side: BorderSide(
          color: isDark ? BizTheme.darkOutline : BizTheme.gray100,
          width: 1,
        ),
      ),
      child: Semantics(
        label: '$title: $metric${trend != null ? ', trend $trend' : ''}',
        container: true,
        child: Padding(
          padding: const EdgeInsets.all(BizTheme.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(BizTheme.radiusMd),
                    ),
                    child: Icon(icon, color: primaryColor, size: 20),
                  ),
                  if (trend != null)
                    _TrendBadge(trend: trend!, isPositive: isPositive),
                ],
              ),
              const SizedBox(height: BizTheme.spacingMd),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    metric,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),
                  const SizedBox(height: 2),
                  Text(
                    title.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOut);
  }
}

class _TrendBadge extends StatelessWidget {
  final String trend;
  final bool isPositive;

  const _TrendBadge({required this.trend, required this.isPositive});

  @override
  Widget build(BuildContext context) {
    final color = isPositive ? BizTheme.successGreen : BizTheme.errorRed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(BizTheme.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            trend,
            style: TextStyle(
              color: color,
              fontSize: 9.6, // Reduced by 20% (12 * 0.8)
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
