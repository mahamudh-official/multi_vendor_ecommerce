import 'package:equatable/equatable.dart';

sealed class ReviewEvent extends Equatable {
  const ReviewEvent();

  @override
  List<Object?> get props => [];
}

final class LoadProductReviews extends ReviewEvent {
  const LoadProductReviews({
    required this.productId,
    this.page = 1,
    this.rating,
    this.verifiedOnly,
  });

  final String productId;
  final int page;
  final int? rating;
  final bool? verifiedOnly;

  @override
  List<Object?> get props => [productId, page, rating, verifiedOnly];
}

final class LoadMoreProductReviews extends ReviewEvent {
  const LoadMoreProductReviews();
}

final class SubmitReview extends ReviewEvent {
  const SubmitReview({
    required this.productId,
    required this.rating,
    this.title,
    this.comment,
  });

  final String productId;
  final int rating;
  final String? title;
  final String? comment;

  @override
  List<Object?> get props => [productId, rating, title, comment];
}

final class EditReview extends ReviewEvent {
  const EditReview({
    required this.reviewId,
    required this.productId,
    this.rating,
    this.title,
    this.comment,
  });

  final String reviewId;
  final String productId;
  final int? rating;
  final String? title;
  final String? comment;

  @override
  List<Object?> get props => [reviewId, productId, rating, title, comment];
}

final class RemoveReview extends ReviewEvent {
  const RemoveReview({required this.reviewId, required this.productId});

  final String reviewId;
  final String productId;

  @override
  List<Object?> get props => [reviewId, productId];
}
