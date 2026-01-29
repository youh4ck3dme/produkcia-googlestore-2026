import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/ui/biz_theme.dart';

/// Custom AppBar s liquid glass efektom pre sticky state
class BizGlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final double? elevation;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double blurAmount;
  final double opacity;

  const BizGlassAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.elevation,
    this.backgroundColor,
    this.foregroundColor,
    this.blurAmount = 15.0,
    this.opacity = 0.85,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return AppBar(
      title: title,
      actions: actions,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      elevation: elevation ?? 0,
      backgroundColor: Colors.transparent, // Transparent pre glass efekt
      foregroundColor: foregroundColor ?? (isDark ? BizTheme.darkOnSurface : BizTheme.slovakBlue),
      centerTitle: false,
      titleSpacing: 16,
      toolbarHeight: kToolbarHeight,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        BizTheme.darkSurface.withValues(alpha: opacity),
                        BizTheme.darkSurfaceVariant.withValues(alpha: opacity * 0.8),
                      ]
                    : [
                        Colors.white.withValues(alpha: opacity),
                        BizTheme.slovakBlue.withValues(alpha: opacity * 0.1),
                      ],
              ),
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? BizTheme.darkOutline.withValues(alpha: 0.3)
                      : BizTheme.gray100.withValues(alpha: 0.5),
                  width: 0.5,
                ),
              ),
            ),
          ),
        ),
      ),
      scrolledUnderElevation: 4, // Zvýšená elevation keď je sticky
      titleTextStyle: theme.appBarTheme.titleTextStyle?.copyWith(
        overflow: TextOverflow.ellipsis,
      ),
      iconTheme: theme.appBarTheme.iconTheme,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
