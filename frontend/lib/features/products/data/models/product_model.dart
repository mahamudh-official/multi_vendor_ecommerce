import '../../domain/entities/product.dart';
import 'category_model.dart';
import 'product_sub_models.dart';

/// DTO for Product entity.
class ProductModel {
  const ProductModel({
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

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final rawPrice = json['price'];
    final double price = rawPrice is num
        ? rawPrice.toDouble()
        : double.tryParse(rawPrice.toString()) ?? 0.0;

    final rawCompare = json['compare_at_price'];
    final double? compareAtPrice = rawCompare == null
        ? null
        : (rawCompare is num
              ? rawCompare.toDouble()
              : double.tryParse(rawCompare.toString()));

    final rawRating = json['average_rating'];
    final double averageRating = rawRating is num
        ? rawRating.toDouble()
        : double.tryParse(rawRating.toString()) ?? 0.0;

    final int reviewCount = json['review_count'] is int
        ? json['review_count'] as int
        : int.tryParse(json['review_count']?.toString() ?? '0') ?? 0;

    return ProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      price: price,
      compareAtPrice: compareAtPrice,
      stockQuantity: json['stock_quantity'] as int? ?? 0,
      sku: json['sku'] as String?,
      imageUrl: json['image_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      isFeatured: json['is_featured'] as bool? ?? false,
      category: CategoryModel.fromJson(
        json['category'] as Map<String, dynamic>,
      ),
      seller: SellerSummaryModel.fromJson(
        json['seller'] as Map<String, dynamic>,
      ),
      images:
          (json['images'] as List<dynamic>?)
              ?.map(
                (img) =>
                    ProductImageModel.fromJson(img as Map<String, dynamic>),
              )
              .toList() ??
          [],
      averageRating: averageRating,
      reviewCount: reviewCount,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

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
  final CategoryModel category;
  final SellerSummaryModel seller;
  final List<ProductImageModel> images;
  final double averageRating;
  final int reviewCount;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'price': price.toStringAsFixed(2),
      'compare_at_price': compareAtPrice?.toStringAsFixed(2),
      'stock_quantity': stockQuantity,
      'sku': sku,
      'image_url': imageUrl,
      'is_active': isActive,
      'is_featured': isFeatured,
      'category': category.toJson(),
      'seller': seller.toJson(),
      'images': images.map((img) => img.toJson()).toList(),
      'average_rating': averageRating,
      'review_count': reviewCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Product toEntity() {
    return Product(
      id: id,
      name: name,
      slug: slug,
      description: description,
      price: price,
      compareAtPrice: compareAtPrice,
      stockQuantity: stockQuantity,
      sku: sku,
      imageUrl: imageUrl,
      isActive: isActive,
      isFeatured: isFeatured,
      category: category.toEntity(),
      seller: seller.toEntity(),
      images: images.map((img) => img.toEntity()).toList(),
      averageRating: averageRating,
      reviewCount: reviewCount,
      createdAt: createdAt,
    );
  }
}
