import '../../domain/entities/cart_item.dart';
import 'cart_product_model.dart';

class CartItemModel extends CartItem {
  const CartItemModel({
    required super.id,
    required super.product,
    required super.quantity,
    required super.lineTotal,
    super.isAvailable = true,
    super.stockWarning,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: json['id'] as String,
      product: CartProductModel.fromJson(
        json['product'] as Map<String, dynamic>,
      ),
      quantity: (json['quantity'] as num).toInt(),
      lineTotal: (json['line_total'] as num).toDouble(),
      isAvailable: (json['is_available'] as bool?) ?? true,
      stockWarning: json['stock_warning'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'product': (product as CartProductModel).toJson(),
    'quantity': quantity,
    'line_total': lineTotal,
    'is_available': isAvailable,
    'stock_warning': stockWarning,
  };
}
