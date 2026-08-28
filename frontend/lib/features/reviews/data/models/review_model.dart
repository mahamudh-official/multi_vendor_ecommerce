import '../../domain/entities/review.dart';

class ReviewUserSummaryModel {
  const ReviewUserSummaryModel({required this.id, required this.fullName});

  factory ReviewUserSummaryModel.fromJson(Map<String, dynamic> json) {
    return ReviewUserSummaryModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? 'Verified Customer',
    );
  }

  final String id;
  final String fullName;

  Map<String, dynamic> toJson() {
    return {'id': id, 'full_name': fullName};
  }

  ReviewUserSummary toEntity() {
    return ReviewUserSummary(id: id, fullName: fullName);
  }
}

class ReviewModel {
  const ReviewModel({
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

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      productName: json['product_name'] as String?,
      user: ReviewUserSummaryModel.fromJson(
        json['user'] as Map<String, dynamic>? ??
            {'id': '', 'full_name': 'Verified Customer'},
      ),
      orderItemId: json['order_item_id'] as String? ?? '',
      rating: json['rating'] as int? ?? 5,
      title: json['title'] as String?,
      comment: json['comment'] as String?,
      isVerifiedPurchase: json['is_verified_purchase'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  final String id;
  final String productId;
  final String? productName;
  final ReviewUserSummaryModel user;
  final String orderItemId;
  final int rating;
  final String? title;
  final String? comment;
  final bool isVerifiedPurchase;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'user': user.toJson(),
      'order_item_id': orderItemId,
      'rating': rating,
      'title': title,
      'comment': comment,
      'is_verified_purchase': isVerifiedPurchase,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Review toEntity() {
    return Review(
      id: id,
      productId: productId,
      productName: productName,
      user: user.toEntity(),
      orderItemId: orderItemId,
      rating: rating,
      title: title,
      comment: comment,
      isVerifiedPurchase: isVerifiedPurchase,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
