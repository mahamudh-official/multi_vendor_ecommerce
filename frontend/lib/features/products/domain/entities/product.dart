import 'package:equatable/equatable.dart';

import 'category.dart';
import 'product_image.dart';
import 'seller_summary.dart';

/// Product entity in the marketplace domain.
class Product extends Equatable {
  const Product({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    required this.price,
    this.compareAtPrice,
    this.stockQuantity = 0,
    this.sku,
    this.imageUrl,
    this.isActive = true,
    this.isFeatured = false,
    required this.category,
    required this.seller,
    this.images = const [],
    this.averageRating = 0.0,
    this.reviewCount = 0,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String slug;
  final String? description;
  final double price;
  final double? compareAtPrice;
  final int stockQuantity;
  final String? sku;
  final String? imageUrl;
  final bool isActive;
  final bool isFeatured;
  final Category category;
  final SellerSummary seller;
  final List<ProductImage> images;
  final double averageRating;
  final int reviewCount;
  final DateTime createdAt;

  bool get inStock => stockQuantity > 0;
  bool get hasDiscount => compareAtPrice != null && compareAtPrice! > price;

  int? get discountPercentage {
    if (!hasDiscount) return null;
    return (((compareAtPrice! - price) / compareAtPrice!) * 100).round();
  }

  @override
  List<Object?> get props => [
    id,
    name,
    slug,
    description,
    price,
    compareAtPrice,
    stockQuantity,
    sku,
    imageUrl,
    isActive,
    isFeatured,
    category,
    seller,
    images,
    averageRating,
    reviewCount,
    createdAt,
  ];
}
