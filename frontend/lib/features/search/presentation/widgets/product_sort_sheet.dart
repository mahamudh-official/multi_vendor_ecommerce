import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class SortOption {
  const SortOption({required this.id, required this.label, required this.icon});

  final String id;
  final String label;
  final IconData icon;
}

const List<SortOption> kSortOptions = [
  SortOption(id: 'newest', label: 'Newest Arrivals', icon: Icons.access_time),
  SortOption(id: 'popular', label: 'Most Popular', icon: Icons.trending_up),
  SortOption(id: 'rating_high', label: 'Top Rated', icon: Icons.star),
  SortOption(id: 'rating_low', label: 'Lowest Rated', icon: Icons.star_border),
  SortOption(
    id: 'price_low',
    label: 'Price: Low to High',
    icon: Icons.arrow_upward,
  ),
  SortOption(
    id: 'price_high',
    label: 'Price: High to Low',
    icon: Icons.arrow_downward,
  ),
  SortOption(id: 'oldest', label: 'Oldest Items', icon: Icons.history),
];

class ProductSortSheet extends StatelessWidget {
  const ProductSortSheet({
    super.key,
    required this.selectedSort,
    required this.onSelect,
  });

  final String selectedSort;
  final ValueChanged<String> onSelect;

  static Future<void> show(
    BuildContext context, {
    required String currentSort,
    required ValueChanged<String> onSortChanged,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => ProductSortSheet(
        selectedSort: currentSort,
        onSelect: (sort) {
          Navigator.of(ctx).pop();
          onSortChanged(sort);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBorder : AppColors.border,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sort Products',
                  style: AppTextStyles.h3.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: kSortOptions.length,
              itemBuilder: (context, index) {
                final option = kSortOptions[index];
                final isSelected = option.id == selectedSort;

                return ListTile(
                  leading: Icon(
                    option.icon,
                    color: isSelected
                        ? AppColors.primary
                        : (isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary),
                  ),
                  title: Text(
                    option.label,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? AppColors.primary
                          : (isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary),
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: AppColors.primary)
                      : null,
                  onTap: () => onSelect(option.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
