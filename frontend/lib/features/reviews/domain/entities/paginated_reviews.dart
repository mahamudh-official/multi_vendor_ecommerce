import 'package:equatable/equatable.dart';

import 'rating_distribution.dart';
import 'review.dart';

class PaginatedReviews extends Equatable {
  const PaginatedReviews({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
    required this.totalPages,
    this.hasNext = false,
    this.hasPrevious = false,
    this.averageRating = 0.0,
    this.reviewCount = 0,
    this.ratingDistribution = const RatingDistribution(),
  });

  final List<Review> items;
  final int page;
  final int pageSize;
  final int total;
  final int totalPages;
  final bool hasNext;
  final bool hasPrevious;
  final double averageRating;
  final int reviewCount;
  final RatingDistribution ratingDistribution;

  bool get hasMore => hasNext || page < totalPages;

  @override
  List<Object?> get props => [
    items,
    page,
    pageSize,
    total,
    totalPages,
    hasNext,
    hasPrevious,
    averageRating,
    reviewCount,
    ratingDistribution,
  ];
}
