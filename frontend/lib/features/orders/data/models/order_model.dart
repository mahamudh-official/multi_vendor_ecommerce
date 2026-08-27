import '../../domain/entities/order.dart';
import '../../domain/entities/order_status.dart';
import 'order_item_model.dart';
import 'shipping_address_model.dart';

class OrderModel extends Order {
  const OrderModel({
    required super.id,
    required super.userId,
    required super.orderNumber,
    required super.status,
    required super.paymentStatus,
    required super.subtotal,
    required super.shippingFee,
    required super.discountAmount,
    required super.taxAmount,
    required super.totalAmount,
    required super.currency,
    required super.shippingAddress,
    super.customerNote,
    required super.items,
    required super.itemCount,
    required super.createdAt,
    required super.updatedAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final itemsList =
        (json['items'] as List<dynamic>?)
            ?.map((i) => OrderItemModel.fromJson(i as Map<String, dynamic>))
            .toList() ??
        <OrderItemModel>[];

    return OrderModel(
      id: json['id'] as String,
      userId: (json['user_id'] ?? '') as String,
      orderNumber: json['order_number'] as String,
      status: OrderStatus.fromString(json['status'] as String),
      paymentStatus: (json['payment_status'] ?? 'pending') as String,
      subtotal: double.parse(json['subtotal']?.toString() ?? '0.0'),
      shippingFee: double.parse(json['shipping_fee']?.toString() ?? '0.0'),
      discountAmount: double.parse(
        json['discount_amount']?.toString() ?? '0.0',
      ),
      taxAmount: double.parse(json['tax_amount']?.toString() ?? '0.0'),
      totalAmount: double.parse(json['total_amount']?.toString() ?? '0.0'),
      currency: (json['currency'] ?? 'USD') as String,
      shippingAddress: ShippingAddressModel.fromJson(json),
      customerNote: json['customer_note'] as String?,
      items: itemsList,
      itemCount: json['item_count'] as int? ?? itemsList.length,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.parse(json['created_at'] as String),
    );
  }
}
