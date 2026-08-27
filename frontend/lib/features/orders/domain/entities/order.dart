import 'package:equatable/equatable.dart';

import 'order_item.dart';
import 'order_status.dart';
import 'shipping_address.dart';

class Order extends Equatable {
  const Order({
    required this.id,
    required this.userId,
    required this.orderNumber,
    required this.status,
    required this.paymentStatus,
    required this.subtotal,
    required this.shippingFee,
    required this.discountAmount,
    required this.taxAmount,
    required this.totalAmount,
    required this.currency,
    required this.shippingAddress,
    this.customerNote,
    required this.items,
    required this.itemCount,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String orderNumber;
  final OrderStatus status;
  final String paymentStatus;
  final double subtotal;
  final double shippingFee;
  final double discountAmount;
  final double taxAmount;
  final double totalAmount;
  final String currency;
  final ShippingAddress shippingAddress;
  final String? customerNote;
  final List<OrderItem> items;
  final int itemCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
    id,
    userId,
    orderNumber,
    status,
    paymentStatus,
    subtotal,
    shippingFee,
    discountAmount,
    taxAmount,
    totalAmount,
    currency,
    shippingAddress,
    customerNote,
    items,
    itemCount,
    createdAt,
    updatedAt,
  ];
}
