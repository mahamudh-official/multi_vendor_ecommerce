import 'package:equatable/equatable.dart';

/// Compact product representation embedded inside Cart & Wishlist items.
class CartProduct extends Equatable {
  const CartProduct({
    required this.id,
    required this.name,
    required this.slug,
    required this.price,
    this.imageUrl,
    this.stockQuantity = 0,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String slug;
  final double price;
  final String? imageUrl;
  final int stockQuantity;
  final bool isActive;

  @override
  List<Object?> get props => [
    id,
    name,
    slug,
    price,
    imageUrl,
    stockQuantity,
    isActive,
  ];
}
