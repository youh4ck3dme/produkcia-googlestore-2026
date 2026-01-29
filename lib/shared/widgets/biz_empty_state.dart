// lib/shared/widgets/biz_empty_state.dart
import 'package:flutter/material.dart';
import '../../core/ui/biz_theme.dart';

class BizEmptyState extends StatelessWidget {
  const BizEmptyState({
    super.key,
    required this.title,
    required this.body,
    this.ctaLabel,
    this.onCta,
    this.icon = Icons.inbox_outlined,
    this.imageAsset,
  });

  final String title;
  final String body;
  final String? ctaLabel;
  final VoidCallback? onCta;
  final IconData icon;
  final String? imageAsset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(BizTheme.pad),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (imageAsset != null) ...[
            // Modern illustration image
            Container(
              constraints: const BoxConstraints(maxHeight: 200, maxWidth: 300),
              child: Image.asset(
                imageAsset!,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback to icon if image fails to load
                  return Icon(icon, size: 80, color: Theme.of(context).primaryColor);
                },
              ),
            ),
            const SizedBox(height: 24),
          ] else ...[
            // Fallback to icon if no image provided
            Icon(icon, size: 80, color: Theme.of(context).primaryColor),
            const SizedBox(height: 12),
          ],
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          if (ctaLabel != null && onCta != null) ...[
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onCta,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(ctaLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
