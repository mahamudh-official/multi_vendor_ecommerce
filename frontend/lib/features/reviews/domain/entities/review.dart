import 'package:equatable/equatable.dart';

class ReviewUserSummary extends Equatable {
  const ReviewUserSummary({required this.id, required this.fullName});

  final String id;
  final String fullName;

  @override
  List<Object?> get props => [id, fullName];
}

class Review extends Equatable {
  const Review({
    required this.id,
    required this.productId,
    this.productName,
    required this.user,
    required this.orderItemId,
    required this.rating,
    this.title,
    this.comment,
    this.isVerifiedPurchase = true,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String productId;
  final String? productName;
  final ReviewUserSummary user;
  final String orderItemId;
  final int rating;
  final String? title;
  final String? comment;
  final bool isVerifiedPurchase;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
    id,
    productId,
    productName,
    user,
    orderItemId,
    rating,
    title,
    comment,
    isVerifiedPurchase,
    createdAt,
    updatedAt,
  ];
}
