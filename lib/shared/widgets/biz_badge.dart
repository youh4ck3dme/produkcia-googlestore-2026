// lib/shared/widgets/biz_badge.dart
import 'package:flutter/material.dart';

enum BizBadgeTone { ok, warn, danger, neutral }

class BizBadge extends StatelessWidget {
  const BizBadge({
    super.key,
    required this.label,
    this.tone = BizBadgeTone.neutral,
  });

  final String label;
  final BizBadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Color bg;
    Color fg;

    switch (tone) {
      case BizBadgeTone.ok:
        bg = cs.primaryContainer;
        fg = cs.onPrimaryContainer;
        break;
      case BizBadgeTone.warn:
        bg = Colors.orange.withValues(alpha: 0.18);
        fg = Colors.orange;
        break;
      case BizBadgeTone.danger:
        bg = Colors.red.withValues(alpha: 0.18);
        fg = Colors.red;
        break;
      case BizBadgeTone.neutral:
        bg = cs.surfaceContainerHighest;
        fg = cs.onSurface;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: fg),
      ),
    );
  }
}
