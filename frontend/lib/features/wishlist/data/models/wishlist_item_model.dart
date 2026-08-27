import '../../../cart/data/models/cart_product_model.dart';
import '../../domain/entities/wishlist_item.dart';

class WishlistItemModel extends WishlistItem {
  const WishlistItemModel({
    required super.id,
    required super.product,
    required super.createdAt,
  });

  factory WishlistItemModel.fromJson(Map<String, dynamic> json) {
    return WishlistItemModel(
      id: json['id'] as String,
      product: CartProductModel.fromJson(
        json['product'] as Map<String, dynamic>,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'product': (product as CartProductModel).toJson(),
    'created_at': createdAt.toIso8601String(),
  };
}
