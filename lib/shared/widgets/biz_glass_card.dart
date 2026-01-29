import 'package:flutter/material.dart';
import '../../../widgets/glass_container.dart';
import '../../core/ui/biz_theme.dart';

class BizGlassCard extends StatelessWidget {
  final Widget child;
  final double blurAmount;
  final double opacity;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  const BizGlassCard({
    super.key,
    required this.child,
    this.blurAmount = 12.0,
    this.opacity = 0.08,
    this.padding = const EdgeInsets.all(BizTheme.spacingMd),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GlassContainer(
      blurAmount: blurAmount,
      opacity: isDark ? 0.05 : opacity,
      padding: padding,
      onTap: onTap,
      child: child,
    );
  }
}
