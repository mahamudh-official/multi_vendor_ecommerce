import 'package:equatable/equatable.dart';
import 'package:multi_vendor_ecommerce/features/orders/domain/entities/order_status.dart';
import 'package:multi_vendor_ecommerce/features/seller/domain/entities/fulfillment_status.dart';

class SellerOrderItem extends Equatable {
  final String id;
  final String orderId;
  final String productId;
  final String productName;
  final String? productSku;
  final String? productImageUrl;
  final double unitPrice;
  final int quantity;
  final double lineTotal;
  final FulfillmentStatus fulfillmentStatus;
  final DateTime createdAt;

  const SellerOrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.productName,
    this.productSku,
    this.productImageUrl,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
    required this.fulfillmentStatus,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    orderId,
    productId,
    productName,
    productSku,
    productImageUrl,
    unitPrice,
    quantity,
    lineTotal,
    fulfillmentStatus,
    createdAt,
  ];
}

class SellerOrder extends Equatable {
  final String id;
  final String orderNumber;
  final OrderStatus status;
  final String paymentStatus;
  final int sellerItemCount;
  final double sellerSubtotal;
  final String currency;
  final String customerName;
  final String? shippingCity;
  final String? shippingCountry;
  final List<SellerOrderItem> items;
  final DateTime createdAt;

  const SellerOrder({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.paymentStatus,
    required this.sellerItemCount,
    required this.sellerSubtotal,
    this.currency = 'USD',
    required this.customerName,
    this.shippingCity,
    this.shippingCountry,
    this.items = const [],
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    orderNumber,
    status,
    paymentStatus,
    sellerItemCount,
    sellerSubtotal,
    currency,
    customerName,
    shippingCity,
    shippingCountry,
    items,
    createdAt,
  ];
}
