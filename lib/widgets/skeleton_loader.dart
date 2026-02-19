import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../config/constants.dart';

class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.muted,
      highlightColor: Colors.white,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.muted,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class SkeletonList extends StatelessWidget {
  final int count;
  const SkeletonList({super.key, this.count = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: count,
      itemBuilder: (_, __) => const SkeletonCard(),
    );
  }
}
