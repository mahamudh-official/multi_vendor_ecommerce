import '../../domain/entities/cart_product.dart';

class CartProductModel extends CartProduct {
  const CartProductModel({
    required super.id,
    required super.name,
    required super.slug,
    required super.price,
    super.imageUrl,
    super.stockQuantity = 0,
    super.isActive = true,
  });

  factory CartProductModel.fromJson(Map<String, dynamic> json) {
    return CartProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      price: (json['price'] as num).toDouble(),
      imageUrl: json['image_url'] as String?,
      stockQuantity: (json['stock_quantity'] as num?)?.toInt() ?? 0,
      isActive: (json['is_active'] as bool?) ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'slug': slug,
    'price': price,
    'image_url': imageUrl,
    'stock_quantity': stockQuantity,
    'is_active': isActive,
  };
}
