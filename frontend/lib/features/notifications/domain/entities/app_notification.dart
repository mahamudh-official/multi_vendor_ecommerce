import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum NotificationType {
  orderCreated(
    'order_created',
    'Order Placed',
    Icons.shopping_bag_outlined,
    Colors.blue,
  ),
  paymentSucceeded(
    'payment_succeeded',
    'Payment Succeeded',
    Icons.check_circle_outline,
    Colors.green,
  ),
  paymentFailed(
    'payment_failed',
    'Payment Failed',
    Icons.error_outline,
    Colors.red,
  ),
  orderConfirmed(
    'order_confirmed',
    'Order Confirmed',
    Icons.thumb_up_outlined,
    Colors.indigo,
  ),
  orderProcessing(
    'order_processing',
    'Order Processing',
    Icons.inventory_2_outlined,
    Colors.purple,
  ),
  orderShipped(
    'order_shipped',
    'Order Shipped',
    Icons.local_shipping_outlined,
    Colors.teal,
  ),
  orderDelivered(
    'order_delivered',
    'Order Delivered',
    Icons.task_alt,
    Colors.green,
  ),
  orderCancelled(
    'order_cancelled',
    'Order Cancelled',
    Icons.cancel_outlined,
    Colors.red,
  ),
  lowStock(
    'low_stock',
    'Low Stock Alert',
    Icons.warning_amber_rounded,
    Colors.orange,
  ),
  sellerOrderCreated(
    'seller_order_created',
    'New Order Received',
    Icons.storefront_outlined,
    Colors.deepPurple,
  );

  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const NotificationType(this.value, this.label, this.icon, this.color);

  static NotificationType fromString(String type) {
    return NotificationType.values.firstWhere(
      (e) => e.value == type.toLowerCase(),
      orElse: () => NotificationType.orderCreated,
    );
  }
}

class AppNotification extends Equatable {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String message;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.data,
    required this.isRead,
    required this.createdAt,
  });

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      userId: userId,
      type: type,
      title: title,
      message: message,
      data: data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    type,
    title,
    message,
    data,
    isRead,
    createdAt,
  ];
}
