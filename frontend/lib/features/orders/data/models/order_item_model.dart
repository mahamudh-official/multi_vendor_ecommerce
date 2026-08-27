import '../../domain/entities/order_item.dart';

class OrderItemModel extends OrderItem {
  const OrderItemModel({
    required super.id,
    required super.productId,
    required super.sellerId,
    required super.productName,
    super.productSku,
    super.productImageUrl,
    required super.unitPrice,
    required super.quantity,
    required super.lineTotal,
    required super.createdAt,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      sellerId: json['seller_id'] as String,
      productName: json['product_name'] as String,
      productSku: json['product_sku'] as String?,
      productImageUrl: json['product_image_url'] as String?,
      unitPrice: double.parse(json['unit_price'].toString()),
      quantity: json['quantity'] as int,
      lineTotal: double.parse(json['line_total'].toString()),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'product_id': productId,
    'seller_id': sellerId,
    'product_name': productName,
    'product_sku': productSku,
    'product_image_url': productImageUrl,
    'unit_price': unitPrice,
    'quantity': quantity,
    'line_total': lineTotal,
    'created_at': createdAt.toIso8601String(),
  };
}
