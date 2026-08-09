import 'package:flutter/material.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/i18n/l10n.dart';

/// Google Play AI transparency — visible label on generated content.
class AiGeneratedLabel extends StatelessWidget {
  const AiGeneratedLabel({super.key, this.compact = true});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final label = context.t(AppStr.aiGeneratedLabel);
    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome, size: 12, color: Color(0xFF7C3AED)),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFF5B21B6),
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.auto_awesome, size: 14, color: Color(0xFF7C3AED)),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: const Color(0xFF5B21B6),
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}