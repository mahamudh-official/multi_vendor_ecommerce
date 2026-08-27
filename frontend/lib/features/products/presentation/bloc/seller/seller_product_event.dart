import 'package:equatable/equatable.dart';

sealed class SellerProductEvent extends Equatable {
  const SellerProductEvent();

  @override
  List<Object?> get props => [];
}

final class SellerProductsRequested extends SellerProductEvent {
  const SellerProductsRequested(this.sellerId);

  final String sellerId;

  @override
  List<Object?> get props => [sellerId];
}

final class SellerProductCreateSubmitted extends SellerProductEvent {
  const SellerProductCreateSubmitted({
    required this.name,
    this.description,
    required this.price,
    this.compareAtPrice,
    this.stockQuantity = 0,
    this.sku,
    required this.categoryId,
    this.imageUrl,
    this.images = const [],
    this.isFeatured = false,
    required this.sellerId,
  });

  final String name;
  final String? description;
  final double price;
  final double? compareAtPrice;
  final int stockQuantity;
  final String? sku;
  final String categoryId;
  final String? imageUrl;
  final List<String> images;
  final bool isFeatured;
  final String sellerId;

  @override
  List<Object?> get props => [
    name,
    description,
    price,
    compareAtPrice,
    stockQuantity,
    sku,
    categoryId,
    imageUrl,
    images,
    isFeatured,
    sellerId,
  ];
}

final class SellerProductUpdateSubmitted extends SellerProductEvent {
  const SellerProductUpdateSubmitted({
    required this.id,
    this.name,
    this.description,
    this.price,
    this.compareAtPrice,
    this.stockQuantity,
    this.sku,
    this.categoryId,
    this.imageUrl,
    this.images,
    this.isFeatured,
    this.isActive,
    required this.sellerId,
  });

  final String id;
  final String? name;
  final String? description;
  final double? price;
  final double? compareAtPrice;
  final int? stockQuantity;
  final String? sku;
  final String? categoryId;
  final String? imageUrl;
  final List<String>? images;
  final bool? isFeatured;
  final bool? isActive;
  final String sellerId;

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    price,
    compareAtPrice,
    stockQuantity,
    sku,
    categoryId,
    imageUrl,
    images,
    isFeatured,
    isActive,
    sellerId,
  ];
}

final class SellerProductDeleteSubmitted extends SellerProductEvent {
  const SellerProductDeleteSubmitted({
    required this.productId,
    required this.sellerId,
  });

  final String productId;
  final String sellerId;

  @override
  List<Object?> get props => [productId, sellerId];
}
