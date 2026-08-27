import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/category.dart';

/// Modal bottom sheet for sorting and filtering products.
class ProductFilterSheet extends StatefulWidget {
  const ProductFilterSheet({
    super.key,
    required this.categories,
    this.selectedCategoryId,
    this.minPrice,
    this.maxPrice,
    this.selectedSort = 'newest',
    required this.onApply,
  });

  final List<Category> categories;
  final String? selectedCategoryId;
  final double? minPrice;
  final double? maxPrice;
  final String selectedSort;
  final Function({
    String? categoryId,
    double? minPrice,
    double? maxPrice,
    String sort,
  })
  onApply;

  @override
  State<ProductFilterSheet> createState() => _ProductFilterSheetState();
}

class _ProductFilterSheetState extends State<ProductFilterSheet> {
  late String? _selectedCatId;
  late String _selectedSort;
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedCatId = widget.selectedCategoryId;
    _selectedSort = widget.selectedSort;
    if (widget.minPrice != null) {
      _minPriceController.text = widget.minPrice!.toStringAsFixed(0);
    }
    if (widget.maxPrice != null) {
      _maxPriceController.text = widget.maxPrice!.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.xl,
          right: AppSpacing.xl,
          top: AppSpacing.lg,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Title + Reset
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filters & Sort',
                    style: AppTextStyles.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedCatId = null;
                        _selectedSort = 'newest';
                        _minPriceController.clear();
                        _maxPriceController.clear();
                      });
                    },
                    child: const Text('Reset'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Sort Section
              Text('Sort By', style: AppTextStyles.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 8,
                children: [
                  _sortChip('Newest', 'newest', theme),
                  _sortChip('Featured', 'featured', theme),
                  _sortChip('Price: Low → High', 'price_asc', theme),
                  _sortChip('Price: High → Low', 'price_desc', theme),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // Category Section
              Text('Category', style: AppTextStyles.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('All Categories'),
                    selected: _selectedCatId == null,
                    onSelected: (val) => setState(() => _selectedCatId = null),
                  ),
                  ...widget.categories.map(
                    (c) => ChoiceChip(
                      label: Text(c.name),
                      selected: _selectedCatId == c.id,
                      onSelected: (val) =>
                          setState(() => _selectedCatId = c.id),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // Price Range Section
              Text('Price Range (\$)', style: AppTextStyles.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _minPriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Min Price',
                        prefixText: '\$ ',
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextField(
                      controller: _maxPriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Max Price',
                        prefixText: '\$ ',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl2),

              // Apply Button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    final minP = double.tryParse(_minPriceController.text);
                    final maxP = double.tryParse(_maxPriceController.text);
                    widget.onApply(
                      categoryId: _selectedCatId,
                      minPrice: minP,
                      maxPrice: maxP,
                      sort: _selectedSort,
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sortChip(String label, String value, ThemeData theme) {
    final isSelected = _selectedSort == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) setState(() => _selectedSort = value);
      },
    );
  }
}
