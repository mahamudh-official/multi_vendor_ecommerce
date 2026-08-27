import 'package:equatable/equatable.dart';

import '../../../cart/domain/entities/cart_product.dart';

/// Wishlist item domain entity.
class WishlistItem extends Equatable {
  const WishlistItem({
    required this.id,
    required this.product,
    required this.createdAt,
  });

  final String id;
  final CartProduct product;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, product, createdAt];
}
