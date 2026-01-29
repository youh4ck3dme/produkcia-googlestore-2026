import 'package:flutter/material.dart';
import '../../../../core/ui/biz_theme.dart';

class BizChartContainer extends StatelessWidget {
  final String title;
  final Widget chart;
  final double height;

  const BizChartContainer({
    super.key,
    required this.title,
    required this.chart,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(BizTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: BizTheme.spacingLg),
            SizedBox(
              height: height,
              child: chart,
            ),
          ],
        ),
      ),
    );
  }
}
