import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_text_styles.dart';

/// Placeholder for product images when no image URL is available.
///
/// Displays a category-appropriate icon with a subtle background.
class ProductImagePlaceholder extends StatelessWidget {
  const ProductImagePlaceholder({
    super.key,
    this.size = 80,
    this.icon = Icons.shopping_bag_outlined,
    this.borderRadius,
  });

  final double size;
  final IconData icon;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isDark
            ? AppColorsDark.surfaceContainer
            : AppColorsLight.surfaceContainer,
        borderRadius: BorderRadius.circular(borderRadius ?? AppRadius.md),
      ),
      child: Icon(
        icon,
        size: size * 0.4,
        color: isDark
            ? AppColorsDark.onSurfaceVariant
            : AppColorsLight.onSurfaceVariant,
      ),
    );
  }
}

/// Full product card placeholder for loading skeleton.
class ProductCardSkeleton extends StatefulWidget {
  const ProductCardSkeleton({super.key, this.width = 160});

  final double width;

  @override
  State<ProductCardSkeleton> createState() => _ProductCardSkeletonState();
}

class _ProductCardSkeletonState extends State<ProductCardSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _shimmer = Tween<double>(
      begin: 0.4,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark
        ? AppColorsDark.surfaceContainer
        : AppColorsLight.neutral200;

    return FadeTransition(
      opacity: _shimmer,
      child: Container(
        width: widget.width,
        decoration: BoxDecoration(
          color: isDark ? AppColorsDark.surface : AppColorsLight.surface,
          borderRadius: BorderRadius.circular(AppRadius.productCard),
          border: Border.all(
            color: isDark ? AppColorsDark.outline : AppColorsLight.outline,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: widget.width * 0.75,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.productCard),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 12,
                    width: widget.width * 0.7,
                    color: baseColor,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 10,
                    width: widget.width * 0.4,
                    color: baseColor,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 14,
                    width: widget.width * 0.5,
                    color: baseColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Product card star rating display.
class StarRating extends StatelessWidget {
  const StarRating({super.key, required this.rating, this.count});

  final double rating;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final starColor = isDark ? AppColorsDark.star : AppColorsLight.star;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, size: 14, color: starColor),
        const SizedBox(width: 2),
        Text(
          rating.toStringAsFixed(1),
          style: AppTextStyles.rating.copyWith(color: starColor),
        ),
        if (count != null) ...[
          const SizedBox(width: 2),
          Text(
            '($count)',
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark
                  ? AppColorsDark.onSurfaceVariant
                  : AppColorsLight.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
