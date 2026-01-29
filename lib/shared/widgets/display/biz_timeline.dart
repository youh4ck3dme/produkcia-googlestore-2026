import 'package:flutter/material.dart';
import '../../../../core/ui/biz_theme.dart';

class BizTimelineItem {
  final String title;
  final String description;
  final DateTime? date;
  final bool isActive;
  final bool isCompleted;

  BizTimelineItem({
    required this.title,
    required this.description,
    this.date,
    this.isActive = false,
    this.isCompleted = false,
  });
}

class BizTimeline extends StatelessWidget {
  final List<BizTimelineItem> items;

  const BizTimeline({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      children: items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final isLast = index == items.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline Line & Dot
            Column(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: item.isCompleted ? BizTheme.successGreen : (item.isActive ? BizTheme.slovakBlue : BizTheme.gray300),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 40, // Fixed height or dynamic, usually expanded
                    color: item.isCompleted ? BizTheme.successGreen.withValues(alpha: 0.5) : BizTheme.gray300,
                  ),
              ],
            ),
            const SizedBox(width: BizTheme.spacingMd),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: BizTheme.spacingLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: item.isActive || item.isCompleted ? Colors.black87 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.description,
                      style: const TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
