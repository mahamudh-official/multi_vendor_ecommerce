import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/rating_distribution.dart';
import 'rating_stars_widget.dart';

class RatingDistributionWidget extends StatelessWidget {
  const RatingDistributionWidget({
    super.key,
    required this.averageRating,
    required this.reviewCount,
    required this.distribution,
  });

  final double averageRating;
  final int reviewCount;
  final RatingDistribution distribution;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: Big Rating Number & Stars
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  averageRating > 0 ? averageRating.toStringAsFixed(1) : '0.0',
                  style: AppTextStyles.h1.copyWith(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                RatingStarsWidget(rating: averageRating, size: 18),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '$reviewCount ${reviewCount == 1 ? "review" : "reviews"}',
                  style: AppTextStyles.caption.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Right: 5-to-1 Star Progress Bars
          Expanded(
            flex: 3,
            child: Column(
              children: [
                for (int star = 5; star >= 1; star--)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Row(
                      children: [
                        Text(
                          '$star★',
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.full),
                            child: LinearProgressIndicator(
                              value: distribution.getPercentage(star),
                              minHeight: 6,
                              backgroundColor: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.border,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.accent,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
