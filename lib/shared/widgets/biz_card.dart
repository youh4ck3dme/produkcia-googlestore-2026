// lib/shared/widgets/biz_card.dart
import 'package:flutter/material.dart';
import '../../core/ui/biz_theme.dart';

class BizCard extends StatelessWidget {
  const BizCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(BizTheme.spacingMd),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(padding: padding, child: child),
    );
  }
}
