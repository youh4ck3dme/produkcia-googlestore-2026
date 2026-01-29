// lib/shared/widgets/biz_progress_list.dart
import 'package:flutter/material.dart';

class BizProgressItem {
  BizProgressItem(this.label, {required this.done, this.subtitle});
  final String label;
  final bool done;
  final String? subtitle;
}

class BizProgressList extends StatelessWidget {
  const BizProgressList({super.key, required this.items});

  final List<BizProgressItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.map((it) {
        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading:
              Icon(it.done ? Icons.check_circle : Icons.radio_button_unchecked),
          title: Text(it.label),
          subtitle: it.subtitle == null ? null : Text(it.subtitle!),
        );
      }).toList(),
    );
  }
}
