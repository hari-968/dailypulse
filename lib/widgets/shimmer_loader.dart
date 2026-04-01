import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../core/theme/app_theme.dart';

class ShimmerLoader extends StatelessWidget {
  final ShimmerType type;
  final int count;

  const ShimmerLoader({
    super.key,
    this.type = ShimmerType.newsCard,
    this.count = 5,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppTheme.cardBg,
      highlightColor: AppTheme.cardBgLight,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (_, __) => type == ShimmerType.newsCard
            ? _NewsCardSkeleton()
            : _MovieCardSkeleton(),
      ),
    );
  }
}

class _NewsCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 80,
            decoration: const BoxDecoration(
              color: AppTheme.cardBgLight,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _box(double.infinity, 14),
                const SizedBox(height: 8),
                _box(200, 12),
                const SizedBox(height: 12),
                Row(children: [_box(60, 10), const SizedBox(width: 12), _box(50, 10)]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MovieCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 90,
            decoration: const BoxDecoration(
              color: AppTheme.cardBgLight,
              borderRadius: BorderRadius.horizontal(left: Radius.circular(20)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _box(160, 14),
                  const SizedBox(height: 8),
                  _box(100, 11),
                  const SizedBox(height: 10),
                  _box(120, 11),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _box(double width, double height) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.cardBgLight,
        borderRadius: BorderRadius.circular(6),
      ),
    );

enum ShimmerType { newsCard, movieCard }
