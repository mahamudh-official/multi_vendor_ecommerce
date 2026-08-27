import 'package:equatable/equatable.dart';

import 'cart_product.dart';

/// Single line item in a customer shopping cart.
class CartItem extends Equatable {
  const CartItem({
    required this.id,
    required this.product,
    required this.quantity,
    required this.lineTotal,
    this.isAvailable = true,
    this.stockWarning,
  });

  final String id;
  final CartProduct product;
  final int quantity;
  final double lineTotal;
  final bool isAvailable;
  final String? stockWarning;

  @override
  List<Object?> get props => [
    id,
    product,
    quantity,
    lineTotal,
    isAvailable,
    stockWarning,
  ];
}
