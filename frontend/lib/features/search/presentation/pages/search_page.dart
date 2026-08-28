import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../products/presentation/bloc/category/category_bloc.dart';
import '../../../products/presentation/bloc/category/category_state.dart';
import '../../../products/presentation/widgets/product_card.dart';
import '../bloc/product_search_bloc.dart';
import '../bloc/product_search_event.dart';
import '../bloc/product_search_state.dart';
import '../widgets/product_filter_sheet.dart';
import '../widgets/product_sort_sheet.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key, this.initialQuery, this.initialCategoryId});

  final String? initialQuery;
  final String? initialCategoryId;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      context.read<ProductSearchBloc>().add(
        ProductSearchQueryChanged(widget.initialQuery!),
      );
    } else if (widget.initialCategoryId != null) {
      context.read<ProductSearchBloc>().add(
        ProductSearchFilterApplied(categoryId: widget.initialCategoryId),
      );
    } else {
      context.read<ProductSearchBloc>().add(
        const ProductSearchQueryChanged(''),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      context.read<ProductSearchBloc>().add(
        const ProductSearchNextPageRequested(),
      );
    }
  }

  void _openSortSheet(BuildContext context, String currentSort) {
    ProductSortSheet.show(
      context,
      currentSort: currentSort,
      onSortChanged: (newSort) {
        context.read<ProductSearchBloc>().add(
          ProductSearchSortChanged(newSort),
        );
      },
    );
  }

  void _openFilterSheet(BuildContext context, ProductSearchState state) {
    final catState = context.read<CategoryBloc>().state;
    final categories = catState is CategoryLoaded ? catState.categories : [];

    ProductFilterSheet.show(
      context,
      currentParams: state.params,
      categories: categories.cast(),
      onApply: (newParams) {
        context.read<ProductSearchBloc>().add(
          ProductSearchFilterApplied(
            categoryId: newParams.categoryId,
            minPrice: newParams.minPrice,
            maxPrice: newParams.maxPrice,
            minRating: newParams.minRating,
            inStockOnly: newParams.inStockOnly,
            sort: newParams.sort,
          ),
        );
      },
      onReset: () {
        context.read<ProductSearchBloc>().add(
          const ProductSearchResetFilters(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.background;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: TextField(
          controller: _searchController,
          autofocus:
              widget.initialQuery == null && widget.initialCategoryId == null,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search products, brands, or SKU...',
            border: InputBorder.none,
            isDense: true,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      context.read<ProductSearchBloc>().add(
                        const ProductSearchCleared(),
                      );
                    },
                  )
                : null,
          ),
          onChanged: (val) {
            setState(() {});
            context.read<ProductSearchBloc>().add(
              ProductSearchQueryChanged(val),
            );
          },
        ),
      ),
      body: BlocBuilder<ProductSearchBloc, ProductSearchState>(
        builder: (context, state) {
          final filterCount = state.params.activeFilterCount;

          return Column(
            children: [
              // Filter & Sort Control Bar
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.surface,
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.border,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    // Sort Button
                    OutlinedButton.icon(
                      onPressed: () =>
                          _openSortSheet(context, state.params.sort),
                      icon: const Icon(Icons.swap_vert, size: 18),
                      label: Text(
                        _getSortLabel(state.params.sort),
                        style: AppTextStyles.labelMedium,
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    // Filter Button
                    OutlinedButton.icon(
                      onPressed: () => _openFilterSheet(context, state),
                      icon: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(Icons.tune, size: 18),
                          if (filterCount > 0)
                            Positioned(
                              top: -4,
                              right: -6,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '$filterCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      label: const Text(
                        'Filters',
                        style: AppTextStyles.labelMedium,
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (state.total > 0)
                      Text(
                        '${state.total} results',
                        style: AppTextStyles.caption.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),

              // Search Body Content
              Expanded(child: _buildSearchBody(context, state)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchBody(BuildContext context, ProductSearchState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    if (state.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: AppSpacing.md),
              Text(
                state.errorMessage ?? 'An error occurred during search.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton(
                onPressed: () {
                  context.read<ProductSearchBloc>().add(
                    ProductSearchQueryChanged(_searchController.text),
                  );
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'No products found',
                style: AppTextStyles.h3.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Try adjusting your search terms or filters.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton(
                onPressed: () {
                  _searchController.clear();
                  context.read<ProductSearchBloc>().add(
                    const ProductSearchResetFilters(),
                  );
                },
                child: const Text('Clear Filters'),
              ),
            ],
          ),
        ),
      );
    }

    // Grid of Products
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900
            ? 4
            : (constraints.maxWidth > 600 ? 3 : 2);

        return GridView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(AppSpacing.md),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: 0.72,
          ),
          itemCount: state.products.length + (state.isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == state.products.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: CircularProgressIndicator.adaptive(),
                ),
              );
            }

            final product = state.products[index];
            return ProductCard(
              product: product,
              onTap: () => context.push('/products/${product.id}'),
            );
          },
        );
      },
    );
  }

  String _getSortLabel(String sort) {
    for (final opt in kSortOptions) {
      if (opt.id == sort) return opt.label;
    }
    return 'Sort';
  }
}
