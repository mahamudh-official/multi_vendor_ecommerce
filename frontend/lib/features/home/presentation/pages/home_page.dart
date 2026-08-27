import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../products/domain/entities/category.dart';
import '../../../products/presentation/bloc/category/category_bloc.dart';
import '../../../products/presentation/bloc/category/category_event.dart';
import '../../../products/presentation/bloc/category/category_state.dart';
import '../../../products/presentation/bloc/product/product_bloc.dart';
import '../../../products/presentation/bloc/product/product_event.dart';
import '../../../products/presentation/bloc/product/product_state.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../cart/presentation/bloc/cart_state.dart';
import '../../../products/presentation/widgets/category_chip_list.dart';
import '../../../products/presentation/widgets/product_card.dart';
import '../../../products/presentation/widgets/product_filter_sheet.dart';

/// Premium marketplace home page connected to live CategoryBloc and ProductBloc.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    context.read<CategoryBloc>().add(const CategoriesRequested());
    context.read<ProductBloc>().add(const ProductsRequested());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      context.read<ProductBloc>().add(ProductSearchChanged(query.trim()));
    });
  }

  void _onCategorySelected(String? categoryId) {
    context.read<CategoryBloc>().add(CategorySelected(categoryId));
    context.read<ProductBloc>().add(
      ProductFilterApplied(categoryId: categoryId),
    );
  }

  void _openFilterSheet(BuildContext context, List<Category> categories) {
    final productState = context.read<ProductBloc>().state;
    String? currentCatId;
    double? minPrice;
    double? maxPrice;
    String currentSort = 'newest';

    if (productState is ProductsLoaded) {
      currentCatId = productState.categoryId;
      minPrice = productState.minPrice;
      maxPrice = productState.maxPrice;
      currentSort = productState.sort;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => ProductFilterSheet(
        categories: categories,
        selectedCategoryId: currentCatId,
        minPrice: minPrice,
        maxPrice: maxPrice,
        selectedSort: currentSort,
        onApply:
            ({
              String? categoryId,
              double? minPrice,
              double? maxPrice,
              String sort = 'newest',
            }) {
              context.read<CategoryBloc>().add(CategorySelected(categoryId));
              context.read<ProductBloc>().add(
                ProductFilterApplied(
                  categoryId: categoryId,
                  minPrice: minPrice,
                  maxPrice: maxPrice,
                  sort: sort,
                ),
              );
            },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColorsDark.background
          : AppColorsLight.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            context.read<CategoryBloc>().add(const CategoriesRequested());
            context.read<ProductBloc>().add(
              const ProductsRequested(refresh: true),
            );
          },
          child: CustomScrollView(
            slivers: [
              // ── Header Bar ───────────────────────────────────────────────
              _buildHeader(context, theme),

              // ── Search & Filter Bar ──────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          decoration: InputDecoration(
                            hintText: 'Search products, brands, tech...',
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              size: 20,
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.clear_rounded,
                                      size: 18,
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      _onSearchChanged('');
                                      setState(() {});
                                    },
                                  )
                                : null,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      BlocBuilder<CategoryBloc, CategoryState>(
                        builder: (context, catState) {
                          final categories = catState is CategoryLoaded
                              ? catState.categories
                              : <Category>[];
                          return Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.tune_rounded),
                              tooltip: 'Filters',
                              onPressed: () =>
                                  _openFilterSheet(context, categories),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // ── Categories List ──────────────────────────────────────────
              SliverToBoxAdapter(
                child: BlocBuilder<CategoryBloc, CategoryState>(
                  builder: (context, state) {
                    if (state is CategoryLoading) {
                      return const SizedBox(
                        height: 40,
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    }
                    if (state is CategoryLoaded) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm,
                        ),
                        child: CategoryChipList(
                          categories: state.categories,
                          selectedCategoryId: state.selectedCategoryId,
                          onCategorySelected: _onCategorySelected,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),

              // ── Featured Banner (Optional) ───────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.primary.withValues(alpha: 0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      boxShadow: isDark ? AppShadows.mdDark : AppShadows.md,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.full,
                                  ),
                                ),
                                child: Text(
                                  'SUMMER SALE 2026',
                                  style: AppTextStyles.badge.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Explore Verified\nMarketplace Products',
                                style: AppTextStyles.titleMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.local_offer_outlined,
                          size: 48,
                          color: Colors.white70,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Products Grid Header ─────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.sm,
                  ),
                  child: BlocBuilder<ProductBloc, ProductState>(
                    builder: (context, state) {
                      final count = state is ProductsLoaded
                          ? state.data.total
                          : 0;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Featured & New Listings',
                            style: AppTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (count > 0)
                            Text(
                              '$count items',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),

              // ── Products Grid / Loading / Empty State ────────────────────
              BlocBuilder<ProductBloc, ProductState>(
                builder: (context, state) {
                  if (state is ProductLoading) {
                    return SliverPadding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.68,
                              crossAxisSpacing: AppSpacing.md,
                              mainAxisSpacing: AppSpacing.md,
                            ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                            ),
                          ),
                          childCount: 6,
                        ),
                      ),
                    );
                  }

                  if (state is ProductFailure) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl2),
                        child: Center(
                          child: Column(
                            children: [
                              const Icon(
                                Icons.wifi_off_rounded,
                                size: 48,
                                color: Colors.orange,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(state.message, textAlign: TextAlign.center),
                              const SizedBox(height: AppSpacing.md),
                              FilledButton(
                                onPressed: () => context
                                    .read<ProductBloc>()
                                    .add(const ProductsRequested()),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  if (state is ProductsLoaded) {
                    if (state.data.items.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.xl3),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.search_off_rounded,
                                  size: 64,
                                  color: theme.colorScheme.outlineVariant,
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  'No products found',
                                  style: AppTextStyles.titleMedium,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  'Try adjusting your search keywords or filter values.',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    return SliverPadding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.68,
                              crossAxisSpacing: AppSpacing.md,
                              mainAxisSpacing: AppSpacing.md,
                            ),
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final product = state.data.items[index];
                          return ProductCard(product: product);
                        }, childCount: state.data.items.length),
                      ),
                    );
                  }

                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                },
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BlocBuilder<CartBloc, CartState>(
        builder: (context, cartState) {
          final cartCount = cartState is CartLoaded ? cartState.itemCount : 0;

          return NavigationBar(
            selectedIndex: 0,
            onDestinationSelected: (index) {
              if (index == 1) {
                context.push('/wishlist');
              } else if (index == 2) {
                context.push('/cart');
              } else if (index == 3) {
                final authState = context.read<AuthBloc>().state;
                final user = authState is Authenticated ? authState.user : null;
                _showAccountSheet(context, user);
              }
            },
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              const NavigationDestination(
                icon: Icon(Icons.favorite_outline_rounded),
                selectedIcon: Icon(Icons.favorite_rounded),
                label: 'Wishlist',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: cartCount > 0,
                  label: Text('$cartCount'),
                  child: const Icon(Icons.shopping_bag_outlined),
                ),
                selectedIcon: Badge(
                  isLabelVisible: cartCount > 0,
                  label: Text('$cartCount'),
                  child: const Icon(Icons.shopping_bag_rounded),
                ),
                label: 'Cart',
              ),
              const NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Account',
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xs,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    Icons.storefront_rounded,
                    size: 20,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  AppConstants.appName,
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                // ── Wishlist Action ─────────────────────────────────────────
                IconButton(
                  icon: const Icon(Icons.favorite_border_rounded),
                  tooltip: 'Wishlist',
                  onPressed: () => context.push('/wishlist'),
                ),

                // ── Cart Action with Live Badge ────────────────────────────
                BlocBuilder<CartBloc, CartState>(
                  builder: (context, cartState) {
                    final count = cartState is CartLoaded
                        ? cartState.itemCount
                        : 0;

                    return Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.shopping_bag_outlined),
                          tooltip: 'Shopping Cart',
                          onPressed: () => context.push('/cart'),
                        ),
                        if (count > 0)
                          Positioned(
                            right: 6,
                            top: 6,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColorsLight.error,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                count > 99 ? '99+' : '$count',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  height: 1,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),

                const SizedBox(width: 4),

                // ── User Avatar / Sheet ────────────────────────────────────
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    final user = state is Authenticated ? state.user : null;

                    return GestureDetector(
                      onTap: () => _showAccountSheet(context, user),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: theme.colorScheme.primary.withValues(
                          alpha: 0.12,
                        ),
                        child: Text(
                          user != null ? user.fullName[0].toUpperCase() : '?',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAccountSheet(BuildContext context, AuthUser? user) {
    final theme = Theme.of(context);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outline,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (user != null) ...[
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: theme.colorScheme.primary,
                        child: Text(
                          user.fullName[0].toUpperCase(),
                          style: AppTextStyles.titleLarge.copyWith(
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.fullName,
                              style: AppTextStyles.titleMedium.copyWith(
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              user.email,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.12,
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(
                          user.role.toUpperCase(),
                          style: AppTextStyles.badge.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const Divider(),

                  // Orders entry
                  ListTile(
                    leading: const Icon(Icons.receipt_long_outlined),
                    title: const Text('My Orders'),
                    subtitle: const Text(
                      'Track active orders & view purchase history',
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      Navigator.pop(bottomSheetContext);
                      context.push('/orders');
                    },
                  ),

                  // Seller product management entry
                  if (user.role == 'seller' || user.role == 'admin')
                    ListTile(
                      leading: const Icon(Icons.storefront_rounded),
                      title: const Text('My Seller Inventory'),
                      subtitle: const Text('Manage products, stock & pricing'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        Navigator.pop(bottomSheetContext);
                        context.push('/seller/products');
                      },
                    ),

                  ListTile(
                    leading: const Icon(
                      Icons.logout_rounded,
                      color: Colors.red,
                    ),
                    title: Text(
                      'Sign Out',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: Colors.red,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(bottomSheetContext);
                      context.read<AuthBloc>().add(const LogoutRequested());
                    },
                  ),
                ] else ...[
                  Text(
                    'Welcome to Marketo',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sign in to manage orders, wishlist, and your seller store.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl2),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(bottomSheetContext);
                            context.go('/register');
                          },
                          child: const Text('Register'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            Navigator.pop(bottomSheetContext);
                            context.go('/login');
                          },
                          child: const Text('Sign In'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
