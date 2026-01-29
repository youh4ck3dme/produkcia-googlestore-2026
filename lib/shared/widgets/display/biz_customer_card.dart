import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/ui/biz_theme.dart';

class BizCustomerCard extends StatelessWidget {
  final String name;
  final String? email;
  final String? phone;
  final VoidCallback? onTap;

  const BizCustomerCard({
    super.key,
    required this.name,
    this.email,
    this.phone,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final initials = name.trim().split(' ').take(2).map((e) => e.isNotEmpty ? e[0] : '').join().toUpperCase();

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: BizTheme.spacingSm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BizTheme.radiusLg),
        side: BorderSide(
          color: isDark ? BizTheme.darkOutline : BizTheme.gray100,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(BizTheme.radiusLg),
        child: Semantics(
          label: 'Zákazník $name${email != null ? ', email $email' : ''}${phone != null ? ', telefón $phone' : ''}',
          button: onTap != null,
          child: Padding(
            padding: const EdgeInsets.all(BizTheme.spacingMd),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  foregroundColor: theme.colorScheme.primary,
                  child: Text(
                    initials, 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.8) // Reduced by 20% (16 * 0.8)
                  ),
                ),
                const SizedBox(width: BizTheme.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name, 
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
                      ),
                      if (email != null || phone != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          email ?? phone!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                // Quick Actions
                if (phone != null)
                  IconButton(
                    icon: const Icon(Icons.phone_outlined, size: 20),
                    onPressed: () async {
                      final sanitized = phone!.replaceAll(RegExp(r'\s+'), '');
                      final uri = Uri(scheme: 'tel', path: sanitized);
                      try {
                        await launchUrl(uri);
                      } catch (e) {
                        debugPrint('Failed to launch $uri: $e');
                      }
                    },
                    style: IconButton.styleFrom(
                      foregroundColor: BizTheme.slovakBlue,
                      backgroundColor: BizTheme.slovakBlue.withValues(alpha: 0.1),
                    ),
                  ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, color: BizTheme.gray300, size: 20),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.05);
  }
}
