import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class RatingStarsWidget extends StatelessWidget {
  const RatingStarsWidget({
    super.key,
    required this.rating,
    this.size = 16,
    this.showRatingNumber = false,
    this.color = AppColors.accent,
  });

  final double rating;
  final double size;
  final bool showRatingNumber;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final fullStars = rating.floor();
    final hasHalfStar = (rating - fullStars) >= 0.5;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 1; i <= 5; i++) ...[
          if (i <= fullStars)
            Icon(Icons.star, size: size, color: color)
          else if (i == fullStars + 1 && hasHalfStar)
            Icon(Icons.star_half, size: size, color: color)
          else
            Icon(
              Icons.star_border,
              size: size,
              color: color.withValues(alpha: 0.4),
            ),
        ],
        if (showRatingNumber) ...[
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: size * 0.85,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }
}
