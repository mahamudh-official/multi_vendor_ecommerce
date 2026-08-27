/// Request payload for product creation.
class ProductCreateRequestModel {
  const ProductCreateRequestModel({
    required this.name,
    this.description,
    required this.price,
    this.compareAtPrice,
    this.stockQuantity = 0,
    this.sku,
    required this.categoryId,
    this.imageUrl,
    this.images = const [],
    this.isFeatured = false,
  });

  final String name;
  final String? description;
  final double price;
  final double? compareAtPrice;
  final int stockQuantity;
  final String? sku;
  final String categoryId;
  final String? imageUrl;
  final List<String> images;
  final bool isFeatured;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'name': name.trim(),
      'price': price.toStringAsFixed(2),
      'stock_quantity': stockQuantity,
      'category_id': categoryId,
      'is_featured': isFeatured,
      'images': images,
    };
    if (description != null && description!.trim().isNotEmpty) {
      data['description'] = description!.trim();
    }
    if (compareAtPrice != null) {
      data['compare_at_price'] = compareAtPrice!.toStringAsFixed(2);
    }
    if (sku != null && sku!.trim().isNotEmpty) {
      data['sku'] = sku!.trim();
    }
    if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      data['image_url'] = imageUrl!.trim();
    }
    return data;
  }
}

/// Request payload for product updates.
class ProductUpdateRequestModel {
  const ProductUpdateRequestModel({
    this.name,
    this.description,
    this.price,
    this.compareAtPrice,
    this.stockQuantity,
    this.sku,
    this.categoryId,
    this.imageUrl,
    this.images,
    this.isFeatured,
    this.isActive,
  });

  final String? name;
  final String? description;
  final double? price;
  final double? compareAtPrice;
  final int? stockQuantity;
  final String? sku;
  final String? categoryId;
  final String? imageUrl;
  final List<String>? images;
  final bool? isFeatured;
  final bool? isActive;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name!.trim();
    if (description != null) data['description'] = description!.trim();
    if (price != null) data['price'] = price!.toStringAsFixed(2);
    if (compareAtPrice != null) {
      data['compare_at_price'] = compareAtPrice!.toStringAsFixed(2);
    }
    if (stockQuantity != null) data['stock_quantity'] = stockQuantity;
    if (sku != null) data['sku'] = sku!.trim();
    if (categoryId != null) data['category_id'] = categoryId;
    if (imageUrl != null) data['image_url'] = imageUrl!.trim();
    if (images != null) data['images'] = images;
    if (isFeatured != null) data['is_featured'] = isFeatured;
    if (isActive != null) data['is_active'] = isActive;
    return data;
  }
}
