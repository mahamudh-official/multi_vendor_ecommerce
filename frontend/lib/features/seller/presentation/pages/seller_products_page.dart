import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:multi_vendor_ecommerce/features/seller/presentation/bloc/seller_products/seller_products_bloc.dart';
import 'package:multi_vendor_ecommerce/features/seller/presentation/widgets/seller_product_card.dart';

class SellerProductsPage extends StatefulWidget {
  final bool? initialLowStock;
  final bool? initialIsActive;

  const SellerProductsPage({
    super.key,
    this.initialLowStock,
    this.initialIsActive,
  });

  @override
  State<SellerProductsPage> createState() => _SellerProductsPageState();
}

class _SellerProductsPageState extends State<SellerProductsPage> {
  final TextEditingController _searchController = TextEditingController();
  bool? _selectedIsActive;
  bool? _selectedLowStock;
  final String _selectedSort = 'newest';

  @override
  void initState() {
    super.initState();
    _selectedLowStock = widget.initialLowStock;
    _selectedIsActive = widget.initialIsActive;
    _fetchProducts();
  }

  void _fetchProducts() {
    context.read<SellerProductsBloc>().add(
      SellerProductsRequested(
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        isActive: _selectedIsActive,
        lowStock: _selectedLowStock,
        sort: _selectedSort,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Products',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Product',
            onPressed: () => context.push('/seller/products/create'),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search & Filter Bar ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search products or SKU...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                _fetchProducts();
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                    ),
                    onSubmitted: (_) => _fetchProducts(),
                  ),
                ),
              ],
            ),
          ),

          // ── Filter Chips ────────────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected:
                      _selectedIsActive == null && _selectedLowStock == null,
                  onSelected: (val) {
                    setState(() {
                      _selectedIsActive = null;
                      _selectedLowStock = null;
                    });
                    _fetchProducts();
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Active'),
                  selected: _selectedIsActive == true,
                  onSelected: (val) {
                    setState(() {
                      _selectedIsActive = val ? true : null;
                    });
                    _fetchProducts();
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Inactive'),
                  selected: _selectedIsActive == false,
                  onSelected: (val) {
                    setState(() {
                      _selectedIsActive = val ? false : null;
                    });
                    _fetchProducts();
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Low Stock'),
                  selected: _selectedLowStock == true,
                  onSelected: (val) {
                    setState(() {
                      _selectedLowStock = val ? true : null;
                    });
                    _fetchProducts();
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 16),

          // ── Product List ────────────────────────────────────────────────
          Expanded(
            child: BlocConsumer<SellerProductsBloc, SellerProductsState>(
              listener: (context, state) {
                if (state is SellerProductActionSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: const Color(0xFF10B981),
                    ),
                  );
                  _fetchProducts();
                }
              },
              builder: (context, state) {
                if (state is SellerProductsLoading ||
                    state is SellerProductActionLoading) {
                  return Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  );
                }

                if (state is SellerProductsFailure) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            size: 48,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            state.message,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _fetchProducts,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (state is SellerProductsLoaded) {
                  if (state.products.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 64,
                              color: isDark
                                  ? Colors.grey[600]
                                  : Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No products found.',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Start by adding your first product to the marketplace.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () =>
                                  context.push('/seller/products/create'),
                              icon: const Icon(Icons.add),
                              label: const Text('Add Product'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: primaryColor,
                    onRefresh: () async => _fetchProducts(),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: state.products.length,
                      itemBuilder: (context, index) {
                        final product = state.products[index];
                        return SellerProductCard(
                          product: product,
                          onEdit: () => context.push(
                            '/seller/products/${product.id}/edit',
                          ),
                          onDeactivate: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Deactivate Product?'),
                                content: Text(
                                  'Are you sure you want to deactivate "${product.name}"? '
                                  'Customers will no longer be able to purchase it.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      context.read<SellerProductsBloc>().add(
                                        SellerProductDeactivated(
                                          productId: product.id,
                                        ),
                                      );
                                    },
                                    child: const Text('Deactivate'),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
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
}
