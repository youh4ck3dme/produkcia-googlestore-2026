// lib/shared/widgets/biz_section_header.dart
import 'package:flutter/material.dart';

class BizSectionHeader extends StatelessWidget {
  const BizSectionHeader({
    super.key,
    required this.title,
    this.trailing,
  });

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleSmall)),
        if (trailing != null) trailing!,
      ],
    );
  }
}
