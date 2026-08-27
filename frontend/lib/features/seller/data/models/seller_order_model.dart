import 'package:multi_vendor_ecommerce/features/orders/domain/entities/order_status.dart';
import 'package:multi_vendor_ecommerce/features/seller/domain/entities/fulfillment_status.dart';
import 'package:multi_vendor_ecommerce/features/seller/domain/entities/seller_order.dart';

class SellerOrderItemModel extends SellerOrderItem {
  const SellerOrderItemModel({
    required super.id,
    required super.orderId,
    required super.productId,
    required super.productName,
    super.productSku,
    super.productImageUrl,
    required super.unitPrice,
    required super.quantity,
    required super.lineTotal,
    required super.fulfillmentStatus,
    required super.createdAt,
  });

  factory SellerOrderItemModel.fromJson(Map<String, dynamic> json) {
    return SellerOrderItemModel(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      productId: json['product_id'] as String,
      productName: json['product_name'] as String,
      productSku: json['product_sku'] as String?,
      productImageUrl: json['product_image_url'] as String?,
      unitPrice: (json['unit_price'] is String)
          ? double.tryParse(json['unit_price'] as String) ?? 0.0
          : (json['unit_price'] as num).toDouble(),
      quantity: json['quantity'] as int,
      lineTotal: (json['line_total'] is String)
          ? double.tryParse(json['line_total'] as String) ?? 0.0
          : (json['line_total'] as num).toDouble(),
      fulfillmentStatus: FulfillmentStatus.fromString(
        json['fulfillment_status'] as String? ?? 'pending',
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class SellerOrderModel extends SellerOrder {
  const SellerOrderModel({
    required super.id,
    required super.orderNumber,
    required super.status,
    required super.paymentStatus,
    required super.sellerItemCount,
    required super.sellerSubtotal,
    super.currency = 'USD',
    required super.customerName,
    super.shippingCity,
    super.shippingCountry,
    super.items = const [],
    required super.createdAt,
  });

  factory SellerOrderModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    final items = rawItems
        .map((i) => SellerOrderItemModel.fromJson(i as Map<String, dynamic>))
        .toList();

    return SellerOrderModel(
      id: json['id'] as String,
      orderNumber: json['order_number'] as String,
      status: OrderStatus.fromString(json['status'] as String),
      paymentStatus: json['payment_status'] as String,
      sellerItemCount: json['seller_item_count'] as int,
      sellerSubtotal: (json['seller_subtotal'] is String)
          ? double.tryParse(json['seller_subtotal'] as String) ?? 0.0
          : (json['seller_subtotal'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      customerName: json['customer_name'] as String? ?? 'Customer',
      shippingCity: json['shipping_city'] as String?,
      shippingCountry: json['shipping_country'] as String?,
      items: items,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
