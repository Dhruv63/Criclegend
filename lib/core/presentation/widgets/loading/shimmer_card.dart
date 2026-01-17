import 'package:flutter/material.dart';
import '../shimmer_loading.dart';

class ShimmerCard extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const ShimmerCard({
    super.key,
    this.width = double.infinity,
    this.height = 100,
    this.borderRadius = 12,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      isLoading: true,
      child: Container(
        width: width,
        height: height,
        margin: margin,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: Colors.grey.shade200),
        ),
      ),
    );
  }
}
