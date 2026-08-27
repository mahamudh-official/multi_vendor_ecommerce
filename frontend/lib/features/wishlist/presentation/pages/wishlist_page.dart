import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/product_image_placeholder.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../cart/presentation/bloc/cart_event.dart';
import '../bloc/wishlist_bloc.dart';
import '../bloc/wishlist_event.dart';
import '../bloc/wishlist_state.dart';

/// Premium Wishlist screen for authenticated customers.
class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      context.read<WishlistBloc>().add(const WishlistRequested());
    }
  }

  void _confirmClearWishlist() {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Wishlist?'),
        content: const Text(
          'Are you sure you want to remove all saved items from your wishlist?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx, true);
              context.read<WishlistBloc>().add(const ClearWishlist());
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColorsLight.error,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! Authenticated) {
          return Scaffold(
            appBar: AppBar(title: const Text('My Wishlist')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite_border_rounded,
                      size: 64,
                      color: isDark
                          ? AppColorsDark.onSurfaceVariant
                          : AppColorsLight.onSurfaceVariant,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Sign In to View Wishlist',
                      style: AppTextStyles.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Save items you love and access them on any device by signing in.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isDark
                            ? AppColorsDark.onSurfaceVariant
                            : AppColorsLight.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    FilledButton.icon(
                      onPressed: () => context.push('/auth/login'),
                      icon: const Icon(Icons.login_rounded),
                      label: const Text('Sign In Now'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('My Wishlist'),
            actions: [
              BlocBuilder<WishlistBloc, WishlistState>(
                builder: (context, state) {
                  if (state is WishlistLoaded && state.items.isNotEmpty) {
                    return IconButton(
                      icon: const Icon(Icons.delete_sweep_outlined),
                      tooltip: 'Clear Wishlist',
                      onPressed: _confirmClearWishlist,
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
          body: BlocConsumer<WishlistBloc, WishlistState>(
            listener: (context, state) {
              if (state is WishlistLoaded && state.message != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message!),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else if (state is WishlistFailure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColorsLight.error,
                    duration: const Duration(seconds: 3),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            builder: (context, state) {
              if (state is WishlistLoading || state is WishlistInitial) {
                return _buildLoadingSkeleton(isDark);
              }

              if (state is WishlistFailure) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 48,
                          color: AppColorsLight.error,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Could not load wishlist',
                          style: AppTextStyles.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          state.message,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        FilledButton.tonalIcon(
                          onPressed: () => context.read<WishlistBloc>().add(
                            const WishlistRequested(),
                          ),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (state is WishlistLoaded) {
                if (state.items.isEmpty) {
                  return _buildEmptyWishlist(isDark);
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    context.read<WishlistBloc>().add(const WishlistRefreshed());
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: state.items.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) {
                      final item = state.items[index];
                      return _buildWishlistItemCard(
                        context,
                        item: item,
                        isDark: isDark,
                      );
                    },
                  ),
                );
              }

              return const SizedBox.shrink();
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyWishlist(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl4),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColorsDark.surfaceContainer
                    : AppColorsLight.surfaceContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite_border_rounded,
                size: 64,
                color: isDark
                    ? AppColorsDark.onSurfaceVariant
                    : AppColorsLight.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Your Wishlist is Empty', style: AppTextStyles.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Save products you want to buy later by tapping the heart icon on any product card.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark
                    ? AppColorsDark.onSurfaceVariant
                    : AppColorsLight.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xl2),
            FilledButton.icon(
              onPressed: () => context.go('/home'),
              icon: const Icon(Icons.explore_outlined),
              label: const Text('Explore Catalog'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWishlistItemCard(
    BuildContext context, {
    required dynamic item,
    required bool isDark,
  }) {
    final theme = Theme.of(context);
    final product = item.product;
    final inStock = product.isActive && product.stockQuantity > 0;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark ? AppColorsDark.outline : AppColorsLight.outline,
        ),
        boxShadow: isDark ? AppShadows.smDark : AppShadows.sm,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Thumbnail ────────────────────────────────────────────────
            GestureDetector(
              onTap: () => context.push('/products/${product.id}'),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: SizedBox(
                  width: 84,
                  height: 84,
                  child:
                      product.imageUrl != null && product.imageUrl!.isNotEmpty
                      ? Image.network(
                          product.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const ProductImagePlaceholder(size: 84),
                        )
                      : const ProductImagePlaceholder(size: 84),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // ── Details & Action ─────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => context.push('/products/${product.id}'),
                    child: Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleMedium.copyWith(fontSize: 15),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '\$${product.price.toStringAsFixed(2)}',
                    style: AppTextStyles.price.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  // Stock status tag
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: inStock
                              ? AppColorsLight.success
                              : AppColorsLight.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        inStock ? 'In Stock' : 'Out of Stock',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: inStock
                              ? AppColorsLight.success
                              : AppColorsLight.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Move to Cart Button
                  FilledButton.icon(
                    onPressed: inStock
                        ? () {
                            context.read<CartBloc>().add(
                              AddToCart(productId: product.id, quantity: 1),
                            );
                          }
                        : null,
                    icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
                    label: const Text('Add to Cart'),
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ],
              ),
            ),

            // ── Remove Button ────────────────────────────────────────────
            IconButton(
              icon: const Icon(
                Icons.favorite_rounded,
                color: AppColorsLight.error,
                size: 22,
              ),
              tooltip: 'Remove from Wishlist',
              onPressed: () {
                context.read<WishlistBloc>().add(
                  RemoveFromWishlist(product.id),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: 3,
      itemBuilder: (_, _) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Container(
          height: 110,
          decoration: BoxDecoration(
            color: isDark
                ? AppColorsDark.surfaceContainer
                : AppColorsLight.surfaceContainer,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
      ),
    );
  }
}
