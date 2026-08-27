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
import '../bloc/cart_bloc.dart';
import '../bloc/cart_event.dart';
import '../bloc/cart_state.dart';

/// Premium Shopping Cart screen for authenticated customers.
class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      context.read<CartBloc>().add(const CartRequested());
    }
  }

  void _confirmClearCart() {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Shopping Cart?'),
        content: const Text(
          'Are you sure you want to remove all items from your shopping cart?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx, true);
              context.read<CartBloc>().add(const ClearCart());
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
            appBar: AppBar(title: const Text('Shopping Cart')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 64,
                      color: isDark
                          ? AppColorsDark.onSurfaceVariant
                          : AppColorsLight.onSurfaceVariant,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Sign In to View Cart',
                      style: AppTextStyles.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Please sign in to view and manage your items in the cart.',
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
            title: const Text('Shopping Cart'),
            actions: [
              BlocBuilder<CartBloc, CartState>(
                builder: (context, state) {
                  if (state is CartLoaded && state.items.isNotEmpty) {
                    return IconButton(
                      icon: const Icon(Icons.delete_sweep_outlined),
                      tooltip: 'Clear Cart',
                      onPressed: _confirmClearCart,
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
          body: BlocConsumer<CartBloc, CartState>(
            listener: (context, state) {
              if (state is CartLoaded && state.message != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message!),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else if (state is CartFailure) {
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
              if (state is CartLoading || state is CartInitial) {
                return _buildLoadingSkeleton(isDark);
              }

              if (state is CartFailure) {
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
                          'Could not load cart',
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
                          onPressed: () => context.read<CartBloc>().add(
                            const CartRequested(),
                          ),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (state is CartLoaded) {
                if (state.items.isEmpty) {
                  return _buildEmptyCart(isDark);
                }

                return Column(
                  children: [
                    // ── Items List ─────────────────────────────────────────
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          context.read<CartBloc>().add(const CartRefreshed());
                        },
                        child: ListView.separated(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          itemCount: state.items.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: AppSpacing.md),
                          itemBuilder: (context, index) {
                            final item = state.items[index];
                            final isUpdating = state.updatingItemIds.contains(
                              item.id,
                            );

                            return _buildCartItemCard(
                              context,
                              item: item,
                              isUpdating: isUpdating,
                              isDark: isDark,
                            );
                          },
                        ),
                      ),
                    ),

                    // ── Bottom Summary & Checkout Placeholder ─────────────
                    _buildCartSummary(
                      context,
                      itemCount: state.itemCount,
                      subtotal: state.subtotal,
                      isDark: isDark,
                    ),
                  ],
                );
              }

              return const SizedBox.shrink();
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyCart(bool isDark) {
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
                Icons.shopping_cart_outlined,
                size: 64,
                color: isDark
                    ? AppColorsDark.onSurfaceVariant
                    : AppColorsLight.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Your Cart is Empty', style: AppTextStyles.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Discover thousands of products from top verified vendors and add them to your cart.',
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
              label: const Text('Start Exploring'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItemCard(
    BuildContext context, {
    required dynamic item,
    required bool isUpdating,
    required bool isDark,
  }) {
    final theme = Theme.of(context);
    final product = item.product;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: item.stockWarning != null
              ? AppColorsLight.warning.withValues(alpha: 0.5)
              : (isDark ? AppColorsDark.outline : AppColorsLight.outline),
        ),
        boxShadow: isDark ? AppShadows.smDark : AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Thumbnail ──────────────────────────────────────────────
                GestureDetector(
                  onTap: () => context.push('/products/${product.id}'),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: SizedBox(
                      width: 80,
                      height: 80,
                      child:
                          product.imageUrl != null &&
                              product.imageUrl!.isNotEmpty
                          ? Image.network(
                              product.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const ProductImagePlaceholder(size: 80),
                            )
                          : const ProductImagePlaceholder(size: 80),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),

                // ── Product Details ────────────────────────────────────────
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
                          style: AppTextStyles.titleMedium.copyWith(
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '\$${product.price.toStringAsFixed(2)} each',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark
                              ? AppColorsDark.onSurfaceVariant
                              : AppColorsLight.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // ── Line Total ───────────────────────────────────────
                      Text(
                        '\$${item.lineTotal.toStringAsFixed(2)}',
                        style: AppTextStyles.price.copyWith(fontSize: 16),
                      ),
                    ],
                  ),
                ),

                // ── Remove Button ──────────────────────────────────────────
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  tooltip: 'Remove Item',
                  onPressed: isUpdating
                      ? null
                      : () {
                          context.read<CartBloc>().add(RemoveCartItem(item.id));
                        },
                ),
              ],
            ),
          ),

          // ── Warning Banner (if any) ──────────────────────────────────────
          if (item.stockWarning != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColorsLight.warning.withValues(alpha: 0.12),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(AppRadius.lg),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: AppColorsLight.warning,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      item.stockWarning!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColorsLight.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            const Divider(height: 1),
            // ── Quantity Stepper ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Quantity', style: AppTextStyles.bodySmall),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, size: 22),
                        onPressed: isUpdating
                            ? null
                            : () {
                                context.read<CartBloc>().add(
                                  CartItemQuantityDecreased(item.id),
                                );
                              },
                      ),
                      Container(
                        constraints: const BoxConstraints(minWidth: 32),
                        alignment: Alignment.center,
                        child: isUpdating
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                '${item.quantity}',
                                style: AppTextStyles.titleMedium.copyWith(
                                  fontSize: 15,
                                ),
                              ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, size: 22),
                        onPressed:
                            isUpdating || item.quantity >= product.stockQuantity
                            ? null
                            : () {
                                context.read<CartBloc>().add(
                                  CartItemQuantityIncreased(item.id),
                                );
                              },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCartSummary(
    BuildContext context, {
    required int itemCount,
    required double subtotal,
    required bool isDark,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
        boxShadow: isDark ? AppShadows.lgDark : AppShadows.lg,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColorsDark.outline : AppColorsLight.outline,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Subtotal ($itemCount ${itemCount == 1 ? 'item' : 'items'})',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark
                        ? AppColorsDark.onSurfaceVariant
                        : AppColorsLight.onSurfaceVariant,
                  ),
                ),
                Text(
                  '\$${subtotal.toStringAsFixed(2)}',
                  style: AppTextStyles.price.copyWith(fontSize: 20),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Checkout Button ───────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: () => context.push('/checkout'),
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text(
                  'Proceed to Checkout',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
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
          height: 120,
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
