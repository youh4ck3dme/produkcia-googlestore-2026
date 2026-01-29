import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class BizShimmer extends StatelessWidget {
  final double width;
  final double height;
  final ShapeBorder shapeBorder;

  const BizShimmer.rectangular({
    super.key,
    this.width = double.infinity,
    required this.height,
  }) : shapeBorder = const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        );

  const BizShimmer.circular({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.shapeBorder = const CircleBorder(),
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Shimmer.fromColors(
      baseColor: cs.surfaceContainerHighest,
      highlightColor: cs.surfaceContainerLowest.withValues(alpha: 0.5),
      child: Container(
        width: width,
        height: height,
        decoration: ShapeDecoration(
          color: cs.surfaceContainerHighest,
          shape: shapeBorder,
        ),
      ),
    );
  }
}

class BizListShimmer extends StatelessWidget {
  const BizListShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 6,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Row(
          children: [
            const BizShimmer.rectangular(height: 50, width: 50),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BizShimmer.rectangular(
                      height: 16,
                      width: MediaQuery.of(context).size.width * 0.6),
                  const SizedBox(height: 8),
                  BizShimmer.rectangular(
                      height: 12,
                      width: MediaQuery.of(context).size.width * 0.4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
