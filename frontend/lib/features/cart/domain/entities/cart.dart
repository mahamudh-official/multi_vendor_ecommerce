import 'package:equatable/equatable.dart';

import 'cart_item.dart';

/// Shopping cart domain entity.
class Cart extends Equatable {
  const Cart({
    required this.id,
    this.items = const [],
    this.itemCount = 0,
    this.subtotal = 0.0,
  });

  final String id;
  final List<CartItem> items;
  final int itemCount;
  final double subtotal;

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  @override
  List<Object?> get props => [id, items, itemCount, subtotal];
}
