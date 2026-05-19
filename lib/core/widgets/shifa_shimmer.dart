import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShifaShimmer extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShifaShimmer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 16,
  });

  factory ShifaShimmer.card({double width = double.infinity, double height = 120}) {
    return ShifaShimmer(width: width, height: height, borderRadius: 24);
  }

  factory ShifaShimmer.listItem({double width = double.infinity, double height = 80}) {
    return ShifaShimmer(width: width, height: height, borderRadius: 16);
  }

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[100]!,
      period: const Duration(milliseconds: 1500),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}
