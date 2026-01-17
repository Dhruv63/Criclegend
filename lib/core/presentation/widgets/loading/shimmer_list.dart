import 'package:flutter/material.dart';
import 'shimmer_card.dart';

class ShimmerList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final EdgeInsetsGeometry padding;

  const ShimmerList({
    super.key,
    this.itemCount = 6,
    this.itemHeight = 80,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: padding,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return ShimmerCard(
          height: itemHeight,
          margin: const EdgeInsets.only(bottom: 12),
        );
      },
    );
  }
}
