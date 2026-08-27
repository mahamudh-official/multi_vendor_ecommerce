import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:multi_vendor_ecommerce/core/theme/app_colors.dart';
import 'package:multi_vendor_ecommerce/core/theme/app_radius.dart';
import 'package:multi_vendor_ecommerce/core/theme/app_spacing.dart';
import 'package:multi_vendor_ecommerce/core/theme/app_text_styles.dart';

import '../../domain/entities/admin_entities.dart';
import '../bloc/admin_blocs.dart';
import '../widgets/admin_shell_scaffold.dart';

class AdminProductsPage extends StatefulWidget {
  const AdminProductsPage({super.key});

  @override
  State<AdminProductsPage> createState() => _AdminProductsPageState();
}

class _AdminProductsPageState extends State<AdminProductsPage> {
  final _searchController = TextEditingController();
  bool _lowStockOnly = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  void _loadProducts() {
    context.read<AdminProductsBloc>().add(
      AdminProductsLoadRequested(
        search: _searchController.text.trim(),
        lowStock: _lowStockOnly ? true : null,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AdminShellScaffold(
      title: 'Product Moderation',
      body: Column(
        children: [
          // Filter Bar
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            color: isDark ? AppColorsDark.surface : Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search products by name...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    onSubmitted: (_) => _loadProducts(),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                FilterChip(
                  label: const Text('Low Stock (≤5)'),
                  selected: _lowStockOnly,
                  onSelected: (val) {
                    setState(() => _lowStockOnly = val);
                    _loadProducts();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: _loadProducts,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Products List
          Expanded(
            child: BlocBuilder<AdminProductsBloc, AdminProductsState>(
              builder: (context, state) {
                if (state is AdminProductsLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is AdminProductsError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(state.message, style: AppTextStyles.bodyMedium),
                        const SizedBox(height: AppSpacing.sm),
                        ElevatedButton(
                          onPressed: _loadProducts,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is AdminProductsLoaded) {
                  if (state.products.isEmpty) {
                    return const Center(
                      child: Text('No products found for moderation.'),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: state.products.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final product = state.products[index];
                      return _buildProductCard(context, product);
                    },
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, AdminProduct product) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppSpacing.md),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            image: product.imageUrl != null
                ? DecorationImage(
                    image: NetworkImage(product.imageUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: product.imageUrl == null
              ? const Icon(Icons.inventory_2_rounded, color: Colors.grey)
              : null,
        ),
        title: Text(
          product.name,
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Seller: ${product.sellerName ?? product.sellerId} • Category: ${product.categoryName ?? 'Uncategorized'}',
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark
                    ? AppColorsDark.onSurfaceVariant
                    : AppColorsLight.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Text(
                  '\$${product.price.toStringAsFixed(2)}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: product.stockQuantity <= 5
                        ? AppColorsLight.error.withValues(alpha: 0.15)
                        : AppColorsLight.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Stock: ${product.stockQuantity}',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: product.stockQuantity <= 5
                          ? AppColorsLight.error
                          : AppColorsLight.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Switch(
              value: product.isActive,
              activeThumbColor: isDark
                  ? AppColorsDark.success
                  : AppColorsLight.success,
              onChanged: (val) {
                context.read<AdminProductsBloc>().add(
                  AdminProductStatusUpdateRequested(
                    productId: product.id,
                    isActive: val,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
