import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ZenLock extends StatelessWidget {
  const ZenLock({super.key});

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.lock_outline,
      size: 20,
      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
    )
        .animate(
          onPlay: (controller) => controller.repeat(),
        )
        .fadeIn(duration: 1500.ms)
        .then(delay: 500.ms)
        .shimmer(
          duration: 2000.ms,
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        )
        .then(delay: 1000.ms);
  }
}
