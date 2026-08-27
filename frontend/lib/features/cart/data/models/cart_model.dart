import '../../domain/entities/cart.dart';
import 'cart_item_model.dart';

class CartModel extends Cart {
  const CartModel({
    required super.id,
    super.items = const [],
    super.itemCount = 0,
    super.subtotal = 0.0,
  });

  factory CartModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return CartModel(
      id: json['id'] as String,
      items: rawItems
          .map((item) => CartItemModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      itemCount: (json['item_count'] as num?)?.toInt() ?? 0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'items': items.map((i) => (i as CartItemModel).toJson()).toList(),
    'item_count': itemCount,
    'subtotal': subtotal,
  };
}
