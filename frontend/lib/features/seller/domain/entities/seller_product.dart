import 'package:equatable/equatable.dart';

class SellerProduct extends Equatable {
  final String id;
  final String sellerId;
  final String categoryId;
  final String? categoryName;
  final String name;
  final String slug;
  final String? description;
  final double price;
  final int stockQuantity;
  final String? sku;
  final String? imageUrl;
  final bool isActive;
  final bool isLowStock;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SellerProduct({
    required this.id,
    required this.sellerId,
    required this.categoryId,
    this.categoryName,
    required this.name,
    required this.slug,
    this.description,
    required this.price,
    required this.stockQuantity,
    this.sku,
    this.imageUrl,
    required this.isActive,
    this.isLowStock = false,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    sellerId,
    categoryId,
    categoryName,
    name,
    slug,
    description,
    price,
    stockQuantity,
    sku,
    imageUrl,
    isActive,
    isLowStock,
    createdAt,
    updatedAt,
  ];
}
