import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../products/domain/entities/category.dart';
import '../../domain/entities/search_filter_params.dart';

class ProductFilterSheet extends StatefulWidget {
  const ProductFilterSheet({
    super.key,
    required this.params,
    required this.categories,
    required this.onApply,
    required this.onReset,
  });

  final SearchFilterParams params;
  final List<Category> categories;
  final ValueChanged<SearchFilterParams> onApply;
  final VoidCallback onReset;

  static Future<void> show(
    BuildContext context, {
    required SearchFilterParams currentParams,
    required List<Category> categories,
    required ValueChanged<SearchFilterParams> onApply,
    required VoidCallback onReset,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: ProductFilterSheet(
          params: currentParams,
          categories: categories,
          onApply: (params) {
            Navigator.of(ctx).pop();
            onApply(params);
          },
          onReset: () {
            Navigator.of(ctx).pop();
            onReset();
          },
        ),
      ),
    );
  }

  @override
  State<ProductFilterSheet> createState() => _ProductFilterSheetState();
}

class _ProductFilterSheetState extends State<ProductFilterSheet> {
  String? _categoryId;
  late TextEditingController _minPriceController;
  late TextEditingController _maxPriceController;
  double? _minRating;
  bool? _inStockOnly;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.params.categoryId;
    _minPriceController = TextEditingController(
      text: widget.params.minPrice != null
          ? widget.params.minPrice!.toStringAsFixed(0)
          : '',
    );
    _maxPriceController = TextEditingController(
      text: widget.params.maxPrice != null
          ? widget.params.maxPrice!.toStringAsFixed(0)
          : '',
    );
    _minRating = widget.params.minRating;
    _inStockOnly = widget.params.inStockOnly;
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  void _handleReset() {
    setState(() {
      _categoryId = null;
      _minPriceController.clear();
      _maxPriceController.clear();
      _minRating = null;
      _inStockOnly = null;
    });
    widget.onReset();
  }

  void _handleApply() {
    final double? minPrice = double.tryParse(_minPriceController.text.trim());
    final double? maxPrice = double.tryParse(_maxPriceController.text.trim());

    final updated = widget.params.copyWith(
      categoryId: _categoryId,
      clearCategory: _categoryId == null,
      minPrice: minPrice,
      clearMinPrice: minPrice == null,
      maxPrice: maxPrice,
      clearMaxPrice: maxPrice == null,
      minRating: _minRating,
      clearMinRating: _minRating == null,
      inStockOnly: _inStockOnly,
      clearInStockOnly: _inStockOnly == null,
      page: 1,
    );
    widget.onApply(updated);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.sm),
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
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filters',
                  style: AppTextStyles.h3.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: _handleReset,
                  child: const Text('Reset All'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                // 1. Categories
                Text(
                  'Category',
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    FilterChip(
                      label: const Text('All Categories'),
                      selected: _categoryId == null,
                      onSelected: (selected) {
                        if (selected) setState(() => _categoryId = null);
                      },
                    ),
                    ...widget.categories.map((cat) {
                      final isSelected = _categoryId == cat.id;
                      return FilterChip(
                        label: Text(cat.name),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _categoryId = selected ? cat.id : null;
                          });
                        },
                      );
                    }),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // 2. Price Range
                Text(
                  'Price Range (\$)',
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _minPriceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Min',
                          prefixText: '\$ ',
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                      child: Text('—'),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _maxPriceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Max',
                          prefixText: '\$ ',
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // 3. Minimum Rating
                Text(
                  'Customer Rating',
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    ChoiceChip(
                      label: const Text('Any Rating'),
                      selected: _minRating == null,
                      onSelected: (selected) {
                        if (selected) setState(() => _minRating = null);
                      },
                    ),
                    for (final rating in [4.0, 3.0, 2.0])
                      ChoiceChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('${rating.toInt()}★ & up'),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.star,
                              size: 14,
                              color: AppColors.accent,
                            ),
                          ],
                        ),
                        selected: _minRating == rating,
                        onSelected: (selected) {
                          setState(() {
                            _minRating = selected ? rating : null;
                          });
                        },
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // 4. Availability
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'In Stock Only',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                  value: _inStockOnly ?? false,
                  activeThumbColor: AppColors.primary,
                  onChanged: (val) {
                    setState(() {
                      _inStockOnly = val ? true : null;
                    });
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _handleApply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                child: const Text('Apply Filters'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
