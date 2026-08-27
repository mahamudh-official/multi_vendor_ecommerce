import 'package:multi_vendor_ecommerce/features/seller/domain/entities/seller_product.dart';

class SellerProductModel extends SellerProduct {
  const SellerProductModel({
    required super.id,
    required super.sellerId,
    required super.categoryId,
    super.categoryName,
    required super.name,
    required super.slug,
    super.description,
    required super.price,
    required super.stockQuantity,
    super.sku,
    super.imageUrl,
    required super.isActive,
    super.isLowStock = false,
    required super.createdAt,
    required super.updatedAt,
  });

  factory SellerProductModel.fromJson(Map<String, dynamic> json) {
    return SellerProductModel(
      id: json['id'] as String,
      sellerId: json['seller_id'] as String,
      categoryId: json['category_id'] as String,
      categoryName: json['category_name'] as String?,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      price: (json['price'] is String)
          ? double.tryParse(json['price'] as String) ?? 0.0
          : (json['price'] as num).toDouble(),
      stockQuantity: json['stock_quantity'] as int,
      sku: json['sku'] as String?,
      imageUrl: json['image_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      isLowStock: json['is_low_stock'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
