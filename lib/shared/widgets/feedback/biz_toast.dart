import 'package:flutter/material.dart';
import '../../../../core/ui/biz_theme.dart';

class BizToast {
  static void showSuccess(BuildContext context, String message) {
    _show(context, message, BizTheme.successGreen, Icons.check_circle_outline);
  }

  static void showError(BuildContext context, String message) {
    _show(context, message, BizTheme.errorRed, Icons.error_outline);
  }

  static void showInfo(BuildContext context, String message) {
    _show(context, message, BizTheme.slovakBlue, Icons.info_outline);
  }

  static void _show(BuildContext context, String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BizTheme.radiusMd)),
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          ],
        ),
      ),
    );
  }
}
