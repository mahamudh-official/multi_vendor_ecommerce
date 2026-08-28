import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/product_image_placeholder.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../cart/presentation/bloc/cart_event.dart';
import '../../../reviews/presentation/bloc/review_bloc.dart';
import '../../../reviews/presentation/bloc/review_event.dart';
import '../../../reviews/presentation/bloc/review_state.dart';
import '../../../reviews/presentation/widgets/rating_distribution_widget.dart';
import '../../../reviews/presentation/widgets/review_card_widget.dart';
import '../../../reviews/presentation/widgets/write_review_modal.dart';
import '../../../wishlist/presentation/bloc/wishlist_bloc.dart';
import '../../../wishlist/presentation/bloc/wishlist_event.dart';
import '../../../wishlist/presentation/bloc/wishlist_state.dart';
import '../../domain/entities/product.dart';
import '../../domain/usecases/get_product_details_usecase.dart';

/// Product details screen with image gallery, seller info, wishlist toggle, and live cart addition.
class ProductDetailsPage extends StatefulWidget {
  const ProductDetailsPage({super.key, required this.productId});

  final String productId;

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  late final Future<Product> _productFuture;
  int _selectedImageIndex = 0;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _productFuture = _fetchProduct();
    context.read<ReviewBloc>().add(
      LoadProductReviews(productId: widget.productId),
    );
  }

  Future<Product> _fetchProduct() async {
    final useCase = getIt<GetProductDetailsUseCase>();
    final result = await useCase(widget.productId);
    return result.fold(
      onSuccess: (product) => product,
      onError: (failure) => throw Exception(failure.message),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sharing product link...')),
              );
            },
          ),
          BlocBuilder<WishlistBloc, WishlistState>(
            builder: (context, wishlistState) {
              final isFavorite =
                  wishlistState is WishlistLoaded &&
                  wishlistState.containsProduct(widget.productId);

              return IconButton(
                icon: Icon(
                  isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: isFavorite ? AppColorsLight.error : null,
                ),
                onPressed: () {
                  final authState = context.read<AuthBloc>().state;
                  if (authState is! Authenticated) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Please sign in to save items to your wishlist.',
                        ),
                        duration: Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }
                  context.read<WishlistBloc>().add(
                    ToggleWishlist(widget.productId),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<Product>(
        future: _productFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Failed to load product',
                    style: AppTextStyles.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  FilledButton(
                    onPressed: () {
                      setState(() {
                        _productFuture = _fetchProduct();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final product = snapshot.data!;
          final images = product.images.isNotEmpty
              ? product.images.map((i) => i.imageUrl).toList()
              : (product.imageUrl != null ? [product.imageUrl!] : <String>[]);

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Image Carousel / Gallery ─────────────────────────
                      Container(
                        height: 320,
                        width: double.infinity,
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: images.isNotEmpty
                            ? Image.network(
                                images[_selectedImageIndex],
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    ProductImagePlaceholder(
                                      size: 160,
                                      categoryName: product.category.name,
                                    ),
                              )
                            : ProductImagePlaceholder(
                                size: 160,
                                categoryName: product.category.name,
                              ),
                      ),

                      // Image thumbnails
                      if (images.length > 1)
                        SizedBox(
                          height: 72,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            scrollDirection: Axis.horizontal,
                            itemCount: images.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(width: AppSpacing.sm),
                            itemBuilder: (context, index) {
                              final isSelected = _selectedImageIndex == index;
                              return GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedImageIndex = index),
                                child: Container(
                                  width: 56,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: isSelected
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.outlineVariant,
                                      width: isSelected ? 2 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.sm,
                                    ),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Image.network(
                                    images[index],
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(Icons.image, size: 24),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Category & Stock Status Tag
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.xs,
                                    ),
                                  ),
                                  child: Text(
                                    product.category.name.toUpperCase(),
                                    style: AppTextStyles.badge.copyWith(
                                      color:
                                          theme.colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: product.inStock
                                        ? Colors.green.withValues(alpha: 0.1)
                                        : Colors.red.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.xs,
                                    ),
                                  ),
                                  child: Text(
                                    product.inStock
                                        ? 'In Stock (${product.stockQuantity})'
                                        : 'Out of Stock',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: product.inStock
                                          ? Colors.green.shade800
                                          : Colors.red.shade800,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),

                            // Product Title
                            Text(
                              product.name,
                              style: AppTextStyles.headlineSmall,
                            ),
                            const SizedBox(height: AppSpacing.md),

                            // Price & Compare-at price
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '\$${product.price.toStringAsFixed(2)}',
                                  style: AppTextStyles.price.copyWith(
                                    fontSize: 26,
                                  ),
                                ),
                                if (product.compareAtPrice != null) ...[
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(
                                    '\$${product.compareAtPrice!.toStringAsFixed(2)}',
                                    style: AppTextStyles.titleMedium.copyWith(
                                      decoration: TextDecoration.lineThrough,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  if (product.discountPercentage != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(
                                          AppRadius.xs,
                                        ),
                                      ),
                                      child: Text(
                                        '-${product.discountPercentage}%',
                                        style: AppTextStyles.badge.copyWith(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                ],
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xl),

                            // Seller info card
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.md,
                                ),
                                border: Border.all(
                                  color: theme.colorScheme.outlineVariant,
                                ),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor:
                                        theme.colorScheme.primaryContainer,
                                    child: Text(
                                      product.seller.fullName.isNotEmpty
                                          ? product.seller.fullName[0]
                                                .toUpperCase()
                                          : 'S',
                                      style: TextStyle(
                                        color: theme
                                            .colorScheme
                                            .onPrimaryContainer,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product.seller.fullName,
                                          style: AppTextStyles.titleSmall
                                              .copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Verified Seller',
                                          style: AppTextStyles.bodySmall
                                              .copyWith(
                                                color: Colors.green.shade700,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  OutlinedButton(
                                    onPressed: () {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Opening ${product.seller.fullName}\'s store...',
                                          ),
                                        ),
                                      );
                                    },
                                    child: const Text('Store'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),

                            // Description
                            Text(
                              'Description',
                              style: AppTextStyles.titleMedium,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              product.description ??
                                  'No detailed description provided for this product.',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl2),

                            // ── Customer Reviews Section ─────────────────────
                            _buildReviewsSection(context, product),
                            const SizedBox(height: AppSpacing.xl2),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Bottom Sticky Bar with Quantity & Live Add to Cart ────────
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      // Quantity selector
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant,
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 18),
                              onPressed: _quantity > 1
                                  ? () => setState(() => _quantity--)
                                  : null,
                            ),
                            Text(
                              '$_quantity',
                              style: AppTextStyles.titleSmall.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 18),
                              onPressed:
                                  product.inStock &&
                                      _quantity < product.stockQuantity
                                  ? () => setState(() => _quantity++)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),

                      // Add to Cart Button
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: product.inStock
                              ? () {
                                  final authState = context
                                      .read<AuthBloc>()
                                      .state;
                                  if (authState is! Authenticated) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Please sign in to add items to cart.',
                                        ),
                                        duration: Duration(seconds: 2),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                    return;
                                  }

                                  context.read<CartBloc>().add(
                                    AddToCart(
                                      productId: product.id,
                                      quantity: _quantity,
                                    ),
                                  );
                                }
                              : null,
                          icon: const Icon(Icons.shopping_bag_outlined),
                          label: Text(
                            product.inStock ? 'Add to Cart' : 'Out of Stock',
                          ),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildReviewsSection(BuildContext context, Product product) {
    final theme = Theme.of(context);

    return BlocBuilder<ReviewBloc, ReviewState>(
      builder: (context, reviewState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Customer Reviews', style: AppTextStyles.titleMedium),
                OutlinedButton.icon(
                  onPressed: () {
                    final authState = context.read<AuthBloc>().state;
                    if (authState is! Authenticated) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please sign in to write a review.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }

                    WriteReviewModal.show(
                      context,
                      productName: product.name,
                      onSubmit: (rating, title, comment) async {
                        context.read<ReviewBloc>().add(
                          SubmitReview(
                            productId: product.id,
                            rating: rating,
                            title: title,
                            comment: comment,
                          ),
                        );
                      },
                    );
                  },
                  icon: const Icon(Icons.rate_review, size: 16),
                  label: const Text('Write Review'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Rating Distribution Overview
            RatingDistributionWidget(
              averageRating: reviewState.averageRating > 0
                  ? reviewState.averageRating
                  : product.averageRating,
              reviewCount: reviewState.reviewCount > 0
                  ? reviewState.reviewCount
                  : product.reviewCount,
              distribution: reviewState.ratingDistribution,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Review List
            if (reviewState.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: CircularProgressIndicator.adaptive(),
                ),
              )
            else if (reviewState.reviews.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Center(
                  child: Text(
                    'No reviews yet. Be the first to review this product!',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else ...[
              for (final review in reviewState.reviews)
                ReviewCardWidget(review: review),
              if (reviewState.hasNext)
                Center(
                  child: TextButton(
                    onPressed: () {
                      context.read<ReviewBloc>().add(
                        const LoadMoreProductReviews(),
                      );
                    },
                    child: reviewState.isLoadingMore
                        ? const CircularProgressIndicator.adaptive()
                        : const Text('Load More Reviews'),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}
