import 'package:equatable/equatable.dart';

class OrderItem extends Equatable {
  const OrderItem({
    required this.id,
    required this.productId,
    required this.sellerId,
    required this.productName,
    this.productSku,
    this.productImageUrl,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
    required this.createdAt,
  });

  final String id;
  final String productId;
  final String sellerId;
  final String productName;
  final String? productSku;
  final String? productImageUrl;
  final double unitPrice;
  final int quantity;
  final double lineTotal;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
    id,
    productId,
    sellerId,
    productName,
    productSku,
    productImageUrl,
    unitPrice,
    quantity,
    lineTotal,
    createdAt,
  ];
}
